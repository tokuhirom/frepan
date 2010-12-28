#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use FrePAN;

my $c = FrePAN->bootstrap;
$c->fts->setup();

