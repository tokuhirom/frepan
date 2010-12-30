package FrePAN::M::Archive;
use strict;
use warnings;
use autodie;
use Archive::Tar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use Try::Tiny;
use Amon2::Declare;
use File::Path qw/remove_tree mkpath/;
use Smart::Args;
use FrePAN::CwdSaver;

# $distvname should be "$dist-$ver"
sub extract {
    args my $class,
         my $distvname,
         my $archive_path,
         my $author_dir,
         ;

    mkpath($author_dir);
    die "cannot create directory" unless -d $author_dir;

    my $guard = FrePAN::CwdSaver->new($author_dir);
    remove_tree($distvname); # clanup before extract

    if ($archive_path =~ /\.(?:tar|tar\.gz|tar\.bz2|tbz|tgz)$/) {
        local $Archive::Tar::CHMOD = 0;
        local $Archive::Tar::CHOWN = 0;

        my $tar = Archive::Tar->new();
        $tar->read($archive_path);
        index([$tar->list_files]->[0], $distvname) == 0 or do {
            mkdir($distvname) unless -d $distvname;
            chdir($distvname);
        };
        $tar->extract();
    } elsif ($archive_path =~ /\.zip$/) {
        my $zip = Archive::Zip->new();
        unless ( $zip->read( $archive_path ) == AZ_OK ) {
            die "Cannot read zip file: '$archive_path'";
        }
        do {
            my @members = $zip->members;
            die "empty archive: $archive_path" unless @members;
            if (index($members[0], $distvname) != 0) {
                mkdir($distvname) unless -d $distvname;
                chdir($distvname);
            }
        };
        ($zip->extractTree() == AZ_OK) or die "cannot extract archive: $archive_path";
    } else {
        die "unknown archive type: $archive_path";
    }
    chdir($distvname);
    return Cwd::getcwd();
}

1;
