package FrePAN::M::CPAN;
use strict;
use warnings;
use Gravatar::URL qw/gravatar_url/;
use DBI;

sub new { bless {}, shift }

my $db = DBI->connect('dbi:SQLite:dbname=/usr/local/minicpan/db/cpandb.sql', '', '') or die;

sub pause_id2gravatar_url {
    my ($class, $pause_id) = @_;
    my $sth = $db->prepare(q{select email from auths where cpanid=?;});
    $sth->execute($pause_id) or die "cannot execute";
    my ($email) = $sth->fetchrow_array();
    if ($email) {
        return gravatar_url(email => $email);
    } else {
        warn "cannot detect";
        return;
    }
}

1;
