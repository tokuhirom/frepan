#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;
use FrePAN::M::Injector;
use Log::Minimal;
use Jonk::Client;

my $c = FrePAN->bootstrap();
my $jonk = Jonk::Client->new($c->dbh);

my $iter = $c->db->search('dist' => {  }, {order_by => {dist_id => 'DESC'}});
my $i;
while (my $dist = $iter->next) {
    my $dist_id = $dist->dist_id;
    infof("regen $dist_id") if $i++ %1000==0;
    $jonk->enqueue('regen' => $dist_id);
}

