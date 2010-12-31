#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use FrePAN;
use FrePAN::M::Remover;

my $c = FrePAN->bootstrap;

FrePAN::M::Remover->run(c => $c);

