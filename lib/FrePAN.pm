package FrePAN;
use Amon -base;

our $VERSION = '0.01';

__PACKAGE__->add_factory(
    'Gearman::Client' => sub {
        my ($c, $klass, $conf) = @_;
        require Gearman::Client;
        Gearman::Client->new(%$conf);
    },
);

__PACKAGE__->add_factory(
    'Gearman::Worker' => sub {
        my ($c, $klass, $conf) = @_;
        require Gearman::Worker;
        Gearman::Worker->new(%$conf);
    },
);

1;
