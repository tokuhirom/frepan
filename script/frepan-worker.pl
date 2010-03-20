use strict;
use warnings;
use FrePAN;
use Gearman::Worker;
use LWP::UserAgent;
use Parallel::Prefork;
use JSON::XS;
use File::Temp qw/tempdir/;
use autodie;
use Pod::Usage;
use Getopt::Long;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, '..', 'lib');
use FrePAN::Worker;
use FrePAN::Worker::ProcessDist;

our $VERSION = '0.01';
warn "$0 $VERSION\n";

GetOptions(
    'v|verbose' => \my $verbose,
);
$FrePAN::Worker::VERBOSE=1 if $verbose;

my ($c);

my $config_file = shift @ARGV or pod2usage();
warn "loading config file $config_file\n";
my $config = do $config_file or die;

my $pm = Parallel::Prefork->new(
    {
        max_workers  => 1,
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
            USR1 => undef,
        }
    }
);
while ( $pm->signal_received ne 'TERM' ) {
    $pm->start and next;

    $c = FrePAN->bootstrap(config => $config);
    print "ready for run $$\n";
    my $worker = $c->get('Gearman::Worker');
    $worker->register_function( 'frepan/add_dist' => sub {
        my $data = decode_json($_[0]->arg);
        FrePAN::Worker::ProcessDist->run( $data );
    });
    $worker->work while 1;

    $pm->finish;
}

$pm->wait_all_children();
exit;

__END__

=head1 SYNOPSIS

    % frepan-worker.pl config.pl

