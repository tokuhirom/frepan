#!/usr/lcoal/bin/perl
use strict;
use warnings;
use FindBin::libs;
use FrePAN;

my $c=FrePAN->bootstrap(config=>do"config.pl");
print $c->model("RSSMaker")->generate(), $/;

