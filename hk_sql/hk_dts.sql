CREATE DATABASE  IF NOT EXISTS `hk_dts`;
USE `hk_dts`;

DROP TABLE IF EXISTS `hk_dts_area_def`;

CREATE TABLE `hk_dts_area_def` (
`id` INT(20) not null AUTO_INCREMENT,
`channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`area_no` INT(20) not null  COMMENT '分区号',
`begin_pos` varchar(50) DEFAULT NULL  COMMENT '分区起始位置',
`end_pos` varchar(50) DEFAULT NULL  COMMENT '分区结束位置',
`high_limit` varchar(50) DEFAULT NULL  COMMENT '分区定温阈值',
`raise_limit` varchar(50) DEFAULT NULL  COMMENT '分区温升阈值',
`diff_limit` varchar(50) DEFAULT NULL  COMMENT '区域温差阈值',
`create_time` varchar(50) DEFAULT NULL  COMMENT '获取该信息的时间',

 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='分区定义表';

DROP TABLE IF EXISTS `hk_dts_ch_def`;
CREATE TABLE `hk_dts_ch_def` (
`id` INT(20) not null AUTO_INCREMENT,
`channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`point_len` INT(20) not null  COMMENT '通道点间距',
`point_num` INT(20) not null  COMMENT '通道点数',
`time_len` INT(20) DEFAULT NULL COMMENT '通道测量时间',
`temp_acc` INT(20) DEFAULT NULL  COMMENT '温度精度',
`area_num` INT(20) DEFAULT NULL  COMMENT '通道分区数',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',

 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='通道设置表';

DROP TABLE IF EXISTS `hk_dts_ch_stat`;
CREATE TABLE `hk_dts_ch_stat` (
`id` INT(20) not null AUTO_INCREMENT,
`channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`fiber_break`  tinyint(1) DEFAULT 0  COMMENT  '是否断纤，0正常，1断纤',
`comm_error`  tinyint(1) DEFAULT 0  COMMENT  '采集模块通讯，0正常，1故障',
`main_power`  tinyint(1) DEFAULT 0  COMMENT  '主电，0正常，1故障',
`back_power`  tinyint(1) DEFAULT 0  COMMENT  '备电，0正常，1故障',
`power_charge`  tinyint(1) DEFAULT 0  COMMENT  '主电，0正常，1故障',
`break_pos` INT(20) DEFAULT NULL  COMMENT '断纤位置',
`create_time` varchar(50) DEFAULT NULL  COMMENT '创建时间',
`fiber_break_time` varchar(50) DEFAULT NULL  COMMENT '断纤时间',
`confirm_time` varchar(50) DEFAULT NULL  COMMENT '最后确认时间',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='通道实时状态表';


DROP TABLE IF EXISTS `hk_dts_area_real_data`;

CREATE TABLE `hk_dts_area_real_data` (
`id` INT(20) not null AUTO_INCREMENT,
`channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`area_no` INT(20) not null  COMMENT '分区号',
`tmp_warning` INT(20) not null  COMMENT '温度报警状态，0正常，1高温报警， 2升温温报警，4差温报警 ',
`high_temp` INT(20) DEFAULT NULL  COMMENT '分区最高温度',
`ava_temp` INT(20) DEFAULT NULL  COMMENT '分区平均温度',
`low_temp` INT(20) DEFAULT NULL  COMMENT '分区最低温度',
`high_pos` INT(20) DEFAULT NULL  COMMENT '分区最高温度点位',
`low_pos` INT(20) DEFAULT NULL  COMMENT '分区最低温度点位',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',

 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='分区实时数据表';


DROP TABLE IF EXISTS `hk_dts_real_alarm_info`;

CREATE TABLE `hk_dts_real_alarm_info` (
`id` INT(20) not null AUTO_INCREMENT,
`channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`area_no` INT(20) not null  COMMENT '分区号',
`alarm_type` INT(20) not null  COMMENT '温度报警状态，0正常，1高温报警， 2升温温报警，4差温报警 ',
`begin_pos` varchar(50) DEFAULT NULL  COMMENT '报警起始位置',
`end_pos` varchar(50) DEFAULT NULL  COMMENT '报警结束位置',
`alarm_time` varchar(50) DEFAULT NULL  COMMENT '报警时间',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',
`is_show`  tinyint(1) DEFAULT 0  COMMENT  '是否已实时显示',

 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='实时报警数据表';

DROP TABLE IF EXISTS `hk_dts_real_data_info`;

CREATE TABLE `hk_dts_real_data_info` (
`id` INT(20) not null AUTO_INCREMENT,
`channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`point_len` INT(20) not null  COMMENT '通道点间距',
`data` varchar(100000) DEFAULT NULL  COMMENT  '数据点HEXY',
`create_time` varchar(50) DEFAULT NULL  COMMENT '修改时间',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='实时温度数据表';




