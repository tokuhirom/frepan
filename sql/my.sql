CREATE TABLE IF NOT EXISTS dist (
     dist_id int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,author   varchar(255) not null
    ,name     varchar(255) not null
    ,version  varchar(255) not null
    ,path     varchar(255)
    ,abstract varchar(255)
    ,license  varchar(255)
    ,repository text
    ,homepage   text
    ,bugtracker text
    ,has_manifest tinyint(1) not null default 0
    ,has_makefile_pl tinyint(1) not null default 0
    ,has_build_pl tinyint(1) not null default 0
    ,has_changes tinyint(1) not null default 0
    ,has_change_log tinyint(1) not null default 0
    ,has_meta_yml tinyint(1) not null default 0
    ,has_meta_json tinyint(1) not null default 0
    ,requires text
    ,ctime   int unsigned not null
    ,UNIQUE idx_author_name_version (author, name, version)
) engine=InnoDB DEFAULT charset=UTF8;

DELIMITER |
CREATE TRIGGER dist_ctime BEFORE INSERT ON dist
FOR EACH ROW BEGIN
    SET NEW.ctime = UNIX_TIMESTAMP(NOW());
END
|
DELIMITER ;

CREATE TABLE IF NOT EXISTS file (
     file_id     int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,path        varchar(255) not null
    ,dist_id     int unsigned not null
    ,package     varchar(255)
    ,description varchar(255)
    ,html        text
    ,UNIQUE(dist_id, path)
) engine=InnoDB DEFAULT charset=UTF8;

CREATE TABLE IF NOT EXISTS changes (
     changes_id  int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,dist_id     int unsigned not null
    ,version     varchar(255) not null
    ,body        text
    ,UNIQUE(dist_id, version)
) engine=InnoDB DEFAULT charset=UTF8;

CREATE TABLE IF NOT EXISTS meta_author (
     pause_id    varchar(255) not null PRIMARY KEY
    ,fullname    varchar(255) not null
    ,email       varchar(255) not null
) engine=InnoDB DEFAULT charset=UTF8;

CREATE TABLE IF NOT EXISTS meta_packages (
     package      varchar(255) BINARY not null PRIMARY KEY
    ,version      varchar(255) BINARY not null
    ,path         varchar(255) BINARY not null
    ,pause_id     varchar(255) BINARY NOT NULL
    ,dist_name    varchar(255) BINARY NOT NULL
    ,dist_version varchar(255) BINARY NOT NULL
) engine=InnoDB DEFAULT charset=UTF8;

