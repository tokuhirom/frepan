# XXX THIS FILE IS GENERATED BY script/make_schema.pl
package FrePAN::DB::Schema;
use strict;
use warnings;
use DBIx::Skinny::Schema;


install_table 'changes' => sub {
    pk      qw(changes_id);
    columns qw(body changes_id version dist_id);
};


install_table 'cpanstats' => sub {
    pk      qw(guid);
    columns qw(date version dist osvers state perl osname postdate type guid platform tester);
};


install_table 'cpanstats_summary' => sub {
    pk      qw(version dist state);
    columns qw(version dist cnt state);
};


install_table 'dist' => sub {
    pk      qw(dist_id);
    columns qw(has_makefile_pl author has_manifest has_meta_json requires has_change_log has_build_pl authorized version has_meta_yml name path released dist_id old resources_json abstract has_changes);
};


install_table 'file' => sub {
    pk      qw(file_id);
    columns qw(html authorized path description dist_id package file_id);
};


install_table 'i_use_this' => sub {
    columns qw(body dist_name dist_version ctime mtime user_id);
};


install_table 'meta_author' => sub {
    pk      qw(pause_id);
    columns qw(gravatar_id email pause_id fullname);
};


install_table 'meta_packages' => sub {
    pk      qw(package);
    columns qw(dist_name dist_version_numified dist_version version pause_id path package);
};


install_table 'meta_perms' => sub {
    columns qw(permission pause_id package);
};


install_table 'meta_uploads' => sub {
    pk      qw(dist_name pause_id dist_version);
    columns qw(dist_name dist_version released pause_id filename type);
};


install_table 'user' => sub {
    pk      qw(user_id);
    columns qw(gravatar_id ctime mtime name login user_id github_response);
};



use Module::Find ();
Module::Find::useall('FrePAN::DB');

1;
# XXX THIS FILE IS GENERATED BY script/make_schema.pl
