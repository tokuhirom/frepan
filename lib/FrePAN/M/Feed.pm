use strict;
use warnings;
use utf8;

package FrePAN::M::Feed;
use Smart::Args;
use FrePAN::TimeDuration qw/ago/;

sub recent {
    args my $class,
        my $rows_per_page => {default => 20, isa => 'Int'},
        my $current_page => {isa => 'Int'},
        my $c,
        ;

    my $entries = $c->dbh->selectall_arrayref(
        "SELECT SQL_CACHE
            dist.dist_id, dist.name, dist.author, dist.version, dist.abstract, dist.released,
            meta_author.gravatar_id,
            changes.body AS diff
        FROM dist
            LEFT JOIN meta_author ON (dist.author=meta_author.pause_id)
            LEFT JOIN changes     ON (dist.dist_id=changes.dist_id)
        ORDER BY released DESC
        LIMIT @{[ $rows_per_page + 1 ]} OFFSET @{[ $rows_per_page*($current_page-1) ]}",
        { Slice => {} }
    );
    my $has_next =  ($rows_per_page+1 == @$entries);
    if ($has_next) { pop @$entries }

    my $now = time();
    for (@$entries) {
        $_->{timestamp} = ago($_->{released});
    }
    return ($entries, $has_next);
}

1;

