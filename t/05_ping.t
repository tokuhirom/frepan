use strict;
use warnings;
use Test::More;
use t::Util;
use FrePAN::M::Injector;

my $result = FrePAN::M::Injector->send_ping();
ok ref $result;
note "ERR: $result" unless ref $result;

done_testing;

