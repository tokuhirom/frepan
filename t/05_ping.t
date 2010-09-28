use strict;
use warnings;
use Test::More;
use FrePAN::Worker::ProcessDist;

my $result = FrePAN::Worker::ProcessDist->send_ping();
ok ref $result;
note "ERR: $result" unless ref $result;

done_testing;

