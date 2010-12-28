#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;
use Log::Minimal;

my $DEBUG = $ENV{DEBUG};

my $c = FrePAN->bootstrap;
my $page = 1;
my $rows = 1000;
my $inserted = 1;
while (1) {
    infof("retrieving page: $page");
    # retrieve from old entries first.
    my @dists = $c->db->search('dist', {}, {order_by => {'dist_id' => $DEBUG ? 'DESC' : 'ASC'}, limit => $rows, offset => $rows*($page-1)});
    last unless @dists;

    for my $dist (@dists) {
        infof("inserted: %d", $inserted++);
        $dist->insert_to_fts();
    }

    last if $DEBUG;

    $page++;
}

