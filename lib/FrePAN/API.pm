use strict;
use warnings;
use utf8;

package FrePAN::API;
use parent qw/Amon2::Web FrePAN/;

sub args { shift->{args} }

__PACKAGE__->load_plugins('Web::JSON');

use FrePAN::API::Dispatcher;
sub dispatch {
    my $c = shift;
    FrePAN::API::Dispatcher->dispatch($c);
}

1;

