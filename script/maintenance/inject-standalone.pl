use strict;
use warnings;
use JSON::XS;
use LWP::UserAgent;
use FrePAN;
use FrePAN::DB;
use FrePAN::M::Injector;
use FrePAN::M::FriendFeed;
use CPAN::DistnameInfo;

my $url = shift || 'http://search.cpan.org/CPAN/authors/id/C/CO/CORNELIUS/I18N-Handle-0.051.tar.gz';
my $info = CPAN::DistnameInfo->new($url);
my $name = $info->dist;
my $version = $info->version;
my $path = join( '/',
    substr( $info->cpanid, 0, 1 ),
    substr( $info->cpanid, 0, 2 ),
    $info->cpanid, $info->filename );

my $c = FrePAN->bootstrap();

local $FrePAN::M::Injector::DEBUG = 1;

my $released = do {
    my $d = $c->db->single(dist => {name => $name, version => $version, author => $info->cpanid});
    $d ? $d->released : time();
};

FrePAN::M::Injector->inject(
    name     => $name,
    version  => $version,
    path     => $path,
    author   => $info->cpanid,
    released => $released,
    force    => 1,
);

exit;

