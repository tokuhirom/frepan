package FrePAN::M::Injector;
use strict;
use warnings;
use autodie;

use FrePAN::FTS;
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
use Pod::POM::View::Text;
use RPC::XML::Client;
use RPC::XML;
use Try::Tiny;
use URI;
use YAML::Tiny;
use Smart::Args;
use Log::Minimal;
use FrePAN::DB::Row::File;

use Amon2::Declare;

use FrePAN::M::CPAN;
use FrePAN::M::Archive;
use FrePAN::M::RSSMaker;
use FrePAN::Pod::POM::View::HTML;
use FrePAN::Pod::POM::View::Text;

our $DEBUG;
our $PATH;

sub p { warn "DEPRECATED" }

sub inject {
    args my $class,
         my $path => 'Str',
         my $released => {isa => 'Int'},  # in epoch time
         my $name => 'Str',
         my $version => 'Str',
         my $author => 'Str',
         my $force => {default => 0, isa => 'Bool'},
         ;
    infof("Run $path \n");

    local $PATH = $path;

    my $c = c();

    # transaction
    my $txn = $c->db->txn_scope;

    {
        my $dist = $c->db->single(
            dist => {
                name    => $name,
                version => $version,
                author  => $author,
            },
        );
        if ($dist && !$force) {
            infof("already processed: $name, $version, $author");
            $txn->rollback();
            return;
        }
    }

    # fetch archive
    my $archivepath = file(FrePAN::M::CPAN->minicpan_path(), 'authors', 'id', $path)->absolute;
    debugf "$archivepath, $path";
    unless ( -f $archivepath ) {
        my $url = 'http://cpan.cpantesters.org/authors/id/' . $path;
        $class->mirror($url, $archivepath);
    }

    # guard.
    my $orig_cwd = Cwd::getcwd();
    guard { chdir $orig_cwd };

    # extract and chdir
    my $srcdir = dir(c->config()->{srcdir}, uc($author));
    debugf "extracting $archivepath to $srcdir";
    $srcdir->mkpath;
    die "cannot mkpath '$srcdir': $!" unless -d $srcdir;
    chdir($srcdir);
    my $distnameinfo = CPAN::DistnameInfo->new($path);
    FrePAN::M::Archive->extract($distnameinfo->distvname, "$archivepath");

    # render and register files.
    my $meta = $class->load_meta(dir => $srcdir);
    my $requires = $meta->{requires};


    debugf 'creating database entry';
    my $dist = $c->db->find_or_create(
        dist => {
            name    => $name,
            version => $version,
            author  => $author,
        }
    );
    $dist->update(
        {
            path     => $path,
            released => $released,
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
    debugf 'removing symlinks';
    File::Find::Rule->new()
                    ->symlink()
                    ->exec( sub {
                        debugf("unlink symlink $_");
                        unlink $_;
                    } )
                    ->in('.');

    debugf 'generating file table';
    $class->insert_files(
        meta     => $meta,
        dir      => '.',
        c        => $c,
        dist     => $dist,
    );

    debugf("register to groonga");
    $dist->insert_to_fts();

    # save changes
    debugf 'make diff';
    my $local_path = FrePAN::M::CPAN->dist2path($dist->name);
    debugf("extract old archive to @{[ $local_path || 'missing meta' ]}(@{[ $dist->name ]})");
    my ($old_changes_file, $old_changes) = get_old_changes($local_path);
    sub {
        unless ($old_changes) {
            debugf "old changes not found";
            return;
        }
        debugf "old changes exists";
        my ($new_changes_file) = grep { -f $_ } qw/CHANGES Changes ChangeLog/;
        unless ($new_changes_file) {
            debugf "missing new changes file";
            return;
        }
        $new_changes_file = Cwd::abs_path($new_changes_file);
        my $new_changes = read_file($new_changes_file);
        unless ($new_changes) {
            debugf "new changes not found";
            return;
        }
        debugf "new changes exists";
        debugf "diff -u $old_changes_file $new_changes_file";
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
    debugf 'regenerate rss';
    FrePAN::M::RSSMaker->generate();

    unless ($DEBUG) {
        debugf 'sending ping';
        my $result = $class->send_ping();
        critf(ref($result) ? $result->value : "Error: $result");
    }

    debugf 'commit';
    $txn->commit;

    chdir $orig_cwd;

    debugf "finished job";
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
        infof("cannot get path for old Changes file");
        return;
    }
    unless ( -f $path ) {
        warnf("[warn]file not found: $path");
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
    args my $class,
         my $dir,
    ;

    my $guard = CwdSaver->new($dir);

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
            warn "Cannot parse META.yml($dir): $_";
            +{};
        };
    } else {
        infof("missing META file in $dir");
        +{};
    }
}

sub mirror {
    my ($self, $url, $dstpath) = @_;

    debugf "mirror '$url' to '$dstpath'";
    my $ua = LWP::UserAgent->new(agent => "FrePAN/$FrePAN::VERSION");
    make_path($dstpath->dir->stringify, {error => \my $err});
    if (@$err) {
        for my $diag (@$err) {
            my ( $file, $message ) = %$diag;
            print "mkpath: error: '@{[ $file || '' ]}', $message\n";
        }
    }
    my $res = $ua->get($url, ':content_file' => "$dstpath");
    $res->code =~ /^(?:304|200)$/ or die "fetch failed: $url, $dstpath, " . $res->status_line;
}

{
    package CwdSaver;
    use autodie;
    use Cwd;

    sub new {
        my ($class, $dir) = @_;
        my $orig_dir = Cwd::getcwd();
        chdir $dir;
        bless \$orig_dir, $dir;
    }
    sub DESTROY {
        my $self = shift;
        chdir $$self;
    }
}

# insert to 'file' table.
sub insert_files {
    args my $class,
         my $meta,
         my $dir,
         my $c,
         my $dist => {isa => 'FrePAN::DB::Row::Dist'},
         ;

    my $txn = $c->db->txn_scope();

    my $no_index = join '|', map { quotemeta $_ } @{
        do {
            my $x = $meta->{no_index}->{directory} || [];
            $x = [$x] unless ref $x; # http://cpansearch.perl.org/src/CFAERBER/Net-IDN-Nameprep-1.100/META.yml
            $x;
          }
      };
       $no_index = qr/^(?:$no_index)/ if $no_index;

    # remove old things
    $c->db->dbh->do(q{DELETE FROM file WHERE dist_id=?}, {}, $dist->dist_id) or die;

    my $guard = CwdSaver->new($dir);

    dir('.')->recurse(
        callback => sub {
            my $f = shift;
            return if -d $f;
            debugf("processing $f");

            unless ($f =~ /(?:\.pm|\.pod)$/) {
                my $fh = $f->openr or return;
                read $fh, my $buf, 1024;
                if ($buf !~ /#!.+perl/) { # script contains shebang
                    return;
                }
            }
            if ($no_index && "$f" =~ $no_index) {
                return;
            }
            if ("$f" =~ m{^(?:t/|inc/|sample/|blib/)}) {
                return;
            }
            debugf("do processing $f");
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
                debugf "name: $name_section";
                ($pkg, $desc) = ($name_section =~ /^(\S+)\s+-\s*(.+)$/);
                if ($pkg) {
                    # workaround for Graph::Centrality::Pagerank
                    $pkg =~ s/[CB]<(.+)>/$1/;
                }
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
                if ($pkg =~ /\.pm$/) {
                    $pkg =~ s!/!::!g;
                    $pkg =~ s!^lib/!!g;
                    $pkg =~ s!\.pm$!!g;
                }
            }

            {
                my $html = FrePAN::Pod::POM::View::HTML->print($pom);

                my $path = $f->relative->stringify;
                $c->db->insert(
                    file => {
                        dist_id     => $dist->dist_id,
                        path        => $path,
                        'package'   => $pkg,
                        description => $desc || '',
                        html        => $html,
                    }
                );
            }
        }
    );

    $txn->commit;

    return;
}

1;
