#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature qw(say switch state unicode_strings);
use FrePAN;
use FrePAN::M::CPAN::Testers;

my $c = FrePAN->bootstrap;
FrePAN::M::CPAN::Testers->fetch_all(c => $c);

