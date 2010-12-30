package FrePAN::Web::C::Perldoc;
use strict;
use warnings;
use utf8;

sub redirect {
    my ($class, $c) = @_;
    my $package = $c->req->env->{QUERY_STRING};
    my ($author, $name, $version, $path) = $c->dbh->selectrow_array(q{SELECT dist.author, dist.name, dist.version, file.path FROM file INNER JOIN dist ON (file.dist_id = dist.dist_id) WHERE package=? ORDER BY file.dist_id DESC LIMIT 1}, {}, $package);
    if (defined $author) {
        return $c->redirect("/~$author/$name-$version/$path");
    } else {
        return $c->res_404();
    }
}

1;

