ALTER TABLE dist ADD has_build_pl tinyint(1) not null default 0 AFTER abstract;
ALTER TABLE dist ADD has_change_log tinyint(1) not null default 0 AFTER abstract;
ALTER TABLE dist ADD has_changes tinyint(1) not null default 0 AFTER abstract;
ALTER TABLE dist ADD has_makefile_pl tinyint(1) not null default 0 AFTER abstract;
ALTER TABLE dist ADD has_manifest tinyint(1) not null default 0 AFTER abstract;
ALTER TABLE dist ADD has_meta_yml tinyint(1) not null default 0 AFTER abstract;
ALTER TABLE dist ADD license  varchar(255) AFTER abstract;
ALTER TABLE dist ADD repository text AFTER abstract;
ALTER TABLE dist ADD homepage text AFTER repository;
ALTER TABLE dist ADD bugtracker text AFTER homepage;
ALTER TABLE dist ADD has_meta_json tinyint(1) not null default 0 AFTER has_meta_yml;

ALTER TABLE dist CHANGE ctime released  int unsigned not null;
DROP TRIGGER dist_ctime;

ALTER TABLE dist ADD INDEX name (name);
