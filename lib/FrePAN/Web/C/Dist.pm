package FrePAN::Web::C::Dist;
use strict;
use warnings;
use String::CamelCase qw/decamelize/;
use JSON::XS qw/decode_json/;

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

    my $dbh = $c->db->dbh;
    my $dist = $dbh->selectrow_hashref(
        q{
            SELECT
                dist_id, author, name, version, path, abstract, has_meta_yml, has_meta_json, resources_json, has_manifest, has_makefile_pl, has_changes, has_change_log, has_build_pl, requires, released, DATE_FORMAT(FROM_UNIXTIME(released), '%Y-%m-%d') AS released_date, meta_author.email
            FROM dist LEFT JOIN meta_author ON (meta_author.pause_id = dist.author)
            WHERE concat(name, '-', version) = ? AND author=?
            ORDER BY dist_id DESC
            LIMIT 1
        },
        {},
        $dist_ver, uc($author)
    ) or return res_404();
    $dist->{resources} = decode_json($dist->{resources_json}) if $dist->{resources_json};
    $dist->{gravatar_url} = FrePAN::M::CPAN->email2gravatar_url($dist->{email});
    $dist->{download_url} = FrePAN::M::CPAN->download_url($dist->{path}, $dist->{released});

    $dist->{files} = $dbh->selectall_arrayref(
        q{
            SELECT
                path, package, description, LENGTH(html) AS has_html
            FROM
                file
            WHERE
                dist_id = ?
            ORDER BY
                package ASC
        },
        { Slice => {} },
        $dist->{dist_id},
    );

    # detect special files
    my @special_files;
    for my $fname ('MANIFEST', 'Makefile.PL', 'Build.PL', 'Changes', 'ChangeLog', 'META.yml', 'META.json') {
        (my $key = 'has_' . decamelize($fname)) =~ s/[.]/_/g;
        if ($dist->{$key}) {
            push @special_files, $fname;
        }
    }

    return $c->render("dist/show.tx", {dist => $dist, special_files => \@special_files});
}

sub show_file {
    my ($class, $c, $args) = @_;
    my $author = $args->{author};
    my $dist_ver = $args->{dist_ver};
    my $path = $args->{path};

    my $dbh = $c->db->dbh;
    my $dist = $dbh->selectrow_hashref(
        q{select dist_id, author, name, version from dist where concat(name, '-', version) = ? AND author=?  ORDER BY dist_id DESC LIMIT 1},
        {},
        $dist_ver, uc($author)
    ) or return res_404();

    my $file = $dbh->selectrow_hashref(
        'select * from file where dist_id=? AND path=? order by file_id DESC LIMIT 1',
        {},
        $dist->{dist_id},
        $path,
    ) or return res_404();

    $c->render("dist/show_file.tx", {dist => $dist, file => $file});
}

1;
