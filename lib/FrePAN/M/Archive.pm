package FrePAN::M::Archive;
use strict;
use warnings;
use autodie;
use Archive::Tar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use Try::Tiny;
use Amon2::Declare;
use File::Path qw/remove_tree mkpath make_path/;
use Smart::Args;
use FrePAN::CwdSaver;
use Archive::Tar::Constant ();
use Path::Class;
use Log::Minimal;

# $distvname should be "$dist-$ver"
sub extract {
    args my $class,
         my $distvname,
         my $archive_path,
         my $srcdir,
         my $author,
         ;

    my $author_dir = dir($srcdir, uc($author));

    # validation
    File::Spec->file_name_is_absolute($author_dir)
      or die "archive path is not absolute.";

    make_path($author_dir);
    die "cannot create directory: $!: $author_dir" unless -d $author_dir;

    my $pkgdir = dir($author_dir, $distvname);
    $pkgdir->rmtree(); # cleanup before extract
    $pkgdir->mkpath();

    if ($archive_path =~ /\.(?:tar|tar\.gz|tar\.bz2|tbz|tgz)$/) {
        local $Archive::Tar::CHMOD = 0;
        local $Archive::Tar::CHOWN = 0;

        my $iter = Archive::Tar->iter( $archive_path, 1);
        while (my $file = $iter->()) {
            next unless $file->type ~~ [Archive::Tar::Constant::DIR, Archive::Tar::Constant::FILE];
            next if $file->name =~ /\.\./; # directory travarsal
            next if $file->name =~ /\0/; # WTF

            my $name = $file->name;
            $name =~ s!^$distvname/?!!;
            $name = dir($pkgdir, $name);
            infof("extract %s to %s", $file->name, $name);
            $file->extract($name);
        }
    } elsif ($archive_path =~ /\.zip$/) {
        my $zip = Archive::Zip->new();
        unless ( $zip->read( $archive_path ) == AZ_OK ) {
            die "Cannot read zip file: '$archive_path'";
        }

        my @members = $zip->members;
        die "empty archive: $archive_path" unless @members;
        for my $member (@members) {
            my $name = $member->fileName();
            $name =~ s!^$distvname/?!!;
            $name = dir($pkgdir, $name);
            infof("extract %s to %s", $member->fileName, $name);

            $member->extractToFileNamed("$name") == AZ_OK
              or die "Cannot extract $name in '$archive_path'";
        }
    } else {
        die "unknown archive type: $archive_path";
    }
    return $pkgdir;
}

1;
