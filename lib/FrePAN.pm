package FrePAN;
use strict;
use warnings;
use parent qw/Amon2/;
use DBI;
use Cache::Memcached::Fast;

use Amon2::Config::Simple;
sub load_config { Amon2::Config::Simple->load(shift) }

our $VERSION = '0.01';

use FrePAN::DB;
sub db {
    my ($c, ) = @_;
    $c->{db} //= do {
        my $conf = $c->config->{'DB'} // die;
        FrePAN::DB->new($conf);
    };
}

sub memcached {
    my ($c) = @_;
    my $conf = $c->config->{'Cache::Memcached::Fast'} // die "missing configuration for Cache::Memcached::Fast";
    Cache::Memcached::Fast->new($conf);
}

sub Cache::Memcached::Fast::get_or_set_cb {
    my ($self, $key, $expire, $cb) = @_;
    my $data = $self->get($key);
    return $data if defined $data;
    $data = $cb->();
    $self->set($key, $data, $expire) or Carp::carp("Cannot set $key to memcached
");
    return $data;
}


1;
