use strict;
use warnings;
use utf8;

package FrePAN::M::IUseThis;
use Amon2::Declare;

sub get_ranking {
    my $ranking = c->dbh->selectall_arrayref(
        q{SELECT dist.name, dist.version, dist.author, COUNT(*) AS cnt
         FROM i_use_this
            INNER JOIN dist ON (dist.name=i_use_this.dist_name AND old=0)
         GROUP BY dist_name
         ORDER BY cnt DESC
         LIMIT 30}, {Slice => +{}}
    );
	return $ranking;
}

1;

