#!/usr/lcoal/bin/perl
use strict;
use warnings;
use FindBin::libs;
use FrePAN;
use FrePAN::M::RSSMaker;

my $c = FrePAN->bootstrap();

FrePAN::M::RSSMaker->generate();

