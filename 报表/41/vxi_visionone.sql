USE [master]
GO
CREATE DATABASE [vxi_visionone]
GO
USE [vxi_visionone]

/****** Object:  StoredProcedure [dbo].[sp_getAccessControl]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getAccessControl]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_getAccessControl]
GO
/****** Object:  StoredProcedure [dbo].[sp_getEmployeeByRoles]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getEmployeeByRoles]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_getEmployeeByRoles]
GO
/****** Object:  StoredProcedure [dbo].[sp_getRecordsByUCID]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getRecordsByUCID]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_getRecordsByUCID]
GO
/****** Object:  StoredProcedure [dbo].[sp_getUCIDByPhone]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getUCIDByPhone]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[sp_getUCIDByPhone]
GO
/****** Object:  Table [dbo].[AccessControl]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AccessControl]') AND type in (N'U'))
DROP TABLE [dbo].[AccessControl]
GO
/****** Object:  Table [dbo].[AccessControlType]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AccessControlType]') AND type in (N'U'))
DROP TABLE [dbo].[AccessControlType]
GO
/****** Object:  UserDefinedFunction [dbo].[func_splitString]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[func_splitString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[func_splitString]
GO
/****** Object:  Table [dbo].[ServiceConfig]    Script Date: 12/13/2016 13:58:37 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ServiceConfig]') AND type in (N'U'))
DROP TABLE [dbo].[ServiceConfig]
GO
/****** Object:  Table [dbo].[ServiceConfig]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[ServiceConfig]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[ServiceConfig](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ServiceIP] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ServicePort] [int] NULL,
	[ServiceName] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ServiceUser] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[ServiceSystem] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[CpuUsed] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[MemoryTotal] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
	[MemoryUsed] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_ServiceConfig] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[ServiceConfig] ON
INSERT [dbo].[ServiceConfig] ([ID], [ServiceIP], [ServicePort], [ServiceName], [ServiceUser], [ServiceSystem], [CpuUsed], [MemoryTotal], [MemoryUsed]) VALUES (1, N'172.28.19.34', 32666, NULL, NULL, NULL, NULL, NULL, NULL)
INSERT [dbo].[ServiceConfig] ([ID], [ServiceIP], [ServicePort], [ServiceName], [ServiceUser], [ServiceSystem], [CpuUsed], [MemoryTotal], [MemoryUsed]) VALUES (2, N'172.28.19.20', 32666, N'SH-PC-ESBU8920', N'yongbing.feng', N'Microsoft Windows 7', N'52', N'3037', N'72')
SET IDENTITY_INSERT [dbo].[ServiceConfig] OFF
/****** Object:  UserDefinedFunction [dbo].[func_splitString]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[func_splitString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
BEGIN
execute dbo.sp_executesql @statement = N'
--select * from func_splitString(''1,2,4,5'','','',0)
CREATE function [dbo].[func_splitString] ( 
	@input					nvarchar(max),
	@separator				nvarchar(max) = '','',
	@removeEmptyEntries		bit = 1 --是否返回空值
) 
returns @table table (id int identity(1,1), value nvarchar(max)) 
as 
begin 
	declare @index int, @entry nvarchar(max) 
	set @index = charindex(@separator,@input)
	
	while @index > 0
	begin 
		set @entry = ltrim(rtrim(substring(@input, 1, @index - 1))) 
		if (@removeEmptyEntries = 0) or (@removeEmptyEntries = 1 and @entry <> '''') 
			insert into @table([value]) values(@entry) 
		 
		set @input = substring(@input, @index + datalength(@separator) / 2, len(@input)) 
		set @index = charindex(@separator, @input) 
	end
	
	set @entry = ltrim(rtrim(@input)) 
	if (@removeEmptyEntries = 0) or (@removeEmptyEntries = 1 and @entry <> '''') 
		insert into @table([value]) values(@entry)	 
return 
end
' 
END
GO
/****** Object:  Table [dbo].[AccessControlType]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AccessControlType]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AccessControlType](
	[Type] [smallint] NOT NULL,
	[TypeName] [varchar](50) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_RecordsAccessControlType] PRIMARY KEY CLUSTERED 
(
	[Type] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
INSERT [dbo].[AccessControlType] ([Type], [TypeName]) VALUES (8, N'{en:Project.,zh:项目}')
INSERT [dbo].[AccessControlType] ([Type], [TypeName]) VALUES (9, N'{en:Agent Group.,zh:座席组}')
INSERT [dbo].[AccessControlType] ([Type], [TypeName]) VALUES (10, N'{en:Extension Group.,zh:分机组}')
INSERT [dbo].[AccessControlType] ([Type], [TypeName]) VALUES (11, N'{en:Report-Project.,zh:报表-项目}')
INSERT [dbo].[AccessControlType] ([Type], [TypeName]) VALUES (12, N'{en:Report-Agent.,zh:报表-座席}')
/****** Object:  Table [dbo].[AccessControl]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AccessControl]') AND type in (N'U'))
BEGIN
CREATE TABLE [dbo].[AccessControl](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[EmployeeId] [int] NULL,
	[Type] [smallint] NULL,
	[Items] [text] COLLATE Chinese_PRC_CI_AS NULL,
	[isDownload] [bit] NULL,
 CONSTRAINT [PK_RecordsAccessControl] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON)
)
END
GO
SET IDENTITY_INSERT [dbo].[AccessControl] ON
INSERT [dbo].[AccessControl] ([ID], [EmployeeId], [Type], [Items], [isDownload]) VALUES (160, 22, 3, N'74336,74255,74276', 0)
INSERT [dbo].[AccessControl] ([ID], [EmployeeId], [Type], [Items], [isDownload]) VALUES (161, 22, 9, N'12', 0)
SET IDENTITY_INSERT [dbo].[AccessControl] OFF
/****** Object:  StoredProcedure [dbo].[sp_getUCIDByPhone]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getUCIDByPhone]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--sp_getUCIDByPhone 1,''2150554830'',''20160128 14:00''
--sp_getUCIDByPhone 2,''8920'',''20141030 11:30''
CREATE PROCEDURE [dbo].[sp_getUCIDByPhone]
	@linkserver int,
	@phone	varchar(50),
	@date	varchar(20)
as
begin
	declare @begindate datetime,@enddate datetime,@thisdate varchar(20)
	set @begindate=dateadd(hh,-3,convert(datetime,@date,112)) --前3小时
	set @enddate=dateadd(hh,2,convert(datetime,@date,112))    --后2小时
	set @thisdate=substring(@date,0,charindex('' '',@date))
	
	--select @begindate,@enddate,@thisdate	
	
		select r.recordId,r.ucid,r.startTime,abs(datediff(mi,r.startTime,@date)) st
		from VisionLog41.dbo.Records r
		where (calling=@phone or called=@phone)		
			and r.startDate=@thisdate
			and datediff(mi,r.startTime, @begindate)<=0
			and datediff(mi,r.startTime, @enddate)>=0
		order by st
end' 
END
GO
/****** Object:  StoredProcedure [dbo].[sp_getRecordsByUCID]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getRecordsByUCID]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--sp_getRecordsByUCID 1,''00001057591443954783'',''20151004 09:00''
--sp_getRecordsByUCID 2,''00001058851373622350'',''20130712 08:00''
CREATE PROCEDURE [dbo].[sp_getRecordsByUCID]
	@linkserver int,
	@ucid	varchar(50),
	@date	varchar(20)
as
begin
	declare @begindate datetime,@enddate datetime,@thisdate varchar(20)
	set @begindate=dateadd(hh,-3,convert(datetime,@date,112)) --前3小时
	set @enddate=dateadd(hh,2,convert(datetime,@date,112))    --后2小时
	set @thisdate=substring(@date,0,charindex('' '',@date))
	
	--select @begindate,@enddate,@thisdate
	
	create table #TempTab(ftpid int,ip varchar(20),port varchar(10),folder varchar(50),extip varchar(100))


		insert into #temptab
		select t.ftpid,rtrim(isnull(s.ip,'''')),''80'',rtrim(isnull(t.folder,'''')),s.extip			
		from VisionLog41.dbo.Station s 
			inner join VisionLog41.dbo.Storage t on s.station=t.station
		
		select r.recordId,
			case when r.voiceType<11 then ''http://'' else ''mms://'' end head,
			1 fileCount,r.startDate,r.channel,
			case when t.ext is null then ''mp3'' else t.ext end ext,
			a.ip au_ip,a.extip au_extip,a.port au_port,a.folder au_folder,
			v.ip vu_ip,v.extip vu_extip,v.port vu_port,v.folder vu_folder,
			r.calling,r.called,r.answer
		from VisionLog41.dbo.Records r
			left join #TempTab a on r.audioUrl=a.ftpid
			left join #TempTab v on r.videoUrl=v.ftpid
		
		where r.ucid=@ucid
			and r.startDate=@thisdate
			and datediff(mi,r.startTime, @begindate)<=0
			and datediff(mi,r.startTime, @enddate)>=0
	
	drop table #TempTab
end' 
END
GO
/****** Object:  StoredProcedure [dbo].[sp_getEmployeeByRoles]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getEmployeeByRoles]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--sp_getEmployeeByRoles ''5,6,13''
CREATE PROCEDURE [dbo].[sp_getEmployeeByRoles]
	@roles	varchar(20)
as
begin
	create table #temp(id int, value nvarchar(20))
	insert into #temp 
	select * from func_splitString(@roles, '','', 1)
	
	select distinct e.id,e.account + ''('' + isnull(e.surname,'''')+isnull(e.firstname,'''') + '')'' name
    	from vxi_common..Employee e
    		left join #temp t on 1=1
			left join vxi_common..RoleGroup rg on e.rolegroupid=rg.id			
			left join vxi_common..Role r on charindex('','' + cast(r.id as varchar(10)) + '','', '','' + rg.roles + '','', 0) > 0	
		where e.status=1 
			and (charindex('','' + t.value + '','', '','' + rg.roles + '','', 0) > 0 or r.parentId=t.value)
		order by name
end' 
END
GO
/****** Object:  StoredProcedure [dbo].[sp_getAccessControl]    Script Date: 12/13/2016 13:58:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[sp_getAccessControl]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'
--sp_getAccessControl 3
CREATE PROCEDURE [dbo].[sp_getAccessControl]
	@employeeId	int
as
begin
	declare @items8 varchar(500),@items9 varchar(500),@items10 varchar(500),@sql varchar(5000)
	set @items8 = ''''
	--set @items9 = ''''
	--set @items10 = ''''
	set @sql=''select type,cast(items as varchar(8000)) items from AccessControl 
		where employeeId='' + cast(@employeeId as varchar(20))
	
	--type=8项目，需要重新解析一下items
	select @items8 = @items8 + '','' + cast(items as varchar) from AccessControl 
	where type=8 
		and employeeid=@employeeId
		
	set @items8 = substring(@items8,2,len(@items8))
		
	if @items8 != ''''
		set @sql = @sql + '' union
		select type,value from VisionLog40..ProjectItem pis
		where pis.projId in ('' + @items8 + '')''
	
	--type=9座席组，转换为座席type=1
	--select @items9 = @items9 + '','' + cast(items as varchar) from AccessControl 
	--where type=9
	--	and employeeid=@employeeId
	--set @items9 = substring(@items9,2,len(@items9))
	
	--if @items9 != ''''
	--	set @sql = @sql + '' union
	--	select 3,agentId+'''','''' from VisionLog40..GroupAgent where groupId in ('' + @items9 + '')''
	
	--type=10分机组，转换为分机type=2
	--select @items10 = @items10 + '','' + cast(items as varchar) from AccessControl 
	--where type=10
	--	and employeeid=@employeeId
	--set @items10 = substring(@items10,2,len(@items10))
	
	--if @items10 != ''''
	--	set @sql = @sql + '' union
	--	select 2,address+'''','''' from VisionLog40..GroupAddress where groupId in ('' + @items10 + '')''
	
	print @sql
	exec(@sql)
end' 
END
GO
