package FrePAN::Web::C::Author;
use Amon::Web::C;

sub show {
    my ($class, $pause_id) = @_;
    $pause_id = uc($pause_id);

    my $author = db->single( meta_author => { pause_id => $pause_id } )
      or return res_404();

    my $iter = db->search_by_sql(q{
        select
            pkg.dist_name, MAX(pkg.dist_version) AS dist_version, DATE_FORMAT(FROM_UNIXTIME(upl.released), '%Y-%m-%d') AS released, dist.abstract
        from
            meta_packages as pkg
            left join meta_uploads as upl on (pkg.dist_name=upl.dist_name AND pkg.pause_id=upl.pause_id)
            left join dist on (dist.name = pkg.dist_name AND dist.version=pkg.dist_version AND dist.author=pkg.pause_id)
        where
            pkg.pause_id=?
        GROUP BY
            pkg.dist_name
        ORDER BY
            pkg.dist_name
    }, [$pause_id]);

    render('author/show.mt', $author, $iter);
}

1;
