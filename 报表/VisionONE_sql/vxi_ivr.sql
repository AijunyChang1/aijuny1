USE [master]
GO
CREATE DATABASE [vxi_ivr]
GO

USE [vxi_ivr]
GO
/****** Object:  DatabaseRole [ba]    Script Date: 2016/9/5 13:28:27 ******/
CREATE ROLE [ba]
GO
/****** Object:  StoredProcedure [dbo].[sp_evaluate_satisfaction]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===================================================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2011-6-14>
-- Description:	<满意度水平报表：呼入量、评价量、5项评价量>
-- Ehai
/* Example:
exec sp_evaluate_satisfaction @DateBegin=null,@DateEnd=null
exec sp_evaluate_satisfaction @DateBegin=20111207,
								@DateEnd=20111207
								,@Agent='7009'
								,@Preload=1
*/
-- ===================================================================
CREATE PROCEDURE [dbo].[sp_evaluate_satisfaction]
	-- Add the parameters for the stored procedure here
	@RecDate	INT			= NULL,		-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
										-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	BIGINT		= NULL,
	@DateEnd	BIGINT		= NULL,
	@TimeBegin	INT			= 0,
	@TimeEnd	INT			= 235959,
	@Agent		VARCHAR(20) = NULL,
	@Preload	BIT			= 0			-- 仅预览表标题
	
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Beg_LogId	bigint,
			@End_LogId	bigint,
			@Error		int
			
	set @Agent = isnull(@Agent, '')
			
	IF (@RecDate IS NULL OR @RecDate <= 0) BEGIN
		SET @RecDate = CONVERT(VARCHAR(8), GETDATE(), 112)	-- yyyyMMdd
		SET @Error = @@ERROR
	END
	                
	IF ISDATE(@DateBegin) != 1 OR ISDATE(@DateEnd) != 1 OR @DateBegin > @DateEnd BEGIN
		IF (@RecDate BETWEEN 19000101 AND 99991231) BEGIN
			-- 作为yyyyMMdd处理
			SELECT @DateBegin = @RecDate, @DateEnd = @RecDate
			SET @Error = @@ERROR
		END
		ELSE IF (@RecDate BETWEEN 190011 AND 999912) BEGIN
			-- 作为yyyyMM处理
			SELECT @DateBegin = @RecDate*100 + 1, @DateEnd = @RecDate*100 + 31	-- 计算范围为1月
			SET @Error = @@ERROR
		END
		ELSE IF (@RecDate BETWEEN 1900 AND 9999) BEGIN
			-- 作为yyyy处理
			SELECT @DateBegin = @RecDate*10000 + 101, @DateEnd = @RecDate*10000 + 1231	-- 计算范围为1年
			SET @Error = @@ERROR		
		END
		ELSE SET @Error = 1;
	END	

	;with cte as(
		select	RecDate,
				Agent,
				AgentName,
				Ans_n,
				Enter_n,
				Enter_p,
				Evaluation_n,
				Evaluation_p,
				Enter_Evaluation_p,
				[1],
				[2],
				[3],
				[1_p],
				[2_p],
				[3_p]
			from dbo.Evaluate_Satisfaction
			where RecDate between @DateBegin and @DateEnd
				and Agent = case when LEN(@Agent) > 0 then @Agent else Agent end
				and 0 = @Preload
	)
	
	select RecDate,
			Agent,
			AgentName,
			Ans_n,
			Enter_n,
			Enter_p,
			Evaluation_n,
			Evaluation_p,
			Enter_Evaluation_p,
			[1],
			[2],
			[3],
			[1_p],
			[2_p],
			[3_p]
		from cte
	union all
	select RecDate = NULL,
			Agent = '',
			AgentName = 'Total',
			Ans_n = sum(Ans_n),
			Enter_n = sum(Enter_n),
			Enter_p = NULL,
			Evaluation_n = sum(Evaluation_n),
			Evaluation_p = NULL,
			Enter_Evaluation_p = NULL,
			[1] = sum([1]),
			[2] = sum([2]),
			[3] = sum([3]),
			[1_p] = NULL,
			[2_p] = NULL,
			[3_p] = NULL
		from cte
		order by RecDate desc, Agent
	
END

GO
/****** Object:  StoredProcedure [dbo].[sp_evaluate_satisfaction_insert]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ===================================================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2011-6-14>
-- Description:	<满意度水平报表：呼入量、评价量、5项评价量>
-- Ehai
/* Example:
exec sp_evaluate_satisfaction_insert @DateBegin=null,@DateEnd=null
exec sp_evaluate_satisfaction_insert @DateBegin=20111209
									,@DateEnd=20111218
									,@Agent='7005'
*/
-- ===================================================================
CREATE PROCEDURE [dbo].[sp_evaluate_satisfaction_insert]
	-- Add the parameters for the stored procedure here
	@RecDate	INT			= NULL,		-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
										-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	BIGINT		= NULL,
	@DateEnd	BIGINT		= NULL,
	@TimeBegin	INT			= 0,
	@TimeEnd	INT			= 235959,
	@Agent		VARCHAR(20) = NULL
	
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Beg_LogId	bigint,
			@End_LogId	bigint,
			@Error		int
			
	set @Agent = isnull(@Agent, '')
			
	IF (@RecDate IS NULL OR @RecDate <= 0) BEGIN
		SET @RecDate = CONVERT(VARCHAR(8), GETDATE(), 112)	-- yyyyMMdd
		SET @Error = @@ERROR
	END
	                
	IF ISDATE(@DateBegin) != 1 OR ISDATE(@DateEnd) != 1 OR @DateBegin > @DateEnd BEGIN
		IF (@RecDate BETWEEN 19000101 AND 99991231) BEGIN
			-- 作为yyyyMMdd处理
			SELECT @DateBegin = @RecDate, @DateEnd = @RecDate
			SET @Error = @@ERROR
		END
		ELSE IF (@RecDate BETWEEN 190011 AND 999912) BEGIN
			-- 作为yyyyMM处理
			SELECT @DateBegin = @RecDate*100 + 1, @DateEnd = @RecDate*100 + 31	-- 计算范围为1月
			SET @Error = @@ERROR
		END
		ELSE IF (@RecDate BETWEEN 1900 AND 9999) BEGIN
			-- 作为yyyy处理
			SELECT @DateBegin = @RecDate*10000 + 101, @DateEnd = @RecDate*10000 + 1231	-- 计算范围为1年
			SET @Error = @@ERROR		
		END
		ELSE SET @Error = 1;
	END	
			
	select @Beg_LogId = cast(@DateBegin as bigint) * 1000000,
			@End_LogId = cast(@DateEnd as bigint) * 1000000 + 999999
