package FrePAN;
use strict;
use warnings;
use parent qw/Amon2/;
use DBI;
use Cache::Memcached::Fast;

__PACKAGE__->load_plugins(qw/ConfigLoader LogDispatch/);

our $VERSION = '0.01';

use FrePAN::DB;
sub db {
    my ($c, ) = @_;
    $c->{db} //= do {
        my $conf = $c->config->{'DB'} // die;
        FrePAN::DB->new($conf);
    };
}

sub create_schwartz_simple {
    my $c = shift;

    require TheSchwartz::Simple;
    my @dbhs = map {
        DBI->connect( $_->{dsn}, $_->{user}, $_->{pass}, )
            or die $DBI::errstr;
    } @{ $c->config->{'TheSchwartz'}->{databases} };
    return TheSchwartz::Simple->new(\@dbhs);
}

sub create_schwartz {
    my ($c) = @_;
    require TheSchwartz;
    my $conf = $c->config->{'TheSchwartz'} // die;
    return TheSchwartz->new(%$conf);
}

sub memcached {
    my ($c) = @_;
    my $conf = $c->config->{'Cache::Memcached::Fast'} // die;
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
