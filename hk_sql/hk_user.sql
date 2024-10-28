CREATE DATABASE  IF NOT EXISTS `hk_user`;
USE `hk_user`;

DROP TABLE IF EXISTS `hk_user_info`;
CREATE TABLE `hk_user_info` (
 `id` INT(20) not null AUTO_INCREMENT,
 `user_name` varchar(50) not NULL  COMMENT '用户名',
 `pass_word` varchar(50) not NULL  COMMENT '密码',
 `user_role` INT(30) DEFAULT NULL  COMMENT  '用户角色,0-admin, 1-normal',
 `create_time` varchar(50) DEFAULT NULL  COMMENT '创建时间',
 `last_login_time` varchar(50) DEFAULT NULL  COMMENT '最后登录时间',
  `is_active`  tinyint(1) DEFAULT NULL  COMMENT  '是否激活',
 PRIMARY KEY (`id`)
) ENGINE=InnoDB  COMMENT='用户表';
