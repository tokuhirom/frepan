package FrePAN::M::Search;
use strict;
use warnings;
use utf8;
use Log::Minimal;
use Time::Duration ();
use SQL::Interp qw/sql_interp/;
use Smart::Args;
use Data::Page;

sub search_author {
    args my $class,
         my $c,
         my $query,
         my $limit => {isa => 'Int', default => 3},
         ;

    # escape for LIKE
    $query =~ s!_!\\_!g;
    $query =~ s!%!\\%!g;

    return @{
        $c->dbh->selectall_arrayref(
            q{SELECT pause_id, fullname FROM meta_author WHERE pause_id LIKE CONCAT(?, '%') OR fullname LIKE CONCAT(?, '%') LIMIT ?},
            { Slice => {} }, $query, $query, $limit
        )
      };
}

1;

