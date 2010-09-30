package FrePAN::V::Xslate::Context;
use strict;
use warnings;
use parent 'Exporter';
use Amon2::Declare;
use FrePAN::M::CPAN;

sub import {
    my $class = shift;
    my $pkg = caller(0);
    no strict 'refs';

    *{"$pkg\::has_item"} = sub { defined $_[0]->{$_[1]} };
}

1;
