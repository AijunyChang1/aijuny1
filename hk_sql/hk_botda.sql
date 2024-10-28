CREATE DATABASE IF NOT EXISTS `hk_botda`;
USE `hk_botda`;

DROP TABLE IF EXISTS `hk_botda_device_info`;
CREATE TABLE `hk_botda_device_info` (
 `id` INT(20) not null AUTO_INCREMENT,
 `event_time` varchar(50) DEFAULT NULL  COMMENT  '消息时间',
 `event_type` varchar(50) DEFAULT NULL  COMMENT  '消息类型',
 `device_name` varchar(50) DEFAULT NULL  COMMENT  '设备名称',
 `device_mode` varchar(50) DEFAULT NULL  COMMENT  '工作模式',
 `max_ch_count` INT(20) not null,
 `run_status`  tinyint(1) DEFAULT NULL  COMMENT  '工作状态',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='botda设备信息详情';

DROP TABLE IF EXISTS `hk_botda_alarm_info`;
CREATE TABLE `hk_botda_alarm_info` (
 `id` INT(20) not null AUTO_INCREMENT,
 `device_name` varchar(50) DEFAULT NULL  COMMENT  '设备名称',
 `channel_id` INT(20) not null  COMMENT '通道号，即光纤号', 
 `alarm_time` varchar(50) DEFAULT NULL  COMMENT  '报警时间',
 `update_time` varchar(50) DEFAULT NULL  COMMENT  '更新时间',
 `event_type` varchar(50) DEFAULT NULL  COMMENT  '消息类型',
 `alarm_guid` varchar(50) DEFAULT NULL  COMMENT  '该报警ID',
 `device_mode` INT(20) default null  COMMENT '报警模式 0-温度，1-应变， 2-DAS数据',
 `alarm_level` INT(20) default null  COMMENT '报警程度，固定为3',
 `alarm_format` INT(20) default null  COMMENT '报警格式，定置、差值等',
 `begin_pos` varchar(50) DEFAULT NULL  COMMENT  '起始位置',
 `end_pos` varchar(50) DEFAULT NULL  COMMENT  '结束位置',
 `cent_pos` varchar(50) DEFAULT NULL  COMMENT  '中间位置',
 `max_value` varchar(50) DEFAULT NULL  COMMENT  '最大历史报警值',
 `limen_value` varchar(50) DEFAULT NULL  COMMENT  '报警阈值',
 `soft_alarm`  tinyint(1) DEFAULT NULL  COMMENT  '是否客户端报警',
 `is_show`  tinyint(1) DEFAULT 0  COMMENT  '是否已实时显示',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='botda报警信息详情';

DROP TABLE IF EXISTS `hk_botda_data`;
CREATE TABLE `hk_botda_data` (
 `id` INT(20) not null AUTO_INCREMENT,
 `event_type` varchar(50) DEFAULT NULL  COMMENT  '消息类型 Name',
 `device_name` varchar(50) DEFAULT NULL  COMMENT  '设备名称 MacID',
 `channel_id` INT(20) not null  COMMENT '通道号，即光纤号 ChnID', 
 `data_size` INT(30) not null  COMMENT '数据的点数 size',
 `data`  mediumtext  DEFAULT NULL  COMMENT  '数据点HEXY',
 `begin_pos` varchar(50) DEFAULT NULL  COMMENT  '有效数据起始位置XOffsetUser',
 `dot_len` varchar(50) DEFAULT NULL  COMMENT  '一点对应的长度XStepUser',
 `rece_time` varchar(50) DEFAULT NULL  COMMENT  '数据发送时间DataTime',
 `is_alarm`  tinyint(1) DEFAULT NULL  COMMENT  '是否客户端报警IsAlarm',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='botda应变数据详情';

DROP TABLE IF EXISTS `hk_botda_anno`;
CREATE TABLE `hk_botda_anno` (
`id` INT(20) not null AUTO_INCREMENT,
`eid` INT(20) not null COMMENT '数据记录id', 
 `dot_pos` varchar(50) DEFAULT NULL  COMMENT  '弯折位置',
 `angle` varchar(50) DEFAULT NULL  COMMENT  '弯折角度',
 `anno` varchar(50) DEFAULT NULL  COMMENT  '备注',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='botda应变备注数据';
 select alarm_time,  device_mode , alarm_format, begin_pos, end_pos, cent_pos, limen_value , max_value  from hk_botda_alarm_info;