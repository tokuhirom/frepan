package FrePAN::M::CPANDB;
use common::sense;
use Amon::Declare;

sub new {
    my ($class, $args) = @_;
    bless {%$args}, $class;
}

sub mk_author {
    my ($self, ) = @_;
    my $txn = db->txn_begin();

    my @rows;

    db->dbh->do(q{DROP TABLE IF EXISTS author_old});
    db->dbh->do(q{CREATE TABLE author_tmp LIKE author});

    my $insert = sub {
        db->bulk_insert(
            'author_tmp' => \@rows,
        );
        @rows = ();
    };

    while (<$fh>) {
        my ($pauseid, $fullname, $email) = /^alias (\S+)\s*"([^<]+)<([^>]+)>"/;
        die "cannot parse:$_" unless $email;
        push @rows, {pause_id => $pauseid, fullname => $fullname, email => $email};
        $insert->() if @rows > 1000;
    }
    $insert->() if @rows;

    db->dbh->do(q{RENAME TABLE author_tmp TO author, author TO author_old;});

    $txn->commit;
}

1;
