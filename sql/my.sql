CREATE TABLE IF NOT EXISTS dist (
     dist_id int unsigned not null AUTO_INCREMENT PRIMARY KEY
    ,author   varchar(255) not null
    ,name     varchar(255) not null
    ,version  varchar(255) not null
    ,path     varchar(255)
    ,abstract varchar(255)
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
    ,package     varchar(255)
    ,description varchar(255)
    ,dist_id     int unsigned
    ,html        text
    ,UNIQUE(dist_id, path)
) engine=InnoDB DEFAULT charset=UTF8;

