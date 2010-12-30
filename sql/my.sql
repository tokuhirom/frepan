CREATE TABLE user (
    user_id int unsigned not null auto_increment primary key
    ,login varchar(255) not null
    ,name varchar(255) default null
    ,github_response text
    ,unique (login)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


CREATE TABLE IF NOT EXISTS dist (
     dist_id int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,author   varchar(255) not null
    ,name     varchar(255) not null
    ,version  varchar(255) not null
    ,path     varchar(255)
    ,abstract varchar(255)
    ,resources_json text
    ,has_manifest tinyint(1) not null default 0
    ,has_makefile_pl tinyint(1) not null default 0
    ,has_build_pl tinyint(1) not null default 0
    ,has_changes tinyint(1) not null default 0
    ,has_change_log tinyint(1) not null default 0
    ,has_meta_yml tinyint(1) not null default 0
    ,has_meta_json tinyint(1) not null default 0
    ,requires text
    ,released int unsigned not null
    ,old      tinyint(1) not null default 0
    ,UNIQUE idx_author_name_version (author, name, version)
    ,INDEX  name (name) -- search by name for removing fts index
) engine=InnoDB DEFAULT charset=UTF8;
create index dist_released ON dist (released);

CREATE TABLE IF NOT EXISTS file (
     file_id     int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,path        varchar(255) not null
    ,dist_id     int unsigned not null
    ,package     varchar(255)
    ,description varchar(255)
    ,html        text
    ,UNIQUE(dist_id, path),
    ,INDEX (package)
) engine=InnoDB DEFAULT charset=UTF8;

CREATE TABLE IF NOT EXISTS changes (
     changes_id  int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,dist_id     int unsigned not null
    ,version     varchar(255) not null
    ,body        text
    ,UNIQUE(dist_id, version)
) engine=InnoDB DEFAULT charset=UTF8;

-- authors/01mailrc.txt.gz
CREATE TABLE IF NOT EXISTS meta_author (
     pause_id    varchar(255) not null PRIMARY KEY
    ,fullname    varchar(255) not null
    ,email       varchar(255) not null
) engine=InnoDB DEFAULT charset=UTF8;

-- modules/02packages.details.txt.gz
CREATE TABLE IF NOT EXISTS meta_packages (
     package      varchar(255) BINARY not null PRIMARY KEY
    ,version      varchar(255) BINARY not null
    ,path         varchar(255) BINARY not null
    ,pause_id     varchar(255) BINARY NOT NULL
    ,dist_name    varchar(255) BINARY NOT NULL
    ,dist_version varchar(255) BINARY NOT NULL
    ,dist_version_numified varchar(255) BINARY NOT NULL
) engine=InnoDB DEFAULT charset=UTF8;
alter table meta_packages add index (pause_id, dist_name, dist_version);

-- from http://devel.cpantesters.org/uploads/uploads.db.bz2
-- select pkg.dist_name, MAX(pkg.dist_version), upl.released from meta_packages as pkg left join meta_uploads as upl on (pkg.dist_name=upl.dist_name AND pkg.pause_id=upl.pause_id) where pkg.pause_id="TOKUHIROM" GROUP BY pkg.dist_name;
CREATE TABLE IF NOT EXISTS meta_uploads (
    type          varchar(255) binary not null
    ,pause_id     varchar(255) binary not null
    ,dist_name    varchar(255) binary not null
    ,dist_version varchar(255) binary not null
    ,filename     varchar(255) binary not null
    ,released     int unsigned        not null -- 'unix time'
    ,PRIMARY KEY (pause_id, dist_name, dist_version)
) engine=InnoDB DEFAULT charset=UTF8;
-- alter table meta_uploads add type          varchar(255) binary not null before pause_id;
