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
@meth = qw/packages author uploads/ unless @meth;

my $c = FrePAN->bootstrap();

print "running $0\n";

for my $meth (map { "mk_$_" } @meth) {
    print "running $meth\n";
    FrePAN::M::CPANDB::Generator->$meth;
}

print "finished\n";

