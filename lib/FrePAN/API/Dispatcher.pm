use strict;
use warnings;
use utf8;

package FrePAN::API::Dispatcher;
use Amon2::Web::Dispatcher::Lite;
use CPAN::DistnameInfo;
use FrePAN::M::CPANStats;

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

