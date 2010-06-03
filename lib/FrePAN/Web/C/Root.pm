package FrePAN::Web::C::Root;
use strict;
use warnings;
use SQL::Interp qw/sql_interp/;

sub index {
    my ($class, $c) = @_;

    my $page = $c->req->param('page') || 1;
    $page =~ /^[0-9]+$/ or die "bad page number: $page";
    my $rows_per_page = 20;

    my $dbh = $c->db->dbh;
    my $entries = $dbh->selectall_arrayref(
        "SELECT SQL_CACHE dist.dist_id, dist.name, dist.author, dist.version, dist.abstract FROM dist ORDER BY released DESC LIMIT @{[ $rows_per_page + 1 ]} OFFSET @{[ $rows_per_page*($page-1) ]}",
        { Slice => {} }
    );

    # fill email address
    my $pause_id2email = $c->memcached->get_or_set_cb(
        "pause_id2email:2" => 24 * 60 * 60 => sub {
            +{ map { $_->[0] => $_->[1] } @{
                $dbh->selectall_arrayref(
                    q{SELECT pause_id, email FROM meta_author})
              } };
        }
    );
    for my $entry (@$entries) {
        $entry->{email} = $pause_id2email->{$entry->{author}};
    }

    # fill changes
    if (@$entries) {
        my @dist_ids = map { $_->{dist_id} } @$entries;
        my ($sql, @bind) = sql_interp q{SELECT dist_id, body FROM changes WHERE dist_id IN }, \@dist_ids;
        my %rows =
          ( map { $_->[0] => $_->[1] }
              @{ $dbh->selectall_arrayref( $sql, {}, @bind ) } );
        for my $entry (@$entries) {
            $entry->{diff} = $rows{$entry->{dist_id}};
        }
    }

    my $has_next =  ($rows_per_page+1 == @$entries);
    if ($has_next) { pop @$entries }

    my $cpan = $c->get('M::CPAN');
    for (@$entries) {
        $_->{gravatar_url} = $cpan->email2gravatar_url($_->{email});
    }
    return $c->render( "index.tx",
        { dists => $entries, page => $page, has_next => $has_next } );
}

sub about {
    my ($class, $c) = @_;
    $c->render('about.tx');
}

1;
