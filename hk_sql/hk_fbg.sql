CREATE DATABASE  IF NOT EXISTS `hk_fbg`;
USE `hk_fbg`;




DROP TABLE IF EXISTS `hk_fbg_real_data_info`;

CREATE TABLE `hk_fbg_real_data_info` (
`id` INT(20) not null AUTO_INCREMENT,
`dev_id`  varchar(50) DEFAULT NULL  COMMENT '设备号或设备名称',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',
`sor_code` varchar(50) DEFAULT NULL  COMMENT  '传感器号或名称',
`data` varchar(32) DEFAULT NULL  COMMENT  '数据值',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='实时数据表';


DROP TABLE IF EXISTS `hk_fbg_his_gap_info`;
CREATE TABLE `hk_fbg_his_gap_info` (
`id` INT(20) not null AUTO_INCREMENT,
`dev_id`  varchar(50) DEFAULT NULL  COMMENT '设备号或设备名称',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',
`sor_code` varchar(50) DEFAULT NULL  COMMENT  '传感器号或名称',
`data` varchar(32) DEFAULT NULL  COMMENT  '数据值',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='裂隙历史数据表';

DROP TABLE IF EXISTS `hk_fbg_his_shenya_info`;
CREATE TABLE `hk_fbg_his_shenya_info` (
`id` INT(20) not null AUTO_INCREMENT,
`dev_id`  varchar(50) DEFAULT NULL  COMMENT '设备号或设备名称',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',
`sor_code` varchar(50) DEFAULT NULL  COMMENT  '传感器号或名称',
`data` varchar(32) DEFAULT NULL  COMMENT  '数据值',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='渗压历史数据表';

DROP TABLE IF EXISTS `hk_fbg_his_chenjiang_info`;
CREATE TABLE `hk_fbg_his_chenjiang_info` (
`id` INT(20) not null AUTO_INCREMENT,
`dev_id`  varchar(50) DEFAULT NULL  COMMENT '设备号或设备名称',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',
`sor_code` varchar(50) DEFAULT NULL  COMMENT  '传感器号或名称',
`data` varchar(32) DEFAULT NULL  COMMENT  '数据值',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='沉降历史数据表';


DROP TABLE IF EXISTS `hk_fbg_alarm_info`;
CREATE TABLE `hk_fbg_alarm_info` (
`id` INT(20) not null AUTO_INCREMENT,
`alarm_type` INT(30) DEFAULT NULL  COMMENT  '报警类型,0-开裂, 1-渗压, 3-沉降',
`dev_id`  varchar(50) DEFAULT NULL  COMMENT '设备号或设备名称',
`alarm_time` varchar(50) DEFAULT NULL  COMMENT '报警时间',
`sor_code` varchar(50) DEFAULT NULL  COMMENT  '传感器号或名称',
`data` varchar(32) DEFAULT NULL  COMMENT  '数据值',
 `is_show`  tinyint(1) DEFAULT 0  COMMENT  '是否已实时显示',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='报警历史数据表';


DROP TABLE IF EXISTS `hk_fbg_sen_info`;
CREATE TABLE `hk_fbg_sen_info` (
`id` INT(20) not null AUTO_INCREMENT,
`dev_id`  varchar(50) DEFAULT NULL  COMMENT '设备号或设备名称',
`sor_code` varchar(50) DEFAULT NULL  COMMENT  '传感器号或名称',
`sor_loc` varchar(100) DEFAULT NULL  COMMENT  '传感器位置信息',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='报警历史数据表';
