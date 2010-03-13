package FrePAN::Pod::POM::View::Text;
use strict;
use warnings;
use parent qw( Pod::POM::View::Text );

sub view_seq_link {
    my ( $self, $link ) = @_;
    if ( $link =~ s/^.*?\|// ) {
        return $link;
    }
    else {
        return $link;
    }
}

1;
