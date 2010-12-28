package FrePAN::Util;
use strict;
use warnings;
use utf8;
use parent qw/Exporter/;

our @EXPORT = qw/html2text/;

sub html2text {
    my ($html) = @_;

    require HTML::TreeBuilder;
    require HTML::FormatText;

    my $tree      = HTML::TreeBuilder->new_from_content($html);
    my $formatter = HTML::FormatText->new( leftmargin => 0, rightmargin => 50 );
    my $text      = $formatter->format($tree);
    $tree = $tree->delete;
    return $text;
}

1;

