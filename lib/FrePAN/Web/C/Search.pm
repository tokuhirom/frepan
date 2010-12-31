package FrePAN::Web::C::Search;
use strict;
use warnings;
use utf8;
use Log::Minimal;
use SQL::Interp qw/sql_interp/;
use Data::Page;

sub result {
    my ($class, $c) = @_;
    my $page = $c->req->param('page') // 1;
    my $query = $c->req->param('q') || return $c->redirect('/');
    my $search_result = $c->fts->search(query => $query, page => $page, rows => 50);
    my $file_infos = $search_result->rows;
    debugf("FILES IDS: %s", ddf($file_infos));
    my ($sql, @binds) = sql_interp(q{SELECT file.*, dist.dist_id, dist.author, dist.name AS dist_name, dist.version AS dist_version, dist.released AS dist_released, meta_author.fullname AS fullname FROM file INNER JOIN dist ON (dist.dist_id=file.dist_id) LEFT JOIN meta_author ON (meta_author.pause_id=dist.author) WHERE file_id IN }, [map { $_->{file_id} } @$file_infos]);
    my %seen;
    my %files = map { $_->file_id => $_ } grep { !$seen{$_->get_column('dist_id')}++ } $c->db->search_by_sql($sql, \@binds, 'file');
    my @files;
    for my $row (@$file_infos) {
        my $fid = $row->{file_id};
        unless ($files{$fid}) {
            # warnf("not matched: $fid");
            next;
        }
        $files{$fid}->set_column('score' => $row->{score});
        push @files, $files{$fid};
    }
    my $now = time();
    for (@files) {
        $_->set_column(timestamp => Time::Duration::ago($now - $_->get_column('dist_released'), 1));
    }
    debugf("FILES IDS: %s", ddf([map { $_->file_id } @files]));
    if ($c->req->param('ajax')) {
        return $c->render('search/result-ajax.tx', {files => \@files, pager => $search_result->pager});
    } else {
        return $c->render('search/result.tx', {files => \@files, query => $query, pager => $search_result->pager});
    }
}

1;

