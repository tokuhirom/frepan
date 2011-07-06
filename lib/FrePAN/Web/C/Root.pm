package FrePAN::Web::C::Root;
use strict;
use warnings;
use FrePAN::M::Feed;

sub index {
    my ($class, $c) = @_;

    my $page = $c->req->param('page') || 1;
    $page =~ /^[0-9]+$/ or die "bad page number: $page";

    my ( $dists, $has_next ) = FrePAN::M::Feed->recent(
        current_page  => $page,
        rows_per_page => 20,
        c             => $c,
    );

    return $c->render(
        "index.tx",
        { dists => $dists, page => $page, has_next => $has_next }
    );
}

sub about {
    my ($class, $c) = @_;
    $c->render('about.tx');
}

1;
