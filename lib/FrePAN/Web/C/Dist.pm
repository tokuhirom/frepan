package FrePAN::Web::C::Dist;
use Amon::Web::C;

sub _get_dist {
    my ($author, $dist_ver) = @_;
    my $iter = db->search_by_sql(
        q{select * from dist where concat(name, '-', version) = ? AND author=?  ORDER BY dist_id DESC LIMIT 1},
        [$dist_ver, uc($author)]
    );
    return $iter->first;
}

sub show {
    my ($class, $c, $args) = @_;
    my $author = $args->{author}
        or die;
    my $dist_ver = $args->{dist_ver}
        or die;

    my $dbh = db->dbh;
    my $sth = $dbh->prepare(
        q{
            SELECT
                dist_id, author, name, version, path, abstract, repository, homepage, bugtracker, license, has_meta_yml, has_meta_json, has_manifest, has_makefile_pl, has_changes, has_change_log, has_build_pl, requires, released, DATE_FORMAT(FROM_UNIXTIME(released), '%Y-%m-%d') AS released_date, meta_author.email
            FROM dist LEFT JOIN meta_author ON (meta_author.pause_id = dist.author)
            WHERE concat(name, '-', version) = ? AND author=?
            ORDER BY dist_id DESC
            LIMIT 1
        },
    );
    $sth->execute($dist_ver, uc($author)) or die $dbh->errstr;

    my $dist = $sth->fetchrow_hashref
        or return res_404();
    $dist->{gravatar_url} = model('CPAN')->email2gravatar_url($dist->{email});
    $dist->{download_url} = model('CPAN')->download_url($dist->{path}, $dist->{released});
    my @files = db->search(
        file => {
            dist_id => $dist->{dist_id},
        },
        {
            order_by => [ {package => 'ASC'} ],
        }
    );
    $dist->{files} = \@files;
    render("dist/show.mt", $dist);
}

sub show_file {
    my ($class, $c, $args) = @_;
    my $author = $args->{author};
    my $dist_ver = $args->{dist_ver};
    my $path = $args->{path};

    my $dist = do {
        my $iter = db->search_by_sql(
            q{select * from dist where concat(name, '-', version) = ? AND author=?  ORDER BY dist_id DESC LIMIT 1},
            [$dist_ver, uc($author)]
        );
        $iter->first;
    };
    return res_404() unless $dist;

    my $file = db->single(
        file => {
            dist_id => $dist->dist_id,
            path    => $path,
        },
        {
            order_by => [ { file_id => 'DESC' } ],
            limit    => 1,
        }
    );

    render("dist/show_file.mt", $dist, $file);
}

1;
