package FrePAN;
use Amon -base;
use DBI;
use Cache::Memcached::Fast;

our $VERSION = '0.01';

__PACKAGE__->add_factory(
    'TheSchwartz::Simple' => sub {
        my ($c, $klass, $conf) = @_;
        require TheSchwartz::Simple;
        my @dbhs = map {
            DBI->connect( $_->{dsn}, $_->{user}, $_->{pass}, )
              or die $DBI::errstr;
        } @{ $c->config->{'TheSchwartz'}->{databases} };
        return TheSchwartz::Simple->new(\@dbhs);
    },
);

__PACKAGE__->add_factory(
    'TheSchwartz' => sub {
        my ($c, $klass, $conf) = @_;
        require TheSchwartz;
        return TheSchwartz->new(%$conf);
    },
);

__PACKAGE__->add_factory(
    'Cache::Memcached::Fast' => sub {
        my ($c, $klass, $conf) = @_;
        return Cache::Memcached::Fast->new($conf);
    },
);

sub memcached { $_[0]->get('Cache::Memcached::Fast') }

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
