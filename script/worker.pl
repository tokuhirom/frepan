#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.10.1;
use Jonk::Worker;
use FrePAN;
use Log::Minimal;

my $c = FrePAN->bootstrap;
my $jonk = Jonk::Worker->new($c->dbh, {functions => [qw/regen/]});
while (1) {
    if (my $job = $jonk->dequeue()) {
        infof("got job: %s", ddf($job));
        given ($job->{func}) {
            when ('regen') {
                my $dist_id = $job->{arg} // die;
                my $dist = $c->db->single('dist' => {dist_id => $dist_id}) // die "unknown dist";
                my $extracted_dir = $dist->extract_archive();
                my $meta = $dist->load_meta(dir => $extracted_dir);
                $dist->insert_files(
                    meta     => $meta,
                    dir      => $extracted_dir,
                    c        => $c,
                    dist     => $dist,
                );
                unless ($dist->old) {
                    $dist->insert_to_fts();
                }
            }
            default {
                die "FATAL"
            }
        }
    } else {
        debugf('sleep');
        sleep 1;
    }
}

