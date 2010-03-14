use strict;
use warnings;
use FrePAN;
use Getopt::Long;

my @meth;
GetOptions(
    'packages' => sub { push @meth, 'packages' },
    'uploads'  => sub { push @meth, 'uploads' },
    'author'   => sub { push @meth, 'author' },
);
@meth = qw/packages uploads author/ unless @meth;

my $conf = shift;
$conf = do $conf;
my $c = FrePAN->bootstrap(config => $conf);

for my $meth (map { "mk_$_" } @meth) {
    $c->model('CPANDB::Generator')->$meth;
}

