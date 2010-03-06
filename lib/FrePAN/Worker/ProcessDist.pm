package FrePAN::Worker::ProcessDist;
use FrePAN::Worker;
use File::Basename;
use Archive::Extract;
use URI;
use Guard;
use Path::Class;
use autodie;
use Pod::POM;
use FrePAN::Pod::POM::View::HTML;
use YAML::Tiny;
use LWP::UserAgent;
use File::Temp qw/tempdir/;
use JSON::XS;
use Cwd;

sub run {
    my ($class, $info) = @_;

    my $c = Amon->context;

    my ($author) = ($info->{path} =~ m{^./../([^/]+)/});
    $info->{author} = $author;
    die "cannot detect author: '$info->{path}'" unless $author;

    # fetch
    my $ua = LWP::UserAgent->new(agent => "FrePAN/$FrePAN::VERSION");
    my ($x, $y, $suffix) = fileparse(URI->new($info->{url})->path, qw/zip tar.gz tar.bz2/);
    msg "suffix: $suffix";
    my $tmp = File::Temp->new(UNLINK => 0, SUFFIX => ".$suffix");
    my $res = $ua->get($info->{url}, ':content_file' => "$tmp");
    $res->code =~ /^(?:304|200)$/ or die "fetch failed: $info->{url}, " . $res->status_line;

    # guard.
    my $orig_cwd = Cwd::getcwd();

    # extract and chdir
    my $tmpdir = tempdir(CLEANUP => 1);
    my $ae = Archive::Extract->new(archive => $tmp);
    $ae->extract(to => $tmpdir) or die "cannot extract $info->{url}, " . $ae->error;
    my @dirs = grep { -d $_ } dir($tmpdir)->children();
    chdir(@dirs==1 ? $dirs[0] : $tmpdir);

    # render and register files.
    my $meta = load_meta($info->{url});
    my $no_index = join '|', map { quotemeta $_ } @{$meta->{no_index}->{directory} || []};
       $no_index = qr/^(?:$no_index)/ if $no_index;
    my $requires = $meta->{requires};

    my $txn = $c->db->txn_scope;

    my $replace = sub {
        my ($self, $table, $params) = @_;
        my $dbh = $self->dbh;
        my @keys = keys %$params;
        my $sql = join('', "REPLACE INTO $table (",
            join(',', @keys),
            ") VALUES (",
            join(',', ("?") x scalar(@keys)),
            ");"
        );
        my $sth = $dbh->prepare($sql);
        $sth->execute(map { $params->{$_} } @keys);
    };

    $replace->(
        $c->db,
        dist => {
            author   => $info->{author},
            path     => $info->{path},
            name     => $info->{name},
            version  => $info->{version},
            requires => encode_json( $requires ),
            abstract => $meta->{abstract} || '',
        }
    );
    my $dist = $c->db->single(
        dist => {
            name    => $info->{name},
            version => $info->{version},
            author  => $info->{author},
        }
    );

    dir('.')->recurse(
        callback => sub {
            my $f = shift;
            msg("processing $f");
            # TODO: show script
            unless ($f =~ /\.pm$/) {
                # msg("skip $f");
                return;
            }
            if ($no_index && "$f" =~ $no_index) {
                # msg("skip $f, by $no_index");
                return;
            }
            if ("$f" =~ m{^(?:t/|inc/)}) {
                # msg("skip $f, by $no_index");
                return;
            }
            msg("do processing $f");
            my $parser = Pod::POM->new();
            my $pom = $parser->parse_file("$f") or do {
                print $parser->error,"\n";
                return;
            };
            my ($name_section) = map { $_->content } grep { $_->title eq 'NAME' } $pom->head1();
            $name_section =~ s/\n//g;
            msg "name: $name_section";
            my ($pkg, $desc) = ($name_section =~ /^(\S+)\s+-\s*(.+)$/);
            msg "desc: $pkg, $desc";
            unless ($pkg) {
                my $fh = $f->openr or return;
                SCAN: while (my $line = <$fh>) {
                    if ($line =~ /^package\s+([a-zA-Z0-9:]+)/) {
                        $pkg = $1;
                        last SCAN;
                    }
                }
            }
            unless ($pkg) {
                $pkg = "$f";
                $pkg =~ s{^lib/}{};
                $pkg =~ s/\.pm$//;
                $pkg =~ s{/}{::};
            }
            my $html = FrePAN::Pod::POM::View::HTML->print($pom);
            msg "insert $pkg, $f, $desc";
            $c->db->insert(
                file => {
                    dist_id     => $dist->dist_id,
                    path        => $f->relative->stringify,
                    'package'   => $pkg,
                    description => $desc || '',
                    html        => $html,
                }
            );
        }
    );

    $txn->commit;

    chdir $orig_cwd;
}

sub load_meta {
    my $url = shift;
    if (-f 'META.yml') {
        YAML::Tiny::LoadFile('META.yml');
    } elsif (-f 'META.json') {
        decode_json('META.json');
    } else {
        warn "missing META file in $url:".Cwd::getcwd();
        +{};
    }
}

1;
