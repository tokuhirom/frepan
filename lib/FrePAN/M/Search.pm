package FrePAN::M::Search;
use strict;
use warnings;
use utf8;
use Log::Minimal;
use Time::Duration ();
use SQL::Interp qw/sql_interp/;
use Smart::Args;

sub search {
    args my $class,
         my $c,
         my $query,
         my $page,
         my $rows => {isa => 'Int', default => 1024},
         ;

    my $search_result = $c->fts->search(query => $query, page => $page, rows => $rows);
    my $file_infos = $search_result->rows;
    # debugf("FILES IDS: %s", ddf($file_infos));

    my ($sql, @binds) = sql_interp(q{
        SELECT SQL_CACHE
            file.file_id, file.package, file.description, file.path,
            dist.dist_id, dist.author, dist.name AS dist_name, dist.version AS dist_version, dist.released AS dist_released,
            meta_author.fullname AS fullname
        FROM file
            INNER JOIN dist ON (dist.dist_id=file.dist_id)
            LEFT JOIN meta_author ON (meta_author.pause_id=dist.author)
        WHERE file_id IN }, [map { $_->{file_id} } @$file_infos]);

    my %files =
      map { $_->{file_id} => $_ }
      @{$c->dbh->selectall_arrayref( $sql, {Slice => +{}}, @binds )};

    my @files;
    for my $row (@$file_infos) {
        my $fid = $row->{file_id};
        my $rdbms_row = $files{$fid};
        unless ($rdbms_row) {
            # warnf("not matched: $fid");
            next;
        }
        $rdbms_row->{score} = $row->{score};
        # if the query matched to package name, give the 10x score.
        if (lc($rdbms_row->{package}) eq lc($query)) {
            $rdbms_row->{score} *= 10;
        }
        # if the query matched to package prefix, give the 2x score
        if (index(lc($rdbms_row->{package}), lc($query)) == 0) {
            $rdbms_row->{score} *= 2;
        }
        push @files, $rdbms_row;
    }

    # sort by files
    @files = reverse sort { $a->{score} <=> $b->{score} } @files;

    # show only one package in dist.
    my %seen;
    @files = grep { !($seen{$_->{'dist_id'}}++) } @files;

    my $now = time();
    for (@files) {
        $_->{timestamp} = Time::Duration::ago($now - $_->{'dist_released'}, 1);
    }
    debugf("FILES IDS: %s", ddf([map { $_->{file_id} } @files]));

    return (\@files, $search_result->pager);
}

1;

