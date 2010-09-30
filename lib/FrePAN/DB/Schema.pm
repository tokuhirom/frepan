package FrePAN::DB::Schema;
use DBIx::Skinny::Schema;

install_table changes => schema {
    pk qw/changes_id/;
    columns qw/changes_id dist_id version body/;
};

install_table dist => schema {
    pk qw/dist_id/;
    columns qw/dist_id author name version path abstract resources_json has_manifest has_makefile_pl has_build_pl has_changes has_change_log has_meta_yml has_meta_json requires released/;
};

install_table file => schema {
    pk qw/file_id/;
    columns qw/file_id path dist_id package description html/;
};

install_table kvs => schema {
    pk qw/k/;
    columns qw/k v/;
};

install_table meta_author => schema {
    pk qw/pause_id/;
    columns qw/pause_id fullname email/;
};

install_table meta_packages => schema {
    pk qw/package/;
    columns qw/package version path pause_id dist_name dist_version dist_version_numified/;
};

install_table meta_uploads => schema {
    pk qw/dist_name pause_id dist_version/;
    columns qw/pause_id dist_name dist_version filename released/;
};

1;