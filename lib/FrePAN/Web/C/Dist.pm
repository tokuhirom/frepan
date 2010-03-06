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
    my ($class, $author, $dist_ver) = @_;

    my $dist = _get_dist($author, $dist_ver);
    $dist->{gravatar_url} = model('CPAN')->pause_id2gravatar_url($dist->author);
    if ($dist) {
        my @files = db->search(
            file => {
                dist_id => $dist->dist_id,
            },
            {
                order_by => [ {package => 'ASC'} ],
            }
        );
        render("dist/show.mt", $dist, \@files);
    } else {
        warn 'not found';
        res_404();
    }
}

sub show_file {
    my ($class, $author, $dist_ver, $path) = @_;
    my $dist = _get_dist($author, $dist_ver);
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
