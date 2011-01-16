package FrePAN::M::CPAN::Testers;
use strict;
use warnings;
use utf8;
use Smart::Args;
use LWP::UserAgent;
use Path::Class;
use Log::Minimal;

# fetch all data from http://devel.cpantesters.org/release/release.db.bz2
# @return none
sub fetch_all {
    args my $class,
         my $c,
         ;

    my $url = 'http://devel.cpantesters.org/cpanstats.db.bz2';
    my $fname = file($c->minicpan_dir, 'cpanstats.db.bz2');
    my $ua = LWP::UserAgent->new(agent => "FrePAN/$FrePAN::VERSION");
    infof("download '%s' to '%s'", $url, $fname);
    $ua->mirror($url, $fname);
    system("bunzip2", $fname)==0 or die $!;
    $fname =~ s/\.bz2$//;
    my $dbh = DBI->connect("dbi:SQLite:dbname=$fname", '', '', {RaiseError => 1}) or die "Cannot connect to database: $DBI::errstr";
}

1;

