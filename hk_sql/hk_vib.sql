CREATE DATABASE  IF NOT EXISTS `hk_vibration`;
USE `hk_vibration`;

DROP TABLE IF EXISTS `hk_vib_event_detail`;
CREATE TABLE `hk_vib_event_detail` (
 `id` INT(20) not null AUTO_INCREMENT,
`topic`  varchar(50) DEFAULT NULL  COMMENT '订阅主题',
 `channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`sensor_id` varchar(50) DEFAULT NULL  COMMENT  '传感器号',
 `sample_id` INT(20) DEFAULT NULL  COMMENT '样本号',
 `sample_name` varchar(50) DEFAULT NULL COMMENT '样本名',
`level` INT(20) DEFAULT NULL  COMMENT '报警等级',
`possibility`  varchar(50) DEFAULT NULL  COMMENT '可信度',
`center_pos` varchar(50) DEFAULT NULL  COMMENT '报警中心位置',
`event_width` varchar(50) DEFAULT NULL  COMMENT '事件宽度',
`max_intensity` varchar(50) DEFAULT NULL  COMMENT  '报警最大强度',
`first_push_time` varchar(50) DEFAULT NULL  COMMENT '第一次推送时间',
`last_push_time` varchar(50) DEFAULT NULL  COMMENT '最后一次推送时间',
`push_time` varchar(50) DEFAULT NULL  COMMENT '推送时间',
`is_show`  tinyint(1) DEFAULT 0  COMMENT  '是否已实时显示',

 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='报警信息详情';

DROP TABLE IF EXISTS `hk_fiber_event_detail`;
CREATE TABLE `hk_fiber_event_detail` (
 `id` INT(20) not null AUTO_INCREMENT,
`topic` varchar(50) not null COMMENT '订阅主题',
 `channel_id` INT(20) not null  COMMENT '通道号，即光纤号',
`sensor_id` varchar(50) DEFAULT NULL  COMMENT  '传感器号',
`fiber_stat` varchar(50) DEFAULT NULL  COMMENT  '光纤状态',
`fiber_bk_len` varchar(50) DEFAULT NULL  COMMENT  '断纤位置',
`fiber_real_len` varchar(50) DEFAULT NULL  COMMENT  '光纤实际长度',
`push_time` varchar(50) DEFAULT NULL  COMMENT '推送时间',
`is_show`  tinyint(1) DEFAULT 0  COMMENT  '是否已实时显示',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='报警信息详情';

DROP TABLE IF EXISTS `hk_cable_figure_id`;
CREATE TABLE `hk_cable_figure_id` (
 `id` INT(20) not null AUTO_INCREMENT,
 `channel` INT(20) DEFAULT NULL  COMMENT  '光纤通道号',
 `cable_type` varchar(300) DEFAULT NULL  COMMENT  '电缆型号',
 `cable_producer` varchar(300) DEFAULT NULL  COMMENT  '电缆生产商',
 `cable_produce_date` varchar(300) DEFAULT NULL  COMMENT  '电缆生产日期或批号',
 `cable_len` INT(30) DEFAULT NULL  COMMENT  '电缆长度',
 `cable_d` varchar(300) DEFAULT NULL  COMMENT  '电缆直径',
 `cable_material` INT(30) DEFAULT NULL  COMMENT  '电缆芯质',
 `file_name` varchar(300) DEFAULT NULL  COMMENT  '电缆附图文件名',
 `cable_annotation` varchar(300) DEFAULT NULL  COMMENT  '备注',
 PRIMARY KEY (`id`)
 ) ENGINE=InnoDB  COMMENT='电缆身份识别卡';

DROP TABLE IF EXISTS `hk_fiber_figure_id`;
CREATE TABLE `hk_fiber_figure_id` (
 `id` INT(20) not null AUTO_INCREMENT,
 `channel` INT(20) DEFAULT NULL  COMMENT  '光纤通道号',
 `fiber_type` varchar(300) DEFAULT NULL  COMMENT  '光纤型号',
 `fiber_producer` varchar(300) DEFAULT NULL  COMMENT  '光纤生产商',
 `fiber_produce_date` varchar(300) DEFAULT NULL  COMMENT  '光纤生产日期或批号',
 `fiber_len` INT(30) DEFAULT NULL  COMMENT  '光纤长度',
 `file_name` varchar(300) DEFAULT NULL  COMMENT  '光纤附图文件名',
 `fiber_annotation` varchar(300) DEFAULT NULL  COMMENT  '备注',
 PRIMARY KEY (`id`)
 ) ENGINE=InnoDB  COMMENT='光纤身份识别卡';

DROP TABLE IF EXISTS `hk_show_figure_event`;
CREATE TABLE `hk_show_figure_event` (
 `id` INT(20) not null AUTO_INCREMENT,
 `push_time` varchar(50) DEFAULT NULL  COMMENT '推送时间',
 `channel` INT(20) DEFAULT NULL  COMMENT  '光纤通道号',
 `is_show`  tinyint(1) DEFAULT 0 COMMENT  '是否已实时显示',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='电缆身份识别事件';

DROP TABLE IF EXISTS `hk_user`;
CREATE TABLE `hk_user` (
 `id` INT(20) not null AUTO_INCREMENT,
 `user_name` varchar(50) not NULL  COMMENT '用户名',
 `pass_word` varchar(50) not NULL  COMMENT '密码',
 `user_role` INT(30) DEFAULT NULL  COMMENT  '用户角色,0-admin, 1-normal',
 `create_time` varchar(50) DEFAULT NULL  COMMENT '创建时间',
 `last_login_time` varchar(50) DEFAULT NULL  COMMENT '最后登录时间',
  `is_active`  tinyint(1) DEFAULT NULL  COMMENT  '是否激活',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='用户表';
