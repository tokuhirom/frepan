use strict;
use warnings;
use utf8;

package FrePAN::API::Dispatcher;
use Amon2::Web::Dispatcher::Lite;
use CPAN::DistnameInfo;
use FrePAN::M::CPANStats;
use FrePAN::M::Dist;
use JSON;

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

    my $dist = FrePAN::M::Dist->get(c => $c, dist_name => $args{dist_name}, dist_version => $version);
    if ($dist) {
        return $c->render_json(
            $dist
        );
    } else {
        my $res = $c->render_json(
            {error => 'Not found'}
        );
        $res->status(404);
        return $res;
    }
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

