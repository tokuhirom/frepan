package FrePAN::Worker::ProcessDist;
use strict;
use warnings;
use parent 'TheSchwartz::Worker';
use autodie;

use Algorithm::Diff;
use CPAN::DistnameInfo;
use Carp ();
use Cwd;
use Data::Dumper;
use DateTime;
use File::Basename;
use File::Find::Rule;
use File::Path qw/rmtree make_path mkpath/;
use Guard;
use JSON::XS;
use LWP::UserAgent;
use Path::Class;
use Pod::POM;
use RPC::XML::Client;
use RPC::XML;
use Try::Tiny;
use URI;
use YAML::Tiny;

use Amon2::Declare;

use FrePAN::M::CPAN;
use FrePAN::M::Archive;
use FrePAN::M::RSSMaker;
use FrePAN::Pod::POM::View::HTML;
use FrePAN::Pod::POM::View::Text;

our $DEBUG;
our $PATH;

sub p { use Data::Dumper; warn Dumper(@_) }

sub debug ($) { c->log->debug(@_) }
sub msg { c->log->info(@_) }

sub work {
    my ($class, $job) = @_;
    try {
        $class->_work($job);
        msg "completed!";
        $job->completed();
    } catch {
        c->log->error("Error in $class: $_");
        sleep 1000;
        die $_; # rethrow
    }
}

