USE [master]
GO
CREATE DATABASE [vxi_sys]
GO

USE [vxi_sys]
GO
/****** Object:  DatabaseRole [ba]    Script Date: 2016/9/5 9:38:57 ******/
CREATE ROLE [ba]
GO
/****** Object:  StoredProcedure [dbo].[func_today]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[func_today]
AS
  declare @date int, @year int, @month int, @day int, @today datetime
  select @today = getdate()
  select @year = datepart(year, @today), @month = datepart(month, @today), @day = datepart(day, @today)
  select @date = @year * 10000 + @month * 100 + @day
  return @date
GO
/****** Object:  StoredProcedure [dbo].[sp_chtype_setup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_chtype_setup] AS

if exists(select * from syscolumns where id = object_id('VXI_SYS..CHTYPE') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_SYS..CHTYPE ON

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (1, 'IVR')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (2, 'VRS')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (4, 'PDS')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (16, 'IVR')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (17, 'IVR-Trunk')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (18, 'IVR-Conf')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (19, 'IVR-Ext')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (20, 'IVR-IP')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (32, 'VRS')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (33, 'VRS-Trunk')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (34, 'VRS-Conf')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (35, 'VRS-Ext')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (36, 'VRS-IP')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (64, 'PDS')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (65, 'PDS-Trunk')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (66, 'PDS-Conf')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (67, 'PDS-Ext')

Insert into VXI_SYS..CHTYPE ([ChType], [TypeName]) 
Values (68, 'PDS-IP')

if exists(select * from syscolumns where id = object_id('VXI_SYS..CHTYPE') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_SYS..CHTYPE OFF


GO
/****** Object:  StoredProcedure [dbo].[sp_database_link_init]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================================================================================
-- Author:		WuYiBin
-- Create date: 2008.12.4
-- Description:	数据库连接的建立
-- Example: sp_database_link_init @host='192.168.0.100',@LinkName='test1_link',@loguser='aa',@logpass='aa',@dbtype=1
-- ===============================================================================================================
CREATE PROCEDURE [dbo].[sp_database_link_init]
	@Host		varchar(20),				-- 主机ip地址或主机名
	@LinkName	varchar(20) = 'link_cms',	-- 数据库链接名
	@LogUser	varchar(20) = '',			-- 登陆用户名
	@LogPass    varchar(20) = '',			-- 登陆密码
	@DbType     tinyint = 1					-- 数据库类型
											--[SqlServer:1;	Oracle:2]
AS
begin try
	declare @ExSql varchar(4000), @Error int
	set @Error = 0
	
	IF exists(SELECT srv.name FROM sys.servers srv WHERE srv.server_id != 0 AND srv.name = @LinkName) 
		EXEC master.dbo.sp_dropserver @server=@LinkName, @droplogins='droplogins'

	set @ExSql = case @DbType
						when 1 then 'exec sp_addlinkedserver '''+ @LinkName 
							+ ''','''',''SQLOLEDB'','''+@Host+''''
						when 2 then 'exec sp_addlinkedserver '''+ @LinkName 
							+ ''',''Oracle'',''MSDAORA'','''+@Host+''''
					end
	print @ExSql
	exec(@ExSql)

	set @ExSql = case @DbType
						when 1 then 'exec sp_addlinkedsrvlogin '''+ @LinkName 
							+''',''false'',null,'''+@LogUser+''','''+@LogPass+''''
						when 2 then 'exec sp_addlinkedsrvlogin '''+ @LinkName 
							+''',false,''sa'','''+@LogUser+''','''+@LogPass+''''
					end
	print @ExSql
	exec(@ExSql)

	select @LinkName DbLink
	return @Error

end try
begin catch
	set @Error = -1
	print '[sp_database_link_init](数据库链接创建失败！)'
	return @Error
end catch

GO
/****** Object:  StoredProcedure [dbo].[sp_devtype_setup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_devtype_setup]
AS

	delete from vxi_sys..devtype

	if exists(select * from syscolumns where id = object_id('VXI_SYS..DEVTYPE') and (not (autoval is null)))
		SET IDENTITY_INSERT VXI_SYS..DEVTYPE ON

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (2, 'Agent')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (18, 'Agent Group')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (7, 'Audio')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (1, 'Extension')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (17, 'Extension Group')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (6, 'External')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (4, 'Route')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (3, 'Skill')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (5, 'Trunk')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (19, 'Trunk Group')

	Insert into VXI_SYS..DEVTYPE ([DevType], [TypeName]) 
	Values (0, 'Unknown')

	if exists(select * from syscolumns where id = object_id('VXI_SYS..DEVTYPE') and (not (autoval is null)))
		SET IDENTITY_INSERT VXI_SYS..DEVTYPE OFF





GO
/****** Object:  StoredProcedure [dbo].[sp_get_agents]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_get_agents]
	@groupid smallint = 0
AS
	if isnull(@groupid, 0) = 0 begin
		select * from agent where enabled = 1 order by groupid, agent
	end
	else begin
		select * from agent where groupid = @groupid and enabled = 1 order by agent
	end
GO
/****** Object:  StoredProcedure [dbo].[sp_get_InsertSql]    Script Date: 2016/9/5 9:38:57 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_grouptype_setup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_grouptype_setup] 
AS

if exists(select * from syscolumns where id = object_id('VXI_SYS..GROUPTYPE') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_SYS..GROUPTYPE ON

Insert into VXI_SYS..GROUPTYPE ([GroupType], [TypeName]) 
Values (0, 'Unknown')

Insert into VXI_SYS..GROUPTYPE ([GroupType], [TypeName]) 
Values (1, 'Agent Group')

Insert into VXI_SYS..GROUPTYPE ([GroupType], [TypeName]) 
Values (2, 'Extension Group')

Insert into VXI_SYS..GROUPTYPE ([GroupType], [TypeName]) 
Values (3, 'Channel Group')

Insert into VXI_SYS..GROUPTYPE ([GroupType], [TypeName]) 
Values (4, 'Trunk Group')

Insert into VXI_SYS..GROUPTYPE ([GroupType], [TypeName]) 
Values (5, 'Station Group')

if exists(select * from syscolumns where id = object_id('VXI_SYS..GROUPTYPE') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_SYS..GROUPTYPE OFF





GO
/****** Object:  StoredProcedure [dbo].[sp_prjitem_type_setup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[sp_prjitem_type_setup]
AS

if exists(select * from syscolumns where id = object_id('VXI_SYS..PRJITEMTYPE') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_SYS..PRJITEMTYPE ON

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (1, 'Agent')

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (2, 'Extension')

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (3, 'Skill')

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (4, 'Route')

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (5, 'Trunk Group')

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (6, 'Calling No.')

Insert into VXI_SYS..PRJITEMTYPE ([Type], [TypeName]) 
Values (7, 'Called No.')

if exists(select * from syscolumns where id = object_id('VXI_SYS..PRJITEMTYPE') and (not (autoval is null)))
	SET IDENTITY_INSERT VXI_SYS..PRJITEMTYPE OFF




GO
/****** Object:  StoredProcedure [dbo].[sp_voicetype_setup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_voicetype_setup]  AS
	delete from VXI_SYS..VOICETYPE

	if exists(select * from syscolumns where id = object_id('VXI_SYS..VOICETYPE') and (not (autoval is null)))
		SET IDENTITY_INSERT VXI_SYS..VOICETYPE ON

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (1, 'VCE', 'vce', 16, 0, 'VCE File, .vce', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (2, 'VOX', 'vox', 16, 0, 'VOX File, .vox', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (3, 'MP3', 'mp3', 8, 0, 'MP3 File, mp3', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (4, 'WAV', 'wav', 8, 0, 'WAV File, .wav', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (5, 'G729A', 'g729a', 16, 4, 'G729A File, .g729a', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (6, 'VXI', 'vxi', 16, 4, 'VXI Compress File, .vxi', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (7, 'g711u', 'g711', 8, 0, 'G711U  File, .g711', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (8, 'alaw', 'alaw', 8, 0, 'ALAW  File, .alaw', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (9, 'g723', 'g723', 16, 0, 'G723 File, .g723', 1)

	Insert into VXI_SYS..VOICETYPE ([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) 
	Values (10, 'g726', 'g726', 16, 0, 'G726 File, .g726', 1)

	if exists(select * from syscolumns where id = object_id('VXI_SYS..VOICETYPE') and (not (autoval is null)))
		SET IDENTITY_INSERT VXI_SYS..VOICETYPE OFF






GO
/****** Object:  StoredProcedure [dbo].[usp_agent_insert]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_agent_insert]  
	@AgentID varchar(20),
	@AgentName varchar(50),  
	@Enabled bit = 1  
AS  
	if @AgentID is null return
	set @AgentID = rtrim(ltrim(@AgentID));
	if (select count(*) from Agent where Agent = @AgentID) = 0 begin  
		insert into Agent (Agent, AgentName, Enabled)  
		values (@AgentID, @AgentName, @Enabled)  
		select 1, 'result' 
	end  
	else begin  
		select 0, 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_get_agent]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_agent]  
	@AgentID varchar(20) = null,  
	@Enabled bit = 1  
AS  
	if @AgentID is null or @AgentID = '0' or @AgentID='' 
		set @AgentID = null 
	select a.* from Agent a 
		where Agent = isnull(@AgentID, Agent)  
		and Enabled = isnull(@Enabled, Enabled)  
	order by a.agent
	select @@rowcount counts
GO
/****** Object:  StoredProcedure [dbo].[usp_get_agentgroupbyagentid]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[usp_get_agentgroupbyagentid]  
	@AgentId varchar(50)
AS  
	begin  
		select * from Groups where GroupId in (select GroupId from AgentGroup  
		where Agent = @AgentId )
	end  
	select @@rowcount counts





GO
/****** Object:  StoredProcedure [dbo].[usp_get_agentgroupbyname]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE PROCEDURE [dbo].[usp_get_agentgroupbyname]  
	@GroupName varchar(50)  
AS  
	begin  
		select * from groups  
		where charindex(',' + GroupName + ',', ',' + @GroupName + ',') > 0
		 order by  groupname 
	end  
	select @@rowcount counts
GO
/****** Object:  StoredProcedure [dbo].[usp_get_groupagent]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_groupagent] 
	@GroupID int = 0,  
	@AgentID varchar(20) = ''  
AS  
	if (@GroupID=0 and @AgentID='') begin 
		select distinct groupid, agent  from AgentGroup order by groupid, agent 
	end 
	else if @GroupID=0 begin  
		select a.groupid, b.groupname, a.* from AgentGroup a, Groups b  
		where a.Agent = @AgentID and b.GroupID= a.GroupID  
		order by b.groupname 
	end  
	else begin  
		select * from AgentGroup a, Agent b  
		where a.GroupID = @GroupID and b.Agent= a.Agent  
		order by b.agent 
	end  
	select @@rowcount counts

GO
/****** Object:  StoredProcedure [dbo].[usp_groupagent_delete]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_groupagent_delete]  
	@GroupID int = 0,  
	@AgentID varchar(20) = null  
AS  
	if  @GroupID=0  
		delete AgentGroup  where Agent = @AgentID  
	else  
		delete AgentGroup where GroupID = @GroupID  
	return


GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_time]    Script Date: 2016/9/5 9:38:57 ******/
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
/****** Object:  Table [dbo].[Agent]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Agent](
	[Agent] [char](20) NOT NULL,
	[AgentName] [varchar](50) NOT NULL,
	[SortId] [int] NULL,
	[ProjectId] [int] NULL,
	[Passwd] [varchar](20) NULL,
	[PrimarySkill] [varchar](20) NULL,
	[GroupId] [smallint] NULL,
	[SkillGroup] [int] NULL,
	[Post] [tinyint] NULL,
	[RegDate] [datetime] NULL,
	[UnregDate] [datetime] NULL,
	[State] [tinyint] NOT NULL,
	[Validity] [int] NULL,
	[SiteId] [smallint] NULL,
	[EmpId] [int] NULL,
	[Enabled] [bit] NULL,
	[LoginSystem] [bit] NULL,
        [TrsName] [varchar](50) NULL,
 CONSTRAINT [PK_Agent] PRIMARY KEY CLUSTERED 
(
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AgentGroup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AgentGroup](
	[GroupId] [smallint] NOT NULL,
	[Agent] [char](20) NOT NULL,
 CONSTRAINT [PK_AgentGroup] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Aux]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Aux](
	[ProjectId] [int] NOT NULL,
	[Cause] [tinyint] NOT NULL,
	[Description] [varchar](200) NULL,
	[LogFlag] [bit] NULL,
 CONSTRAINT [PK_Aux] PRIMARY KEY CLUSTERED 
(
	[ProjectId] ASC,
	[Cause] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CallType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CallType](
	[App_Input] [varchar](50) NOT NULL,
	[CallType] [varchar](20) NOT NULL,
	[CallTypeDesc] [varchar](50) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_CallType] PRIMARY KEY CLUSTERED 
(
	[App_Input] ASC,
	[CallType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Channels]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Channels](
	[Channel] [char](20) NOT NULL,
	[Station] [char](20) NOT NULL,
	[SortId] [int] NULL,
	[DevName] [varchar](50) NULL,
	[PortNo] [smallint] NULL,
	[ChType] [tinyint] NOT NULL,
	[VoiceType] [tinyint] NULL,
	[AutoMon] [bit] NULL,
	[Mapped] [bit] NULL,
	[MaxCalls] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Channels] PRIMARY KEY CLUSTERED 
(
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ChType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ChType](
	[ChType] [tinyint] NOT NULL,
	[TypeName] [char](20) NOT NULL,
 CONSTRAINT [PK_ChType] PRIMARY KEY CLUSTERED 
(
	[ChType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DataType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DataType](
	[DataType] [char](1) NOT NULL,
	[TypeName] [char](10) NOT NULL,
 CONSTRAINT [PK_DataType] PRIMARY KEY CLUSTERED 
(
	[DataType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Devices]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Devices](
	[Device] [char](20) NOT NULL,
	[SortId] [int] NULL,
	[DevName] [varchar](50) NULL,
	[DevType] [tinyint] NOT NULL,
	[Station] [char](20) NULL,
	[IP] [varchar](20) NULL,
	[Mac] [varchar](20) NULL,
	[SiteId] [smallint] NULL,
	[LocationX] [smallint] NULL,
	[LocationY] [smallint] NULL,
	[ModIndex] [smallint] NULL,
	[Password] [varchar](120) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Devices] PRIMARY KEY CLUSTERED 
(
	[Device] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[DevType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DevType](
	[DevType] [tinyint] NOT NULL,
	[TypeName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_DevType] PRIMARY KEY CLUSTERED 
(
	[DevType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_DevType] UNIQUE NONCLUSTERED 
(
	[TypeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[EmailService]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EmailService](
	[ID] [varchar](20) NOT NULL,
	[UserID] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[PopHost] [varchar](50) NULL,
	[PopPort] [int] NULL,
	[SmtpHost] [varchar](50) NULL,
	[SmtpPort] [int] NULL,
	[RetrieveInterval] [int] NULL,
	[ServerName] [varchar](30) NULL,
	[Skill] [varchar](20) NULL,
	[Priority] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_EmailService] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Extension]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Extension](
	[Device] [char](20) NOT NULL,
	[Station] [varchar](20) NULL,
	[GroupId] [smallint] NULL,
	[Sortid] [int] NULL,
	[DevName] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Extension] PRIMARY KEY CLUSTERED 
(
	[Device] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ExtGroup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ExtGroup](
	[GroupId] [smallint] NOT NULL,
	[Device] [char](20) NOT NULL,
 CONSTRAINT [PK_ExtGroup] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[Device] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Groups]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Groups](
	[GroupId] [smallint] NOT NULL,
	[GroupName] [varchar](50) NOT NULL,
	[GroupType] [tinyint] NOT NULL,
	[PrjId] [int] NULL,
	[Items] [varchar](4000) NULL,
	[Summary] [text] NULL,
	[Leader] [char](20) NULL,
	[SiteId] [smallint] NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Groups] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GroupType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GroupType](
	[GroupType] [tinyint] NOT NULL,
	[TypeName] [varchar](50) NULL,
 CONSTRAINT [PK_GroupType] PRIMARY KEY CLUSTERED 
(
	[GroupType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MediaTerminal]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MediaTerminal](
	[TerminalNo] [char](16) NOT NULL,
	[Name] [varchar](64) NOT NULL,
	[Description] [varchar](128) NULL,
	[IP] [varchar](24) NULL,
	[Mac] [varchar](24) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_MediaTerminal] PRIMARY KEY CLUSTERED 
(
	[TerminalNo] ASC,
	[Name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MobileAttribution]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MobileAttribution](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MobileNumber] [nvarchar](20) NULL,
	[MobileArea] [nvarchar](50) NULL,
	[MobileType] [nvarchar](50) NULL,
	[AreaCode] [nvarchar](10) NULL,
	[PostCode] [nvarchar](50) NULL,
 CONSTRAINT [PK_Mobile] PRIMARY KEY NONCLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Posts]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Posts](
	[Post] [tinyint] NOT NULL,
	[PostName] [varchar](50) NOT NULL,
	[Description] [varchar](100) NULL,
	[bAnswer] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Posts] PRIMARY KEY CLUSTERED 
(
	[Post] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PrjItem]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PrjItem](
	[PrjId] [int] NOT NULL,
	[SubId] [smallint] NOT NULL,
	[Type] [smallint] NOT NULL,
	[Items] [varchar](2000) NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_PrjItem] PRIMARY KEY CLUSTERED 
(
	[PrjId] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PrjItemType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PrjItemType](
	[Type] [smallint] NOT NULL,
	[TypeName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_PrjItemType] PRIMARY KEY CLUSTERED 
(
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Projects]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Projects](
	[PrjId] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[Project] [varchar](50) NULL,
	[Summary] [varchar](500) NULL,
	[StartDay] [int] NULL,
	[StopDay] [int] NULL,
	[BegTime] [int] NULL,
	[EndTime] [int] NULL,
	[State] [varchar](50) NULL,
	[Weekly] [int] NULL,
	[Monthly] [int] NULL,
	[Holidays] [int] NULL,
	[MLastDays] [tinyint] NULL,
	[TimeSpanType] [tinyint] NULL,
	[FirstWeekDay] [tinyint] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED 
(
	[PrjId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Route]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Route](
	[Route] [char](20) NOT NULL,
	[RouteName] [varchar](50) NULL,
	[PrjId] [int] NULL,
	[Station] [varchar](20) NULL,
	[SortId] [int] NULL,
	[SwitchIn] [varchar](50) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Route] PRIMARY KEY CLUSTERED 
(
	[Route] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SelStratDef]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SelStratDef](
	[Strategy] [int] NOT NULL,
	[Name] [varchar](60) NOT NULL,
	[Description] [varchar](200) NULL,
 CONSTRAINT [PK_SelStratDef] PRIMARY KEY CLUSTERED 
(
	[Strategy] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Site]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Site](
	[SiteId] [smallint] NOT NULL,
	[SiteName] [varchar](50) NOT NULL,
	[Country] [varchar](50) NULL,
	[City] [varchar](50) NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Site] PRIMARY KEY CLUSTERED 
(
	[SiteId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Skill]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Skill](
	[Skill] [char](20) NOT NULL,
	[SortId] [int] NOT NULL,
	[SkillName] [varchar](50) NOT NULL,
	[SkillType] [tinyint] NULL,
	[AgentList] [varchar](4000) NULL,
	[Agents] [int] NULL,
	[SkillLevel] [int] NOT NULL,
	[DevList] [varchar](4000) NULL,
	[Strategy] [int] NOT NULL,
	[Overflow] [bit] NOT NULL,
	[AnsTime] [smallint] NULL,
	[Split] [smallint] NULL,
	[SkillGroup] [int] NULL,
	[ProjectId] [int] NULL,
	[PrjId] [int] NULL,
	[Summary] [varchar](500) NULL,
	[Enabled] [bit] NOT NULL,
	[SkillId] [varchar](20) NULL,
 CONSTRAINT [PK_Skill] PRIMARY KEY CLUSTERED 
(
	[Skill] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SkillAgent]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SkillAgent](
	[Skill] [char](20) NOT NULL,
	[Agent] [char](20) NOT NULL,
 CONSTRAINT [PK_SkillAgent] PRIMARY KEY CLUSTERED 
(
	[Skill] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SkillGroup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SkillGroup](
	[SkillGroup] [int] NOT NULL,
	[GroupName] [varchar](50) NOT NULL,
	[PrjId] [int] NOT NULL,
	[SkillList] [varchar](500) NULL,
	[SkillNum] [int] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_SkillGroup] PRIMARY KEY CLUSTERED 
(
	[SkillGroup] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Station]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Station](
	[Station] [char](20) NOT NULL,
	[SortId] [int] NULL,
	[GroupId] [smallint] NULL,
	[IP] [char](16) NULL,
	[ExtIP] [varchar](500) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Station] PRIMARY KEY CLUSTERED 
(
	[Station] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StationGroup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StationGroup](
	[GroupId] [smallint] NOT NULL,
	[Station] [char](20) NOT NULL,
 CONSTRAINT [PK_StationGroup] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[Station] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SubUser]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SubUser](
	[SubUser] [varchar](30) NOT NULL,
	[UserName] [varchar](30) NOT NULL,
	[Password] [varchar](120) NULL,
	[Role] [smallint] NOT NULL,
	[DeptId] [smallint] NULL,
	[ProjectId] [int] NULL,
	[SkillList] [varchar](max) NULL,
	[AgentList] [varchar](max) NULL,
	[GroupList] [varchar](max) NULL,
	[ExtList] [varchar](max) NULL,
	[TaskList] [varchar](max) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_SubUser] PRIMARY KEY CLUSTERED 
(
	[SubUser] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Trunk]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Trunk](
	[TrunkID] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[TrunkNum] [int] NOT NULL,
	[TrunkGroup] [int] NOT NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Trunk] PRIMARY KEY CLUSTERED 
(
	[TrunkID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TrunkGroup]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrunkGroup](
	[GroupID] [int] NOT NULL,
	[GroupName] [varchar](50) NOT NULL,
	[SortId] [int] NULL,
	[TrunkAmt] [smallint] NULL,
	[Summary] [varchar](500) NULL,
	[AutoBill] [bit] NULL,
	[Station] [varchar](20) NULL,
	[FtpId] [smallint] NOT NULL,
	[VoiceType] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_TrunkGroup] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VoiceType]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VoiceType](
	[VoiceType] [tinyint] NOT NULL,
	[TypeName] [varchar](10) NULL,
	[Ext] [varchar](10) NOT NULL,
	[Wavbit] [tinyint] NOT NULL,
	[Code] [tinyint] NOT NULL,
	[Description] [varchar](100) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_VoiceType] PRIMARY KEY CLUSTERED 
(
	[VoiceType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[station_view]    Script Date: 2016/9/5 9:38:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[station_view]
AS
SELECT Station, SortId, GroupId, IP, ExtIP, Enabled, RTRIM(IP) + ' [' + RTRIM(Station) 
      + ']' AS stn_desc
FROM dbo.Station
WHERE (Enabled = 1)


GO
ALTER TABLE [dbo].[Agent] ADD  CONSTRAINT [DF_Agent_RegDate]  DEFAULT (getdate()) FOR [RegDate]
GO
ALTER TABLE [dbo].[Agent] ADD  CONSTRAINT [DF_Agent_State]  DEFAULT ((1)) FOR [State]
GO
ALTER TABLE [dbo].[Channels] ADD  CONSTRAINT [DF_Channels_MaxCalls]  DEFAULT ((1)) FOR [MaxCalls]
GO
ALTER TABLE [dbo].[Channels] ADD  CONSTRAINT [DF_CardPort_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Devices] ADD  CONSTRAINT [DF_Devices_DevType]  DEFAULT ((1)) FOR [DevType]
GO
ALTER TABLE [dbo].[Devices] ADD  CONSTRAINT [DF_Devices_LocationX]  DEFAULT ((0)) FOR [LocationX]
GO
ALTER TABLE [dbo].[Devices] ADD  CONSTRAINT [DF_Devices_LocationY]  DEFAULT ((0)) FOR [LocationY]
GO
ALTER TABLE [dbo].[Devices] ADD  CONSTRAINT [DF_Devices_ModIndex]  DEFAULT ((0)) FOR [ModIndex]
GO
ALTER TABLE [dbo].[Devices] ADD  CONSTRAINT [DF_Devices_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[EmailService] ADD  CONSTRAINT [DF_EmailServices_PopPort]  DEFAULT ((110)) FOR [PopPort]
GO
ALTER TABLE [dbo].[EmailService] ADD  CONSTRAINT [DF_EmailServices_SmtpPort]  DEFAULT ((25)) FOR [SmtpPort]
GO
ALTER TABLE [dbo].[Extension] ADD  CONSTRAINT [DF_Extension_NetPC]  DEFAULT ((0)) FOR [Station]
GO
ALTER TABLE [dbo].[Extension] ADD  CONSTRAINT [DF_Extension_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Groups] ADD  CONSTRAINT [DF_Groups_Summary]  DEFAULT ('0') FOR [Summary]
GO
ALTER TABLE [dbo].[Posts] ADD  CONSTRAINT [DF_Dutys_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[PrjItem] ADD  CONSTRAINT [DF_PrjItem_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_MLastDays]  DEFAULT ((0)) FOR [MLastDays]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_TimeSpanType]  DEFAULT ((15)) FOR [TimeSpanType]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_FirstWeekDay]  DEFAULT ((0)) FOR [FirstWeekDay]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Route] ADD  CONSTRAINT [DF_Route_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Site] ADD  CONSTRAINT [DF_Site_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Skill] ADD  CONSTRAINT [DF_Skill_SkillLevel]  DEFAULT ((1)) FOR [SkillLevel]
GO
ALTER TABLE [dbo].[Skill] ADD  CONSTRAINT [DF_Skill_Strategy]  DEFAULT ((1)) FOR [Strategy]
GO
ALTER TABLE [dbo].[Skill] ADD  CONSTRAINT [DF_Skill_Overflow]  DEFAULT ((0)) FOR [Overflow]
GO
ALTER TABLE [dbo].[Skill] ADD  CONSTRAINT [DF_Skill_AnsTime]  DEFAULT ((15)) FOR [AnsTime]
GO
ALTER TABLE [dbo].[Skill] ADD  CONSTRAINT [DF_Skill_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Station] ADD  CONSTRAINT [DF_NetPC_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Trunk] ADD  CONSTRAINT [DF_Trunk_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[TrunkGroup] ADD  CONSTRAINT [DF_TrunkGroup_Billed]  DEFAULT ((0)) FOR [AutoBill]
GO
ALTER TABLE [dbo].[TrunkGroup] ADD  CONSTRAINT [DF_TrunkGroup_FtpId]  DEFAULT ((0)) FOR [FtpId]
GO
ALTER TABLE [dbo].[TrunkGroup] ADD  CONSTRAINT [DF_TrunkGroup_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[AgentGroup]  WITH NOCHECK ADD  CONSTRAINT [FK_AgentGroup_Agent] FOREIGN KEY([Agent])
REFERENCES [dbo].[Agent] ([Agent])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[AgentGroup] CHECK CONSTRAINT [FK_AgentGroup_Agent]
GO
ALTER TABLE [dbo].[Channels]  WITH CHECK ADD  CONSTRAINT [FK_Channels_ChType] FOREIGN KEY([ChType])
REFERENCES [dbo].[ChType] ([ChType])
GO
ALTER TABLE [dbo].[Channels] CHECK CONSTRAINT [FK_Channels_ChType]
GO
ALTER TABLE [dbo].[Channels]  WITH NOCHECK ADD  CONSTRAINT [FK_Channels_Station] FOREIGN KEY([Station])
REFERENCES [dbo].[Station] ([Station])
GO
ALTER TABLE [dbo].[Channels] CHECK CONSTRAINT [FK_Channels_Station]
GO
ALTER TABLE [dbo].[Channels]  WITH CHECK ADD  CONSTRAINT [FK_Channels_VoiceType] FOREIGN KEY([VoiceType])
REFERENCES [dbo].[VoiceType] ([VoiceType])
GO
ALTER TABLE [dbo].[Channels] CHECK CONSTRAINT [FK_Channels_VoiceType]
GO
ALTER TABLE [dbo].[ExtGroup]  WITH CHECK ADD  CONSTRAINT [FK_ExtGroup_Devices] FOREIGN KEY([Device])
REFERENCES [dbo].[Devices] ([Device])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[ExtGroup] CHECK CONSTRAINT [FK_ExtGroup_Devices]
GO
ALTER TABLE [dbo].[Groups]  WITH CHECK ADD  CONSTRAINT [FK_Groups_GroupType] FOREIGN KEY([GroupType])
REFERENCES [dbo].[GroupType] ([GroupType])
GO
ALTER TABLE [dbo].[Groups] CHECK CONSTRAINT [FK_Groups_GroupType]
GO
ALTER TABLE [dbo].[PrjItem]  WITH CHECK ADD  CONSTRAINT [FK_PrjItem_PrjItemType] FOREIGN KEY([Type])
REFERENCES [dbo].[PrjItemType] ([Type])
GO
ALTER TABLE [dbo].[PrjItem] CHECK CONSTRAINT [FK_PrjItem_PrjItemType]
GO
ALTER TABLE [dbo].[PrjItem]  WITH CHECK ADD  CONSTRAINT [FK_PrjItem_Projects] FOREIGN KEY([PrjId])
REFERENCES [dbo].[Projects] ([PrjId])
ON UPDATE CASCADE
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[PrjItem] CHECK CONSTRAINT [FK_PrjItem_Projects]
GO
ALTER TABLE [dbo].[Skill]  WITH CHECK ADD  CONSTRAINT [FK_Skill_SelStratDef] FOREIGN KEY([Strategy])
REFERENCES [dbo].[SelStratDef] ([Strategy])
GO
ALTER TABLE [dbo].[Skill] CHECK CONSTRAINT [FK_Skill_SelStratDef]
GO
ALTER TABLE [dbo].[StationGroup]  WITH CHECK ADD  CONSTRAINT [FK_StationGroup_Groups] FOREIGN KEY([GroupId])
REFERENCES [dbo].[Groups] ([GroupId])
GO
ALTER TABLE [dbo].[StationGroup] CHECK CONSTRAINT [FK_StationGroup_Groups]
GO
ALTER TABLE [dbo].[StationGroup]  WITH NOCHECK ADD  CONSTRAINT [FK_StationGroup_Station] FOREIGN KEY([Station])
REFERENCES [dbo].[Station] ([Station])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[StationGroup] CHECK CONSTRAINT [FK_StationGroup_Station]
GO
ALTER TABLE [dbo].[Trunk]  WITH NOCHECK ADD  CONSTRAINT [FK_Trunk_TrunkGroup] FOREIGN KEY([TrunkGroup])
REFERENCES [dbo].[TrunkGroup] ([GroupID])
ON DELETE CASCADE
GO
ALTER TABLE [dbo].[Trunk] CHECK CONSTRAINT [FK_Trunk_TrunkGroup]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'坐席组代码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'AgentGroup', @level2type=N'COLUMN',@level2name=N'GroupId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'坐席组名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'AgentGroup', @level2type=N'COLUMN',@level2name=N'Agent'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'设备代码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Channels', @level2type=N'COLUMN',@level2name=N'Channel'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'设备分类' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Channels', @level2type=N'COLUMN',@level2name=N'SortId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'设备名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Channels', @level2type=N'COLUMN',@level2name=N'DevName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'交换机中存在直连的同名设备' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Channels', @level2type=N'COLUMN',@level2name=N'Mapped'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效标志' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Channels', @level2type=N'COLUMN',@level2name=N'Enabled'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'设备代码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Devices', @level2type=N'COLUMN',@level2name=N'Device'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'设备分类代码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Devices', @level2type=N'COLUMN',@level2name=N'SortId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'设备名称' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Devices', @level2type=N'COLUMN',@level2name=N'DevName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效标志' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Devices', @level2type=N'COLUMN',@level2name=N'Enabled'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'项目/工程代码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Projects', @level2type=N'COLUMN',@level2name=N'PrjId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'项目分类' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Projects', @level2type=N'COLUMN',@level2name=N'SortId'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'项目启动日期，格式：yyyymmdd' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Projects', @level2type=N'COLUMN',@level2name=N'StartDay'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'项目截止日期，格式：yyyymmdd' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Projects', @level2type=N'COLUMN',@level2name=N'StopDay'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'项目状态描述' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Projects', @level2type=N'COLUMN',@level2name=N'State'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'项目有效标志' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Projects', @level2type=N'COLUMN',@level2name=N'Enabled'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'路由点' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Route', @level2type=N'COLUMN',@level2name=N'Route'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'路由点描述' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Route', @level2type=N'COLUMN',@level2name=N'RouteName'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'接入电话号码' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Route', @level2type=N'COLUMN',@level2name=N'SwitchIn'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'有效标志' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Route', @level2type=N'COLUMN',@level2name=N'Enabled'
GO