/*		

*/

	declare @ResultIdList	varchar(20),
			@ResultId		varchar(20),
			@StrSql			nvarchar(4000)
	
	set @ResultIdList = ''
	select @ResultIdList = @ResultIdList + '[' + rtrim(ltrim(str(ResultId))) + '],'
		from vxi_ivr.dbo.SurveyResult
		where len(Description) > 0
			
	if len(@ResultIdList) > 0 set @ResultIdList = left(@ResultIdList, len(@ResultIdList) - 1)
	select @ResultId = replace(replace(@ResultIdList,'[',''''),']','''')
	--print @ResultIdList --
	
	set @StrSql = '
	;with cte1 as(
		/*总接听量*/
		select RecDate = u.UcdId - u.UcdId % 1000000,
				Agent,
				Ans_n = count(*)
			from vxi_ucd.dbo.Ucd u
			where u.UcdId between ' + str(@Beg_LogId, 16) + ' and ' + str(@End_LogId, 16) + '
				and u.Inbound = 1
				and len(u.Agent) > 0
			/*	and len(u.Skill) > 0 */
				and u.Agent = ' + case when len(@Agent) > 0 then @Agent else 'u.Agent' end + '
				and exists(select 1 from vxi_ucd.dbo.UcdCall uc
							where uc.UcdId = u.UcdId
								and uc.bEstb = 1
								and len(uc.Agent) > 0)
			group by u.UcdId - u.UcdId % 1000000, Agent
	),
	cte2 as(
		/*转入满意度评测:Enter_n*/
		/*顾客参与评测:Evaluation_n*/
		select RecDate = SurveyId - SurveyId % 1000000,
				Agent,
				Enter_n = count(*),
				Evaluation_n = sum(case when len(Dtmf) > 0 
									and Dtmf in ('+@ResultId+')
									then 1 else 0 end)
			from vxi_ivr.dbo.Survey s
			where SurveyId between ' + str(@Beg_LogId, 16) + ' and ' + str(@End_LogId, 16) + '
				and len(Agent) > 0
				and Agent = ' + case when len(@Agent) > 0 then @Agent else 'Agent' end + '
			group by SurveyId - SurveyId % 1000000, Agent
	)'
	--print @StrSql --
	
	if len(@ResultIdList) > 0 begin
		set @StrSql = @StrSql + ',
		cte5 as(
			select RecDate,Agent,' + @ResultIdList + '
			from
			(select RecDate = SurveyId - SurveyId % 1000000,
					Agent,
					Dtmf = case when len(Dtmf) = 0 then ''0'' else Dtmf end
				from vxi_ivr.dbo.Survey
				where SurveyId between ' + str(@Beg_LogId, 16) + ' and ' + str(@End_LogId, 16) + '
					and len(Agent) > 0
					and Agent = ' + case when len(@Agent) > 0 then @Agent else 'Agent' end + '
					and len(Dtmf) >= 0) as SourceTable
			PIVOT
			(
			count(Dtmf)
			FOR Dtmf in (' + @ResultIdList + ')
			) as PivotTable
		),
		cte6 as(
		select RecDate = c1.RecDate / 1000000,
				c1.Agent,
				c1.Ans_n,
				c2.Enter_n,
				c2.Evaluation_n,
				'+ 
				@ResultIdList + '
			from cte1 c1 
				left join cte2 c2 on c2.RecDate = c1.RecDate and c2.Agent = c1.Agent
				left join cte5 c5 on c5.RecDate = c1.RecDate and c5.Agent = c1.Agent
		),
		cte7 as(
		select c6.RecDate,
				c6.Agent,
				a.AgentName,
				c6.Ans_n,
				c6.Enter_n,
				Enter_p = case when c6.Ans_n > 0 
								then convert(numeric(12,0), (1.0 * c6.Enter_n / c6.Ans_n * 100))
							else 0 end,
				c6.Evaluation_n,
				Evaluation_p = case when c6.Enter_n > 0 
									then convert(numeric(12,0), (1.0 * c6.Evaluation_n / c6.Enter_n * 100))
								else 0 end,
				'+ 
				@ResultIdList + ',
				[1_p] = case when c6.Evaluation_n > 0 
							then convert(numeric(12, 0), (1.0 * c6.[1] / c6.Evaluation_n * 100))
						else 0 end,
				[2_p] = case when c6.Evaluation_n > 0 
							then convert(numeric(12,0), (1.0 * c6.[2] / c6.Evaluation_n * 100))
						else 0 end,
				[3_p] = case when c6.Evaluation_n > 0 
							then convert(numeric(12,0), (1.0 * c6.[3] / c6.Evaluation_n * 100))
						else 0 end
			from cte6 c6
					left join vxi_sys.dbo.Agent a on a.Agent = c6.Agent
		),
		cte10 as(
			select RecDate,
					Agent,
					AgentName,
					Ans_n,
					Enter_n,
					Enter_p,
					Evaluation_n,
					Evaluation_p,
					Enter_Evaluation_p = Enter_p * Evaluation_p / 100,
					'+ 
					@ResultIdList + ',
					[1_p],
					[2_p],
					[3_p]	
				from cte7
		)
		
		insert into dbo.Evaluate_Satisfaction
					([RecDate]
					  ,[Agent]
					  ,[AgentName]
					  ,[Ans_n]
					  ,[Enter_n]
					  ,[Enter_p]
					  ,[Evaluation_n]
					  ,[Evaluation_p]
					  ,[Enter_Evaluation_p]
					  ,[1]
					  ,[2]
					  ,[3]
					  ,[1_p]
					  ,[2_p]
					  ,[3_p])
			select RecDate = str(RecDate,8),
						Agent,
						AgentName,
						Ans_n,
						Enter_n,
						Enter_p,
						Evaluation_n,
						Evaluation_p,
						Enter_Evaluation_p = Enter_p * Evaluation_p / 100,
						'+ 
						@ResultIdList + ',
						[1_p],
						[2_p],
						[3_p]
				from cte10
		'
	end
	
	--print @StrSql --
	delete from dbo.Evaluate_Satisfaction
		where RecDate between @DateBegin and @DateEnd
			and Agent = case when len(@Agent) > 0 then @Agent else Agent end
			
	exec sp_executesql @StrSql
	
	return @@rowcount

END



GO
/****** Object:  StoredProcedure [dbo].[sp_get_InsertSql]    Script Date: 2016/9/5 13:28:27 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_get_ivr_banggo_survey]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================
-- Author:		Summit.lau
-- Create date: 2011.09.23
-- Description:	Surver 满意度明细查询报表
/* Example:
exec sp_get_ivr_Survey @Agent='ddd',@Dtmf=5,@Calling='2234',
		@DateBegin=null ,@DateEnd=null, @Preload=1
exec sp_get_ivr_Survey @DateBegin=null
						,@DateEnd=null
						,@Preload=1
*/
-- ===========================================================
CREATE PROCEDURE [dbo].[sp_get_ivr_banggo_survey] 
	-- Add the parameters for the stored procedure here
	@Agent	 	varchar(8) = '',		-- 坐席编号	@Dtmf      INT        = 0 ,         -- 评价类型	@Calling   varchar(23) = '',       -- 主叫号码	@DateBegin	BIGINT		= NULL,     -- 起始日期
	@DateEnd	BIGINT		= NULL,     -- 结束日期
	@Preload	bit		= NULL			-- 预加载
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    declare @BegDate	varchar(10),
			@EndDate	varchar(10),
			@Sql        VARCHAR(max),
			@Error		int
	SET @Agent = isnull(@Agent, '')
	SET @Dtmf = ISNULL(@Dtmf,-1)
	SET @Calling = ISNULL(@Calling,'')
	SET @DateBegin = ISNULL(@DateBegin ,0)
	SET @DateEnd = ISNULL(@DateEnd,0)
	SET @Preload = ISNULL(@Preload, 0)

	IF @DateBegin > 0 AND @DateEnd > 0 AND @DateBegin < @DateEnd Begin 
	      SET @BegDate = dbo.intdatehh_to_str(@DateBegin)
	      SET @EndDate = dbo.intdatehh_to_str(@DateEnd)	      
	      SET @Sql = 'And StartTime BETWEEN '''+@BegDate + ' 00:00:00.000'' AND '''+@EndDate+' 23:59:59.000'''	
    END 
    ELSE IF @DateBegin > 0 AND @DateEnd > 0 AND @DateBegin > @DateEnd BEGIN
           SET @BegDate = dbo.intdatehh_to_str(@DateBegin)
	       SET @EndDate = dbo.intdatehh_to_str(@DateEnd)	  	    
           SET @Sql = 'And StartTime BETWEEN '''+@EndDate + ' 00:00:00.000'' AND '''+@BegDate+' 23:59:59.000'''		                        
    END
	ELSE IF @DateBegin = 0 AND @DateEnd > 0 BEGIN
              SET @EndDate = dbo.intdatehh_to_str(@DateEnd)	    
              SET @Sql = 'And StartTime < '''+@EndDate+' 23:59:59.000'''	
    END
	ELSE IF @DateBegin > 0 AND @DateEnd = 0 BEGIN
              SET @BegDate = dbo.intdatehh_to_str(@DateBegin)	    
              SET @Sql = 'And StartTime > '''+@BegDate+' 00:00:00.000'''	
    END
    ELSE IF @DateBegin > 0 AND @DateEnd > 0   BEGIN
              SET @BegDate = dbo.intdatehh_to_str(@DateBegin)
              SET @Sql = 'And StartTime BETWEEN '''+@BegDate + ' 00:00:00.000'' AND '''+@BegDate+' 23:59:59.000'''	
    END
	ELSE SET @Sql = 'And StartTime > '''+CONVERT(VARCHAR(10),GETDATE(),120)+''''		
   SET  @Sql =  'SELECT [SurveyID]
						  ,[UcdID]
						  ,[Agent]
						  ,[SurveyResult] = [Dtmf]
						  ,[Calling]
						  ,[Called]
						  ,[CallID]
						  ,[StartTime]
						  ,[UCID]
						  ,[UUI]
				 FROM Survey 
				  WHERE Agent = CASE  WHEN LEN('''+@Agent+''') > 0 THEN '''+@Agent+'''
										ELSE Agent
										END
					 AND Dtmf = CASE WHEN '+ CAST(@Dtmf AS VARCHAR(2)) +'> 0 THEN '''+cast(@Dtmf AS VARCHAR(2))+'''
										ELSE Dtmf
										END                                    
					 AND Calling = CASE WHEN LEN('''+@Calling+''') > 0 THEN '''+@Calling+'''
										 ELSE Calling
										 END
					 ' + @Sql + ' AND 0 = ' + STR(@Preload) + '
					 ORDER BY StartTime Desc '       
         PRINT @Sql
         EXEC(@Sql)
END
GO
/****** Object:  StoredProcedure [dbo].[sp_get_ivr_ivrRecords_view]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--sp_get_ivr_ivrRecords_view '2013-01-01','2015-11-30','','','','','','',''

create PROCEDURE [dbo].[sp_get_ivr_ivrRecords_view]
	@repdate_begin varchar(10),     --开始日期
	@repdate_end varchar(10),       --结束日期
	@ivrflow int,                   --ivr流程
	@ivrid bigint,                  --记录号
	@calling varchar(50),           --主叫号码
	@called varchar(50),            --被叫号码
	@channel varchar(20),           --IVR通道
	@timelen int,                   --时长
	@exittype char(1)               --结束类型
AS

	select * from vxi_ivr..ivrRecords_view 
	where 
		datediff(day,StartTime, @repdate_begin) <= 0 
		and datediff(day,StartTime, @repdate_end) >= 0
		and (@ivrflow='' or IvrFlow=@ivrflow)
		and (@ivrid='' or IvrId=@ivrid)
		and (@calling='' or Calling=@calling)
		and (@called='' or Called=@called)
		and (@channel='' or Channel=@channel)
		and (@timelen='' or TimeLen=@timelen)
		and (@exittype='' or ExitType=@exittype)
	order by StartTime desc, ivrid asc


GO
/****** Object:  StoredProcedure [dbo].[sp_get_ivr_report]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE      PROCEDURE [dbo].[sp_get_ivr_report]
	@repdate int = null,		-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，注：mm = 0 表示年报，dd = 0 表示月报
	@flowid int = 0,			-- 流程代码（@flowid = 0 表示所有流程）
	@time_begin datetime = null,		-- 起始时间 缺省日期：当前日期 - 7
	@time_end datetime = null		-- 截止时间 缺省日期：当前日期
AS

	declare @returnval int, @strkey varchar(10)

	if isnull(@flowid, 0) <> 0	begin --指定流程
		set @strkey = 'flow'
	end

	exec @returnval = sp_sch_stat_ivr_call 	@repdate = @repdate,
											@time_begin = @time_begin,
											@time_end = @time_end,
											@sch_key = @strkey,
											@sch_value = @flowid
	return @returnval

/*
	declare @strSQL nvarchar(4000), @strTblName varchar(20), @strWhere varchar(200)
	declare @strGroupby varchar(100), @GroupLevel int
	declare @repdate_begin_int int, @repdate_end_int int

	if isnull(@repdate, 0) = 0 begin
		--@repdate缺省，采用@time_begin/@time_end
		if @time_begin is null
			set @time_begin = convert(varchar(10), getdate() - 6, 120) + ' 00:00:00'
		if @time_end is null
			set @time_end = convert(varchar(10), getdate(), 120) + ' 23:59:59'

		set @repdate_begin_int = dbo.datehh_to_int(@time_begin)
		set @repdate_end_int = dbo.datehh_to_int(@time_end)

		set @strWhere = ' Where (RepDate between ' + cast(@repdate_begin_int as varchar(18)) 
					  + ' and ' + cast(@repdate_end_int as varchar(18)) + ')'

		if @time_end - @time_begin <= 7
			set @GroupLevel = 0	 	--按时分组
		else
			set @GroupLevel = 2		--按日分组
	end
	else begin	--@repdate没有缺省
		if @repdate / 100 % 100	= 0		-- mm = 0, @repdate = 20060000
			set @GroupLevel = 4			--年报，按月分组
		else if @repdate % 100 = 0		-- dd = 0, @repdate = 20060300
			set @GroupLevel = 2			--月报，按日分组
		else							-- @repdate = 20060318
			set @GroupLevel = 0			--日报，按时分组

		--注：RepDate格式yyyymmddhh, @repdate格式yyyymmdd
		set @strWhere = ' Where (RepDate / power(10, ' + cast((@GroupLevel + 2) as varchar(1)) + ')) = ' 
					  + cast((@repdate / power(10, @GroupLevel)) as varchar(20))
	end
	
	set @strGroupby = case @GroupLevel
						when 0 then	' Group By RepDate'	--时报表
						else ' Group By (RepDate / power(10, ' + cast(@GroupLevel as varchar(1)) + '))' --其他
					  end

	if isnull(@flowid, 0) = 0 begin
		set @strTblName = 'stat_ivr_call'		--所有流程
	end
	else begin
		set @strTblName = 'stat_ivr_flow'		--指定流程
		set @strWhere = @strWhere + ' and (FlowId = ' + cast(@flowid as varchar(20)) + ')'
  	end

	set @strSQL = 'select ''Total:'' RepDate, sum(CallNum) CallNum, sum(CallTm) CallTm, '
				+ 'vxi_def.dbo.avg_str(sum(CallTm), sum(CallNum), 0) CallAvgTm, '
				+ 'max(MaxTm) MaxTm, max(MinTm) MinTm, sum(ExtUNum) ExtUNum, sum(ExtUTm) ExtUTm, '
				+ 'vxi_def.dbo.avg_str(sum(ExtUTm), sum(ExtUNum), 0) ExtUAvgTm, '
				+ 'sum(ExtINum) ExtINum, sum(ExtITm) ExtITm, '
				+ 'vxi_def.dbo.avg_str(sum(ExtITm), sum(ExtINum), 0) ExtIAvgTm, '
				+ 'sum(ExtDNum) ExtDNum, sum(ExtDTm) ExtDTm, '
				+ 'vxi_def.dbo.avg_str(sum(ExtDTm), sum(ExtDNum), 0) ExtDAvgTm '
				+ 'from ' + @strTblName + @strWhere	--合计信息
				+ ' union all '	--下面是详细数据部分
				+ 'select dbo.intdatehh_to_str(RepDate) RepDate, CallNum, CallTm, CallAvgTm, MaxTm, MinTm, '
				+ 'ExtUNum, ExtUTm, ExtUAvgTm, ExtINum, ExtITm, ExtIAvgTm, ExtDNum, ExtDTm, ExtDAvgTm from ('
				+ 'select ' + substring(@strGroupby, 11, len(@strGroupby)) + ' RepDate, '
				+ 'sum(CallNum) CallNum, sum(CallTm) CallTm, '
				+ 'vxi_def.dbo.avg_str(sum(CallTm), sum(CallNum), 0) CallAvgTm, '
				+ 'max(MaxTm) MaxTm, max(MinTm) MinTm, sum(ExtUNum) ExtUNum, sum(ExtUTm) ExtUTm, '
				+ 'vxi_def.dbo.avg_str(sum(ExtUTm), sum(ExtUNum), 0) ExtUAvgTm, '
				+ 'sum(ExtINum) ExtINum, sum(ExtITm) ExtITm, '
				+ 'vxi_def.dbo.avg_str(sum(ExtITm), sum(ExtINum), 0) ExtIAvgTm, '
				+ 'sum(ExtDNum) ExtDNum, sum(ExtDTm) ExtDTm, '
				+ 'vxi_def.dbo.avg_str(sum(ExtDTm), sum(ExtDNum), 0) ExtDAvgTm '
				+ 'from ' + @strTblName + @strWhere + @strGroupby
				+ ') t '

	print @strSQL
	exec sp_executesql @strSQL

	return @@rowcount
*/




GO
/****** Object:  StoredProcedure [dbo].[sp_get_ivr_survey]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===========================================================
-- Author:		Summit.lau
-- Create date: 2011.09.23
-- Description:	Surver 满意度明细查询报表
/* Example:
exec sp_get_ivr_Survey @Agent='ddd',@Dtmf=5,@Calling='2234',
		@DateBegin=null ,@DateEnd=null, @Preload=1
exec sp_get_ivr_Survey @DateBegin=null
						,@DateEnd=null
						,@Preload=1
*/
-- ===========================================================
CREATE PROCEDURE [dbo].[sp_get_ivr_survey] 
	-- Add the parameters for the stored procedure here
	@Agent	 	varchar(8) = '',		-- 坐席编号	@Dtmf      INT        = 0 ,         -- 评价类型	@Calling   varchar(23) = '',       -- 主叫号码	@DateBegin	BIGINT		= NULL,     -- 起始日期
	@DateEnd	BIGINT		= NULL,     -- 结束日期
	@Preload	bit		= NULL			-- 预加载
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
    declare @BegDate	varchar(10),
			@EndDate	varchar(10),
			@Sql        VARCHAR(max),
			@Error		int
	SET @Agent = isnull(@Agent, '')
	SET @Dtmf = ISNULL(@Dtmf,-1)
	SET @Calling = ISNULL(@Calling,'')
	SET @DateBegin = ISNULL(@DateBegin ,0)
	SET @DateEnd = ISNULL(@DateEnd,0)
	SET @Preload = ISNULL(@Preload, 0)

	IF @DateBegin > 0 AND @DateEnd > 0 AND @DateBegin < @DateEnd Begin 
	      SET @BegDate = dbo.intdatehh_to_str(@DateBegin)
	      SET @EndDate = dbo.intdatehh_to_str(@DateEnd)	      
	      SET @Sql = 'And StartTime BETWEEN '''+@BegDate + ' 00:00:00.000'' AND '''+@EndDate+' 23:59:59.000'''	
    END 
    ELSE IF @DateBegin > 0 AND @DateEnd > 0 AND @DateBegin > @DateEnd BEGIN
           SET @BegDate = dbo.intdatehh_to_str(@DateBegin)
	       SET @EndDate = dbo.intdatehh_to_str(@DateEnd)	  	    
           SET @Sql = 'And StartTime BETWEEN '''+@EndDate + ' 00:00:00.000'' AND '''+@BegDate+' 23:59:59.000'''		                        
    END
	ELSE IF @DateBegin = 0 AND @DateEnd > 0 BEGIN
              SET @EndDate = dbo.intdatehh_to_str(@DateEnd)	    
              SET @Sql = 'And StartTime < '''+@EndDate+' 23:59:59.000'''	
    END
	ELSE IF @DateBegin > 0 AND @DateEnd = 0 BEGIN
              SET @BegDate = dbo.intdatehh_to_str(@DateBegin)	    
              SET @Sql = 'And StartTime > '''+@BegDate+' 00:00:00.000'''	
    END
    ELSE IF @DateBegin > 0 AND @DateEnd > 0   BEGIN
              SET @BegDate = dbo.intdatehh_to_str(@DateBegin)
              SET @Sql = 'And StartTime BETWEEN '''+@BegDate + ' 00:00:00.000'' AND '''+@BegDate+' 23:59:59.000'''	
    END
	ELSE SET @Sql = 'And StartTime > '''+CONVERT(VARCHAR(10),GETDATE(),120)+''''		
   SET  @Sql =  'SELECT [SurveyID]
						  ,[UcdID]
						  ,[Agent]
						  ,[SurveyResult] = [Dtmf]
						  ,[Calling]
						  ,[Called]
						  ,[CallID]
						  ,[StartTime]
				 FROM Survey 
				  WHERE Agent = CASE  WHEN LEN('''+@Agent+''') > 0 THEN '''+@Agent+'''
										ELSE Agent
										END
					 AND Dtmf = CASE WHEN '+ CAST(@Dtmf AS VARCHAR(2)) +'> 0 THEN '''+cast(@Dtmf AS VARCHAR(2))+'''
										ELSE Dtmf
										END                                    
					 AND Calling = CASE WHEN LEN('''+@Calling+''') > 0 THEN '''+@Calling+'''
										 ELSE Calling
										 END
					 ' + @Sql + ' AND 0 = ' + STR(@Preload) + '
					 ORDER BY StartTime Desc '       
         PRINT @Sql
         EXEC(@Sql)
END
GO
/****** Object:  StoredProcedure [dbo].[sp_ivr_fax_setup]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ivr_fax_setup]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--init faxlevel table
delete faxlevel
insert faxlevel values(1,	2,	'normal')
insert faxlevel values(2,	3,	'important')
insert faxlevel values(3,	5,	'very important')

delete faxreason
insert faxreason values(0,	'Normal',			'正常')
insert faxreason values(1,	'Invalid Time Range',		'非法时间范围(超过预定结束时间)')
insert faxreason values(2,	'Overrun Max Trytimes',		'超过最大发送次数')
insert faxreason values(3,	'No Local FAX File',		'本地FAX文件未找到')
insert faxreason values(4,	'Conver Fail',			'转化TIF失败，超时')
insert faxreason values(5,	'Printer Fail',			'打印机启动失败')
insert faxreason values(6,	'No Local TIF File',		'本地接收TIF文件未找到')
insert faxreason values(7,	'Conver Dest Format Fail',	'转化为目的文件格式失败')
insert faxreason values(101,	'CFR_NO_DIAL_TONE',		'没有拨号音')
insert faxreason values(102,	'CFR_INVALID_DNIS',		'非法被叫')
insert faxreason values(103,	'CFR_RMT_BUSY',			'远端忙')
insert faxreason values(104,	'CFR_TIMEOUT',			'超时')
insert faxreason values(105,	'CFR_NO_ANSWER',		'无应答')
insert faxreason values(106,	'CFR_TRUNK_BUSY',		'中继忙')
insert faxreason values(107,	'CFR_ERROR',			'错误')
insert faxreason values(108,	'CFR_RMT_RELEASED',		'远端释放')
insert faxreason values(109,	'CFR_RELEASED',			'本端释放')
insert faxreason values(110,	'CFR_NO_AVALABLE',		'不可用')

delete faxstatus
insert faxstatus values(1,	'Send_Fax',		'待发送传真')
insert faxstatus values(2,	'Send_Sending',		'发送传真中')
insert faxstatus values(3,	'Send_Fail',		'发送传真失败')
insert faxstatus values(4,	'Send_Succ',		'发送传真成功')
insert faxstatus values(5,	'Send_Fin_Succ',	'发送传真最终成功')
insert faxstatus values(6,	'Send_Fin_Fail',	'发送传真最终失败')
insert faxstatus values(11,	'Rece_New',		'新收到传真')
insert faxstatus values(12,	'Rece_Notify',		'已经通知程序')
insert faxstatus values(13,	'Rece_Fin_Succ',	'接收传真最终成功')
insert faxstatus values(14,	'Rece_Fin_Fail',	'接收传真最终失败')

END

GO
/****** Object:  StoredProcedure [dbo].[sp_ivr_node_result_setup]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_ivr_node_result_setup]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (0,	'NORMAL', '节点正常结束')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (2,	'TERM_DTMF', '用户安按键终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (3,	'TERM_MAX_DIGITS', '最大按键数终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (4,	'TERM_END_DIGIT', '终止键终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (5,	'TERM_STOPPED', '主动停止终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (6,	'TERM_RMT_RELEASED', '远端挂机终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (7,	'TERM_TIMEOUT', '超时终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (8,	'TERM_MAX_TIME', '到达最大时长终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (9,	'TERM_MAX_SILENCE', '到达最大静音时长终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (10, 'TERM_ERROR', '遇到错误终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (11, 'TERM_RELEASED', '呼叫释放导致终止')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (101, 'CFR_NO_DIAL_TONE', '没有拨号音')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (102, 'CFR_INVALID_DNIS', '非法被叫')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (103, 'CFR_RMT_BUSY', '远端忙')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (104, 'CFR_TIMEOUT', '超时')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (105, 'CFR_NO_ANSWER', '无应答')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (106, 'CFR_TRUNK_BUSY', '中继忙')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (107, 'CFR_ERROR', '错误')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (108, 'CFR_RMT_RELEASED', '远端释放')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (109, 'CFR_RELEASED', '本端释放')
	INSERT INTO [IvrNodeResult] ([Result], [Descript], [Remark]) VALUES (110, 'CFR_NO_AVALABLE', '不可用')
END

GO
/****** Object:  StoredProcedure [dbo].[sp_sch_stat_ivr_call]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE       PROCEDURE [dbo].[sp_sch_stat_ivr_call]
	@repdate int = null,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，注：mm = 0 表示年报，dd = 0 表示月报
	@time_begin datetime = null,		-- 起始时间
	@time_end datetime = null,		-- 截止时间
	@sch_key varchar(20) = null,		-- 查询键，支持：null / flow / channel / node
	@sch_value varchar(1000) = null		-- 查询值，支持：指具体的
AS
	declare @strSQL nvarchar(3000), @strTblName varchar(20), @strWhere varchar(200)
	declare @strGroupby varchar(100), @GroupLevel int
	declare @TotalRelaField varchar(50), @RelaField varchar(50), @RepDateExp varchar(50)
	declare @strOrder varchar(50)
	declare @repdate_begin_int int, @repdate_end_int int

	if isnull(@repdate, 0) = 0 begin
		--@repdate缺省，采用@time_begin/@time_end
		if @time_begin is null
			set @time_begin = convert(varchar(10), getdate() - 6, 120) + ' 00:00:00'
		if @time_end is null
			set @time_end = convert(varchar(10), getdate(), 120) + ' 23:59:59'

		set @repdate_begin_int = dbo.datehh_to_int(@time_begin)
		set @repdate_end_int = dbo.datehh_to_int(@time_end)

		set @strWhere = ' Where (RepDate between ' + cast(@repdate_begin_int as varchar(18)) 
					  + ' and ' + cast(@repdate_end_int as varchar(18)) + ')'

		if @time_end - @time_begin <= 7
			set @GroupLevel = 0	 	--按时分组
		else
			set @GroupLevel = 2		--按日分组
	end
	else begin	--@repdate没有缺省
		if len(@repdate) < 8
			set @repdate = @repdate * power(10, 8 - len(@repdate))	--长度补足8位

		if @repdate / 100 % 100	= 0		-- mm = 0, @repdate = 20060000
			set @GroupLevel = 4			--年报，按月分组
		else if @repdate % 100 = 0		-- dd = 0, @repdate = 20060300
			set @GroupLevel = 2			--月报，按日分组
		else							-- @repdate = 20060318
			set @GroupLevel = 0			--日报，按时分组

		--注：RepDate格式yyyymmddhh, @repdate格式yyyymmdd
		set @strWhere = ' Where (RepDate / power(10, ' + cast((@GroupLevel + 2) as varchar(1)) + ')) = ' 
					  + cast((@repdate / power(10, @GroupLevel)) as varchar(20))
	end
	
	set @strGroupby = case @GroupLevel
						when 0 then	' Group By RepDate'	--时报表
						else ' Group By (RepDate / power(10, ' + cast(@GroupLevel as varchar(1)) + '))' --其他
					  end

	set @RepDateExp = substring(@strGroupby, 11, len(@strGroupby))
/*	if isnull(@flowid, 0) = 0 begin
		set @strTblName = 'stat_ivr_call'		--所有流程
	end
	else begin
		set @strTblName = 'stat_ivr_flow'		--指定流程
		set @strWhere = @strWhere + ' and (FlowId = ' + cast(@flowid as varchar(20)) + ')'
  	end*/
	set @sch_key = ltrim(rtrim(@sch_key))
	if len(@sch_key) > 0 begin
		--非null, ''
		if @sch_key not in ('flow', 'channel', 'node') begin
			raiserror('查询键，支持：null / flow / channel / node', 0, 1)
			select null
			return -1
		end
		
		set @strTblName = 'stat_ivr_' + @sch_key
		set @RelaField = case @sch_key when 'flow' then 'FlowId' when 'node' then 'NodeName' else @sch_key end
		set @strGroupby = @strGroupby + ', ' + @RelaField

		if not (@sch_value is null) begin
			set @strWhere = @strWhere + ' and (' + @RelaField + ' in (' + @sch_value + '))'
		end

		set @TotalRelaField = 'null ' + @RelaField + ', '
		set @RelaField = @RelaField + ', '
		set @strOrder = 'order by 1, 2'

	end
	else begin
		--为null or ''，所有记录
		set @strTblName = 'stat_ivr_call'
		set @RelaField = ''
		set @TotalRelaField = ''
		set @strOrder = 'order by 1'
	end

	set @strSQL = 'select '' Total:'' RepDate, ' + @TotalRelaField + 'sum(CallNum) CallNum, sum(CallTm) CallTm, '
				+ 'vxi_def.dbo.avg_int(sum(CallTm), sum(CallNum)) CallAvgTm, '
				+ 'max(MaxTm) MaxTm, max(MinTm) MinTm, sum(ExtUNum) ExtUNum, sum(ExtUTm) ExtUTm, '
				+ 'vxi_def.dbo.avg_int(sum(ExtUTm), sum(ExtUNum)) ExtUAvgTm, '
				+ 'sum(ExtINum) ExtINum, sum(ExtITm) ExtITm, '
				+ 'vxi_def.dbo.avg_int(sum(ExtITm), sum(ExtINum)) ExtIAvgTm, '
				+ 'sum(ExtDNum) ExtDNum, sum(ExtDTm) ExtDTm, '
				+ 'vxi_def.dbo.avg_int(sum(ExtDTm), sum(ExtDNum)) ExtDAvgTm '
				+ 'from ' + @strTblName + @strWhere	--合计信息
				+ ' union all '	--下面是详细数据部分
				+ 'select dbo.intdatehh_to_str(RepDate) RepDate, ' + @RelaField 
				+ 'CallNum, CallTm, CallAvgTm, MaxTm, MinTm, '
				+ 'ExtUNum, ExtUTm, ExtUAvgTm, ExtINum, ExtITm, ExtIAvgTm, ExtDNum, ExtDTm, ExtDAvgTm from ('
				+ 'select ' + @RepDateExp + ' RepDate, ' + @RelaField
				+ 'sum(CallNum) CallNum, sum(CallTm) CallTm, '
				+ 'vxi_def.dbo.avg_int(sum(CallTm), sum(CallNum)) CallAvgTm, '
				+ 'max(MaxTm) MaxTm, max(MinTm) MinTm, sum(ExtUNum) ExtUNum, sum(ExtUTm) ExtUTm, '
				+ 'vxi_def.dbo.avg_int(sum(ExtUTm), sum(ExtUNum)) ExtUAvgTm, '
				+ 'sum(ExtINum) ExtINum, sum(ExtITm) ExtITm, '
				+ 'vxi_def.dbo.avg_int(sum(ExtITm), sum(ExtINum)) ExtIAvgTm, '
				+ 'sum(ExtDNum) ExtDNum, sum(ExtDTm) ExtDTm, '
				+ 'vxi_def.dbo.avg_int(sum(ExtDTm), sum(ExtDNum)) ExtDAvgTm '
				+ 'from ' + @strTblName + @strWhere + @strGroupby
				+ ') t ' + @strOrder

	print @strSQL
	exec sp_executesql @strSQL

	return @@rowcount
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_ivr_call]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE      PROCEDURE [dbo].[sp_stat_ivr_call]
	@repdate_begin datetime = null,		-- 开始时间
	@repdate_end datetime = null		-- 结束时间
AS

declare @repdate_begin_int int, @repdate_end_int int
declare @result int

set @result = 0

if @repdate_begin is null
begin
	set @repdate_begin = getdate()
end

if @repdate_end is null
begin
	set @repdate_end = getdate()
end

set @repdate_begin_int = dbo.datehh_to_int(@repdate_begin)
set @repdate_end_int = dbo.datehh_to_int(@repdate_end)

SELECT 	dbo.datehh_to_int(StartTime) Repdate, ivrid, FlowId, isnull(Channel, '') Channel, 
		isnull(TimeLen, 0) CallTm, 
		CASE ExitType WHEN 'U' THEN 1 ELSE 0 END ExtUNum, 
		CASE ExitType WHEN 'U' THEN isnull(TimeLen, 0) ELSE 0 END ExtUTm, 
		CASE ExitType WHEN 'I' THEN 1 ELSE 0 END ExtINum, 
		CASE ExitType WHEN 'I' THEN isnull(TimeLen, 0) ELSE 0 END ExtITm, 
		CASE ExitType WHEN 'D' THEN 1 ELSE 0 END ExtDNum, 
		CASE ExitType WHEN 'D' THEN isnull(TimeLen, 0) ELSE 0 END ExtDTm
INTO #tmpivr
FROM ivrrecords WHERE StartTime between @repdate_begin and @repdate_end

--生成stat_ivr_call记录
begin tran
delete from stat_ivr_call where RepDate between @repdate_begin_int and @repdate_end_int
insert into stat_ivr_call(RepDate, CallNum, CallTm, MaxTm, MinTm, ExtUNum, ExtUTm, ExtINum, ExtITm, 
		ExtDNum, ExtDTm) 
select RepDate, count(*) CallNum, sum(CallTm), max(CallTm), min(CallTm), 
		sum(ExtUNum), sum(ExtUTm), sum(ExtINum), sum(ExtITm), sum(ExtDNum), sum(ExtDTm) 
		from #tmpivr group by RepDate
if @@Error = 0
	commit tran
else begin
	rollback tran
	set @result = 1
end

--生成stat_ivr_flow记录
begin tran
delete from stat_ivr_flow where RepDate between @repdate_begin_int and @repdate_end_int
insert into stat_ivr_flow(RepDate, FlowId, CallNum, CallTm, MaxTm, MinTm, ExtUNum, ExtUTm, ExtINum, 
      ExtITm, ExtDNum, ExtDTm) 
select RepDate, FlowId, count(*) CallNum, sum(CallTm), max(CallTm), min(CallTm), 
		sum(ExtUNum), sum(ExtUTm), sum(ExtINum), sum(ExtITm), sum(ExtDNum), sum(ExtDTm)
		from #tmpivr group by RepDate, FlowId
if @@Error = 0
	commit tran
else begin
	rollback tran
	set @result = 1
end

--生成stat_ivr_channel记录
begin tran
delete from stat_ivr_channel where RepDate between @repdate_begin_int and @repdate_end_int
insert into stat_ivr_channel(RepDate, Channel, CallNum, CallTm, MaxTm, MinTm, ExtUNum, ExtUTm, ExtINum, 
      ExtITm, ExtDNum, ExtDTm) 
select RepDate, Channel, count(*) CallNum, sum(CallTm), max(CallTm), min(CallTm), 
		sum(ExtUNum), sum(ExtUTm), sum(ExtINum), sum(ExtITm), sum(ExtDNum), sum(ExtDTm)
		from #tmpivr group by RepDate, Channel
if @@Error = 0
	commit tran
else begin
	rollback tran
	set @result = 1
end

--生成stat_ivr_node记录
begin tran
delete from stat_ivr_node where RepDate between @repdate_begin_int and @repdate_end_int
insert into stat_ivr_node(RepDate, NodeName, CallNum, CallTm, MaxTm, MinTm, ExtUNum, ExtUTm, 
      ExtINum, ExtITm, ExtDNum, ExtDTm)
select RepDate, it.NodeName, count(*) CallNum, sum(CallTm), max(CallTm), min(CallTm), 
		sum(ExtUNum), sum(ExtUTm), sum(ExtINum), sum(ExtITm), sum(ExtDNum), sum(ExtDTm) 
from #tmpivr ir 
join (select distinct ivrid, NodeName from IvrTrack) it on ir.ivrid = it.ivrid
group by RepDate, it.NodeName
if @@Error = 0
	commit tran
else begin
	rollback tran
	set @result = 1
end


--清理
drop table #tmpivr


return @result
GO
/****** Object:  StoredProcedure [dbo].[sp_stat_ivr_selection]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==========================================================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2012.9.21>
-- Description:	<查询统计IVR中客户按键呼叫数量>
-- Ehai
/* Example:
exec sp_stat_ivr_selection @DateBegin=null,@DateEnd=null,
							@TimeBegin=null, @TimeEnd=null
							,@Called=''
							,@Selection='3'
							,@Preload=1
exec sp_stat_ivr_selection @DateBegin='20120921',@DateEnd='20120921'
					,@TimeBegin='0',@TimeEnd='235959'
					,@Selection='3'
					,@Called='85583148'
*/
-- ==========================================================================
CREATE PROCEDURE [dbo].[sp_stat_ivr_selection]
	-- Add the parameters for the stored procedure here
	@DateBegin	bigint			= null,		-- 起始时间(缺省当天) 
	@DateEnd	bigint			= null,		-- 结束时间(缺省当天)
	@TimeBegin	INT				= null,
	@TimeEnd	INT				= null,
	@Called		varchar(20)		= null,
	@Selection	varchar(100)	= null,
    @Preload	bit = 0
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @Beg_LogId	bigint,
			@End_LogId	bigint
	
	set @Called = isnull(rtrim(@Called), '')		
	set @Selection = isnull(rtrim(@Selection), '')
	set @Preload = isnull(@Preload , 1)
			
	if @DateBegin is null and @DateEnd is null begin
		select @DateBegin = dbo.time_to_bigint(getdate(),1) / 10000,
				@DateEnd = dbo.time_to_bigint(getdate(),1) / 10000
	end
	
	if @TimeBegin is null and @TimeEnd is null begin
		select @TimeBegin = 0,
				@TimeEnd = 235959
	end
	
	select @Beg_LogId = @DateBegin * 1000000,
			@End_LogId = @DateEnd  * 1000000 + 999999
/*			
print @DateBegin
print @DateEnd
print @TimeBegin
print @TimeEnd			
print @Beg_LogId
print @End_LogId	
*/

	select RecRange = r.IvrId / 1000000,
			Called = r.Called,
			Selection = @Selection,
			SelectTimes = count(*)
		from vxi_ivr..IvrRecords r
		where r.IvrId between @Beg_LogId and @End_LogId
			and datepart(hour, r.StartTime) * 10000 
				+ datepart(minute, r.StartTime) * 100 
				+ datepart(second, r.StartTime) between @TimeBegin and @TimeEnd
			and (@Called = '' or charindex(@Called, '0'+ rtrim(r.Called)) > 0)
			and exists(select 1 from vxi_ivr..IvrTrack t
							where r.IvrId = t.IvrId
								and rtrim(t.Selection) = @Selection)
			and 0 = @Preload
		group by r.IvrId / 1000000, r.Called

END
GO
/****** Object:  StoredProcedure [dbo].[usp_account_verify]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


--===========================================
/*Example: 
exec usp_insert_survey @inparam1='',@inparam2='',
						@inparam3='',@outparam4=''
*/
--===========================================
CREATE PROCEDURE [dbo].[usp_account_verify] 
	@inparam1 varchar(32)='', 	-- input param
	@inparam2 varchar(32)='',	-- 
	@inparam3 varchar(32)='',	-- 
	@outparam1 varchar(32)='' output	-- return result. 1-verify pass. verify fail.		
AS
BEGIN
	set @inparam1 = rtrim(ltrim(@inparam1))
	set @inparam2 = rtrim(ltrim(@inparam2))

	--根据输入参数查询表，并设置@outparam1值，验证通过为1，失败为0

	
END

GO
/****** Object:  StoredProcedure [dbo].[usp_del_voice_mail]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example:
exec [dbo].[usp_del_voice_mail] @inparam1='100000'
*/
CREATE PROCEDURE [dbo].[usp_del_voice_mail] 
	@inparam1	varchar(20)=''		-- VoiceId
AS
	set @inparam1=isnull(@inparam1,'0')
	
	if len(@inparam1) > 0 and isnumeric(@inparam1) = 1 begin
		update VoiceMail set Status = 3 where VoiceId = @inparam1
	end
	
	return @@rowcount
GO
/****** Object:  StoredProcedure [dbo].[usp_get_new_voice_mail]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example:
exec [dbo].[usp_get_new_voice_mail] @inparam1='9000'
*/
CREATE PROCEDURE [dbo].[usp_get_new_voice_mail] 
	@inparam1	varchar(16)='',			-- Extension
	@outparam1	varchar(20)='0' output,	-- (VoiceId)
	@outparam2	varchar(120)='' output,	-- (VirtualDir)
	@outparam3	varchar(120)='' output,	-- (FileName)
	@days		int=7					-- 查询范围限定天数
AS
	set @inparam1=isnull(@inparam1,'')
	set @days=isnull(@days,7)
	
	declare @VoiceId	bigint,
			@MaxVoiceId bigint,
			@MinVoiceId bigint,
			@StartTime	datetime
	
	if len(@inparam1) > 0 begin
		-- 取值范围默认一周
		select @MaxVoiceId = max(VoiceId)
			from VoiceMail
		select @StartTime = StartTime
			from VoiceMail
			where VoiceId = @MaxVoiceId
		select @MinVoiceId = min(VoiceId)
			from VoiceMail
			where StartTime between dateadd(day,-@days,@StartTime) and @StartTime
	
	
		select @VoiceId = min(VoiceId)
			from VoiceMail
			where Extension = @inparam1
				and Status = 1
				and VoiceId between @MinVoiceId and @MaxVoiceId
				
		if @VoiceId > 0 begin
			select @outparam1 = VoiceId,
					@outparam2 = VirtualDir,
					@outparam3 = FileName
				from VoiceMail
				where VoiceId = @VoiceId
				
			update VoiceMail set Status = 2 where VoiceId = @VoiceId
		end
		else begin
			select @outparam1 = '0',@outparam2='',@outparam3=''
		end
	end
	else begin
		select @outparam1 = '0',@outparam2='',@outparam3=''
	end
	
	print @outparam1
	print @outparam2
	print @outparam3
	
	




GO
/****** Object:  StoredProcedure [dbo].[usp_get_send_fax]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[usp_get_send_fax] 
	@outparam1 int=0 output,		--return result, 1 - success, 0 - failure
	@outparam2 varchar(32)='' output,	--fax id
	@outparam3 varchar(32)='' output,	--fax number
	@outparam4 varchar(120)='' output,	--fax file name
	@inparam5  varchar(1024)=''	--dealing fax numer list
AS
set @outparam1=null
	set @outparam2=null
	set @outparam3=null
	set @outparam4=null
	update faxsend set status=1 where status=2 and DATEDIFF(minute,isnull(SendTime,StartTime),GETDATE())>=20
	update faxsend set status=3,reason=1 where status=1 and getdate()>endtime
	update faxsend set status=3,reason=2 from faxsend fs where (status=1 and trytimes>=(select trytimes from faxlevel fl where fl.levelid=fs.levelid))
	declare @count int
	select top 1 @outparam2=faxid,@outparam3=replace(called, '-', ''),@outparam4=filename from faxsend fs
		where status=1 and getdate()>=starttime and getdate()<=endtime and trytimes<(select trytimes from faxlevel where levelid=fs.levelid)
			--and replace(called, '-', '') not in (@inparam5)
			and PATINDEX('%'+replace(called, '-', '')+'%',@inparam5) = 0
		order by faxid / 1000000000, faxid % 100000	
	set @count=@@rowcount
	if @count>0
		begin
			update faxsend set trytimes=trytimes+1,status=2 where faxid=@outparam2
			set @outparam1=1
		end
	set @outparam1=isnull(@outparam1,0)
	set @outparam2=isnull(@outparam2,'')
	set @outparam3=isnull(@outparam3,'')
	set @outparam4=isnull(@outparam4,'')
	print @outparam1
	print @outparam2
	print @outparam3
	print @outparam4

GO
/****** Object:  StoredProcedure [dbo].[usp_get_voice_mail_count]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example:
exec [dbo].[usp_get_voice_mail_count] @inparam1='9000'
*/
CREATE PROCEDURE [dbo].[usp_get_voice_mail_count] 
	@inparam1	varchar(16)='',			-- Extension
	@outparam1	varchar(5)='0' output,	-- (return count)
	@days		int=7					-- 查询范围限定天数
AS
	set @inparam1=isnull(@inparam1,'')
	set @days=isnull(@days,7)
	
	declare @MaxVoiceId bigint,
			@MinVoiceId bigint,
			@StartTime	datetime
	
	if len(@inparam1) > 0 begin
		-- 取值范围默认一周
		select @MaxVoiceId = max(VoiceId)
			from VoiceMail
		select @StartTime = StartTime
			from VoiceMail
			where VoiceId = @MaxVoiceId
		select @MinVoiceId = min(VoiceId)
			from VoiceMail
			where StartTime between dateadd(day,-@days,@StartTime) and @StartTime
		
		select @outparam1 = count(*)
			from VoiceMail
			where Extension = @inparam1
				and Status = 1
				and VoiceId between @MinVoiceId and @MaxVoiceId
				
		set @outparam1 = isnull(@outparam1, '0')
	end
	else begin
		set @outparam1 = '0'
	end
	
	print @outparam1
GO
/****** Object:  StoredProcedure [dbo].[usp_insert_recv_fax]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_insert_recv_fax] 
	@inparam1 int=0,	-- client id
	@inparam2 varchar(32)='',	-- calling
	@inparam3 varchar(32)='',	-- called
	@inparam4 varchar(32)='',	-- callid
	@inparam5 varchar(32)='',	-- channel id
	@inparam6 varchar(120)=''	-- fax file name
AS
	set @inparam1=isnull(@inparam1,0)
	if (@inparam1>0)
		begin
			declare @maxid int
			select @maxid=max(faxid % 100000) from faxrecv where ((faxid % 1000000000) / 100000)=@inparam1 and (faxid / 1000000000)=cast(convert(varchar(20), getdate(), 112) as bigint)
			set @maxid=isnull(@maxid,0)
			set @maxid=@maxid+1
			declare @faxid bigint
			set @faxid=cast(convert(varchar(20), getdate(), 112) as bigint) * 1000000000 + @inparam1 * 100000 + @maxid
			insert into faxrecv values(@faxid,@inparam2,@inparam3,@inparam4,@inparam5,@inparam6,getdate(),11,0)
		end




GO
/****** Object:  StoredProcedure [dbo].[usp_insert_survey]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--===========================================
/*Example: 
exec usp_insert_survey @inparam1='',@inparam2='',
                     @inparam3='',@inparam4='',
                     @inparam5='',@inparam6='',
                     @inparam7='',@inparam8=''
*/
--===========================================
CREATE PROCEDURE [dbo].[usp_insert_survey] 
    @inparam1 varchar(32)='',   -- Dtmf(Survey dtmf)
    @inparam2 varchar(32)='',   -- ucdid
    @inparam3 varchar(32)='',   -- (devid)channelid
    @inparam4 varchar(32)='',   -- agent   
    @inparam5 varchar(32)='',   -- calling
    @inparam6 varchar(32)='',   -- called
    @inparam7 varchar(32)='',   -- callid
    @inparam8 varchar(32)='',   -- starttime
    @inparam9 varchar(32)='',   -- ucid
    @inparam10 varchar(100)=''  -- uui
AS
BEGIN
    declare @maxid       bigint,
           @RecId     bigint,
           @SurveyResult varchar(32)

    set @inparam1 = rtrim(ltrim(@inparam1))
    set @inparam2 = rtrim(ltrim(@inparam2))
    select @maxid = max(surveyid) from survey
    select @maxid = dbo.func_newid(@maxid)

    insert into survey (surveyid,ucdid,devid,agent,dtmf,calling,called,callid,starttime,ucid,uui) 
           values(@maxid,@inparam2,@inparam3,@inparam4,@inparam1,@inparam5,@inparam6,@inparam7,GETDATE(),@inparam9,@inparam10)

    --select @RecordId = RecordId from VisionLog.dbo.Records where ucid = @inparam9 and startdate=getdate()  
    
    Select @SurveyResult = Description From SurveyResult Where convert(varchar(32), ResultID) = @inparam1
   -- select @RecId = RecordId from vxi_rec.dbo.Records where UcdId = @inparam2

	Insert Into vxi_rec.dbo.RecExts(RecordId,Item01) 
		select m.RecordId, @SurveyResult
			from vxi_rec.dbo.Records m
			where UcdId = @inparam2
				and @inparam2 > CAST(0 as bigint)
				and not exists(select 1 from vxi_rec.dbo.RecExts s
								where s.RecordId = m.RecordId)

END

GO
/****** Object:  StoredProcedure [dbo].[usp_insert_voice_mail]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_insert_voice_mail] 
	@inparam1 varchar(32)='',	-- Project ID
	@inparam2 varchar(32)='',	-- calling
	@inparam3 varchar(32)='',	-- called
	@inparam4 varchar(32)='',	-- callid
	@inparam5 varchar(32)='',	-- extension
	@inparam6 varchar(120)='',	-- virtual directory(ivr storage name)
	@inparam7 varchar(120)='',	-- voice file name
	@inparam8 varchar(120)='',	-- Server address(ip:port, voice file server)
	@inparam9 varchar(32)='',	-- start time
	@inparam10 varchar(32)=''	-- length(s)	
AS

BEGIN

declare @maxid bigint
select @maxid = max(VoiceID) from voicemail
select @maxid = dbo.func_newid(@maxid)
		
insert into voicemail (voiceid,prjid,calling,called,callid,extension,virtualdir,[filename],serveraddr,starttime,length,status,reason)
				values(@maxid,@inparam1,@inparam2,@inparam3,@inparam4,@inparam5,@inparam6,@inparam7,@inparam8,@inparam9,@inparam10,1,0)
							
END


GO
/****** Object:  StoredProcedure [dbo].[usp_search_voice_mail]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================
-- Author:		YiBin WU
-- Create date: 2011.05.17
-- Description: VoiceMail记录查找
/* Example:
exec usp_search_voice_mail @voiceid=20110530000001,
							@time_begin='2011-05-16 12:12:33.797',
							@time_end='2011-05-16 14:12:33.797',
							@status=1,
							@calling='123456789'
*/
-- =========================================================================
CREATE PROCEDURE [dbo].[usp_search_voice_mail]
	@voiceid	bigint		= null,	-- 记录号
	@time_begin	datetime	= null,	-- 起始时间
	@time_end	datetime	= null,	-- 截止时间
	@status		tinyint		= null,	-- 状态值，如：1-新留言；2-已听留言；3-已删除
	@calling	varchar(24) = null	-- 主叫代码
AS

BEGIN
	declare @Beg_VoiceID	bigint,
			@End_VoiceID	bigint,
			@MaxLines		int,
			@StrSql			varchar(1000)

	set @MaxLines = 100
				
	if @voiceid is null and (@time_begin is null or @time_end is null) begin
		if @time_begin is null begin
			set @time_begin = convert(varchar(10), getdate(), 120) + ' 00:00:00'
			set @Beg_VoiceID = cast(dbo.func_today() as bigint) * 1000000
		end
		else begin
			set @Beg_VoiceID = cast(dbo.func_day(@time_begin) as bigint) * 1000000
		end
		
		if @time_end is null begin
			set @time_end = convert(varchar(10), getdate(), 120) + ' 23:59:59'
			set @End_VoiceID = cast(dbo.func_today() as bigint) * 1000000 + 999999
		end
		else begin
			set @End_VoiceID = cast(dbo.func_day(@time_end) as bigint) * 1000000 + 999999
		end
	end

	set @StrSql = '	select top(' + str(@MaxLines) + ')' + '	
				[VoiceID]
				,[PrjID]
				,[CustomerID]
				,[Calling]
				,[Called]
				,[CallID]
				,[ChannelID]
				,[Agent]
				,[Extension]
				,[Skill]
				,[VirtualDir]
				,[FileName]
				,[ServerAddr]
				,[StartTime]
				,[Length]
				,[ReadTime]
				,[Status]
				,[Reason]
			from VoiceMail
			where 0 = 0'

	set @voiceid = isnull(@voiceid, 0)
			
	if @voiceid > 0 begin
		set @StrSql = @StrSql + ' and VoiceId > ' + convert(varchar(16), @voiceid)
	end
	
	if @Beg_VoiceID > 0 and @End_VoiceID > 0 begin
		set @StrSql = @StrSql + ' and VoiceId between ' + convert(varchar(16), @Beg_VoiceID)
						+ ' and ' + convert(varchar(16), @End_VoiceID)
	end
	
	if @time_begin is not null and @time_end is not null begin
		set @StrSql = @StrSql + ' and StartTime between ''' + convert(varchar, @time_begin, 121)
						+ ''' and ''' + convert(varchar, @time_end, 121) + ''''
	end
	
	if @status is not null begin
		set @StrSql = @StrSql + ' and Status = ' + str(@status)
	end
	
	if len(@calling) > 0 begin
		set @StrSql = @StrSql + ' and calling = ''' + @calling + ''''
	end

	--print @StrSql
	exec(@StrSql)
			
	return @@rowcount

END
GO
/****** Object:  StoredProcedure [dbo].[usp_update_send_fax]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_update_send_fax]
	@inparam1 int=2,		--result 1-success,0-failure
	@inparam2 varchar(32)='',	--faxid
	@inparam3 varchar(32)='',	--calling
	@inparam4 varchar(32)='',	--callid
	@inparam5 varchar(32)='',	--channel id
	@inparam6 int=0		--reason
 AS
	if @inparam1=1
		begin
			update faxsend set calling=@inparam3,callid=@inparam4,channelid=@inparam5,sendtime=getdate(),status=4,reason=@inparam6 where faxid=@inparam2
		end
	else if @inparam1=0
		begin
			update faxsend set calling=@inparam3,callid=@inparam4,channelid=@inparam5,sendtime=getdate(),status=1,reason=@inparam6 where faxid=@inparam2
		end
	print @inparam1
	print @inparam2
	print @inparam3
	print @inparam4
	print @inparam5
	print @inparam6
GO
/****** Object:  StoredProcedure [dbo].[usp_update_voice_mail]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
-- =========================================================================
-- Author:		YiBin WU
-- Create date: 2011.05.17
-- Description: VoiceMail记录修改
/* Example:
exec usp_update_voice_mail @voiceid=123456789,@customerid='000123',
							@agent='1234',@extension='5678',
							@skill='6789',@readtime='2011-05-16 15:11:39.903',
							@status=2,@reason=100
*/
-- =========================================================================
CREATE PROCEDURE [dbo].[usp_update_voice_mail]
	@voiceid	bigint,				-- 记录代码
	@customerid	varchar(24)	= null,	-- 客户代码
	@agent		varchar(16)	= null,	-- 坐席代码
	@extension	varchar(16)	= null, -- 分机代码
	@skill		varchar(16) = null, -- 技能代码
	@readtime	datetime	= null, -- 读取时间
	@status		tinyint		= null,	-- 状态值，如：1-新留言；2-已听留言；3-已删除
	@reason		tinyint		= null	-- 原因值
AS

BEGIN
	declare @StrSql		varchar(2000),
			@bValid		bit
	
	set @bValid = 0
	if exists(select 1 from VoiceMail where VoiceID = @voiceid) begin
		set @StrSql = 'Update VoiceMail set '
		
		if len(@customerid) > 0 begin
			set @StrSql = @StrSql + 'CustomerID = ''' + @customerid + ''','
			set @bValid = 1
		end
		
		if len(@agent) > 0 begin
			set @StrSql = @StrSql + 'Agent = ''' + @agent + ''','
			set @bValid = 1
		end
		
		if len(@extension) > 0 begin
			set @StrSql = @StrSql + 'Extension = ''' + @extension + ''','
			set @bValid = 1
		end
		
		if len(@skill) > 0 begin
			set @StrSql = @StrSql + 'Skill = ''' + @skill + ''','
			set @bValid = 1
		end
		
		if @readtime is not null begin
			set @StrSql = @StrSql + 'ReadTime = ''' + convert(varchar, @readtime, 120) + ''','
			set @bValid = 1
		end
		
		if @status is not null begin
			set @StrSql = @StrSql + 'Status = ' + str(@status) + ','
			set @bValid = 1
		end
		
		if @reason is not null begin
			set @StrSql = @StrSql + 'Reason = ' + str(@reason) + ','
			set @bValid = 1
		end
		
		if @bValid = 1 begin
			select @StrSql = left(@StrSql, len(@StrSql) - 1)
							+ ' Where VoiceID = ' + convert(varchar(16), @voiceid)
			--print @StrSql
			exec(@StrSql)
		end
	end
			
	return @@rowcount

END
GO
/****** Object:  UserDefinedFunction [dbo].[datehh_to_int]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create    FUNCTION [dbo].[datehh_to_int] (@Date datetime)
RETURNS int AS  
BEGIN 
	return dbo.datehhstr_to_int(CONVERT(varchar(13), @Date, 120))
END




GO
/****** Object:  UserDefinedFunction [dbo].[datehhstr_to_int]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--yyyy-mm-dd hh

create    FUNCTION [dbo].[datehhstr_to_int] (@strDate varchar(13))
RETURNS int AS  
BEGIN 
	return left(@strDate, 4) + substring(@strDate, 6, 2) + substring(@strDate, 9, 2) + right(@strDate, 2)
END




GO
/****** Object:  UserDefinedFunction [dbo].[datetimeInt_to_Varchar]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Summit.lau
-- Create date: 2011.09.23
-- Description:	把整型日期转成日期字符型
-- =============================================
CREATE  FUNCTION [dbo].[datetimeInt_to_Varchar] (@dt BIGINT)
RETURNS VARCHAR(10) 
AS
BEGIN
	-- Declare the return variable here
	DECLARE @GetDate VARCHAR(30)	
	SELECT @GetDate = LEFT(@dt,4) + '-' + SUBSTRING(STR(@dt),3,2) + '-' + RIGHT(@dt,2)
	
	-- Return the result of the function
	RETURN @GetDate

END

GO
/****** Object:  UserDefinedFunction [dbo].[func_day]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[func_day] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END

GO
/****** Object:  UserDefinedFunction [dbo].[func_newid]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ==============================================
-- Author:		WuYiBin
-- Create date: 2011.05.17
-- Description:	获取表中最大编号值
-- Example: select dbo.func_newid(20110517000001)
-- ==============================================
CREATE FUNCTION [dbo].[func_newid]
(
 @maxid	bigint
)
RETURNS bigint
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ID		bigint, 
			@today	int, 
			@baseid bigint
			
	select @today = dbo.func_today()
	select @baseid = cast(@today as bigint) * 1000000
	set @maxid = isnull(@maxid, @baseid)
	
	if @maxid >= @baseid and @maxid < (@baseid + 999999) begin
		set @ID = @maxid + 1
	end
	else begin
		set @ID = @baseid + 1
	end

	RETURN @ID

END
GO
/****** Object:  UserDefinedFunction [dbo].[func_today]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[func_today] ()
RETURNS int AS  
BEGIN 
	return year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate())
END


GO
/****** Object:  UserDefinedFunction [dbo].[intdate_to_str]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[intdate_to_str](@Date bigint)
RETURNS varchar(16) AS  
BEGIN 
	return dbo.strdate_to_str(@Date)
END


GO
/****** Object:  UserDefinedFunction [dbo].[intdatehh_to_str]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE             FUNCTION [dbo].[intdatehh_to_str] (@Date int)
RETURNS varchar(16) AS  
BEGIN 
	declare @datelen int
	declare @strDate varchar(10)
	declare @result varchar(16)

	set @strDate = @Date
	set @datelen = len(@strDate)
	set @result = ''

	if @datelen >= 10 begin	--yyyymmddhh
		set @result = substring(@strDate, 9, 2) + ':00'
		goto L_ADD_YEAR
	end
	else if @datelen >= 8 begin --yyyymmdd
L_ADD_YEAR:
		set @result = substring(@strDate, 7, 2) + ' ' + @result	
		goto L_ADD_MONTH
	end
	else if @datelen >= 6 begin	--yyyymm
L_ADD_MONTH:
		set @result = substring(@strDate, 5, 2) + '-' + @result
	end	
	set @result = left(@strDate, 4) + '-' + @result
	
	return case when @datelen > 6 then
					@result
				else 
					left(@result, len(@result) - 1) 
		   end

END










GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_time]    Script Date: 2016/9/5 13:28:27 ******/
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
/****** Object:  UserDefinedFunction [dbo].[strdate_to_str]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[strdate_to_str](@strDate varchar(12))
RETURNS varchar(16) AS  
BEGIN 
	declare @datelen int
--	declare @strDate varchar(12)
	declare @result varchar(16)

--	set @strDate = @Date
	set @datelen = len(@strDate)
	set @result = ''

	if @datelen >= 12 begin	--yyyymmddhhmm
		set @result = ':' + substring(@strDate, 11, 2)
		goto L_ADD_HOUR
	end
	if @datelen >= 10 begin	--yyyymmddhh
		set @result = ':00'
L_ADD_HOUR:
		set @result = substring(@strDate, 9, 2) + @result
		goto L_ADD_YEAR
	end
	else if @datelen >= 8 begin --yyyymmdd
L_ADD_YEAR:
		set @result = substring(@strDate, 7, 2) + ' ' + @result	
		goto L_ADD_MONTH
	end
	else if @datelen >= 6 begin	--yyyymm
L_ADD_MONTH:
		set @result = substring(@strDate, 5, 2) + '-' + @result
	end	
	set @result = left(@strDate, 4) + '-' + @result
	
	return case when @datelen > 6 then
					@result
				else 
					left(@result, len(@result) - 1) 
		   end

END
GO
/****** Object:  UserDefinedFunction [dbo].[time_to_bigint]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE  FUNCTION [dbo].[time_to_bigint] (@time datetime, @unit int)
RETURNS bigint AS
BEGIN 

	declare @result bigint, @idate bigint, @itime bigint

	select  @idate = year(@time) * 10000 + month(@time) * 100 + day(@time), 
			@itime = datepart(hour, @time) * 100 + datepart(minute, @time) / @unit * @unit

	select @result = 10000 * @idate + @itime
	return @result
END


GO
/****** Object:  Table [dbo].[Evaluate_Satisfaction]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Evaluate_Satisfaction](
	[RecDate] [int] NOT NULL,
	[Agent] [varchar](20) NOT NULL,
	[AgentName] [varchar](50) NULL,
	[Ans_n] [int] NULL,
	[TransOut_n] [int] NULL,
	[Enter_n] [int] NULL,
	[Enter_p] [int] NULL,
	[Evaluation_n] [int] NULL,
	[Evaluation_p] [float] NULL,
	[Enter_Evaluation_p] [float] NULL,
	[1] [int] NULL,
	[2] [int] NULL,
	[3] [int] NULL,
	[1_p] [float] NULL,
	[2_p] [float] NULL,
	[3_p] [float] NULL,
	[DateTime] [datetime] NULL,
 CONSTRAINT [PK_Evaluate_Satisfaction] PRIMARY KEY CLUSTERED 
(
	[RecDate] ASC,
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxCategory]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxCategory](
	[CategoryID] [tinyint] NOT NULL,
	[CategoryName] [varchar](50) NULL,
 CONSTRAINT [PK_FaxCategory] PRIMARY KEY CLUSTERED 
(
	[CategoryID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxClient]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxClient](
	[ClientID] [int] NOT NULL,
	[ClientName] [varchar](64) NOT NULL,
	[Password] [varchar](32) NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
 CONSTRAINT [PK_FaxClient] PRIMARY KEY CLUSTERED 
(
	[ClientID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxLevel]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxLevel](
	[LevelID] [tinyint] NOT NULL,
	[TryTimes] [tinyint] NOT NULL,
	[LevelDesc] [varchar](50) NULL,
 CONSTRAINT [PK_FaxLevel] PRIMARY KEY CLUSTERED 
(
	[LevelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxReason]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxReason](
	[Reason] [tinyint] NOT NULL,
	[ReasonKey] [varchar](50) NULL,
	[ReasonDesc] [varchar](120) NULL,
 CONSTRAINT [PK_FaxReason] PRIMARY KEY CLUSTERED 
(
	[Reason] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxRecv]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxRecv](
	[FaxID] [bigint] NOT NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[CallID] [int] NULL,
	[ChannelID] [varchar](16) NULL,
	[FileName] [varchar](120) NULL,
	[RecvTime] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[Reason] [tinyint] NULL,
 CONSTRAINT [PK_FaxRecv] PRIMARY KEY CLUSTERED 
(
	[FaxID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxSend]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxSend](
	[FaxID] [bigint] NOT NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[CallID] [int] NULL,
	[ChannelID] [varchar](16) NULL,
	[FileName] [varchar](120) NOT NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[SendTime] [datetime] NULL,
	[LevelID] [tinyint] NULL,
	[CategoryID] [tinyint] NULL,
	[TryTimes] [tinyint] NULL,
	[Status] [tinyint] NOT NULL,
	[Reason] [tinyint] NULL,
 CONSTRAINT [PK_FaxSend] PRIMARY KEY CLUSTERED 
(
	[FaxID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FaxStatus]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FaxStatus](
	[Status] [tinyint] NOT NULL,
	[StatusKey] [varchar](50) NULL,
	[StatusDesc] [varchar](120) NULL,
 CONSTRAINT [PK_FaxStatus] PRIMARY KEY CLUSTERED 
(
	[Status] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IvrFlow]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IvrFlow](
	[FlowId] [int] NOT NULL,
	[FlowName] [varchar](50) NULL,
	[FlowFile] [varchar](100) NULL,
 CONSTRAINT [PK_IvrFlow] PRIMARY KEY CLUSTERED 
(
	[FlowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_IvrFlow] UNIQUE NONCLUSTERED 
(
	[FlowName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IvrNodeResult]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IvrNodeResult](
	[Result] [int] NOT NULL,
	[Descript] [varchar](20) NOT NULL,
	[Remark] [varchar](50) NULL,
 CONSTRAINT [PK_IvrNodeResult] PRIMARY KEY CLUSTERED 
(
	[Result] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IvrNodeType]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IvrNodeType](
	[FlowId] [int] NOT NULL,
	[NodeName] [varchar](50) NOT NULL,
	[NodeType] [varchar](50) NULL,
 CONSTRAINT [PK_IvrNodeType] PRIMARY KEY CLUSTERED 
(
	[FlowId] ASC,
	[NodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IvrRecords]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IvrRecords](
	[IvrId] [bigint] NOT NULL,
	[FlowId] [int] NOT NULL,
	[UcdId] [bigint] NULL,
	[CallId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Channel] [varchar](20) NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[ExitType] [char](1) NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
 CONSTRAINT [PK_IvrRecords] PRIMARY KEY NONCLUSTERED 
(
	[IvrId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IvrTrack]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IvrTrack](
	[IvrId] [bigint] NOT NULL,
	[SubId] [smallint] NOT NULL,
	[NodeName] [varchar](50) NULL,
	[Selection] [varchar](100) NULL,
	[Enter] [int] NULL,
	[Leave] [int] NULL,
	[Result] [int] NULL,
 CONSTRAINT [PK_IvrTrack] PRIMARY KEY CLUSTERED 
(
	[IvrId] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[IvrTypes]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[IvrTypes](
	[TypeSort] [char](20) NOT NULL,
	[TypeKey] [char](10) NOT NULL,
	[TypeValue] [varchar](50) NULL,
 CONSTRAINT [PK_IvrTypes] PRIMARY KEY CLUSTERED 
(
	[TypeSort] ASC,
	[TypeKey] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_ivr_call]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stat_ivr_call](
	[RepDate] [int] NOT NULL,
	[CallNum] [int] NULL,
	[CallTm] [int] NULL,
	[MaxTm] [int] NULL,
	[MinTm] [int] NULL,
	[ExtUNum] [int] NULL,
	[ExtUTm] [int] NULL,
	[ExtINum] [int] NULL,
	[ExtITm] [int] NULL,
	[ExtDNum] [int] NULL,
	[ExtDTm] [int] NULL,
 CONSTRAINT [PK_stat_ivr_call] PRIMARY KEY CLUSTERED 
(
	[RepDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[stat_ivr_channel]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_ivr_channel](
	[RepDate] [int] NOT NULL,
	[Channel] [varchar](20) NOT NULL,
	[CallNum] [int] NULL,
	[CallTm] [int] NULL,
	[MaxTm] [int] NULL,
	[MinTm] [int] NULL,
	[ExtUNum] [int] NULL,
	[ExtUTm] [int] NULL,
	[ExtINum] [int] NULL,
	[ExtITm] [int] NULL,
	[ExtDNum] [int] NULL,
	[ExtDTm] [int] NULL,
 CONSTRAINT [PK_stat_ivr_channel] PRIMARY KEY CLUSTERED 
(
	[RepDate] ASC,
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[stat_ivr_flow]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[stat_ivr_flow](
	[RepDate] [int] NOT NULL,
	[FlowId] [int] NOT NULL,
	[CallNum] [int] NULL,
	[CallTm] [int] NULL,
	[MaxTm] [int] NULL,
	[MinTm] [int] NULL,
	[ExtUNum] [int] NULL,
	[ExtUTm] [int] NULL,
	[ExtINum] [int] NULL,
	[ExtITm] [int] NULL,
	[ExtDNum] [int] NULL,
	[ExtDTm] [int] NULL,
 CONSTRAINT [PK_stat_ivr_flow] PRIMARY KEY CLUSTERED 
(
	[RepDate] ASC,
	[FlowId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[stat_ivr_node]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[stat_ivr_node](
	[RepDate] [int] NOT NULL,
	[NodeName] [varchar](50) NOT NULL,
	[CallNum] [int] NULL,
	[CallTm] [int] NULL,
	[MaxTm] [int] NULL,
	[MinTm] [int] NULL,
	[ExtUNum] [int] NULL,
	[ExtUTm] [int] NULL,
	[ExtINum] [int] NULL,
	[ExtITm] [int] NULL,
	[ExtDNum] [int] NULL,
	[ExtDTm] [int] NULL,
 CONSTRAINT [PK_stat_ivr_node] PRIMARY KEY CLUSTERED 
(
	[RepDate] ASC,
	[NodeName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Survey]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Survey](
	[SurveyID] [bigint] NOT NULL,
	[UcdID] [bigint] NULL,
	[DevID] [varchar](8) NULL,
	[Agent] [varchar](8) NULL,
	[Dtmf] [varchar](23) NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[CallID] [varchar](50) NULL,
	[StartTime] [datetime] NULL,
	[CallStartTime] [datetime] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[RecID] [bigint] NULL,
 CONSTRAINT [PK_Survey] PRIMARY KEY CLUSTERED 
(
	[SurveyID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SurveyResult]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SurveyResult](
	[ResultID] [int] NOT NULL,
	[OrderId] [tinyint] NOT NULL,
	[Description] [varchar](50) NULL,
 CONSTRAINT [PK_SurveyResult] PRIMARY KEY CLUSTERED 
(
	[ResultID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[test_fax_table]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[test_fax_table](
	[faxid] [int] NOT NULL,
	[enabled] [bit] NOT NULL,
	[dnis] [varchar](50) NULL,
	[voicetype] [bit] NULL,
 CONSTRAINT [PK_test_fax_table] PRIMARY KEY CLUSTERED 
(
	[faxid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VoiceMail]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VoiceMail](
	[VoiceID] [bigint] NOT NULL,
	[PrjID] [int] NULL,
	[CustomerID] [varchar](24) NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[CallID] [int] NULL,
	[ChannelID] [varchar](16) NULL,
	[Agent] [varchar](16) NULL,
	[Extension] [varchar](16) NULL,
	[Skill] [varchar](16) NULL,
	[VirtualDir] [varchar](120) NOT NULL,
	[FileName] [varchar](120) NOT NULL,
	[ServerAddr] [varchar](24) NULL,
	[StartTime] [datetime] NULL,
	[Length] [int] NULL,
	[ReadTime] [datetime] NULL,
	[Status] [tinyint] NOT NULL,
	[Reason] [tinyint] NULL,
 CONSTRAINT [PK_VoiceMail] PRIMARY KEY CLUSTERED 
(
	[VoiceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VoiceStatus]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VoiceStatus](
	[StatusID] [tinyint] NOT NULL,
	[Description] [varchar](100) NULL,
 CONSTRAINT [PK_VoiceStatus] PRIMARY KEY CLUSTERED 
(
	[StatusID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[IvrRecords_view]    Script Date: 2016/9/5 13:28:27 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[IvrRecords_view]
AS
SELECT     IvrId, FlowId AS IvrFlow, UcdId, CallId, Calling, Called, Channel, StartTime, TimeLen, ExitType, UCID, UUI
FROM         dbo.IvrRecords

GO
ALTER TABLE [dbo].[IvrNodeType]  WITH CHECK ADD  CONSTRAINT [FK_IvrNodeType_IvrFlow] FOREIGN KEY([FlowId])
REFERENCES [dbo].[IvrFlow] ([FlowId])
GO
ALTER TABLE [dbo].[IvrNodeType] CHECK CONSTRAINT [FK_IvrNodeType_IvrFlow]
GO
ALTER TABLE [dbo].[IvrRecords]  WITH CHECK ADD  CONSTRAINT [FK_IvrRecords_IvrFlow] FOREIGN KEY([FlowId])
REFERENCES [dbo].[IvrFlow] ([FlowId])
GO
ALTER TABLE [dbo].[IvrRecords] CHECK CONSTRAINT [FK_IvrRecords_IvrFlow]
GO
ALTER TABLE [dbo].[IvrTrack]  WITH NOCHECK ADD  CONSTRAINT [FK_IvrTrack_IvrRecords] FOREIGN KEY([IvrId])
REFERENCES [dbo].[IvrRecords] ([IvrId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[IvrTrack] CHECK CONSTRAINT [FK_IvrTrack_IvrRecords]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'类型分类' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'IvrTypes', @level2type=N'COLUMN',@level2name=N'TypeSort'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'类型关键字' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'IvrTypes', @level2type=N'COLUMN',@level2name=N'TypeKey'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'类型描述' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'IvrTypes', @level2type=N'COLUMN',@level2name=N'TypeValue'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[39] 4[22] 2[20] 3) )"
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
         Begin Table = "IvrRecords"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 321
               Right = 435
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'IvrRecords_view'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'IvrRecords_view'
GO
