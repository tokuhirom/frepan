#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;
use Log::Minimal;

my $c = FrePAN->bootstrap();

my $iter = $c->db->search('dist', {}, {order_by => {'dist_id' => 'DESC'}});
my $n=0;
while (my $dist = $iter->next) {
    $c->db->do(q{UPDATE dist SET old=1 WHERE name=? AND dist_id < ?}, {}, $dist->name, $dist->dist_id);

    print "$n\n" if $n++ % 1000 == 0;
}

