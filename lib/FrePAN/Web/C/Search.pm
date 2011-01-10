package FrePAN::Web::C::Search;
use strict;
use warnings;
use utf8;
use Log::Minimal;
use FrePAN::M::Search;

sub result {
    my ($class, $c) = @_;
    my $page = $c->req->param('page') // 1;
    my $query = $c->req->param('q') || return $c->redirect('/');

    my ($files, $pager) = FrePAN::M::Search->search(
        query => $query,
        c     => $c,
        page  => $page,
    );

    if ($c->req->param('ajax')) {
        return $c->render('search/result-ajax.tx', {files => $files, pager => $pager});
    } else {
        return $c->render('search/result.tx', {files => $files, query => $query, pager => $pager});
    }
}

1;

