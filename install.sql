CREATE TABLE IF NOT EXISTS `gangs` (
    `name` VARCHAR(50) NOT NULL,
    `label` VARCHAR(64) NOT NULL,
    `pos_coffre` LONGTEXT NOT NULL,
    `pos_boss` LONGTEXT NOT NULL,
    `marker_type` INT(11) NOT NULL DEFAULT 1,
    `marker_size` FLOAT NOT NULL DEFAULT 1,
    `marker_color_r` INT(11) NOT NULL DEFAULT 255,
    `marker_color_g` INT(11) NOT NULL DEFAULT 0,
    `marker_color_b` INT(11) NOT NULL DEFAULT 0,
    `money` BIGINT(20) NOT NULL DEFAULT 0,
    `black_money` BIGINT(20) NOT NULL DEFAULT 0,
    PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
