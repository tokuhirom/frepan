use strict;
use warnings;
use FrePAN;
use DBIx::Skinny::Schema::Loader qw/make_schema_at/;
use FindBin;

my $c = FrePAN->bootstrap;
my $conf = $c->config->{'DB'};

my $schema = make_schema_at( 'FrePAN::DB::Schema', {}, $conf );
my $dest = File::Spec->catfile($FindBin::Bin, '..', 'lib', 'FrePAN', 'DB', 'Schema.pm');
open my $fh, '>', $dest or die "cannot open file '$dest': $!";
print {$fh} $schema;
close $fh;
