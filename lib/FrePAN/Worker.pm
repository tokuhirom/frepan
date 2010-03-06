package FrePAN::Worker;
use strict;
use warnings;
use base qw/Exporter/;

our @EXPORT = qw/msg/;

our $VERBOSE;

sub msg {
    print "@_\n" if $VERBOSE;
}

sub import {
    strict->import;
    warnings->import;
    __PACKAGE__->export_to_level(1);
}

1;
