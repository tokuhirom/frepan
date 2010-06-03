package FrePAN::Web::C::Author;
use strict;
use warnings;
use SQL::Interp qw/:all/;

sub show {
    my ($class, $c, $args) = @_;
    my $pause_id = $args->{author};

    my $author = $c->db->single( meta_author => { pause_id => $pause_id } )
      or return $c->res_404();

    my $packages = $c->db->dbh->selectall_arrayref(q{
        select dist_name, MAX(dist_version) AS dist_version from meta_packages where pause_id=? GROUP BY dist_name;
    }, {Slice => {}}, $pause_id);

    # fill release date
    my ( $sql, @bind ) = sql_interp(
        q{SELECT dist_name, DATE_FORMAT(FROM_UNIXTIME(MAX(released)), '%Y-%m-%d') AS released FROM meta_uploads WHERE pause_id=}, \$pause_id, q{ AND dist_name IN },
        [ map { $_->{dist_name} } @$packages ],
        q{ GROUP BY dist_version}
    );
    my %released_for = map { $_->[0] => $_->[1] } @{$c->db->dbh->selectall_arrayref($sql, {}, @bind)};
    for my $pkg (@$packages) {
        $pkg->{released} = $released_for{$pkg->{dist_name}};
    }

    # fill abstract

#   my $iter = db->search_by_sql(q{
#       select
#           pkg.dist_name, MAX(pkg.dist_version) AS dist_version, DATE_FORMAT(FROM_UNIXTIME(upl.released), '%Y-%m-%d') AS released, dist.abstract
#       from
#           meta_packages as pkg
#           left join meta_uploads as upl on (pkg.dist_name=upl.dist_name AND pkg.pause_id=upl.pause_id)
#           left join dist on (dist.name = pkg.dist_name AND dist.version=pkg.dist_version AND dist.author=pkg.pause_id)
#       where
#           pkg.pause_id=?
#       GROUP BY
#           pkg.dist_name
#       ORDER BY
#           pkg.dist_name
#   }, [$pause_id]);

    $c->render('author/show.tx', {author => $author, packages => $packages});
}

1;
