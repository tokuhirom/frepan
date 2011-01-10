#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Web::Scraper;
use Log::Minimal;
use URI;
use 5.10.1;

my $s = scraper {
    process 'a' => 'links[]' => '@href';
}->scrape(URI->new('http://friendfeed.com/cpan'));
my @u = grep m{^http://cpan}, map { $_->as_string } @{$s->{links}};
for (@u) {
    say qq{sudo -u frepan sh -c 'PLACK_ENV=production /usr/local/app/perl/bin/perl -Ilib script/maintenance/inject-standalone.pl $_'};
}
