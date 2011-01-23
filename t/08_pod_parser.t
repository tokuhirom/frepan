use strict;
use warnings;
use utf8;
use Test::More;
use File::Temp;
use FrePAN::Pod;

my $tmp = File::Temp->new();

my $parser = FrePAN::Pod->new();
$parser->parse_file($tmp->filename) or die;
unlike $parser->html(), qr/<html>/;
unlike $parser->html(), qr{</html>};
is length($parser->html()), 0;

done_testing;

