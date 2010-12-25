use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use FrePAN;
use FrePAN::DB;
use FrePAN::M::Injector;
use FrePAN::M::FriendFeed;
use CPAN::DistnameInfo;

my $url = 'http://search.cpan.org/CPAN/authors/id/T/TO/TOKUHIROM/App-cpanoutdated-0.13.tar.gz';
my $info = CPAN::DistnameInfo->new($url);
my $released = time;
my $name = $info->dist;
my $version = $info->version;
my $path = join( '/',
    substr( $info->cpanid, 0, 1 ),
    substr( $info->cpanid, 0, 2 ),
    $info->cpanid, $info->filename );

my $c = FrePAN->bootstrap();

local $FrePAN::M::Injector::DEBUG = 1;

FrePAN::M::Injector->inject(
    name     => $name,
    version  => $version,
    path     => $path,
    author   => $info->cpanid,
    released => $released,
    force    => 1,
);

exit;

