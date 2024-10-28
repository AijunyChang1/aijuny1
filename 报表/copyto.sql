
declare @Recc varchar(30);
set @Recc='172.28.19.71';

exec sp_droplinkedsrvlogin ITSV, NULL;  --第一次运行时需注释掉
exec sp_dropserver  ITSV;               --第一次运行时需注释掉
exec sp_addlinkedserver   'ITSV', '', 'SQLOLEDB ','172.28.19.71'; --远程主机ip，连接名为ITSU
exec sp_addlinkedsrvlogin  'ITSV', 'false ',NULL, 'sa', 'sasasa'; --远程用户名密码
select * from ITSV.vxi_rec.dbo.Records ;
--select * FROM openquery(ITSV,  'SELECT *  FROM vxi_rec.dbo.Records ') ;
insert openquery(ITSV,  'SELECT RecordId,UcdId,CallID,Calling,Called,Answer,StartTime,TimeLen,Agent,Skill,Route,Trunk,TrunkGroupId,VideoURL,Channel,Extension,VoiceType,
    StartDate,StartHour,Inbound,Outbound,UCID,UUI,PrjId,finished,ActFlag,Labeled,FileCount,DataEncry  FROM vxi_rec.dbo.Records') select  RecordId,UcdId,CallID,Calling,Called,Answer,StartTime,TimeLen,Agent,Skill,Route,Trunk,TrunkGroupId,VideoURL,Channel,Extension,VoiceType,
    StartDate,StartHour,Inbound,Outbound,UCID,UUI,PrjId,finished,ActFlag,Labeled,FileCount,DataEncry  from vxi_rec.dbo.Records;

--delete from ITSV.vxi_sys.dbo.GroupType;
insert openquery(ITSV,  'select GroupType,TypeName from vxi_sys.dbo.GroupType ') select GroupType,TypeName from vxi_sys.dbo.GroupType;
insert openquery(ITSV,  'select GroupId,GroupName,GroupType,PrjId,Items,Summary,Leader,SiteId,Acked,Enabled from vxi_sys.dbo.Groups ') select GroupId,GroupName,GroupType,PrjId,Items,Summary,Leader,SiteId,Acked,Enabled from vxi_sys.dbo.Groups;
insert openquery(ITSV,  'select Station,SortId,GroupId,IP,ExtIP,Enabled from vxi_sys.dbo.Station ') select Station,SortId,GroupId,IP,ExtIP,Enabled  from vxi_sys.dbo.Station;
insert openquery(ITSV,  'select GroupId,Station from vxi_sys.dbo.StationGroup ') select GroupId,Station from vxi_sys.dbo.StationGroup;
insert openquery(ITSV,  'select Device,SortId,DevName,DevType,Station,IP,Mac,Enabled,ModIndex from vxi_sys.dbo.Devices') select Device,SortId,DevName,DevType,Station,IP,Mac,Enabled,ModIndex from vxi_sys.dbo.Devices;
insert openquery(ITSV,  'select Route,RouteName,PrjId,Station,SortId,SwitchIn,Enabled from vxi_sys.dbo.Route ') select Route,RouteName,PrjId,Station,SortId,SwitchIn,Enabled from vxi_sys.dbo.Route;
--insert openquery(ITSV,  'select TrunkID,SortId,TrunkNum,TrunkGroup,Enabled from vxi_sys.dbo.Trunk') select TrunkID,SortId,TrunkNum,TrunkGroup,Enabled from vxi_sys.dbo.Trunk;
insert openquery(ITSV,  'select GroupID,GroupName,SortId,TrunkAmt,Summary,AutoBill,Station,FtpId,VoiceType,Enabled from vxi_sys.dbo.TrunkGroup ') select GroupID,GroupName,SortId,TrunkAmt,Summary,AutoBill,Station,FtpId,VoiceType,Enabled from vxi_sys.dbo.TrunkGroup;

--insert openquery(ITSV,  'select ChType,TypeName from vxi_sys.dbo.ChType ') select ChType,TypeName from vxi_sys.dbo.ChType;
--insert openquery(ITSV,  'select VoiceType,TypeName,Ext,Wavbit,Code,Description,Enabled from vxi_sys.dbo.VoiceType ') select VoiceType,TypeName,Ext,Wavbit,Code,Description,Enabled from vxi_sys.dbo.VoiceType;
insert openquery(ITSV,  'select Channel,Station,SortId,DevName,PortNo,ChType,VoiceType,AutoMon,Mapped,Enabled from vxi_sys.dbo.Channels ') select Channel,Station,SortId,DevName,PortNo,ChType,VoiceType,AutoMon,Mapped,Enabled from vxi_sys.dbo.Channels;
insert openquery(ITSV,  'select Agent,AgentName,SortId,ProjectId,Passwd,PrimarySkill,GroupId,SkillGroup,Post,RegDate,UnregDate,State,SiteId,EmpId,Enabled from vxi_sys.dbo.Agent ') select Agent,AgentName,SortId,ProjectId,Passwd,PrimarySkill,GroupId,SkillGroup,Post,RegDate,UnregDate,State,SiteId,EmpId,Enabled from vxi_sys.dbo.Agent;

--delete from ITSV.vxi_rec.dbo.Store;
insert openquery(ITSV,  'select FtpId,SortId,Station,Folder,Port,Drive,Encry,RealFolder,Priority,UserName,Password,AutoBackup,DestFolder,BackupTime,KeepDays,Type,Enabled from vxi_rec.dbo.Store ') select FtpId,SortId,Station,Folder,Port,Drive,Encry,RealFolder,Priority,UserName,Password,AutoBackup,DestFolder,BackupTime,KeepDays,Type,Enabled from vxi_rec.dbo.Store;


insert openquery(ITSV,  'select TaskID,SortId, TaskName,Items,TaskType,DevType,Quality,State,WeekMark,MonthMark,DateStart,DateEnd,TimeStart,TimeEnd,RecFlag,Priority,RecPercent,ScrPercent,Enabled,RecStorage,ScrStorage,AsrFlag,AsrPercent,AsrPkgs from vxi_rec.dbo.Task ') select 
 TaskID,SortId, TaskName,Items,TaskType,DevType,Quality,State,WeekMark,MonthMark,DateStart,DateEnd,TimeStart,TimeEnd,RecFlag,Priority,RecPercent,ScrPercent,Enabled,RecStorage,ScrStorage,AsrFlag,AsrPercent,AsrPkgs from vxi_rec.dbo.Task;
--insert openquery(ITSV,  'select from vxi_rec.dbo.Filter ') select from vxi_rec.dbo.Filter;


--select RecordId into vxi_rec.dbo.Records from ITSV.vxi_rec.dbo.Records;

--insert openrowset( 'SQLOLEDB ', '192.168.150.221'; 'sa'; 'sasasa',vxi_rec.dbo.Records) select *from vxi_rec.dbo.Records;
exec sp_droplinkedsrvlogin ITSV, NULL;
exec sp_dropserver  'ITSV ', 'droplogins';




