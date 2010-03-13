package FrePAN::M::CPAN;
use strict;
use warnings;
use parent qw/Class::Accessor::Fast/;
use Gravatar::URL qw/gravatar_url/;
use DBI;
use Path::Class qw/dir file/;
use Amon::Declare qw/db/;
__PACKAGE__->mk_accessors(qw/minicpan/);

sub new {
    my ($class, $args) = @_;
    my $dbh = DBI->connect( $args->{dsn}, $args->{username}, $args->{password} )
      or die "cannot connect db";
    bless { minicpan => $args->{minicpan}, dbh => $dbh }, $class;
}

sub dbh { $_[0]->{dbh} }

sub pause_id2gravatar_url {
    my ($self, $pause_id) = @_;
    my $author = db->single( author => { pause_id => $pause_id } );
    if ($author) {
        return gravatar_url(email => $author->email);
    } else {
        warn "cannot detect";
        return;
    }
}

sub dist2path {
    my ($self, $distname) = @_;
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
