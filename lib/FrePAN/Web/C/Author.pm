package FrePAN::Web::C::Author;
use strict;
use warnings;
use SQL::Interp qw/:all/;

sub show {
    my ($class, $c, $args) = @_;
    my $pause_id = $args->{author};
    return $c->redirect_metacpan('/author/' . uc($pause_id));
}

1;
