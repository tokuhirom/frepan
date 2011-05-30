package FrePAN;
use strict;
use warnings;
use parent qw/Amon2/;
use constant is_devel => $ENV{PLACK_ENV} eq 'development' ? 1 : 0;
use DBI;
use Cache::Memcached::Fast;

use Amon2::Config::Simple;
sub load_config { Amon2::Config::Simple->load(shift) }

our $VERSION = '0.01';

use FrePAN::DB;
use FrePAN::DBI;
sub dbh {
    my ($c) = @_;
    $c->{dbh} //= do {
        my $conf = $c->config->{'DB'} // die;
        FrePAN::DBI->connect(@$conf) or die $DBI::errstr;
    };
}

sub db {
    my ($c, ) = @_;
    $c->{db} //= do {
        my $dbh = $c->dbh;;
        FrePAN::DB->new({dbh => $dbh});
    };
}

sub memcached {
    my ($c) = @_;
    my $conf = $c->config->{'Cache::Memcached::Fast'} // die "missing configuration for Cache::Memcached::Fast";
    Cache::Memcached::Fast->new($conf);
}

sub minicpan_dir {
    my $c = shift;
    $c->config->{'M::CPAN'}->{minicpan} // die "missing configuration for minicpan directory";
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

sub web_host { $_[0]->config->{web_host} // die "missing configuration 'web_host'" }

1;
