use strict;
use warnings;
use Test::More;
use FrePAN::M::Injector;
use t::Util;

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
