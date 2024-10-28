该目录下的脚本用于有静音统计需求的项目,安装前需确保数据库已安装visionlog41(或已从visionlog40升级到了visionlog41)

步骤:
1.执行ETL_LOG.sql
2.打开Deployment目录, 在打开的应用程序中输入相应的数据库及用户名密码, 完成SSIS包的安装
3.打开"调用IS_RecordEventCaculate_LOAD的作业.sql"脚本, 修改链接的数据库、用户名、密码，执行脚本。
、