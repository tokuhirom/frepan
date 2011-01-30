use strict;
use warnings;
use utf8;

package FrePAN::API::Dispatcher;
use Amon2::Web::Dispatcher::Lite;
use CPAN::DistnameInfo;
use FrePAN::M::CPANStats;
use FrePAN::M::Dist;

get '/v1/dist/show.json' => sub {
    my $c = shift;

    my %args = (c => $c);
    for (qw/dist_name/) {
        $args{$_} = $c->req->param($_) or return $c->show_error("Missing mandatory parameter: $_");
    }
    my $version;
    unless ($version = $c->req->param('dist_version')) {
        $version = FrePAN::M::Dist->get_latest_version(name => $args{dist_name});
    }
    my $dist = $c->dbh->selectrow_hashref(q{SELECT name, version, abstract FROM dist WHERE name=? AND version=?}, {Slice => {}}, $args{dist_name}, $version);
    return $c->render_json(
        $dist
    );
};

get '/v1/cpanstats/list' => sub {
    my $c = shift;
    my %args = (c => $c);
    for (qw/dist_name dist_version/) {
        $args{$_} = $c->req->param($_) or return $c->show_error("Missing mandatory parameter: $_");
    }
    return $c->render_json(FrePAN::M::CPANStats->search_for_dist(
        %args
    ));
};

1;

