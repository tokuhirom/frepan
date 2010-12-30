package FrePAN::Web::C::Dist;
use strict;
use warnings;
use String::CamelCase qw/decamelize/;
use JSON::XS qw/decode_json/;
use Smart::Args;

# show distribution meta data
sub show {
    my ($class, $c, $args) = @_;
    my $author = $args->{author}
        or die;
    my $dist_ver = $args->{dist_ver}
        or die;

    my $dist = $c->dbh->selectrow_hashref(
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
    ) or return $c->res_404();
    $dist->{resources}    = decode_json($dist->{resources_json}) if $dist->{resources_json};
    $dist->{gravatar_url} = FrePAN::M::CPAN->email2gravatar_url($dist->{email});
    $dist->{download_url} = FrePAN::M::CPAN->download_url($dist->{path}, $dist->{released});

    $dist->{files} = $c->dbh->selectall_arrayref(
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

    my $other_releases = $c->db->dbh->selectall_arrayref(
        q{SELECT dist_id, dist.author, dist.name, dist.version, DATE_FORMAT(FROM_UNIXTIME(released), '%Y-%m-%d') AS released_date FROM dist WHERE dist_id != ? AND name=? ORDER BY released DESC},
        {Slice => {}},
        $dist->{dist_id}, $dist->{name}
    );

    return $c->render("dist/show.tx", {dist => $dist, special_files => \@special_files, other_releases => $other_releases});
}

# show pod
sub show_file {
    my ($class, $c, $args) = @_;
    my $author = $args->{author};
    my $dist_ver = $args->{dist_ver};
    my $path = $args->{path};

    my $dist = $c->dbh->selectrow_hashref(
        q{select dist_id, author, name, version from dist where concat(name, '-', version) = ? AND author=?  ORDER BY dist_id DESC LIMIT 1},
        {},
        $dist_ver, uc($author)
    ) or return $c->res_404();

    my $file = $c->dbh->selectrow_hashref(
        'select * from file where dist_id=? AND path=? order by file_id DESC LIMIT 1',
        {},
        $dist->{dist_id},
        $path,
    ) or return $c->res_404();

    $c->render("dist/show_file.tx", {dist => $dist, file => $file});
}

# other version
sub other_version {
    my ($class, $c) = @_;

    my $dist_id = $c->req->param('dist_id') // die "missing mandatory parameter: dist_id";
    my $dist = $c->db->single(dist => {dist_id => $dist_id}) // return $c->res_404();
    return $c->redirect($dist->relative_url());
}

1;
