package FrePAN::M::CPANDB::Generator;
use strict;
use warnings;
use Amon2::Declare;
use IO::Zlib;
use CPAN::DistnameInfo;
use LWP::UserAgent;
use File::Spec::Functions qw/catfile/;
use version ();
use Try::Tiny;

sub new {
    my ($class, ) = @_;
    bless {}, $class;
}

{
    my $mc;
    sub minicpan () {
        $mc ||= c->config->{'M::CPAN'}->{minicpan};
    }
}

sub mk_author {
    my ($self, ) = @_;

    $self->_swap(
        'author' => sub {
            my $rows = shift;
            my $fh = IO::Zlib->new(File::Spec->catfile(minicpan, 'authors/01mailrc.txt.gz'), "rb") or die "cannot open file";
            while (<$fh>) {
                my ($pauseid, $fullname, $email) = /^alias (\S+)\s*"(.+)<(.+?)>"$/;
                die "cannot parse:$_" unless $email;
                $rows->push(
                    {
                        pause_id => uc($pauseid),
                        fullname => $fullname,
                        email    => $email
                    }
                );
                $rows->insert() if $rows->count() > 1000;
            }
        }
    );
}

sub mk_packages {
    my ($self, ) = @_;

    $self->_swap(
        'packages' => sub {
            my $rows = shift;
            my $fh = IO::Zlib->new(File::Spec->catfile(minicpan, 'modules/02packages.details.txt.gz'), "rb") or die "cannot open file";
            while (<$fh>) {
                last unless /\S/; # strip header lines.
            }
            while (<$fh>) {
                my %row;
                @row{qw/package version path/} = split /\s+/, $_;
                my $dist = CPAN::DistnameInfo->new($row{path});
                $row{pause_id}     = uc($dist->cpanid);
                $row{dist_name}    = $dist->dist;
                $row{dist_version} = $dist->version;
                $row{dist_version_numified} = try { version->parse($dist->version)->numify };
                $row{path} =~ s!^./../!!; # remove duplicated stuff
                $rows->push(\%row);
                $rows->insert() if $rows->count() > 10000;
            }
        }
    );
}

sub mk_uploads {
    my ($self) = @_;

    c->log->debug("start uploads");
    my $url = 'http://devel.cpantesters.org/uploads/uploads.db.bz2';
    my $ua = LWP::UserAgent->new();
    my $bz2 = catfile(minicpan, 'modules/uploads.db.bz2');
    my $res = $ua->get($url, ':content_file' => $bz2);
    $res->is_success or die $res->status_line;
    (my $db = $bz2) =~ s/\.bz2//;
    unlink($db) if -f $db;
    system('bunzip2', $bz2)==0 or die "cannot bunzip2: $bz2";
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '') or die "cannot open database";
    my $sth = $dbh->prepare('SELECT author, dist, version, filename, released FROM uploads');
    $sth->execute();

    $self->_swap(
        'uploads' => sub {
            my $rows = shift;
            while (my ($author, $dist, $version, $filename, $released) = $sth->fetchrow_array()) {
                $rows->push(
                    {
                        pause_id     => uc($author),
                        dist_name    => $dist,
                        dist_version => $version,
                        filename     => $filename,
                        released     => $released,
                    }
                );
                $rows->insert() if $rows->count() > 10000;
            }
        }
    );
}

sub _swap {
    my ($self, $table, $cb) = @_;

    c->log->debug("creating $table");

    my $txn = c->db->txn_scope();
    my $dbh = c->db->dbh;
    $dbh->do(qq(DELETE FROM meta_${table}));

    my $rows = FrePAN::M::CPANDB::Generator::Inserter->new("meta_${table}");

    $cb->($rows);
    $rows->insert();

    $txn->commit();
}

{
    package FrePAN::M::CPANDB::Generator::Inserter;
    use Amon2::Declare;
    sub new {
        my ($class, $table) = @_;
        bless {rows => [], table => $table}, $class;
    }
    sub push {
        my ($self, $row) = @_;
        push @{$self->{rows}}, $row;
    }
    sub count { scalar @{$_[0]->{rows}} }
    sub insert {
        my ($self, ) = @_;
        c->log->debug('insert');
        c->db->bulk_insert(
            $self->{table} => $self->{rows},
        );
        @{$self->{rows}}= ();
    }
}

1;
