use strict;
use warnings;
use utf8;
use Test::More;

use FrePAN2;

my $c = FrePAN2->new();
isa_ok $c->cache, 'Cache::FileCache';
$c->run();

done_testing;

