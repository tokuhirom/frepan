package FrePAN::Web::C::Admin;
use strict;
use warnings;
use utf8;
use Jonk::Client;

sub regen {
    my ($class, $c) = @_;

    my $dist_id = $c->req->param('dist_id') // die;

    my $jonk = Jonk::Client->new($c->dbh);
    $jonk->enqueue('regen' => $dist_id);
    return $c->create_response(200, [], ['OK']);
}

1;

