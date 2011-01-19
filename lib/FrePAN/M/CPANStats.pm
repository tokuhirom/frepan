use strict;
use warnings;
use utf8;

package FrePAN::M::CPANStats;
use Smart::Args;
use List::MoreUtils qw/uniq/;

sub search_for_dist {
    args my $class,
         my $c,
         my $dist_name => 'Str',
         my $dist_version => 'Str',
         ;

    my $rows = $c->dbh->selectall_arrayref(q{
        SELECT osname, perl, state, platform
        FROM cpanstats
        WHERE dist=? AND version=?
    }, {Slice => {}}, $dist_name, $dist_version);
    return $rows;
}

1;

