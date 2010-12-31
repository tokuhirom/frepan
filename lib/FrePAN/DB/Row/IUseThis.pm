package FrePAN::DB::Row::IUseThis;
use strict;
use warnings;
use utf8;
use parent qw/FrePAN::DB::Row/;

use Time::Piece;
sub ctime_piece { Time::Piece->new($_[0]->ctime) }
sub mtime_piece { Time::Piece->new($_[0]->mtime) }

1;

