DELIMITER |
    CREATE TRIGGER before_insert_user BEFORE INSERT ON user FOR EACH ROW BEGIN
        SET NEW.ctime = UNIX_TIMESTAMP(NOW());
    END
|
DELIMITER |
    CREATE TRIGGER before_update_user BEFORE UPDATE ON user FOR EACH ROW BEGIN
        SET NEW.mtime = UNIX_TIMESTAMP(NOW());
    END
|

DELIMITER |
    CREATE TRIGGER before_insert_i_use_this BEFORE INSERT ON i_use_this FOR EACH ROW BEGIN
        SET NEW.ctime = UNIX_TIMESTAMP(NOW());
        SET NEW.mtime = UNIX_TIMESTAMP(NOW());
    END
|
DELIMITER |
    CREATE TRIGGER before_update_i_use_this BEFORE UPDATE ON i_use_this FOR EACH ROW BEGIN
        SET NEW.mtime = UNIX_TIMESTAMP(NOW());
    END
|
DELIMITER |
    CREATE TRIGGER after_insert_cpanstats AFTER INSERT ON cpanstats FOR EACH ROW BEGIN
        INSERT INTO cpanstats_summary (dist, version, state, cnt) VALUES (NEW.dist, NEW.version, NEW.state, 1)
            ON DUPLICATE KEY UPDATE cnt = cnt + 1;
    END
|
DELIMITER |
    CREATE TRIGGER before_delete_cpanstats BEFORE DELETE ON cpanstats FOR EACH ROW BEGIN
       UPDATE cpanstats_summary SET cnt = cnt - 1
        WHERE dist=OLD.dist AND version=OLD.version AND state=OLD.state;
    END
|
