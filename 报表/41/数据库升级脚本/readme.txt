数据库从3.1.40升级到3.1.41步骤:
1. 确认数据库已安装visionlog40数据库、3.1.40版的vxi_common、vxi_visionone两个数据库,升级前先做好相关数据库备份。
2. 执行脚本upgrade40-41.sql
3.从数据库管理器中分离visionlog41
4.到数据库目录中修改物理文件名, "visionlog40.mdf"改为“visionlog41.mdf”， “visionlog40_log.LDF”改为“visionlog41_log.LDF”
5. 附加visionlog41数据库， 注意选物理文件名为“visionlog41.mdf”和“visionlog40_log.LDF”，附加完成后，数据库升级完成。
6. 升级数据库后，需同时将visionone升级到3.1.41版本，并将配置中的数据库名称visionlog40改为visionlog41
7. 其他应用程序如visionlog也需将配置中的数据库名称visionlog40改为visionlog41


8. 执行"静音统计脚本"目录下的三个步骤(如有静音统计需求)
9. 如有TRS监控需求,请执行"左导航TRS监控.sql"