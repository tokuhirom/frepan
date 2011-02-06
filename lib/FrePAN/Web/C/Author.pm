package FrePAN::Web::C::Author;
use strict;
use warnings;
use SQL::Interp qw/:all/;

sub show {
    my ($class, $c, $args) = @_;
    my $pause_id = $args->{author};

    my $author = $c->db->single( meta_author => { pause_id => $pause_id } )
      or return $c->res_404();

    my $packages = $c->dbh->selectall_arrayref(q{
        select SQL_CACHE name, MAX(version) AS version, DATE_FORMAT(FROM_UNIXTIME(MAX(released)), '%Y-%m-%d') AS released from dist where author=? GROUP BY name;
    }, {Slice => {}}, $pause_id);

    $c->render2(
        '#title' => $author->fullname . ' - FrePAN',
        '#Content' => [
            'author/show.tx',
            {author => $author, packages => $packages}
        ]
    );
}

1;
