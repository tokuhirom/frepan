#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.10.1;
use Jonk::Worker;
use FrePAN;
use Log::Minimal;
use Try::Tiny;
use Sub::Throttle qw/throttle/;

my $c = FrePAN->bootstrap;
my $jonk = Jonk::Worker->new($c->dbh, {functions => [qw/regen/]});
while (1) {
    my $txn = $c->db->txn_scope();
    if (my $job = $jonk->dequeue()) {
        throttle(0.1, sub {
            infof("got job: %s", ddf($job));
            given ($job->{func}) {
                when ('regen') {
                    my $dist_id = $job->{arg} // die;
                    eval {
                        dispatch_regen($dist_id);
                    };
                    if($@) {
                        if ($@ =~ /404 Not Found/) {
                            # skip
                            infof("got 404: %s", $@);
                        } else {
                            die $@;
                        }
                    }
                }
                default {
                    die "FATAL"
                }
            }
            $txn->commit;
        });
    } else {
        $txn->rollback;
        debugf('sleep');
        sleep 1;
    }
}

sub dispatch_regen {
    my $dist_id = shift;

    my $dist = $c->db->single('dist' => {dist_id => $dist_id}) // do {
        warnf("dist not found: %d", $dist_id);
        return;
    };
    unless ($dist->version) {
        warnf("This distribution doesn't have a version number...");
        return;
    }
    $dist->mirror_archive();
    my $extracted_dir = $dist->extract_archive();
    my $meta = $dist->load_meta(dir => $extracted_dir);
    $dist->insert_files(
        meta     => $meta,
        dir      => $extracted_dir,
        c        => $c,
    );
    $dist->insert_to_fts();
}

