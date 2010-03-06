package FrePAN::DB::Schema;
use strict;
use warnings;
use DBIx::Skinny::Schema;

install_table 'dist' => schema {
    pk 'dist_id';
    columns qw/dist_id path author ctime name version requires abstract/;
};

install_table 'file' => schema {
    pk 'file_id';
    columns qw/file_id dist_id package path description html/;
};

1;
