#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Web::Query;
use 5.010001;

for (grep m{^http://cpan},
  map { $_->attr('href') } wq('http://friendfeed.com/cpan')->find('a')) {
    say qq{perl -Ilib script/maintenance/inject-standalone.pl $_};
}
