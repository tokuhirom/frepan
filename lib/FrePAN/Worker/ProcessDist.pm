package FrePAN::Worker::ProcessDist;
use FrePAN::Worker;
use File::Basename;
use URI;
use Guard;
use Path::Class;
use autodie;
use Pod::POM;
use FrePAN::Pod::POM::View::HTML;
use YAML::Tiny;
use LWP::UserAgent;
use JSON::XS;
use Cwd;
use DateTime;
use File::Find::Rule;
use Algorithm::Diff;
use XMLRPC::Lite;
use File::Path qw/rmtree make_path mkpath/;
use Carp ();
use Try::Tiny;
use Amon::Declare;
use CPAN::DistnameInfo;

our $DEBUG;

sub p { use Data::Dumper; warn Dumper(@_) }

sub logger () { c->get("Logger") }
sub debug ($) { logger->debug(@_) }

sub run {
    my ($class, $info) = @_;

    my $c = Amon->context;

    my ($author) = ($info->{path} =~ m{^./../([^/]+)/});
    $info->{author} = $author;
    die "cannot detect author: '$info->{path}'" unless $author;

    # fetch archive
    my $archivepath = file($c->model('CPAN')->minicpan, 'authors', 'id', $info->{path})->absolute;
    debug "$archivepath, $info->{path}";
    unless ( -f $archivepath ) {
        $class->mirror($info->{url}, $archivepath);
    }

    # guard.
    my $orig_cwd = Cwd::getcwd();
    guard { chdir $orig_cwd };

    # extract and chdir
    my $srcdir = dir(config()->{srcdir}, uc($author));
    debug "extracting $archivepath to $srcdir";
    $srcdir->mkpath;
    die "cannot mkpath '$srcdir': $!" unless -d $srcdir;
    chdir($srcdir);
    my $distnameinfo = CPAN::DistnameInfo->new($info->{path});
    model('Archive')->extract($distnameinfo->distvname, "$archivepath");

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
            unless ($f =~ /(?:\.pm|\.pod)$/) {
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

    unless ($DEBUG) {
        my $result = XMLRPC::Lite->proxy('http://ping.fc2.com/')
                                ->call(
                                'weblogUpdates.ping',
                                "Yet Another CPAN Recent Changes",
                                "http://cpanrecent.64p.org/index.rss"
                    )->result;
        msg($result->{'message'});
    }


    $txn->commit;

    chdir $orig_cwd;
}

sub get_old_changes {
    my ($path) = @_;
    my $orig_cwd = Cwd::getcwd();
    guard { chdir $orig_cwd };

    unless ($path) {
        msg("cannot get path");
        return;
    }
    unless ( -f $path ) {
        msg("[warn]file not found: $path");
        return;
    }
    my $author = basename(file($path)->dir); # .../A/AU/AUTHOR/Dist-ver.tar.gz
    my $srcdir = dir(config()->{srcdir}, uc($author));
    mkpath($srcdir);
    die "cannot mkpath '$srcdir': $!" unless $srcdir;
    chdir($srcdir);

    my $distnameinfo = CPAN::DistnameInfo->new($path);
    model('Archive')->extract($distnameinfo->distvname, "$path");
    my @files = File::Find::Rule->new()
                                ->name('Changes', 'ChangeLog')
                                ->in($srcdir);
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
        try {
            YAML::Tiny::LoadFile('META.yml');
        } catch {
            warn "Cannot open META.yml($url): $_";
            +{};
        };
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

sub mirror {
    my ($self, $url, $path) = @_;

    msg "mirror '$url' to '$path'";
    my $ua = LWP::UserAgent->new(agent => "FrePAN/$FrePAN::VERSION");
    make_path($path->dir->stringify, {error => \my $err});
    if (@$err) {
        for my $diag (@$err) {
            my ( $file, $message ) = %$diag;
            print "mkpath: error: '@{[ $file || '' ]}', $message\n";
        }
    }
    my $res = $ua->get($url, ':content_file' => "$path");
    $res->code =~ /^(?:304|200)$/ or die "fetch failed: $url, $path, " . $res->status_line;
}

1;
