#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use feature qw(say switch state unicode_strings);
use FrePAN;
use SQL::Interp ':all';
use Log::Minimal;
use DBI;
use Sub::Throttle qw/throttle/;

my $dbpath = shift or die;
my $c = FrePAN->bootstrap;
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbpath", '', '', {RaiseError => 1}) or die;
my $offset=0;
while (1) {
    my $sth = $dbh->prepare(qq{SELECT * FROM cpanstats ORDER BY id DESC LIMIT 1000 OFFSET $offset});
    $sth->execute();
    infof("inserting %s", $offset);
    my $inserted;
    throttle(0.1, sub {
        my $txn = $c->db->txn_scope;
        while (my $row = $sth->fetchrow_hashref('NAME_lc')) {
            my ($sql, @bind) = sql_interp(q{REPLACE INTO cpanstats }, {
                guid     => $row->{guid},
                postdate => $row->{postdate},
                tester   => $row->{tester},
                state    => $row->{state},
                dist     => $row->{dist},
                version  => $row->{version},
                platform => $row->{platform},
                osname   => $row->{osname},
                osvers   => $row->{osvers},
                perl     => $row->{perl},
                date     => $row->{date},
            });
            debugf("%s, %s", $sql, ddf(\@bind));
            $c->dbh->do($sql, {}, @bind);
            $inserted++;
        }
        $txn->commit;
    });
    last unless $inserted;
    $offset += 1000;
}

