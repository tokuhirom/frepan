package FrePAN::CwdSaver;
use strict;
use warnings;
use utf8;
use autodie;
use Cwd;

sub new {
    my ($class, $dir) = @_;
    my $orig_dir = Cwd::getcwd();
    chdir $dir;
    bless \$orig_dir, $dir;
}
sub DESTROY {
    my $self = shift;
    chdir $$self;
}

1;

