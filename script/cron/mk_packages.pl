use strict;
use warnings;
use FrePAN;

my $conf = shift;
$conf = do $conf;
my $c = FrePAN->bootstrap(config => $conf);

$c->model('CPANDB::Generator')->mk_packages;
