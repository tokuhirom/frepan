package FrePAN::M::CPANDB::Generator;
use common::sense;
use Amon::Declare;
use IO::Zlib;

sub new {
    my ($class, $args) = @_;
    bless {%$args}, $class;
}

sub mk_author {
    my ($self, ) = @_;

    my $minicpan = model('CPAN')->minicpan;

    my $txn = db->txn_scope();

    my @rows;

    db->dbh->do(q{DROP TABLE IF EXISTS meta_author_old});
    db->dbh->do(q{DROP TABLE IF EXISTS meta_author_tmp});
    db->dbh->do(q{CREATE TABLE meta_author_tmp LIKE meta_author});

    my $insert = sub {
        db->bulk_insert(
            'meta_author_tmp' => \@rows,
        );
        @rows = ();
    };

    my $fh = IO::Zlib->new(File::Spec->catfile($minicpan, 'authors/01mailrc.txt.gz'), "rb") or die "cannot open file";
    while (<$fh>) {
        my ($pauseid, $fullname, $email) = /^alias (\S+)\s*"(.+)<(.+?)>"$/;
        die "cannot parse:$_" unless $email;
        push @rows, {pause_id => $pauseid, fullname => $fullname, email => $email};
        $insert->() if @rows > 1000;
    }
    $insert->() if @rows;

    logger->debug("renaming");
    db->dbh->do(q{RENAME TABLE meta_author TO meta_author_old, meta_author_tmp TO meta_author;});

    $txn->commit;

    logger->debug('done');
}

1;
