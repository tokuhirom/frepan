package FrePAN::M::CPANDB::Generator;
use common::sense;
use Amon::Declare;
use IO::Zlib;
use CPAN::DistnameInfo;

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

sub mk_packages {
    my ($self, ) = @_;

    my $minicpan = model('CPAN')->minicpan;

    my $txn = db->txn_scope();

    my @rows;

    db->dbh->do(q{DROP TABLE IF EXISTS meta_packages_old});
    db->dbh->do(q{DROP TABLE IF EXISTS meta_packages_tmp});
    db->dbh->do(q{CREATE TABLE meta_packages_tmp LIKE meta_packages});

    my $insert = sub {
        db->bulk_insert(
            'meta_packages_tmp' => \@rows,
        );
        @rows = ();
    };

    my $fh = IO::Zlib->new(File::Spec->catfile($minicpan, 'modules/02packages.details.txt.gz'), "rb") or die "cannot open file";
    while (<$fh>) {
        last unless /\S/; # strip header lines.
    }
    while (<$fh>) {
        my %row;
        @row{qw/package version path/} = split /\s+/, $_;
        my $dist = CPAN::DistnameInfo->new($row{path});
        $row{pause_id}     = $dist->cpanid;
        $row{dist_name}    = $dist->dist;
        $row{dist_version} = $dist->version;
        $row{path} =~ s!^./../!!; # remove duplicated stuff
        push @rows, \%row;
        $insert->() if @rows > 1000;
    }
    $insert->() if @rows;

    logger->debug("renaming");
    db->dbh->do(q{RENAME TABLE meta_packages TO meta_packages_old, meta_packages_tmp TO meta_packages;});

    $txn->commit;

    logger->debug('done');
}

1;
