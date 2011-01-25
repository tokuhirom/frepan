package FrePAN::DB;
use strict;
use warnings;
use DBIx::Skinny;

sub txn_scope { $_[0]->dbh->txn_scope }
sub txn_begin { $_[0]->dbh->txn_manager->txn_begin }
sub txn_end   { $_[0]->dbh->txn_manager->txn_end   }

1;
