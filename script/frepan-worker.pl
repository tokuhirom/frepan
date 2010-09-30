use strict;
use warnings;
use FrePAN;
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
use FrePAN::Worker::ProcessDist;
use Try::Tiny;
use Amon2::Declare;
use FrePAN::M::Archive;

select STDOUT;$|++;

our $VERSION = '0.01';
warn "$0 $VERSION\n";

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

    my $c = FrePAN->bootstrap();
    print "ready for run $$\n";
    my $worker = $c->create_schwartz();
    $worker->can_do('FrePAN::Worker::ProcessDist');
    my $worked  = 0;
    while ($worked < 1000) {
        if ($worker->work_once()) {
            print "worked!\n";
            $worked++;
        } else {
            # print "sleep\n";
            sleep 1;
        }
    }
    print "restart $$\n";

    $pm->finish;
}

$pm->wait_all_children();
exit;

__END__

=head1 SYNOPSIS

    % frepan-worker.pl

