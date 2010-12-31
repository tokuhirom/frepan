package FrePAN::M::Formatter;
use strict;
use warnings;
use utf8;
use Smart::Args;

sub format {
    args_pos my $src;
    $src =~ s!\n!<br />!g;
    return $src;
}

1;
