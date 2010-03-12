package FrePAN::M::Archive;
use strict;
use warnings;
use autodie;
use Archive::Tar;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use File::Spec;
use Try::Tiny;
use Amon::Declare;

sub new { bless {}, shift }

# $distvname should be "$dist-$ver"
sub extract {
    my ($self, $distvname, $path) = @_;

    if ($path =~ /\.tar/) {
        my $tar = Archive::Tar->new();
        $tar->read($path);
        index([$tar->list_files]->[0], $distvname) == 0 or do {
            mkdir($distvname) unless -d $distvname;
            chdir($distvname);
        };
        $tar->extract();
    } elsif ($path =~ /\.zip$/) {
        my $zip = Archive::Zip->new();
        unless ( $zip->read( $path ) == AZ_OK ) {
            die "Cannot read zip file: '$path'";
        }
        do {
            my @members = $zip->members;
            die "empty archive: $path" unless @members;
            if (index($members[0], $distvname) != 0) {
                mkdir($distvname);
                chdir($distvname);
            }
        };
        ($zip->extractTree() == AZ_OK) or die "cannot extract archive: $path";
    } else {
        die "unknown archive type: $path";
    }
    try { chdir($distvname); }
}

1;
