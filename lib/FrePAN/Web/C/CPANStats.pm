use strict;
use warnings;
use utf8;

package FrePAN::Web::C::CPANStats;
use FrePAN::M::CPANStats;

sub list {
    my ($class, $c) = @_;

    my $dist_vname = $c->args->{dist_vname} // die;
    my ($name, $version) = CPAN::DistnameInfo::distname_info($dist_vname);
    my $data = FrePAN::M::CPANStats->search_for_dist(
        dist_name    => $name,
        dist_version => $version,
        c            => $c,
    );

    return $c->render2(
        title => $dist_vname,
        '#Content' => [
            'cpanstats/list.tx',
            { rows => $data, dist_name => $name, dist_version => $version }
        ],
    );
}

1;

