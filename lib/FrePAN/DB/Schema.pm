package FrePAN::DB::Schema;
use strict;
use warnings;
use DBIx::Skinny::Schema;

install_table 'dist' => schema {
    pk 'dist_id';
    columns qw/
      dist_id path author ctime name version requires abstract
      license repository has_manifest has_makefile_pl has_build_pl
      has_changes has_change_log has_meta_yml
      homepage bugtracker has_meta_json
    /;
};

install_table 'file' => schema {
    pk 'file_id';
    columns qw/file_id dist_id package path description html/;
};

install_table changes => schema {
    pk 'changes_id';
    columns qw/dist_id changes_id version body/;
};

1;
