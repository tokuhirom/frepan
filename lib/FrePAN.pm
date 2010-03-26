package FrePAN;
use Amon -base;
use DBI;

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

1;
