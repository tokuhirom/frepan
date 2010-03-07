use strict;
use warnings;
use Test::More;
use FrePAN::Worker::ProcessDist;

my $new = <<'...';
foo
bar
baz
...

my $old = <<'...';
bar
baz
...

my $diff = FrePAN::Worker::ProcessDist::make_diff(
    $old, $new
);

is $diff, "foo\n";

done_testing;
