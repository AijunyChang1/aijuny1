USE [master]
GO
CREATE DATABASE [vxi_ucd]
GO

USE [vxi_ucd]
GO
/****** Object:  DatabaseRole [ba]    Script Date: 2016/9/5 13:29:41 ******/
CREATE ROLE [ba]
GO
/****** Object:  Schema [hist]    Script Date: 2016/9/5 13:29:41 ******/
CREATE SCHEMA [hist]
GO
/****** Object:  StoredProcedure [dbo].[sp_agent_login_rec]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[sp_agent_login_rec] 
	@time_begin datetime = null,
	@time_end datetime = null,
	@logid bigint = null,
	@agent varchar(20) = null,
	@device varchar(20) = null,
	@skills varchar(20) = null,
	@status int = null
	
AS
BEGIN
/*
	-- 老版本查询
	if @logid  is null  begin
		if @time_begin is null 	set @time_begin = str(year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
		if @time_end  is null 	set @time_end = getdate()

		select  logid, agent, device, skills, (case status when 1 then 'login' else 'ready' end) oper, starttime, 
				dateadd(ms, timelen, starttime) endtime, dbo.ms_to_time(timelen) timelen
			from agentlog
			where  starttime between @time_begin and @time_end
			  and agent = isnull(@agent, agent)
			  and device = isnull(@device, device)
			  and skills = isnull(@skills, skills)
			  and status = isnull(@status, status)
			order by logid desc
	end
	else begin
		select  logid, agent, device, skills, (case status when 1 then 'login' else 'ready' end) oper, starttime, 
				dateadd(ms, timelen, starttime) endtime, dbo.ms_to_time(timelen) timelen
			from agentlog	
			where  logid = @logid
	end
*/

	if @time_begin is null 	set @time_begin = str(year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
	if @time_end is null 	set @time_end = getdate()

	declare @strSQL nvarchar(4000), @WherePart nvarchar(1000)
	
	select
		@WherePart = 
		case when @logid is null then
' where l.starttime between @time_begin and @time_end
	and l.agent = isnull(@agent, l.agent)
	and l.device = isnull(@device, l.device)
	and isnull(l.skills, '''') = isnull(@skills, isnull(l.skills, ''''))
'
		else ' where l.logid = @logid' end,
		
		@strSQL = '
	select LogID, Agent, Device, Skills, case when Flag = 1 then ''login'' else ''logout'' end Oper, StartTime,
		EndTime, dbo.ms_to_time(TimeLen) TimeLen
	from [Login] l' + @WherePart + '
	union all
	select * from 
	(
		select l.LogID, l.Agent, l.Device, l.Skills, ''ready'' Oper, dateadd(ms, r.StartTime, l.StartTime) StartTime,
			dateadd(ms, r.TimeLen, dateadd(ms, r.StartTime, l.StartTime)) EndTime, dbo.ms_to_time(r.TimeLen) TimeLen
		from [Login] l
		inner join Ready r on l.LogID = r.LogID' + @WherePart + '
	) tr
	order by LogID, Oper, Agent'

	--print @strSQL
	
	declare @result int
	exec @result = sp_executesql @strSQL,
					N'@logid		bigint,
					  @time_begin	datetime, 
					  @time_end		datetime,
					  @agent		varchar(20), 
					  @device		varchar(20),
					  @skills		varchar(20)',
					@time_begin = @time_begin,
					@time_end = @time_end,
					@logid = @logid,
					@agent = @agent,
					@device = @device,
					@skills = @skills

	if @@error != 0 or @result != 0 begin
		raiserror('sp_executesql error!', 1, 1)
	end

	return @result

END
GO
/****** Object:  StoredProcedure [dbo].[sp_get_InsertSql]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =======================================================================================
-- Author:		Guozhi.Song
-- CREATE date: 2010.12.20
-- Description:	生成INSERT语句
/* 
Example:	
EXEC sp_get_InsertSql @dbName='wfm_def', 
	@tabList='Action,BaseInfo,CalendarSolarData,CallBack,DataWin,Chart,City,Country,
				Define,DefItem,Dictionary,District,Emails,ExtUsers,Fields,Sort,
				Flow where FlowId != 96,Node where FlowId != 96,Nation,
				Holidays where Nation=1,HotFields,Modules,PrivSort,PrivLoc,Query,
				Roles where Role=1 or Role=2 or Role=3 or Role=4,Service,State,Strings,Tables,Tags,
				TempItems,Template,TempRep,TplFileLib,TreeDef,TreeItem,
				Users where UserId = ''admin'',UserStyle,Version', 
	@IncludeIdentity=1, 
	@DeleteOldData=0		
	
EXEC sp_get_InsertSql @dbName='wfm_biz', 
	@tabList='Project where ProjectId=0,GROUPS  where GroupId = 0,
			 SKILLGROUP WHERE SkillGroup=0,
			 OPTREST,SAMPTYPE,SAMPITEM,SCHETYPE,
			 SITE WHERE SiteId=0,TIMESPAN,
			 POSTS,WORKTAG,SHIFTSORT where ProjectId=0',
	@IncludeIdentity=1, 
	@DeleteOldData=0
EXEC vxi_def..sp_get_InsertSql @dbName='vxi_ivr', 
	@tabList='FaxStatus', 
	@IncludeIdentity=1, 
	@DeleteOldData=0
*/
-- =======================================================================================
create PROC [dbo].[sp_get_InsertSql]
	@dbName				VARCHAR(32)='',	--数据库名称 wfm_biz or wfm_def
	@tabList			VARCHAR(max),	--要导出数据的表名，表名之间用逗号隔开，过滤条件跟在表名后面，用空格隔开 如tab1 where col1!=2, tab2, tab3	
	@IncludeIdentity	BIT=1,			--是否包含自增字段
	@DeleteOldData		BIT=1			--插入前删除所有数据
AS
	DECLARE
		@index		INT, 
		@wi			INT,
		@SQL		VARCHAR(max),
		@SQL1		VARCHAR(max),
		@tabName	VARCHAR(128),
		@colName	VARCHAR(128),
		@colType	VARCHAR(128),
		@tabPrefix	VARCHAR(32),
		@cols		VARCHAR(max),
		@colsData	VARCHAR(max),
		@SQLWhere	VARCHAR(1024),		
		@SQLIdentityOn	VARCHAR(MAX),
		@SQLIdentityOff VARCHAR(MAX),
		@SQLDelete		VARCHAR(max),
		@SQLIfBegin		VARCHAR(1024),
		@SQLIfEnd		VARCHAR(1024),
		@SQLNull		VARCHAR(1024);		
	DECLARE @t_tb TABLE(TB varchar(128), Sqlwhere varchar(1024), SN BIGINT IDENTITY(1,1))
	DECLARE @tb TABLE(insert_sql VARCHAR(max), SN BIGINT IDENTITY(1,1));
	DECLARE @colList TABLE(colName VARCHAR(128), colType VARCHAR(128), 
		colValueL VARCHAR(120), colValueR VARCHAR(120), selColName VARCHAR(128));
	create table #t_tb(TB varchar(128), Sqlwhere varchar(1024), SN BIGINT)
BEGIN
	SET NOCOUNT ON
	SET @tabList = REPLACE(@tabList, CHAR(9), '')
	SET @tabList = REPLACE(@tabList, CHAR(10), '')
	SET @tabList = REPLACE(@tabList, CHAR(13), '')
	SET @dbName = LTRIM(RTRIM(@dbName))
	SET @index = CHARINDEX(',', @tabList)
	IF LEN(@dbName) > 0
		SET @tabPrefix = @dbName + '..'
	ELSE 
		SET @tabPrefix = '';	
	
	WHILE @index > 0 AND @index IS NOT NULL
	BEGIN
		SET @tabName = SUBSTRING(@tabList, 1, @index-1)
		 
		SET @wi=CHARINDEX(' where', LTRIM(@tabName))

		IF @wi=0
			SET @wi = LEN(@tabName)
				
		INSERT INTO @t_tb(tb, Sqlwhere) VALUES(SUBSTRING(@tabName, 1, @wi), SUBSTRING(@tabName, @wi+1, LEN(@tabName)-@wi))

		SET @tabList = SUBSTRING(@tabList, @index+1, LEN(@tabList)-@index)
		SET @index = CHARINDEX(',', @tabList)
	END

	IF @index = 0 OR @index IS NULL
		SET @tabName = @tabList
	ELSE 
		SET @tabName = SUBSTRING(@tabList, 1, @index)
	
	
	SET @wi=CHARINDEX(' where', LTRIM(@tabName))
	
	IF @wi=0
		SET @wi = LEN(@tabName)
	
	INSERT INTO @t_tb(tb, Sqlwhere) VALUES(SUBSTRING(@tabName, 1, @wi), SUBSTRING(@tabName, @wi+1, LEN(@tabName)-@wi))

	SELECT	@SQL1 = 'select INSERT_SQL='';SET NOCOUNT ON'+CHAR(13) + ''''+
					' union all '
	SELECT @SQLNull =	'select INSERT_SQL=''  '' union all ',		
		   @SQLIfBegin = 'select INSERT_SQL=''    If @Error=0 begin '''+
					' union all ',
		   @SQLIfEnd = ' union all ' + 'select INSERT_SQL=''    end;'''
	
	IF @dbName='wfm_biz' BEGIN
		DECLARE tab_cur CURSOR FOR 
		SELECT t.name, tb.Sqlwhere FROM wfm_biz.sys.tables t
		INNER JOIN @t_tb tb ON t.name=RTRIM(LTRIM(tb.TB))
		ORDER BY tb.SN
	END
	ELSE IF @dbName='wfm_def' BEGIN
		DECLARE tab_cur CURSOR FOR 
		SELECT t.name, tb.Sqlwhere FROM wfm_def.sys.tables t
		INNER JOIN @t_tb tb ON t.name=RTRIM(LTRIM(tb.TB))
		ORDER BY tb.SN
	END
	ELSE BEGIN
		insert into #t_tb select * from @t_tb
		
		declare @StrSql varchar(500)
		set @StrSql = '
			DECLARE tab_cur CURSOR FOR 
			SELECT t.name, tb.Sqlwhere FROM ' + @dbName + '.sys.tables t
			INNER JOIN #t_tb tb ON t.name=RTRIM(LTRIM(tb.TB))
			ORDER BY tb.SN'
		--print @StrSql --
		exec(@StrSql)
	END
	
	OPEN tab_cur
	FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere 
	WHILE @@FETCH_STATUS=0 BEGIN
		DELETE FROM @colList

		IF @dbName='wfm_biz' BEGIN
			IF NOT EXISTS(SELECT 1 FROM wfm_biz.sys.objects WHERE name=@tabName AND type='U') BEGIN
				PRINT(@tabName + N' 不存在1！')
				RAISERROR(@tabName, 16, -1);
				FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
				CONTINUE;
			END
		
			INSERT INTO @colList(colName, colType, colValueL, colValueR)
			SELECT c.NAME, t.name, '',''
			FROM wfm_biz.sys.columns c
			INNER JOIN wfm_biz.sys.tables tab
				ON c.object_id = tab.object_id
			INNER JOIN wfm_biz.sys.types t
				ON c.user_type_id = t.user_type_id
			WHERE c.is_computed=0 
				AND tab.name = @tabName

			IF @IncludeIdentity=0
				DELETE FROM @colList WHERE colName IN(
					SELECT c.name FROM wfm_biz.sys.columns c
					INNER JOIN wfm_biz.sys.tables tab
						ON c.object_id = tab.OBJECT_ID
					WHERE is_identity=1)
		END
		ELSE IF @dbName='wfm_def' BEGIN
			IF NOT EXISTS(SELECT 1 FROM wfm_def.sys.objects WHERE name=@tabName AND type='U') BEGIN
				PRINT(@tabName + N' 不存在2！')
				RAISERROR(@tabName, 16, -1);
				FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
				CONTINUE;
			END
			
			INSERT INTO @colList(colName, colType, colValueL, colValueR)
			SELECT c.NAME, t.name, '',''
			FROM wfm_def.sys.columns c
			INNER JOIN wfm_def.sys.tables tab
				ON c.object_id = tab.object_id
			INNER JOIN wfm_def.sys.types t
				ON c.user_type_id = t.user_type_id			
			WHERE c.is_computed=0 
				AND tab.name =@tabName

			IF @IncludeIdentity=0
				DELETE FROM @colList WHERE colName IN(
					SELECT c.name FROM wfm_def.sys.columns c
					INNER JOIN wfm_def.sys.tables tab
						ON c.object_id = tab.OBJECT_ID
					WHERE is_identity=1)
			
		END
		ELSE BEGIN
			IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE name=@tabName AND type='U') BEGIN
				PRINT(@tabName + N' 不存在3！')
				RAISERROR(@tabName, 16, -1);
				FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
				CONTINUE;
			END
			
			INSERT INTO @colList(colName, colType, colValueL, colValueR)
			SELECT c.NAME, t.name, '',''
			FROM sys.columns c
			INNER JOIN sys.tables tab
				ON c.object_id = tab.object_id
			INNER JOIN sys.types t
				ON c.user_type_id = t.user_type_id
			WHERE c.is_computed=0 
				AND tab.name =@tabName

			IF @IncludeIdentity=0
				DELETE FROM @colList WHERE colName IN(
					SELECT name FROM sys.columns WHERE object_id = OBJECT_ID(@tabName) AND is_identity=1)
			
		END
	
		UPDATE @colList SET colValueL='RTRIM(', colValueR = ')' 
		WHERE colType IN('text', 'varchar', 'nvarchar', 'char', 'uniqueidentifier', 'datetime', 'nchar', 'sysname')
		
		SELECT @cols='', @colsData = '', @SQL = '';
		
		UPDATE @colList SET colName = '[' + colName + ']'	
		UPDATE @colList SET selColName=colName		
		
		UPDATE @colList SET colValueL='replace('+colValueL, colValueR = colValueR+','''''''','''''''''''')' 
		WHERE colType IN('text', 'varchar', 'nvarchar', 'char', 'nchar', 'sysname')	
			
		UPDATE @colList SET colValueL= 
			CASE WHEN colType IN('text', 'varchar', 'nvarchar', 'char', 'uniqueidentifier', 'datetime', 'nchar', 'sysname') THEN '''''''''+' ELSE '' END 
				+colValueL,
			colValueR = colValueR + CASE WHEN colType IN('text', 'varchar', 'nvarchar', 'char', 'nchar', 'datetime', 'uniqueidentifier', 'sysname') THEN '+''''''''' ELSE '' END 
				
		SELECT @cols = @cols + colName + ', ',
			@colsData = @colsData + 'isnull(' +
				colValueL +			
				CASE WHEN colType='datetime' THEN 'convert(varchar(20),'+colName+',120)'
				WHEN colType='uniqueidentifier'THEN 'convert(varchar(50),'+colName+')'
				WHEN colType='text'THEN 'convert(nvarchar(max),'+colName+')'
				WHEN colType='sysname'THEN 'convert(nvarchar(max),'+colName+')'
				WHEN colType='varbinary' OR colType='BINARY' OR colType='image' 
					THEN 'master.dbo.fn_varbintohexsubstring(1,'+colName+',1,0)'				
				ELSE  'cast('+colName+' as nvarchar(max))' END 
				+ colValueR + ',''null'')+'', ''+'
		FROM @colList

		SELECT @cols = LEFT(@cols, LEN(@cols)-1),
				@colsData = LEFT(@colsData, LEN(@colsData)-5),
				@SQL = 'select INSERT_SQL=''print ''''Table Name:  '+CHAR(9)+@tabName + ''''''''+
					' union all '
				--@colsNULL = LEFT(@colsNULL, LEN(@colsNULL)-1)
		
		SELECT @cols = 'select INSERT_SQL=''INSERT INTO ' + @tabPrefix + @tabName + '('+@cols+')',
			@colsData = '  VALUES(''+'+ @colsData + '+'');'' FROM '+ @tabPrefix + @tabName 
		SELECT @colsData = @colsData +' '+ ISNULL(@SQLWhere, '')
		--FROM @t_tb WHERE TB=@tabName

		IF @DeleteOldData=1	
			SET @SQLDelete = 'select INSERT_SQL='''' +
					''Delete from '+@tabPrefix + @tabName + '; '''+ 
					' union all '
		ELSE 
			SET @SQLDelete=''
		
		IF @IncludeIdentity=1 AND EXISTS(SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID(@tabName) AND is_identity=1)
		BEGIN
			SELECT @SQLIdentityOn = 'select INSERT_SQL=''SET IDENTITY_INSERT '+@tabPrefix + @tabName + ' ON;'''+
					' union all ',
				@SQLIdentityOff = ' union all ' + 'select INSERT_SQL=''SET IDENTITY_INSERT '+@tabPrefix + @tabName + ' OFF;'''
		END 
		ELSE 
		BEGIN
			SELECT @SQLIdentityOff = '',
				@SQLIdentityOn = '';
		END

		INSERT INTO @tb(insert_sql)
		EXECUTE(@SQLNull + @SQLIfBegin + @SQL+@SQLDelete+@SQLIdentityOn + @cols+@colsData + @SQLIdentityOff + @SQLIfEnd) 
	--PRINT @cols+@colsData	
		FETCH NEXT FROM tab_cur INTO @tabName, @SQLWhere
	END

	CLOSE tab_cur
	DEALLOCATE tab_cur
		
	SELECT insert_sql FROM @tb ORDER BY sn
	
	drop table #t_tb
END


GO
/****** Object:  StoredProcedure [dbo].[sp_get_rt_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rt_agent]
	@skill varchar(20) = null,
	@agent varchar(20) = null,
	@agents varchar(4000) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @sqlstr varchar(4000)
	set @sqlstr = 'select a.*, d.DevFlag from rt_agent a left join rt_device d on a.agent = d.agent where a.enabled = 1'

	if isnull(@agent, '') != '' begin
		set @sqlstr = @sqlstr + ' and a.agent = ''' + ltrim(rtrim(@agent)) + ''''
	end
	else begin
		if isnull(@skill, '') != '' begin
			set @sqlstr = @sqlstr + ' and a.skills like ''%' + ltrim(rtrim(@skill)) + '%'''
		end
		if isnull(@agents, '') != '' begin
			set @sqlstr = @sqlstr + ' and ''' + @agents + ''' like ''%'' + ltrim(rtrim(a.agent)) + ''%'''
		end
	end
	set @sqlstr = @sqlstr + ' order by a.agent'
	-- print @sqlstr
	exec( @sqlstr )
END

GO
/****** Object:  StoredProcedure [dbo].[sp_get_rt_device]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rt_device]
	@device varchar(20) = null,
	@agent varchar(20) = null,
	@skill varchar(20) = null,
	@devices varchar(4000) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @sqlstr varchar(4000)
	set @sqlstr = 'select * from rt_device where enabled = 1'

	if isnull(@device, '') != '' begin
		set @sqlstr = @sqlstr + ' and device = ''' + ltrim(rtrim(@device)) + ''''
	end
	else if isnull(@agent, '') != '' begin
		set @sqlstr = @sqlstr + ' and agent = ''' + ltrim(rtrim(@agent)) + ''''
	end
	else begin
		if isnull(@skill, '') != '' begin
			set @sqlstr = @sqlstr + ' and skills like ''%' + ltrim(rtrim(@skill)) + '%'''
		end
		if isnull(@devices, '') != '' begin
			set @sqlstr = @sqlstr + ' and ''' + @devices + ''' like ''%'' + ltrim(rtrim(device)) + ''%'''
		end
	end
	set @sqlstr = @sqlstr + ' order by device'
	print @sqlstr
	exec( @sqlstr )
END


GO
/****** Object:  StoredProcedure [dbo].[sp_get_stat_call]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_get_stat_call]
	@time_begin datetime = null,
	@time_end datetime = null,
	@split_tm int = 30
AS
	declare @dt_begin bigint, @dt_end bigint

	if @time_begin is null	set @time_begin = str(dbo.get_day(getdate()))
	if @time_end is null 	set @time_end = getdate()
	
	set @dt_begin = dbo.time_to_bigint(@time_begin, @split_tm)
	set @dt_end = dbo.time_to_bigint(dateadd(ss, -1, @time_end), @split_tm)

	select * from stat_call
		where recdt between @dt_begin and @dt_end
		order by recdt desc
GO
/****** Object:  StoredProcedure [dbo].[sp_get_stat_call_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_get_stat_call_agent]
	@time_begin datetime = null,
	@time_end datetime = null,
	@agent varchar(20) = null,
	@split_tm int = 30
AS
	declare @dt_begin bigint, @dt_end bigint

	if @time_begin is null 	set @time_begin = str(dbo.get_day(getdate()))
	if @time_end is null 	set @time_end = getdate()
	
	set @dt_begin = dbo.time_to_bigint(@time_begin, @split_tm)
	set @dt_end = dbo.time_to_bigint(dateadd(ss, -1, @time_end), @split_tm)
	
	if @agent = ''	set @agent = null

	select * from stat_call_agent
		where recdt between @dt_begin and @dt_end
			and agent = isnull(@agent, agent)
		order by recdt desc, agent
GO
/****** Object:  StoredProcedure [dbo].[sp_get_stat_call_ext]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE   PROCEDURE [dbo].[sp_get_stat_call_ext]
	@time_begin datetime = null,
	@time_end datetime = null,
	@ext varchar(20) = null,
	@split_tm int = 30
AS
	declare @dt_begin bigint, @dt_end bigint

	if @time_begin is null 	set @time_begin = str(dbo.get_day(getdate()))
	if @time_end is null 	set @time_end = getdate()
	
	set @dt_begin = dbo.time_to_bigint(@time_begin, @split_tm)
	set @dt_end = dbo.time_to_bigint(dateadd(ss, -1, @time_end), @split_tm)
	
	if @ext = ''	set @ext = null

	select * from stat_call_ext
		where recdt between @dt_begin and @dt_end
			and ext = isnull(@ext, ext)
		order by recdt desc, ext


GO
/****** Object:  StoredProcedure [dbo].[sp_get_stat_call_skill]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO


create   PROCEDURE [dbo].[sp_get_stat_call_skill]
	@time_begin datetime = null,
	@time_end datetime = null,
	@skill varchar(20) = null,
	@split_tm int = 30
AS
	declare @dt_begin bigint, @dt_end bigint

	if @time_begin is null 	set @time_begin = str(dbo.get_day(getdate()))
	if @time_end is null 	set @time_end = getdate()
	
	set @dt_begin = dbo.time_to_bigint(@time_begin, @split_tm)
	set @dt_end = dbo.time_to_bigint(dateadd(ss, -1, @time_end), @split_tm)
	
	if @skill = ''	set @skill = null

	select * from stat_call_skill
		where recdt between @dt_begin and @dt_end
			and skill = isnull(@skill, skill)
		order by recdt desc, skill


GO
/****** Object:  StoredProcedure [dbo].[sp_get_stat_call_trunk]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE     PROCEDURE [dbo].[sp_get_stat_call_trunk]
	@time_begin datetime = null,
	@time_end datetime = null,
	@GrpId int = null,
	@split_tm int = 30
AS
--	declare @dt_begin bigint, @dt_end bigint
--
--	if @time_begin is null 	set @time_begin = str(dbo.get_day(getdate()))
--	if @time_end is null 	set @time_end = getdate()
--	
--	set @dt_begin = dbo.time_to_bigint(@time_begin, @split_tm)
--	set @dt_end = dbo.time_to_bigint(dateadd(ss, -1, @time_end), @split_tm)
--	
--	if @GrpId <= 0	set @GrpId = null
--
--	select * from stat_call_trunk
--		where recdt between @dt_begin and @dt_end
--			and GrpId = isnull(@GrpId, GrpId)
--		order by recdt desc, GrpId





GO
/****** Object:  StoredProcedure [dbo].[sp_get_stat_param]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-04-23>
-- Description:	<计算统计查询日期范围>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_stat_param]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0 out,			-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报
	
	@PrjID int = 0,					-- 缺省0表示所有项目
	@Skill varchar(20) = null,		-- 缺省null表示所有技能组
	@Skills varchar(100) = null,	-- 缺省null表示所有技能组
	@Agent varchar(20) = null,		-- 缺省null表示所有坐席

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null out,		-- 需要统计的起始时间 
	@Time_End datetime = null out,			-- 需要统计的结束时间
	@date_group varchar(10) = 'day' out,	-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30,						-- 统计间隔时长, 单位：分
	
	-- 指定统计时间返回内某一具体时段（如：9:00 - 10:00）
	@PeriodTimeBegin datetime = null,		-- 某一具体时段的起始时间
	@PeriodTimeEnd datetime = null,			-- 某一具体时段的结束时间

	-- 传回参数
	@RoundBegin bigint out,					-- 圆整过的起始日期时间值
	@RoundEnd bigint out,					-- 圆整过的结束日期时间值
	@DisplayPart nvarchar(512) out,			-- sql显示部分
	@GroupPart nvarchar(512) out,			-- sql分组部分
	@WherePart nvarchar(512) out			-- sql条件过滤部分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit

	-------------------- 计算统计时间范围 --------------------------------
	set @SpecBeginEnd = case when @Time_Begin is not null then 1 else 0 end
	if @SpecBeginEnd = 1 begin
		-- 按照时间段取
		if @Time_End is null begin
			set @Time_End = getdate()
		end
	end
	else begin
		-- 开始时间为空，按照@RepDate计算
		set @Error = 0

		if (@RepDate <= 0) begin
			set @RepDate = convert(varchar(8), getdate(), 112)	-- yyyyMMdd
		end

		if (@RepDate between 19001122 and 99998877) begin

			declare @Year int, @Month int, @Day int
			select @Year = @RepDate / 10000, @Month = (@RepDate - @Year * 10000) / 100, @Day = @RepDate % 100

			-- 数据库中的字段Repdate格式为一yyyyMMddhhmm的bigint

			if @Month = 0 /*and @Day = 0*/ begin
				-- mm = 00 & dd = 00：年报
				select @Time_Begin = cast(@Year as char(4)) + '0101', 
					   @Time_End = dateadd(year, 1, @Time_Begin),		-- 计算范围为1年
					   @date_group = 'month'							-- 年报按照月份分组
				set @Error = @@error
			end
			else if (@Month between 1 and 12) begin
				if @Day = 0	begin
					-- mm = 01～12 & dd = 00：月报
					select @Time_Begin = cast((@Year * 100 + @Month) as char(6)) + '01', 
						   @Time_End = dateadd(month, 1, @Time_Begin),	-- 计算范围为1月
						   @date_group = 'day'							-- 月报按照天分组
				end
				else begin
					-- mm = 01～12 & dd > 0：日报
					select @Time_Begin = cast((@RepDate) as char(8)), 
						   @Time_End = dateadd(day, 1, @Time_Begin),	-- 计算范围为1天
						   @date_group = ''								-- 日报不按照时间字段分组
				end
				set @Error = @@error
			end
			else if @Month = 20 and (@Day between 1 and 4) begin
				-- mm = 20 & dd = 01～04：季报
				select @Time_Begin = cast(@Year as char(4)) + '0101',
					   @Time_Begin = dateadd(month, (@Day - 1) * 3, @Time_Begin),
					   @Time_End = dateadd(month, 3, @Time_Begin),	-- 计算范围为3月=1季度
					   @date_group = 'month'						-- 季报按照月分组
				set @Error = @@error
			end
			else if @Month = 30 and (@Day between 1 and 53) begin
				-- mm = 30 & dd = 01～53：周报
				select @Time_Begin = cast(@Year as char(4)) + '0101',
					   @Time_Begin = dateadd(day, (@Day - 1) * 7, @Time_Begin),
					   @Time_End = dateadd(day, 7, @Time_Begin),	-- 计算范围为1周
					   @date_group = 'day'							-- 周报按照天分组
				set @Error = @@error
			end
			else begin
				set @Error = 1
			end

		end
		else begin
			set @Error = 1
		end

		if @Error != 0 begin
			raiserror('The format of parameter ''@RepDate''[%d] is invalid, use as ''yyyymmdd''', 1, 1, @RepDate)
			return @Error
		end
	end

	-- RecDT 格式 yyyyMMddhhmm
	if @date_group = 'year' begin -- 按年分组
		select @DisplayPart = 'cast(RecDT as char(4))',
			   @GroupPart = 'RecDT/100000000'
	end
	else if @date_group = 'month' begin	-- 按月分组
		select @DisplayPart = 'vxi_def.dbo.strdate_to_str(RecDT)',
			   @GroupPart = 'RecDT/1000000'
	end
	else if @date_group = 'week' begin	-- 按星期分组
		declare @strBeginTime char(8)
		select @strBeginTime = convert(char(8), @Time_Begin, 112),
			   @DisplayPart = 'vxi_def.dbo.week_series_to_str(''' 
											+ @strBeginTime
											+ ''',RecDT)',
			   @GroupPart = 'vxi_def.dbo.week_series(''' 
									+ @strBeginTime
									+ ''',cast((RecDT/10000) as char(8)))'
	end
	else if @date_group = 'day' begin	-- 按天分组
		select @DisplayPart = 'vxi_def.dbo.strdate_to_str(RecDT)',
			   @GroupPart = 'RecDT/10000'
	end
	else begin	-- 不分组
		select @DisplayPart = 'vxi_def.dbo.strdate_to_str(RecDT)',
			   @GroupPart = 'RecDT'
	end

	select  @RoundBegin = dbo.time_to_bigint(@Time_Begin, @SplitTm),	--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
			@RoundEnd = dbo.time_to_bigint(@Time_End, @SplitTm)			--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm

	if @SpecBeginEnd = 0 begin	-- 不按照时间段取数
		-- 查询范围调整为半开半闭区间[@RoundBegin, @RoundEnd)
		set @RoundEnd = @RoundEnd - 1
	end

	-- 生成where部分
	set @WherePart = ''
	if @PrjID != 0 begin
		set @WherePart = @WherePart + ' and PrjID=' + cast(replace(@PrjID, '''', '') as nvarchar(11))
	end

	if len(isnull(@Skill, '')) > 0 begin
		set @WherePart = @WherePart + ' and Skill=''' + replace(@Skill, '''', '') + ''''
	end

	if len(isnull(@Skills, '')) > 0 begin
		set @WherePart = @WherePart + ' and CharIndex(''' + replace(@Skills, '''', '') + ','',rtrim(Skills)+'','')>0'
	end

	if len(isnull(@Agent, '')) > 0 begin
		set @WherePart = @WherePart + ' and Agent=''' + replace(@Agent, '''', '') + ''''
	end

	if @PeriodTimeBegin is not null and @PeriodTimeEnd is not null begin
		-- 添加统计范围内的具体时段
		-- 200611010800
		declare @RoundPeriodTimeBegin int, @RoundPeriodTimeEnd int
		select @RoundPeriodTimeBegin = dbo.get_time(@PeriodTimeBegin, @SplitTm),
			   @RoundPeriodTimeEnd = dbo.get_time(@PeriodTimeEnd, @SplitTm)
		set @WherePart = @WherePart + ' and (RecDT%10000 between ' 
					   + cast(@RoundPeriodTimeBegin as varchar(4)) + ' and '
					   + cast(@RoundPeriodTimeEnd as varchar(4)) + ')'
	end

	set @WherePart = @WherePart + ' '

	return 0
END

GO
/****** Object:  StoredProcedure [dbo].[sp_history_archive]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2012.8.3>
-- Description:	<历史数据转移到备份表中>
-- hist.devlog/hist.login/hist/hist.ready
-- hist.ucdcall/hist.ucditem/hist.ucd
/*Example:
exec [dbo].[sp_history_archive] @keepmonths=16
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_history_archive]
	@keepmonths tinyint = null
AS
begin try
	declare @keepdate	int,
			@keeplogid	bigint,
			@error		int
			
	set @keepmonths = isnull(@keepmonths, 12)
	set @error = 0
	
	set @keepdate = convert(varchar(8), dateadd(m, -@keepmonths, getdate()), 112)
	set @keeplogid = cast(@keepdate as bigint) * 1000000

	begin
		begin tran
		insert into hist.devlog 
			select * from dbo.devlog m
				where logid < @keeplogid
					and not exists(select 1 from hist.devlog s
									where s.logid = m.logid)
		set @error = @@error
		
		if @error = 0 begin
			delete from dbo.devlog where logid < @keeplogid
			set @error = @@error
		end
		
		if @error = 0 begin
			commit tran
		end
		else begin
			rollback tran
		end
	end
	
	begin
		begin tran
		insert into hist.login
			select * from dbo.login m
				where logid < @keeplogid
					and not exists(select 1 from hist.login s
										where s.logid = m.logid)
		set @error = @@error
		
		if @error = 0 begin
			delete from dbo.login where logid < @keeplogid
		end
		
		if @error = 0 begin
			commit tran
		end
		else begin
			rollback tran
		end 
	end
	
	begin
		begin tran
		insert into hist.ready
			select * from dbo.ready m
				where logid < @keeplogid
					and not exists(select 1 from hist.ready s
										where s.logid = m.logid)
		set @error = @@error
		
		if @error = 0 begin
			delete from dbo.ready where logid < @keeplogid
		end
		
		if @error = 0 begin
			commit tran
		end
		else begin
			rollback tran
		end 
	end
	
	begin
		begin tran
		insert into hist.ucdcall
			select * from dbo.ucdcall m
				where ucdid < @keeplogid
					and not exists(select 1 from hist.ucdcall s
										where s.ucdid = m.ucdid)
		set @error = @@error
		
		if @error = 0 begin
			delete from dbo.ucdcall where ucdid < @keeplogid
		end
		
		if @error = 0 begin
			commit tran
		end
		else begin
			rollback tran
		end 
	end
	
	begin
		begin tran
		insert into hist.ucditem
			select * from dbo.ucditem m
				where ucdid < @keeplogid
					and not exists(select 1 from hist.ucditem s
										where s.ucdid = m.ucdid)
		set @error = @@error
		
		if @error = 0 begin
			delete from dbo.ucditem where ucdid < @keeplogid
		end
		
		if @error = 0 begin
			commit tran
		end
		else begin
			rollback tran
		end 
	end
	
	begin
		begin tran
		insert into hist.ucd
			select * from dbo.ucd m
				where ucdid < @keeplogid
					and not exists(select 1 from hist.ucd s
										where s.ucdid = m.ucdid)
		set @error = @@error
		
		if @error = 0 begin
			delete from dbo.ucd where ucdid < @keeplogid
		end
		
		if @error = 0 begin
			commit tran
		end
		else begin
			rollback tran
		end 
	end
	
	
	
end try
begin catch
	if @@trancount > 0 rollback
	print '[sp_history_archive]执行失败!'
end catch


GO
/****** Object:  StoredProcedure [dbo].[sp_history_clear]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		Anqing.chen
-- Create date: 2011.06.08
-- Description:	清除历史纪录，减少数据库体积
-- Example:		sp_history_clear @date = 20110301
-- =============================================
CREATE PROCEDURE [dbo].[sp_history_clear]
	@date int = 20100101	-- 清除记录的截止日期
AS
BEGIN
	SET NOCOUNT ON;
	declare @recid bigint
	set @recid = cast(@date as bigint) * 1000000  
	delete from ucditem where ucdid < @recid
	delete from ucdcall where ucdid < @recid
	delete from ucd where ucdid < @recid
	delete from devlog where logid < @recid
	delete from ready where logid < @recid
	delete from login where logid < @recid
END


GO
/****** Object:  StoredProcedure [dbo].[sp_import_agent_data_from_server]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_import_agent_data_from_server]
	-- Add the parameters for the stored procedure here
	@ServerIP nvarchar(200),
	@User nvarchar(50) = 'sa',
	@Password nvarchar(50),
	@ImportDate datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @strSQL nvarchar(4000)
	declare @Result	int
	
	-- add linked server if specific server does not exists
	IF NOT EXISTS (SELECT srvname FROM master..sysservers WHERE srvid != 0 AND srvname = @ServerIP) begin
		EXEC master.dbo.sp_addlinkedserver @server = @ServerIP, @srvproduct=N'SQL Server'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'collation compatible', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'data access', @optvalue=N'true'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'dist', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'pub', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'rpc', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'rpc out', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'sub', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'connect timeout', @optvalue=N'0'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'collation name', @optvalue=null
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'lazy schema validation', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'query timeout', @optvalue=N'0'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'use remote collation', @optvalue=N'true'
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @ServerIP, @locallogin = NULL, @useself = N'False', @rmtuser = @User, @rmtpassword = @Password
	end

	if @ImportDate is null begin
		raiserror('@ImportDate could not be ''NULL''', 1, 1)
		return 1
	end

	declare @ImportDateBegin bigint, @ImportDateEnd bigint
	select	@ImportDateBegin = cast(convert(varchar(8), @ImportDate, 112) as bigint) * 1000000,
			@ImportDateEnd = @ImportDateBegin + 999999,
			@ServerIP = '[' + @ServerIP + '].vxi_ucd.dbo.'

	--print @ImportDateBegin
	--print @ImportDateEnd

	begin tran

	-- import Login
	delete from [Login] where Logid between @ImportDateBegin and @ImportDateEnd
	set @strSQL = 'insert into [Login] (LogID, Agent, Device, Skills, Finish, Flag, StartTime,
						TimeLen, ReadyLen, AcwLen, cause) 
				   select LogID, Agent, Device, Skills, Finish, Flag, StartTime,
						TimeLen, ReadyLen, AcwLen, cause from ' + @ServerIP 
				+ '[Login] where Logid between @ImportDateBegin and @ImportDateEnd'
	exec @Result = sp_executesql @strSQL,
								 N'@ImportDateBegin bigint, @ImportDateEnd bigint',
								 @ImportDateBegin = @ImportDateBegin,
								 @ImportDateEnd = @ImportDateEnd

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''[Login]'' fail', 1, 1)
		set @Result = 2
		goto ExitWithRollback
	end

	-- import Ready
	delete from Ready where Logid between @ImportDateBegin and @ImportDateEnd
	set @strSQL = 'insert into Ready (LogID, SubID, Finish, Flag, StartTime, TimeLen, cause) 
				   select LogID, SubID, Finish, Flag, StartTime, TimeLen, cause from ' + @ServerIP 
				+ 'Ready where Logid between @ImportDateBegin and @ImportDateEnd'
	exec @Result = sp_executesql @strSQL,
								 N'@ImportDateBegin bigint, @ImportDateEnd bigint',
								 @ImportDateBegin = @ImportDateBegin,
								 @ImportDateEnd = @ImportDateEnd

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''Ready'' fail', 1, 1)
		set @Result = 3
		goto ExitWithRollback
	end

	-- import DevLog
	delete from DevLog where Logid between @ImportDateBegin and @ImportDateEnd
	set @strSQL = 'insert into DevLog (LogId, Device, AgentLogId, OldFlag, DevFlag,
						BegTime, TimeLen, Finished) 
				   select LogId, Device, AgentLogId, OldFlag, DevFlag,
						BegTime, TimeLen, Finished from ' + @ServerIP 
				+ 'DevLog where Logid between @ImportDateBegin and @ImportDateEnd'
	exec @Result = sp_executesql @strSQL,
								 N'@ImportDateBegin bigint, @ImportDateEnd bigint',
								 @ImportDateBegin = @ImportDateBegin,
								 @ImportDateEnd = @ImportDateEnd

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''DevLog'' fail', 1, 1)
		set @Result = 4
		goto ExitWithRollback
	end

	commit tran
	return 0

ExitWithRollback:
	rollback tran
	return @Result

END


GO
/****** Object:  StoredProcedure [dbo].[sp_insert_cdrlog]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[sp_insert_cdrlog]
	@Calling varchar(30) = '',
	@Called varchar(30) = '',
	@Route varchar(20) = '',
	@CallDate varchar(8) = '',
	@CallTime varchar(4) = '',
	@TimeLen int = 0,
	@InGroup int = 0,
	@InMember int = 0,
	@OutGroup int = 0,
	@OutMember int = 0,
	@Frl char(1) = ''
AS
	insert CdrLog (CdrId,CallId,Calling,Called,Route,CallDate,CallTime,TimeLen,InGroup,InMember,InTrunk,OutGroup,OutMember,OutTrunk,Extension,Agent,PrjId,Frl) 
	           values(0,0,@Calling,@Called,@Route,@CallDate,@CallTime,@TimeLen,@InGroup,@InMember,0,@OutGroup,@OutMember,0,'0','0',0,@Frl)
GO
/****** Object:  StoredProcedure [dbo].[sp_insert_ucd_mail]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		yanwei.mao@vxichina.com
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_insert_ucd_mail] 
	-- Add the parameters for the stored procedure here
	@OperFlag char(1),					-- 'I' - insert, 'U' - update, 'A' - auto
	@UcdID bigint,
	@MailType tinyint = null,
	@MailFrom varchar(100) = null,
	@MailTo varchar(1200) = null,
	@MailCopy varchar(1200) = null,
	@MailSubject varchar(300) = null,
	@MailText text = null,
	@FtpID smallint = null,
	@MailFiles text = null,
	@PriorID bigint = null,
	@MailTime datetime = null,
	@Skill varchar(20) = null,
	@Agent varchar(20) = null,
	@bPush bit = null,
	@OnPush int = null,
	@bPopup bit = null,
	@OnPopup int = null,
	@bOpen bit = null,
	@OnOpen int = null,
	@bHold bit = null,
	@OnHold int = null,
	@bReopen bit = null,
	@OnReopen int = null,
	@bTrans bit = null,
	@OnTrans int = null,
	@TransTo varchar(100) = null,
	@bSend bit = null,
	@OnSend int = null,
	@OnEnd int = null,
	@PrjID int = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @TimeLen int

    if @UcdID is null begin
		return -1
	end
	
	-- 计算ucd中timelen
	set @TimeLen = case when @OnEnd is null then 0 else @OnEnd end

	-- 判断记录插入还是更新
	set @OperFlag = upper(isnull(@OperFlag, 'A'))
	if @OperFlag in ('A', '')  begin
		-- 自动检测
		if exists(select * from UcdEmail where UcdID = @UcdID) begin
			-- 记录已存在，更新操作
			set @OperFlag = 'U'
		end
		else begin
			-- 不存在，新增操作
			set @OperFlag = 'I'
		end
	end

	-- 查找prjid
	if isnull(@PrjID, 0) <= 0 begin
		set @PrjId = vxi_rec.dbo.find_match_prjid(0,
												  @Skill,
								  	  			  @Agent,
								  	  			  '',
								  	  			  '',
								  	  			  '',
								  	  			  ''
								 	 			 )
	end

	if @OperFlag = 'I' begin
		-- 插入
		-- email类型：0-Inner，1-inbound，2-outbound，4-feedback
		INSERT INTO [Ucd]
			   (
				[UcdId], [UcdType], [ClientId], [Calling], [Called], [Answer], 
				[Route], [Skill], [Trunk], [StartTime], [TimeLen], [Inbound], [Outbound], 
				[Extension], [Agent], [UcdDate], [UcdHour], 
				[PrjId], [UCID], [UUI]
			   )
		 VALUES
			   (
				@UcdId, 2, NULL, @MailFrom, cast(@MailTo as varchar(100)), cast(@MailTo as varchar(100)), 
				'',	@Skill,	'', @MailTime, @TimeLen, 
				case when @MailType & 1 = 1 then 1 else 0 end, -- <Inbound, bit,>,
				case when @MailType & 2 = 2 then 1 else 0 end, -- <Outbound, bit,>,
				'', @Agent, dbo.get_day(@MailTime), datepart(hour, @MailTime),
				@PrjId, '', ''
			   )

		INSERT INTO [UcdEmail] 
			   (
				[UcdID], [MailType], [MailFrom], [MailTo], [MailCopy], [MailSubject], [MailText], [FtpID], 
			    [MailFiles], [PriorID], [MailTime], [Skill], [Agent], [bPush], [OnPush], [bPopup], [OnPopup], 
			    [bOpen], [OnOpen], [bHold], [OnHold], [bReopen], [OnReopen], [bTrans], [OnTrans], [TransTo], 
			    [bSend], [OnSend], [OnEnd], [PrjID]
			   )
		VALUES ( 
				@UcdID, @MailType, @MailFrom, @MailTo, @MailCopy, @MailSubject, @MailText, @FtpID, 
				@MailFiles, @PriorID, @MailTime, @Skill, @Agent, @bPush, @OnPush, @bPopup, @OnPopup, 
				@bOpen, @OnOpen, @bHold, @OnHold, @bReopen, @OnReopen, @bTrans, @OnTrans, @TransTo, 
				@bSend, @OnSend, @OnEnd, @PrjID
			  )
	end
	else begin
		-- 更新
		UPDATE [Ucd]
		   SET [TimeLen] = @TimeLen
			  ,[PrjID] = @PrjId
			  ,[Agent] = @Agent
		   WHERE UcdID = @UcdID

		UPDATE [UcdEmail]
		   SET [PriorID] = @PriorID
			  ,[Skill] = @Skill
			  ,[Agent] = @Agent
			  ,[bPush] = @bPush
			  ,[OnPush] = @OnPush
			  ,[bPopup] = @bPopup
			  ,[OnPopup] = @OnPopup
			  ,[bOpen] = @bOpen
			  ,[OnOpen] = @OnOpen
			  ,[bHold] = @bHold
			  ,[OnHold] = @OnHold
			  ,[bReopen] = @bReopen
			  ,[OnReopen] = @OnReopen
			  ,[bTrans] = @bTrans
			  ,[OnTrans] = @OnTrans
			  ,[TransTo] = @TransTo
			  ,[bSend] = @bSend
			  ,[OnSend] = @OnSend
			  ,[OnEnd] = @OnEnd
			  ,[PrjID] = @PrjID
		   WHERE UcdID = @UcdID
	end
END




GO
/****** Object:  StoredProcedure [dbo].[sp_sch_stat_call_old]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE    PROCEDURE [dbo].[sp_sch_stat_call_old]
	@time_begin datetime = null,
	@time_end datetime = null,
	@recdt bigint = null,
	@sch_key varchar(20) = null,		-- 查询键，支持：null / agent / ext / skill / trunk
	@sch_value varchar(1000) = null,	-- 查询值，支持：指具体的
	@split_tm int = 30
AS
	declare @dt_begin bigint, @dt_end bigint
	declare @strSQL nvarchar(4000), @strTblName varchar(20), @strFldName varchar(20)
	declare @result int

	if @time_begin is null	set @time_begin = str(dbo.get_day(getdate()))
	if @time_end is null 	set @time_end = getdate()
	
	set @dt_begin = dbo.time_to_bigint(@time_begin, @split_tm)
	set @dt_end = dbo.time_to_bigint(dateadd(ss, -1, @time_end), @split_tm)

	if ltrim(rtrim(@sch_value)) = '' begin
		set @sch_value = null
	end

	set @sch_key = ltrim(rtrim(@sch_key))
	set @strFldName = null
	set @strSQL = ''

	if len(@sch_key) > 0  begin
		--非null, ''
		if @sch_key not in ('agent', 'ext', 'skill', 'trunk') begin
			raiserror('查询键，支持：null / agent / ext / skill / trunk', 0, 1)
			select null
			return 1
		end
		
		set @strTblName = 'stat_call_' + @sch_key

		if not (@sch_value is null) begin

			if @sch_key <> 'trunk' begin
				set @strFldName = @sch_key
			end
			else begin
				set @strFldName = 'GrpId'
			end
			
			set @strSQL = ' and (' + @strFldName + ' in (' + @sch_value + '))'
		end

	end
	else begin
		--为null or ''
		set @strTblName = 'stat_call'
	end

		
	set @strSQL = 'select * from ' + @strTblName 
		+ ' where (RecDT between ' + cast(@dt_begin as varchar(19)) 
		+ ' and ' + cast(@dt_end as varchar(19))
		+ ') ' + @strSQL + ' order by Recdt desc' + isnull(',' + @strFldName, '')
	
	print @strSQL

	exec @result = sp_executesql @strSQL
	if @result <> 0 begin
		raiserror('sp_executesql错误', 0, 1)
	end
	return @result	--0（成功）或 1（失败）
GO
/****** Object:  StoredProcedure [dbo].[sp_sch_stat_call_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE              PROCEDURE [dbo].[sp_sch_stat_call_report]
	@RecDT int = null,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，注：mm = 0 表示年报，dd = 0 表示月报
	@time_begin datetime = null,		-- 起始时间
	@time_end datetime = null,			-- 截止时间
	@split_tm int = 30,					-- 整数倍时间，配合@time_begin/@time_end有效（分钟）
	@sch_key varchar(20) = null,		-- 查询键，支持：null / agent / agent_g / agent_t / ext / skill / trunk
	@sch_value varchar(1000) = null,	-- 查询值，支持：指具体的
	@group_level varchar(20) = null		-- 分组级别（all, year, month, week, day, record）
AS
	declare @strSQL nvarchar(4000), @strTblName varchar(20), @strWhere varchar(1500) --, @strWhere_t varchar(1500)
	declare @strGroupby varchar(500), @GroupDiv int
	declare @TotalRelaField varchar(500), @RelaField varchar(500), @RelaField2 varchar(500) 
	declare @RecDTExp varchar(500)
	declare @strOrder varchar(100)
	declare @RecDT_begin_int bigint, @RecDT_end_int bigint

	--计算分组级别
	set @GroupDiv = case @group_level 
						when 'record' then 0
						when 'day' then 4
						when 'week' then 5
						when 'month' then 6
						when 'year' then 8
						when 'all'	then 9
					end	--otherwise then null

	if isnull(@RecDT, 0) = 0 begin

		--@RecDT缺省，采用@time_begin/@time_end
		if @time_begin is null
			set @time_begin = vxi_def.dbo.datetime_to_datestr(getdate() - 7) + ' 00:00:00'
		if @time_end is null
			set @time_end = vxi_def.dbo.datetime_to_datestr(getdate()) + ' 23:59:59'

		set @RecDT_begin_int = dbo.time_to_bigint(@time_begin, @split_tm)	--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
		set @RecDT_end_int = dbo.time_to_bigint(@time_end, @split_tm)		--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm

		--求默认分组级别
		if @GroupDiv is null begin
			declare @timediff int
			set @timediff = datediff(day, @time_begin, @time_end)
			set @GroupDiv = case
								when @timediff <= 7 then 0	--按时分组
								when @timediff <= 31 then 5	--按星期分组
								else 4						--按日分组
							end
		end

	end
	else begin	--@RecDT没有缺省

		declare @RecDtLen int, @AddDt int
		set @RecDtLen = len(@RecDT)
		if @RecDtLen < 12 begin
			--计算查询时间的范围
			set @AddDt = power(10, 12 - @RecDtLen)
			set @RecDT_begin_int = cast(@RecDt as bigint) * @AddDt			--yyyyMMdd0000 / yyyyMM000000 / ...
			set @RecDT_end_int = cast((@RecDt + 1) as bigint) * @AddDt - 1	--yyyyMMdd9999 / yyyyMM999999 / ...
			
			--求默认分组级别
			if @GroupDiv is null begin
				if @RecDtLen < 8
					set @RecDT = @RecDT * power(10, 8 - @RecDtLen)	--长度补足8位		

				if @RecDT / 100 % 100 = 0	-- mm = 0, @RecDT = 20060000
					set @GroupDiv = 6		-- 年报，按月分组
				else if @RecDT % 100 = 0	-- dd = 0, @RecDT = 20060300
					set @GroupDiv = 4		-- 月报，按日分组
				else						-- @RecDT = 20060318
					set @GroupDiv = 0		-- 日报，按时分组
			end
		end

	end


	--写Where子句，注：RecDT格式yyyymmddhhmm, @RecDT格式yyyymmdd
	set @strWhere = ' Where (RecDT between ' + cast(@RecDT_begin_int as varchar(20)) 
				  + ' and ' + cast(@RecDT_end_int as varchar(20)) + ')'		--RecDT has a clustered index, yyyyMMddhhmm
	--set @strWhere_t = ''

	--写Group by子句
	set @strGroupby = case @GroupDiv
						when 0 then	' Group By RecDT'	--日报，按时分组
						when 5 then ' Group By vxi_def.dbo.week_series(''' 
									+ cast((@RecDT_begin_int / 10000) as varchar(8)) 
									+ ''', cast((RecDT / 10000) as varchar(8)))'	--按星期分组
						when 9 then ' Group By '	--仅按照关联表字段分组
						else ' Group By (RecDT / power(10, ' + cast(@GroupDiv as varchar(1)) + '))' --其他
					  end

	set @RecDTExp = substring(@strGroupby, 11, len(@strGroupby))

	--处理查询键
	set @sch_key = ltrim(rtrim(isnull(@sch_key, '')))
	if len(@sch_key) > 0 begin
		--非null, ''
		if @sch_key not in ('agent', 'agent_g', 'agent_t', 'ext', 'skill', 'trunk') begin
			raiserror('查询键，支持：null / agent / agent_g / agent_t / ext / skill / trunk', 0, 1)
			select null
			return 1
		end		

		--处理查询表，相关字段
		if @sch_key in ('agent_g', 'agent_t') begin
			-- @sch_key为agent_g or agent_t
			
			--set @strTblName = 'stat_call_agent'
			set @strTblName = case when @sch_key = 'agent_g' then 'stat_call_agent' else 'stat_call_skill' end

			
			--添加Where子句
			if not (@sch_value is null) begin
				if @sch_key = 'agent_t' begin
					set @strWhere = @strWhere + ' and (skill in (' + @sch_value + '))'
				end
				else begin
					set @strWhere = @strWhere + ' and (agent in (' + @sch_value + '))'
				end
			end

			if @GroupDiv != 9 begin	--按照日期和关联表字段分组

				declare @spec_field varchar(500)
				set @spec_field = case @sch_key 
									when 'agent_g'
										then 'GroupId, case when IsGrpTotal = 1 then ''小计'' when IsTotal = 1 then ''总计'' '
											 + 'else agent end agent, '
									else '' 
								  end
				
				if @GroupDiv != 5 begin	--非按星期分组
					if len(@spec_field) > 0 begin	--agent_g
						set @RelaField = 'vxi_def.dbo.strdate_to_str(RecDT) RecDT, ' + @spec_field
						set @RecDTExp = 'cast( (' + @RecDTExp + ') as varchar(20) )'
					end
					else begin	--agent_t
						set @RelaField = 'case when not (RecDT is null) then vxi_def.dbo.strdate_to_str(RecDT) '
									   + 'else ''总计'' end RecDT, '
					end
				end
				else begin	--按星期分组
					set @RelaField = case 
										when len(@spec_field) > 0 then	--agent_g
											'vxi_def.dbo.week_series_to_str(''' 
													+ cast((@RecDT_begin_int / 10000) as varchar(8))
													+ ''', RecDT) RecDT, '
										else	--agent_t
											'case when not (RecDT is null) then vxi_def.dbo.week_series_to_str(''' 
													+ cast((@RecDT_begin_int / 10000) as varchar(8))
													+ ''', RecDT) else ''总计'' end RecDT, ' 
									 end + @spec_field
				end

				if len(@spec_field) > 0 begin	--agent_g

					set @RelaField2 = 'grouping(' + @RecDTExp + ') IsTotal, ' + char(10)
									+ 'case when grouping(agent) = 1 and grouping(' + @RecDTExp + ') = 0 then 1 else 0 end IsGrpTotal, ' + char(10)
									+ @RecDTExp + ' RecDT, ' + char(10) + 'GroupId, agent, ' + char(10)
									--+ 'case when grouping(agent) = 0 then agent '
									--+ 'when grouping(' + @RecDTExp + ') = 0 then ''小计'' end agent, ' + char(10)

					set @strGroupby = ' Group by '  + @RecDTExp
										+ ', GroupId, agent with cube ' + char(10)
										+ 'having (grouping(GroupId) = 0 and grouping(agent) = 0 and grouping(' + @RecDTExp 
										+ ') = 0) or (grouping(GroupId) = 1 and grouping(agent) = 1)'

					set @strOrder = ' order by IsTotal, RecDT, IsGrpTotal, GroupId, agent'

				end
				else begin	--agent_t

					set @RelaField2 = @RecDTExp + ' RecDT, ' + char(10)

					set @strGroupby = ' Group by '  + @RecDTExp + ' with cube ' + char(10)

					set @strOrder = ' order by 1'

				end

			end
			else begin	--仅按照关联表字段分组
				if @sch_key = 'agent_t' begin
					raiserror('“电话呼叫统计报表”不能舍去日期字段', 0, 1)
					select null
					return 1					
				end
				
				--必为座席员状态统计信息
				set @RelaField = 'GroupId, case when IsGrpTotal = 1 then ''小计'' when IsTotal = 1 then ''总计'' else agent end agent, ' + char(10)
				set @RelaField2 = 'grouping(GroupId) IsTotal, ' + char(10)
								+ 'case when grouping(agent) = 1 and grouping(GroupId) = 0 then 1 else 0 end IsGrpTotal, ' + char(10)
								+ 'cast(GroupId as varchar(20)) GroupId, ' + char(10)
								+ 'agent, ' + char(10)
				set @strOrder = ' order by IsTotal, GroupId, IsGrpTotal, agent'
				set @strGroupby = @strGroupby + 'GroupId, agent with cube having grouping(GroupId) = 0 or grouping(agent) = 1'
			end

		end
		--else if @sch_key = 'agent_t' begin	--@sch_key为agent_t
		--end
		else begin	-- @sch_key为agent / ext / skill / trunk
			set @strTblName = 'stat_call_' + @sch_key
			set @RelaField = case @sch_key 
								when 'trunk' then 'GrpId'
								when 'node' then 'NodeName'
								else @sch_key
							 end
			set @TotalRelaField = 'null ' + @RelaField + ', '

			--添加Where子句
			if not (@sch_value is null) begin
				set @strWhere = @strWhere + ' and (' + @RelaField + ' in (' + @sch_value + '))'
			end
			
			if @GroupDiv != 9 begin	--按照日期和关联表字段分组
				set @strOrder = 'order by 1, 2'
				set @strGroupby = @strGroupby + ', ' + @RelaField
			end
			else begin	--仅按照关联表字段分组
				set @strOrder = 'order by 1'
				set @strGroupby = @strGroupby + @RelaField
			end

			--set @strOrder = case @GroupDiv when 9 then 'order by 1' else 'order by 1, 2' end	--仅按照关联表字段分组，排序1	
			--添加Group by子句
			--set @strGroupby = case @GroupDiv when 9 then @strGroupby + @RelaField else @strGroupby + ', ' + @RelaField end
			set @RelaField = @RelaField + ', '
		end

	end
	else begin	-- @sch_key为null or ''，所有记录
		set @strTblName = 'stat_call'
		set @RelaField = ''
		set @TotalRelaField = ''
		set @strOrder = 'order by 1'
		if @GroupDiv = 9 begin	--仅按照关联表字段分组
			set @strGroupby = ''
		end
	end

	--生成SQL
	if @sch_key = 'agent_g' begin
		-- @sch_key为agent_g
		set @strSQL = 'SELECT ' + @RelaField
				+ 'LoginTime, '
				+ 'TotalTm, vxi_def.dbo.avg_str(TotalTm, LoginTime, 1) AS TotalTmL, '
				+ 'TotalNum, vxi_def.dbo.avg_float(TotalNum, vxi_def.dbo.sec_to_hour(LoginTime), 2) AS TotalNumL, '
				+ 'cast(vxi_def.dbo.avg_float(TotalTm, TotalNum, 0) as int) AS TotalTmN, '	--总呼叫平均通话时间(s)
				+ 'IncTm, vxi_def.dbo.avg_str(IncTm, LoginTime, 1) AS IncTmL, '
				+ 'AnsNum, vxi_def.dbo.avg_float(AnsNum, vxi_def.dbo.sec_to_hour(LoginTime), 2) AS AnsNumL, '
				+ 'cast(vxi_def.dbo.avg_float(IncTm, AnsNum, 0) as int) AS IncTmN, '	--呼入平均通话时间(s)
				+ 'OtgTm, vxi_def.dbo.avg_str(OtgTm, LoginTime, 1) AS OtgTmL, '
				+ 'OtgNum, vxi_def.dbo.avg_float(OtgNum, vxi_def.dbo.sec_to_hour(LoginTime), 2) AS OtgNumL, '
				+ 'cast(vxi_def.dbo.avg_float(OtgTm, OtgNum, 0) as int) AS OtgTmN, '	--呼出平均通话时间(s)
				+ 'InsTm, InsNum, TrsNum, '	--内部通话时间(s)、数量、转移数
				+ 'FreeTime, vxi_def.dbo.avg_str(FreeTime, LoginTime, 1) AS FreeTimeL, '
				+ 'NotReadyTime, vxi_def.dbo.avg_str(NotReadyTime, LoginTime, 1) AS NotReadyTimeL, '
				+ 'cast(vxi_def.dbo.avg_float(RingTm, AnsNum, 0) as int) AS RingTm, '
				+ 'vxi_def.dbo.avg_str(RingTm, LoginTime, 1) AS RingTmL, '
				+ 'vxi_def.dbo.avg_str(TotalTm + RingTm, LoginTime, 1) AS Efficiency '
				+ 'FROM (' + char(10)
				+ 'SELECT ' + @RelaField2 
				+ 'SUM(LoginTime) LoginTime, SUM(TotalTm) TotalTm, SUM(TotalNum) TotalNum,  '
				+ 'SUM(IncTm) IncTm, SUM(AnsNum) AnsNum, SUM(OtgTm) OtgTm, SUM(OtgNum) OtgNum, '
				+ 'SUM(InsTm) InsTm, SUM(InsNum) InsNum, SUM(TrsNum) TrsNum, '
				+ 'SUM(FreeTime) FreeTime, SUM(NotReadyTime) NotReadyTime, SUM(RingTm) RingTm ' + char(10)
				+ 'FROM ' + @strTblName + @strWhere + char(10) + @strGroupby + ') t ' + @strOrder
	end
	else if @sch_key = 'agent_t' begin

		-- @sch_key为agent_t
		/*set @strSQL = 'SELECT ' + @RelaField + ' PBXIncNum, PBXOtgNum, IncNum, AnsNum, vxi_def.dbo.avg_str(AnsNum, IncNum, 1) AS AnsNumI, '
				    + 'AnsLessNum, vxi_def.dbo.avg_str(AnsLessNum, IncNum, 1) AS AnsLessNumI, '
      				+ 'AnsMoreNum, '
					+ 'case when not (AnsNum is null) then cast(vxi_def.dbo.avg_float(AnsTm, AnsNum, 0) as int) end AS AnsTm, '
					+ 'AbanNum, vxi_def.dbo.avg_str(AbanNum, IncNum, 1) AS AbanNumI, '
					+ 'AbanMoreNum, AbanQueueNum, vxi_def.dbo.avg_str(AbanQueueNum, AbanNum, 1) AS AbanQueueNumAN, '
					+ 'AbanAgentNum, vxi_def.dbo.avg_str(AbanAgentNum, AbanNum, 1) AS AbanAgentNumAN, '
					+ 'case when not (AbanAgentNum is null) then cast(vxi_def.dbo.avg_float(AbanTm, AbanAgentNum, 0) as int) end AS AbanTm, '
					+ 'MaxWaitTm, WorkTm, LoginTime, '
					+ 'vxi_def.dbo.avg_str(TotalTm + RingTm, LoginTime, 1) AS Efficiency FROM (' + char(10)
					+ 'SELECT ' + @RelaField2 + 'MAX(t2.PBXIncNum) PBXIncNum, MAX(t2.PBXOtgNum) PBXOtgNum, SUM(IncNum) IncNum, '
					+ 'SUM(AnsNum) AnsNum, SUM(AnsLessNum) AnsLessNum, '
					+ 'SUM(AnsMoreNum) AnsMoreNum, SUM(AnsTm) AnsTm, SUM(AbanNum) AbanNum, SUM(AbanMoreNum) '
					+ 'AbanMoreNum, SUM(AbanQueueNum) AbanQueueNum, SUM(AbanAgentNum) AbanAgentNum, SUM(AbanTm) AbanTm, '
					+ 'MAX(MaxWaitTm) MaxWaitTm, SUM(WorkTm) WorkTm, SUM(LoginTime) LoginTime, SUM(TotalTm) TotalTm, '
					+ 'SUM(RingTm) RingTm ' + char(10)
			        + 'FROM ' + @strTblName 
					+ ' t1 left join (select recdt recdt_t, PBXIncNum, PBXOtgNum from stat_call) t2'
				    + ' on t1.recdt = t2.recdt_t ' + @strWhere + char(10) + @strGroupby + ') t' + @strOrder
		*/

		/*set @strSQL = 'SELECT ' + @RelaField + ' PBXIncNum, PBXOtgNum, IncNum, AnsNum, vxi_def.dbo.avg_str(AnsNum, IncNum, 1) AS AnsNumI, '
				    + 'AnsLessNum, vxi_def.dbo.avg_str(AnsLessNum, IncNum, 1) AS AnsLessNumI, '
      				+ 'AnsMoreNum, '
					+ 'case when not (AnsNum is null) then cast(vxi_def.dbo.avg_float(AnsTm, AnsNum, 0) as int) end AS AnsTm, '
					+ 'AbanNum, vxi_def.dbo.avg_str(AbanNum, IncNum, 1) AS AbanNumI, '
					+ 'AbanMoreNum, AbanQueueNum, vxi_def.dbo.avg_str(AbanQueueNum, AbanNum, 1) AS AbanQueueNumAN, '
					+ 'AbanAgentNum, vxi_def.dbo.avg_str(AbanAgentNum, AbanNum, 1) AS AbanAgentNumAN, '
					+ 'case when not (AbanAgentNum is null) then cast(vxi_def.dbo.avg_float(AbanTm, AbanAgentNum, 0) as int) end AS AbanTm, '
					+ 'MaxWaitTm, WorkTm, LoginTime, '
					+ 'vxi_def.dbo.avg_str(TotalTm + RingTm, LoginTime, 1) AS Efficiency FROM (' + char(10)
					+ 'SELECT ' + @RelaField2 + 'SUM(PBXIncNum) PBXIncNum, SUM(PBXOtgNum) PBXOtgNum, SUM(IncNum) IncNum, '
					+ 'SUM(AnsNum) AnsNum, SUM(AnsLessNum) AnsLessNum, '
					+ 'SUM(AnsMoreNum) AnsMoreNum, SUM(AnsTm) AnsTm, SUM(AbanNum) AbanNum, SUM(AbanMoreNum) '
					+ 'AbanMoreNum, SUM(AbanQueueNum) AbanQueueNum, SUM(AbanAgentNum) AbanAgentNum, SUM(AbanTm) AbanTm, '
					+ 'MAX(MaxWaitTm_a) MaxWaitTm, SUM(WorkTm_a) WorkTm, SUM(LoginTime) LoginTime, SUM(TotalTm) TotalTm, '
					+ 'SUM(RingTm) RingTm ' + char(10)
			        + 'FROM (select * from ' + @strTblName + @strWhere + @strWhere_t
					+ ') t1 left join (select recdt recdt_t, MAX(MaxWaitTm) MaxWaitTm_a, SUM(LoginTime) LoginTime,'
					+ ' SUM(WorkTm) WorkTm_a from stat_call_agent ' + @strWhere + ' group by recdt) t2'
				    + ' on t1.recdt = t2.recdt_t ' + char(10) + @strGroupby + ') t' 
					+ @strOrder
		*/

		set @strSQL = 'SELECT ' + @RelaField + ' PBXIncNum, PBXOtgNum, IncNum, AnsNum, vxi_def.dbo.avg_str(AnsNum, IncNum, 1) AS AnsNumI, '
				    + 'AnsLessNum, vxi_def.dbo.avg_str(AnsLessNum, IncNum, 1) AS AnsLessNumI, '
      				+ 'AnsMoreNum, '
					+ 'case when not (AnsNum is null) then cast(vxi_def.dbo.avg_float(AnsTm, AnsNum, 0) as int) end AS AnsTm, '
					+ 'AbanNum, vxi_def.dbo.avg_str(AbanNum, IncNum, 1) AS AbanNumI, '
					+ 'AbanMoreNum, AbanQueueNum, vxi_def.dbo.avg_str(AbanQueueNum, AbanNum, 1) AS AbanQueueNumAN, '
					+ 'AbanAgentNum, vxi_def.dbo.avg_str(AbanAgentNum, AbanNum, 1) AS AbanAgentNumAN, '
					+ 'case when not (AbanAgentNum is null) then cast(vxi_def.dbo.avg_float(AbanTm, AbanAgentNum, 0) as int) end AS AbanTm, '
					+ 'MaxWaitTm, WorkTm, LoginTime/*, '
					+ 'vxi_def.dbo.avg_str(TotalTm + RingTm, LoginTime, 1) AS Efficiency*/ FROM (' + char(10)
					+ 'SELECT ' + @RelaField2 + 'SUM(PBXIncNum) PBXIncNum, SUM(PBXOtgNum) PBXOtgNum, SUM(IncNum) IncNum, '
					+ 'SUM(AnsNum) AnsNum, SUM(AnsLessNum) AnsLessNum, '
					+ 'SUM(AnsMoreNum) AnsMoreNum, SUM(AnsTm) AnsTm, SUM(AbanNum) AbanNum, SUM(AbanMoreNum) '
					+ 'AbanMoreNum, SUM(AbanQueueNum) AbanQueueNum, SUM(AbanAgentNum) AbanAgentNum, SUM(AbanTm) AbanTm, '
					+ 'MAX(MaxWaitTm) MaxWaitTm, SUM(WorkTm) WorkTm, SUM(LoginTime) LoginTime, SUM(TotalTm) TotalTm, '
					+ 'SUM(RingTm) RingTm ' + char(10)
			        + 'FROM ' + @strTblName + @strWhere + char(10) + @strGroupby + ') t'
					+ @strOrder

	end
	else begin
		-- @sch_key为null / agent / ext / skill / trunk
		if @GroupDiv != 9 begin	--按照时间和关联表字段分组
			set @TotalRelaField = ''' Total:'' RecDT, ' + @TotalRelaField
			set @RelaField2 = @RecDTExp + ' RecDT, ' + @RelaField			
			set @RelaField = case @GroupDiv 
								when 5 then 'vxi_def.dbo.week_series_to_str(''' 
											+ cast((@RecDT_begin_int / 10000) as varchar(8))
											+ ''', RecDT) RecDT, '	--按星期分组
								else  'vxi_def.dbo.strdate_to_str(RecDT) RecDT, ' 
							 end + @RelaField
		end
		else begin
			--仅按关联表字段分组
			set @RelaField2 = @RelaField
		end

		set @strSQL = 'SELECT ' + @TotalRelaField + 'SUM(TotalNum) TotalNum, SUM(TotalTm) TotalTm, '
				+ 'vxi_def.dbo.avg_int(SUM(TotalTm), SUM(TotalNum)) TotalAvgTm, '
				+ 'SUM(IncNum) IncNum, SUM(IncTm) IncTm, '
				+ 'vxi_def.dbo.avg_int(SUM(IncTm), SUM(IncNum)) IncAvgTm, '
				+ 'SUM(OtgNum) OtgNum, SUM(OtgTm) OtgTm, '
				+ 'vxi_def.dbo.avg_int(SUM(OtgTm), SUM(OtgNum)) OtgAvgTm, '
				+ 'SUM(InsNum) InsNum, SUM(InsTm) InsTm, '
				+ 'vxi_def.dbo.avg_int(SUM(InsTm), SUM(InsNum)) InsAvgTm, '
				+ 'SUM(AnsNum) AnsNum, SUM(AnsLessNum) AnsLessNum, SUM(AnsMoreNum) AnsMoreNum, '
				+ 'SUM(AnsTm) AnsTm, vxi_def.dbo.avg_int(SUM(AnsTm), SUM(AnsNum)) AnsAvgTm, '
				+ 'SUM(ConNum) ConNum, SUM(TrsNum) TrsNum, '
				+ 'SUM(AbanNum) AbanNum, SUM(AbanLessNum) AbanLessNum, SUM(AbanMoreNum) AbanMoreNum, '
				+ 'SUM(AbanTm) AbanTm, vxi_def.dbo.avg_int(SUM(AbanTm), SUM(AbanNum)) AbanAvgTm, '
				+ 'MAX(MaxWaitTm) MaxWaitTm, SUM(WorkTm) WorkTm, '
				+ 'SUM(AbanQueueNum) AbanQueueNum, SUM(AbanAgentNum) AbanAgentNum ' + char(10)
				+ 'FROM ' + @strTblName + @strWhere + char(10)	--合计信息
				+ ' union all ' + char(10)	--下面是详细数据部分
				+ 'SELECT ' + @RelaField
				+ 'TotalNum, TotalTm, TotalAvgTm, IncNum, IncTm, IncAvgTm, OtgNum, '
      			+ 'OtgTm, OtgAvgTm, InsNum, InsTm, InsAvgTm, AnsNum, AnsLessNum, AnsMoreNum, '
      			+ 'AnsTm, AnsAvgTm, ConNum, TrsNum, AbanNum, AbanLessNum, AbanMoreNum, '
      			+ 'AbanTm, AbanAvgTm, MaxWaitTm, WorkTm, AbanQueueNum, AbanAgentNum FROM (' + char(10)
				+ 'SELECT ' + @RelaField2
				+ 'SUM(TotalNum) TotalNum, SUM(TotalTm) TotalTm, '
				+ 'vxi_def.dbo.avg_int(SUM(TotalTm), SUM(TotalNum)) TotalAvgTm, '
				+ 'SUM(IncNum) IncNum, SUM(IncTm) IncTm, '
				+ 'vxi_def.dbo.avg_int(SUM(IncTm), SUM(IncNum)) IncAvgTm, '
				+ 'SUM(OtgNum) OtgNum, SUM(OtgTm) OtgTm, '
				+ 'vxi_def.dbo.avg_int(SUM(OtgTm), SUM(OtgNum)) OtgAvgTm, '
				+ 'SUM(InsNum) InsNum, SUM(InsTm) InsTm, '
				+ 'vxi_def.dbo.avg_int(SUM(InsTm), SUM(InsNum)) InsAvgTm, '
				+ 'SUM(AnsNum) AnsNum, SUM(AnsLessNum) AnsLessNum, SUM(AnsMoreNum) AnsMoreNum, '
				+ 'SUM(AnsTm) AnsTm, vxi_def.dbo.avg_int(SUM(AnsTm), SUM(AnsNum)) AnsAvgTm, '
				+ 'SUM(ConNum) ConNum, SUM(TrsNum) TrsNum, '
				+ 'SUM(AbanNum) AbanNum, SUM(AbanLessNum) AbanLessNum, SUM(AbanMoreNum) AbanMoreNum, '
				+ 'SUM(AbanTm) AbanTm, vxi_def.dbo.avg_int(SUM(AbanTm), SUM(AbanNum)) AbanAvgTm, '
				+ 'MAX(MaxWaitTm) MaxWaitTm, SUM(WorkTm) WorkTm, '
				+ 'SUM(AbanQueueNum) AbanQueueNum, SUM(AbanAgentNum) AbanAgentNum ' + char(10)
				+ 'FROM ' + @strTblName + @strWhere + @strGroupby
				+ ') t ' + @strOrder
	end


	--运行SQL
	print @strSQL
	exec sp_executesql @strSQL

	return @@rowcount

GO
/****** Object:  StoredProcedure [dbo].[sp_stat_agent_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-04-23>
-- Description:	<查询统计中间结果表，取得完整的坐席呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_agent_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Agent varchar(20) = null,		-- 缺省null表示所有坐席
	@Skill varchar(100) = null,		-- 缺省null表示所有技能组

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Agent = @Agent,
			@Skills = @Skill,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end

	-- 数据库中的索引为{RecDate (ASC), Agent (ASC)}
	--set @ExecSQL = 'Select ' + @DisplayPart + ' RecDT, Agent, '
	--modified by wenyong xia 2007 12/04
	set @ExecSQL = 'Select  case when isnull(t.RecDT,0) != 0 then  ' + @DisplayPart + ' else ''合计'' end RecDT,Agent,'
				 +' case when isnull(t.RecDT,0) = 0 then null else FirstLogin end FirstLogin,'
				 +' case when isnull(t.RecDT,0) = 0 then null else LastLogout end LastLogout,'
				 + 'Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
	--			 + 'FirstLogin, LastLogout, Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
	--			 + 'FirstLogin, LastLogout, Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
				 + 'TalkTime, IdleTime, NotReady00, NotReady01, NotReady02, NotReady03, NotReady04, '
				 + 'NotReady05, NotReady06, NotReady07, NotReady08, NotReady09, NotReady00Time, '
				 + 'NotReady01Time, NotReady02Time, NotReady03Time, NotReady04Time, NotReady05Time, '
				 + 'NotReady06Time, NotReady07Time, NotReady08Time, NotReady09Time, Logout00, Logout01, '
				 + 'Logout02, Logout03, Logout04, Logout05, Logout06, Logout07, Logout08, Logout09, '
				 + 'Logout00Time, Logout01Time, Logout02Time, Logout03Time, Logout04Time, Logout05Time, '
				 + 'Logout06Time, Logout07Time, Logout08Time, Logout09Time '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, Agent, '
				 + 'Min(LoginTime) FirstLogin, Max(LogoutTime) LastLogout, sum(Login_n) Login, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Login_t)) LoginTime, sum(Ready_n) Ready, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Ready_t)) ReadyTime, sum(Acw_n) Acw, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Acw_t)) AcwTime, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) TalkTime, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Idle_t)) IdleTime, sum(NotReady00_n) NotReady00, '
				 + 'sum(NotReady01_n) NotReady01, sum(NotReady02_n) NotReady02, sum(NotReady03_n) NotReady03, '
				 + 'sum(NotReady04_n) NotReady04, sum(NotReady05_n) NotReady05, sum(NotReady06_n) NotReady06, '
				 + 'sum(NotReady07_n) NotReady07, sum(NotReady08_n) NotReady08, sum(NotReady09_n) NotReady09, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady00_t)) NotReady00Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady01_t)) NotReady01Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady02_t)) NotReady02Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady03_t)) NotReady03Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady04_t)) NotReady04Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady05_t)) NotReady05Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady06_t)) NotReady06Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady07_t)) NotReady07Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady08_t)) NotReady08Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady09_t)) NotReady09Time, sum(Logout00_n) Logout00, '
				 + 'sum(Logout01_n) Logout01, sum(Logout02_n) Logout02, sum(Logout03_n) Logout03, '
				 + 'sum(Logout04_n) Logout04, sum(Logout05_n) Logout05, sum(Logout06_n) Logout06, '
				 + 'sum(Logout07_n) Logout07, sum(Logout08_n) Logout08, sum(Logout09_n) Logout09, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout00_t)) Logout00Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout01_t)) Logout01Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout02_t)) Logout02Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout03_t)) Logout03Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout04_t)) Logout04Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout05_t)) Logout05Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout06_t)) Logout06Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout07_t)) Logout07Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout08_t)) Logout08Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout09_t)) Logout09Time '
				 + 'From stat_agent Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) 
				 -- + ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent) t '
				 --modified by wenyong xia 2007 12/05
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent with Rollup ) t '
				 --
				 --+ 'Order by RecDT, Agent'
	--add by wenyong xia 2007 12/05
		set @ExecSQL = 'Select  a.RecDT,a.Agent,a.FirstLogin,a.LastLogout,'
				 + 'a.Login, a.LoginTime, a.Ready, a.ReadyTime, a.Acw, a.AcwTime, '
	--			 + 'a.FirstLogin, a.LastLogout, a.Login, a.LoginTime, a.Ready, a.ReadyTime, a.Acw, a.AcwTime, '
	--			 + 'FirstLogin, LastLogout, Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
				 + 'a.TalkTime, a.IdleTime, a.NotReady00, a.NotReady01, a.NotReady02, a.NotReady03, a.NotReady04, '
				 + 'a.NotReady05, a.NotReady06, a.NotReady07, a.NotReady08, a.NotReady09, a.NotReady00Time, '
				 + 'a.NotReady01Time, a.NotReady02Time, a.NotReady03Time, a.NotReady04Time, a.NotReady05Time, '
				 + 'a.NotReady06Time, a.NotReady07Time, a.NotReady08Time, a.NotReady09Time, a.Logout00, a.Logout01, '
				 + 'a.Logout02, a.Logout03, a.Logout04, a.Logout05, a.Logout06, a.Logout07, a.Logout08, a.Logout09, '
				 + 'Logout00Time, Logout01Time, Logout02Time, Logout03Time, Logout04Time, Logout05Time, '
				 + 'a.Logout06Time, a.Logout07Time, a.Logout08Time, a.Logout09Time From ('
				 + @ExecSQL + ' ) a where ((a.RecDT = ''合计'' and a.Agent is null) or (a.Agent is not null))  '
				 + 'Order by a.RecDT, a.Agent'
	--				
	-- for debug
	print @ExecSQL

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value

END
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_agent_report_save]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-04-23>
-- Description:	<查询统计中间结果表，取得完整的坐席呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_agent_report_save]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Agent varchar(20) = null,		-- 缺省null表示所有坐席
	@Skill varchar(100) = null,		-- 缺省null表示所有技能组

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS

begin try

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Agent = @Agent,
			@Skills = @Skill,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end

	-- 数据库中的索引为{RecDate (ASC), Agent (ASC)}
	--set @ExecSQL = 'Select ' + @DisplayPart + ' RecDT, Agent, '
	--modified by wenyong xia 2007 12/04
	set @ExecSQL = 'Select  case when isnull(t.RecDT,0) != 0 then  ' + @DisplayPart + ' else ''合计'' end RecDT,Agent,'
				 +' case when isnull(t.RecDT,0) = 0 then null else FirstLogin end FirstLogin,'
				 +' case when isnull(t.RecDT,0) = 0 then null else LastLogout end LastLogout,'
				 + 'Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
	--			 + 'FirstLogin, LastLogout, Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
	--			 + 'FirstLogin, LastLogout, Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
				 + 'TalkTime, IdleTime, NotReady00, NotReady01, NotReady02, NotReady03, NotReady04, '
				 + 'NotReady05, NotReady06, NotReady07, NotReady08, NotReady09, NotReady00Time, '
				 + 'NotReady01Time, NotReady02Time, NotReady03Time, NotReady04Time, NotReady05Time, '
				 + 'NotReady06Time, NotReady07Time, NotReady08Time, NotReady09Time, Logout00, Logout01, '
				 + 'Logout02, Logout03, Logout04, Logout05, Logout06, Logout07, Logout08, Logout09, '
				 + 'Logout00Time, Logout01Time, Logout02Time, Logout03Time, Logout04Time, Logout05Time, '
				 + 'Logout06Time, Logout07Time, Logout08Time, Logout09Time '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, Agent, '
				 + 'Min(LoginTime) FirstLogin, Max(LogoutTime) LastLogout, sum(Login_n) Login, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Login_t)) LoginTime, sum(Ready_n) Ready, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Ready_t)) ReadyTime, sum(Acw_n) Acw, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Acw_t)) AcwTime, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) TalkTime, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Idle_t)) IdleTime, sum(NotReady00_n) NotReady00, '
				 + 'sum(NotReady01_n) NotReady01, sum(NotReady02_n) NotReady02, sum(NotReady03_n) NotReady03, '
				 + 'sum(NotReady04_n) NotReady04, sum(NotReady05_n) NotReady05, sum(NotReady06_n) NotReady06, '
				 + 'sum(NotReady07_n) NotReady07, sum(NotReady08_n) NotReady08, sum(NotReady09_n) NotReady09, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady00_t)) NotReady00Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady01_t)) NotReady01Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady02_t)) NotReady02Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady03_t)) NotReady03Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady04_t)) NotReady04Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady05_t)) NotReady05Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady06_t)) NotReady06Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady07_t)) NotReady07Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady08_t)) NotReady08Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(NotReady09_t)) NotReady09Time, sum(Logout00_n) Logout00, '
				 + 'sum(Logout01_n) Logout01, sum(Logout02_n) Logout02, sum(Logout03_n) Logout03, '
				 + 'sum(Logout04_n) Logout04, sum(Logout05_n) Logout05, sum(Logout06_n) Logout06, '
				 + 'sum(Logout07_n) Logout07, sum(Logout08_n) Logout08, sum(Logout09_n) Logout09, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout00_t)) Logout00Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout01_t)) Logout01Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout02_t)) Logout02Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout03_t)) Logout03Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout04_t)) Logout04Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout05_t)) Logout05Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout06_t)) Logout06Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout07_t)) Logout07Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout08_t)) Logout08Time, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Logout09_t)) Logout09Time '
				 + 'From stat_agent Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) 
				 -- + ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent) t '
				 --modified by wenyong xia 2007 12/05
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent with Rollup ) t '
				 --
				 --+ 'Order by RecDT, Agent'
	--add by wenyong xia 2007 12/05
		set @ExecSQL = 'Select  a.RecDT,a.Agent,a.FirstLogin,a.LastLogout,'
				 + 'a.Login, a.LoginTime, a.Ready, a.ReadyTime, a.Acw, a.AcwTime, '
	--			 + 'a.FirstLogin, a.LastLogout, a.Login, a.LoginTime, a.Ready, a.ReadyTime, a.Acw, a.AcwTime, '
	--			 + 'FirstLogin, LastLogout, Login, LoginTime, Ready, ReadyTime, Acw, AcwTime, '
				 + 'a.TalkTime, a.IdleTime, a.NotReady00, a.NotReady01, a.NotReady02, a.NotReady03, a.NotReady04, '
				 + 'a.NotReady05, a.NotReady06, a.NotReady07, a.NotReady08, a.NotReady09, a.NotReady00Time, '
				 + 'a.NotReady01Time, a.NotReady02Time, a.NotReady03Time, a.NotReady04Time, a.NotReady05Time, '
				 + 'a.NotReady06Time, a.NotReady07Time, a.NotReady08Time, a.NotReady09Time, a.Logout00, a.Logout01, '
				 + 'a.Logout02, a.Logout03, a.Logout04, a.Logout05, a.Logout06, a.Logout07, a.Logout08, a.Logout09, '
				 + 'Logout00Time, Logout01Time, Logout02Time, Logout03Time, Logout04Time, Logout05Time, '
				 + 'a.Logout06Time, a.Logout07Time, a.Logout08Time, a.Logout09Time From ('
				 + @ExecSQL + ' ) a where ((a.RecDT = ''合计'' and a.Agent is null) or (a.Agent is not null))  '
				 + 'Order by a.RecDT, a.Agent'
	--				
	-- for debug
	set @ExecSQL = 'Insert into vxi_rep..rep_stat_agent_report([RecDT]
      ,[Agent]
      ,[FirstLogin]
      ,[LastLogout]
      ,[Login]
      ,[LoginTime]
      ,[Ready]
      ,[ReadyTime]
      ,[Acw]
      ,[AcwTime]
      ,[TalkTime]
      ,[IdleTime]
      ,[NotReady00]
      ,[NotReady01]
      ,[NotReady02]
      ,[NotReady03]
      ,[NotReady04]
      ,[NotReady05]
      ,[NotReady06]
      ,[NotReady07]
      ,[NotReady08]
      ,[NotReady09]
      ,[NotReady00Time]
      ,[NotReady01Time]
      ,[NotReady02Time]
      ,[NotReady03Time]
      ,[NotReady04Time]
      ,[NotReady05Time]
      ,[NotReady06Time]
      ,[NotReady07Time]
      ,[NotReady08Time]
      ,[NotReady09Time]
      ,[Logout00]
      ,[Logout01]
      ,[Logout02]
      ,[Logout03]
      ,[Logout04]
      ,[Logout05]
      ,[Logout06]
      ,[Logout07]
      ,[Logout08]
      ,[Logout09]
      ,[Logout00Time]
      ,[Logout01Time]
      ,[Logout02Time]
      ,[Logout03Time]
      ,[Logout04Time]
      ,[Logout05Time]
      ,[Logout06Time]
      ,[Logout07Time]
      ,[Logout08Time]
      ,[Logout09Time]) ' + @ExecSQL

	print @ExecSQL
	delete from vxi_rep..rep_stat_agent_report where RecDt = @RepDate and Agent = @Agent
	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value

end try
begin catch
	if @@trancount != 0 rollback
	return error_number()
end catch
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_call_agent_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-04-23>
-- Description:	<查询统计中间结果表，取得完整的坐席呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_call_agent_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Agent varchar(20) = null,		-- 缺省null表示所有坐席

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Agent = @Agent,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end

	-- 数据库中的索引为{RecDate (ASC), Agent (ASC)}
	select @DisplayPart = replace(@DisplayPart, 'RecDT', 'isnull(sca.RecDT, sa.RecDT)'),
		   --@ExecSQL = 'Select ' + @DisplayPart + ' RecDT, isnull(sca.Agent, sa.Agent) Agent, '
		   --modfied by wenyong xia 2007 12/04
			 @ExecSQL = 'Select case when isnull(isnull(sca.RecDT, sa.RecDT),0)!= 0 then ' + @DisplayPart + ' else ''合计'' end RecDT,' 
				 + 'isnull(sca.Agent, sa.Agent) Agent, '
				 + 'TotalCall, SkillCall, SkillAns, AnsLess, AnsMore, CallAban, '
				 + 'vxi_def.dbo.avg_float(CallAban, SkillCall, 2) AbanRate, AbanLess, AbanMore, TalkTime, '
				 + 'InTalk, OutTalk, InnerTalk, vxi_def.dbo.avg_int(TalkTime, Talk_n) AvgTalkTime, '
				 + 'vxi_def.dbo.avg_int(Skill_t, SkillAns) AvgAcdTime, '
				 + 'vxi_def.dbo.avg_int(Ans_t, SkillAns) AvgAnsTime, '
				 + 'vxi_def.dbo.avg_int(Hold_t, Hold_n) AvgHoldTime, '
				 + 'vxi_def.dbo.avg_int(Acw_t, Acw_n) AvgAcwTime, '
				 + 'vxi_def.dbo.avg_int(Handle_t, Talk_n) AvgHandleTime, CallTrans, '
				 + 'vxi_def.dbo.avg_float(CallTrans, Talk_n, 2) CallTransRate, CallConf, CallTrunk, TrunkIn, '
				 + 'TrunkInAns, TrunkOut, TrunkOutAns, TalkLess10, TalkLess20, TalkMore20, LoginTime, '
				 + '(Ready_t + Acw_t) AvailTime, vxi_def.dbo.avg_float(Ready_t + Acw_t, LoginTime, 2) AvailRate, '
				 + 'vxi_def.dbo.avg_float(Handle_t, LoginTime, 2) Occupancy '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, Agent, '
				 + 'sum(Total_n) TotalCall, sum(Skill_n) SkillCall, sum(Ans_n) SkillAns, sum(AnsLess_n) AnsLess, '
				 + 'sum(AnsMore_n) AnsMore, sum(Aban_n) CallAban, sum(AbanLess) AbanLess, sum(AbanMore) AbanMore, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) TalkTime, '
				 + 'sum(InTalk_n) InTalk, sum(OutTalk_n) OutTalk, '
				 + 'sum(Inner_n) InnerTalk, sum(Talk_n) Talk_n, sum(vxi_def.dbo.ms_to_int_sec(Skill_t)) Skill_t, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) Ans_t, sum(vxi_def.dbo.ms_to_int_sec(Hold_t)) Hold_t, '
				 + 'sum(Hold_n) Hold_n, sum(vxi_def.dbo.ms_to_int_sec(Handle_t)) Handle_t, sum(Trans_n) CallTrans, '
				 + 'sum(Conf_n) CallConf, '
				 + 'sum(Trunk_n) CallTrunk, sum(TrunkIn_n) TrunkIn, sum(TrunkInAns_n) TrunkInAns, '
				 + 'sum(TrunkOut_n) TrunkOut, sum(TrunkOutAns_n) TrunkOutAns, sum(TalkLess10_n) TalkLess10, '
				 + 'sum(TalkLess20_n) TalkLess20, sum(TalkMore20_n) TalkMore20 '
				 + 'From stat_call_agent Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) 
				 --+ ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent) sca 
				 --modified by wenyong 2007 12/04
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent with rollup ) sca '
				 --+ 'having ((Grouping(' + @GroupPart + ') = 1 ) or (not GROUPING(Agent) = 1 ))) sca '
				 --
				 + 'Full Join (Select Top 100 Percent ' + @GroupPart + ' RecDT, Agent, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Acw_t)), 0) Acw_t, sum(Acw_n) Acw_n, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Login_t)) LoginTime, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Ready_t)), 0) Ready_t From stat_agent '
				 + 'Where (RecDT between ' + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) + ')' + @WherePart + ' Group by ' + @GroupPart
--				 + ', Agent Order by 1, 2) sa On sca.RecDT = sa.RecDT and sca.Agent = sa.Agent '
				 + ', Agent with rollup '
				-- + 'having ((Grouping(' + @GroupPart + ') = 1 ) or (not GROUPING(Agent) = 1 )) '
				 + 'Order by 1, 2) sa On isnull(sca.RecDT, '''') = isnull(sa.RecDT, '''') and isnull(sca.Agent, '''') = isnull(sa.Agent, '''') '
				--modified by wenyong xia 2007 12/04
				-- + 'Order by RecDT, Agent'
	set @ExecSQL = 'Select a.RecDT,a.Agent, a.TotalCall, a.SkillCall, a.SkillAns, a.AnsLess, a.AnsMore, a.CallAban, '
				 + 'a.AbanRate, a.AbanLess, a.AbanMore, a.TalkTime,a.InTalk, a.OutTalk, a.InnerTalk, a.AvgTalkTime, '
				 + 'a.AvgAcdTime, a.AvgAnsTime, a.AvgHoldTime, a.AvgAcwTime, a.AvgHandleTime, CallTrans, a.CallTransRate, a.CallConf, '
				 + 'a.CallTrunk, a.TrunkIn, a.TrunkInAns, a.TrunkOut, a.TrunkOutAns, a.TalkLess10, a.TalkLess20, a.TalkMore20, '
				 + ' a.LoginTime, a.AvailTime, a.AvailRate, a.Occupancy From ( ' 
				 + @ExecSQL +  + ' ) a where ((a.RecDT = ''合计'' and a.Agent is null) or (a.Agent is not null))  '
				 + 'Order by a.RecDT, a.Agent'
	-- for debug
	print @ExecSQL
	print len(@ExecSQL)

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value

END
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_call_agent_report_save]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-04-23>
-- Description:	<查询统计中间结果表，取得完整的坐席呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_call_agent_report_save]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Agent varchar(20) = null,		-- 缺省null表示所有坐席

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS

begin try

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Agent = @Agent,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end

	-- 数据库中的索引为{RecDate (ASC), Agent (ASC)}
	select @DisplayPart = replace(@DisplayPart, 'RecDT', 'isnull(sca.RecDT, sa.RecDT)'),
		   --@ExecSQL = 'Select ' + @DisplayPart + ' RecDT, isnull(sca.Agent, sa.Agent) Agent, '
		   --modfied by wenyong xia 2007 12/04
			 @ExecSQL = 'Select case when isnull(isnull(sca.RecDT, sa.RecDT),0)!= 0 then ' + @DisplayPart + ' else ''合计'' end RecDT,' 
				 + 'isnull(sca.Agent, sa.Agent) Agent, '
				 + 'TotalCall, SkillCall, SkillAns, AnsLess, AnsMore, CallAban, '
				 + 'vxi_def.dbo.avg_float(CallAban, SkillCall, 2) AbanRate, AbanLess, AbanMore, TalkTime, '
				 + 'InTalk, OutTalk, InnerTalk, vxi_def.dbo.avg_int(TalkTime, Talk_n) AvgTalkTime, '
				 + 'vxi_def.dbo.avg_int(Skill_t, SkillAns) AvgAcdTime, '
				 + 'vxi_def.dbo.avg_int(Ans_t, SkillAns) AvgAnsTime, '
				 + 'vxi_def.dbo.avg_int(Hold_t, Hold_n) AvgHoldTime, '
				 + 'vxi_def.dbo.avg_int(Acw_t, Acw_n) AvgAcwTime, '
				 + 'vxi_def.dbo.avg_int(Handle_t, Talk_n) AvgHandleTime, CallTrans, '
				 + 'vxi_def.dbo.avg_float(CallTrans, Talk_n, 2) CallTransRate, CallConf, CallTrunk, TrunkIn, '
				 + 'TrunkInAns, TrunkOut, TrunkOutAns, TalkLess10, TalkLess20, TalkMore20, LoginTime, '
				 + '(Ready_t + Acw_t) AvailTime, vxi_def.dbo.avg_float(Ready_t + Acw_t, LoginTime, 2) AvailRate, '
				 + 'vxi_def.dbo.avg_float(Handle_t, LoginTime, 2) Occupancy '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, Agent, '
				 + 'sum(Total_n) TotalCall, sum(Skill_n) SkillCall, sum(Ans_n) SkillAns, sum(AnsLess_n) AnsLess, '
				 + 'sum(AnsMore_n) AnsMore, sum(Aban_n) CallAban, sum(AbanLess) AbanLess, sum(AbanMore) AbanMore, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) TalkTime, '
				 + 'sum(InTalk_n) InTalk, sum(OutTalk_n) OutTalk, '
				 + 'sum(Inner_n) InnerTalk, sum(Talk_n) Talk_n, sum(vxi_def.dbo.ms_to_int_sec(Skill_t)) Skill_t, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) Ans_t, sum(vxi_def.dbo.ms_to_int_sec(Hold_t)) Hold_t, '
				 + 'sum(Hold_n) Hold_n, sum(vxi_def.dbo.ms_to_int_sec(Handle_t)) Handle_t, sum(Trans_n) CallTrans, '
				 + 'sum(Conf_n) CallConf, '
				 + 'sum(Trunk_n) CallTrunk, sum(TrunkIn_n) TrunkIn, sum(TrunkInAns_n) TrunkInAns, '
				 + 'sum(TrunkOut_n) TrunkOut, sum(TrunkOutAns_n) TrunkOutAns, sum(TalkLess10_n) TalkLess10, '
				 + 'sum(TalkLess20_n) TalkLess20, sum(TalkMore20_n) TalkMore20 '
				 + 'From stat_call_agent Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) 
				 --+ ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent) sca 
				 --modified by wenyong 2007 12/04
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ', Agent with rollup ) sca '
				 --+ 'having ((Grouping(' + @GroupPart + ') = 1 ) or (not GROUPING(Agent) = 1 ))) sca '
				 --
				 + 'Full Join (Select Top 100 Percent ' + @GroupPart + ' RecDT, Agent, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Acw_t)), 0) Acw_t, sum(Acw_n) Acw_n, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Login_t)) LoginTime, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Ready_t)), 0) Ready_t From stat_agent '
				 + 'Where (RecDT between ' + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) + ')' + @WherePart + ' Group by ' + @GroupPart
--				 + ', Agent Order by 1, 2) sa On sca.RecDT = sa.RecDT and sca.Agent = sa.Agent '
				 + ', Agent with rollup '
				-- + 'having ((Grouping(' + @GroupPart + ') = 1 ) or (not GROUPING(Agent) = 1 )) '
				 + 'Order by 1, 2) sa On isnull(sca.RecDT, '''') = isnull(sa.RecDT, '''') and isnull(sca.Agent, '''') = isnull(sa.Agent, '''') '
				--modified by wenyong xia 2007 12/04
				-- + 'Order by RecDT, Agent'
	set @ExecSQL = 'Select a.RecDT,a.Agent, a.TotalCall, a.SkillCall, a.SkillAns, a.AnsLess, a.AnsMore, a.CallAban, '
				 + 'a.AbanRate, a.AbanLess, a.AbanMore, a.TalkTime,a.InTalk, a.OutTalk, a.InnerTalk, a.AvgTalkTime, '
				 + 'a.AvgAcdTime, a.AvgAnsTime, a.AvgHoldTime, a.AvgAcwTime, a.AvgHandleTime, CallTrans, a.CallTransRate, a.CallConf, '
				 + 'a.CallTrunk, a.TrunkIn, a.TrunkInAns, a.TrunkOut, a.TrunkOutAns, a.TalkLess10, a.TalkLess20, a.TalkMore20, '
				 + ' a.LoginTime, a.AvailTime, a.AvailRate, a.Occupancy From ( ' 
				 + @ExecSQL +  + ' ) a where ((a.RecDT = ''合计'' and a.Agent is null) or (a.Agent is not null))  '
				 + 'Order by a.RecDT, a.Agent'
	-- for debug
	set @ExecSQL = 'Insert into vxi_rep..rep_stat_call_agent_report([RecDT]
      ,[Agent]
      ,[TotalCall]
      ,[SkillCall]
      ,[SkillAns]
      ,[AnsLess]
      ,[AnsMore]
      ,[CallAban]
      ,[AbanRate]
      ,[AbanLess]
      ,[AbanMore]
      ,[TalkTime]
      ,[InTalk]
      ,[OutTalk]
      ,[InnerTalk]
      ,[AvgTalkTime]
      ,[AvgAcdTime]
      ,[AvgAnsTime]
      ,[AvgHoldTime]
      ,[AvgAcwTime]
      ,[AvgHandleTime]
      ,[CallTrans]
      ,[CallTransRate]
      ,[CallConf]
      ,[CallTrunk]
      ,[TrunkIn]
      ,[TrunkInAns]
      ,[TrunkOut]
      ,[TrunkOutAns]
      ,[TalkLess10]
      ,[TalkLess20]
      ,[TalkMore20]
      ,[LoginTime]
      ,[AvailTime]
      ,[AvailRate]
      ,[Occupancy]) ' + @ExecSQL

	print @ExecSQL

	delete from vxi_rep..rep_stat_call_agent_report where RecDT = @RepDate and Agent = @Agent
	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value

end try
begin catch
	if @@trancount != 0 rollback
	return error_number()
end catch
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_call_old]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [dbo].[sp_stat_call_old]
	@time_begin datetime = null,	-- 开始时间
	@time_end datetime = null,		-- 结束时间
	@SplitTm int = 30,				-- 统计间隔时长, 单位：分
	@WaitTm int = 15,				-- 统计等待时长分界点，单位：秒
	@AbanTm int = 15				-- 统计未接通电话的等待时长分界点，单位：秒
AS

/*	Add for test
	declare	@time_begin datetime, @time_end datetime, @SplitTm int, @WaitTm int, @AbanTm int
	select @time_begin = '20060101 10:00', @time_end = '20060125 18:00'
	select @SplitTm = 30, @WaitTm = 15, @AbanTm = 15
*/

--declare @RecF bigint, @RecT bigint, @RecDT bigint, @WaitMS int, @AbanMS int
--
--if isnull(@WaitTm, 0) < 5 begin
--	set @WaitTm = 5
--end
--
--if isnull(@AbanTm, 0) < 15 begin
--	set @AbanTm = 15
--end
--
--select @AbanMS = @AbanTm * 1000, @WaitMS = @WaitTm * 1000
--
--if @time_begin is null begin
--	set @time_begin = str(year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
--end
--
--if @time_end is null begin
--	set @time_end = getdate()
--end
--
--set @time_begin = dbo.trim_time(@time_begin, @SplitTm)
--set @time_end = dbo.trim_time(@time_end, @SplitTm)
--
--select @RecDT = 0, @RecF = dbo.time_to_bigint(@time_begin, @SplitTm), @RecT = dbo.time_to_bigint(@time_end, @SplitTm)
--
--select dbo.time_to_bigint(u.starttime, @SplitTm) RecDT, u.starttime ucd_starttime, 
--	dateadd(ms, c.callbegin, u.starttime) call_stattime, ltrim(rtrim(u.Agent)) Agent, ltrim(rtrim(u.extension)) Extension,  /* c.* */
--	c.UcdId, c.SubId, c.CallId, c.Calling, c.Called, c.Answer, c.Route, ltrim(rtrim(c.Skill)) Skill, 
--	ltrim(rtrim(c.Trunk)) Trunk, c.CallBegin, c.bRing, c.Deliver, c.bEstb, c.Establish, c.bTrans, c.Transfer, c.bConf, 
--      	c.Conference, c.CallEnd, c.Type
--	into #TempCall
--	from ucd u inner join ucdcall c on u.ucdid = c.ucdid
--	where starttime between @time_begin and @time_end
--
---- type: 0: inner	1: inbound	2: outbound
--
----begin stat_call
--delete from stat_call 
--	where RecDT between @RecF and @RecT
--
--insert into stat_call (RecDT, TimeSpan, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, InsNum, 
--      InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select RecDT, @SplitTm TimeSpan, 
--		isnull(count(*), 0) TotalNum,
--		isnull(sum(case when bEstb = 1 then CallEnd - Establish else 0 end), 0) TotalTm,
--		isnull(sum(case when type = 1 then 1 else 0 end), 0) IncNum,
--		isnull(sum(case when type = 1 then callend - callbegin else 0 end), 0) IncTm,
--		isnull(sum(case when type = 2 then 1 else 0 end), 0) OtgNum,
--		isnull(sum(case when type = 2 then callend - callbegin else 0 end), 0) OtgTm,
--		isnull(sum(case when type = 0 then 1 else 0 end), 0) InsNum,
--		isnull(sum(case when type = 0 then 0 else callend - callbegin end), 0) InsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then 1 else 0 end), 0) AnsNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) < @WaitTm then 1 else 0 end), 0) AnsLessNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) > @WaitTm then 1 else 0 end), 0) AnsMoreNum,
--		isnull(sum(case when bConf = 1 then 1 else 0 end), 0) ConNum,
--		isnull(sum(case when bTrans = 1 then 1 else 0 end), 0) TrsNum,
--		isnull(sum(case when type = 1 and bEstb = 0 then 1 else 0 end), 0) AbanNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) <= @AbanMS then 1 else 0 end), 0) AbanLessNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) > @AbanMS then 1 else 0 end), 0) AbanMoreNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then CallEnd - Deliver else 0 end), 0) AbanTm,
--		isnull(max(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) MaxWaitTm,
--		isnull(sum(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) AnsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then CallEnd - Establish else 0 end), 0) WorkTm,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 0 then 1 else 0 end), 0) AbanQueueNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then 1 else 0 end), 0) AbanAgentNum
----	into #TempStatCall
--	from #TempCall
--	group by RecDT
--
----insert into stat_call
----	select * from #TempStatCall
----drop table #TempStatCall
----end stat_call
--
--
----begin stat_call_skill
--delete from stat_call_skill 
--	where RecDT between @RecF and @RecT
--
--insert into stat_call_skill (RecDT, Skill, TimeSpan, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select RecDT, Skill, @SplitTm TimeSpan, 
--		isnull(count(*), 0) TotalNum,
--		isnull(sum(case when bEstb = 1 then CallEnd - Establish else 0 end), 0) TotalTm,
--		isnull(sum(case when type = 1 then 1 else 0 end), 0) IncNum,
--		isnull(sum(case when type = 1 then callend - callbegin else 0 end), 0) IncTm,
--		isnull(sum(case when type = 2 then 1 else 0 end), 0) OtgNum,
--		isnull(sum(case when type = 2 then callend - callbegin else 0 end), 0) OtgTm,
--		isnull(sum(case when type = 0 then 1 else 0 end), 0) InsNum,
--		isnull(sum(case when type = 0 then 0 else callend - callbegin end), 0) InsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then 1 else 0 end), 0) AnsNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) < @WaitTm then 1 else 0 end), 0) AnsLessNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) > @WaitTm then 1 else 0 end), 0) AnsMoreNum,
--		isnull(sum(case when bConf = 1 then 1 else 0 end), 0) ConNum,
--		isnull(sum(case when bTrans = 1 then 1 else 0 end), 0) TrsNum,
--		isnull(sum(case when type = 1 and bEstb = 0 then 1 else 0 end), 0) AbanNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) <= @AbanMS then 1 else 0 end), 0) AbanLessNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) > @AbanMS then 1 else 0 end), 0) AbanMoreNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then CallEnd - Deliver else 0 end), 0) AbanTm,
--		isnull(max(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) MaxWaitTm,
--		isnull(sum(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) AnsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then CallEnd - Establish else 0 end), 0) WorkTm,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 0 then 1 else 0 end), 0) AbanQueueNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then 1 else 0 end), 0) AbanAgentNum
--	from #TempCall
--	where isnull(Skill, '') <> ''
--	group by RecDT, Skill
----end stat_call_skill
--
----begin stat_call_trunk
--delete from stat_call_trunk 
--	where RecDT between @RecF and @RecT
--
--insert into stat_call_trunk (RecDT, GrpId, TimeSpan, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select RecDT, cast(left(Trunk, len(Trunk) - 3) as int) GrpId, @SplitTm TimeSpan, 
--		isnull(count(*), 0) TotalNum,
--		isnull(sum(case when bEstb = 1 then CallEnd - Establish else 0 end), 0) TotalTm,
--		isnull(sum(case when type = 1 then 1 else 0 end), 0) IncNum,
--		isnull(sum(case when type = 1 then callend - callbegin else 0 end), 0) IncTm,
--		isnull(sum(case when type = 2 then 1 else 0 end), 0) OtgNum,
--		isnull(sum(case when type = 2 then callend - callbegin else 0 end), 0) OtgTm,
--		isnull(sum(case when type = 0 then 1 else 0 end), 0) InsNum,
--		isnull(sum(case when type = 0 then 0 else callend - callbegin end), 0) InsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then 1 else 0 end), 0) AnsNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) < @WaitTm then 1 else 0 end), 0) AnsLessNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) > @WaitTm then 1 else 0 end), 0) AnsMoreNum,
--		isnull(sum(case when bConf = 1 then 1 else 0 end), 0) ConNum,
--		isnull(sum(case when bTrans = 1 then 1 else 0 end), 0) TrsNum,
--		isnull(sum(case when type = 1 and bEstb = 0 then 1 else 0 end), 0) AbanNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) <= @AbanMS then 1 else 0 end), 0) AbanLessNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) > @AbanMS then 1 else 0 end), 0) AbanMoreNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then CallEnd - Deliver else 0 end), 0) AbanTm,
--		isnull(max(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) MaxWaitTm,
--		isnull(sum(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) AnsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then CallEnd - Establish else 0 end), 0) WorkTm,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 0 then 1 else 0 end), 0) AbanQueueNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then 1 else 0 end), 0) AbanAgentNum
--	from #TempCall
--	where len(Trunk) > 3
--	group by RecDT, cast(left(Trunk, len(Trunk) - 3) as int)
----end stat_call_trunk
--
----begin stat_call_agent
--delete from stat_call_agent 
--	where RecDT between @RecF and @RecT
--
--insert into stat_call_agent (RecDT, Agent, TimeSpan, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select RecDT, Agent, @SplitTm TimeSpan, 
--		isnull(count(*), 0) TotalNum,
--		isnull(sum(case when bEstb = 1 then CallEnd - Establish else 0 end), 0) TotalTm,
--		isnull(sum(case when type = 1 then 1 else 0 end), 0) IncNum,
--		isnull(sum(case when type = 1 then callend - callbegin else 0 end), 0) IncTm,
--		isnull(sum(case when type = 2 then 1 else 0 end), 0) OtgNum,
--		isnull(sum(case when type = 2 then callend - callbegin else 0 end), 0) OtgTm,
--		isnull(sum(case when type = 0 then 1 else 0 end), 0) InsNum,
--		isnull(sum(case when type = 0 then 0 else callend - callbegin end), 0) InsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then 1 else 0 end), 0) AnsNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) < @WaitTm then 1 else 0 end), 0) AnsLessNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) > @WaitTm then 1 else 0 end), 0) AnsMoreNum,
--		isnull(sum(case when bConf = 1 then 1 else 0 end), 0) ConNum,
--		isnull(sum(case when bTrans = 1 then 1 else 0 end), 0) TrsNum,
--		isnull(sum(case when type = 1 and bEstb = 0 then 1 else 0 end), 0) AbanNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) <= @AbanMS then 1 else 0 end), 0) AbanLessNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) > @AbanMS then 1 else 0 end), 0) AbanMoreNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then CallEnd - Deliver else 0 end), 0) AbanTm,
--		isnull(max(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) MaxWaitTm,
--		isnull(sum(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) AnsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then CallEnd - Establish else 0 end), 0) WorkTm,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 0 then 1 else 0 end), 0) AbanQueueNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then 1 else 0 end), 0) AbanAgentNum
--	from #TempCall
--	where isnull(Agent, '') <> ''
--	group by RecDT, Agent
----end stat_call_agent
--
--
----begin stat_call_ext
--delete from stat_call_ext 
--	where RecDT between @RecF and @RecT
--
--insert into stat_call_ext (RecDT, Ext, TimeSpan, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select RecDT, Extension, @SplitTm TimeSpan, 
--		isnull(count(*), 0) TotalNum,
--		isnull(sum(case when bEstb = 1 then CallEnd - Establish else 0 end), 0) TotalTm,
--		isnull(sum(case when type = 1 then 1 else 0 end), 0) IncNum,
--		isnull(sum(case when type = 1 then callend - callbegin else 0 end), 0) IncTm,
--		isnull(sum(case when type = 2 then 1 else 0 end), 0) OtgNum,
--		isnull(sum(case when type = 2 then callend - callbegin else 0 end), 0) OtgTm,
--		isnull(sum(case when type = 0 then 1 else 0 end), 0) InsNum,
--		isnull(sum(case when type = 0 then 0 else callend - callbegin end), 0) InsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then 1 else 0 end), 0) AnsNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) < @WaitTm then 1 else 0 end), 0) AnsLessNum,
--		isnull(sum(case when type = 1 and bEstb = 1 and (CallEnd - Establish) > @WaitTm then 1 else 0 end), 0) AnsMoreNum,
--		isnull(sum(case when bConf = 1 then 1 else 0 end), 0) ConNum,
--		isnull(sum(case when bTrans = 1 then 1 else 0 end), 0) TrsNum,
--		isnull(sum(case when type = 1 and bEstb = 0 then 1 else 0 end), 0) AbanNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) <= @AbanMS then 1 else 0 end), 0) AbanLessNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and (CallEnd - CallBegin) > @AbanMS then 1 else 0 end), 0) AbanMoreNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then CallEnd - Deliver else 0 end), 0) AbanTm,
--		isnull(max(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) MaxWaitTm,
--		isnull(sum(case when type = 1 and bEstb = 1 and bRing = 1 then Establish - Deliver else 0 end), 0) AnsTm,
--		isnull(sum(case when type = 1 and bEstb = 1 then CallEnd - Establish else 0 end), 0) WorkTm,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 0 then 1 else 0 end), 0) AbanQueueNum,
--		isnull(sum(case when type = 1 and bEstb = 0 and bRing = 1 then 1 else 0 end), 0) AbanAgentNum
--	from #TempCall
--	where isnull(Extension, '') <> ''
--	group by RecDT, Extension
----end stat_call_ext
--
--
--drop table #TempCall

GO
/****** Object:  StoredProcedure [dbo].[sp_stat_call_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE       PROCEDURE [dbo].[sp_stat_call_report]
	@time_begin datetime = null,	-- 开始时间
	@time_end datetime = null,		-- 结束时间
	@SplitTm int = 30,				-- 统计间隔时长, 单位：分
	@WaitTm int = 15,				-- 统计等待时长分界点，单位：秒
	@AbanTm int = 15				-- 统计未接通电话的等待时长分界点，单位：秒
AS

--declare @RecF bigint, @RecT bigint, @WaitMS int, @AbanMS int
--
--if isnull(@WaitTm, 0) < 5 begin
--	set @WaitTm = 5
--end
--
--if isnull(@AbanTm, 0) < 15 begin
--	set @AbanTm = 15
--end
--
--set @AbanMS = @AbanTm * 1000	--化为毫秒
--set @WaitMS = @WaitTm * 1000	--化为毫秒
--
--if @time_begin is null begin
--	set @time_begin = convert(varchar(10), getdate(), 120) --str(year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
--end
--
--if @time_end is null begin
--	set @time_end = getdate()
--end
--
--set @time_begin = dbo.trim_time(@time_begin, @SplitTm)	--化为@SplitTm整数分钟，时间型
--set @time_end = dbo.trim_time(@time_end, @SplitTm)		--化为@SplitTm整数分钟，时间型
--set @RecF = dbo.time_to_bigint(@time_begin, @SplitTm)	--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
--set @RecT = dbo.time_to_bigint(@time_end, @SplitTm)		--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
--
--/*
--type: 0: inner,	1: inbound,	2: outbound
--
--(type = 0, skill = '') 内部呼叫
--
--(type = 0, skill <> '') IVR转座席的呼入
--(type = 1, skill <> '') 经过PBX到达技能组的呼入
--(type = 1, skill = '')  经过PBX直接到达座席的呼入
--正常情况下(skill <> '')-->(type <> 2)，故到技能组的呼入是(skill <> '') [ and type <> 2]
--总的呼入是(type = 0 and skill <> '') or (type = 1)
--
--(type = 2, skill = '') : 座席外拨
--正常情况下(type = 2)-->(skill = '')
--
--*/
--
--select dbo.time_to_bigint(u.starttime, @SplitTm) RecDT, /*u.starttime ucd_starttime, 
--	dateadd(ms, c.CallBegin, u.starttime) call_starttime, */
--	ltrim(rtrim(c.Agent)) Agent, ltrim(rtrim(u.extension)) Extension,  /* c.* */
--	/*c.UcdId, c.SubId, c.CallId, c.Calling, c.Called, c.Answer, c.Route,*/ ltrim(rtrim(c.Skill)) Skill, 
--	ltrim(rtrim(c.Trunk)) Trunk, /*c.CallBegin, c.bRing, c.Deliver, c.bEstb, c.Establish, 
--	c.bTrans, c.Transfer, c.bConf, c.Conference, c.CallEnd, c.Type,*/
--	/*** 以下所有时间由毫秒化为秒存入数据库 ***/
--	isnull(case when c.bEstb = 1 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then vxi_def.dbo.ms_to_int_sec(c.Establish - c.Deliver) end, 0) RingTm,	--振铃时间
--	isnull(case when c.type = 1 then 1 end, 0) PBXIncNum,	--经过PBX的呼入数
--	isnull(case when c.type = 2 then 1 end, 0) PBXOtgNum,	--经过PBX的呼出数
--	isnull(case c.bEstb when 1 then 1 end, 0) TotalNum,	--接通总呼叫
--	isnull(case c.bEstb when 1 then vxi_def.dbo.ms_to_int_sec(case when c.CallEnd > 0 then c.CallEnd else c.Establish end - c.Establish) end, 0) TotalTm,	--通话总时间
--	isnull(case when ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then 1 end, 0) IncNum,	--到座席/技能组来电总数
--	isnull(case when c.bEstb = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then vxi_def.dbo.ms_to_int_sec(case when c.CallEnd > 0 then c.CallEnd else c.Establish end - c.Establish) end, 0) IncTm,	--到座席来电通话时间
--	isnull(case when c.bEstb = 1 and c.Type = 2 then 1 end, 0) OtgNum,	--外拨接通数
--	isnull(case when c.bEstb = 1 and c.Type = 2 then vxi_def.dbo.ms_to_int_sec(case when c.CallEnd > 0 then c.CallEnd else c.Establish end - c.Establish) end, 0) OtgTm,	--外拨通话时间
--	isnull(case when c.bEstb = 1 and (c.Type = 0 and isnull(c.skill, '') = '') then 1 end, 0) InsNum,	--内部接通数
--	isnull(case when c.bEstb = 1 and (c.Type = 0 and isnull(c.skill, '') = '') then vxi_def.dbo.ms_to_int_sec(case when c.CallEnd > 0 then c.CallEnd else c.Establish end - c.Establish) end, 0) InsTm,	--内部通话时间
--	isnull(case when c.bEstb = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then 1 end, 0) AnsNum,	--到座席应答数（来电接通数）
--	isnull(case when c.bEstb = 1 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) and ((c.Establish - c.Deliver) <= @WaitMS) then 1 end, 0) AnsLessNum,--到座席应答<=x数
--	isnull(case when c.bEstb = 1 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) and (c.Establish - c.Deliver) > @WaitMS then 1 end, 0) AnsMoreNum,	--到座席应答>x数
--	isnull(case when bConf = 1 then 1 end, 0) ConNum,	--三方会议数
--	isnull(case when bTrans = 1 then 1 end, 0) TrsNum,	--转移数
--
--	isnull(case when c.bEstb = 0 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then 1 end, 0) AbanNum,	--放弃总数
--	isnull(case when c.bEstb = 0 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) and (case when c.CallEnd > 0 then c.CallEnd else c.Deliver end - c.Deliver) <= @AbanMS then 1 end, 0) AbanLessNum,	--到座席放弃<=x数
--	isnull(case when c.bEstb = 0 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) and (case when c.CallEnd > 0 then c.CallEnd else c.Deliver end - c.Deliver) > @AbanMS then 1 end, 0) AbanMoreNum,	--到座席放弃>x数
--	isnull(case when c.bEstb = 0 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then vxi_def.dbo.ms_to_int_sec(case when c.CallEnd > 0 then c.CallEnd else c.Deliver end - c.Deliver) end, 0) AbanTm,	--放弃时间
--	--max(AnsTm)--最大等待时间
--	isnull(case when c.bEstb = 1 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then vxi_def.dbo.ms_to_int_sec(c.Establish - c.Deliver) end, 0) AnsTm,	--座席应答（客户等待）时间
--	isnull(case when c.bEstb = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then vxi_def.dbo.ms_to_int_sec(case when c.CallEnd > 0 then c.CallEnd else c.Establish end - c.Establish) end, 0) WorkTm,	--工作时间
--	isnull(case when c.bEstb = 0 and c.bRing = 0 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then 1 end, 0) AbanQueueNum,	--队列放弃数
--	isnull(case when c.bEstb = 0 and c.bRing = 1 and ((c.Type = 0 and c.skill <> '') or (c.Type = 1)) then 1 end, 0) AbanAgentNum	--座席放弃数
--into #TempCall
--from (select ucdid, extension, starttime from ucd where starttime between @time_begin and @time_end) u 
--inner join ucdcall c on u.ucdid = c.ucdid
--
--CREATE INDEX [IX_TempCall_temp] ON [#TempCall]([RecDT], [Agent]) --ON [PRIMARY]
--
--select RecDT, Agent, LoginTime, ReadyTime, NotReadyTime
--	into #TempAgent
--	from stat_agent where (RecDT between @RecF and @RecT) and ((LoginTime <> 0) OR (ReadyTime <> 0) OR (NotReadyTime <> 0))
--
--CREATE INDEX [IX_TempAgent_temp] ON [#TempAgent]([RecDT], [Agent]) --ON [PRIMARY]
--
--
----for debug
----select * from #TempCall where agent <> '' order by RecDT desc
------------------------------------------------------------------------
--
----begin stat_call
--delete from stat_call where RecDT between @RecF and @RecT
--
--insert into stat_call (RecDT, TimeSpan, RingTm, PBXIncNum, PBXOtgNum,TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, InsNum, 
--      InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select 	RecDT, @SplitTm TimeSpan, 
--		sum(RingTm) RingTm,	--振铃时间
--		sum(PBXIncNum) PBXIncNum,	--经过PBX的呼入数
--		sum(PBXOtgNum) PBXOtgNum,	--经过PBX的呼出数
--		sum(TotalNum) TotalNum,	--接通总呼叫
--		sum(TotalTm) TotalTm,	--通话总时间
--		sum(IncNum) IncNum,	--到座席/技能组来电总数
--		sum(IncTm) IncTm,	--到座席来电通话时间
--		sum(OtgNum) OtgNum,	--外拨接通数
--		sum(OtgTm) OtgTm,	--外拨通话时间
--		sum(InsNum) InsNum,	--内部接通数
--		sum(InsTm) InsTm,	--内部通话时间
--		sum(AnsNum) AnsNum,	--到座席应答数（来电接通数）
--		sum(AnsLessNum) AnsLessNum,	--到座席应答<=x数
--		sum(AnsMoreNum) AnsMoreNum,	--到座席应答>x数
--		sum(ConNum) ConNum,	--三方会议数
--		sum(TrsNum) TrsNum,	--转移数
--		sum(AbanNum) AbanNum,	--放弃总数
--		sum(AbanLessNum) AbanLessNum,	--到座席放弃<=x
--		sum(AbanMoreNum) AbanMoreNum,	--到座席放弃>x
--		sum(AbanTm) AbanTm,	--放弃时间
--		max(AnsTm) MaxWaitTm,	--最大等待时间
--		sum(AnsTm) AnsTm,	--座席应答（客户等待）时间
--		sum(WorkTm) WorkTm,	--工作时间
--		sum(AbanQueueNum) AbanQueueNum,	--队列放弃数
--		sum(AbanAgentNum) AbanAgentNum	--座席放弃数
--	from #TempCall
--	group by RecDT
----end stat_call
--
----begin stat_call_skill
--delete from stat_call_skill where RecDT between @RecF and @RecT
--/*
--delete from stat_call_skill where RecDT between @RecF and @RecT
--
--insert into stat_call_skill (RecDT, Skill, TimeSpan, RingTm, PBXIncNum, PBXOtgNum, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select 	RecDT, Skill, @SplitTm TimeSpan, 
--		sum(RingTm) RingTm,	--振铃时间
--		sum(PBXIncNum) PBXIncNum,	--经过PBX的呼入数
--		sum(PBXOtgNum) PBXOtgNum,	--经过PBX的呼出数
--		sum(TotalNum) TotalNum,	--接通总呼叫
--		sum(TotalTm) TotalTm,	--通话总时间
--		sum(IncNum) IncNum,	--到座席/技能组来电总数
--		sum(IncTm) IncTm,	--到座席来电通话时间
--		sum(OtgNum) OtgNum,	--外拨接通数
--		sum(OtgTm) OtgTm,	--外拨通话时间
--		sum(InsNum) InsNum,	--内部接通数
--		sum(InsTm) InsTm,	--内部通话时间
--		sum(AnsNum) AnsNum,	--到座席应答数（来电接通数）
--		sum(AnsLessNum) AnsLessNum,	--到座席应答<=x数
--		sum(AnsMoreNum) AnsMoreNum,	--到座席应答>x数
--		sum(ConNum) ConNum,	--三方会议数
--		sum(TrsNum) TrsNum,	--转移数
--		sum(AbanNum) AbanNum,	--放弃总数
--		sum(AbanLessNum) AbanLessNum,	--到座席放弃<=x
--		sum(AbanMoreNum) AbanMoreNum,	--到座席放弃>x
--		sum(AbanTm) AbanTm,	--放弃时间
--
--		max(AnsTm) MaxWaitTm,	--最大等待时间
--		sum(AnsTm) AnsTm,	--座席应答（客户等待）时间
--		sum(WorkTm) WorkTm,	--工作时间
--		sum(AbanQueueNum) AbanQueueNum,	--队列放弃数
--		sum(AbanAgentNum) AbanAgentNum	--座席放弃数
--	from #TempCall
--	where isnull(Skill, '') <> ''
--	group by RecDT, Skill
--*/
--
--insert into stat_call_skill (RecDT, Skill, TimeSpan, LoginTime, FreeTime, NotReadyTime, RingTm, PBXIncNum, PBXOtgNum, 
--		TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      	InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      	AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      	AbanQueueNum, AbanAgentNum)
--select	t.RecDT RecDT, Skill, @SplitTm TimeSpan, isnull(sum(sa.LoginTime), 0), 
--		sum(case when sa.ReadyTime > 0 then (sa.ReadyTime - isnull(t.WorkTm, 0)) else 0 end) FreeTime,
--		isnull(sum(sa.NotReadyTime), 0), isnull(sum(t.RingTm), 0) RingTm, sum(t.PBXIncNum), sum(t.PBXOtgNum),
--		sum(t.TotalNum), sum(t.TotalTm), sum(t.IncNum), sum(t.IncTm), sum(t.OtgNum), sum(t.OtgTm), 
--		sum(t.InsNum), sum(t.InsTm), sum(t.AnsNum), sum(t.AnsLessNum), sum(t.AnsMoreNum), 
--		sum(t.ConNum), sum(t.TrsNum), sum(t.AbanNum), sum(t.AbanLessNum), sum(t.AbanMoreNum), 
--		sum(t.AbanTm), max(t.MaxWaitTm), sum(t.AnsTm), sum(t.WorkTm), sum(t.AbanQueueNum), sum(t.AbanAgentNum) 
--from 
--	(select RecDT, Agent, Skill,
--			sum(RingTm) RingTm,	--振铃时间
--			sum(PBXIncNum) PBXIncNum,	--经过PBX的呼入数
--			sum(PBXOtgNum) PBXOtgNum,	--经过PBX的呼出数
--			sum(TotalNum) TotalNum,	--接通总呼叫
--			sum(TotalTm) TotalTm,	--通话总时间
--			sum(IncNum) IncNum,	--到座席/技能组来电总数
--			sum(IncTm) IncTm,	--到座席来电通话时间
--			sum(OtgNum) OtgNum,	--外拨接通数
--			sum(OtgTm) OtgTm,	--外拨通话时间
--			sum(InsNum) InsNum,	--内部接通数
--			sum(InsTm) InsTm,	--内部通话时间
--			sum(AnsNum) AnsNum,	--到座席应答数（来电接通数）
--			sum(AnsLessNum) AnsLessNum,	--到座席应答<=x数
--			sum(AnsMoreNum) AnsMoreNum,	--到座席应答>x数
--			sum(ConNum) ConNum,	--三方会议数
--			sum(TrsNum) TrsNum,	--转移数
--			sum(AbanNum) AbanNum,	--放弃总数
--			sum(AbanLessNum) AbanLessNum,	--到座席放弃<=x
--			sum(AbanMoreNum) AbanMoreNum,	--到座席放弃>x
--			sum(AbanTm) AbanTm,	--放弃时间
--			case when agent <> '' then max(AnsTm) else 0 end MaxWaitTm,	--最大等待时间
--			sum(AnsTm) AnsTm,	--座席应答（客户等待）时间
--			case when agent <> '' then sum(WorkTm) else 0 end WorkTm,	--工作时间
--			sum(AbanQueueNum) AbanQueueNum,	--队列放弃数
--			sum(AbanAgentNum) AbanAgentNum	--座席放弃数
--		from #TempCall
--		where isnull(Skill, '') <> ''
--		group by RecDT, Agent, Skill
--	) t
--	left join #TempAgent sa on t.RecDT = sa.RecDT and t.Agent = sa.Agent	-- n-1 => n
--	left join vxi_sys..Agent a on isnull(t.Agent, sa.Agent) = a.Agent		-- n-1 => n
--	group by t.RecDT, t.Skill
--
----end stat_call_skill
--
----begin stat_call_trunk
--delete from stat_call_trunk where RecDT between @RecF and @RecT
--
--insert into stat_call_trunk (RecDT, GrpId, TimeSpan, RingTm, PBXIncNum, PBXOtgNum, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select RecDT, cast(left(Trunk, len(Trunk) - 3) as int) GrpId, @SplitTm TimeSpan, 
--		sum(RingTm) RingTm,	--振铃时间
--		sum(PBXIncNum) PBXIncNum,	--经过PBX的呼入数
--
--		sum(PBXOtgNum) PBXOtgNum,	--经过PBX的呼出数
--		sum(TotalNum) TotalNum,	--接通总呼叫
--		sum(TotalTm) TotalTm,	--通话总时间
--		sum(IncNum) IncNum,	--到座席/技能组来电总数
--		sum(IncTm) IncTm,	--到座席来电通话时间
--		sum(OtgNum) OtgNum,	--外拨接通数
--		sum(OtgTm) OtgTm,	--外拨通话时间
--		sum(InsNum) InsNum,	--内部接通数
--		sum(InsTm) InsTm,	--内部通话时间
--		sum(AnsNum) AnsNum,	--到座席应答数（来电接通数）
--		sum(AnsLessNum) AnsLessNum,	--到座席应答<=x数
--		sum(AnsMoreNum) AnsMoreNum,	--到座席应答>x数
--		sum(ConNum) ConNum,	--三方会议数
--		sum(TrsNum) TrsNum,	--转移数
--		sum(AbanNum) AbanNum,	--放弃总数
--		sum(AbanLessNum) AbanLessNum,	--到座席放弃<=x
--		sum(AbanMoreNum) AbanMoreNum,	--到座席放弃>x
--		sum(AbanTm) AbanTm,	--放弃时间
--		max(AnsTm) MaxWaitTm,	--最大等待时间
--		sum(AnsTm) AnsTm,	--座席应答（客户等待）时间
--		sum(WorkTm) WorkTm,	--工作时间
--		sum(AbanQueueNum) AbanQueueNum,	--队列放弃数
--		sum(AbanAgentNum) AbanAgentNum	--座席放弃数
--	from #TempCall
--	where len(Trunk) > 3
--	group by RecDT, cast(left(Trunk, len(Trunk) - 3) as int)
----end stat_call_trunk
--
----begin stat_call_agent
--delete from stat_call_agent 
--	where RecDT between @RecF and @RecT
--
--insert into stat_call_agent (RecDT, Agent, TimeSpan, GroupId, LoginTime, FreeTime, NotReadyTime, RingTm, PBXIncNum, PBXOtgNum, 
--							TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, 
--							ConNum, TrsNum, AbanNum, AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--							AbanQueueNum, AbanAgentNum)
--select	isnull(t.RecDT, sa.RecDT) RecDT, isnull(t.Agent, sa.Agent) Agent, @SplitTm TimeSpan,
--		a.GroupId, isnull(sa.LoginTime, 0) LoginTime, 
--		case when sa.ReadyTime > 0 then (sa.ReadyTime - isnull(t.WorkTm, 0)) else 0 end FreeTime,
--		isnull(sa.NotReadyTime, 0) NotReadyTime, isnull(t.RingTm, 0) RingTm, t.PBXIncNum, t.PBXOtgNum,
--		t.TotalNum, t.TotalTm, t.IncNum, t.IncTm, t.OtgNum, t.OtgTm, t.InsNum, t.InsTm, t.AnsNum, t.AnsLessNum, t.AnsMoreNum, 
--		t.ConNum, t.TrsNum, t.AbanNum, t.AbanLessNum, t.AbanMoreNum, t.AbanTm, t.MaxWaitTm, t.AnsTm, t.WorkTm, 
--      	t.AbanQueueNum, t.AbanAgentNum from 
--	(select	RecDT, Agent,
--			sum(RingTm) RingTm,	--振铃时间
--			sum(PBXIncNum) PBXIncNum,	--经过PBX的呼入数
--			sum(PBXOtgNum) PBXOtgNum,	--经过PBX的呼出数
--			sum(TotalNum) TotalNum,	--接通总呼叫
--			sum(TotalTm) TotalTm,	--通话总时间
--			sum(IncNum) IncNum,	--到座席/技能组来电总数
--			sum(IncTm) IncTm,	--到座席来电通话时间
--			sum(OtgNum) OtgNum,	--外拨接通数
--			sum(OtgTm) OtgTm,	--外拨通话时间
--			sum(InsNum) InsNum,	--内部接通数
--			sum(InsTm) InsTm,	--内部通话时间
--			sum(AnsNum) AnsNum,	--到座席应答数（来电接通数）
--			sum(AnsLessNum) AnsLessNum,	--到座席应答<=x数
--			sum(AnsMoreNum) AnsMoreNum,	--到座席应答>x数
--			sum(ConNum) ConNum,	--三方会议数
--			sum(TrsNum) TrsNum,	--转移数
--			sum(AbanNum) AbanNum,	--放弃总数
--			sum(AbanLessNum) AbanLessNum,	--到座席放弃<=x
--			sum(AbanMoreNum) AbanMoreNum,	--到座席放弃>x
--			sum(AbanTm) AbanTm,	--放弃时间
--			max(AnsTm) MaxWaitTm,	--最大等待时间
--			sum(AnsTm) AnsTm,	--座席应答（客户等待）时间
--			sum(WorkTm) WorkTm,	--工作时间
--			sum(AbanQueueNum) AbanQueueNum,	--队列放弃数
--			sum(AbanAgentNum) AbanAgentNum	--座席放弃数
--		from #TempCall
--		where isnull(Agent, '') <> ''
--		group by RecDT, Agent
--	) t
--	full join #TempAgent sa on t.RecDT = sa.RecDT and t.Agent = sa.Agent	-- 1-1
--	left join vxi_sys..Agent a on isnull(t.Agent, sa.Agent) = a.Agent	-- n-1 => n
----end stat_call_agent
--
----begin stat_call_ext
--delete from stat_call_ext where RecDT between @RecF and @RecT
--
--insert into stat_call_ext (RecDT, Ext, TimeSpan, RingTm, PBXIncNum, PBXOtgNum, TotalNum, TotalTm, IncNum, IncTm, OtgNum, OtgTm, 
--      InsNum, InsTm, AnsNum, AnsLessNum, AnsMoreNum, ConNum, TrsNum, AbanNum, 
--      AbanLessNum, AbanMoreNum, AbanTm, MaxWaitTm, AnsTm, WorkTm, 
--      AbanQueueNum, AbanAgentNum)
--select 	RecDT, Extension, @SplitTm TimeSpan, 
--		sum(RingTm) RingTm,	--振铃时间
--		sum(PBXIncNum) PBXIncNum,	--经过PBX的呼入数
--		sum(PBXOtgNum) PBXOtgNum,	--经过PBX的呼出数
--		sum(TotalNum) TotalNum,	--接通总呼叫
--		sum(TotalTm) TotalTm,	--通话总时间
--		sum(IncNum) IncNum,	--到座席/技能组来电总数
--		sum(IncTm) IncTm,	--到座席来电通话时间
--		sum(OtgNum) OtgNum,	--外拨接通数
--		sum(OtgTm) OtgTm,	--外拨通话时间
--		sum(InsNum) InsNum,	--内部接通数
--		sum(InsTm) InsTm,	--内部通话时间
--		sum(AnsNum) AnsNum,	--到座席应答数（来电接通数）
--		sum(AnsLessNum) AnsLessNum,	--到座席应答<=x数
--		sum(AnsMoreNum) AnsMoreNum,	--到座席应答>x数
--		sum(ConNum) ConNum,	--三方会议数
--		sum(TrsNum) TrsNum,	--转移数
--		sum(AbanNum) AbanNum,	--放弃总数
--		sum(AbanLessNum) AbanLessNum,	--到座席放弃<=x
--		sum(AbanMoreNum) AbanMoreNum,	--到座席放弃>x
--		sum(AbanTm) AbanTm,	--放弃时间
--		max(AnsTm) MaxWaitTm,	--最大等待时间
--		sum(AnsTm) AnsTm,	--座席应答（客户等待）时间
--		sum(WorkTm) WorkTm,	--工作时间
--		sum(AbanQueueNum) AbanQueueNum,	--队列放弃数
--		sum(AbanAgentNum) AbanAgentNum	--座席放弃数
--	from #TempCall
--	where isnull(Extension, '') <> ''
--	group by RecDT, Extension
----end stat_call_ext
--
--drop table #TempCall
--drop table #TempAgent

return 0





GO
/****** Object:  StoredProcedure [dbo].[sp_stat_device]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_device]
	@time_begin datetime = null,	-- 开始时间
	@time_end datetime = null,		-- 结束时间
	@SplitTm int = 30				-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @RecF bigint, @RecT bigint, @RecDT bigint, @time_loop datetime, @time_loop_end datetime, @begday datetime

	if @time_begin is null begin
		set @time_begin = dbo.func_day(getdate())
		set @begday = @time_begin
	end
	else begin
		set @begday = str(dbo.func_day(@time_begin))
	end
	if @time_end is null begin
		set @time_end = getdate()
	end

	select @RecDT = 0, @RecF = dbo.time_to_bigint(@time_begin, @SplitTm), @RecT = dbo.time_to_bigint(@time_end, @SplitTm)

	select * into #TempDevBef
		from DevLog 
		where logid in (
			select max(logid) logid	from Login
				where begtime between @begday and @time_begin
				group by device
			)

	-- update #TempDevBef set begtime = @time_begin

	select m.*, l.agent, l.device, l.skills into #TempDev
		from (
			select * from #TempDevBef
				where endtime > @time_begin
			union
			select * from DevLog
				where begtime between @time_begin and @time_end
		) m left join Login l on m.AgentLogId = l.LogID

	drop table #TempDevBef

	-- Create Init Records
	create table #TempDevInfo (
		[RecDT] [bigint] NOT NULL,
		[Device] [char](20) NOT NULL,
		[Agent] [char](20) NOT NULL,
		[TimeSpan] [int] NOT NULL,
		[IdleTime] [int] NULL,
		[DialTime] [int] NULL,
		[RingTime] [int] NULL,
		[TalkTime] [int] NULL,
		[HoldTime] [int] NULL,
		[WorkTime] [int] NULL,
		[CallNum] [int] NULL,
		[InNum] [int] NULL,
		[OutNum] [int] NULL,
		[DialNum] [int] NULL,
		[RingNum] [int] NULL,
		[HoldNum] [int] NULL,
	)

	select distinct agent, skill into #TempSkill 
		from #TempDev l inner join SkillLog s on l.agent = s.agent
		group by agent, skill

	set @time_loop = @time_begin

	while @time_loop < @time_end begin
		select @RecDT = dbo.time_to_bigint(@time_loop, @SplitTm), 
				@time_loop_end = dateadd(minute, @SplitTm, @time_loop)

		insert into #TempDevInfo (RecDT, Device, Agent, TimeSpan, 
				IdleTime, DialTime, RingTime, TalkTime, HoldTime, WorkTime, 
				CallNum, DialNum, RingNum, InNum, OutNum, HoldNum)
			select @RecDT, device, agent, @SplitTm TimeSpan, 
				isnull(sum(
					case when devflag = 0 then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) IdleTime,
				isnull(sum(
					case when devflag & 7 = 3 then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) DialTime,
				isnull(sum(
					case when devflag & 7 = 2 then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) RingTime,
				isnull(sum(
					case when devflag & 7 = 7  then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) TalkTime,
				isnull(sum(
					case when devflag & 8 = 8 then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) HoldTime,
				isnull(sum(
					case when devflag & 8 = 8 or devflag & 3 = 3 then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) WorkTime,	-- Work = Dial + Talk + Hold
				isnull(sum(
					case when l.flag = 0 and cause = 6 then datediff(ss, 
						case when begtime > @time_loop then begtime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) CallNum,
				isnull(sum(case when devflag & 7 = 3 then 1 else 0 end), 0) DialNum,
				isnull(sum(case when devflag & 7 = 2 then 1 else 0 end), 0) RingNum,
				isnull(sum(case when devflag & 7 = 7 and oldflag & 7 = 2 then 1 else 0 end), 0) InNum,
				isnull(sum(case when devflag & 7 = 7 and oldflag & 7 = 3 then 1 else 0 end), 0) OutNum, 
				isnull(sum(case when devflag & 8 = 8 and oldflag & 8 = 0 then 1 else 0 end), 0) HoldNum
			from #TempDev
			where (begtime between @time_loop and @time_loop_end) or
				  (endtime  between @time_loop and @time_loop_end) or
				  (begtime < @time_loop and endtime > @time_loop_end)
			group by device, agent

		set @time_loop = @time_loop_end
		continue
	end

	/*
	insert into #TempSkillInfo (RecDT, Skill, TimeSpan, IdleTime, 
				DialTime, RingTime, TalkTime, HoldTime, WorkTime, 
				CallNum, DialNum, RingNum, InNum, OutNum, HoldNum)
		select a.RecDT, s.Skill, a.TimeSpan, sum(a.IdleTime) IdleTime, 
				sum(a.DialTime) DialTime, sum(a.RingTime) RingTime, 
				sum(a.TalkTime) TalkTime, sum(a.HoldTime) HoldTime, 
				sum(a.WorkTime) WorkTime, sum(a.CallNum) CallNum, 
				sum(a.DialNum) DialNum, sum(a.RingNum) RingNum, 
				sum(a.InNum) InNum, sum(a.OutNum) OutNum,
				sum(a.HoldNum) HoldNum
			from #TempSkill s inner join #TempDev a on s.skill = a.skill
			where s.RecDT = a.RecDT
			group by a.RecDT, s.Skill, a.TimeSpan

	delete stat_skill
		where recdt between @RecF and @RecT

	insert into stat_skill
		select * from #TempSkillInfo

	*/

	delete stat_device 
		where recdt between @RecF and @RecT

	insert into stat_device
		select * from #TempAgentInfo


	/* Add for debug 
	select * from #TempDevInfo
	select * from #TempSkillInfo
	select * from #TempDev
	select * from #TempSkill
	-- */

	drop table #TempDevInfo
	drop table #TempDev

	-- drop table #TempSkillInfo
	-- drop table #TempSkill

END
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_login]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_login]
	@time_begin datetime = null,	-- 开始时间
	@time_end datetime = null,		-- 结束时间
	@SplitTm int = 15				-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @RecF bigint, @RecT bigint, @RecDT bigint, @time_loop datetime, @time_loop_end datetime, @begday datetime

	if @time_begin is null begin
		set @time_begin = dbo.func_day(getdate())
		set @begday = @time_begin
	end
	else begin
		set @begday = str(dbo.func_day(@time_begin))
	end
	if @time_end is null begin
		set @time_end = getdate()
	end

	select @RecDT = 0, @RecF = dbo.time_to_bigint(@time_begin, @SplitTm), @RecT = dbo.time_to_bigint(@time_end, @SplitTm)

	select * into #TempLoginBef
		from Login 
		where logid in (
			select max(logid) logid	from Login
				where starttime between @begday and @time_begin
				group by agent
			)

	update #TempLoginBef set starttime = @time_begin

	select m.* into #TempLogin 
		from (
			select * from #TempLoginBef
				where endtime > @time_begin
			union
			select * from Login
				where starttime between @time_begin and @time_end
		) m

	drop table #TempLoginBef

	select r.LogId, r.SubId, l.Agent, l.Device, l.Skills, 
			dateadd(ms, r.StartTime, l.StartTime) starttime, r.Flag, r.Finish, 
			r.TimeLen, dateadd(ms, r.StartTime + r.TimeLen, l.StartTime) endtime, r.Cause
		into #TempReady
		from Ready r inner join Login l on l.logid = r.logid
		where l.logid in (select logid from #TempLogin)

	-- Create Init Records
	create table #TempAgentInfo (
		[RecDT] [bigint] NULL, 
		[agent] [char] (20) NULL,
		[TimeSpan] [int] NULL, 
		[LoginTime] [int] NULL,
		[ReadyTime] [int] NULL,
		[NotReadyTime] [int] NULL,
		[AcwTime] [int] NULL,
		[LogoutTime] [int] NULL,
		[AcwTime] [int] NULL,
		[LogoutTime] [int] NULL,
		[NotReady01] [int] NULL,
		[NotReady02] [int] NULL,
		[NotReady03] [int] NULL,
		[NotReady04] [int] NULL,
		[NotReady05] [int] NULL,
		[NotReady06] [int] NULL,
		[NotReady07] [int] NULL,
		[NotReady08] [int] NULL,
		[NotReady09] [int] NULL,
		[Logout01] [int] NULL,
		[Logout02] [int] NULL,
		[Logout03] [int] NULL,
		[Logout04] [int] NULL,
		[Logout05] [int] NULL,
		[Logout06] [int] NULL,
		[Logout07] [int] NULL,
		[Logout08] [int] NULL,
		[Logout09] [int] NULL,
	)

	create table #TempSkillInfo (
		[RecDT] [bigint] NULL, 
		[Skill] [char] (20) NULL,
		[TimeSpan] [int] NULL, 
		[AgentNum] [int] NULL,
		[LoginTime] [int] NULL,
		[ReadyTime] [int] NULL,
		[NotReadyTime] [int] NULL,
		[AcwTime] [int] NULL,
		[LogoutTime] [int] NULL,
		[AcwTime] [int] NULL,
		[LogoutTime] [int] NULL,
		[NotReady01] [int] NULL,
		[NotReady02] [int] NULL,
		[NotReady03] [int] NULL,
		[NotReady04] [int] NULL,
		[NotReady05] [int] NULL,
		[NotReady06] [int] NULL,
		[NotReady07] [int] NULL,
		[NotReady08] [int] NULL,
		[NotReady09] [int] NULL,
		[Logout01] [int] NULL,
		[Logout02] [int] NULL,
		[Logout03] [int] NULL,
		[Logout04] [int] NULL,
		[Logout05] [int] NULL,
		[Logout06] [int] NULL,
		[Logout07] [int] NULL,
		[Logout08] [int] NULL,
		[Logout09] [int] NULL,
	)

	select distinct agent, skill into #TempSkill 
		from #TempLogin l inner join SkillLog s on l.agent = s.agent
		group by agent, skill

	set @time_loop = @time_begin

	while @time_loop < @time_end begin
		select @RecDT = dbo.time_to_bigint(@time_loop, @SplitTm), 
				@time_loop_end = dateadd(minute, @SplitTm, @time_loop)

		insert into #TempAgentInfo (RecDT, Agent, TimeSpan, LoginTime, Logout01, Logout02, 
				Logout03, Logout04, Logout05, Logout06, Logout07, Logout08, Logout09)
			select @RecDT, a.agent, @SplitTm TimeSpan, 
				isnull(sum(
					case when l.flag = 1 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) LoginTime,
				isnull(sum(
					case when l.flag = 0 and cause = 1 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout01,
				isnull(sum(
					case when l.flag = 0 and cause = 2 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout02,
				isnull(sum(
					case when l.flag = 0 and cause = 3 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout03,
				isnull(sum(
					case when l.flag = 0 and cause = 4 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout04,
				isnull(sum(
					case when l.flag = 0 and cause = 5 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout05,
				isnull(sum(
					case when l.flag = 0 and cause = 6 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout06,
				isnull(sum(
					case when l.flag = 0 and cause = 7 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout07,
				isnull(sum(
					case when l.flag = 0 and cause = 8 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout08,
				isnull(sum(
					case when l.flag = 0 and cause = 9 then datediff(ss, 
						case when starttime > @time_loop then starttime else @time_loop end, 
						case when endtime < @time_loop_end then endtime else @time_loop_end end)
					else 0 end), 0) Logout09
			from rt_agent a left join #TempLogin l on a.agent = l.agent 
			where a.enabled = 1
				and	((l.starttime between @time_loop and @time_loop_end) or
				     (l.endtime  between @time_loop and @time_loop_end) or
				     (l.starttime < @time_loop and l.endtime > @time_loop_end))
			group by a.agent, isnull(TimeSpan, @SplitTm)

		update #TempAgentInfo set
				ReadyTime = t.ReadyTime, NotReadyTime = t.NotReadyTime, AcwTime = t.AcwTime, 
				NotReady01 = t.NotReady01, NotReady02 = t.NotReady02, NotReady01 = t.NotReady03, 
				NotReady04 = t.NotReady04, NotReady05 = t.NotReady05, NotReady06 = t.NotReady06, 
				NotReady07 = t.NotReady07, NotReady08 = t.NotReady08, NotReady09 = t.NotReady09
			from #TempAgentInfo a, (select @RecDT RecDT, Agent, 
					isnull(sum(
						case when l.flag = 3 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) ReadyTime,
					isnull(sum(
						case when l.flag = 1 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReadyTime,
					isnull(sum(
						case when l.flag = 5 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) AcwTime,
					isnull(sum(
						case when l.flag = 1 and cause = 1 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady01,
					isnull(sum(
						case when l.flag = 1 and cause = 2 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady02,
					isnull(sum(
						case when l.flag = 1 and cause = 3 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady03,
					isnull(sum(
						case when l.flag = 1 and cause = 4 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady04,
					isnull(sum(
						case when l.flag = 1 and cause = 5 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady05,
					isnull(sum(
						case when l.flag = 1 and cause = 6 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady06,
					isnull(sum(
						case when l.flag = 1 and cause = 7 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady07,
					isnull(sum(
						case when l.flag = 1 and cause = 8 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady08,
					isnull(sum(
						case when l.flag = 1 and cause = 9 then datediff(ss, 
							case when starttime > @time_loop then starttime else @time_loop end, 
							case when endtime < @time_loop_end then endtime else @time_loop_end end)
						else 0 end), 0) NotReady09
				from #TempReady
				where (starttime between @time_loop and @time_loop_end) or
					  (endtime  between @time_loop and @time_loop_end) or
					  (starttime < @time_loop and endtime > @time_loop_end)
				group by a.agent
			) t
			where a.RecDT = t.RecDT and a.agent = t.agent

		set @time_loop = @time_loop_end
		continue
	end

	update #TempAgentInfo set LogoutTime = TimeSpan - LoginTime

	insert into #TempSkillInfo (RecDT, Skill, TimeSpan, AgentNum, LoginTime, 
			ReadyTime, NotReadyTime, AcwTime, LogoutTime, 
			NotReady01, NotReady02, NotReady03, NotReady04, 
			NotReady05, NotReady06, NotReady07, NotReady08, NotReady09, 
			Logout01, Logout02, Logout03, Logout04, Logout05, 
			Logout06, Logout07, Logout08, Logout09)
		select a.RecDT, s.Skill, a.TimeSpan, count(*) AgentNum, sum(a.LoginTime) LoginTime, 
				sum(a.ReadyTime) ReadyTime, sum(a.NotReadyTime) NotReadyTime, 
				sum(a.AcwTime) AcwTime, sum(a.LogoutTime) LogoutTime, 
				sum(a.NotReady01) NotReady01, sum(a.NotReady02) NotReady02, sum(a.NotReady03) NotReady03,
				sum(a.NotReady04) NotReady04, sum(a.NotReady05) NotReady05, sum(a.NotReady06) NotReady06,
				sum(a.NotReady07) NotReady07, sum(a.NotReady08) NotReady08, sum(a.NotReady09) NotReady09,
				sum(a.Logout01) Logout01, sum(a.Logout02) Logout02, sum(a.Logout03) Logout03, 
				sum(a.Logout01) Logout04, sum(a.Logout02) Logout05, sum(a.Logout03) Logout06, 
				sum(a.Logout01) Logout07, sum(a.Logout02) Logout08, sum(a.Logout03) Logout09
			from #TempSkill s inner join #TempAgentInfo a on s.skill = a.skill
			where s.RecDT = a.RecDT
			group by a.RecDT, s.Skill, a.TimeSpan

	delete stat_agent 
		where recdt between @RecF and @RecT

	insert into stat_agent
		select * from #TempAgentInfo

	delete stat_skill
		where recdt between @RecF and @RecT

	insert into stat_skill
		select * from #TempSkillInfo


	/* Add for debug 
	select * from #TempAgentInfo
	select * from #TempSkillInfo
	select * from #TempAgent
	select * from #TempSkill
	select * from #TempLogin
	select * from #TempReady
	-- */

	drop table #TempAgentInfo
	drop table #TempSkillInfo

	drop table #TempAgent
	drop table #TempLogin
	drop table #TempReady
	drop table #TempSkill

END



GO
/****** Object:  StoredProcedure [dbo].[sp_stat_login_backup]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROCEDURE [dbo].[sp_stat_login_backup]
	@time_begin datetime = null,	-- 开始时间
	@time_end datetime = null,	-- 结束时间
	@SplitTm int = 30		-- 统计间隔时长, 单位：分
AS

/*	Add for test
	declare	@time_begin datetime, @time_end datetime, @SplitTm int, @WaitTm int
	select @time_begin = '20060101 10:00', @time_end = '20060120 18:00'
	select @SplitTm = 30
*/

declare @RecF bigint, @RecT bigint, @RecDT bigint, @time_loop datetime, @time_loop_end datetime

if @time_begin is null begin
	set @time_begin = str(year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
end
if @time_end is null begin
	set @time_end = getdate()
end

select @RecDT = 0, @RecF = dbo.time_to_bigint(@time_begin, @SplitTm), @RecT = dbo.time_to_bigint(@time_end, @SplitTm)

select *, dateadd(ms, timelen, starttime) endtime
	into #TempLoginBef
	from AgentLog where logid in (
	select max(logid) logid	from AgentLog
		where starttime < @time_begin
			and status = 1
		group by agent, status
	)

delete #TempLoginBef where endtime <= @time_begin
update #TempLoginBef set starttime = @time_begin

--update #TempLoginBef set endtime = @time_end, timelen = datediff(ms, StartTime, @time_end) where timelen = 0

-- select * from #TempLoginBef order by logid

select @RecDT RecDT, @SplitTm TimeSpan, m.* 
	into #TempLogin from (
		select * from #TempLoginBef
		union
		select *, dateadd(ms, timelen, starttime) endtime
			from AgentLog
			where starttime between @time_begin and @time_end
		) m

update #TempLogin
	set RecDT = dbo.time_to_bigint(starttime, @SplitTm)

/*** 替换 #TempLogin 中timelen为0的记录 ***/
update #TempLogin
set timelen = DATEDIFF(ms, starttime, ll.LossTime), EndTime = ll.LossTime
from #TempLogin tl, 
(
select 
l1.Logid, 
case when floor(cast(min(l2.StartTime) as numeric(38, 6))) = floor(cast(l1.StartTime as numeric(38, 6)))
then min(l2.StartTime)	--同一天，取后续时间
else cast( (cast(FLOOR(cast(l1.StartTime as numeric(38, 6))) as numeric(38, 6)) + 1) as datetime )	--非同一天，取该天的24:00
end LossTime
from ( select * from #TempLogin 
	where (isnull(timelen, 0) = 0) ) l1	--timelen为NULL数据
join #TempLogin l2 
on (l1.agent = l2.agent) and (l2.StartTime > l1.StartTime) 	--取存在同座席后续时间的记录
	and (l1.status = 2 or (l1.status = l2.status))					-- 1对应1， 1/2对应2
group by l1.Logid, l1.StartTime
) ll
where tl.Logid = ll.Logid

update #TempLogin set timelen = DATEDIFF(ms, starttime, @time_end),
	EndTime = @time_end where isnull(timelen, 0) = 0
----------------------------------------------------------------

-- Create Init Records
create table #TempAgentInfo (
	RecDT bigint, 
	agent char(20),
	TimeSpan int, 
	LoginTime int,
	ReadyTime int,
	NotReadyTime int
)

create table #TempSkillInfo (
	RecDT bigint, 
	skill char(20),
	TimeSpan int, 
	AgentNum int,
	LoginTime int,
	ReadyTime int,
	NotReadyTime int
)

select distinct agent, skills into #TempAgent from #TempLogin

set @time_loop = @time_begin
while @time_loop < @time_end begin
	select @RecDT = dbo.time_to_bigint(@time_loop, @SplitTm), 
	       @time_loop_end = dateadd(minute, @SplitTm, @time_loop)

	insert into #TempAgentInfo
		select @RecDT, a.agent, @SplitTm TimeSpan, 
			isnull(sum((case l.status when 1 then 1 else 0 end) * datediff(ss, 
				case when starttime > @time_loop then starttime else @time_loop end, 
				case when endtime < @time_loop_end then endtime else @time_loop_end end
				)), 0) LoginTime,
			isnull(sum((case l.status when 2 then 1 else 0 end) * datediff(ss, 
				case when starttime > @time_loop then starttime else @time_loop end, 
				case when endtime < @time_loop_end then endtime else @time_loop_end end
				)), 0) ReadyTime,
			0 NotReadyTime
		from #TempAgent a left join #TempLogin l on a.agent = l.agent 
			and a.skills = l.skills
			and ((l.starttime between @time_loop and @time_loop_end) or
			     (l.endtime  between @time_loop and @time_loop_end) or
			     (l.starttime < @time_loop and l.endtime > @time_loop_end))
		group by a.agent, isnull(TimeSpan, @SplitTm)


	insert into #TempSkillInfo
		select @RecDT, s.skill, @SplitTm TimeSpan, 
			count (*) AgenNnum,
			isnull(sum((case l.status when 1 then 1 else 0 end) * datediff(ss, 
				case when starttime > @time_loop then starttime else @time_loop end, 
				case when endtime < @time_loop_end then endtime else @time_loop_end end
				)), 0) LoginTime,
			isnull(sum((case l.status when 2 then 1 else 0 end) * datediff(ss, 
				case when starttime > @time_loop then starttime else @time_loop end, 
				case when endtime < @time_loop_end then endtime else @time_loop_end end
				)), 0) ReadyTime,
			0 NotReadyTime
		from SkillLog s inner join #TempLogin l on s.logid = l.logid
			and ((l.starttime between @time_loop and @time_loop_end) or
			     (l.endtime  between @time_loop and @time_loop_end) or
			     (l.starttime < @time_loop and l.endtime > @time_loop_end))
		group by s.skill, TimeSpan

	set @time_loop = @time_loop_end
	continue
end

--  select * from #TempAgentInfo	

update #TempAgentInfo 
	set LoginTime = case when LoginTime > TimeSpan * 60 then TimeSpan * 60 else LoginTime end,
	    ReadyTime = case when ReadyTime > TimeSpan * 60 then TimeSpan * 60 else ReadyTime end,
	    NotReadyTime = case when (LoginTime - ReadyTime) > TimeSpan * 60 then TimeSpan * 60 else LoginTime - ReadyTime end

/*
update #TempAgentInfo
	set LoginTime = TimeSpan * 60,
	     NotReadyTime = TimeSpan * 60 - ReadyTime
	where loginTime = 0 and NotReadyTime < 0
*/

update #TempAgentInfo
	set NotReadyTime = LoginTime - ReadyTime
	where logintime < readytime + notreadytime

update #TempAgentInfo set logintime = readytime, notreadytime = 0 
	where notreadytime < 0

-- select * from #TempAgentInfo order by agent, RecDT
-- select * from stat_agent

delete stat_agent 
	where recdt between @RecF and @RecT

insert into stat_agent
	select * from #TempAgentInfo

delete stat_skill
	where recdt between @RecF and @RecT

insert into stat_skill
	select * from #TempSkillInfo


/*** for debug ***/
/*select * from #TempAgentInfo
select * from #TempSkillInfo
select * from #TempAgent
select * from #TempLoginBef
select * from #TempLogin*/
----------------------

drop table #TempAgentInfo
drop table #TempSkillInfo

drop table #TempAgent
drop table #TempLoginBef
drop table #TempLogin
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_realtime]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[sp_stat_realtime]
AS
	declare @ucd_begin bigint, @repdate int
	
	set @repdate = year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate())
	set @ucd_begin = cast(@repdate as bigint) * 1000000
	select  count(*) total, 
	 	sum(case when type = 1 then 1 else 0 end) total_in,
	 	sum(case when type = 2 then 1 else 0 end) total_out,
	 	sum(case when type = 0 then 1 else 0 end) total_inner,
	 	sum(case when skill != '' then 1 else 0 end) total_skill,
	 	sum(case when skill != '' and (bRing = 1 or bEstb = 1) then 1 else 0 end) trans,
	 	sum(case when skill != '' and bEstb = 1 and type != 2 then 1 else 0 end) answer,
	 	sum(case when skill != '' and bEstb = 0 then 1 else 0 end) abandon,
	 	sum(case when skill != '' and bRing = 0 and bEstb = 0 then 1 else 0 end) aban_queue,
	 	sum(case when skill != '' and bRing = 1 and bEstb = 0 then 1 else 0 end) aban_agent
	from ucdcall
	where ucdid > @ucd_begin
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_sd_inbound_answer_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-29>
-- Description:	<2呼入电话请求答复者分布报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_sd_inbound_answer_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	
	-- 指定统计时间返回内某一具体时段（如：9:00 - 10:00）
	@PeriodTimeBegin datetime = null,		-- 某一具体时段的起始时间
	@PeriodTimeEnd datetime = null,			-- 某一具体时段的结束时间

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PeriodTimeBegin = @PeriodTimeBegin,
			@PeriodTimeEnd = @PeriodTimeEnd,
			@PrjID = @PrjID,
			@Skill = null,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end
	-- 数据库中的索引为{[RecDT] ASC, [GroupId] ASC}
	set @ExecSQL = 'Select case when RecDT is not null then ' + @DisplayPart + ' else ''' 
				 + dbo.get_stat_param('total_description') + ''' end RecDT, '
				 + 'TrunkIn_n, TrunkInAns_Ivr_n, TrunkInAns_Skill_n '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, '
				 + 'sum(TrunkIn_n) TrunkIn_n, '
				 + 'sum(TrunkInAns_Ivr_n) TrunkInAns_Ivr_n, '
				 + 'sum(TrunkInAns_Skill_n) TrunkInAns_Skill_n '
				 + 'From stat_call_trunk '
				 + 'Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' + cast(@RoundEnd as nvarchar(12)) 
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ' with Rollup) t '
				 + 'Where TrunkIn_n > 0 or TrunkInAns_Ivr_n > 0 or TrunkInAns_Skill_n > 0 '
				 + 'order by 1'

	-- for debug
	--print @ExecSQL
	--print 'len=' + cast(len(@ExecSQL) as varchar(50))

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value
END





GO
/****** Object:  StoredProcedure [dbo].[sp_stat_sd_skill_in_detail_ans_abn_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-29>
-- Description:	<4技能组呼入电话报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_sd_skill_in_detail_ans_abn_report]
	-- Add the parameters for the stored procedure here
	@Skill varchar(20),				-- 技能组
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目

	-- 指定统计时间返回内某一具体时段（如：9:00 - 10:00）
	@PeriodTimeBegin datetime = null,		-- 某一具体时段的起始时间
	@PeriodTimeEnd datetime = null,			-- 某一具体时段的结束时间

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PeriodTimeBegin = @PeriodTimeBegin,
			@PeriodTimeEnd = @PeriodTimeEnd,
			@PrjID = @PrjID,
			@Skill = @Skill,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end
	-- 数据库中的索引为{[RecDT] ASC, [Skill] ASC}
	set @ExecSQL = 'Select case when RecDT is not null then ' + @DisplayPart + ' else ''' 
				 + dbo.get_stat_param('total_description') + ''' end RecDT, '
				 + 'SkillIn_n, '
				 + 'Ans_n, '
				 + 'Aban_n '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, sum(SkillIn_n) SkillIn_n, '
				 + 'sum(Ans_n) Ans_n, '
				 + 'sum(Aban_n) Aban_n '
				 + 'From stat_call_skill '
				 + 'Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' + cast(@RoundEnd as nvarchar(12)) 
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ' with RollUp) t '
				 + 'Where SkillIn_n > 0 '
				 + 'order by 1'

	-- for debug
	--print @ExecSQL
	--print 'len=' + cast(len(@ExecSQL) as varchar(50))

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value
END




GO
/****** Object:  StoredProcedure [dbo].[sp_stat_sd_skill_in_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-29>
-- Description:	<3中继技能组呼入电话报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_sd_skill_in_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	
	-- 指定统计时间返回内某一具体时段（如：9:00 - 10:00）
	@PeriodTimeBegin datetime = null,		-- 某一具体时段的起始时间
	@PeriodTimeEnd datetime = null,			-- 某一具体时段的结束时间

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PeriodTimeBegin = @PeriodTimeBegin,
			@PeriodTimeEnd = @PeriodTimeEnd,
			@PrjID = @PrjID,
			@Skill = null,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end
	-- 数据库中的索引为{[RecDT] ASC, [Skill] ASC}
	set @ExecSQL = 'Select case when RecDT is not null then ' + @DisplayPart + ' else ''' 
				 + dbo.get_stat_param('total_description') + ''' end RecDT, '
				 + 'Skill, '
				 + 'SkillIn_n '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, Skill, sum(SkillIn_n) SkillIn_n '
				 + 'From stat_call_skill '
				 + 'Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' + cast(@RoundEnd as nvarchar(12)) 
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ', Skill with Cube) t '
				 + 'Where (Skill is not null) and SkillIn_n > 0 '
				 + 'order by 1, 2'

	-- for debug
	--print @ExecSQL
	--print 'len=' + cast(len(@ExecSQL) as varchar(50))

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value
END




GO
/****** Object:  StoredProcedure [dbo].[sp_stat_sd_trunk_in_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-29>
-- Description:	<1呼入电话_中继呼入电话报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_sd_trunk_in_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	
	-- 指定统计时间返回内某一具体时段（如：9:00 - 10:00）
	@PeriodTimeBegin datetime = null,		-- 某一具体时段的起始时间
	@PeriodTimeEnd datetime = null,			-- 某一具体时段的结束时间

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PeriodTimeBegin = @PeriodTimeBegin,
			@PeriodTimeEnd = @PeriodTimeEnd,
			@PrjID = @PrjID,
			@Skill = null,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end
	-- 数据库中的索引为{[RecDT] ASC, [GroupId] ASC}
	set @ExecSQL = 'Select case when RecDT is not null then ' + @DisplayPart + ' else ''' 
				 + dbo.get_stat_param('total_description') + ''' end RecDT, '
				 + 'GroupId, '
				 + 'TrunkIn_n '
				 + 'From (Select ' 
				 + @GroupPart + ' RecDT, GroupId, sum(TrunkIn_n) TrunkIn_n '
				 + 'From stat_call_trunk '
				 + 'Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' + cast(@RoundEnd as nvarchar(12)) 
				 + ')' + @WherePart + 'Group by ' + @GroupPart + ', GroupId with Cube) t '
				 + 'Where (GroupId is not null) and TrunkIn_n > 0 '
				 + 'order by 1, 2'

	-- for debug
	--print @ExecSQL
	--print 'len=' + cast(len(@ExecSQL) as varchar(50))

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value
END




GO
/****** Object:  StoredProcedure [dbo].[sp_stat_skill_report]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-29>
-- Description:	<查询统计中间结果表，取得完整的技能组呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_skill_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Skill varchar(20) = null,		-- 缺省null表示所有技能组
	
	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Skill = @Skill,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end
	-- 数据库中的索引为{RecDate (ASC), Skill (ASC)}
	--set @ExecSQL = 'Select ' + @DisplayPart + ' RecDT, Skill, '
		set @ExecSQL = 'Select  case when isnull(t.RecDT,'''') != '''' then  ' + @DisplayPart + ' else ''合计'' end RecDT,skill,'
	--set @ExecSQL = 'Select Case When Grouping('+@DisplayPart+') = 1 then ''''总计'''' else '+ @DisplayPart+' end'
	--			 + ' RecDT, Skill, '
	--
				 + 'TrunkIn, TrunkInAns, '
				 + 'CallOffer, CallAns, AnsLess, AnsMore, CallAban, vxi_def.dbo.avg_float(CallAban, SkillIn_n, 2) AbanRate, '
				 + 'AbanSkill, AbanAgent, AbanLess, AbanMore, '
				 + 'TotalTalkTime, vxi_def.dbo.avg_int(TotalTalkTime, CallAns) AvgTalkTime, '
				 + 'vxi_def.dbo.avg_int(Hold_t, CallAns) AvgHoldTime, '
				 + 'vxi_def.dbo.avg_int(Ans_t, CallAns) AvgRingTime, '
				 + 'vxi_def.dbo.avg_int(Acw_t, CallAns) AvgAcwTime, '
				 + 'vxi_def.dbo.avg_int(Handle_t, CallAns) AvgHandleTime, '
				 + 'vxi_def.dbo.avg_float(WaitLess_n, SkillIn_n, 2) SvcLevel, CallTrans, '
				 + 'vxi_def.dbo.avg_float(CallTrans, CallAns, 2) CallTransRate, CallConf, LoginTime, (Ready_t + Acw_t) AvailTime, '
				 + 'vxi_def.dbo.avg_float(Ready_t + Acw_t, LoginTime, 2) AvailRate, '
				 + 'vxi_def.dbo.avg_float(Handle_t, LoginTime, 2) Occupancy '
				 + 'From (Select ' 
				 --modified by wenyong xia 2007 12/03
				 --+ ' Case When Grouping('+@GroupPart+') = 1 then 0 else '+ @GroupPart+' end RecDT,Skill,'
				 --+ ' Case When Grouping(skill) = 1 then '+'''----'''+' else skill end skill,'
				 + @GroupPart + ' RecDT, Skill, '
				 + 'sum(TrunkIn_n) TrunkIn, sum(TrunkInAns_n) TrunkInAns, '
				 + 'sum(Skill_n) CallOffer, sum(SkillIn_n) SkillIn_n, sum(Ans_n) CallAns, sum(AnsLess_n) AnsLess, '
				 + 'sum(AnsMore_n) AnsMore, sum(Aban_n) CallAban,  sum(AbanSkill) AbanSkill, sum(AbanAgent) AbanAgent, '
				 + 'sum(AbanLess) AbanLess, sum(AbanMore) AbanMore, sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) Ans_t, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) TotalTalkTime, sum(vxi_def.dbo.ms_to_int_sec(Hold_t)) Hold_t, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Acw_t)), 0) Acw_t, sum(vxi_def.dbo.ms_to_int_sec(Handle_t)) Handle_t, '
				 + 'sum(WaitLess_n) WaitLess_n, sum(Trans_n) CallTrans, sum(Conf_n) CallConf, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Login_t)) LoginTime, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Ready_t)), 0) Ready_t '
				 + 'From stat_call_skill Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) 
				 --modified by wenyong xia 2007 12/03
				 + ')' + @WherePart + 'Group by ' + @GroupPart	 + ', Skill with Rollup ) t'
				 --+ ' having (GROUPING('+@GroupPart+') = 1 ) or (not GROUPING(skill) = 1 )) t Order by RecDT, Skill'
				 --
				 
	--add by wenyong xia 2007 12/04
	set @ExecSQL = 'Select  a.RecDT,a.skill,a.TrunkIn, a.TrunkInAns, a.CallOffer, a.CallAns, a.AnsLess, a.AnsMore, '+
				 + 'a.CallAban, a.AbanRate, a.AbanSkill, a.AbanAgent, a.AbanLess, a.AbanMore, a.TotalTalkTime, a.AvgTalkTime,  '
				 + 'a.AvgHoldTime, a.AvgRingTime, a.AvgAcwTime, a.AvgHandleTime, a.SvcLevel, a.CallTrans, a.CallTransRate, a.CallConf,  '
				 + 'a.LoginTime, a.availTime, a.AvailRate, a.Occupancy From (' 
				 + @ExecSQL + ' ) a where ((a.RecDT = ''合计'' and  a.skill is null) or (a.skill is not null))  '
				 + 'Order by a.RecDT, a.skill'

	-- for debug
	print @ExecSQL
	-- print 'len=' + cast(len(@ExecSQL) as varchar(50))

	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value
END



GO
/****** Object:  StoredProcedure [dbo].[sp_stat_skill_report_save]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-29>
-- Description:	<查询统计中间结果表，取得完整的技能组呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_stat_skill_report_save]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Skill varchar(20) = null,		-- 缺省null表示所有技能组
	
	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@date_group varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS

begin try
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Error int, @SpecBeginEnd bit
	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @return_value int

	EXEC	@return_value = [dbo].[sp_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@date_group = @date_group OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Skill = @Skill,
			@SplitTm = @SplitTm

	/*
	-- for debug
	SELECT	@return_value as N'@Return Value',
			@RepDate as N'@RepDate',
			@Time_Begin as N'@Time_Begin',
			@Time_End as N'@Time_End',
			@date_group as N'@date_group',
			@RoundBegin as N'@RoundBegin',
			@RoundEnd as N'@RoundEnd',
			@DisplayPart as N'@DisplayPart',
			@GroupPart as N'@GroupPart',
			@WherePart as N'@WherePart'
	--*/

	if @return_value != 0 begin
		return @return_value
	end
	-- 数据库中的索引为{RecDate (ASC), Skill (ASC)}
	--set @ExecSQL = 'Select ' + @DisplayPart + ' RecDT, Skill, '
		set @ExecSQL = 'Select  case when isnull(t.RecDT,'''') != '''' then  ' + @DisplayPart + ' else ''合计'' end RecDT,skill,'
	--set @ExecSQL = 'Select Case When Grouping('+@DisplayPart+') = 1 then ''''总计'''' else '+ @DisplayPart+' end'
	--			 + ' RecDT, Skill, '
	--
				 + 'TrunkIn, TrunkInAns, '
				 + 'CallOffer, CallAns, AnsLess, AnsMore, CallAban, vxi_def.dbo.avg_float(CallAban, SkillIn_n, 2) AbanRate, '
				 + 'AbanSkill, AbanAgent, AbanLess, AbanMore, '
				 + 'TotalTalkTime, vxi_def.dbo.avg_int(TotalTalkTime, CallAns) AvgTalkTime, '
				 + 'vxi_def.dbo.avg_int(Hold_t, CallAns) AvgHoldTime, '
				 + 'vxi_def.dbo.avg_int(Ans_t, CallAns) AvgRingTime, '
				 + 'vxi_def.dbo.avg_int(Acw_t, CallAns) AvgAcwTime, '
				 + 'vxi_def.dbo.avg_int(Handle_t, CallAns) AvgHandleTime, '
				 + 'vxi_def.dbo.avg_float(WaitLess_n, SkillIn_n, 2) SvcLevel, CallTrans, '
				 + 'vxi_def.dbo.avg_float(CallTrans, CallAns, 2) CallTransRate, CallConf, LoginTime, (Ready_t + Acw_t) AvailTime, '
				 + 'vxi_def.dbo.avg_float(Ready_t + Acw_t, LoginTime, 2) AvailRate, '
				 + 'vxi_def.dbo.avg_float(Handle_t, LoginTime, 2) Occupancy '
				 + 'From (Select ' 
				 --modified by wenyong xia 2007 12/03
				 --+ ' Case When Grouping('+@GroupPart+') = 1 then 0 else '+ @GroupPart+' end RecDT,Skill,'
				 --+ ' Case When Grouping(skill) = 1 then '+'''----'''+' else skill end skill,'
				 + @GroupPart + ' RecDT, Skill, '
				 + 'sum(TrunkIn_n) TrunkIn, sum(TrunkInAns_n) TrunkInAns, '
				 + 'sum(Skill_n) CallOffer, sum(SkillIn_n) SkillIn_n, sum(Ans_n) CallAns, sum(AnsLess_n) AnsLess, '
				 + 'sum(AnsMore_n) AnsMore, sum(Aban_n) CallAban,  sum(AbanSkill) AbanSkill, sum(AbanAgent) AbanAgent, '
				 + 'sum(AbanLess) AbanLess, sum(AbanMore) AbanMore, sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) Ans_t, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) TotalTalkTime, sum(vxi_def.dbo.ms_to_int_sec(Hold_t)) Hold_t, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Acw_t)), 0) Acw_t, sum(vxi_def.dbo.ms_to_int_sec(Handle_t)) Handle_t, '
				 + 'sum(WaitLess_n) WaitLess_n, sum(Trans_n) CallTrans, sum(Conf_n) CallConf, '
				 + 'sum(vxi_def.dbo.ms_to_int_sec(Login_t)) LoginTime, '
				 + 'isnull(sum(vxi_def.dbo.ms_to_int_sec(Ready_t)), 0) Ready_t '
				 + 'From stat_call_skill Where (RecDT between ' 
				 + cast(@RoundBegin as nvarchar(12)) + ' and ' 
				 + cast(@RoundEnd as nvarchar(12)) 
				 --modified by wenyong xia 2007 12/03
				 + ')' + @WherePart + 'Group by ' + @GroupPart	 + ', Skill with Rollup ) t'
				 --+ ' having (GROUPING('+@GroupPart+') = 1 ) or (not GROUPING(skill) = 1 )) t Order by RecDT, Skill'
				 --
				 
	--add by wenyong xia 2007 12/04
	set @ExecSQL = 'Select  a.RecDT,a.skill,a.TrunkIn, a.TrunkInAns, a.CallOffer, a.CallAns, a.AnsLess, a.AnsMore, '+
				 + 'a.CallAban, a.AbanRate, a.AbanSkill, a.AbanAgent, a.AbanLess, a.AbanMore, a.TotalTalkTime, a.AvgTalkTime,  '
				 + 'a.AvgHoldTime, a.AvgRingTime, a.AvgAcwTime, a.AvgHandleTime, a.SvcLevel, a.CallTrans, a.CallTransRate, a.CallConf,  '
				 + 'a.LoginTime, a.availTime, a.AvailRate, a.Occupancy From (' 
				 + @ExecSQL + ' ) a where ((a.RecDT = ''合计'' and  a.skill is null) or (a.skill is not null))  '
				 + 'Order by a.RecDT, a.skill'

	-- for debug
	set @ExecSQL = 'Insert into vxi_rep..rep_stat_skill_report([RecDT]
      ,[skill]
      ,[TrunkIn]
      ,[TrunkInAns]
      ,[CallOffer]
      ,[CallAns]
      ,[AnsLess]
      ,[AnsMore]
      ,[CallAban]
      ,[AbanRate]
      ,[AbanSkill]
      ,[AbanAgent]
      ,[AbanLess]
      ,[AbanMore]
      ,[TotalTalkTime]
      ,[AvgTalkTime]
      ,[AvgHoldTime]
      ,[AvgRingTime]
      ,[AvgAcwTime]
      ,[AvgHandleTime]
      ,[SvcLevel]
      ,[CallTrans]
      ,[CallTransRate]
      ,[CallConf]
      ,[LoginTime]
      ,[availTime]
      ,[AvailRate]
      ,[Occupancy]) ' + @ExecSQL

	print @ExecSQL
	-- print 'len=' + cast(len(@ExecSQL) as varchar(50))
	delete from vxi_rep..rep_stat_skill_report where RecDT = @RepDate and Skill = @SKill
	exec @return_value = sp_executesql @ExecSQL
	
	return @return_value

end try
begin catch
	if @@trancount != 0 rollback
	return error_number()
end catch



GO
/****** Object:  StoredProcedure [dbo].[sp_syn_data_from_server]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <Create Date,,>
-- Description:	synchronize data from specific server
-- =============================================
CREATE PROCEDURE [dbo].[sp_syn_data_from_server]
	-- Add the parameters for the stored procedure here
	@ServerIP nvarchar(200),
	@User nvarchar(50) = 'sa',
	@Password nvarchar(50),
	@TimeBegin datetime,
	@TimeEnd datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @strSQL nvarchar(4000)
	declare @Result	int
	
	-- add linked server if specific server does not exists
	IF NOT EXISTS (SELECT srvname FROM master..sysservers WHERE srvid != 0 AND srvname = @ServerIP) begin
		EXEC master.dbo.sp_addlinkedserver @server = @ServerIP, @srvproduct=N'SQL Server'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'collation compatible', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'data access', @optvalue=N'true'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'dist', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'pub', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'rpc', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'rpc out', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'sub', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'connect timeout', @optvalue=N'0'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'collation name', @optvalue=null
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'lazy schema validation', @optvalue=N'false'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'query timeout', @optvalue=N'0'
		EXEC master.dbo.sp_serveroption @server=@ServerIP, @optname=N'use remote collation', @optvalue=N'true'
		EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname = @ServerIP, @locallogin = NULL, @useself = N'False', @rmtuser = @User, @rmtpassword = @Password
	end

	-------------------------------------------------------------------------------------------

	if @TimeBegin is null begin
		set @TimeBegin = convert(varchar(8), getdate(), 112)	-- yyyyMMdd
	end

	if @TimeEnd is null begin
		set @TimeEnd = getdate()
	end

	if @TimeBegin > @TimeEnd begin
		raiserror('@TimeBegin should be less than @TimeEnd', 1, 1)
		return 1
	end

	-------------------------------------------------------------------------------------------

	-- import ucd data from linked server
	exec sp_executesql N'if object_id(''tempdb..##RemoteUcd'') is not null drop table ##RemoteUcd'
	select	@ServerIP = '[' + @ServerIP + '].vxi_ucd.dbo.',
			@strSQL = 'select * into ##RemoteUcd from ' + @ServerIP + 'Ucd where StartTime between @From and @To'

	--print @strSQL
	exec @result = sp_executesql @strSQL,
								 N'@From datetime, @To datetime',
								 @From = @TimeBegin,
								 @To = @TimeEnd

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''Ucd'' fail', 1, 1)
		set @Result = 2
		goto ExitWithDropTempTable
	end

	CREATE INDEX [IX_RemoteUcd_temp] ON [##RemoteUcd](UCID)		-- UCID
	CREATE INDEX [IX_RemoteUcd_temp2] ON [##RemoteUcd](UcdId)	-- Ucdid

	-- delete existed data
	delete from ##RemoteUcd 
		where UCID in (select UCID from Ucd where StartTime between @TimeBegin and @TimeEnd)

	-------------------------------------------------------------------------------------------

	-- determine range of ucd which should be copied
	declare @MaxId bigint, @MinId bigint
	select @MaxId = max(UcdId), @MinId = min(UcdId) from ##RemoteUcd
	
	-------------------------------------------------------------------------------------------

	-- import ucdcall data from linked server
	exec sp_executesql N'if object_id(''tempdb..##RemoteUcdCall'') is not null drop table ##RemoteUcdCall'
	set @strSQL = 'select * into ##RemoteUcdCall from ' + @ServerIP + 'UcdCall where UcdId between @From and @To'
	--print @strSQL
	exec @result = sp_executesql @strSQL,
								 N'@From bigint, @To bigint',
								 @From = @MinId,
								 @To = @MaxId

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''UcdCall'' fail', 1, 1)
		set @Result = 3
		goto ExitWithDropTempTable
	end

	CREATE INDEX [IX_RemoteUcdCall_temp] ON [##RemoteUcdCall](UcdId)	-- Ucdid
	
	-- delete existed data
	delete from ##RemoteUcdCall where UcdId not in (select UcdId from ##RemoteUcd)

	-------------------------------------------------------------------------------------------

	-- import ucditem data from linked server
	exec sp_executesql N'if object_id(''tempdb..##RemoteUcdItem'') is not null drop table ##RemoteUcdItem'
	set @strSQL = 'select * into ##RemoteUcdItem from ' + @ServerIP + 'UcdItem where UcdId between @From and @To'
	--print @strSQL
	exec @result = sp_executesql @strSQL,
								 N'@From bigint, @To bigint',
								 @From = @MinId,
								 @To = @MaxId

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''UcdItem'' fail', 1, 1)
		set @Result = 4
		goto ExitWithDropTempTable
	end

	CREATE INDEX [IX_RemoteUcdItem_temp] ON [##RemoteUcdItem](UcdId)	-- Ucdid
	
	-- delete existed data
	delete from ##RemoteUcdItem where UcdId not in (select UcdId from ##RemoteUcd)
	
	-------------------------------------------------------------------------------------------

	-- import RouteRecord data from linked server
	exec sp_executesql N'if object_id(''tempdb..##RemoteRouteRecord'') is not null drop table ##RemoteRouteRecord'
	set @strSQL = 'select * into ##RemoteRouteRecord from ' + @ServerIP + 'RouteRecord where StartTime between @From and @To'

	--print @strSQL
	exec @result = sp_executesql @strSQL,
								 N'@From datetime, @To datetime',
								 @From = @TimeBegin,
								 @To = @TimeEnd

	if @@error != 0 or @result != 0 begin
		raiserror('importing ''RouteRecord'' fail', 1, 1)
		set @Result = 5
		goto ExitWithDropTempTable
	end
	
	CREATE INDEX [IX_RemoteRouteRecord_temp] ON [##RemoteRouteRecord](UCID)		-- UCID

	-- delete existed data
	delete from ##RemoteRouteRecord 
		where UCID in (select UCID from RouteRecord where StartTime between @TimeBegin and @TimeEnd)

	-------------------------------------------------------------------------------------------

	-- update ucdid
	declare @AddID bigint
	set @AddID = 50000000
	update ##RemoteUcd set UcdId = UcdId + @AddID
	update ##RemoteUcdCall set UcdId = UcdId + @AddID
	update ##RemoteUcdItem set UcdId = UcdId + @AddID
	update ##RemoteRouteRecord set RouteID = RouteID + @AddID
	
	-- copy temporary data to local server
	insert into [Ucd] ([UcdId], [ClientId], [Calling], [Called], [Answer], [Route], [Skill], [Trunk], [StartTime], [TimeLen], 
					   [Inbound], [Outbound], [Extension], [Agent], [UcdDate], [UcdHour], [PrjId], [UCID], [UUI])
		select [UcdId], [ClientId], [Calling], [Called], [Answer], [Route], [Skill], [Trunk], [StartTime], [TimeLen], 
			   [Inbound], [Outbound], [Extension], [Agent], [UcdDate], [UcdHour], [PrjId], [UCID], [UUI] from ##RemoteUcd
	--print @@rowcount

	insert into [UcdCall] ([UcdId], [SubId], [CallId], [Calling], [Called], [Answer], [Type], [Agent], [Route], [Skill], [Trunk], 
						   [CtrlDev], [bRing], [bEstb], [bHold], [bRetv], [bTrans], [bConf], [bOverflow], [bAcw], [OnCallBegin], 
						   [OnRoute], [OnSkill], [OnRing], [OnEstb], [OnHold], [OnRetv], [OnTrans], [OnConf], [OnConfEnd], [OnCallEnd], 
						   [OnOverflow], [OnAcwEnd], [UCID], [UUI])
		select [UcdId], [SubId], [CallId], [Calling], [Called], [Answer], [Type], [Agent], [Route], [Skill], [Trunk], 
			   [CtrlDev], [bRing], [bEstb], [bHold], [bRetv], [bTrans], [bConf], [bOverflow], [bAcw], [OnCallBegin], 
			   [OnRoute], [OnSkill], [OnRing], [OnEstb], [OnHold], [OnRetv], [OnTrans], [OnConf], [OnConfEnd], [OnCallEnd], 
			   [OnOverflow], [OnAcwEnd], [UCID], [UUI] from ##RemoteUcdCall
	--print @@rowcount

	insert into [UcdItem] ([UcdId], [PartyId], [Device], [Phone], [Agent], [bRing], [bEstb], [Enter], [Establish], [Leave], [AcwEnd])
		select [UcdId], [PartyId], [Device], [Phone], [Agent], [bRing], [bEstb], [Enter], [Establish], [Leave], [AcwEnd] from ##RemoteUcdItem		
	--print @@rowcount

	INSERT INTO [RouteRecord] ([RouteId], [UcdId], [CallId], [Calling], [Called], [Route], [StartTime], 
							   [TimeLen], [RouteTo], [DevType], [Result], [UCID])
		SELECT	[RouteId], [UcdId], [CallId], [Calling], [Called], [Route], [StartTime], 
				[TimeLen], [RouteTo], [DevType], [Result], [UCID]
			FROM ##RemoteRouteRecord

	--print @@rowcount
	set @Result = 0	
	
	-------------------------------------------------------------------------------------------

	-- clean
ExitWithDropTempTable:
	exec sp_executesql N'if object_id(''tempdb..##RemoteUcd'') is not null drop table ##RemoteUcd'
	exec sp_executesql N'if object_id(''tempdb..##RemoteUcdCall'') is not null drop table ##RemoteUcdCall'
	exec sp_executesql N'if object_id(''tempdb..##RemoteUcdItem'') is not null drop table ##RemoteUcdItem'
	exec sp_executesql N'if object_id(''tempdb..##RemoteRouteRecord'') is not null drop table ##RemoteRouteRecord'
	return @Result
END

GO
/****** Object:  StoredProcedure [dbo].[sp_syn_device_setup]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- Example: exec sp_syn_device_setup
-- =============================================
CREATE PROCEDURE [dbo].[sp_syn_device_setup]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @rowcount int

    -- Insert statements for procedure here
	delete rt_agent
		from rt_agent m
		where not exists(select 1 from vxi_sys..agent s where m.agent = s.agent)
	set @rowcount = @@rowcount

	print 'delete rt_agent rows:'
	print @rowcount
	print ''

	delete rt_device
		from rt_device m
		where not exists(select 1 from vxi_sys..devices s where m.device = s.device)
	set @rowcount = @@rowcount

	print 'delete rt_device rows:'
	print @rowcount
	print ''

	update rt_agent set enabled = s.enabled
		from rt_agent m, vxi_sys..agent s
		where m.agent = s.agent
			and isnull(m.enabled, 0) != isnull(s.enabled, 0)
	set @rowcount = @@rowcount

	print 'update rt_agent rows:'
	print @rowcount
	print ''

	update rt_device set enabled = s.enabled
		from rt_device m, vxi_sys..devices s
		where m.device = s.device
			and isnull(m.enabled, 0) != isnull(s.enabled, 0)
	set @rowcount = @@rowcount

	print 'update rt_device rows:'
	print @rowcount
	print ''

	insert into rt_agent (agent, device, enabled)
		select agent, '', enabled 
			from vxi_sys..agent m
			where not exists(select 1 from rt_agent s where m.agent = s.agent)
				and m.enabled = 1
	set @rowcount = @@rowcount

	print 'insert rt_agent rows:'
	print @rowcount
	print ''

	insert into rt_device (device, agent, skills, enabled)
		select device, '', '', enabled 
			from vxi_sys..devices m
			where not exists(select 1 from rt_device s where m.device = s.device)
				and m.enabled = 1
	set @rowcount = @@rowcount

	print 'insert rt_device rows:'
	print @rowcount
	print ''

END
GO
/****** Object:  StoredProcedure [dbo].[sp_syn_rt_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_syn_rt_agent]
	-- Add the parameters for the stored procedure here
	@Agent varchar(20) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	/********************增加chat rt_agent同步 by haignag.chen 20130806=================================*********************/
	set @Agent = isnull(@Agent,'')
	insert into vxi_chat..rt_agent(agent, LogFlag, FlagTime,Cause,LogId,SubId,LogTime,Enabled)
				select  Agent, 0, getdate() FlagTime,0,0,0,getdate() LogTime, Enabled from vxi_sys..Agent
					where Agent not in (select Agent from vxi_chat..rt_agent) and enabled=1 and (len(@Agent)=0 or  @Agent=Agent  )

	/********************=================================*********************/

    -- Insert statements for procedure here

	if isnull(@Agent, '') = '' begin
		-- 同步所有数据
		update ra set ra.Enabled = a.Enabled
			from vxi_ucd..rt_agent ra, vxi_sys..Agent a
			where ra.Agent = a.Agent

		insert into vxi_ucd..rt_agent(agent, device, Enabled)
			select Agent, '', Enabled from vxi_sys..Agent
				where Agent not in (select Agent from vxi_ucd..rt_agent)

		delete from vxi_ucd..rt_agent 
			where Agent not in (select Agent from vxi_sys..Agent)

		return 0
	end

	declare @Enabled bit
	set @Enabled = (select top 1 Enabled from vxi_sys..Agent where Agent = @Agent)
	
	if @Enabled is null begin
		delete from vxi_ucd..rt_agent where Agent = @Agent
		return 0
	end

	-- 按照设备最新Enabled值更新rt_agent的值
	update vxi_ucd..rt_agent set Enabled = @Enabled where Agent = @Agent
	if @@rowcount <= 0 begin
		-- rt_agent没有记录，且需要新增
		insert into vxi_ucd..rt_agent(agent, device, Enabled) values (@Agent, '', @Enabled)
	end
	
	return 0
END


--exec [dbo].[sp_syn_rt_agent]  @Agent='11111'



GO
/****** Object:  StoredProcedure [dbo].[sp_syn_rt_device]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_syn_rt_device]
	-- Add the parameters for the stored procedure here
	@Device varchar(20) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	if isnull(@Device, '') = '' begin
		-- 同步所有数据
		update rd set rd.Enabled = d.Enabled
			from vxi_ucd..rt_device rd, vxi_sys..Devices d
			where rd.device = d.device

		insert into vxi_ucd..rt_device(device, Enabled)
			select device, Enabled from vxi_sys..Devices
				where device not in (select device from vxi_ucd..rt_device)

		delete from vxi_ucd..rt_device 
			where device not in (select device from vxi_sys..Devices)

		return 0
	end

	declare @Enabled bit
	set @Enabled = (select top 1 Enabled from vxi_sys..Devices where device = @Device)

	if @Enabled is null begin
		delete from vxi_ucd..rt_device where Device = @Device
		return 0
	end	

	-- 按照设备最新Enabled值更新rt_device的值
	update vxi_ucd..rt_device set Enabled = @Enabled where Device = @Device
	if @@rowcount <= 0 begin
		-- rt_device没有记录，且需要设置enabled为可用
		insert into vxi_ucd..rt_device(device, Enabled) values (@Device, @Enabled)
	end

	return 0
END





GO
/****** Object:  StoredProcedure [dbo].[sp_syn_stat_call_hourly]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-03-15>
-- Description:	<将报表统计所需的数据存入统计中间表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_syn_stat_call_hourly]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 格式yyyyMMdd或yyyyMM，缺省0表示当前日期
	@PrjId int = 0,					-- 缺省0表示所有项目
	@Skill varchar(20) = null,		-- 缺省null表示所有技能组
	@Agent varchar(20) = null,		-- 缺省null表示所有坐席
	@SplitTm int = 30,				-- 统计间隔时长, 单位：分
	@AnsLim int = 15,				-- 统计应答时长分界点，单位：秒
	@AbanLim int = 15,				-- 统计放弃时长分界点，单位：秒
	@WaitLim int = 15				-- 统计约定时间内应答分界点，单位：秒
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SET ARITHABORT ON;
	SET ANSI_WARNINGS ON;
	--SET CONCAT_NULL_YIELDS_NULL ON;

    -- Insert statements for procedure here
	declare @BeginTime datetime, @EndTime datetime	-- 需要统计的起始/结束时间
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @Beg_UcdId bigint, @End_UcdId bigint	-- UcdId 范围
	declare @Error int

	-- 计算统计时间范围
	set @Error = 0
	if (@RepDate <= 0) begin
		set @RepDate = convert(varchar(8), getdate(), 112)	-- yyyyMMdd
	end

	if (@RepDate between 19001122 and 99998877) begin
		-- 作为yyyyMMdd处理
		select @BeginTime = dateadd(day, -1, cast(@RepDate as varchar(8))), @EndTime = dateadd(day, 2, @BeginTime)	-- 计算范围为2天
		set @Error = @@error
	end
	else if (@RepDate between 190011 and 999988) begin
		-- 作为yyyyMM处理
		select @BeginTime = cast(@RepDate as varchar(6)) + '01', @EndTime = dateadd(month, 1, @BeginTime)	-- 计算范围为1月
		set @Error = @@error
	end
	else if (@RepDate between 1900 and 9999) begin
		-- 作为yyyy处理
		select @BeginTime = cast(@RepDate as varchar(4)) + '0101', @EndTime = dateadd(year, 1, @BeginTime)	-- 计算范围为1年
		set @Error = @@error
	end
	else begin
		set @Error = 1
	end

	if @Error != 0 begin
		raiserror('The format of parameter ''@RepDate''[%d] is invalid, use as ''yyyymmdd'' or ''yyyymm'' or ''yyyy'' ', 1, 1, @RepDate)
		return 1
	end

	-- @BeginTime、@EndTime总是为整数小时
	select  @RoundBegin = dbo.time_to_bigint(@BeginTime, @SplitTm),	--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
			@RoundEnd = dbo.time_to_bigint(@EndTime, @SplitTm)		--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
	select @Beg_UcdId = @RoundBegin / 10000 * 1000000,
			@End_UcdId = @RoundEnd / 10000 * 1000000 + 999999
	-- for debug
	--print @BeginTime
	--print @EndTime

	-- 时间界限转毫秒数
	select @AnsLim = @AnsLim * 1000, @AbanLim = @AbanLim * 1000, @WaitLim = @WaitLim * 1000
	----------------------------------------------------------------------
/*
	type: 0: inner,	1: inbound,	2: outbound

	(type = 0, skill = '') 内部呼叫

	(type = 0, skill <> '') IVR转坐席的呼入
	(type = 1, skill <> '') 经过PBX到达技能组的呼入
	(type = 1, skill = '')  经过PBX直接到达坐席的呼入
	正常情况下(skill <> '')-->(type <> 2)，故到技能组的呼入是(skill <> '') [ and type <> 2]
	总的呼入是(type = 0 and skill <> '') or (type = 1)

	(type = 2, skill = '') : 坐席外拨
	正常情况下(type = 2)-->(skill = '')
*/

	--------------------- 技能组状态统计：时间、技能组 ------------------------
	select dbo.time_to_bigint(u.StartTime, @SplitTm) RecDate,	-- 整数化起始时间yyyyMMddhhmm
		/*isnull(c.Skill, a_s.Skill)*/ c.Skill,
		c.Agent,
		u.PrjId,
		(cast(c.Trunk as int) / 1000) TrunkGroupID,
		
		case when len(c.Agent) > 0 then 1 else 0 end Total_n,
		case when len(c.Agent) > 0 then c.OnCallEnd - 
			case when c.bRing = 1 then c.OnRing
				 when c.bEstb = 1 then c.OnEstb
				 else c.OnCallBegin
			end
		end Total_t,
		
		case when len(c.Agent) > 0 and len(c.Skill) > 0 then 1 else 0 end Skill_Agent_n,
		/*
		case when len(c.Agent) > 0 and len(c.Skill) > 0 then c.OnCallEnd - 
			case when c.bRing = 1 then c.OnRing
				 when c.bEstb = 1 then c.OnEstb
				 else c.OnCallBegin
			end
		end Skill_Agent_t,
		*/
		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then c.OnCallEnd - c.OnEstb 
		else 0 end Skill_Agent_t,

		case when len(c.Skill) > 0 or (c.Type = 2 and len(c.Agent) > 0) then 1 else 0 end Skill_n,
		case 
		when len(c.Skill) > 0 then
			(c.OnCallEnd - c.OnSkill)
		when (c.Type = 2 and len(c.Agent) > 0) then
			(c.OnCallEnd - c.OnCallBegin)
		else 0
		end Skill_t,

		case when len(c.Skill) > 0 then 1 else 0 end SkillIn_n,
		case when len(c.Skill) > 0 then (c.OnCallEnd - c.OnSkill) else 0 end SkillIn_t,
		
		case when c.bEstb = 1 and c.Type = 2 and len(c.Agent) > 0 then 1 else 0 end AgentOut_n,		
		case when c.bEstb = 1 and c.Type = 2 and len(c.Agent) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end AgentOut_t,
		
		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then 1 else 0 end Ans_n,
		
		case 
		when c.bEstb = 1 and c.bRing = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then 
			(c.OnEstb - c.OnRing) 
		else 0
		end Ans_t,
		
		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end Talk_t,

		case when c.bEstb = 1 and len(c.Agent) > 0 then 1 else 0 end Talk_Agent_All_n,
		case when c.bEstb = 1 and len(c.Agent) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end Talk_Agent_All_t,
		
		case when c.bEstb = 1 and len(c.Agent) > 0 and (c.Type = 2 or len(c.Skill) > 0) then (c.OnCallEnd - c.OnEstb) else 0 end Talk_Agent_t,

		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 1 then 1 else 0 end InTalk_n,
		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 1 then (c.OnCallEnd - c.OnEstb) else 0 end InTalk_t,

		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 1 and len(isnull(c.Skill, '')) <= 0 then 1 else 0 end ExtIn_n,
		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 1 and len(isnull(c.Skill, '')) <= 0 then (c.OnCallEnd - c.OnEstb) else 0 end ExtIn_t,

		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 0 and len(isnull(c.Skill, '')) <= 0 then 1 else 0 end ExtInner_n,
		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 0 and len(isnull(c.Skill, '')) <= 0 then (c.OnCallEnd - c.OnEstb) else 0 end ExtInner_t,

		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 2 then 1 else 0 end OutTalk_n,
		case when c.bEstb = 1 and len(c.Agent) > 0 and c.Type = 2 then (c.OnCallEnd - c.OnEstb) else 0 end OutTalk_t,

		case when c.bRing = 1 and len(c.Agent) > 0 then -- 有振铃且有坐席
			case when c.bEstb = 1 and (len(c.Skill) > 0 or c.Type = 2) then
				-- 通话建立且为 （技能组呼入或外拨）
				-- 有振铃、inbound、呼叫接通才认为是工作振铃
				-- 有振铃且为坐席外拨，则不论是否接通都认为是工作振铃
				c.OnEstb - c.OnRing
			when c.Type = 2 then
				-- 外拨电话未接通
				c.OnCallEnd - c.OnRing
			end			
		end Work_Ring_Agent_t,

		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 and (c.bRing = 0 or (c.OnEstb - c.OnRing <= @AnsLim)) then 1 else 0 end AnsLess_n,
		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 and (c.bRing = 1 and (c.OnEstb - c.OnRing > @AnsLim)) then 1 else 0 end AnsMore_n,

		case when c.bEstb = 0 and len(c.Skill) > 0 then 1 else 0 end Aban_n,
		case when c.bEstb = 0 and len(c.Skill) > 0 then (c.OnCallEnd - c.OnSkill) end Aban_t,
		case when c.bEstb = 0 and len(c.Skill) > 0 and len(isnull(c.Agent, '')) <= 0 then 1 else 0 end AbanSkill,
		case when c.bEstb = 0 and len(c.Skill) > 0 and len(c.Agent) > 0 then 1 else 0 end AbanAgent,
		case when c.bEstb = 0 and len(c.Skill) > 0 and len(c.Agent) > 0 and (c.bRing = 1) then (c.OnCallEnd - c.OnRing) else 0 end Aban_Agent_t,
		case when c.bEstb = 0 and len(c.Skill) > 0 and len(c.Agent) > 0 and (c.bRing = 0 or (c.OnCallEnd - c.OnRing <= @AbanLim)) then 1 else 0 end AbanLess,
		case when c.bEstb = 0 and len(c.Skill) > 0 and len(c.Agent) > 0 and (c.bRing = 1 and (c.OnCallEnd - c.OnRing > @AbanLim)) then 1 else 0 end AbanMore,
		
		isnull(
		case when c.bEstb = 0 and len(c.Skill) > 0 then 
			case when len(isnull(c.Agent, '')) <= 0 then (c.OnCallEnd - c.OnSkill)	-- 无座席取技能组放弃时间
				 when (c.bRing = 1) then (c.OnCallEnd - c.OnRing)	-- 有座席取座席放弃时间
			end
		end, 0) AbanSkillOrAgent_t,

		case when c.bHold = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then 1 else 0 end Hold_n,
		
		case 
		when c.bHold = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then 
			(case when c.bRetv = 1 then c.OnRetv else c.OnCallEnd end - c.OnHold)
		else 0 
		end Hold_t,
		
		case when c.bEstb = 1 and c.bHold = 1 and len(c.Agent) > 0  then 1 else 0 end Hold_Agent_n,

		case 
		when c.bEstb = 1 and c.bHold = 1 and len(c.Agent) > 0  then
			(case when c.bRetv = 1 then c.OnRetv else c.OnCallEnd end - c.OnHold)
		else 0 
		end Hold_Agent_t,

		--case when c.bEstb = 1 and c.bAcw = 1 and len(c.Agent) > 0 then (c.OnAcwEnd - c.OnCallEnd) else 0 end Acw_t,
		
		case 
		when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then
			(case when c.bAcw = 1 then c.OnAcwEnd else c.OnCallEnd end
				- case when c.bRing = 1 then c.OnRing else c.onEstb end)
		else 0
		end Handle_t,

		case 
		when c.bEstb = 1 and len(c.Agent) > 0 then
			(case when c.bAcw = 1 then c.OnAcwEnd else c.OnCallEnd end
				- case when c.bRing = 1 then c.OnRing else c.onEstb end)
		else 0
		end Handle_Agent_t,

		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 then (c.OnEstb - c.OnSkill) else 0 end Wait_t,
		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 and c.OnEstb - c.OnSkill <= @WaitLim then 1 else 0 end WaitLess_n,
		case when c.bEstb = 1 and len(c.Skill) > 0 and len(c.Agent) > 0 and c.OnEstb - c.OnSkill > @WaitLim then 1 else 0 end WaitMore_n,
		case when c.bTrans = 1 and len(c.Agent) > 0 and 
			exists(select * from vxi_sys..Devices d
					where d.devtype = 1 and d.enabled = 1 and d.device = c.CtrlDev collate Chinese_PRC_CI_AS ) then 1 else 0 end Trans_n,
		case when c.bConf = 1 and len(c.Agent) > 0 then 1 else 0 end Conf_n,

/*
		-- 现在按照整个ucd来统计Trunk数据，不按照ucdcall来统计
		case when len(c.Trunk) > 0 then 1 else 0 end Trunk_n,
		case when len(c.Trunk) > 0 then (c.OnCallEnd - c.OnCallBegin) else 0 end Trunk_t,

		case when c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end TrunkIn_n,
		case when c.Type = 1 and len(c.Trunk) > 0 then (c.OnCallEnd - c.OnCallBegin) else 0 end TrunkIn_t,
		case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end TrunkInAns_n,
		case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end TrunkInAns_t,

		case when c.Type = 2 and len(c.Trunk) > 0 then 1 else 0 end TrunkOut_n,
		case when c.Type = 2 and len(c.Trunk) > 0 then (c.OnCallEnd - c.OnCallBegin) else 0 end TrunkOut_t,
		case when c.bEstb = 1 and c.Type = 2 and len(c.Trunk) > 0 then 1 else 0 end TrunkOutAns_n,
		case when c.bEstb = 1 and c.Type = 2 and len(c.Trunk) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end TrunkOutAns_t,
*/
		
		case when c.bEstb = 1 and c.Type = 2 and len(c.Agent) > 0 and (c.OnCallEnd - c.OnEstb) < 10 * 1000 then 1 else 0 end TalkLess10_n,
		case when c.bEstb = 1 and c.Type = 2 and len(c.Agent) > 0 and (c.OnCallEnd - c.OnEstb) < 20 * 1000 then 1 else 0 end TalkLess20_n,
		case when c.bEstb = 1 and c.Type = 2 and len(c.Agent) > 0 and (c.OnCallEnd - c.OnEstb) >= 20 * 1000 then 1 else 0 end TalkMore20_n,

		case when len(isnull(c.Trunk, '')) <= 0 then 1 else 0 end Inner_n,
		case when len(isnull(c.Trunk, '')) <= 0 then (c.OnCallEnd - c.OnCallBegin) else 0 end Inner_t,

		u.Calling OrgCalling
	into #TempCall
	from Ucd u
	inner join UcdCall c on u.UcdId = c.Ucdid
		where u.UcdId between @Beg_UcdId and @End_UcdId
			and u.Starttime between @BeginTime and @EndTime
	--left join SkillAgent a_s on (len(isnull(c.Skill, '')) <= 0) and (c.Agent = a_s.Agent) -- SkillAgent可能一个坐席有多个技能组

	CREATE INDEX [IX_TempCall_temp] ON [#TempCall]([RecDate], [Agent])
	CREATE INDEX [IX_TempCall_temp2] ON [#TempCall]([RecDate], [Skill])
	CREATE INDEX [IX_TempCall_temp3] ON [#TempCall]([RecDate], [TrunkGroupID])
	--CREATE INDEX [IX_TempCall_temp4] ON [#TempCall]([Agent])
	--CREATE INDEX [IX_TempCall_temp5] ON [#TempCall]([Skill])
	--CREATE INDEX [IX_TempCall_temp6] ON [#TempCall]([TrunkGroupID])

	------------------------------------------------------------
	-- 现在按照整个ucd来统计Trunk数据，不按照ucdcall来统计
	-- 保存有呼叫过程中有trunk的ucd数据

	select
		u.UcdID, 
		dbo.time_to_bigint(min(u.StartTime), @SplitTm) RecDate,
		max(c.Trunk) Trunk, 
		(cast(max(c.Trunk) as int) / 1000) TrunkGroupID,
		max(c.Skill) Skill, 
		ltrim(right(min(
			case when len(c.Agent) > 0 then cast(c.SubId as varchar(11)) else '99999' end
			+ space(20) + c.Agent), 20)) Agent, -- 取第一个检测到的坐席

		max(case when len(c.Trunk) > 0 then 1 else 0 end) Trunk_n,
		max(case when len(c.Trunk) > 0 then u.TimeLen else 0 end) Trunk_t,

		max(case when c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end) TrunkIn_n,
		max(case when c.Type = 1 and len(c.Trunk) > 0 then u.TimeLen else 0 end) TrunkIn_t,

		max(case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end) TrunkInAns_All_n,
		
		-- 整个ucd中有中继呼入应答数，且有技能组应答，则TrunkInAns_Skill_n为1
		case when max(case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end) = 1 then
			max(case when c.bEstb = 1 and len(c.Skill) > 0 then 1 else 0 end) 
		else 0 end TrunkInAns_Skill_n,

		-- 整个ucd中有中继呼入应答数，且有坐席应答，则TrunkInAns_Agent_n为1
		case when max(case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end) = 1 then
			max(case when c.bEstb = 1 and len(c.Agent) > 0 then 1 else 0 end) 
		else 0 end TrunkInAns_Agent_n,

		-- 整个ucd中有中继呼入应答数，且有IVR应答但无Skill，则TrunkInAns_Ivr_n为1
		case when max(case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then 1 else 0 end) = 1 and
				  max(case when len(c.Skill) > 0 then 1 else 0 end) = 0
		then
			max(case when i.IvrNo is not null then 1 else 0 end)
		else 0 end TrunkInAns_Ivr_n,

		max(case when c.bEstb = 1 and c.Type = 1 and len(c.Trunk) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end) TrunkInAns_t,

		max(case when c.Type = 2 and len(c.Trunk) > 0 then 1 else 0 end) TrunkOut_n,
		max(case when c.Type = 2 and len(c.Trunk) > 0 then u.TimeLen else 0 end) TrunkOut_t,
		max(case when c.bEstb = 1 and c.Type = 2 and len(c.Trunk) > 0 then 1 else 0 end) TrunkOutAns_n,
		max(case when c.bEstb = 1 and c.Type = 2 and len(c.Trunk) > 0 then (c.OnCallEnd - c.OnEstb) else 0 end) TrunkOutAns_t
		
	into #TempTrunkCall
	from Ucd u
		inner join UcdCall c on u.UcdId = c.Ucdid
		left join (SELECT Channel IvrNo FROM vxi_sys..Channels WHERE ChType = 1 OR ChType / 16 = 1) i on c.Answer = i.IvrNo
		where u.UcdId between @Beg_UcdId and @End_UcdId
			and u.Starttime between @BeginTime and @EndTime
	group by u.UcdID

	CREATE INDEX [IX_TempTrunkCall_temp] ON [#TempTrunkCall]([RecDate], [Agent])	
	CREATE INDEX [IX_TempTrunkCall_temp2] ON [#TempTrunkCall]([RecDate], [Skill])
	CREATE INDEX [IX_TempTrunkCall_temp3] ON [#TempTrunkCall]([RecDate], [TrunkGroupID])

	-- for debug
	--select * from #TempTrunkCall

	----------------------------------------------------

	----------------------- 坐席状态相关 --------------------------
	-- declare @BeginTime datetime, @EndTime datetime, @SplitTm int

	-- 存放坐席在某一时间段内的状态统计。本过程假定某一时间（0.5/1小时）段内坐席不会更换技能组。
	-- 故由假定可以推断：同一时间段内(RecDate)，相同坐席(Agent)的技能组列表(Skills)必相同
	CREATE TABLE [dbo].[#TempStatAgent](
		[id] [int] IDENTITY(1,1) NOT NULL,	--*1
		[RecDate] [bigint] NOT NULL,	--*2
		[Agent] [char](20)  NOT NULL,	--*2
		[Skills] [varchar](50)  NOT NULL,
		[Login_t] [int] NULL,
		[Ready_t] [int] NULL,
		[Acw_t] [int] NULL,
		[Login_n] [int] NULL,
		[Ready_n] [int] NULL,
		[Acw_n] [int] NULL,
		[LoginTime] [datetime] NULL,
		[LogoutTime] [datetime] NULL,
		[NotReady00_n] [int] NULL,
		[NotReady01_n] [int] NULL,
		[NotReady02_n] [int] NULL,
		[NotReady03_n] [int] NULL,
		[NotReady04_n] [int] NULL,
		[NotReady05_n] [int] NULL,
		[NotReady06_n] [int] NULL,
		[NotReady07_n] [int] NULL,
		[NotReady08_n] [int] NULL,
		[NotReady09_n] [int] NULL,
		[NotReady00_t] [int] NULL,
		[NotReady01_t] [int] NULL,
		[NotReady02_t] [int] NULL,
		[NotReady03_t] [int] NULL,
		[NotReady04_t] [int] NULL,
		[NotReady05_t] [int] NULL,
		[NotReady06_t] [int] NULL,
		[NotReady07_t] [int] NULL,
		[NotReady08_t] [int] NULL,
		[NotReady09_t] [int] NULL,
		[Logout00_n] [int] NULL,
		[Logout01_n] [int] NULL,
		[Logout02_n] [int] NULL,
		[Logout03_n] [int] NULL,
		[Logout04_n] [int] NULL,
		[Logout05_n] [int] NULL,
		[Logout06_n] [int] NULL,
		[Logout07_n] [int] NULL,
		[Logout08_n] [int] NULL,
		[Logout09_n] [int] NULL,
		[Logout01_t] [int] NULL,
		[Logout02_t] [int] NULL,
		[Logout03_t] [int] NULL,
		[Logout04_t] [int] NULL,
		[Logout05_t] [int] NULL,
		[Logout06_t] [int] NULL,
		[Logout07_t] [int] NULL,
		[Logout08_t] [int] NULL,
		[Logout09_t] [int] NULL,
	)
	
	CREATE UNIQUE INDEX [IX_TempStatAgent] ON [#TempStatAgent]([RecDate], [Agent])
	CREATE UNIQUE INDEX [IX_TempStatAgent2] ON [#TempStatAgent]([id])
	
	-- 将Login时间小于统计结束时间且Logout时间大于统计起始时间的Login/Logout(有原因码)记录取出保存
	select LogID, Agent, isnull(Skills, '') Skills, StartTime OnLogStart,
		case when Finish = 1 then EndTime else getdate() end OnLogEnd,
		Finish, Flag, Cause
	into #TempAgentLogin
	from [Login] 
	where LogId between @Beg_UcdId and @End_UcdId
		and StartTime < @EndTime and (case when Finish = 1 then EndTime else getdate() end) > @BeginTime

	CREATE INDEX [IX_TempAgentLogin_temp] ON [#TempAgentLogin](Agent)
	CREATE INDEX [IX_TempAgentLogin_temp2] ON [#TempAgentLogin](OnLogStart)
	CREATE INDEX [IX_TempAgentLogin_temp3] ON [#TempAgentLogin](OnLogEnd)
	CREATE UNIQUE INDEX [IX_TempAgentLogin_temp4] ON [#TempAgentLogin](LogID)

	-- 将Login时间小于统计结束时间且Logout时间大于统计起始时间的Ready记录取出保存
	select l.Agent, r.Flag, 
		dateadd(ms, r.StartTime, l.OnLogStart) OnFlagStart,
		case 
		when r.Finish = 1 then
			dateadd(ms, r.StartTime + r.TimeLen, l.OnLogStart)
		else
			getdate()
		end OnFlagEnd,
		r.Cause
	into #TempAgentReady
	from #TempAgentLogin l
	inner join Ready r 
	on l.LogID = r.LogID and l.Flag = 1 /*and r.Flag != 0*/ -- 只连接Login-Logout范围内的相关数据

	CREATE INDEX [IX_TempAgentReady_temp] ON [#TempAgentReady](Agent)
	CREATE INDEX [IX_TempAgentReady_temp2] ON [#TempAgentReady](OnFlagStart)
	CREATE INDEX [IX_TempAgentReady_temp3] ON [#TempAgentReady](OnFlagEnd)

	-- @BeginTime、@EndTime总是为整数小时，统计范围从@BeginTime到@EndTime
	declare	@CalcBegin datetime, @CalcEnd datetime, @CalcRecDT bigint
	
	set @CalcBegin = @BeginTime
	while @CalcBegin < @EndTime begin
		select @CalcRecDT = dbo.time_to_bigint(@CalcBegin, @SplitTm),	-- 整数化起始时间yyyyMMddhhmm
			   @CalcEnd = dateadd(mi, @SplitTm, @CalcBegin)				-- 统计结束时间点

		-- 由于缩小统计范围，sum操作不会计算溢出，此处保留毫秒值
		-- [Logout00_t][int] NULL,	-- 00 不统计时间
		insert into #TempStatAgent(RecDate, Agent, Skills, Login_t, Login_n, LoginTime, LogoutTime,
			Logout00_n, Logout01_n, Logout02_n, Logout03_n, Logout04_n, Logout05_n, Logout06_n,	Logout07_n, Logout08_n, 
			Logout09_n, 
			Logout01_t, Logout02_t, Logout03_t, Logout04_t,	Logout05_t, Logout06_t, Logout07_t, Logout08_t, Logout09_t,
			Ready_t, Ready_n, Acw_t, Acw_n,
			NotReady00_n, NotReady01_n, NotReady02_n, NotReady03_n, NotReady04_n, NotReady05_n, NotReady06_n, 
			NotReady07_n, NotReady08_n, NotReady09_n, 
			NotReady00_t, NotReady01_t, NotReady02_t, NotReady03_t, NotReady04_t, NotReady05_t, NotReady06_t, 
			NotReady07_t, NotReady08_t, NotReady09_t
		)
		select @CalcRecDT RecDate, al.Agent, Skills, Login_t, Login_n, LoginTime, LogoutTime,
			(LogoutAll_n - Logout01_09_n) Logout00_n, Logout01_n, Logout02_n, Logout03_n, Logout04_n, Logout05_n, Logout06_n,
			Logout07_n, Logout08_n, Logout09_n, 
			Logout01_t, Logout02_t, Logout03_t, Logout04_t,	Logout05_t, Logout06_t, Logout07_t, Logout08_t, Logout09_t,
			isnull(Ready_t, 0) Ready_t, isnull(Ready_n, 0) Ready_n, isnull(Acw_t, 0) Acw_t, isnull(Acw_n, 0) Acw_n,
			isnull(NotReady00_n, 0) NotReady00_n, isnull(NotReady01_n, 0) NotReady01_n, isnull(NotReady02_n, 0) NotReady02_n, 
			isnull(NotReady03_n, 0) NotReady03_n, isnull(NotReady04_n, 0) NotReady04_n, isnull(NotReady05_n, 0) NotReady05_n, 
			isnull(NotReady06_n, 0) NotReady06_n, isnull(NotReady07_n, 0) NotReady07_n, isnull(NotReady08_n, 0) NotReady08_n, 
			isnull(NotReady09_n, 0) NotReady09_n, isnull(NotReady00_t, 0) NotReady00_t, isnull(NotReady01_t, 0) NotReady01_t, 
			isnull(NotReady02_t, 0) NotReady02_t, isnull(NotReady03_t, 0) NotReady03_t, isnull(NotReady04_t, 0) NotReady04_t, 
			isnull(NotReady05_t, 0) NotReady05_t, isnull(NotReady06_t, 0) NotReady06_t, isnull(NotReady07_t, 0) NotReady07_t, 
			isnull(NotReady08_t, 0) NotReady08_t, isnull(NotReady09_t, 0) NotReady09_t
		from (
			select Agent, max(Skills) Skills,
				isnull(sum(case when Flag = 1 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Login_t,
				isnull(sum(case when Flag = 1 and (OnLogStart between @CalcBegin and @CalcEnd) then 1 end), 0) Login_n,
				
				-- “Flag = 1” 表明“OnLogStart”指示Login时间点，“OnLogEnd”指示Logout时间点
				min(case when Flag = 1 /*and (OnLogStart between @CalcBegin and @CalcEnd)*/ then OnLogStart end) LoginTime, 
				max(case when Flag = 1 and Finish = 1 /*and (OnLogEnd between @CalcBegin and @CalcEnd)*/ then OnLogEnd end) LogoutTime,
				
				isnull(sum(case when Flag = 1 and Finish = 1 and (OnLogEnd between @CalcBegin and @CalcEnd) then 1 end), 0) LogoutAll_n,

				-- “Flag = 0” 表明“OnLogStart”指示Logout时间点，“OnLogEnd”指示Login时间点，此时必有原因码1-9
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause > 0 then 1 end), 0) Logout01_09_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 1 then 1 end), 0) Logout01_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 2 then 1 end), 0) Logout02_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 3 then 1 end), 0) Logout03_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 4 then 1 end), 0) Logout04_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 5 then 1 end), 0) Logout05_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 6 then 1 end), 0) Logout06_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 7 then 1 end), 0) Logout07_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 8 then 1 end), 0) Logout08_n,
				isnull(sum(case when Flag = 0 and (OnLogStart between @CalcBegin and @CalcEnd) and Cause = 9 then 1 end), 0) Logout09_n,

				isnull(sum(case when Flag = 0 and Cause = 1 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout01_t,
				isnull(sum(case when Flag = 0 and Cause = 2 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout02_t,
				isnull(sum(case when Flag = 0 and Cause = 3 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout03_t,
				isnull(sum(case when Flag = 0 and Cause = 4 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout04_t,
				isnull(sum(case when Flag = 0 and Cause = 5 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout05_t,
				isnull(sum(case when Flag = 0 and Cause = 6 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout06_t,
				isnull(sum(case when Flag = 0 and Cause = 7 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout07_t,
				isnull(sum(case when Flag = 0 and Cause = 8 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout08_t,
				isnull(sum(case when Flag = 0 and Cause = 9 then dbo.in_time(@CalcBegin, @CalcEnd, OnLogStart, OnLogEnd) end), 0) Logout09_t
			from #TempAgentLogin
			where OnLogStart < @CalcEnd and OnLogEnd > @CalcBegin
			group by Agent
		) al
		left join (
			select top 100 percent Agent, 
				sum(case when Flag = 0x03 then	-- 坐席就绪标志0x02 | 登录标志0x01
						dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd)
					end) Ready_t,
				sum(case when Flag = 0x03 and (OnFlagStart between @CalcBegin and @CalcEnd) then 1 end) Ready_n,
				
				sum(case when Flag = 0x05 then	-- 坐席话后工作标志0x04 | 登录标志0x01
						dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd)
					end) Acw_t,
				sum(case when Flag = 0x05 and (OnFlagStart between @CalcBegin and @CalcEnd) then 1 end) Acw_n,

				-- “Flag为0x01，Cause为0”说明由其他状态转到NotReady状态，包括初始Login后也算进入一次NotReady状态
				-- 若“Cause不为0” 说明是其他状态转到NotReady状态，且有原因。
				-- 直接由Ready状态转到Logout状态不计算内，因为此时NotReady时长是0
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 0 then 1 end) NotReady00_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 1 then 1 end) NotReady01_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 2 then 1 end) NotReady02_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 3 then 1 end) NotReady03_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 4 then 1 end) NotReady04_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 5 then 1 end) NotReady05_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 6 then 1 end) NotReady06_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 7 then 1 end) NotReady07_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 8 then 1 end) NotReady08_n,
				sum(case when Flag = 0x01 and (OnFlagStart between @CalcBegin and @CalcEnd) and Cause = 9 then 1 end) NotReady09_n,
				sum(case when Flag = 0x01 and Cause = 0 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady00_t,
				sum(case when Flag = 0x01 and Cause = 1 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady01_t,
				sum(case when Flag = 0x01 and Cause = 2 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady02_t,
				sum(case when Flag = 0x01 and Cause = 3 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady03_t,
				sum(case when Flag = 0x01 and Cause = 4 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady04_t,
				sum(case when Flag = 0x01 and Cause = 5 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady05_t,
				sum(case when Flag = 0x01 and Cause = 6 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady06_t,
				sum(case when Flag = 0x01 and Cause = 7 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady07_t,
				sum(case when Flag = 0x01 and Cause = 8 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady08_t,
				sum(case when Flag = 0x01 and Cause = 9 then dbo.in_time(@CalcBegin, @CalcEnd, OnFlagStart, OnFlagEnd) end) NotReady09_t
			from #TempAgentReady
			where OnFlagStart < @CalcEnd and OnFlagEnd > @CalcBegin
			group by Agent order by Agent
		) ar
		on al.Agent = ar.Agent collate Chinese_PRC_CI_AS
		
		-- 统计下一个范围
		set @CalcBegin = dateadd(mi, @SplitTm, @CalcBegin)
	end -- while @CalcBegin < @EndTime

	------------------- 1、坐席状态统计中间表 --------------------------
	-- 坐席可能同时登录多个技能组，但客户只会通过1个技能组找到坐席，
	-- 故坐席不通话时，其统计数据属于所有技能组，通话时其统计数据属于特定技能组。
	-- 坐席状态统计表中，只按照坐席分组
	begin tran
	delete from stat_agent where RecDT between @RoundBegin and @RoundEnd
	
	insert into stat_agent (RecDT, Agent, Skills, Period, PrjID, Login_t, Ready_t, Talk_t, Acw_t, Idle_t, 
		Login_n, Ready_n, Acw_n, LoginTime, LogoutTime, 
		NotReady00_n, NotReady01_n, NotReady02_n, NotReady03_n, NotReady04_n, 
		NotReady05_n, NotReady06_n, NotReady07_n, NotReady08_n, NotReady09_n, 
		NotReady00_t, NotReady01_t, NotReady02_t, NotReady03_t, NotReady04_t, 
		NotReady05_t, NotReady06_t, NotReady07_t, NotReady08_t, NotReady09_t, 
		Logout00_n, Logout01_n, Logout02_n, Logout03_n, Logout04_n, 
		Logout05_n, Logout06_n, Logout07_n, Logout08_n, Logout09_n, 
		Logout01_t, Logout02_t, Logout03_t, Logout04_t, Logout05_t, 
		Logout06_t, Logout07_t, Logout08_t, Logout09_t)
	select sa.RecDate RecDT, sa.Agent, Skills, @SplitTm [Period], PrjID, Login_t, Ready_t, Talk_Agent_t [Talk_t],
		Acw_t, 
		case when (Ready_t - isnull(Talk_Agent_t, 0) - isnull(Work_Ring_Agent_t, 0)) > 0 then (Ready_t - isnull(Talk_Agent_t, 0) - isnull(Work_Ring_Agent_t, 0)) else 0 end [Idle_t], 
		Login_n, Ready_n, Acw_n,
		LoginTime, LogoutTime, NotReady00_n, NotReady01_n, NotReady02_n, NotReady03_n, NotReady04_n, 
		NotReady05_n, NotReady06_n, NotReady07_n, NotReady08_n, NotReady09_n, NotReady00_t, NotReady01_t, 
		NotReady02_t, NotReady03_t, NotReady04_t, NotReady05_t, NotReady06_t, NotReady07_t, NotReady08_t, 
		NotReady09_t, Logout00_n, Logout01_n, Logout02_n, Logout03_n, Logout04_n, Logout05_n, Logout06_n, 
		Logout07_n, Logout08_n, Logout09_n, Logout01_t, Logout02_t, Logout03_t, Logout04_t, Logout05_t, 
		Logout06_t, Logout07_t, Logout08_t, Logout09_t
	from #TempStatAgent sa
	left join (select top 100 percent RecDate, Agent, max(PrjID) PrjID, sum(Talk_Agent_t) Talk_Agent_t,
					sum(Work_Ring_Agent_t) Work_Ring_Agent_t
				from #TempCall where len(Agent) > 0 group by RecDate, Agent order by RecDate, Agent) tc
	on sa.RecDate = tc.RecDate and sa.Agent collate Chinese_PRC_CI_AS = tc.Agent collate Chinese_PRC_CI_AS
	
	if @@Error = 0 begin
		commit tran
	end
	else begin
		rollback tran
		raiserror('update ''stat_agent'' fail', 11, 1)
		return 2
	end


	------------------- 2、坐席呼叫统计中间表 --------------------------
	-- 坐席可能同时登录多个技能组，但客户只会通过1个技能组找到坐席，
	-- 故坐席不通话时，其统计数据属于所有技能组，通话时其统计数据属于特定技能组。
	-- 坐席呼叫统计表中，只按照坐席分组

	begin tran
	delete from stat_call_agent where RecDT between @RoundBegin and @RoundEnd
	
	insert into stat_call_agent (RecDT, Agent, Period, PrjId, Total_n, Total_t, Skill_n, Skill_t, Ans_n, Ans_t, MaxAns_t,
			AnsLess_n, AnsMore_n, Aban_n, Aban_t, Loss_n, AbanLess, AbanMore, Talk_n, Talk_t, InTalk_n, InTalk_t,
			OutTalk_n, OutTalk_t, Hold_n, Hold_t, Acw_t, Handle_t, WaitLess_n, WaitMore_n, Trans_n, Conf_n, Trunk_n, 
			Trunk_t, TrunkIn_n, TrunkIn_t, TrunkInAns_n, TrunkInAns_t, TrunkOut_n, TrunkOut_t, TrunkOutAns_n, 
			TrunkOutAns_t, TalkLess10_n, TalkLess20_n, TalkMore20_n, Inner_n, Inner_t, ExtIn_n, ExtIn_t, ExtInner_n, ExtInner_t)
	select RecDT, tc.Agent, @SplitTm [Period], PrjId, Total_n, Total_t, Skill_n, Skill_t, Ans_n, Ans_t, MaxAns_t,
			AnsLess_n, AnsMore_n, Aban_n, Aban_t, Loss_n, AbanLess, AbanMore, Talk_n, Talk_t, InTalk_n, InTalk_t,
			OutTalk_n, OutTalk_t, Hold_n, Hold_t, Acw_t, Handle_t, WaitLess_n, WaitMore_n, Trans_n, Conf_n, Trunk_n, 
			Trunk_t, TrunkIn_n, TrunkIn_t, TrunkInAns_n, TrunkInAns_t, TrunkOut_n, TrunkOut_t, TrunkOutAns_n, 
			TrunkOutAns_t, TalkLess10_n, TalkLess20_n, TalkMore20_n, Inner_n, Inner_t, ExtIn_n, ExtIn_t, ExtInner_n, ExtInner_t 
	from
	(select RecDate RecDT, Agent, 
		max(PrjId) PrjId, sum(Total_n) Total_n, sum(Total_t) Total_t, sum(Skill_Agent_n) [Skill_n], 
		sum(Skill_Agent_t) [Skill_t], sum(Ans_n) Ans_n, sum(Ans_t) Ans_t, max(Ans_t) MaxAns_t, sum(AnsLess_n) AnsLess_n, 
		sum(AnsMore_n) AnsMore_n, sum(AbanAgent) [Aban_n], sum(Aban_Agent_t) [Aban_t], 
		count(distinct case when Aban_n = 1 then OrgCalling end) [Loss_n], -- 此处不区分是否坐席放弃 
		sum(AbanLess) AbanLess, sum(AbanMore) AbanMore, sum(Talk_Agent_All_n) [Talk_n], sum(Talk_Agent_All_t) [Talk_t], 
		sum(InTalk_n) InTalk_n, sum(InTalk_t) InTalk_t,	sum(OutTalk_n) OutTalk_n, sum(OutTalk_t) OutTalk_t, sum(Hold_Agent_n) [Hold_n], 
		sum(Hold_Agent_t) [Hold_t], /*sum(Acw_t) Acw_t,*/ sum(Handle_Agent_t) [Handle_t], sum(WaitLess_n) WaitLess_n, 
		sum(WaitMore_n) WaitMore_n, sum(Trans_n) Trans_n, sum(Conf_n) Conf_n, /*sum(Trunk_n) Trunk_n, 
		sum(Trunk_t) Trunk_t, sum(TrunkIn_n) TrunkIn_n, sum(TrunkIn_t) TrunkIn_t, sum(TrunkInAns_n) TrunkInAns_n, 
		sum(TrunkInAns_t) TrunkInAns_t, sum(TrunkOut_n) TrunkOut_n, sum(TrunkOut_t) TrunkOut_t, 
		sum(TrunkOutAns_n) TrunkOutAns_n, sum(TrunkOutAns_t) TrunkOutAns_t,*/ sum(TalkLess10_n) TalkLess10_n, 
		sum(TalkLess20_n) TalkLess20_n, sum(TalkMore20_n) TalkMore20_n, sum(Inner_n) Inner_n, sum(Inner_t) Inner_t,
		sum(ExtIn_n) ExtIn_n, sum(ExtIn_t) ExtIn_t, sum(ExtInner_n) ExtInner_n, sum(ExtInner_t) ExtInner_t
		from #TempCall where len(Agent) > 0 group by RecDate, Agent
	) tc 
	left join 
	(
		select top 100 percent RecDate, Agent, Acw_t from #TempStatAgent order by RecDate, Agent
	) sa
		on tc.RecDT = sa.RecDate and tc.Agent collate Chinese_PRC_CI_AS = sa.Agent collate Chinese_PRC_CI_AS
	left join 
	(
		select top 100 percent RecDate, Agent, 
			sum(Trunk_n) Trunk_n, sum(Trunk_t) Trunk_t, 
			sum(TrunkIn_n) TrunkIn_n, sum(TrunkIn_t) TrunkIn_t, 
			sum(TrunkInAns_Agent_n) TrunkInAns_n, sum(TrunkInAns_t) TrunkInAns_t, 
			sum(TrunkOut_n) TrunkOut_n, sum(TrunkOut_t) TrunkOut_t, 
			sum(TrunkOutAns_n) TrunkOutAns_n, sum(TrunkOutAns_t) TrunkOutAns_t
		from #TempTrunkCall where len(Agent) > 0 group by RecDate, Agent order by RecDate, Agent
	) tu 
		on tc.RecDT = tu.RecDate and tc.Agent collate Chinese_PRC_CI_AS = tu.Agent collate Chinese_PRC_CI_AS

	if @@Error = 0 begin
		commit tran
	end
	else begin
		rollback tran
		raiserror('update ''stat_call_agent'' fail', 11, 1)
		return 3
	end
	

	------------------- 3、中继呼叫统计中间表 --------------------------
	-- 中继呼叫统计表中，只按照中继组ID分组
	begin tran
	delete from stat_call_trunk where RecDT between @RoundBegin and @RoundEnd

	insert into stat_call_trunk (RecDT, GroupID, Period, Total_n, Total_t, TrunkIn_n, TrunkIn_t, 
		TrunkInAns_n, TrunkInAns_t, TrunkOut_n, TrunkOut_t, TrunkOutAns_n, TrunkOutAns_t, 
		TalkLess10_n, TalkLess20_n, TalkMore20_n, 
		TrunkInAns_Skill_n, TrunkInAns_Agent_n, TrunkInAns_Ivr_n
	)
	select RecDT, GroupID, @SplitTm [Period], Total_n, Total_t, TrunkIn_n, TrunkIn_t, 
		TrunkInAns_n, TrunkInAns_t, TrunkOut_n, TrunkOut_t, TrunkOutAns_n, TrunkOutAns_t, 
		TalkLess10_n, TalkLess20_n, TalkMore20_n,
		TrunkInAns_Skill_n, TrunkInAns_Agent_n, TrunkInAns_Ivr_n
	from
	(
		select RecDate RecDT, TrunkGroupID [GroupID], 
			/*
			sum(Trunk_n) [Total_n], sum(Trunk_t) [Total_t], 
			sum(TrunkIn_n) TrunkIn_n, sum(TrunkIn_t) TrunkIn_t, 
			sum(TrunkInAns_n) TrunkInAns_n, sum(TrunkInAns_t) TrunkInAns_t, 
			sum(TrunkOut_n) TrunkOut_n, sum(TrunkOut_t) TrunkOut_t, 
			sum(TrunkOutAns_n) TrunkOutAns_n, sum(TrunkOutAns_t) TrunkOutAns_t, 
			*/
			sum(TalkLess10_n) TalkLess10_n, sum(TalkLess20_n) TalkLess20_n, sum(TalkMore20_n) TalkMore20_n
		from #TempCall where TrunkGroupID > 0 group by RecDate, TrunkGroupID
	) tc
	left join 
	(
		select top 100 percent RecDate, TrunkGroupID,
			sum(Trunk_n) [Total_n], sum(Trunk_t) [Total_t], 
			sum(TrunkIn_n) TrunkIn_n, sum(TrunkIn_t) TrunkIn_t, 
			sum(TrunkInAns_All_n) TrunkInAns_n, sum(TrunkInAns_t) TrunkInAns_t, 
			sum(TrunkOut_n) TrunkOut_n, sum(TrunkOut_t) TrunkOut_t, 
			sum(TrunkOutAns_n) TrunkOutAns_n, sum(TrunkOutAns_t) TrunkOutAns_t,
			sum(TrunkInAns_Skill_n) TrunkInAns_Skill_n, 
			sum(TrunkInAns_Agent_n) TrunkInAns_Agent_n, 
			sum(TrunkInAns_Ivr_n) TrunkInAns_Ivr_n
		from #TempTrunkCall where TrunkGroupID > 0 group by RecDate, TrunkGroupID order by RecDate, TrunkGroupID
	) tu 
		on tc.RecDT = tu.RecDate and tc.GroupID = tu.TrunkGroupID


	if @@Error = 0 begin
		commit tran
	end
	else begin
		rollback tran
		raiserror('update ''stat_call_trunk'' fail', 11, 1)
		return 4
	end

	------------------- 坐席状态统计临时表#TempStatAgent技能组拆分 --------------------------
	-- 按技能组列表拆分为多条记录
	--begin tran
	-- for debug
	--select * from #TempStatAgent order by 1, 2

	-- 修改原唯一性索引
	CREATE INDEX [IX_TempStatAgent] ON #TempStatAgent([RecDate], [Skills]) WITH DROP_EXISTING
	CREATE INDEX [IX_TempStatAgent2] ON #TempStatAgent([id]) WITH DROP_EXISTING

	SET IDENTITY_INSERT #TempStatAgent ON

	declare @sa_Pos int, @sa_Skill varchar(50), @sa_LastPos int
	declare @sa_id int, @sa_RecDate bigint, @sa_Agent char(20), @sa_Skills varchar(50), @sa_Login_t int, 
		@sa_Ready_t int, @sa_Acw_t int, @sa_Login_n int, @sa_Ready_n int, @sa_Acw_n int, 
		@sa_LoginTime datetime, @sa_LogoutTime datetime, @sa_NotReady00_n int, @sa_NotReady01_n int, 
		@sa_NotReady02_n int, @sa_NotReady03_n int, @sa_NotReady04_n int, @sa_NotReady05_n int, 
		@sa_NotReady06_n int, @sa_NotReady07_n int, @sa_NotReady08_n int, @sa_NotReady09_n int, 
		@sa_NotReady00_t int, @sa_NotReady01_t int, @sa_NotReady02_t int, @sa_NotReady03_t int, 
		@sa_NotReady04_t int, @sa_NotReady05_t int, @sa_NotReady06_t int, @sa_NotReady07_t int, 
		@sa_NotReady08_t int, @sa_NotReady09_t int, @sa_Logout01_n int, @sa_Logout02_n int, 
		@sa_Logout03_n int, @sa_Logout04_n int, @sa_Logout05_n int, @sa_Logout06_n int, @sa_Logout07_n int, 
		@sa_Logout08_n int, @sa_Logout09_n int, @sa_Logout01_t int, @sa_Logout02_t int, @sa_Logout03_t int, 
		@sa_Logout04_t int, @sa_Logout05_t int, @sa_Logout06_t int, @sa_Logout07_t int, @sa_Logout08_t int, 
		@sa_Logout09_t int

	declare curStatAgent CURSOR FAST_FORWARD FOR 
	select id, RecDate, Agent, Skills, Login_t, Ready_t, Acw_t, Login_n, Ready_n, Acw_n, LoginTime, 
		LogoutTime, NotReady00_n, NotReady01_n, NotReady02_n, NotReady03_n, NotReady04_n, NotReady05_n, 
		NotReady06_n, NotReady07_n, NotReady08_n, NotReady09_n, NotReady00_t, NotReady01_t, NotReady02_t, 
		NotReady03_t, NotReady04_t, NotReady05_t, NotReady06_t, NotReady07_t, NotReady08_t, NotReady09_t, 
		Logout01_n, Logout02_n, Logout03_n, Logout04_n, Logout05_n, Logout06_n, Logout07_n, Logout08_n, 
		Logout09_n, Logout01_t, Logout02_t, Logout03_t, Logout04_t, Logout05_t, Logout06_t, Logout07_t, 
		Logout08_t, Logout09_t
	from #TempStatAgent

	-- 遍历整个#TempStatAgent，找到需要拆分的skills则拆分之

	OPEN curStatAgent
	fetch next from curStatAgent into @sa_id, @sa_RecDate, @sa_Agent, @sa_Skills, @sa_Login_t, @sa_Ready_t, 
		@sa_Acw_t, @sa_Login_n, @sa_Ready_n, @sa_Acw_n, @sa_LoginTime, @sa_LogoutTime, @sa_NotReady00_n, 
		@sa_NotReady01_n, @sa_NotReady02_n, @sa_NotReady03_n, @sa_NotReady04_n, @sa_NotReady05_n, 
		@sa_NotReady06_n, @sa_NotReady07_n, @sa_NotReady08_n, @sa_NotReady09_n, @sa_NotReady00_t, 
		@sa_NotReady01_t, @sa_NotReady02_t, @sa_NotReady03_t, @sa_NotReady04_t, @sa_NotReady05_t, 
		@sa_NotReady06_t, @sa_NotReady07_t, @sa_NotReady08_t, @sa_NotReady09_t, @sa_Logout01_n, 
		@sa_Logout02_n, @sa_Logout03_n, @sa_Logout04_n, @sa_Logout05_n, @sa_Logout06_n, @sa_Logout07_n, 
		@sa_Logout08_n, @sa_Logout09_n, @sa_Logout01_t, @sa_Logout02_t, @sa_Logout03_t, @sa_Logout04_t, 
		@sa_Logout05_t, @sa_Logout06_t, @sa_Logout07_t, @sa_Logout08_t, @sa_Logout09_t

	while @@FETCH_STATUS = 0
	begin

		select @sa_LastPos = 1, @sa_Pos = charindex(',', @sa_Skills)	-- 保存“,”位置
		if (@sa_Pos > 0) begin
			-- 删除原记录
			delete from #TempStatAgent where id = @sa_id

			while (@sa_Pos > 0) begin
				select @sa_Skill = substring(@sa_Skills, @sa_LastPos, @sa_Pos - @sa_LastPos), 
					   @sa_LastPos = @sa_Pos + 1,
					   @sa_Pos = charindex(',', @sa_Skills, @sa_LastPos)

				insert into #TempStatAgent(id, RecDate, Agent, Skills, Login_t, Ready_t, Acw_t, Login_n, Ready_n, Acw_n, 
					LoginTime, LogoutTime, NotReady00_n, NotReady01_n, NotReady02_n, NotReady03_n, NotReady04_n, 
					NotReady05_n, NotReady06_n, NotReady07_n, NotReady08_n, NotReady09_n, NotReady00_t, NotReady01_t, 
					NotReady02_t, NotReady03_t, NotReady04_t, NotReady05_t, NotReady06_t, NotReady07_t, NotReady08_t, 
					NotReady09_t, Logout01_n, Logout02_n, Logout03_n, Logout04_n, Logout05_n, Logout06_n, Logout07_n, 
					Logout08_n, Logout09_n, Logout01_t, Logout02_t, Logout03_t, Logout04_t, Logout05_t, Logout06_t, 
					Logout07_t, Logout08_t, Logout09_t)
				values (@sa_id, @sa_RecDate, @sa_Agent, @sa_Skill, @sa_Login_t, @sa_Ready_t, @sa_Acw_t, @sa_Login_n, 
					@sa_Ready_n, @sa_Acw_n, @sa_LoginTime, @sa_LogoutTime, @sa_NotReady00_n, @sa_NotReady01_n, 
					@sa_NotReady02_n, @sa_NotReady03_n, @sa_NotReady04_n, @sa_NotReady05_n, @sa_NotReady06_n, 
					@sa_NotReady07_n, @sa_NotReady08_n, @sa_NotReady09_n, @sa_NotReady00_t, @sa_NotReady01_t, 
					@sa_NotReady02_t, @sa_NotReady03_t, @sa_NotReady04_t, @sa_NotReady05_t, @sa_NotReady06_t, 
					@sa_NotReady07_t, @sa_NotReady08_t, @sa_NotReady09_t, @sa_Logout01_n, @sa_Logout02_n, 
					@sa_Logout03_n, @sa_Logout04_n, @sa_Logout05_n, @sa_Logout06_n, @sa_Logout07_n, @sa_Logout08_n, 
					@sa_Logout09_n, @sa_Logout01_t, @sa_Logout02_t, @sa_Logout03_t, @sa_Logout04_t, @sa_Logout05_t, 
					@sa_Logout06_t, @sa_Logout07_t, @sa_Logout08_t, @sa_Logout09_t)
			end
		    
			set @sa_Skill = substring(@sa_Skills, @sa_LastPos, 50)

			insert into #TempStatAgent(id, RecDate, Agent, Skills, Login_t, Ready_t, Acw_t, Login_n, Ready_n, Acw_n, 
				LoginTime, LogoutTime, NotReady00_n, NotReady01_n, NotReady02_n, NotReady03_n, NotReady04_n, 
				NotReady05_n, NotReady06_n, NotReady07_n, NotReady08_n, NotReady09_n, NotReady00_t, NotReady01_t, 
				NotReady02_t, NotReady03_t, NotReady04_t, NotReady05_t, NotReady06_t, NotReady07_t, NotReady08_t, 
				NotReady09_t, Logout01_n, Logout02_n, Logout03_n, Logout04_n, Logout05_n, Logout06_n, Logout07_n, 
				Logout08_n, Logout09_n, Logout01_t, Logout02_t, Logout03_t, Logout04_t, Logout05_t, Logout06_t, 
				Logout07_t, Logout08_t, Logout09_t)
			values (@sa_id, @sa_RecDate, @sa_Agent, @sa_Skill, @sa_Login_t, @sa_Ready_t, @sa_Acw_t, @sa_Login_n, 
				@sa_Ready_n, @sa_Acw_n, @sa_LoginTime, @sa_LogoutTime, @sa_NotReady00_n, @sa_NotReady01_n, 
				@sa_NotReady02_n, @sa_NotReady03_n, @sa_NotReady04_n, @sa_NotReady05_n, @sa_NotReady06_n, 
				@sa_NotReady07_n, @sa_NotReady08_n, @sa_NotReady09_n, @sa_NotReady00_t, @sa_NotReady01_t, 
				@sa_NotReady02_t, @sa_NotReady03_t, @sa_NotReady04_t, @sa_NotReady05_t, @sa_NotReady06_t, 
				@sa_NotReady07_t, @sa_NotReady08_t, @sa_NotReady09_t, @sa_Logout01_n, @sa_Logout02_n, 
				@sa_Logout03_n, @sa_Logout04_n, @sa_Logout05_n, @sa_Logout06_n, @sa_Logout07_n, @sa_Logout08_n, 
				@sa_Logout09_n, @sa_Logout01_t, @sa_Logout02_t, @sa_Logout03_t, @sa_Logout04_t, @sa_Logout05_t, 
				@sa_Logout06_t, @sa_Logout07_t, @sa_Logout08_t, @sa_Logout09_t)
		end -- if (@sa_Pos > 0)

		fetch next from curStatAgent into @sa_id, @sa_RecDate, @sa_Agent, @sa_Skills, @sa_Login_t, @sa_Ready_t, 
			@sa_Acw_t, @sa_Login_n, @sa_Ready_n, @sa_Acw_n, @sa_LoginTime, @sa_LogoutTime, @sa_NotReady00_n, 
			@sa_NotReady01_n, @sa_NotReady02_n, @sa_NotReady03_n, @sa_NotReady04_n, @sa_NotReady05_n, 
			@sa_NotReady06_n, @sa_NotReady07_n, @sa_NotReady08_n, @sa_NotReady09_n, @sa_NotReady00_t, 
			@sa_NotReady01_t, @sa_NotReady02_t, @sa_NotReady03_t, @sa_NotReady04_t, @sa_NotReady05_t, 
			@sa_NotReady06_t, @sa_NotReady07_t, @sa_NotReady08_t, @sa_NotReady09_t, @sa_Logout01_n, 
			@sa_Logout02_n, @sa_Logout03_n, @sa_Logout04_n, @sa_Logout05_n, @sa_Logout06_n, @sa_Logout07_n, 
			@sa_Logout08_n, @sa_Logout09_n, @sa_Logout01_t, @sa_Logout02_t, @sa_Logout03_t, @sa_Logout04_t, 
			@sa_Logout05_t, @sa_Logout06_t, @sa_Logout07_t, @sa_Logout08_t, @sa_Logout09_t

	end -- while @@FETCH_STATUS = 0

	SET IDENTITY_INSERT #TempStatAgent OFF

	CLOSE curStatAgent
	DEALLOCATE curStatAgent

	--commit tran

	-- for debug
	--select * from #TempStatAgent order by 1, 2

	------------------- 4、技能组呼叫统计中间表 --------------------------
	-- 坐席可能同时登录多个技能组，但客户只会通过1个技能组找到坐席，
	-- 故坐席不通话时，其统计数据属于所有技能组，通话时其统计数据属于特定技能组。
	-- 技能组状态统计表中，只按照技能组分组

	begin tran
	delete from stat_call_skill where RecDT between @RoundBegin and @RoundEnd

	insert into stat_call_skill(RecDT, Skill, Period, PrjId, Skill_n, Skill_t, SkillIn_n, SkillIn_t, AgentOut_n, 
			AgentOut_t, Ans_n, Ans_t, MaxAns_t, Talk_t, AnsLess_n, AnsMore_n, Aban_n, Aban_t, Loss_n, AbanSkill, AbanAgent, AbanLess, 
			AbanMore, Hold_n, Hold_t, Acw_t, Handle_t, Wait_t, WaitLess_n, WaitMore_n, Trans_n, Conf_n, Trunk_n, 
			Trunk_t, TrunkIn_n, TrunkIn_t, TrunkInAns_n, TrunkInAns_t, TrunkOut_n, TrunkOut_t, TrunkOutAns_n, 
			TrunkOutAns_t, Login_t, Ready_t, Work_t, Idle_t, Inner_n, Inner_t)
	select 	tc.RecDate RecDT, tc.Skill, @SplitTm [Period], PrjId, Skill_n, Skill_t, SkillIn_n, SkillIn_t, AgentOut_n, 
			AgentOut_t, Ans_n, Ans_t, MaxAns_t, Talk_t, AnsLess_n, AnsMore_n, Aban_n, Aban_t, Loss_n, AbanSkill, AbanAgent, AbanLess, 
			AbanMore, Hold_n, Hold_t, Acw_t, Handle_t, Wait_t, WaitLess_n, WaitMore_n, Trans_n, Conf_n, Trunk_n, 
			Trunk_t, TrunkIn_n, TrunkIn_t, TrunkInAns_n, TrunkInAns_t, TrunkOut_n, TrunkOut_t, TrunkOutAns_n, 
			TrunkOutAns_t, Login_t, Ready_t, (Talk_Agent_t + Acw_t) [Work_t], 
			case when (Ready_t - isnull(Talk_Agent_t, 0) - isnull(Work_Ring_Agent_t, 0)) > 0 then (Ready_t - isnull(Talk_Agent_t, 0) - isnull(Work_Ring_Agent_t, 0)) else 0 end [Idle_t], 
			Inner_n, Inner_t
	from (
		select RecDate, isnull(tc.Skill, a_s.Skill) Skill, max(PrjId) PrjId, sum(Skill_n) Skill_n, sum(Skill_t) Skill_t,
			sum(SkillIn_n) SkillIn_n, sum(SkillIn_t) SkillIn_t, sum(AgentOut_n) AgentOut_n, 
			sum(AgentOut_t) AgentOut_t,	sum(Ans_n) Ans_n, sum(Ans_t) Ans_t, max(Ans_t) MaxAns_t, sum(Talk_t) Talk_t, 
			sum(AnsLess_n) AnsLess_n, sum(AnsMore_n) AnsMore_n, sum(Aban_n) Aban_n, sum(Aban_t) Aban_t, 
			count(distinct case when Aban_n = 1 then OrgCalling end) [Loss_n], -- 此处不区分是否坐席放弃 
			sum(AbanSkill) AbanSkill, sum(AbanAgent) AbanAgent, sum(AbanLess) AbanLess, sum(AbanMore) AbanMore, 
			sum(Hold_n) Hold_n, sum(Hold_t) Hold_t, /*sum(Acw_t) Acw_t,*/ sum(Handle_t) Handle_t, sum(Wait_t) Wait_t, 
			sum(WaitLess_n) WaitLess_n, sum(WaitMore_n) WaitMore_n, sum(Trans_n) Trans_n, sum(Conf_n) Conf_n, 
/*			
			sum(Trunk_n) Trunk_n, sum(Trunk_t) Trunk_t, sum(TrunkIn_n) TrunkIn_n, sum(TrunkIn_t) TrunkIn_t, 
			sum(TrunkInAns_n) TrunkInAns_n, sum(TrunkInAns_t) TrunkInAns_t, sum(TrunkOut_n) TrunkOut_n, 
			sum(TrunkOut_t) TrunkOut_t, sum(TrunkOutAns_n) TrunkOutAns_n, sum(TrunkOutAns_t) TrunkOutAns_t, 
*/
			sum(Talk_Agent_t) Talk_Agent_t, sum(Inner_n) Inner_n, sum(Inner_t) Inner_t, 
			sum(Work_Ring_Agent_t) Work_Ring_Agent_t
		from #TempCall tc
		-- 连接使得1条没有skill的#TempCall产生多条skill对应记录，因为1坐席可能属于多个技能组
		left join vxi_sys..SkillAgent a_s on (len(isnull(tc.Skill, '')) <= 0) and (tc.Agent = a_s.Agent collate Chinese_PRC_CI_AS)
		where len(isnull(tc.Skill, a_s.Skill)) > 0 group by RecDate, isnull(tc.Skill, a_s.Skill)
	) tc 
	left join (
		-- CREATE INDEX [IX_TempStatAgent] ON #TempStatAgent([RecDate], [Skills]) WITH (DROP_EXISTING = ON)
		select top 100 percent RecDate, Skills Skill, sum(Login_t) Login_t, sum(Ready_t) Ready_t, sum(Acw_t) Acw_t
		from #TempStatAgent	group by RecDate, Skills order by RecDate, Skill	-- 按照技能组分组
	) sa	-- 已拆分skills的坐席状态表
		on tc.RecDate = sa.RecDate and tc.Skill collate Chinese_PRC_CI_AS = sa.Skill collate Chinese_PRC_CI_AS
	left join
	(
		select top 100 percent RecDate, Skill,
			sum(Trunk_n) Trunk_n, sum(Trunk_t) Trunk_t, 
			sum(TrunkIn_n) TrunkIn_n, sum(TrunkIn_t) TrunkIn_t, 
			sum(TrunkInAns_Skill_n) TrunkInAns_n, sum(TrunkInAns_t) TrunkInAns_t, 
			sum(TrunkOut_n) TrunkOut_n, sum(TrunkOut_t) TrunkOut_t, 
			sum(TrunkOutAns_n) TrunkOutAns_n, sum(TrunkOutAns_t) TrunkOutAns_t		
		from #TempTrunkCall where len(Skill) > 0 group by RecDate, Skill order by RecDate, Skill
	) tu 
		on tc.RecDate = tu.RecDate and tc.Skill collate Chinese_PRC_CI_AS = tu.Skill collate Chinese_PRC_CI_AS

	if @@Error = 0 begin
		commit tran
	end
	else begin
		rollback tran
		raiserror('update ''stat_call_skill'' fail', 11, 1)
		return 5
	end

	------------------- 4-2、技能组座席呼叫统计中间表 --------------------------
	-- 按技能组坐席分组统计
	delete from stat_call_skill_agent where RecDT between @RoundBegin and @RoundEnd
	insert into stat_call_skill_agent (
			RecDT, Skill, Agent, Ans_n, Aban_0_5_n, Aban_5_10_n, Aban_10_20_n,
			Aban_20_30_n, Aban_30_60_n, Aban_gt_60_n, Aban_t
		   )
	select	RecDate RecDT, Skill, Agent,
			sum(Ans_n) Ans_n, -- 此值仅在Agent存在时有效
			isnull(sum(case when Aban_n = 1 and AbanSkillOrAgent_t <= 5 * 1000 then 1 end), 0) Aban_0_5_n, 
			isnull(sum(case when Aban_n = 1 and (AbanSkillOrAgent_t between 5 * 1000 + 1 and 10 * 1000) then 1 end), 0) Aban_5_10_n, 
			isnull(sum(case when Aban_n = 1 and (AbanSkillOrAgent_t between 10 * 1000 + 1 and 20 * 1000) then 1 end), 0) Aban_10_20_n,
			isnull(sum(case when Aban_n = 1 and (AbanSkillOrAgent_t between 20 * 1000 + 1 and 30 * 1000) then 1 end), 0) Aban_20_30_n, 
			isnull(sum(case when Aban_n = 1 and (AbanSkillOrAgent_t between 30 * 1000 + 1 and 60 * 1000) then 1 end), 0) Aban_30_60_n, 
			isnull(sum(case when Aban_n = 1 and AbanSkillOrAgent_t > 60 * 1000 then 1 end), 0) Aban_gt_60_n, 
			sum(AbanSkillOrAgent_t) Aban_t
	from #TempCall tc
	where len(Skill) > 0 group by RecDate, Skill, Agent

	---------------------------------------------------------------------------------

	-- 以下统计Route记录
	select 
		dbo.time_to_bigint(StartTime, @SplitTm) RecDate,	-- 整数化起始时间yyyyMMddhhmm
		-- 作为主键的一部分，需要保证以下3字段非空
		isnull(DevType, 0) DevType, isnull(Route, '') Route, isnull(RouteTo, '') RouteTo, 
		TimeLen
	into #RouteRecordTemp
	from RouteRecord rr 
	where Starttime between @BeginTime and @EndTime

	CREATE INDEX [IX_RouteRecordTemp] ON [#RouteRecordTemp](RecDate, DevType, Route)
	CREATE INDEX [IX_RouteRecordTemp2] ON [#RouteRecordTemp](RecDate, RouteTo)

	begin tran
	delete from stat_route_type where RecDT between @RoundBegin and @RoundEnd
	
	INSERT INTO stat_route_type (RecDT, DevType, Route, Period, TimeLen, RecCount)
	Select recDate RecDT, DevType, Route, @SplitTm [Period], sum(TimeLen) TimeLen, count(*) [RecCount]
	From #RouteRecordTemp 
	Group by RecDate, DevType, Route 

	if @@Error = 0 begin
		commit tran
	end
	else begin
		rollback tran
		raiserror('update ''stat_route_type'' fail', 11, 1)
		return 6
	end


	begin tran
	delete from stat_route_to where RecDT between @RoundBegin and @RoundEnd

	INSERT INTO stat_route_to (RecDT, RouteTo, Period, TimeLen, RecCount)
	Select recDate RecDT, RouteTo, @SplitTm [Period], sum(TimeLen) TimeLen, count(*) [RecCount]
	From #RouteRecordTemp 
	Group by RecDate, RouteTo

	if @@Error = 0 begin
		commit tran
	end
	else begin
		rollback tran
		raiserror('update ''stat_route_to'' fail', 11, 1)
		return 7
	end

	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#TempCall')) DROP TABLE #TempCall
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#TempTrunkCall')) DROP TABLE #TempTrunkCall
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#TempStatAgent')) DROP TABLE #TempStatAgent
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#TempAgentLogin')) DROP TABLE #TempAgentLogin
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#TempAgentReady')) DROP TABLE #TempAgentReady
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#RouteRecordTemp')) DROP TABLE #RouteRecordTemp
	----------------------------------------------------------------------------------------------------------------------

	return 0
END
GO
/****** Object:  UserDefinedFunction [dbo].[func_day]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_day] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_month_first]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[func_month_first] (@date datetime)
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + 1)
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_month_last]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[func_month_last] (@date datetime)
RETURNS int AS  
BEGIN 
	declare @first datetime, @last datetime
	set @first = str(year(@date) * 10000 + month(@date) * 100 + 1)
	set @last = dateadd(dd, -1, dateadd(mm, 1, @first))
	return (year(@last) * 10000 + month(@last) * 100 + day(@last))
END




GO
/****** Object:  UserDefinedFunction [dbo].[func_time]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[func_time] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (datepart(hour, @date) * 10000 + datepart(minute, @date) * 100 + datepart(second, @date))
END



GO
/****** Object:  UserDefinedFunction [dbo].[func_tomorrow]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[func_tomorrow] (@date datetime)
RETURNS int AS  
BEGIN 
	declare @day datetime
	set @date = dateadd(day, 1, @date)
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_year_first]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[func_year_first] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + 101)
END



GO
/****** Object:  UserDefinedFunction [dbo].[func_yesterday]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION [dbo].[func_yesterday] (@date datetime)
RETURNS int AS  
BEGIN 
	declare @day datetime
	set @date = dateadd(day, -1, @date)
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[get_day]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE FUNCTION [dbo].[get_day] (@date datetime)
RETURNS int AS  
BEGIN 
	return year(@date) * 10000 + month(@date) * 100 + day(@date)
END

GO
/****** Object:  UserDefinedFunction [dbo].[get_stat_param]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[get_stat_param] 
(
	@key varchar(50)
)
RETURNS varchar(50)
AS
BEGIN
	-- Declare the return variable here
	DECLARE @result varchar(50) 

	SELECT @result = [value] from stat_param where [key] = @key

	RETURN @result
END

GO
/****** Object:  UserDefinedFunction [dbo].[get_time]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[get_time] 
(
	@time datetime, @unit int
)
RETURNS int
AS
BEGIN
	return datepart(hour, @time) * 100 + datepart(minute, @time) / @unit * @unit
END

GO
/****** Object:  UserDefinedFunction [dbo].[in_time]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	计算某个统计时间范围内，FlagTime实际应该被统计的时间长度，单位：毫秒
-- =============================================
CREATE FUNCTION [dbo].[in_time]
(
	-- Add the parameters for the function here
	@StatBeginTime datetime,	-- 统计起始时间
	@StatEndTime	datetime,	-- 统计结束时间
	@FlagBeginTime datetime,	-- 状态起始时间
	@FlagEndTime datetime		-- 状态结束时间
)
RETURNS int						-- 返回长度：单位毫秒
AS
BEGIN
	if (@StatEndTime <= @FlagBeginTime) -- 统计区间位于状态区间左边
		or (@StatBeginTime >= @FlagEndTime)	-- 统计区间位于状态区间右边
	begin
		return 0
	end

	-- Declare the return variable here
	DECLARE @CalcBeginTime datetime, @CalcEndTime datetime

	select
		@CalcBeginTime = case when @StatBeginTime >= @FlagBeginTime then @StatBeginTime else @FlagBeginTime end,
		@CalcEndTime = case when @StatEndTime <= @FlagEndTime then @StatEndTime else @FlagEndTime end

	-- Return the result of the function
	RETURN datediff(ms, @CalcBeginTime, @CalcEndTime)

END




GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_time]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[ms_to_time] ( @ms_time int )
RETURNS varchar(20) AS  
BEGIN 
	declare @time int, @hour  int, @min int, @sec int, @ms int, @retval varchar (20)
	select @ms = @ms_time % 1000, 	@time = @ms_time / 1000
	select @sec = @time % 60, 	@time = @time / 60
	select @min = @time % 60, 	@time = @time / 60
	select @hour = @time % 60, 	@retval = ''

	if @hour < 10 	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@hour)) + ':'
	if @min < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@min)) + ':'
	if @sec < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@sec)) + '.'
	if @ms < 100  	set @retval = @retval + '0'
	if @ms < 10   	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@ms))

	return @retval

END

GO
/****** Object:  UserDefinedFunction [dbo].[time_to_bigint]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  FUNCTION [dbo].[time_to_bigint] (@time datetime, @unit int)
RETURNS bigint AS
BEGIN 

	declare @result bigint, @idate bigint, @itime bigint

	select  	@idate = year(@time) * 10000 + month(@time) * 100 + day(@time), 
		@itime = datepart(hour, @time) * 100 + datepart(minute, @time) / @unit * @unit

	select @result = 10000 * @idate + @itime
	return @result
END




GO
/****** Object:  UserDefinedFunction [dbo].[trim_time]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
@unit: 整数倍时间，单位分钟
*/
CREATE        FUNCTION [dbo].[trim_time] (@time datetime, @unit int)
RETURNS datetime AS
BEGIN 
	declare @strDate varchar(14)	-- yyyy-mm-dd hh:
	declare @min int

	set @strDate = convert(varchar(14), @time, 120)
	set @min = datepart(minute, @time)
	set @min = @min - @min % @unit

	return @strDate + cast(@min as varchar(2)) + ':00'
		
/*	declare @result bigint, @idate bigint, @itime bigint
	select  	@idate = year(@time) * 10000 + month(@time) * 100 + day(@time), 
		@itime = datepart(hour, @time) * 100 + datepart(minute, @time) / @unit * @unit

	select @result = 10000 * @idate + @itime
	return @result*/
END


GO
/****** Object:  Table [dbo].[AgentEventDetail]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AgentEventDetail](
	[LogId] [bigint] NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[Agent] [varchar](20) NOT NULL,
	[Extension] [varchar](20) NULL,
	[Skill] [varchar](500) NULL,
	[LoginDateTime] [datetime] NULL,
	[Status] [int] NOT NULL,
	[TimeLen] [int] NULL,
	[Cause] [smallint] NULL,
 CONSTRAINT [PK_AgentEventDetail] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AgentLog]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AgentLog](
	[LogID] [bigint] NOT NULL,
	[Agent] [char](16) NOT NULL,
	[Device] [char](16) NOT NULL,
	[Skills] [varchar](50) NULL,
	[Status] [tinyint] NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
 CONSTRAINT [PK_AgentLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[blacklist]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[blacklist](
	[PhoneNo] [varchar](100) NOT NULL,
	[UserName] [varchar](100) NULL,
	[Level] [smallint] NULL,
	[bPermanent] [bit] NULL,
	[CreateDate] [int] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_blacklist] PRIMARY KEY CLUSTERED 
(
	[PhoneNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CallDetail]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CallDetail](
	[LogId] [bigint] IDENTITY(1,1) NOT NULL,
	[UcdId] [bigint] NOT NULL,
	[CallId] [int] NOT NULL,
	[CallType] [tinyint] NOT NULL,
	[Agent] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Route] [varchar](20) NULL,
	[StartTime] [datetime] NOT NULL,
	[CallDispositionFlag] [int] NULL,
	[CallDisposition] [smallint] NOT NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[OriCalling] [varchar](50) NULL,
	[OriCalled] [varchar](50) NULL,
	[Extension] [varchar](20) NULL,
	[TimeLen] [int] NULL,
	[RingLen] [int] NULL,
	[DelayLen] [int] NULL,
	[HoldLen] [int] NULL,
	[HoldTimes] [tinyint] NULL,
	[TalkLen] [int] NULL,
	[AcwLen] [int] NULL,
	[QueueLen] [int] NULL,
	[ConferenceLen] [int] NULL,
	[Variable1] [varchar](40) NULL,
	[Variable2] [varchar](40) NULL,
	[Variable3] [varchar](40) NULL,
	[Variable4] [varchar](40) NULL,
	[Variable5] [varchar](40) NULL,
	[Variable6] [varchar](40) NULL,
	[Variable7] [varchar](40) NULL,
	[Variable8] [varchar](40) NULL,
	[Variable9] [varchar](40) NULL,
	[Variable10] [varchar](40) NULL,
	[NewTransaction] [bit] NULL,
	[ICRCallKey] [bigint] NULL,
	[ICRCallKeyParent] [bigint] NULL,
	[ICRCallKeyChild] [bigint] NULL,
	[Trunk] [varchar](20) NULL,
	[RouterSequenceNumber] [int] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
 CONSTRAINT [PK_CallDetail] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CdrLog]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CdrLog](
	[CdrId] [bigint] NOT NULL,
	[CallId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Route] [varchar](20) NULL,
	[CallDate] [varchar](8) NULL,
	[CallTime] [varchar](4) NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[InGroup] [int] NULL,
	[InMember] [int] NULL,
	[InTrunk] [varchar](20) NULL,
	[OutGroup] [int] NULL,
	[OutMember] [int] NULL,
	[OutTrunk] [varchar](20) NULL,
	[Extension] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[PrjId] [int] NULL,
	[Frl] [char](1) NULL,
 CONSTRAINT [PK_CdrLog] PRIMARY KEY CLUSTERED 
(
	[CdrId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DevLog]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DevLog](
	[LogId] [bigint] NOT NULL,
	[Device] [varchar](20) NOT NULL,
	[AgentLogId] [bigint] NOT NULL,
	[OldFlag] [tinyint] NULL,
	[DevFlag] [tinyint] NOT NULL,
	[UcdId] [bigint] NULL,
	[CallId] [int] NULL,
	[BegTime] [datetime] NOT NULL,
	[TimeLen] [int] NOT NULL,
	[Finished] [bit] NULL,
	[EndTime]  AS (dateadd(millisecond,[timelen],[BegTime])),
 CONSTRAINT [PK_DevLog] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Login]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Login](
	[LogID] [bigint] NOT NULL,
	[Agent] [char](20) NOT NULL,
	[Device] [char](20) NOT NULL,
	[Skills] [varchar](50) NULL,
	[Finish] [bit] NULL,
	[Flag] [tinyint] NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[EndTime]  AS (dateadd(millisecond,[timelen],[StartTime])),
	[ReadyLen] [int] NULL,
	[AcwLen] [int] NULL,
	[cause] [smallint] NOT NULL,
	[BegRecTime] [int] NULL,
	[EndRecTime] [int] NULL,
 CONSTRAINT [PK_Login] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ready]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Ready](
	[LogID] [bigint] NOT NULL,
	[SubID] [smallint] NOT NULL,
	[Finish] [bit] NULL,
	[Flag] [tinyint] NULL,
	[StartTime] [int] NULL,
	[TimeLen] [int] NULL,
	[cause] [smallint] NOT NULL,
 CONSTRAINT [PK_Ready] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC,
	[SubID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[RouteCallDetail]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RouteCallDetail](
	[LogId] [bigint] IDENTITY(1,1) NOT NULL,
	[UcdId] [bigint] NOT NULL,
	[CallId] [int] NULL,
	[Route] [varchar](20) NULL,
	[StartTime] [datetime] NOT NULL,
	[Calling] [varchar](50) NULL,
	[QueueLen] [int] NULL,
	[Variable1] [varchar](40) NULL,
	[Variable2] [varchar](40) NULL,
	[Variable3] [varchar](40) NULL,
	[Variable4] [varchar](40) NULL,
	[Variable5] [varchar](40) NULL,
	[Variable6] [varchar](40) NULL,
	[Variable7] [varchar](40) NULL,
	[Variable8] [varchar](40) NULL,
	[Variable9] [varchar](40) NULL,
	[Variable10] [varchar](40) NULL,
	[TargetLabel] [varchar](32) NULL,
 CONSTRAINT [PK_RouteCallDetail] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RouteRecord]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RouteRecord](
	[RouteId] [bigint] NOT NULL,
	[UcdId] [bigint] NULL,
	[CallId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Route] [varchar](20) NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[RouteTo] [varchar](20) NULL,
	[DevType] [tinyint] NULL,
	[Result] [int] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[UEC] [varchar](50) NULL,
 CONSTRAINT [PK_RouteRecord] PRIMARY KEY CLUSTERED 
(
	[RouteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[rt_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[rt_agent](
	[Agent] [char](20) NOT NULL,
	[Device] [char](20) NOT NULL,
	[Skills] [varchar](50) NULL,
	[LogFlag] [tinyint] NOT NULL,
	[FlagTime] [datetime] NOT NULL,
	[Cause] [smallint] NOT NULL,
	[LogId] [bigint] NULL,
	[SubId] [smallint] NULL,
	[LogTime] [datetime] NOT NULL,
	[FirstLogin] [datetime] NULL,
	[LastLogout] [datetime] NULL,
	[LastLogin] [datetime] NULL,
	[LastReady] [datetime] NULL,
	[LastNotReady] [datetime] NULL,
	[LastAcw] [datetime] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_rt_agent] PRIMARY KEY CLUSTERED 
(
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[rt_device]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[rt_device](
	[Device] [char](20) NOT NULL,
	[Agent] [char](20) NULL,
	[Skills] [varchar](50) NULL,
	[FlagTime] [datetime] NOT NULL,
	[DevFlag] [tinyint] NOT NULL,
	[AgentFlag] [tinyint] NOT NULL,
	[Cause] [smallint] NOT NULL,
	[LogId_d] [bigint] NULL,
	[LogTime_d] [datetime] NULL,
	[LogId_a] [bigint] NULL,
	[LogTime_a] [datetime] NULL,
	[SubId] [smallint] NULL,
	[UcdId] [bigint] NULL,
	[CallId] [int] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_rt_device] PRIMARY KEY CLUSTERED 
(
	[Device] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SkillLog]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SkillLog](
	[LogID] [bigint] NOT NULL,
	[Skill] [char](20) NOT NULL,
 CONSTRAINT [PK_SkillLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC,
	[Skill] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_agent](
	[RecDT] [bigint] NOT NULL,
	[Agent] [char](20) NOT NULL,
	[Period] [smallint] NOT NULL,
	[Skills] [varchar](100) NULL,
	[PrjID] [int] NULL,
	[Login_t] [int] NULL,
	[Ready_t] [int] NULL,
	[Talk_t] [int] NULL,
	[Acw_t] [int] NULL,
	[Idle_t] [int] NULL,
	[Login_n] [int] NULL,
	[Ready_n] [int] NULL,
	[Acw_n] [int] NULL,
	[LoginTime] [datetime] NULL,
	[LogoutTime] [datetime] NULL,
	[NotReady00_n] [int] NULL,
	[NotReady01_n] [int] NULL,
	[NotReady02_n] [int] NULL,
	[NotReady03_n] [int] NULL,
	[NotReady04_n] [int] NULL,
	[NotReady05_n] [int] NULL,
	[NotReady06_n] [int] NULL,
	[NotReady07_n] [int] NULL,
	[NotReady08_n] [int] NULL,
	[NotReady09_n] [int] NULL,
	[NotReady00_t] [int] NULL,
	[NotReady01_t] [int] NULL,
	[NotReady02_t] [int] NULL,
	[NotReady03_t] [int] NULL,
	[NotReady04_t] [int] NULL,
	[NotReady05_t] [int] NULL,
	[NotReady06_t] [int] NULL,
	[NotReady07_t] [int] NULL,
	[NotReady08_t] [int] NULL,
	[NotReady09_t] [int] NULL,
	[Logout00_n] [int] NULL,
	[Logout01_n] [int] NULL,
	[Logout02_n] [int] NULL,
	[Logout03_n] [int] NULL,
	[Logout04_n] [int] NULL,
	[Logout05_n] [int] NULL,
	[Logout06_n] [int] NULL,
	[Logout07_n] [int] NULL,
	[Logout08_n] [int] NULL,
	[Logout09_n] [int] NULL,
	[Logout00_t]  AS (((((((((([Period]*(60000)-[Login_t])-[Logout01_t])-[Logout02_t])-[Logout03_t])-[Logout04_t])-[Logout05_t])-[Logout06_t])-[Logout07_t])-[Logout08_t])-[Logout09_t]) PERSISTED,
	[Logout01_t] [int] NULL,
	[Logout02_t] [int] NULL,
	[Logout03_t] [int] NULL,
	[Logout04_t] [int] NULL,
	[Logout05_t] [int] NULL,
	[Logout06_t] [int] NULL,
	[Logout07_t] [int] NULL,
	[Logout08_t] [int] NULL,
	[Logout09_t] [int] NULL,
 CONSTRAINT [PK_stat_agent] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_call]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stat_call](
	[RecDT] [bigint] NOT NULL,
	[TimeSpan] [int] NOT NULL,
	[RingTm] [int] NULL,
	[PBXIncNum] [int] NULL,
	[PBXOtgNum] [int] NULL,
	[TotalNum] [int] NULL,
	[TotalTm] [int] NULL,
	[IncNum] [int] NULL,
	[IncTm] [int] NULL,
	[OtgNum] [int] NULL,
	[OtgTm] [int] NULL,
	[InsNum] [int] NULL,
	[InsTm] [int] NULL,
	[AnsNum] [int] NULL,
	[AnsLessNum] [int] NULL,
	[AnsMoreNum] [int] NULL,
	[ConNum] [int] NULL,
	[TrsNum] [int] NULL,
	[AbanNum] [int] NULL,
	[AbanLessNum] [int] NULL,
	[AbanMoreNum] [int] NULL,
	[AbanTm] [int] NULL,
	[MaxWaitTm] [int] NULL,
	[AnsTm] [int] NULL,
	[WorkTm] [int] NULL,
	[AbanQueueNum] [int] NULL,
	[AbanAgentNum] [int] NULL,
 CONSTRAINT [PK_stat_call] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[stat_call_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_call_agent](
	[RecDT] [bigint] NOT NULL,
	[Agent] [char](20) NOT NULL,
	[Period] [smallint] NOT NULL,
	[PrjID] [int] NULL,
	[Total_n] [int] NULL,
	[Total_t] [int] NULL,
	[Skill_n] [int] NULL,
	[Skill_t] [int] NULL,
	[Ans_n] [int] NULL,
	[Ans_t] [int] NULL,
	[MaxAns_t] [int] NULL,
	[AnsLess_n] [int] NULL,
	[AnsMore_n] [int] NULL,
	[Aban_n] [int] NULL,
	[Aban_t] [int] NULL,
	[Loss_n] [int] NULL,
	[AbanLess] [int] NULL,
	[AbanMore] [int] NULL,
	[Talk_n] [int] NULL,
	[Talk_t] [int] NULL,
	[InTalk_n] [int] NULL,
	[InTalk_t] [int] NULL,
	[OutTalk_n] [int] NULL,
	[OutTalk_t] [int] NULL,
	[Hold_n] [int] NULL,
	[Hold_t] [int] NULL,
	[Acw_t] [int] NULL,
	[Handle_t] [int] NULL,
	[WaitLess_n] [int] NULL,
	[WaitMore_n] [int] NULL,
	[Trans_n] [int] NULL,
	[Conf_n] [int] NULL,
	[Trunk_n] [int] NULL,
	[Trunk_t] [int] NULL,
	[TrunkIn_n] [int] NULL,
	[TrunkIn_t] [int] NULL,
	[TrunkInAns_n] [int] NULL,
	[TrunkInAns_t] [int] NULL,
	[TrunkOut_n] [int] NULL,
	[TrunkOut_t] [int] NULL,
	[TrunkOutAns_n] [int] NULL,
	[TrunkOutAns_t] [int] NULL,
	[TalkLess10_n] [int] NULL,
	[TalkLess20_n] [int] NULL,
	[TalkMore20_n] [int] NULL,
	[Inner_n] [int] NULL,
	[Inner_t] [int] NULL,
	[ExtIn_n] [int] NULL,
	[ExtIn_t] [int] NULL,
	[ExtInner_n] [int] NULL,
	[ExtInner_t] [int] NULL,
	[Ring_t] [int] NULL,
 CONSTRAINT [PK_stat_call_agent] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_call_ext]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_call_ext](
	[RecDT] [bigint] NOT NULL,
	[Ext] [char](20) NOT NULL,
	[TimeSpan] [int] NULL,
	[RingTm] [int] NULL,
	[PBXIncNum] [int] NULL,
	[PBXOtgNum] [int] NULL,
	[TotalNum] [int] NULL,
	[TotalTm] [int] NULL,
	[IncNum] [int] NULL,
	[IncTm] [int] NULL,
	[OtgNum] [int] NULL,
	[OtgTm] [int] NULL,
	[InsNum] [int] NULL,
	[InsTm] [int] NULL,
	[AnsNum] [int] NULL,
	[AnsLessNum] [int] NULL,
	[AnsMoreNum] [int] NULL,
	[ConNum] [int] NULL,
	[TrsNum] [int] NULL,
	[AbanNum] [int] NULL,
	[AbanLessNum] [int] NULL,
	[AbanMoreNum] [int] NULL,
	[AbanTm] [int] NULL,
	[MaxWaitTm] [int] NULL,
	[AnsTm] [int] NULL,
	[WorkTm] [int] NULL,
	[AbanQueueNum] [int] NULL,
	[AbanAgentNum] [int] NULL,
 CONSTRAINT [PK_stat_call_ext] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Ext] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_call_skill]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_call_skill](
	[RecDT] [bigint] NOT NULL,
	[Skill] [char](20) NOT NULL,
	[Period] [smallint] NOT NULL,
	[PrjID] [int] NULL,
	[Skill_n] [int] NULL,
	[Skill_t] [int] NULL,
	[SkillIn_n] [int] NULL,
	[SkillIn_t] [int] NULL,
	[AgentOut_n] [int] NULL,
	[AgentOut_t] [int] NULL,
	[Ans_n] [int] NULL,
	[Ans_t] [int] NULL,
	[MaxAns_t] [int] NULL,
	[Talk_t] [int] NULL,
	[AnsLess_n] [int] NULL,
	[AnsMore_n] [int] NULL,
	[Aban_n] [int] NULL,
	[Aban_t] [int] NULL,
	[Loss_n] [int] NULL,
	[AbanSkill] [int] NULL,
	[AbanAgent] [int] NULL,
	[AbanLess] [int] NULL,
	[AbanMore] [int] NULL,
	[Hold_n] [int] NULL,
	[Hold_t] [int] NULL,
	[Acw_t] [int] NULL,
	[Handle_t] [int] NULL,
	[Wait_t] [int] NULL,
	[WaitLess_n] [int] NULL,
	[WaitMore_n] [int] NULL,
	[Trans_n] [int] NULL,
	[Conf_n] [int] NULL,
	[Trunk_n] [int] NULL,
	[Trunk_t] [int] NULL,
	[TrunkIn_n] [int] NULL,
	[TrunkIn_t] [int] NULL,
	[TrunkInAns_n] [int] NULL,
	[TrunkInAns_t] [int] NULL,
	[TrunkOut_n] [int] NULL,
	[TrunkOut_t] [int] NULL,
	[TrunkOutAns_n] [int] NULL,
	[TrunkOutAns_t] [int] NULL,
	[Login_t] [int] NULL,
	[Ready_t] [int] NULL,
	[Work_t] [int] NULL,
	[Idle_t] [int] NULL,
	[Inner_n] [int] NULL,
	[Inner_t] [int] NULL,
 CONSTRAINT [PK_stat_call_skill] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Skill] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_call_skill_agent]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_call_skill_agent](
	[RecDT] [bigint] NOT NULL,
	[Skill] [char](20) NOT NULL,
	[Agent] [char](20) NOT NULL,
	[Ans_n] [int] NULL,
	[Aban_0_5_n] [int] NULL,
	[Aban_5_10_n] [int] NULL,
	[Aban_10_20_n] [int] NULL,
	[Aban_20_30_n] [int] NULL,
	[Aban_30_60_n] [int] NULL,
	[Aban_gt_60_n] [int] NULL,
	[Aban_t] [int] NULL,
 CONSTRAINT [PK_stat_call_skill_agent] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Skill] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_call_trunk]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stat_call_trunk](
	[RecDT] [bigint] NOT NULL,
	[GroupId] [int] NOT NULL,
	[Period] [smallint] NOT NULL,
	[Total_n] [int] NULL,
	[Total_t] [int] NULL,
	[TrunkIn_n] [int] NULL,
	[TrunkIn_t] [int] NULL,
	[TrunkInAns_n] [int] NULL,
	[TrunkInAns_t] [int] NULL,
	[TrunkOut_n] [int] NULL,
	[TrunkOut_t] [int] NULL,
	[TrunkOutAns_n] [int] NULL,
	[TrunkOutAns_t] [int] NULL,
	[TalkLess10_n] [int] NULL,
	[TalkLess20_n] [int] NULL,
	[TalkMore20_n] [int] NULL,
	[TrunkInAns_Skill_n] [int] NULL,
	[TrunkInAns_Agent_n] [int] NULL,
	[TrunkInAns_Ivr_n] [int] NULL,
 CONSTRAINT [PK_stat_call_trunk] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[stat_device]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_device](
	[RecDT] [bigint] NOT NULL,
	[Device] [char](20) NOT NULL,
	[Agent] [char](20) NOT NULL,
	[TimeSpan] [int] NOT NULL,
	[IdleTime] [int] NULL,
	[DialTime] [int] NULL,
	[RingTime] [int] NULL,
	[TalkTime] [int] NULL,
	[HoldTime] [int] NULL,
	[WorkTime] [int] NULL,
	[CallNum] [int] NULL,
	[InNum] [int] NULL,
	[OutNum] [int] NULL,
	[DialNum] [int] NULL,
	[RingNum] [int] NULL,
	[HoldNum] [int] NULL,
 CONSTRAINT [PK_stat_device] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Device] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_param]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_param](
	[key] [varchar](50) NOT NULL,
	[value] [varchar](50) NULL,
 CONSTRAINT [PK_stat_param] PRIMARY KEY CLUSTERED 
(
	[key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_route_to]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_route_to](
	[RecDT] [bigint] NOT NULL,
	[RouteTo] [varchar](20) NOT NULL,
	[Period] [smallint] NOT NULL,
	[TimeLen] [int] NULL,
	[RecCount] [int] NULL,
 CONSTRAINT [PK_stat_route_to] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[RouteTo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_route_type]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_route_type](
	[RecDT] [bigint] NOT NULL,
	[DevType] [tinyint] NOT NULL,
	[Route] [varchar](20) NOT NULL,
	[Period] [smallint] NOT NULL,
	[TimeLen] [int] NULL,
	[RecCount] [int] NULL,
 CONSTRAINT [PK_stat_route_type] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[DevType] ASC,
	[Route] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_skill]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_skill](
	[RecDT] [bigint] NOT NULL,
	[Skill] [char](20) NOT NULL,
	[TimeSpan] [int] NOT NULL,
	[AgentNum] [int] NULL,
	[LoginTime] [int] NULL,
	[ReadyTime] [int] NULL,
	[NotReadyTime] [int] NULL,
	[AcwTime] [int] NULL,
	[LogoutTime] [int] NULL,
	[NotReady01] [int] NULL,
	[NotReady02] [int] NULL,
	[NotReady03] [int] NULL,
	[NotReady04] [int] NULL,
	[NotReady05] [int] NULL,
	[NotReady06] [int] NULL,
	[NotReady07] [int] NULL,
	[NotReady08] [int] NULL,
	[NotReady09] [int] NULL,
	[Logout01] [int] NULL,
	[Logout02] [int] NULL,
	[Logout03] [int] NULL,
	[Logout04] [int] NULL,
	[Logout05] [int] NULL,
	[Logout06] [int] NULL,
	[Logout07] [int] NULL,
	[Logout08] [int] NULL,
	[Logout09] [int] NULL,
 CONSTRAINT [PK_stat_skill] PRIMARY KEY CLUSTERED 
(
	[RecDT] ASC,
	[Skill] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrunkRecord]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrunkRecord](
	[RecId] [bigint] NOT NULL,
	[UcdId] [bigint] NULL,
	[TrunkGroup] [smallint] NOT NULL,
	[TrunkNumber] [smallint] NOT NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Answer] [varchar](50) NULL,
	[Extension] [varchar](20) NULL,
	[Route] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[StartTime] [datetime] NOT NULL,
	[TimeLen] [int] NOT NULL,
	[Inbound] [bit] NOT NULL,
	[Outbound] [bit] NOT NULL,
	[Flag] [tinyint] NULL,
	[PrjId] [int] NULL,
	[UCID] [varchar](50) NULL,
 CONSTRAINT [PK_TrunkRecord] PRIMARY KEY CLUSTERED 
(
	[RecId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ucd]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Ucd](
	[UcdId] [bigint] NOT NULL,
	[UcdType] [tinyint] NULL,
	[ClientId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Answer] [varchar](50) NULL,
	[Route] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Trunk] [varchar](20) NULL,
	[StartTime] [datetime] NOT NULL,
	[TimeLen] [int] NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[Extension] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[UcdDate] [int] NULL,
	[UcdHour] [tinyint] NULL,
	[PrjId] [int] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[UcdTime] [int] NULL,
 CONSTRAINT [PK_Ucd] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UcdCall]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UcdCall](
	[UcdId] [bigint] NOT NULL,
	[SubId] [tinyint] NOT NULL,
	[CallId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Answer] [varchar](50) NULL,
	[Type] [tinyint] NOT NULL,
	[Agent] [varchar](20) NULL,
	[Extension] [varchar](20) NULL,
	[Route] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Trunk] [varchar](20) NULL,
	[CtrlDev] [varchar](20) NULL,
	[bRing] [bit] NULL,
	[bEstb] [bit] NULL,
	[bHold] [bit] NULL,
	[bRetv] [bit] NULL,
	[bTrans] [bit] NULL,
	[bConf] [bit] NULL,
	[bOverflow] [bit] NULL,
	[bAcw] [bit] NULL,
	[OnCallBegin] [int] NOT NULL,
	[OnRoute] [int] NULL,
	[OnSkill] [int] NULL,
	[OnRing] [int] NULL,
	[OnEstb] [int] NULL,
	[OnHold] [int] NULL,
	[OnRetv] [int] NULL,
	[OnTrans] [int] NULL,
	[OnConf] [int] NULL,
	[OnConfEnd] [int] NULL,
	[OnCallEnd] [int] NULL,
	[OnOverflow] [int] NULL,
	[OnAcwEnd] [int] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[CallLenInAcw] [int] NULL,
 CONSTRAINT [PK_UcdCall] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UcdEmail]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UcdEmail](
	[UcdID] [bigint] NOT NULL,
	[MailType] [tinyint] NULL,
	[MailFrom] [varchar](100) NULL,
	[MailTo] [varchar](1200) NULL,
	[MailCopy] [varchar](1200) NULL,
	[MailSubject] [varchar](300) NULL,
	[MailText] [text] NULL,
	[FtpID] [smallint] NULL,
	[MailFiles] [text] NULL,
	[PriorID] [bigint] NULL,
	[MailTime] [datetime] NULL,
	[Skill] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[bPush] [bit] NULL,
	[OnPush] [int] NULL,
	[bPopup] [bit] NULL,
	[OnPopup] [int] NULL,
	[bOpen] [bit] NULL,
	[OnOpen] [int] NULL,
	[bHold] [bit] NULL,
	[OnHold] [int] NULL,
	[bReopen] [bit] NULL,
	[OnReopen] [int] NULL,
	[bTrans] [bit] NULL,
	[OnTrans] [int] NULL,
	[TransTo] [varchar](100) NULL,
	[bSend] [bit] NULL,
	[OnSend] [int] NULL,
	[OnEnd] [int] NULL,
	[PrjID] [int] NULL,
	[ActFlag] [int] NULL,
	[Labeled] [bit] NULL,
 CONSTRAINT [PK_UcdEmail] PRIMARY KEY CLUSTERED 
(
	[UcdID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UcdItem]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UcdItem](
	[UcdId] [bigint] NOT NULL,
	[PartyId] [tinyint] NOT NULL,
	[Device] [varchar](20) NULL,
	[Phone] [varchar](50) NULL,
	[Agent] [varchar](20) NULL,
	[bRing] [bit] NULL,
	[bEstb] [bit] NULL,
	[Enter] [int] NOT NULL,
	[Establish] [int] NULL,
	[Leave] [int] NOT NULL,
	[AcwEnd] [int] NULL,
 CONSTRAINT [PK_UcdItem] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC,
	[PartyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VipUsers]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VipUsers](
	[PhoneNo] [varchar](100) NOT NULL,
	[UserName] [varchar](100) NULL,
	[Level] [smallint] NULL,
	[bPermanent] [bit] NULL,
	[CreateDate] [int] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_VipUsers] PRIMARY KEY CLUSTERED 
(
	[PhoneNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[DevLog]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[DevLog](
	[LogId] [bigint] NOT NULL,
	[Device] [varchar](20) NOT NULL,
	[AgentLogId] [bigint] NOT NULL,
	[OldFlag] [tinyint] NULL,
	[DevFlag] [tinyint] NOT NULL,
	[UcdId] [bigint] NULL,
	[CallId] [int] NULL,
	[BegTime] [datetime] NOT NULL,
	[TimeLen] [int] NOT NULL,
	[Finished] [bit] NULL,
	[EndTime] [datetime] NULL,
 CONSTRAINT [PK_DevLog] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[Login]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[Login](
	[LogID] [bigint] NOT NULL,
	[Agent] [char](20) NOT NULL,
	[Device] [char](20) NOT NULL,
	[Skills] [varchar](50) NULL,
	[Finish] [bit] NULL,
	[Flag] [tinyint] NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[EndTime] [datetime] NULL,
	[ReadyLen] [int] NULL,
	[AcwLen] [int] NULL,
	[cause] [tinyint] NULL,
	[BegRecTime] [int] NULL,
	[EndRecTime] [int] NULL,
 CONSTRAINT [PK_Login] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[Ready]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [hist].[Ready](
	[LogID] [bigint] NOT NULL,
	[SubID] [smallint] NOT NULL,
	[Finish] [bit] NULL,
	[Flag] [tinyint] NULL,
	[StartTime] [int] NULL,
	[TimeLen] [int] NULL,
	[cause] [tinyint] NULL,
 CONSTRAINT [PK_Ready] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC,
	[SubID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [hist].[Ucd]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[Ucd](
	[UcdId] [bigint] NOT NULL,
	[UcdType] [tinyint] NULL,
	[ClientId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Answer] [varchar](50) NULL,
	[Route] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Trunk] [varchar](20) NULL,
	[StartTime] [datetime] NOT NULL,
	[TimeLen] [int] NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[Extension] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[UcdDate] [int] NULL,
	[UcdHour] [tinyint] NULL,
	[PrjId] [int] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[UcdTime] [int] NULL,
 CONSTRAINT [PK_Ucd] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[UcdCall]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[UcdCall](
	[UcdId] [bigint] NOT NULL,
	[SubId] [tinyint] NOT NULL,
	[CallId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Answer] [varchar](50) NULL,
	[Type] [tinyint] NOT NULL,
	[Agent] [varchar](20) NULL,
	[Extension] [varchar](20) NULL,
	[Route] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Trunk] [varchar](20) NULL,
	[CtrlDev] [varchar](20) NULL,
	[bRing] [bit] NULL,
	[bEstb] [bit] NULL,
	[bHold] [bit] NULL,
	[bRetv] [bit] NULL,
	[bTrans] [bit] NULL,
	[bConf] [bit] NULL,
	[bOverflow] [bit] NULL,
	[bAcw] [bit] NULL,
	[OnCallBegin] [int] NOT NULL,
	[OnRoute] [int] NULL,
	[OnSkill] [int] NULL,
	[OnRing] [int] NULL,
	[OnEstb] [int] NULL,
	[OnHold] [int] NULL,
	[OnRetv] [int] NULL,
	[OnTrans] [int] NULL,
	[OnConf] [int] NULL,
	[OnConfEnd] [int] NULL,
	[OnCallEnd] [int] NULL,
	[OnOverflow] [int] NULL,
	[OnAcwEnd] [int] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[CallLenInAcw] [int] NULL,
 CONSTRAINT [PK_UcdCall] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[UcdItem]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[UcdItem](
	[UcdId] [bigint] NOT NULL,
	[PartyId] [tinyint] NOT NULL,
	[Device] [varchar](20) NULL,
	[Phone] [varchar](50) NULL,
	[Agent] [varchar](20) NULL,
	[bRing] [bit] NULL,
	[bEstb] [bit] NULL,
	[Enter] [int] NOT NULL,
	[Establish] [int] NULL,
	[Leave] [int] NOT NULL,
	[AcwEnd] [int] NULL,
 CONSTRAINT [PK_UcdItem] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC,
	[PartyId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[agentlog_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[agentlog_view]
AS
SELECT     TOP (100) PERCENT LogID, Agent, Device, Skills, Status, StartTime, CASE TimeLen WHEN 0 THEN NULL ELSE DATEADD(ms, TimeLen, StartTime) 
                      END AS EndTime, TimeLen
FROM         dbo.AgentLog
ORDER BY LogID

GO
/****** Object:  View [dbo].[devlog_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[devlog_view]
AS
SELECT     dbo.DevLog.LogId, dbo.DevLog.Device, dbo.DevLog.AgentLogId, dbo.Login.Agent, dbo.Login.Skills, dbo.DevLog.DevFlag, dbo.DevLog.BegTime, 
                      dbo.DevLog.TimeLen, dbo.DevLog.Finished, dbo.DevLog.EndTime
FROM         dbo.DevLog LEFT OUTER JOIN
                      dbo.Login ON dbo.DevLog.AgentLogId = dbo.Login.LogID

GO
/****** Object:  View [dbo].[ready_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[ready_view]
AS
SELECT     TOP (100) PERCENT dbo.Ready.LogID, dbo.Ready.SubID, dbo.Ready.StartTime, dbo.Ready.TimeLen, dbo.Ready.cause, dbo.Ready.Flag, dbo.Ready.Finish, 
                      dbo.Login.StartTime AS BegTime, dbo.Login.Agent, dbo.Login.Device, dbo.Login.Skills, DATEADD(ms, dbo.Ready.StartTime + dbo.Ready.TimeLen, 
                      dbo.Login.StartTime) AS EndTime
FROM         dbo.Login INNER JOIN
                      dbo.Ready ON dbo.Login.LogID = dbo.Ready.LogID
ORDER BY dbo.Ready.LogID, dbo.Ready.SubID


GO
/****** Object:  View [dbo].[rt_agent_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[rt_agent_view]
AS
SELECT     Agent, Device, Skills, LogFlag, FlagTime, Cause, Enabled
FROM         dbo.rt_agent

GO
/****** Object:  View [dbo].[rt_device_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[rt_device_view]
AS
SELECT     Device, Agent, Skills, FlagTime, DevFlag, AgentFlag, Cause, Enabled
FROM         dbo.rt_device

GO
/****** Object:  View [dbo].[ucdcall_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ucdcall_view]
AS
SELECT     c.UcdId, c.SubId, c.CallId, c.Calling, c.Called, c.Answer, c.Type, c.Agent, c.Extension, c.Route, c.Skill, c.Trunk, c.CtrlDev, c.bRing, c.bEstb, c.bHold, c.bRetv, c.bTrans, 
                      c.bConf, c.bOverflow, c.bAcw, c.OnCallBegin, c.OnRoute, c.OnSkill, c.OnRing, c.OnEstb, c.OnHold, c.OnRetv, c.OnTrans, c.OnConf, c.OnConfEnd, c.OnCallEnd, 
                      c.OnOverflow, c.OnAcwEnd, c.UCID, c.UUI, u.StartTime, DATEADD(ms, c.OnCallEnd, u.StartTime) AS EndTime
FROM         dbo.Ucd AS u INNER JOIN
                      dbo.UcdCall AS c ON u.UcdId = c.UcdId

GO
/****** Object:  View [dbo].[ucditem_view]    Script Date: 2016/9/5 13:29:41 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[ucditem_view]
AS
SELECT i.UcdId, min(i.PartyId) as PartyId, i.Device, i.Phone, i.Agent, u.StartTime, 
	max(case i.bRing when 1 then 1 else 0 end) as bRing, 
	max(case i.bEstb when 1 then 1 else 0 end) as bEstb, MIN(i.Enter) AS enter, 
      MIN(i.Establish) AS establish, MAX(i.Leave) AS leave,
	sum(case i.bEstb when 1 then i.establish else i.leave end - i.enter) as RingMS,
	sum(case i.bEstb when 1 then i.leave - i.establish else 0 end) as TalkMS
FROM dbo.Ucd u INNER JOIN
      dbo.UcdItem i ON u.UcdId = i.UcdId
GROUP BY i.UcdId, i.Device, i.Phone, i.Agent, u.StartTime

GO
ALTER TABLE [dbo].[DevLog] ADD  CONSTRAINT [DF_DevLog_AgentLogId]  DEFAULT ((0)) FOR [AgentLogId]
GO
ALTER TABLE [dbo].[DevLog] ADD  CONSTRAINT [DF_DevLog_BegTime]  DEFAULT (getdate()) FOR [BegTime]
GO
ALTER TABLE [dbo].[DevLog] ADD  CONSTRAINT [DF_DevLog_TimeLen]  DEFAULT ((0)) FOR [TimeLen]
GO
ALTER TABLE [dbo].[Login] ADD  CONSTRAINT [DF_Login_cause]  DEFAULT ((-1)) FOR [cause]
GO
ALTER TABLE [dbo].[Login] ADD  CONSTRAINT [DF__Login__RecTime__5649C92D]  DEFAULT (NULL) FOR [BegRecTime]
GO
ALTER TABLE [dbo].[Login] ADD  CONSTRAINT [DF__Login__EndRecTim__573DED66]  DEFAULT (NULL) FOR [EndRecTime]
GO
ALTER TABLE [dbo].[Ready] ADD  CONSTRAINT [DF_Ready_cause]  DEFAULT ((-1)) FOR [cause]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_LogFlag]  DEFAULT ((0)) FOR [LogFlag]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_FlagTime]  DEFAULT (getdate()) FOR [FlagTime]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_Cause]  DEFAULT ((-1)) FOR [Cause]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_LoginTime]  DEFAULT (getdate()) FOR [LogTime]
GO
ALTER TABLE [dbo].[rt_device] ADD  CONSTRAINT [DF_rt_device_FlagTime]  DEFAULT (getdate()) FOR [FlagTime]
GO
ALTER TABLE [dbo].[rt_device] ADD  CONSTRAINT [DF_rt_device_DevFlag]  DEFAULT ((0)) FOR [DevFlag]
GO
ALTER TABLE [dbo].[rt_device] ADD  CONSTRAINT [DF_rt_device_AgentFlag]  DEFAULT ((0)) FOR [AgentFlag]
GO
ALTER TABLE [dbo].[rt_device] ADD  CONSTRAINT [DF_rt_device_Cause]  DEFAULT ((-1)) FOR [Cause]
GO
ALTER TABLE [dbo].[rt_device] ADD  CONSTRAINT [DF_rt_device_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[TrunkRecord] ADD  CONSTRAINT [DF_TrunkRecord_Inbound]  DEFAULT ((0)) FOR [Inbound]
GO
ALTER TABLE [dbo].[TrunkRecord] ADD  CONSTRAINT [DF_TrunkRecord_Outbound]  DEFAULT ((0)) FOR [Outbound]
GO
ALTER TABLE [dbo].[Ucd] ADD  CONSTRAINT [DF_Ucd_UcdType]  DEFAULT ((1)) FOR [UcdType]
GO
ALTER TABLE [dbo].[Ucd] ADD  DEFAULT (NULL) FOR [UcdTime]
GO
ALTER TABLE [dbo].[VipUsers] ADD  CONSTRAINT [DF_VipUsers_bPermanent]  DEFAULT ((0)) FOR [bPermanent]
GO
ALTER TABLE [dbo].[VipUsers] ADD  CONSTRAINT [DF_VipUsers_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[UcdCall]  WITH CHECK ADD  CONSTRAINT [FK_UcdCall_Ucd] FOREIGN KEY([UcdId])
REFERENCES [dbo].[Ucd] ([UcdId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UcdCall] CHECK CONSTRAINT [FK_UcdCall_Ucd]
GO
ALTER TABLE [dbo].[UcdEmail]  WITH CHECK ADD  CONSTRAINT [FK_UcdEmail_Ucd] FOREIGN KEY([UcdID])
REFERENCES [dbo].[Ucd] ([UcdId])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[UcdEmail] CHECK CONSTRAINT [FK_UcdEmail_Ucd]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'统一联络数据单元' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'UcdId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'原始主叫号码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'Calling'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'原始被叫号码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'Called'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'原始应答号码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'Answer'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'原始呼入的路由点' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'Route'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'原始呼入的技能组' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'Skill'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'联络起始时间' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'StartTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'联络过程时长：单元位' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Ucd', @level2type=N'COLUMN',@level2name=N'TimeLen'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'creating time' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'UcdCall', @level2type=N'COLUMN',@level2name=N'OnCallBegin'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "AgentLog"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 168
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'agentlog_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'agentlog_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "DevLog"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 243
               Right = 174
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Login"
            Begin Extent = 
               Top = 6
               Left = 257
               Bottom = 250
               Right = 342
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'devlog_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'devlog_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "Login"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 235
               Right = 168
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "Ready"
            Begin Extent = 
               Top = 6
               Left = 206
               Bottom = 240
               Right = 336
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ready_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ready_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "rt_agent"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 304
               Right = 301
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'rt_agent_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'rt_agent_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "rt_device"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 307
               Right = 262
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'rt_device_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'rt_device_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "u"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 177
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 6
               Left = 215
               Bottom = 125
               Right = 362
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ucdcall_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'ucdcall_view'
GO
