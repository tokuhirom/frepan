package FrePAN::M::CPAN;
use strict;
use warnings;
use Gravatar::URL qw/gravatar_url/;
use DBI;

sub new {
    my ($class, $args) = @_;
    my $dbh = DBI->connect( $args->{dsn}, $args->{username}, $args->{password} )
      or die "cannot connect db";
    bless { minicpan => $args->{minicpan}, dbh => $dbh }, $class;
}

sub dbh { $_[0]->{dbh} }

sub pause_id2gravatar_url {
    my ($self, $pause_id) = @_;
    my $sth = $self->dbh->prepare(q{select email from auths where cpanid=?;});
    $sth->execute($pause_id) or die "cannot execute";
    my ($email) = $sth->fetchrow_array();
    if ($email) {
        return gravatar_url(email => $email);
    } else {
        warn "cannot detect";
        return;
    }
}

sub dist2path {
    my ($self, $distname) = @_;
    warn $distname;
    my $sql = "SELECT auths.cpanid, dists.dist_file FROM dists, auths WHERE dist_name=? AND auths.auth_id=dists.auth_id;";
    my $sth = $self->dbh->prepare($sql);
    $sth->execute($distname) or die "cannot execute";
    my ($cpanid, $distfile) = $sth->fetchrow_array();
    if ($cpanid && $distfile) {
        return File::Spec->catfile(
            $self->{minicpan},
            'authors', 'id',
            substr($cpanid, 0, 1),
            substr($cpanid, 0, 2),
            $cpanid,
            $distfile,
        );
    } else {
        return;
    }
}

1;
