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

# -------------------------------------------------------------------------
# cpan db

# from 01mailrc.txt
install_table meta_author => schema {
    pk 'pause_id';
    columns qw/pause_id fullname email/;
};

# from 02packages.details.txt.gz
install_table meta_packages => schema {
    pk 'package';
    columns qw/package version path/;
};

1;
