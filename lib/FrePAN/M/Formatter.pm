package FrePAN::M::Formatter;
use strict;
use warnings;
use utf8;
use Smart::Args;
use Text::Xslate::Util qw/mark_raw html_escape/;

sub format {
    args_pos my $src;
    $src = html_escape($src);
    $src =~ s!\n!<br />!g;
    return mark_raw($src);
}

1;
