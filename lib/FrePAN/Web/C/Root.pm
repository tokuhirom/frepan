package FrePAN::Web::C::Root;
use strict;
use warnings;
use SQL::Interp qw/sql_interp/;
use FrePAN::M::CPAN;
use Time::Duration;

sub index {
    my ($class, $c) = @_;

    my $page = $c->req->param('page') || 1;
    $page =~ /^[0-9]+$/ or die "bad page number: $page";
    my $rows_per_page = 20;

    my $entries = $c->dbh->selectall_arrayref(
        "SELECT SQL_CACHE
            dist.dist_id, dist.name, dist.author, dist.version, dist.abstract, dist.released,
            meta_author.gravatar_id,
            changes.body AS diff
        FROM dist
            LEFT JOIN meta_author ON (dist.author=meta_author.pause_id)
            LEFT JOIN changes     ON (dist.dist_id=changes.dist_id)
        ORDER BY released DESC
        LIMIT @{[ $rows_per_page + 1 ]} OFFSET @{[ $rows_per_page*($page-1) ]}",
        { Slice => {} }
    );
    my $has_next =  ($rows_per_page+1 == @$entries);
    if ($has_next) { pop @$entries }

    my $now = time();
    for (@$entries) {
        $_->{timestamp}    = Time::Duration::ago($now - $_->{released}, 1);
    }
    return $c->render( "index.tx",
        { dists => $entries, page => $page, has_next => $has_next } );
}

sub about {
    my ($class, $c) = @_;
    $c->render('about.tx');
}

1;
