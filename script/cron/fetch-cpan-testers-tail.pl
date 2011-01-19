#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature qw(say switch state unicode_strings);
use FrePAN;
use CPAN::DistnameInfo;
use SQL::Interp ':all';
use Log::Minimal;

# run this script eash 30 mins

my $url = 'http://metabase.cpantesters.org/tail/log.txt';

my $c = FrePAN->bootstrap;

my $ua  = LWP::UserAgent->new();
my $res = $ua->get($url);
die $res->status_line unless $res->is_success;

# [2011-01-19T15:40:12Z] [Chris Williams (BINGOS)] [pass] [JDHEDDEN/Thread-Queue-2.12.tar.gz] [darwin-2level] [perl-v5.10.1] [674a9f8a-23e2-11e0-afb0-adca6bb533f3] [2011-01-19T15:40:12Z]
my @lines = split /\r?\n/, $res->content;
shift @lines;    # remove header line

for my $line (@lines) {
    my @row;
    while ( $line =~ s/\[([^\]]+)\]// ) {
        push @row, $1;
    }
    my ( $postdate, $tester, $state, $path, $platform, $perl, $guid, $date ) = @row;
    my $distvinfo = CPAN::DistnameInfo->new($path);
    my ($sql, @bind) = sql_interp(q{INSERT IGNORE INTO cpanstats }, {
        guid     => $guid,
        postdate => $postdate,
        tester   => $tester,
        state    => $state,
        dist     => $distvinfo->dist,
        version  => $distvinfo->version,
        platform => $platform,
        perl     => $perl,
        date     => $date,
    });
    debugf("%s, %s", $sql, ddf(\@bind));
    $c->dbh->do($sql, {}, @bind);
}

