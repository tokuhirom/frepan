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
