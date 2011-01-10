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
use RPC::XML::Client;
use RPC::XML;
use Try::Tiny;
use URI;
use YAML::Tiny;
use Smart::Args;
use Log::Minimal;
use FrePAN::DB::Row::File;
use FrePAN::CwdSaver;

use Amon2::Declare;

use FrePAN::M::CPAN;
use FrePAN::M::Archive;
use FrePAN::M::RSSMaker;
use FrePAN::Pod;

our $DEBUG;

sub inject {
    args my $class,
         my $path => 'Str',
         my $released => {isa => 'Int'},  # in epoch time
         my $name => 'Str',
         my $version => 'Str',
         my $author => 'Str',
         my $force => {default => 0, isa => 'Bool'},
         ;
    infof("Run $path");

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

    debugf 'creating database entry';
    my $dist = $c->db->find_or_create(
        dist => {
            name    => $name,
            version => $version,
            author  => $author,
        }
    );
    $dist->set_columns({
        path     => $path,
        released => $released,
    });

    # fetch archive
    $dist->mirror_archive();

    # extract and chdir
    my $extracted_dir = $dist->extract_archive();
    infof("extracted directory is: $extracted_dir");

    debugf 'removing symlinks';
    $class->remove_symlinks(dir => $extracted_dir);

    my $guard = FrePAN::CwdSaver->new($extracted_dir);

    # render and register files.
    my $meta = $dist->load_meta(dir => $extracted_dir);

    $c->db->do(q{UPDATE dist SET old=1 WHERE name=?}, {}, $name);

    my $requires = $meta->{requires};
    $dist->set_columns(
        {
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
            old             => 0,
        }
    );
    $dist->update();

    debugf 'generating file table';
    $dist->insert_files(
        meta     => $meta,
        dir      => $extracted_dir,
        c        => $c,
    );

    debugf("register to groonga");
    $dist->insert_to_fts();

    # save changes
    debugf 'make diff';
    $class->make_changes_diff(c => $c, dist => $dist);


    # regen rss
    debugf 'regenerate rss';
    FrePAN::M::RSSMaker->generate();

    unless ($DEBUG) {
        debugf 'sending ping';
        my $result = $class->send_ping();
        critf(ref($result) ? ddf($result->value) : "Error: $result");
    }

    debugf 'commit';
    $txn->commit;

    debugf "finished job";
}

sub make_changes_diff {
    args my $class,
        my $dist,
        my $c,
        ;

    my $old = $dist->last_release();
    unless ($old) {
        infof("cannot retrieve last_release info");
        return;
    }

    my $old_changes = $old->get_changes();
    my $new_changes = $dist->get_changes();

    my $diff = do {
        if ($old_changes && $new_changes) {
            infof("make diff");
            make_diff($old_changes, $new_changes);
        } elsif ($old_changes) {
            infof("old changes file is available");
            $old_changes
        } elsif ($new_changes) {
            infof("missing old changes: %s(%d)", $old->name, $old->dist_id);
            $new_changes;
        } else {
            infof("no changes file is available");
            "no changes file";
        }
    };
    debugf("diff is : %s", ddf($diff));
    $c->db->do(q{INSERT INTO changes (dist_id, version, body) VALUES (?,?,?)
                    ON DUPLICATE KEY UPDATE body=?}, {}, $dist->dist_id, $dist->version, $diff, $diff);
}

sub send_ping {
    my $result =
        RPC::XML::Client->new('http://ping.feedburner.com/')
        ->send_request( 'weblogUpdates.ping',
        "Yet Another CPAN Recent Changes",
        "http://frepan.org/" );
    return $result;
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

sub remove_symlinks {
    args my $class,
         my $dir,
         ;

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
                    ->in($dir);
}

1;
