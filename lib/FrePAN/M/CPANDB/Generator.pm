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
use Log::Minimal;
use Digest::MD5 qw/md5_hex/;

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

# fetch permission information and insert it to db
sub mk_perms {
    my ($self, ) = @_;

    my $url = 'http://cpan.yimg.com/modules/06perms.txt';
    my $ua = LWP::UserAgent->new();
    my $fname = catfile(minicpan, 'modules/06perms.txt');
    my $res = $ua->get($url, ':content_file' => $fname);
    $res->is_success or die $res->status_line;

    open my $fh, '<', $fname or die "Cannot open file : $fname";

    # skip headers
    while (<$fh>) {
        last unless /\S/;
    }

    $self->_swap(
        'perms' => sub {
            my $rows = shift;
            chomp;

            while (<$fh>) {
                my %row;
                @row{qw/package pause_id permission/} = split /,/, $_;
                $rows->push(\%row);
                $rows->insert() if $rows->count() > 1000;
            }
        }
    );
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
                        pause_id    => uc($pauseid),
                        fullname    => $fullname,
                        email       => $email,
                        gravatar_id => md5_hex(lc($pauseid) . '@cpan.org'),
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
            my $fname = File::Spec->catfile( minicpan,
                'modules/02packages.details.txt.gz' );
            my $fh = IO::Zlib->new( $fname, "rb" )
              or die "cannot open file: $fname";
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

    debugf("start uploads");
    my $url = 'http://devel.cpantesters.org/uploads/uploads.db.bz2';
    my $ua = LWP::UserAgent->new();
    my $bz2 = catfile(minicpan, 'modules/uploads.db.bz2');
    my $res = $ua->get($url, ':content_file' => $bz2);
    $res->is_success or die "$url: " . $res->status_line;
    (my $db = $bz2) =~ s/\.bz2//;
    unlink($db) if -f $db;
    system('bunzip2', $bz2)==0 or die "cannot bunzip2: $bz2";
    my $dbh = DBI->connect("dbi:SQLite:dbname=$db", '', '') or die "cannot open database";
    my $sth = $dbh->prepare('SELECT type, author, dist, version, filename, released FROM uploads');
    $sth->execute();

    $self->_swap(
        'uploads' => sub {
            my $rows = shift;
            while (my ($type, $author, $dist, $version, $filename, $released) = $sth->fetchrow_array()) {
                $rows->push(
                    {
                        type         => $type,
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

    debugf("creating $table");

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
    use Log::Minimal;
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
        debugf('insert');
        my ($sql, @binds) = c->dbh->sql_maker->insert_multi(
            $self->{table} => $self->{rows},
        );
        $sql =~ s/^INSERT/REPLACE/;
        c->dbh->do($sql, {}, @binds);
        @{$self->{rows}}= ();
    }
}

1;
