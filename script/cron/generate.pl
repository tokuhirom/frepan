#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;

use FindBin::libs;
use FrePAN2;

my $c = FrePAN2->new();
$c->run();

