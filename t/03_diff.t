use strict;
use warnings;
use Test::More;
use t::Util;
use FrePAN::M::Injector;

my $new = <<'...';
foo
bar
baz
...

my $old = <<'...';
bar
baz
...

my $diff = FrePAN::M::Injector::make_diff(
    $old, $new
);

is $diff, "foo\n";

done_testing;