sub _work {
    my ($class, $job) = @_;
    my $info = decode_json($job->arg);
    print "Run $info->{path} @{[ $job->jobid ]}, @{[ $job->arg ]}\n";
    $info->{released} or die "missing released date";
    c->log->info("worker start: @{[ $job->jobid ]}");

    local $PATH = $info->{path};

    my $c = c();

    my ($author) = ($info->{path} =~ m{^./../([^/]+)/});
    $info->{author} = $author;
    die "cannot detect author: @{[ $job->jobid ]}, @{[ $job->arg ]}" unless $author;

    # fetch archive
    my $archivepath = file(FrePAN::M::CPAN->minicpan_path(), 'authors', 'id', $info->{path})->absolute;
    debug "$archivepath, $info->{path}";
    unless ( -f $archivepath ) {
        $class->mirror($info->{url}, $archivepath);
    }

    # guard.
    my $orig_cwd = Cwd::getcwd();
    guard { chdir $orig_cwd };

    # extract and chdir
    my $srcdir = dir(c->config()->{srcdir}, uc($author));
    debug "extracting $archivepath to $srcdir";
    $srcdir->mkpath;
    die "cannot mkpath '$srcdir': $!" unless -d $srcdir;
    chdir($srcdir);
    my $distnameinfo = CPAN::DistnameInfo->new($info->{path});
    FrePAN::M::Archive->extract($distnameinfo->distvname, "$archivepath");

    # render and register files.
    my $meta = load_meta($info->{url});
    my $no_index = join '|', map { quotemeta $_ } @{
        do {
            my $x = $meta->{no_index}->{directory} || [];
            $x = [$x] unless ref $x; # http://cpansearch.perl.org/src/CFAERBER/Net-IDN-Nameprep-1.100/META.yml
            $x;
          }
      };
       $no_index = qr/^(?:$no_index)/ if $no_index;
    my $requires = $meta->{requires};

    my $txn = $c->db->txn_scope;

    debug 'creating database entry';
    my $dist = $c->db->find_or_create(
        dist => {
            name    => $info->{name},
            version => $info->{version},
            author  => $info->{author},
        }
    );
    $dist->update(
        {
            path     => $info->{path},
            released => $info->{released},
            requires => scalar($requires ? encode_json($requires) : ''),
            abstract => $meta->{abstract},
            resources_json  => $meta->{resources} ? encode_json($meta->{resources}) : undef,
            has_meta_yml    => ( -f 'META.yml'    ? 1 : 0 ),
            has_meta_json   => ( -f 'META.json'   ? 1 : 0 ),
            has_manifest    => ( -f 'MANIFEST'    ? 1 : 0 ),
            has_makefile_pl => ( -f 'Makefile.PL' ? 1 : 0 ),
            has_changes     => ( -f 'Changes'     ? 1 : 0 ),
            has_change_log  => ( -f 'ChangeLog'   ? 1 : 0 ),
            has_build_pl    => ( -f 'Build.PL'    ? 1 : 0 ),
        }
    );

    # Some dists contains symlinks.
    # symlinks cause deep recursion, or security issue.
    # I should remove it first.
    # e.g. C/CM/CMORRIS/Parse-Extract-Net-MAC48-0.01.tar.gz
    debug 'removing symlinks';
    File::Find::Rule->new()
                    ->symlink()
                    ->exec( sub {
                        msg("unlink symlink $_");
                        unlink $_;
                    } )
                    ->in('.');
    debug 'rendering pod';
    dir('.')->recurse(
        callback => sub {
            my $f = shift;
            return if -d $f;
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
            if ("$f" =~ m{^(?:t/|inc/|sample/|blib/)}) {
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
                $name_section = FrePAN::Pod::POM::View::Text->print($name_section);
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
                    if ($line =~ /^package\s+([a-zA-Z0-9:_]+)/) {
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
    debug 'make diff';
    my $path = FrePAN::M::CPAN->dist2path($dist->name);
    msg("extract old archive to @{[ $path || 'missing meta' ]}(@{[ $dist->name ]})");
    my ($old_changes_file, $old_changes) = get_old_changes($path);
    sub {
        unless ($old_changes) {
            msg "old changes not found";
            return;
        }
        msg "old changes exists";
        my ($new_changes_file) = grep { -f $_ } qw/Changes ChangeLog/;
        unless ($new_changes_file) {
            msg "missing new changes file";
            return;
        }
        $new_changes_file = Cwd::abs_path($new_changes_file);
        my $new_changes = read_file($new_changes_file);
        unless ($new_changes) {
            msg "new changes not found";
            return;
        }
        msg "new changes exists";
        msg "diff -u $old_changes_file $new_changes_file";
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
    }->();

    # regen rss
    debug 'regenerate rss';
    FrePAN::M::RSSMaker->generate();

    unless ($DEBUG) {
        debug 'sending ping';
        my $result = $class->send_ping();
        c->log->error(ref($result) ? $result->value : "Error: $result");
    }

    debug 'commit';
    $txn->commit;

    chdir $orig_cwd;

    debug "finished job";
}

sub send_ping {
    my $result =
        RPC::XML::Client->new('http://ping.feedburner.com/')
        ->send_request( 'weblogUpdates.ping',
        "Yet Another CPAN Recent Changes",
        "http://frepan.64p.org/" );
    return $result;
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
    my $srcdir = dir(c->config()->{srcdir}, uc($author));
    make_path($srcdir, {error => \my $err});
    die "cannot mkpath '$srcdir', '$author', '$path': $err" unless -d $srcdir;
    chdir($srcdir);

    my $distnameinfo = CPAN::DistnameInfo->new($path);
    FrePAN::M::Archive->extract($distnameinfo->distvname, "$path");
    my @files = File::Find::Rule->new()
                                ->name('Changes', 'ChangeLog')
                                ->in(Cwd::getcwd());
    if (@files && $files[0]) {
        my $res = read_file($files[0]);
        chdir $orig_cwd;
        return ($files[0], $res);
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
    Carp::croak("missing args for read_file($PATH)") unless $fname;
    open my $fh, '<', $fname;
    do { local $/; <$fh> };
}

sub load_meta {
    my $url = shift;
    if (-f 'META.json') {
        try {
            open my $fh, '<', 'META.json';
            my $src = do { local $/; <$fh> };
            decode_json($src);
        } catch {
            warn "cannot open META.json file: $_";
            +{};
        };
    } elsif (-f 'META.yml') {
        try {
            YAML::Tiny::LoadFile('META.yml');
        } catch {
            warn "Cannot parse META.yml($url): $_";
            +{};
        };
    } else {
        c->log->info("missing META file in $url:".Cwd::getcwd());
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
