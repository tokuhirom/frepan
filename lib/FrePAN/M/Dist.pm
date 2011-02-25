use strict;
use warnings;
use utf8;

package FrePAN::M::Dist;
use Smart::Args;
use Amon2::Declare;
use JSON::XS ();
require version;

sub get_latest_version {
    args my $class,
         my $name,
         ;
    my $c = c();

    my ($latest) = reverse sort {
        eval { version->parse($a) || 0 } <=> eval { version->parse($b) || 0 }
      } map { @$_ } @{
        $c->dbh->selectall_arrayref( q{SELECT version FROM dist WHERE name=?},
            {}, $name )
      };
    return $latest;
}

sub get {
    args my $class,
         my $dist_name => 'Str',
         my $dist_version => 'Str',
         my $c,
         ;

    my $dist = $c->dbh->selectrow_hashref(
        q{
            SELECT
                dist_id, author, name, version, path, abstract, has_meta_yml, has_meta_json, resources_json, has_manifest, has_makefile_pl, has_changes, has_change_log, has_build_pl, requires, released, authorized, DATE_FORMAT(FROM_UNIXTIME(released), '%Y-%m-%d') AS released_date, meta_author.email, meta_author.gravatar_id
            FROM dist LEFT JOIN meta_author ON (meta_author.pause_id = dist.author)
            WHERE name = ? AND version = ?
            ORDER BY dist_id DESC
            LIMIT 1
        },
        {},
        $dist_name, $dist_version
    ) or return $c->res_404();
    $dist->{resources}    = JSON::XS::decode_json($dist->{resources_json}) if $dist->{resources_json};
    $dist->{download_url} = FrePAN::M::CPAN->download_url($dist->{path}, $dist->{released});

    $dist->{files} = $c->dbh->selectall_arrayref(
        q{
            SELECT
                path, package, description, LENGTH(html) AS has_html, authorized
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

    return $dist;
}

1;

