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
use DateTime;
use File::Find::Rule;
use Algorithm::Diff;
use XMLRPC::Lite;
use File::Path qw/rmtree/;
use Carp ();
use Try::Tiny;

sub p { use Data::Dumper; warn Dumper(@_) }

sub run {
    my ($class, $info) = @_;

    my $c = Amon->context;

    my ($author) = ($info->{path} =~ m{^./../([^/]+)/});
    $info->{author} = $author;
    die "cannot detect author: '$info->{path}'" unless $author;

    # fetch archive
    my $ua = LWP::UserAgent->new(agent => "FrePAN/$FrePAN::VERSION");
    my ($x, $y, $suffix) = fileparse(URI->new($info->{url})->path, qw/zip tar.gz tar.bz2/);
    msg "suffix: $suffix";
    my $tmp = File::Temp->new(UNLINK => 1, SUFFIX => ".$suffix");
    my $res = $ua->get($info->{url}, ':content_file' => "$tmp");
    $res->code =~ /^(?:304|200)$/ or die "fetch failed: $info->{url}, " . $res->status_line;

    # guard.
    my $orig_cwd = Cwd::getcwd();

    # extract and chdir
    my $tmpdir = tempdir(CLEANUP => 0);
    guard { rmtree($tmpdir) };
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

    my $dist = $c->db->find_or_create(
        dist => {
            name    => $info->{name},
            version => $info->{version},
            author  => $info->{author},
        }
    );
    $dist->update({
        path     => $info->{path},
        requires => $requires ? encode_json( $requires ) : '',
        abstract => $meta->{abstract},
    });

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
            if ("$f" =~ m{^(?:t/|inc/|sample/)}) {
                # msg("skip $f, by $no_index");
                return;
            }
            msg("do processing $f");
            my $parser = Pod::POM->new();
            my $pom = $parser->parse_file("$f") or do {
                print $parser->error,"\n";
                return;
            };
            my ($pkg, $desc);
            my ($name_section) = map { $_->content } grep { $_->title eq 'NAME' } $pom->head1();
            if ($name_section) {
                $name_section =~ s/\n//g;
                msg "name: $name_section";
                ($pkg, $desc) = ($name_section =~ /^(\S+)\s+-\s*(.+)$/);
                if ($pkg) {
                    # workaround for Graph::Centrality::Pagerank
                    $pkg =~ s/[CB]<(.+)>/$1/;
                }
                # msg "desc: $pkg, $desc";
            }
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
                $pkg =~ s{/}{::}g;
            }
            my $html = FrePAN::Pod::POM::View::HTML->print($pom);
            # msg "insert $pkg, $f, $desc";
            {
                my $path = $f->relative->stringify;
                my $file_row = $c->db->find_or_create(
                    file => {
                        dist_id     => $dist->dist_id,
                        path        => $path,
                    }
                );
                $file_row->update({
                    'package'   => $pkg,
                    description => $desc || '',
                    html        => $html,
                });
            }
        }
    );

    # save changes
    my $path = $c->model('CPAN')->dist2path($dist->name);
    my $old_changes = get_old_changes($path);
    if ($old_changes) {
        msg "old changes exists";
        my ($new_changes_file) = grep { -f $_ } qw/Changes ChangeLog/;
        my $new_changes = read_file($new_changes_file);
        if ($new_changes) {
            msg "new changes exists";
            my $diff = make_diff($old_changes, $new_changes);
            my $changes = $c->db->find_or_create(
                changes => {
                    dist_id => $dist->dist_id,
                    version => $dist->version,
                }
            );
            $changes->update({
                body => $diff
            });
        } else {
            msg "new changes not found";
        }
    } else {
        msg "old changes not found";
    }

    # regen rss
    $c->model('RSSMaker')->generate();

    my $result = XMLRPC::Lite->proxy('http://ping.fc2.com/')
                              ->call(
                              'weblogUpdates.ping',
                              "Yet Another CPAN Recent Changes",
                              "http://cpanrecent.64p.org/index.rss"
                 )->result;
    msg($result->{'message'});


    $txn->commit;

    chdir $orig_cwd;
}

sub get_old_changes {
    my ($path) = @_;
    my $orig_cwd = Cwd::getcwd();

    unless ($path) {
        msg("cannot get path");
        return;
    }
    unless ( -f $path ) {
        msg("file not found: $path");
        return;
    }
    my $tmpdir = tempdir( CLEANUP => 0 );
    guard { rmtree($tmpdir) };

    my $ae = Archive::Extract->new(archive => $path);
    $ae->extract(to => $tmpdir) or die $ae->error();
    my @files = File::Find::Rule->new()
                                ->name('Changes', 'ChangeLog')
                                ->in($tmpdir);
    if (@files && $files[0]) {
        my $res = read_file($files[0]);
        chdir $orig_cwd;
        return $res;
    } else {
        chdir $orig_cwd;
        return;
    }
}

sub make_diff {
    my ($old, $new) = @_;
    my $res = '';
    my $diff = Algorithm::Diff->new(
        [ split /\n/, $old ],
        [ split /\n/, $new ],
    );
    $diff->Base(1);
    while ($diff->Next()) {
        next if $diff->Same();
        $res .= "$_\n" for $diff->Items(2);
    }
    return $res;
}

sub write_file {
    my ($fname, $content) = @_;
    open my $fh, '>', $fname;
    print {$fh} $content;
    close $fh;
}

sub read_file {
    my ($fname) = @_;
    Carp::croak("missing args for read_file") unless $fname;
    open my $fh, '<', $fname;
    do { local $/; <$fh> };
}

sub load_meta {
    my $url = shift;
    if (-f 'META.yml') {
        YAML::Tiny::LoadFile('META.yml');
    } elsif (-f 'META.json') {
        try {
            open my $fh, '<', 'META.json';
            my $src = do { local $/; <$fh> };
            decode_json($src);
        } catch {
            warn "cannot open META.json file: $_";
            +{};
        };
    } else {
        warn "missing META file in $url:".Cwd::getcwd();
        +{};
    }
}

1;
