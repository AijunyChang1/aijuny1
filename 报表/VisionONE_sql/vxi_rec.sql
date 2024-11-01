USE [master]
GO
CREATE DATABASE [vxi_rec]
GO

USE [vxi_rec]
GO
/****** Object:  DatabaseRole [ba]    Script Date: 2016/9/5 13:24:59 ******/
CREATE ROLE [ba]
GO
/****** Object:  Schema [asr]    Script Date: 2016/9/5 13:24:59 ******/
CREATE SCHEMA [asr]
GO
/****** Object:  FullTextCatalog [RecAsr]    Script Date: 2016/9/5 13:24:59 ******/
CREATE FULLTEXT CATALOG [RecAsr]WITH ACCENT_SENSITIVITY = ON

GO
/****** Object:  StoredProcedure [asr].[sp_get_pkginfo]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		WuYiBin
-- Create date: 2010.8.20
-- Description:	获取包中包含的词及语句列表
-- Example: exec asr.sp_get_pkginfo @PkgID = 2
-- =============================================
CREATE PROCEDURE [asr].[sp_get_pkginfo]
	@PkgID int = 0
AS
BEGIN
	declare @Sql_Words		varchar(max)
	declare @Sql_Clauses	varchar(max)

	declare @T_PkgID table(PkgID int)
	declare @T_Result table(PkgID int, WordList varchar(max), ClauseList varchar(max))
	
	insert into @T_PkgID(PkgID)
		select PkgID from Package
			where PkgID = case when @PkgID > 0 then @PkgID else PkgID end
				and Enabled = 1

	set @PkgID = 0
	select @PkgID = min(PkgID) from @T_PkgID where PkgID > @PkgID
	While @PkgID is not null begin
		select @Sql_Words = '', @Sql_Clauses = ''
		select @Sql_Words = @Sql_Words + w.Word + ';'
			from asr.Package p, asr.Word w
			where ',' + rtrim(p.Words) + ',' like '%,' + rtrim(w.WordID) + ',%'
				and p.PkgID = @PkgID
				and p.Enabled = 1
				and w.Enabled = 1

		/*
		select @Sql_Clauses = @Sql_Clauses + c.Clause + ';'
			from asr.Package p, asr.Clause c
			where ',' + rtrim(p.Clauses) + ',' like '%,' + rtrim(c.ClauseID) + ',%'
				and p.PkgID = @PkgID
				and p.Enabled = 1
				and c.Enabled = 1
		*/

		insert into @T_Result(PkgID, WordList, ClauseList)
			select @PkgID, @Sql_Words, @Sql_Clauses

		select @PkgID = min(PkgID) from @T_PkgID where PkgID > @PkgID
	end

	select * from @T_Result

END



GO
/****** Object:  StoredProcedure [dbo].[sp_add_asr_result]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- ============================================================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2013.4.19>
-- Description:	<Description,,>
/* Example: 
exec sp_add_asr_result @recordid=20121120000024
						,@asrflag=2
						,@asrresult='@asrresult@asrresult'
						,@confidence=15
*/
-- ============================================================================
CREATE PROCEDURE [dbo].[sp_add_asr_result]
	@recordid		bigint		= 0,
	@asrflag		int		    = 0,
	@asrresult		text		= null,
	@confidence		smallint	= null
AS
BEGIN
	set @asrflag = isnull(@asrflag, 0)
	
	declare @flag tinyint

	select @flag = case when @asrflag & 1 <> 0 then 1
						when @asrflag & 2 <> 0 then 2
						when @asrflag & 4 <> 0 then 4
					end

	if @flag = 1 begin
		update recasr set asrresult = @asrresult ,
							confidence = @confidence
			where recordid = @recordid
		
		if @@rowcount = 0 begin
			insert into recasr(recordid,asrresult,confidence) values(@recordid,@asrresult,@confidence)
		end
		
		print 'asrflag(1) success!'
	end
	
	if @flag = 2 begin
		update recasr set asrresulta = @asrresult,
							confidencea = @confidence
			where recordid = @recordid
		
		if @@rowcount = 0 begin
			insert into recasr(recordid,asrresulta,confidencea) 
				values(@recordid,@asrresult,@confidence)
		end
		
		print 'asrflag(2) success!'
	end
	
	if @flag = 4 begin
		update recasr set asrresultb = @asrresult,
							confidenceb = @confidence
			where recordid = @recordid
		
		if @@rowcount = 0 begin
			insert into recasr(recordid,asrresultb,confidenceb) 
				values(@recordid,@asrresult,@confidence)
		end
		
		print 'asrflag(4) success!'
	end 
	
END






GO
/****** Object:  StoredProcedure [dbo].[sp_asr_Report]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* Example: 
exec sp_asr_Report_old1 @DateBegin='20111110' ,@DateEnd='20130505',@word='1'
*/
CREATE PROCEDURE [dbo].[sp_asr_Report]
	@RecDate	INT = NULL,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
									-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	BIGINT = NULL,
	@DateEnd	BIGINT = NULL,
	@Skill		VARCHAR(20) = NULL,		
	@SkillGroup INT = NULL,
	@ProjectId	INT = NULL,
	@Agent		VARCHAR(20) = NULL,
	@word		VARCHAR(20) = NULL,
	@Preload	BIT = 0			-- 仅预览表标题		
AS
BEGIN

	;WITH cte0 as(
				SELECT A.recordid,B.word,B.wordid
				FROM vxi_rec..recasr A,
					 vxi_rec..RepWords B 
				WHERE b.enabled=1 and ( charindex(B.word,asrresult)!=0 or  charindex(B.word,asrresulta)!=0 or  charindex(B.word,asrresultb)!=0 )
		),cte as(
				select M.RecordId,M.Skill,M.Agent,M.StartTime,M.StartDate,
					N.WORD,N.WORDID,rownum = COUNT(*) OVER (partition by M.AGENT,M.SKILL,M.StartDate )
					from vxi_rec..records M 
					left join cte0 N on M.recordid=N.recordid 
					where M.StartDate between @DateBegin and @DateEnd
		),cte1 as(
				select SKILL,AGENT,STARTDATE,WORD,WORDID,COUNT(*) OCC,(MAX(ROWNUM)-COUNT(*)) NCC,MAX(ROWNUM) ACC,dbo.avg_str(COUNT(*),MAX(ROWNUM),1) AS Normal from cte A GROUP BY SKILL,AGENT,STARTDATE,WORD,WORDID
		)
		
	select STARTDATE,AGENT,SKILL,WORD,OCC,NCC,ACC,Normal from cte1 outter
		where	 outter.skill = case when len(@Skill) > 0 then @Skill else outter.skill end
			AND  outter.agent = case when len(@Agent) > 0 then @Agent else outter.agent end
			AND  isnull(outter.wordid,'') = case when len(@word) > 0 then @word  else isnull(outter.wordid,'') end
	UNION ALL	
	select null,'Total:','','',sum(OCC),null,null,null from cte1 outter
		where	 outter.skill = case when len(@Skill) > 0 then @Skill else outter.skill end
			AND  outter.agent = case when len(@Agent) > 0 then @Agent else outter.agent end
			AND  isnull(outter.wordid,'') = case when len(@word) > 0 then @word  else isnull(outter.wordid,'') end	
END

GO
/****** Object:  StoredProcedure [dbo].[sp_asr_Report_old]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* Example: 
exec sp_asr_Report @DateBegin='20111110' ,@DateEnd='20130505',@word='1'
*/
CREATE PROCEDURE [dbo].[sp_asr_Report_old]
	@RecDate	INT = NULL,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
									-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	BIGINT = NULL,
	@DateEnd	BIGINT = NULL,
--	@TimeBegin	INT = 0,
--  @TimeEnd	INT = 235959,
	@Skill		VARCHAR(20) = NULL,		
	@SkillGroup INT = NULL,
	@ProjectId	INT = NULL,
	@Agent		VARCHAR(20) = NULL,
	@word		VARCHAR(20) = NULL,
	@Preload	BIT = 0			-- 仅预览表标题		
AS
	DECLARE @Error INT,
			@whereSql VARCHAR(100)
BEGIN
		

		;WITH cte0 as(
				select N.asrresult,N.asrresulta,N.asrresultb,M.recordid,M.skill,M.agent,M.startdate from  vxi_rec..recasr N left join
					( select recordid,agent,skill,startdate from vxi_rec..records
					) M
				on M.recordid=N.recordid
		),cte1 as(
					SELECT A.asrresult,A.asrresulta,A.asrresultb,A.recordid,A.skill,A.agent,B.word,B.wordid,A.startdate
					FROM cte0 A,
						(select wordid,word from vxi_rec..RepWords where enabled='1') B 
					WHERE charindex(B.word,asrresult)!=0 or  charindex(B.word,asrresulta)!=0 or  charindex(B.word,asrresultb)!=0

		),cte2 as(
				select CONVERT(VARCHAR(10),outter.startdate) startdate,outter.skill,outter.agent,outter.word,outter.wordid,count(outter.recordid) occ from 
				cte1 outter where asrresult  is not null
				group by outter.skill,outter.wordid,outter.word,outter.agent,outter.startdate

	   ),cte3 as(
				select CONVERT(VARCHAR(10),outter.startdate) startdate,outter.skill,outter.agent,outter.word,outter.wordid,count(outter.recordid) occ1 from 
				cte1 outter where asrresulta  is not null
				group by outter.skill,outter.wordid,outter.word,outter.agent,outter.startdate

		),cte4 as(
				select CONVERT(VARCHAR(10),outter.startdate) startdate,outter.skill,outter.agent,outter.word,outter.wordid,count(outter.recordid) occ2 from 
				cte1 outter where asrresultb  is not null
				group by outter.skill,outter.wordid,outter.word,outter.agent,outter.startdate

		),cte as(
				select outter.startdate,outter.agent,outter.skill,outter.word,outter.wordid,outter.occ,outter.occ1,outter.occ2 from
					(select A.startdate,A.agent,A.skill,A.word,A.wordid,A.occ,B.occ1,C.occ2 from cte2 A,cte3 B,cte4 C
						where A.agent=B.agent
						 and  A.agent=C.agent
						 and  A.skill=B.skill
						 and   A.skill=C.skill
						 and  A.word=B.word
						 and  A.word=C.word
						 and   A.startdate=B.startdate
						 and   A.startdate=C.startdate
						) outter
					where
							outter.startdate between @DateBegin and @DateEnd
							AND	 outter.skill = case when len(@Skill) > 0 then @Skill else outter.skill end
							AND  outter.agent = case when len(@Agent) > 0 then @Agent else outter.agent end
							AND  outter.wordid = case when len(@word) > 0 then @word else outter.wordid end
							
			)
		
		select startdate,agent,skill,word,occ,occ1,occ2 from cte
	UNION ALL
		select 'Total:','','','',sum(occ),sum(occ1),sum(occ2) from cte

END
GO
/****** Object:  StoredProcedure [dbo].[sp_asr_Report_old2]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/* Example: 
exec sp_asr_Report @DateBegin='20111110' ,@DateEnd='20130905',@word='移动'
*/
CREATE PROCEDURE [dbo].[sp_asr_Report_old2]
	@RecDate	INT = NULL,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
									-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	NVARCHAR(10) = NULL,
	@DateEnd	NVARCHAR(10) = NULL,
	@Skill		VARCHAR(20) = NULL,		
	@SkillGroup INT = NULL,
	@ProjectId	INT = NULL,
	@Agent		VARCHAR(20) = NULL,
	@word		VARCHAR(20) = NULL,
	@Preload	BIT = 0			-- 仅预览表标题		
AS
BEGIN

	declare @sch		varchar(4000),
			@whereSql   VARCHAR(100),
			@totalSql   VARCHAR(100)
		
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 112)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 112)
	end

	if (len(@word) > 0) set @whereSql = 'and A.WORDID = ''' + @word + ''''
	
	if (len(@Agent) > 0) set @whereSql = 'and A.AGENTNAME = ''' + @Agent + ''''
	
	if (len(@Skill) > 0) set @whereSql = 'and A.SKIll = ''' + @Skill + ''''
	
	SELECT A.recordid,B.word,B.WORDID into #tab
	FROM vxi_rec..recasr A,
	vxi_rec..RepWords B 
	WHERE b.enabled=1 and ( charindex(B.word,asrresult)!=0 or  charindex(B.word,asrresulta)!=0 or  charindex(B.word,asrresultb)!=0 )
	
	
	create table #ASR_records(RecordId bigint,Skill varchar(20),AgentName varchar(50),StartTime datetime,StartDate int
								,WORD  varchar(20)
								,WORDID  int
								,rownum int)
		 					
	set @sch = 'insert into #ASR_records(RecordId,Skill,AgentName,StartTime,StartDate,WORD,WORDID,rownum)
					select M.RecordId,M.Skill,M.Agent,M.StartTime,M.StartDate,
					N.WORD,N.WORDID,rownum = COUNT(*) OVER (partition by m.AGENT,m.SKILL,M.StartDate )'
					+ 'from  vxi_rec..records M '
					+ 'left join  #tab N on M.recordid=N.recordid where  str(M.StartDate)  between   str('+@DateBegin+') and  str('+@DateEnd+')'
		
				 	
	execute(@sch)
	
	select SKILL,AGENTNAME,STARTDATE,WORD,WORDID,COUNT(*) OCC,MAX(ROWNUM) ACC INTO #tab1 from #ASR_records A GROUP BY SKILL,AGENTNAME,STARTDATE,WORD,WORDID

	SET @sch='select STARTDATE,SKILL,AGENTNAME,WORD,OCC,(ACC-OCC) NCC,ACC,ROUND(CAST(OCC AS FLOAT)/ACC, 2) AS Normal from #tab1 A
			where 1=1 ' + isnull(@whereSql,'')
			
	execute(@sch+@totalSql)

	
	
	IF OBJECT_ID('tempdb..#ASR_records') IS NOT NULL BEGIN
		DROP TABLE #ASR_records
		PRINT 'delete temp table #ASR_records'
	END
	
	IF OBJECT_ID('tempdb..#tab') IS NOT NULL BEGIN
		DROP TABLE #tab
		PRINT 'delete temp table #tab'
	END

	IF OBJECT_ID('tempdb..#tab1') IS NOT NULL BEGIN
		DROP TABLE #tab1
		PRINT 'delete temp table #tab1'
	END
END
GO
/****** Object:  StoredProcedure [dbo].[sp_asr_skill_Report]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



/* Example: 
exec [sp_asr_skill_Report] @DateBegin='20111110' ,@DateEnd='20130505',@word='1'
*/
CREATE PROCEDURE [dbo].[sp_asr_skill_Report]
	@RecDate	INT = NULL,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
									-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	BIGINT = NULL,
	@DateEnd	BIGINT = NULL,
	@Skill		VARCHAR(20) = NULL,		
	@SkillGroup INT = NULL,
	@ProjectId	INT = NULL,
	@word		VARCHAR(20) = NULL,
	@Preload	BIT = 0			-- 仅预览表标题		
AS
BEGIN

	;WITH cte0 as(
				SELECT A.recordid,B.word,B.wordid
				FROM vxi_rec..recasr A,
					 vxi_rec..RepWords B 
				WHERE b.enabled=1 and ( charindex(B.word,asrresult)!=0 or  charindex(B.word,asrresulta)!=0 or  charindex(B.word,asrresultb)!=0 )
		),cte as(
				select M.RecordId,M.Skill,M.Agent,M.StartTime,M.StartDate,
					N.WORD,N.WORDID,rownum = COUNT(*) OVER (partition by M.SKILL,M.StartDate )
					from vxi_rec..records M 
					left join cte0 N on M.recordid=N.recordid 
					where M.StartDate between @DateBegin and @DateEnd
		),cte1 as(
				select SKILL,STARTDATE,WORD,WORDID,COUNT(*) OCC,(MAX(ROWNUM)-COUNT(*)) NCC,MAX(ROWNUM) ACC,dbo.avg_str(COUNT(*),MAX(ROWNUM),1) AS Normal from cte A GROUP BY SKILL,STARTDATE,WORD,WORDID
		)
		
	select STARTDATE,SKILL,WORD,OCC,NCC,ACC,Normal from cte1 outter
		where	 outter.skill = case when len(@Skill) > 0 then @Skill else outter.skill end
			AND  isnull(outter.wordid,'') = case when len(@word) > 0 then @word  else isnull(outter.wordid,'') end
	UNION ALL	
	select null,'Total:','',sum(OCC),null,null,null from cte1 outter
		where	 outter.skill = case when len(@Skill) > 0 then @Skill else outter.skill end
			AND  isnull(outter.wordid,'') = case when len(@word) > 0 then @word  else isnull(outter.wordid,'') end	
END


GO
/****** Object:  StoredProcedure [dbo].[sp_asr_word_Report]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/* Example: 
exec [sp_asr_word_Report] @DateBegin='20110722' ,@DateEnd='20140705',@word='1'
*/
CREATE PROCEDURE [dbo].[sp_asr_word_Report]
	@RecDate	INT = NULL,			-- 报表日期（用于日报表查询）格式：yyyymmdd/yyyymm/yyyy，
									-- 注：mm = 0 表示年报，dd = 0 表示月报
	@DateBegin	BIGINT = NULL,
	@DateEnd	BIGINT = NULL,
	@Skill		VARCHAR(20) = NULL,		
	@SkillGroup INT = NULL,
	@ProjectId	INT = NULL,
	@word		VARCHAR(20) = NULL,
	@Preload	BIT = 0			-- 仅预览表标题		
AS
BEGIN

	;WITH cte0 as(
				SELECT A.recordid,B.word,B.wordid
				FROM vxi_rec..recasr A,
					 vxi_rec..RepWords B 
				WHERE b.enabled=1 and ( charindex(B.word,asrresult)!=0 or  charindex(B.word,asrresulta)!=0 or  charindex(B.word,asrresultb)!=0 )
		),cte as(
				select M.RecordId,M.Skill,M.Agent,M.StartTime,M.StartDate,
					N.WORD,N.WORDID
					from vxi_rec..records M 
					left join cte0 N on M.recordid=N.recordid 
					where M.StartDate between @DateBegin and @DateEnd
		),cte1 as(
				select WORD,WORDID,COUNT(*) OCC,((select count(*) from cte)-COUNT(*)) NCC,dbo.avg_str(COUNT(*),(select count(*) from cte),1) AS Normal from cte A GROUP BY WORD,WORDID
		)
		
	select WORD,OCC,NCC,Normal from cte1 outter
		where isnull(outter.wordid,'') = case when len(@word) > 0 then @word  else isnull(outter.wordid,'') end
	UNION ALL	
	select 'Total:',sum(OCC),null,null from cte1 outter
		where isnull(outter.wordid,'') = case when len(@word) > 0 then @word  else isnull(outter.wordid,'') end	
END




GO
/****** Object:  StoredProcedure [dbo].[sp_get_InsertSql]    Script Date: 2016/9/5 13:24:59 ******/
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
/****** Object:  StoredProcedure [dbo].[sp_get_projects]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE procedure [dbo].[sp_get_projects]

@currentDate varchar(10)=1

as
select prjid id,project projectName,summary description from vxi_sys..projects
where enabled=1
GO
/****** Object:  StoredProcedure [dbo].[sp_get_record]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/* Example: 
exec sp_get_record @recordid=20141030000002
*/
CREATE PROCEDURE [dbo].[sp_get_record]
	@recordid bigint
AS
BEGIN
	declare @AssRec bigint
	
	select @AssRec = isnull(AssRec, 0) from records where recordid = @recordid
	
	if @AssRec > 0 set @recordid = @AssRec
	
	--select t.ftpid, rtrim(isnull(s.ip,'')) + ':' + rtrim(isnull(t.port,'80')) + '/' + rtrim(isnull(t.folder,'')) addr,
	--		s.station, s.ip, t.folder, t.encry,s.extip
	select t.ftpid, rtrim(isnull(s.ip,'')) ip, case when t.port is null then 80 else t.port end port, 
		rtrim(isnull(t.folder,'')) folder, s.station, t.encry,s.extip 
	into #TempTab
		from vxi_sys..station s 
			inner join store t on s.station = t.station
	--	where s.enabled = 1 and t.enabled = 1

	select r.[RecordId], r.[UcdId], r.[CallID], 
		isnull(r.Calling,c.Calling) Calling, 
		isnull(r.Called,c.Called) Called, 
		isnull(r.Answer,c.Answer) Answer, 
		r.[StartTime], r.[TimeLen], r.[Seconds], r.[Agent], r.[Skill], r.[Route], r.[Trunk], 
		r.[TrunkGroupId], r.[VideoURL], r.[AudioURL], r.[Channel], r.[Extension], r.[VoiceType], 
		r.[StartDate], r.[StartHour], r.[Inbound], r.[Outbound], r.[UCID], r.[UUI], r.[PrjId], 
		r.[Finished], r.[ActFlag], r.[Labeled], r.[FileCount],r.[DataEncry],		
		--a.addr Audio, v.addr Video,
		a.ip au_ip, a.port au_port, a.folder au_folder,a.extip au_extip,
		v.ip vu_ip, v.port vu_port, v.folder vu_folder,v.extip vu_extip,
		v.encry, t.typename, t.ext, t.wavbit,t.code,
			case when r.VoiceType < 11 then 'http://' else 'mms://' end head,
			a.station StnAudio, v.station StnVideo
		from records r  left join #TempTab a on r.AudioUrl = a.ftpid
				left join #TempTab v on r.VideoUrl = v.ftpid
				left join vxi_sys..VoiceType t on r.VoiceType = t.VoiceType
				left join vxi_ucd..UcdCall c on r.UcdID = c.UcdID and r.CallID = c.CallID
		where r.recordid = @recordid

	drop table #TempTab

END

GO
/****** Object:  StoredProcedure [dbo].[sp_insert_record]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
返回参数：
	@PrjId：返回当前记录对应的PrjId
返回值：0 - 成功
		1 - RecordId错误
		2 - 更新Records错误
*/
CREATE  PROCEDURE [dbo].[sp_insert_record]
	@OperType		varchar(1) = '',	-- 'N'-新增记录；'U'-更新；''-自动判断新增还是更新
	@RecordId 		bigint,
	@UcdId 			bigint,
	@Calling 		varchar(20),
	@Called 		varchar(20),
	@Answer 		varchar(20),
	@StartTime 		datetime,
	@TimeLen 		int,
	@Agent 			varchar(20),
	@Skill 			varchar(20),
	@Route			varchar(20),
	@Trunk			varchar(20),
	@TrunkGroupId 	int,
	@VideoURL 		smallint,
	@AudioURL 		smallint,
	@Channel 		varchar(20),
	@Extension 		varchar(20),
	@VoiceType 		tinyint,
	@StartDate 		int,
	@StartHour 		tinyint,
	@Inbound 		bit,
	@Outbound 		bit,
	@UCID 			varchar(50),
	@UUI 			varchar(100),
	@PrjId 			int = -2 out,	-- -1表示需手工匹配；0由手工设置；>0表示已经匹配到项目；本过程-2表示需要查找匹配项目
	@Finished 		tinyint,
	@Labeled 		bit,
	@Tasks			varchar(2048),	-- 任务列表，以逗号隔开
	@AgentGroupId	int,
	@ExtGroupId		int,
	@CallID			int = null,
    @FileCount      smallint = 1,
	@DataEncry		bit = 0,
	@AssRec			bigint = 0,
    @Established    bit = 1,
    @VideoType      smallint=0,
    @EncryKey       varchar(500),
	@ChatSession    varchar(100),
---------------------------------------
    @HasRecExt      bit,
    @Source         varchar(100),
    @MsgTime        datetime,
    @Msg01          varchar(500),
    @Msg02          varchar(500),
    @Msg03          varchar(500),
    @Msg04          varchar(500),
    @Msg05          varchar(500),
    @Msg06          varchar(500),
    @Msg07          varchar(500),
    @Msg08          varchar(500),
    @Msg09          varchar(500),
    @Msg10          varchar(500)
----------------------------------------
AS

	if (isnull(@RecordId, 0) <= 0) begin
		return 1	-- RecordId错误
	end

	-- 判断操作类型
	if (isnull(@OperType, '') = '') begin
		-- 为空，判断是否记录已经存在，以次确定新增还是更新
		declare @Recc int
		select @Recc = count(RecordId) from Records where RecordId = @RecordId
		set @OperType = case when @Recc > 0 then 'U' else 'N'end
	end

	if (@PrjId is null) begin
		-- 为空置-2
		set @PrjId = -2
	end
	
	if isnull(@CallID, 0) = 0 begin
		set @AssRec = 0
	end

	-- 如PrjId为-2，查找对应的项目Id，找不到设置为-1
	if (@PrjId = -2) begin
		set @PrjId = dbo.find_match_prjid(@TrunkGroupId,
										  @Skill,
								  	  	  @Agent,
								  	  	  @Extension,
								  	  	  @Route,
								  	  	  @Calling,
								  	  	  @Called
								 	 	 )
	end

	-- 开始更新表
	--begin tran

	-- 根据操作类型执行insert或update records
	declare @ErrCode int, @RowEffect int
	if (upper(@OperType) = 'U') begin
		-- 更新操作
		update Records set
			UcdId 			= case when @UcdId > 0 then @UcdId else UcdId end, 
			CallID			= @CallID, 
			Calling			= @Calling, 
			Called 			= @Called, 
			Answer 			= @Answer, 
			StartTime 		= @StartTime, 
			TimeLen 		= @TimeLen, 
			Agent 			= @Agent, 
			Skill 			= @Skill, 
			Route			= @Route,
			Trunk			= @Trunk,
			TrunkGroupId	= @TrunkGroupId,
      		VideoURL 		= @VideoURL, 
			AudioURL 		= @AudioURL, 
			Channel 		= @Channel, 
			Extension 		= @Extension, 
			VoiceType 		= @VoiceType, 
			StartDate		= @StartDate, 
			StartHour		= @StartHour, 
			Inbound 		= @Inbound, 
      		Outbound		= @Outbound, 
			UCID			= @UCID, 
			UUI				= @UUI, 
			PrjId			= @PrjId, 
			Finished		= @Finished, 
			Labeled			= @Labeled,
            FileCount       = @FileCount,
			DataEncry		= @DataEncry,
			AssRec			= 0,
            Established     = @Established,
            VideoType       = @VideoType,
            EncryKey        = @EncryKey,
			ChatSession     = @ChatSession 
		where RecordId = @RecordId
		
	end
	else begin
		-- 新增操作
		insert into Records(RecordId, UcdId, Calling, Called, Answer, StartTime, TimeLen, Agent, Skill, Route, Trunk, 
			TrunkGroupId, VideoURL, AudioURL, Channel, Extension, VoiceType, StartDate, StartHour, Inbound, Outbound, 
			UCID, UUI, PrjId, Finished, Labeled, CallID, FileCount, DataEncry, AssRec, Established, VideoType, EncryKey,ChatSession) 
		values (@RecordId, @UcdId, @Calling, @Called, @Answer, @StartTime, @TimeLen, @Agent, @Skill, @Route, @Trunk, 
			@TrunkGroupId, @VideoURL, @AudioURL, @Channel, @Extension, @VoiceType, @StartDate, @StartHour, @Inbound, 
			@Outbound, @UCID, @UUI, @PrjId, @Finished, @Labeled, @CallID, @FileCount, @DataEncry, 0, @Established, @VideoType, @EncryKey,@ChatSession)

	end	-- end if (upper(@OperType) = 'U')
	
	select @ErrCode = @@Error, @RowEffect = @@RowCount	-- 保存错误代码和插入/更新数

	if ( (@ErrCode != 0) or (@RowEffect != 1) ) begin
		--rollback tran
		return 2	-- 更新Records表错误
	end

    if(@HasRecExt>0)
    begin
         if exists (select * from RecExts where RecordId=@RecordId)
         begin
            update RecExts set 
                Handler = @Source,
                Item01 = @Msg01,
                Item02 = @Msg02,
                Item03 = @Msg03,
                Item04 = @Msg04,
                Item05 = @Msg05,
                Item06 = @Msg06,
                Item07 = @Msg07,
                Item08 = @Msg08,
                Item09 = @Msg09,
                Item10 = @Msg10
            where RecordId=@RecordId        
         end
         else
         begin
            insert into RecExts(RecordId,Item01,Item02,Item03,Item04,Item05,Item06,Item07,Item08,Item09,Item10,ItemTime,Handler, Enabled)
            values(@RecordId,@Msg01,@Msg02,@Msg03,@Msg04,@Msg05,@Msg06,@Msg07,@Msg08,@Msg09,@Msg10,@MsgTime,@Source,1)
         end
  
    end
    else
    begin
         if exists (select * from RecExts where RecordId=@RecordId)
         begin
            delete from RecExts where RecordId=@RecordId 
         end     
    end  
	

	-- 插入GroupRec表
	if ( @AgentGroupId > 0 ) begin
		if (not exists(select * from GroupRec where RecordId = @RecordId and GroupId = @AgentGroupId)) begin
			insert into GroupRec(RecordId, GroupId) values(@RecordId, @AgentGroupId)
			--select @RecordId, GroupId from vxi_sys..AgentGroup where Agent = @Agent
		end
	end

	if ( @ExtGroupId > 0) begin
		if (not exists(select * from GroupRec where RecordId = @RecordId and GroupId = @ExtGroupId)) begin
			insert into GroupRec(RecordId, GroupId) values(@RecordId, @ExtGroupId)
			--select @RecordId, GroupId from vxi_sys..ExtGroup where Device = @Extension
		end
	end

	-- 插入TaskRec表
	if ( len(@Tasks) > 0 ) begin
		declare @TaskItem int, @Pos int, @LastPos int, @curLen int
		set @Tasks = @Tasks + ','
		set @LastPos = 1
		set @Pos = charindex(',', @Tasks)
		while @Pos > 0 begin
			set @curLen = @Pos - @LastPos
			if (@curLen > 0) begin
				set @TaskItem = cast(substring(@Tasks, @LastPos, @curLen) as int)
				if (not exists(select * from TaskRec where RecordId = @RecordId and TaskId = @TaskItem)) begin
					insert into TaskRec(RecordId, TaskId) values(@RecordId, @TaskItem)
				end
			end

			set @LastPos = @Pos + 1
			set @Pos = charindex(',', @Tasks, @LastPos)
		end

	end

	-- 提交所有更改
	--commit tran
	return 0	-- 成功返回











GO
/****** Object:  StoredProcedure [dbo].[sp_recexts_insert]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Author:		wenyong xia
-- Create date: 2007 12/07
-- Description:	recexts insert or update
-- =============================================
CREATE PROCEDURE [dbo].[sp_recexts_insert]  
	-- Add the parameters for the stored procedure here
	@RecordId bigint = null,
	@Handler varchar(20) = null,
	@Item01 varchar(50) = null,
	@Item02 varchar(50) = null,
	@Item03 varchar(50) = null,
	@Item04 varchar(50) = null,
	@Item05 varchar(50) = null,
	@Item06 varchar(50) = null,
	@Item07 varchar(50) = null,
	@Item08 varchar(50) = null,
	@Item09 varchar(50) = null,
	@Item10 varchar(50) = null,	
	@Note varchar(1000) = null,
	@Enabled bit = 1
AS
BEGIN
	if exists(select 1 from RecExts where RecordId = @RecordId  ) begin
		update RecExts set 
			Handler = isnull(@Handler,Handler),
			Item01 = isnull(@Item01,Item01),
			Item02 = isnull(@Item02,Item02),
			Item03 = isnull(@Item03,Item03),
			Item04 = isnull(@Item04,Item04),
			Item05 = isnull(@Item05,Item05),
			Item06 = isnull(@Item02,Item06),
			Item07 = isnull(@Item07,Item07),
			Item08 = isnull(@Item02,Item08),
			Item09 = isnull(@Item09,Item09),
			Item10 = isnull(@Item02,Item10),
			Note = isnull(@Note,Note),
			Enabled = isnull(@Enabled,Enabled)
		where RecordId = @RecordId
	end
	else begin

		if @RecordId is not null begin
			insert into RecExts(RecordId, Handler, Item01, Item02, Item03, Item04, 
				Item05, Item06,	Item07, Item08, Item09, Item10, Note, ItemTime, Enabled )
			 values(@RecordId, @Handler, @Item01, @Item02, @Item03, @Item04, 
				@Item05, @Item06, @Item07, @Item08, @Item09, @Item10, @Note, getdate(), isnull(@Enabled,1))
		
			
		end
	end
	select recordid from vxi_rec..records where recordid=@RecordId 
END
GO
/****** Object:  StoredProcedure [dbo].[sp_sch_records]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================
-- Author:		fei yu
-- Create date: 03/24/2008
-- Description:	<Description,,>
/* Example: 
exec sp_sch_records @num_begin=0,@num_end=30000
					,@StartTime_begin='20141020 10:10'
					,@StartTime_end='20141030 23:59'
					,@AgentList_p='79902'
					,@SkillList_p='4739'
					,@baudioasr=1
					,@audioasr=''		
					,@PageSize=5
					,@Page=3			
exec sp_sch_records @calltype=1, @SchMode = 3
exec sp_sch_records @bLabel=1, @label='asdfa'
					,@SurveyResult='1'
					
exec sp_sch_records @num_begin=0,@num_end=30000
					,@StartTime_begin='20110529 10:10'
					,@StartTime_end='20140529 23:59'
					,@audioasr='
					,@asritem='0'	
					
exec sp_sch_records @num_begin=0
					,@num_end=30000
					,@SkillList='10,20,103,206'
*/
-- ====================================================
create PROCEDURE [dbo].[sp_sch_records]
	@recordid			bigint = 0,
	@num_begin			int = 0,
	@num_end			int = 0,
	@TaskList			varchar(2000) = '',
	@GroupList			varchar(2000) = '',
	@prjid				varchar(200) = '',
	@prjid_p			varchar(200) = '',		-- 项目列表（权限）
	@calltype			varchar(1) = null,
	@UcdId				bigint = 0,
	@Calling			varchar(20) = '',
	@Calling_p			varchar(2000) = '',
	@Called				varchar(20) = '',
	@Called_p			varchar(2000) = '',
	@Answer				varchar(20) = '',
	@StartTime_begin	datetime = null,
	@StartTime_end		datetime = null,
	@AgentList			varchar(max) = '',
	@AgentList_p		varchar(max) = '',		-- 坐席列表（权限）
	@SkillList			varchar(max) = '',
	@SkillList_p		varchar(max) = '',		-- 技能列表（权限）
	@ExtList			varchar(max) = '',
	@ExtList_p			varchar(max) = '',		-- 分机列表（权限）
	@ItemNo				tinyint = 0,
	@Value				varchar(50) = '',
	@bLabel				bit = 0,
	@Label				varchar(2000) = '',
	@custom				varchar(20) = '',
	@audioasr			varchar(5000) = '',
	
	@baudioasr			bit = 0,	--语音内容搜索是否包含搜索词
	@asritem			int=0,		--asr检所选项
	
	@confidence			int = 60,
	@ItemKey			tinyint = 0,
	@ItemValue			varchar(20) = '',
	@Finished			tinyint = 0,
	@SurveyResult		varchar(20) = '',
	@SchMode			tinyint = 0,
	-- Paging --	
	@PageSize			int = 8000,		-- 页尺寸
	@Page				int = 1,		-- 页码
	@TotalCount			int = 1,		-- 记录总数
    -- hold,mute,confer统计
	@MutetimeFrom	    int = 0, 
	@MutetimeTo	        int = 0, 
	@HoldtimeFrom	    int = 0, 
	@HoldtimeTo	        int = 0, 
	@ConferencetimeFrom	int = 0, 
	@ConferencetimeTo	int = 0,
	@bAdmin				bit = 0		-- 是否管理员
AS
/*
@calltype-[0:Inner,1-Inbound,2-Outbound]
@SchMode-[0:Default,1-YongDa,2-NongXin,3-Banggo]
*/
BEGIN

	set @prjid = ltrim(rtrim(isnull(@prjid, '')))
	set @prjid_p = ltrim(rtrim(isnull(@prjid_p, '')))
	set @Calling = ltrim(rtrim(isnull(@Calling, ''))) 
	set @Calling_p = ltrim(rtrim(isnull(@Calling_p, '')))
	set @ExtList = ltrim(rtrim(isnull(@ExtList, '')))
	set @ExtList_p = ltrim(rtrim(isnull(@ExtList_p, ''))) 
	set @Called	= ltrim(rtrim(isnull(@Called, ''))) 
	set @Called_p = ltrim(rtrim(isnull(@Called_p, '')))
	set @Answer	= ltrim(rtrim(isnull(@Answer, ''))) 
	set @AgentList	= ltrim(rtrim(isnull(@AgentList, '')))
	set @AgentList_p	= ltrim(rtrim(isnull(@AgentList_p, ''))) 
	set @SkillList = ltrim(rtrim(isnull(@SkillList, '')))
	set @SkillList_p = ltrim(rtrim(isnull(@SkillList_p, '')))
	set @TaskList = ltrim(rtrim(isnull(@TaskList, '')))
	set @GroupList = ltrim(rtrim(isnull(@GroupList, '')))
	set @label	= ltrim(rtrim(isnull(@label, ''))) 
	set @custom	= ltrim(rtrim(isnull(@custom, ''))) 
	set @Value = ltrim(rtrim(isnull(@Value, '')))
	set @bLabel = isnull(@bLabel, 0)
	set @Label = ltrim(rtrim(isnull(@Label, '')))
	set @SurveyResult = isnull(rtrim(@SurveyResult), '')
	set @SchMode = isnull(@SchMode, 0)
	set @audioasr = ltrim(rtrim(isnull(@audioasr, '')))
	set @baudioasr = isnull(@baudioasr, 0)	--语音内容是否包含
	set @bAdmin = isnull(@bAdmin, 0)

	IF OBJECT_ID('tempdb..#t_record_p') IS NOT NULL BEGIN
		DROP TABLE #t_record_p
		PRINT 'drop temp table #t_record_p'
	END
	IF OBJECT_ID('tempdb..#t_records') IS NOT NULL BEGIN
		DROP TABLE #t_records
		PRINT 'drop temp table #t_records'
	END
	IF OBJECT_ID('tempdb..#T_RecAsr') IS NOT NULL BEGIN
		DROP TABLE #T_RecAsr
		PRINT 'drop temp table #T_RecAsr'
	END

	declare @sch			varchar(max),
			@Item			varchar(20),
			@order_str		varchar(200),
			@sch1			varchar(4000),
			@sch2			varchar(4000),
			@audioasrs		varchar(500),
			@asrresult		varchar(20), --语音范围
			@basr			bit,
			@ind			int,		  --搜索词个数1
			@ind1			int,		  --搜索词个数2
			@ind2			int,		  --搜索词个数3（既有空格又有逗号分隔）
			@var			int,		  --判断是否包含逗号	
			@spa			int,		  --判断是否包含空格
			@a				int,		  --循环使用变量1
			@b				int,		  --循环使用变量1
			@sch_p			varchar(max),
			@bPrivilege		bit
	
	set @order_str = ' order by m.starttime desc'
	set @bPrivilege = 0

	if @audioasr != '' begin
		set @basr = 1
	end
	else begin
		set @basr = 0
	end
	
	create table #t_record_p(recordid bigint)
	create index #ix_t_record_p on #t_record_p(recordid)

	if @SchMode = 1 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension,m.Established, 
							CallType = case when m.Inbound = 1 and m.Outbound = 0 then 1
											when m.Inbound = 0 and m.Outbound = 1 then 2
										else 0 end, 
							m.mark,''<a href=http://127.0.0.1/record/''+SUBSTRING(cast(m.RecordId as varchar(14)),1,8)+''/''+cast(m.Extension as varchar(4))+''/''+cast(m.RecordId as varchar(14))+''/''+cast(m.RecordId as varchar(14))+''.wav>下载</a>'' as DownLoad'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent '  
	end
	else if @SchMode = 2 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension,m.Established'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  --+ ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	else begin
		create table #T_records(RecordId bigint,Calling varchar(20),Called varchar(20),Answer varchar(20),Finished tinyint,
								Skill varchar(20),Master varchar(20),Established bit,AgentName varchar(50),StartTime datetime,StartDate int,Seconds int,
								Extension varchar(20),SurveyResult int,Item01 varchar(50),Item02 varchar(50),Item03 varchar(50),mark varchar(10),
								UCID varchar(50),rownum int,muteTime int, holdTime int, conferenceTime int)
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master,m.Established, a.AgentName, m.StartTime, m.StartDate,
							m.Seconds, m.Extension,	e.Item01, e.Item02, e.Item03, m.mark, m.UCID,
							rownum = row_number() over(partition by m.StartDate,m.UCID order by m.StartTime desc),
							isnull(ra.muteTime, 0) muteTime, isnull(ra.holdTime, 0) holdTime, isnull(ra.conferenceTime, 0) conferenceTime
						from vxi_rec..records m
							left join vxi_rec..taskrec r on r.recordid = m.recordid
							left join vxi_sys..Agent a on a.agent = m.agent
							left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1
							left join (
										 select recadd.recordid, 
											sum(case when recadd.eventtype = 0 then 1 else 0 end) holdTime,
											sum(case when recadd.eventtype = 1 then 1 else 0 end) conferenceTime,
											sum(case when recadd.eventtype = 2 then 1 else 0 end) muteTime
										 from RecAdditional recadd
										 group by recordid
										) ra on m.recordid = ra.recordid ' 
	end
	
	CREATE TABLE #T_RecAsr (RecordId bigint,AsrResult text) 
	
	IF OBJECT_ID('tempdb..#T_RecAsr') IS NOT NULL BEGIN
		 set @asrresult = 'AsrResult'
	END
	
    if isnull(@asritem, 0) != 4 begin
		INSERT  INTO #T_RecAsr
		select * from vxi_rec.dbo.Format_AsrResult(@asritem)
	end

	if @basr = 1 set @sch = @sch + ' left join #T_RecAsr s on s.recordid = m.recordid'

	set @sch = @sch + ' 
						where m.Finished >= 1 
							and m.seconds > 1 '
						
	if @StartTime_begin is not null and @StartTime_end is not null begin
		select @sch = @sch 	+ ' 
							and m.StartTime between ''' + convert(varchar(20), @StartTime_begin, 120) + ''''
							+ ' and ''' + convert(varchar(20), @StartTime_end,120) + ''''
	end
	else begin
		select @sch = @sch + ' 
							and m.RecordId between ' + convert(varchar(20), dbo.time_to_bigint(@StartTime_begin,1) / 10000 * 1000000)
							+ ' and ' + convert(varchar(20), dbo.time_to_bigint(@StartTime_end,1) / 10000 * 1000000 + 999999)
	end
	
	/*权限控制录音记录取舍Begin*/
	if @bAdmin = 1 goto _NEXT
	if len(@AgentList_p) = 0 and len(@ExtList_p) = 0 and len(@SkillList_p) = 0 
		and len(@prjId_p) = 0 and len(@Calling_p) = 0 and len(@Called_p) = 0 goto _NEXT
	
	set @sch_p = @sch + '
						and '
	
	if len(@AgentList_p) > 0 begin
		set @AgentList_p = ',' + @AgentList_p + ','
		set @sch_p = @sch_p + ' (charindex('','' + rtrim(m.agent) + '','' ,''' + @AgentList_p + ''') > 0 '
	end
	if len(@ExtList_p) > 0 begin
		set @ExtList_p = ',' + @ExtList_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(m.Extension) + '','' ,''' + @ExtList_p + ''') > 0 '
	end
	if len(@SkillList_p) > 0 begin
		set @SkillList_p = ',' + @SkillList_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(m.skill) + '','' ,''' + @SkillList_p + ''') > 0 '
	end
	if len(@prjId_p) > 0 begin
		set @prjId_p = ',' + @prjId_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + convert(varchar, m.prjId) + '','' ,''' + @prjId_p + ''') > 0 '
	end
	if len(@Calling_p) > 0 begin
		set @Calling_p = ',' + @Calling_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(m.Calling) + '','', ''' + @Calling_p + ''') > 0 ' 
	end
	if len(@Called_p) > 0 begin
		set @Called_p = ',' + @Called_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(m.Called) + '','', ''' + @Called_p + ''') > 0 ' 
	end
	
	set @sch_p = @sch_p + ')'
	
	set @sch_p = 'insert into #t_record_p(recordid) 
						select recordid from (' + @sch_p + ') t'
	
	--print @sch_p --
	exec(@sch_p)
	
	set @bPrivilege = 1
	
	/*权限控制录音记录取舍End*/
	
	_NEXT:
	
	
	if @basr = 1 begin
		set @var=charindex('+',@audioasr)			 --判断是否包含加号
		set @spa=charindex(' ',rtrim(@audioasr))	 --判断是否包含空格
			if @spa>0 begin
					set @audioasr=dbo.TrimString(@audioasr)
					set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1	
	--a+b  cc d+e+f				
					if @var>0 begin
								if @baudioasr = 1 begin
										set @a=1
										set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
										set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
										set @b=1
										set @sch1 = ' and ( ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
										while @b<@ind1 begin
													set @sch1 = @sch1 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
													set @b=@b+1
										end	
										set @sch1 = @sch1 + ')' 

										while @a<@ind begin
										set @a=@a+1
										set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
										set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
										set @sch2 = ' or ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
										set @b=1
										while @b<@ind2 begin
												set @sch2 = @sch2 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
												set @b=@b+1
										end
										set @sch2 =@sch2 +')'
										set @sch1 =@sch1 +@sch2
										end
										set @sch =@sch +@sch1+')'
								end
								else begin
										set @a=1
										set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
										set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
										set @b=1
										set @sch1 = ' and ( ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
										while @b<@ind1 begin
													set @sch1 = @sch1 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b) + '%'''
													set @b=@b+1
										end	
										set @sch1 = @sch1 + ')' 

										while @a<@ind begin
										set @a=@a+1
										set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
										set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
										set @sch2 = ' or ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
										set @b=1
										while @b<@ind2 begin
												set @sch2 = @sch2 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
												set @b=@b+1
										end
										set @sch2 =@sch2 +')'
										set @sch1 =@sch1 +@sch2
										end
										set @sch =@sch +@sch1+')'
								end
						end
	--aa ccc ddddd
						else begin	
							if @baudioasr=1 begin
									set @a=1
									set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
									while @a<@ind begin
										set @sch1 =@sch1+'and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end
							else begin
									set @a=1
									set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
									while @a<@ind begin
										set @sch1 = @sch1 + ' or '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end
						end
			
			end
	------------------------------------------
			else begin
	--a+c+bss
				if @var>0 begin
					set @ind=(len(replace(@audioasr,'+','--'))-len(@audioasr))+1
								if @baudioasr = 1 begin
										set @a=1
										set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
										while @a<@ind  begin
											set @sch1 =@sch1+'or '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
											set @a=@a+1
										end
										set @sch = @sch + ' and ('+	@sch1 +')' 
								end
								else begin
										set @a=1
										set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
										while @a<@ind begin
											set @sch1 = @sch1 + ' and '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
											set @a=@a+1
										end
										set @sch = @sch + ' and ('+	@sch1 +')' 
								end		
				end
	--a
				else begin
								if @baudioasr = 1 begin
										set @sch1 = 'and '+@asrresult+' not like ''%' + @audioasr+ '%'''	
										set @sch = @sch+@sch1
								end
								else begin
										set @sch1 = 'and '+@asrresult+' like ''%' +@audioasr + '%'''	
										set @sch = @sch+@sch1
								end			
				end
		end
	end	

	if @bLabel = 1 begin
		if len(@Label) > 0 begin
			set @Label = ',' + @Label + ',' 
			select @sch = @sch + ' 
									and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid 
									and charindex('','' + rtrim(b.Title) + '','', ''' + @Label + ''') > 0)'
		end
		else begin
			select @sch = @sch + ' 
									and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid)'
		end
	end
		
	if isnull(@calltype, '') != '' begin
		select @sch = @sch + case when @calltype = 1 then ' and m.Inbound = 1 and m.Outbound = 0'
									when @calltype = 2 then ' and m.Inbound = 0 and m.Outbound = 1'
								else ' and m.Inbound = 0 and m.Outbound = 0' 
								end
	end
    else if (@custom != '')  begin
		--select @sch = @sch + ' and ((m.Inbound = 1 and m.Outbound = 0 and m.Calling like ''' 
		--			+ @custom + '%'') or (m.Inbound = 0 and m.Outbound = 1 and m.Called like ''' + @custom + '%''))' 
		select @sch = @sch + ' and (( m.Calling like ''' 
					+ @custom + '%'') or ( m.Called like ''' + @custom + '%''))' 
	end

	if @recordid != 0
		select @sch = @sch + ' 
								and m.recordid = ' + convert(varchar, @recordid)
		
	if @num_begin  != 0
		select @sch = @sch + ' 
							and m.seconds >= ' + convert(varchar, @num_begin )

	if @num_end != 0
		select @sch = @sch + ' 
							and m.seconds <= ' + convert(varchar, @num_end)

	-- hold mute confer 统计
	if (@MutetimeTo !=0)  
		select @sch = @sch + ' and isnull(ra.muteTime, 0) between ' + str(@MutetimeFrom) + ' and ' + str(@MutetimeTo) 
	if (@HoldtimeTo !=0)  
		select @sch = @sch + ' and isnull(ra.holdTime, 0) between ' + str(@HoldtimeFrom) + ' and ' + str(@HoldtimeTo) 
	if (@ConferencetimeTo !=0)  
		select @sch = @sch + ' and isnull(ra.conferenceTime, 0) between ' + str(@ConferencetimeFrom) + ' and ' + str(@ConferencetimeTo) 

	if len(@TaskList) > 0 begin
		set @TaskList = ',' + @TaskList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.TaskId) + '','', ''' + @TaskList + ''') > 0 '
	end

	if Len(@GroupList) > 0 begin
		set @GroupList = ',' + @GroupList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, g.groupid) + '','', ''' + @GroupList + ''') > 0 '
	end

	if @prjid != ''
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.prjid) + '','', ''' + @prjid + ''') > 0 '

	if @UcdId != 0
		select @sch = @sch + ' and m.UcdId = ' + convert(varchar, @UcdId)

	if @Calling != ''
		select @sch = @sch + ' and m.Calling like ''%' + @Calling + '%'''

	if @Called != ''
		select @sch = @sch + ' and m.Called like ''%' + @Called + '%'''

	if @Answer != ''
		select @sch = @sch + ' and Answer like ''%' + @Answer + '%'''

	if len(@AgentList) > 0 begin
		set @AgentList = ',' + @AgentList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.agent) + '','' ,''' + @AgentList + ''') > 0 '
	end

	if len(@SkillList) > 0 begin
		set @SkillList = ',' + @SkillList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.skill) + '','' ,''' + @SkillList + ''') > 0 '
	end

	if len(@ExtList) > 0 begin
		set @ExtList = ',' + @ExtList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.Extension) + '','', ''' + @ExtList + ''') > 0 '
	end

	if not (@ItemNo is null or @ItemNo = 0 or @ItemNo > 10 or @Value ='')  begin
		if @ItemNo = 10  begin
			select @Item = ' e.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item = ' e.Item0' + cast(@ItemNo as varchar(10))	 
		end
		set @Value =  @Value + '%'
		select @sch = @sch + ' and ' + @item + ' like '''+ @Value +''''
	end
	
	if isnull(@ItemKey, 0) > 0 begin
		set @Item = case @ItemKey
							when 1 then 'e.Item01'
							when 2 then 'e.Item02'
							when 3 then 'e.Item03'
					else '' end
					
		if len(@Item) > 0 and len(@ItemValue) > 0 begin
			select @sch = @sch + ' and ' + @Item + ' = ''' + @ItemValue + ''''
		end
	end
	
	if isnull(@Finished, 0) > 0 begin
		select @sch = @sch + ' and m.Finished = ' + str(@Finished)
	end
	
	if @SchMode not in (1,2) begin
		set @sch = 'insert into #T_records(RecordId,Calling,Called,Answer,Finished,Skill,Master,Established,AgentName,StartTime,
											StartDate,Seconds,Extension,Item01,Item02,Item03,mark,UCID,rownum,muteTime,holdTime,conferenceTime)
				   '
				   + @sch
				   + case when @bPrivilege > 0 then '
							and exists(select 1 from #t_record_p tp 
											where tp.recordid = m.recordid)' else '' end 
		print @sch--
		execute(@sch)

		update #T_Records set SurveyResult = sr.ResultId
			from #T_Records t,
					vxi_ivr..Survey sv,
					vxi_ivr..SurveyResult sr
			where t.StartDate = dbo.func_day(sv.StartTime)
				and sv.CallID = t.UCID
				and str(sr.ResultId, 1) = sv.Dtmf
				and len(rtrim(sv.CallID)) > 0
				and sv.StartTime between @StartTime_begin and @StartTime_end
				and t.rownum = 1
	
		set @sch = 'select RecordId, Calling, Called, 
							Answer, Finished, Skill, Master, AgentName, StartTime, 
							Seconds, Extension,Established,SurveyResult,Item01,Item02,Item03,mark,muteTime,holdTime,conferenceTime 
					from #T_Records'
	end
	
		
	if len(@SurveyResult) > 0 begin
		set @SurveyResult = ',' + @SurveyResult + ','
		select @sch = @sch + ' where charindex('','' + rtrim(SurveyResult) + '','', ''' + @SurveyResult + ''') > 0 '
	end
	
	--Paging--
	declare @cte0 varchar(2000),
			@cte1 varchar(2000),
			@cte2 varchar(2000),
			@SQLString	nvarchar(2000),
			@ParmDefine nvarchar(200)

	set @cte0 = ';with cte0 as('
				+ @sch	
				+ ')'
	set @cte1 = ',cte1 as(
					select top ' + str(@Page * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
	set @cte2 = ',cte2 as(
					select top ' + str((@Page - 1) * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
				
	set @SQLString = @cte0 + ' select @TotalCount = count(*) from cte0';

	set @ParmDefine = N'@TotalCount int OUTPUT';
	execute sp_executesql @SQLString, @ParmDefine, @TotalCount = @TotalCount OUTPUT;
	
	--print @TotalCount--
								
	set @sch = @cte0 + @cte1 + @cte2
				+ 'select top ' + str(@PageSize) + ' * from cte1 c1'
				+ ' where not exists(select 1 from cte2 c2
										where c1.RecordId = c2.RecordId
										)' 
										
	--print @sch

	execute(@sch)
	
	IF OBJECT_ID('tempdb..#t_record_p') IS NOT NULL BEGIN
		DROP TABLE #t_record_p
		PRINT 'drop temp table #t_record_p'
	END
	IF OBJECT_ID('tempdb..#T_Records') IS NOT NULL BEGIN
		DROP TABLE #T_Records
		PRINT 'drop temp table #T_Records'
	END
	IF OBJECT_ID('tempdb..#T_RecAsr') IS NOT NULL BEGIN
		DROP TABLE #T_RecAsr
		PRINT 'drop temp table #T_RecAsr'
	END

	return @TotalCount
	
END

GO
/****** Object:  StoredProcedure [dbo].[sp_sch_records_old1]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================
-- Author:		fei yu
-- Create date: 03/24/2008
-- Description:	<Description,,>
/* Example: 
exec sp_sch_records @audioasr='中华人民共和国'
exec sp_sch_records @ItemKey=2,@ItemValue='item02',
					@Finished=1
exec sp_sch_records @recordid=20100604000001
					--,@TaskList='10,20,103,206'
					--,@GroupList='10,20,103,206'
					--,@ExtList='10,20,103,206'
					--,@AgentList='10,20,103,206'
					,@SkillList='10,20,103,206'
exec sp_sch_records @num_begin=0,@num_end=30000
					,@custom=''
					,@StartTime_begin='20110920 00:00'
					,@StartTime_end='20130920 23:59'
					,@baudioasr=1
					,@audioasr='大象  老虎, 汽车  飞机'
					,@audioasr='老虎 飞机'
					,@audioasr='大象 老虎，飞机，汽车'
					
					,@PageSize=5
					,@Page=3			
exec sp_sch_records @calltype=1, @SchMode = 3
exec sp_sch_records @bLabel=1, @label='asdfa'
					,@SurveyResult='1'
*/
-- ====================================================
CREATE PROCEDURE [dbo].[sp_sch_records_old1]
	@recordid			bigint = 0,
	@num_begin			int = 0,
	@num_end			int = 0,
	@TaskList			varchar(200) = '',
	@GroupList			varchar(200) = '',
	@prjid				varchar(20) = '',
	@calltype			varchar(1) = null,
	@UcdId				bigint = 0,
	@Calling			varchar(20) = '',
	@Called				varchar(20) = '',
	@Answer				varchar(20) = '',
	@StartTime_begin	datetime = null,
	@StartTime_end		datetime = null,
	@AgentList			varchar(200) = '',
	@SkillList			varchar(200) = '',
	@ExtList			varchar(200) = '',
	@ItemNo				tinyint = 0,
	@Value				varchar(50) = '',
	@bLabel				bit = 0,
	@Label				varchar(2000) = '',
	@custom				varchar(20) = '',
	@audioasr			varchar(500) = '',
	
	@baudioasr			bit = 0,	--语音内容搜索是否包含搜索词
	
	@confidence			int = 60,
	@ItemKey			tinyint = 0,
	@ItemValue			varchar(20) = '',
	@Finished			tinyint = 0,
	@SurveyResult		varchar(20) = '',
	@SchMode			tinyint = 0,
	-- Paging --	
	@PageSize			int = 8000,		-- 页尺寸
	@Page				int = 1,		-- 页码
	@TotalCount			int = 1			-- 记录总数
	
AS
/*
@calltype-[0:Inner,1-Inbound,2-Outbound]
@SchMode-[0:Default,1-YongDa,2-NongXin,3-Banggo]
*/
BEGIN
	declare @sch		varchar(4000),
			@Item		varchar(20),
			@order_str	varchar(200),
			@sch1		varchar(4000),
			@sch2		varchar(4000),
			@audioasrs	varchar(500),
			@basr		bit,
			@ind        int,		  --搜索词个数1
			@ind1       int,		  --搜索词个数2
			@ind2       int,		  --搜索词个数3（既有空格又有逗号分隔）
			@var		int,		  --判断是否包含逗号	
			@spa        int,		  --判断是否包含空格
			@a			int,		  --循环使用变量1
			@b			int			  --循环使用变量1
			
	set @prjid = ltrim(rtrim(isnull(@prjid, '')))
	set @Calling = ltrim(rtrim(isnull(@Calling, ''))) 
	set @ExtList = ltrim(rtrim(isnull(@ExtList, ''))) 
	set @Called	= ltrim(rtrim(isnull(@Called, ''))) 
	set @Answer	= ltrim(rtrim(isnull(@Answer, ''))) 
	set @AgentList	= ltrim(rtrim(isnull(@AgentList, ''))) 
	set @SkillList = ltrim(rtrim(isnull(@SkillList, '')))
	set @TaskList = ltrim(rtrim(isnull(@TaskList, '')))
	set @GroupList = ltrim(rtrim(isnull(@GroupList, '')))
	set @label	= ltrim(rtrim(isnull(@label, ''))) 
	set @custom	= ltrim(rtrim(isnull(@custom, ''))) 
	set @Value = ltrim(rtrim(isnull(@Value, '')))
	set @bLabel = isnull(@bLabel, 0)
	set @Label = ltrim(rtrim(isnull(@Label, '')))
	set @order_str = ' order by m.starttime desc'
	set @SurveyResult = isnull(rtrim(@SurveyResult), '')
	set @SchMode = isnull(@SchMode, 0)
	
	set @audioasr = ltrim(rtrim(isnull(@audioasr, '')))
	set @baudioasr = isnull(@baudioasr, 0)	--语音内容是否包含
	select @basr = 0

	if @audioasr != '' set @basr = 1

	if @SchMode = 1 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension, 
							CallType = case when m.Inbound = 1 and m.Outbound = 0 then 1
											when m.Inbound = 0 and m.Outbound = 1 then 2
										else 0 end, 
							m.mark,''<a href=http://127.0.0.1/record/''+SUBSTRING(cast(m.RecordId as varchar(14)),1,8)+''/''+cast(m.Extension as varchar(4))+''/''+cast(m.RecordId as varchar(14))+''/''+cast(m.RecordId as varchar(14))+''.wav>下载</a>'' as DownLoad'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent '  
	end
	else if @SchMode = 2 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	else begin
		create table #T_records(RecordId bigint,Calling varchar(20),Called varchar(20),Answer varchar(20),Finished tinyint,
								Skill varchar(20),Master varchar(20),AgentName varchar(50),StartTime datetime,StartDate int,Seconds int,
								Extension varchar(20),SurveyResult int,Item01 varchar(50),Item02 varchar(50),Item03 varchar(50),mark varchar(10),
								UCID varchar(50),rownum int)
		set @sch = 'insert into #T_records(RecordId,Calling,Called,Answer,Finished,Skill,Master,AgentName,StartTime,
											StartDate,Seconds,Extension,Item01,Item02,Item03,mark,UCID,rownum)
					select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, m.StartDate,
							m.Seconds, m.Extension,	e.Item01, e.Item02, e.Item03, m.mark, m.UCID,
							rownum = row_number() over(partition by m.StartDate,m.UCID order by m.StartTime desc)'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	

	if @basr = 1 set @sch = @sch + ' left join vxi_rec..recasr s on s.recordid = m.recordid'

	set @sch = @sch + ' where m.Finished >= 1 and m.seconds > 1 ' --and isnull(m.AssRec, 0) = 0'
	
if @basr = 1 begin
	set @var=charindex(',',@audioasr)  --判断是否包含逗号
	set @spa=charindex(' ',rtrim(@audioasr))  --判断是否包含空格
		if @var>0 begin
			if @spa>0 begin		--既包含，又包含空格
					set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1
					if @baudioasr = 1 begin
							set @a=1
							---
							set @audioasrs=dbo.TrimString(dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a))
							set @ind1=(len(replace(@audioasrs,',','--'))-len(@audioasrs))+1
							set @sch1 = ' and ( ( asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',1) + '%'''	
							set @b=1
							while @b<@ind1 begin
								set @sch1 = @sch1 + ' and asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',@b+1) + '%'''
								set @b=@b+1
							end
							set @sch1 = @sch1 + ')'  
							--
							while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.TrimString(dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a))
									set @ind2=(len(replace(@audioasrs,',','--'))-len(@audioasrs))+1
									set @sch2 = ' and ( asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',@b) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
							end
							set @sch =@sch +@sch1+')'
					end
					else begin
							set @a=1
							---
							set @audioasrs=dbo.TrimString(dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a))
							set @ind1=(len(replace(@audioasrs,',','--'))-len(@audioasrs))+1
							set @sch1 = ' and ( ( asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',1) + '%'''	
							set @b=1
							while @b<@ind1 begin
								set @sch1 = @sch1 + ' and asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',@b+1) + '%'''
								set @b=@b+1
							end
							set @sch1 = @sch1 + ')'  
							--
							while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.TrimString(dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a))
									set @ind2=(len(replace(@audioasrs,',','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( asrresult like ''%'+dbo.Get_StrArrayStrOfIndex(@audioasrs,',',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,',',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2=@sch2
									set @sch1 =@sch1 +@sch2+')'
							end
							set @sch =@sch +@sch1+')'
					end
			end
			else begin			--仅包含逗号
					set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1
					if @baudioasr = 1 begin
						set @sch1 = 'and asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',1) + '%'''	
						--循环判断（声明一个循环始量，和条件字符串变量）
						set @a=1
						while @a<@ind begin
							set @sch1 =@sch1+'and asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
							set @a=@a+1
						end
						set @sch = @sch+@sch1
					end
					else begin
						set @sch1 = 'asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',1) + '%'''	
						--循环判断（声明一个循环始量和范围量，和条件字符串变量）
						set @a=1
						while @a<@ind begin
							set @sch1 = @sch1 + ' or asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
							set @a=@a+1
						end
						set @sch = @sch + ' and ('+	@sch1 +')' 
					end
			end
		end
		else begin
			if @spa>0 begin  --仅包含空格
					set @audioasr=dbo.TrimString(@audioasr)
					set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1
					if @baudioasr = 1 begin
						set @sch1 = 'and asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',1) + '%'''	
						--循环判断（声明一个循环始量，和条件字符串变量）
						set @a=1
						while @a<@ind  begin
								set @sch1 =@sch1+'and asrresult not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
								set @a=@a+1
						end
						set @sch = @sch+@sch1
					end
					else begin
						set @sch1 = 'and asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',1) + '%'''	
						--循环判断（声明一个循环始量和范围量，和条件字符串变量）
						set @a=1
						while @a<@ind begin
							set @sch1 = @sch1 + ' and asrresult like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
							set @a=@a+1
						end
						set @sch = @sch+@sch1
					end			
			end
			else begin
					if @baudioasr = 1 begin
						set @sch1 = 'and asrresult not like ''%' + @audioasr+ '%'''	
						set @sch = @sch+@sch1
					end
					else begin
						set @sch1 = 'and asrresult like ''%' +@audioasr + '%'''	
						set @sch = @sch+@sch1
					end			
			end
		end
end	
	if @bLabel = 1 begin
		if len(@Label) > 0 begin
			set @Label = ',' + @Label + ',' 
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid 
									and charindex('','' + rtrim(b.Title) + '','', ''' + @Label + ''') > 0)'
		end
		else begin
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid)'
		end
	end
		
	if isnull(@calltype, '') != '' begin
		select @sch = @sch + case when @calltype = 1 then ' and m.Inbound = 1 and m.Outbound = 0'
									when @calltype = 2 then ' and m.Inbound = 0 and m.Outbound = 1'
								else ' and m.Inbound = 0 and m.Outbound = 0' 
								end
	end
    else if (@custom != '')  begin
		select @sch = @sch + ' and ((m.Inbound = 1 and m.Outbound = 0 and m.Calling like ''' 
					+ @custom + '%'') or (m.Inbound = 0 and m.Outbound = 1 and m.Called like ''' + @custom + '%''))' 
	end

	if @recordid != 0
		select @sch = @sch + ' and m.recordid = ' + convert(varchar, @recordid)
		
	if @num_begin  != 0
		select @sch = @sch + ' and m.seconds > ' + convert(varchar, @num_begin )

	if @num_end != 0
		select @sch = @sch + ' and m.seconds < ' + convert(varchar, @num_end)

	if len(@TaskList) > 0 begin
		set @TaskList = ',' + @TaskList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.TaskId) + '','', ''' + @TaskList + ''') > 0 '
	end

	if Len(@GroupList) > 0 begin
		set @GroupList = ',' + @GroupList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, g.groupid) + '','', ''' + @GroupList + ''') > 0 '
	end

	if @prjid != ''
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.prjid) + '','', ''' + @prjid + ''') > 0 '

	if @UcdId != 0
		select @sch = @sch + ' and m.UcdId = ' + convert(varchar, @UcdId)

	if @Calling != ''
		select @sch = @sch + ' and m.Calling like ''' + @Calling + '%'''

	if @Called != ''
		select @sch = @sch + ' and m.Called like ''' + @Called + '%'''

	if @Answer != ''
		select @sch = @sch + ' and Answer = ''' + @Answer + ''''
		
	/*if @StartTime_begin is not null
		select @sch = @sch + ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''

	if @StartTime_end is not null
		select @sch = @sch + ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + '''' */

	if @StartTime_begin is not null and @StartTime_end is not null
		select @sch = @sch + ' and m.RecordId > ' + convert(varchar(20), vxi_def.dbo.time_to_bigint(@StartTime_begin,1) / 10000 * 1000000)
							+ ' and m.RecordId < ' + convert(varchar(20), vxi_def.dbo.time_to_bigint(@StartTime_end,1) / 10000 * 1000000 + 999999)
							+ ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''
							+ ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + ''''

	if len(@AgentList) > 0 begin
		set @AgentList = ',' + @AgentList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.agent) + '','' ,''' + @AgentList + ''') > 0 '
	end

	if len(@SkillList) > 0 begin
		set @SkillList = ',' + @SkillList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.skill) + '','' ,''' + @SkillList + ''') > 0 '
	end

	if len(@ExtList) > 0 begin
		set @ExtList = ',' + @ExtList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.Extension) + '','', ''' + @ExtList + ''') > 0 '
	end
	
	if len(@SurveyResult) > 0 begin
		set @SurveyResult = ',' + @SurveyResult + ','
		select @sch = @sch + ' and charindex('','' + rtrim(sv.Dtmf) + '','', ''' + @SurveyResult + ''') > 0 '
	end

	if not (@ItemNo is null or @ItemNo = 0 or @ItemNo > 10 or @Value ='')  begin
		if @ItemNo = 10  begin
			select @Item = ' e.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item = ' e.Item0' + cast(@ItemNo as varchar(10))	 
		end
		set @Value =  @Value + '%'
		select @sch = @sch + ' and ' + @item + ' like '''+ @Value +''''
	end
	
	if isnull(@ItemKey, 0) > 0 begin
		set @Item = case @ItemKey
							when 1 then 'e.Item01'
							when 2 then 'e.Item02'
							when 3 then 'e.Item03'
					else '' end
					
		if len(@Item) > 0 and len(@ItemValue) > 0 begin
			select @sch = @sch + ' and ' + @Item + ' = ''' + @ItemValue + ''''
		end
	end
	
	if isnull(@Finished, 0) > 0 begin
		select @sch = @sch + ' and m.Finished = ' + str(@Finished)
	end
	
	if @SchMode not in (1,2) begin
		print @sch--
		execute(@sch)

		update #T_Records set SurveyResult = sr.ResultId
			from #T_Records t,
					vxi_ivr..Survey sv,
					vxi_ivr..SurveyResult sr
			where t.StartDate = vxi_def.dbo.func_day(sv.StartTime)
				and sv.CallID = t.UCID
				and str(sr.ResultId, 1) = sv.Dtmf
				and len(rtrim(sv.CallID)) > 0
				and sv.StartTime between @StartTime_begin and @StartTime_end
				and t.rownum = 1
	
		set @sch = 'select RecordId, Calling, Called, 
							Answer, Finished, Skill, Master, AgentName, StartTime, 
							Seconds, Extension,	SurveyResult, Item01, Item02, Item03, mark 
					from #T_Records'
	end
	
	--Paging--
	declare @cte0 varchar(2000),
			@cte1 varchar(2000),
			@cte2 varchar(2000),
			@SQLString	nvarchar(2000),
			@ParmDefine nvarchar(200)

	set @cte0 = ';with cte0 as('
				+ @sch	
				+ ')'
	set @cte1 = ',cte1 as(
					select top ' + str(@Page * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
	set @cte2 = ',cte2 as(
					select top ' + str((@Page - 1) * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
				
	set @SQLString = @cte0 + ' select @TotalCount = count(*) from cte0';

	set @ParmDefine = N'@TotalCount int OUTPUT';
	execute sp_executesql @SQLString, @ParmDefine, @TotalCount = @TotalCount OUTPUT;
	
	--print @TotalCount--
								
	set @sch = @cte0 + @cte1 + @cte2
				+ 'select top ' + str(@PageSize) + ' * from cte1 c1'
				+ ' where not exists(select 1 from cte2 c2
										where c1.RecordId = c2.RecordId
										)' 
										
	--print @sch

	execute(@sch)
	
	IF OBJECT_ID('tempdb..#T_Records') IS NOT NULL BEGIN
		DROP TABLE #T_Records
		PRINT 'delete temp table #T_Records'
	END
	
	return @TotalCount
END



GO
/****** Object:  StoredProcedure [dbo].[sp_sch_records_old2]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =====================================================
-- Author:		fei yu
-- Create date: 03/24/2008
-- Description:	<Description,,>
/* Example: 
exec sp_sch_records @audioasr='中华人民共和国'
exec sp_sch_records @ItemKey=2,@ItemValue='item02',
					@Finished=1
exec sp_sch_records @recordid=20100604000001
					--,@TaskList='10,20,103,206'
					--,@GroupList='10,20,103,206'
					--,@ExtList='10,20,103,206'
					--,@AgentList='10,20,103,206'
					,@SkillList='10,20,103,206'
exec sp_sch_records @num_begin=0,@num_end=30000
					,@custom=''
					,@StartTime_begin='20130529 10:10'
					,@StartTime_end='20130529 23:59'
					,@baudioasr=1
					,@audioasr='三 六'		
					,@PageSize=5
					,@Page=3			
exec sp_sch_records @calltype=1, @SchMode = 3
exec sp_sch_records @bLabel=1, @label='asdfa'
					,@SurveyResult='1'
*/
-- ====================================================
CREATE PROCEDURE [dbo].[sp_sch_records_old2]
	@recordid			bigint = 0,
	@num_begin			int = 0,
	@num_end			int = 0,
	@TaskList			varchar(200) = '',
	@GroupList			varchar(200) = '',
	@prjid				varchar(20) = '',
	@calltype			varchar(1) = null,
	@UcdId				bigint = 0,
	@Calling			varchar(20) = '',
	@Called				varchar(20) = '',
	@Answer				varchar(20) = '',
	@StartTime_begin	datetime = null,
	@StartTime_end		datetime = null,
	@AgentList			varchar(200) = '',
	@SkillList			varchar(200) = '',
	@ExtList			varchar(200) = '',
	@ItemNo				tinyint = 0,
	@Value				varchar(50) = '',
	@bLabel				bit = 0,
	@Label				varchar(2000) = '',
	@custom				varchar(20) = '',
	@audioasr			varchar(500) = '',
	
	@baudioasr			bit = 0,	--语音内容搜索是否包含搜索词
	@asritem			int=0,		--asr检所选项
	
	@confidence			int = 60,
	@ItemKey			tinyint = 0,
	@ItemValue			varchar(20) = '',
	@Finished			tinyint = 0,
	@SurveyResult		varchar(20) = '',
	@SchMode			tinyint = 0,
	-- Paging --	
	@PageSize			int = 8000,		-- 页尺寸
	@Page				int = 1,		-- 页码
	@TotalCount			int = 1			-- 记录总数
	
AS
/*
@calltype-[0:Inner,1-Inbound,2-Outbound]
@SchMode-[0:Default,1-YongDa,2-NongXin,3-Banggo]
*/
BEGIN


	declare @sch		varchar(4000),
			@Item		varchar(20),
			@order_str	varchar(200),
			@sch1		varchar(4000),
			@sch2		varchar(4000),
			@audioasrs	varchar(500),
			@asrresult	varchar(20), --语音范围
			@basr		bit,
			@ind        int,		  --搜索词个数1
			@ind1       int,		  --搜索词个数2
			@ind2       int,		  --搜索词个数3（既有空格又有逗号分隔）
			@var		int,		  --判断是否包含逗号	
			@spa        int,		  --判断是否包含空格
			@a			int,		  --循环使用变量1
			@b			int			  --循环使用变量1
			
	set @prjid = ltrim(rtrim(isnull(@prjid, '')))
	set @Calling = ltrim(rtrim(isnull(@Calling, ''))) 
	set @ExtList = ltrim(rtrim(isnull(@ExtList, ''))) 
	set @Called	= ltrim(rtrim(isnull(@Called, ''))) 
	set @Answer	= ltrim(rtrim(isnull(@Answer, ''))) 
	set @AgentList	= ltrim(rtrim(isnull(@AgentList, ''))) 
	set @SkillList = ltrim(rtrim(isnull(@SkillList, '')))
	set @TaskList = ltrim(rtrim(isnull(@TaskList, '')))
	set @GroupList = ltrim(rtrim(isnull(@GroupList, '')))
	set @label	= ltrim(rtrim(isnull(@label, ''))) 
	set @custom	= ltrim(rtrim(isnull(@custom, ''))) 
	set @Value = ltrim(rtrim(isnull(@Value, '')))
	set @bLabel = isnull(@bLabel, 0)
	set @Label = ltrim(rtrim(isnull(@Label, '')))
	set @order_str = ' order by m.starttime desc'
	set @SurveyResult = isnull(rtrim(@SurveyResult), '')
	set @SchMode = isnull(@SchMode, 0)
	
	set @audioasr = ltrim(rtrim(isnull(@audioasr, '')))
	set @baudioasr = isnull(@baudioasr, 0)	--语音内容是否包含
	select @basr = 0

	if @audioasr != '' set @basr = 1

	if @SchMode = 1 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension, 
							CallType = case when m.Inbound = 1 and m.Outbound = 0 then 1
											when m.Inbound = 0 and m.Outbound = 1 then 2
										else 0 end, 
							m.mark,''<a href=http://127.0.0.1/record/''+SUBSTRING(cast(m.RecordId as varchar(14)),1,8)+''/''+cast(m.Extension as varchar(4))+''/''+cast(m.RecordId as varchar(14))+''/''+cast(m.RecordId as varchar(14))+''.wav>下载</a>'' as DownLoad'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent '  
	end
	else if @SchMode = 2 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	else begin
		create table #T_records(RecordId bigint,Calling varchar(20),Called varchar(20),Answer varchar(20),Finished tinyint,
								Skill varchar(20),Master varchar(20),AgentName varchar(50),StartTime datetime,StartDate int,Seconds int,
								Extension varchar(20),SurveyResult int,Item01 varchar(50),Item02 varchar(50),Item03 varchar(50),mark varchar(10),
								UCID varchar(50),rownum int)
		set @sch = 'insert into #T_records(RecordId,Calling,Called,Answer,Finished,Skill,Master,AgentName,StartTime,
											StartDate,Seconds,Extension,Item01,Item02,Item03,mark,UCID,rownum)
					select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, m.StartDate,
							m.Seconds, m.Extension,	e.Item01, e.Item02, e.Item03, m.mark, m.UCID,
							rownum = row_number() over(partition by m.StartDate,m.UCID order by m.StartTime desc)'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	
	if @asritem = 0 begin
			set @asrresult = 'asrresult'
	end
	else if @asritem = 1 begin
			set @asrresult = 'asrresultA'
	end
	else begin
			set @asrresult = 'asrresultB'
	end

	if @basr = 1 set @sch = @sch + ' left join vxi_rec..recasr s on s.recordid = m.recordid'

	set @sch = @sch + ' where m.Finished >= 1 and m.seconds > 1 ' --and isnull(m.AssRec, 0) = 0'
	
if @basr = 1 begin
	set @var=charindex('+',@audioasr)			 --判断是否包含加号
	set @spa=charindex(' ',rtrim(@audioasr))	 --判断是否包含空格
		if @spa>0 begin
				set @audioasr=dbo.TrimString(@audioasr)
				set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1	
--a+b  cc d+e+f				
				if @var>0 begin
							if @baudioasr = 1 begin
									set @a=1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
									set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @b=1
									set @sch1 = ' and ( ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
									while @b<@ind1 begin
												set @sch1 = @sch1 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
												set @b=@b+1
									end	
									set @sch1 = @sch1 + ')' 

									while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
									set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
									end
									set @sch =@sch +@sch1+')'
							end
							else begin
									set @a=1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
									set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @b=1
									set @sch1 = ' and ( ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
									while @b<@ind1 begin
												set @sch1 = @sch1 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b) + '%'''
												set @b=@b+1
									end	
									set @sch1 = @sch1 + ')' 

									while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
									set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
									end
									set @sch =@sch +@sch1+')'
							end
					end
--aa ccc ddddd
					else begin	
						if @baudioasr=1 begin
								set @a=1
								set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
								while @a<@ind begin
									set @sch1 =@sch1+'and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
									set @a=@a+1
								end
								set @sch = @sch + ' and ('+	@sch1 +')' 
						end
						else begin
								set @a=1
								set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
								while @a<@ind begin
									set @sch1 = @sch1 + ' or '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
									set @a=@a+1
								end
								set @sch = @sch + ' and ('+	@sch1 +')' 
						end
					end
		
		end
------------------------------------------
		else begin
--a+c+bss
			if @var>0 begin
				set @ind=(len(replace(@audioasr,'+','--'))-len(@audioasr))+1
							if @baudioasr = 1 begin
									set @a=1
									set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
									while @a<@ind  begin
										set @sch1 =@sch1+'or '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end
							else begin
									set @a=1
									set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
									while @a<@ind begin
										set @sch1 = @sch1 + ' and '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end		
			end
--a
			else begin
							if @baudioasr = 1 begin
									set @sch1 = 'and '+@asrresult+' not like ''%' + @audioasr+ '%'''	
									set @sch = @sch+@sch1
							end
							else begin
									set @sch1 = 'and '+@asrresult+' like ''%' +@audioasr + '%'''	
									set @sch = @sch+@sch1
							end			
			end
	end
end	

	if @bLabel = 1 begin
		if len(@Label) > 0 begin
			set @Label = ',' + @Label + ',' 
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid 
									and charindex('','' + rtrim(b.Title) + '','', ''' + @Label + ''') > 0)'
		end
		else begin
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid)'
		end
	end
		
	if isnull(@calltype, '') != '' begin
		select @sch = @sch + case when @calltype = 1 then ' and m.Inbound = 1 and m.Outbound = 0'
									when @calltype = 2 then ' and m.Inbound = 0 and m.Outbound = 1'
								else ' and m.Inbound = 0 and m.Outbound = 0' 
								end
	end
    else if (@custom != '')  begin
		select @sch = @sch + ' and ((m.Inbound = 1 and m.Outbound = 0 and m.Calling like ''' 
					+ @custom + '%'') or (m.Inbound = 0 and m.Outbound = 1 and m.Called like ''' + @custom + '%''))' 
	end

	if @recordid != 0
		select @sch = @sch + ' and m.recordid = ' + convert(varchar, @recordid)
		
	if @num_begin  != 0
		select @sch = @sch + ' and m.seconds >= ' + convert(varchar, @num_begin )

	if @num_end != 0
		select @sch = @sch + ' and m.seconds <= ' + convert(varchar, @num_end)

	if len(@TaskList) > 0 begin
		set @TaskList = ',' + @TaskList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.TaskId) + '','', ''' + @TaskList + ''') > 0 '
	end

	if Len(@GroupList) > 0 begin
		set @GroupList = ',' + @GroupList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, g.groupid) + '','', ''' + @GroupList + ''') > 0 '
	end

	if @prjid != ''
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.prjid) + '','', ''' + @prjid + ''') > 0 '

	if @UcdId != 0
		select @sch = @sch + ' and m.UcdId = ' + convert(varchar, @UcdId)

	if @Calling != ''
		select @sch = @sch + ' and m.Calling like ''' + @Calling + '%'''

	if @Called != ''
		select @sch = @sch + ' and m.Called like ''' + @Called + '%'''

	if @Answer != ''
		select @sch = @sch + ' and Answer = ''' + @Answer + ''''
		
	/*if @StartTime_begin is not null
		select @sch = @sch + ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''

	if @StartTime_end is not null
		select @sch = @sch + ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + '''' */

	if @StartTime_begin is not null and @StartTime_end is not null
		select @sch = @sch + ' and m.RecordId > ' + convert(varchar(20), vxi_def.dbo.time_to_bigint(@StartTime_begin,1) / 10000 * 1000000)
							+ ' and m.RecordId < ' + convert(varchar(20), vxi_def.dbo.time_to_bigint(@StartTime_end,1) / 10000 * 1000000 + 999999)
							+ ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''
							+ ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + ''''

	if len(@AgentList) > 0 begin
		set @AgentList = ',' + @AgentList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.agent) + '','' ,''' + @AgentList + ''') > 0 '
	end

	if len(@SkillList) > 0 begin
		set @SkillList = ',' + @SkillList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.skill) + '','' ,''' + @SkillList + ''') > 0 '
	end

	if len(@ExtList) > 0 begin
		set @ExtList = ',' + @ExtList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.Extension) + '','', ''' + @ExtList + ''') > 0 '
	end

	if not (@ItemNo is null or @ItemNo = 0 or @ItemNo > 10 or @Value ='')  begin
		if @ItemNo = 10  begin
			select @Item = ' e.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item = ' e.Item0' + cast(@ItemNo as varchar(10))	 
		end
		set @Value =  @Value + '%'
		select @sch = @sch + ' and ' + @item + ' like '''+ @Value +''''
	end
	
	if isnull(@ItemKey, 0) > 0 begin
		set @Item = case @ItemKey
							when 1 then 'e.Item01'
							when 2 then 'e.Item02'
							when 3 then 'e.Item03'
					else '' end
					
		if len(@Item) > 0 and len(@ItemValue) > 0 begin
			select @sch = @sch + ' and ' + @Item + ' = ''' + @ItemValue + ''''
		end
	end
	
	if isnull(@Finished, 0) > 0 begin
		select @sch = @sch + ' and m.Finished = ' + str(@Finished)
	end
	
	if @SchMode not in (1,2) begin
		--print @sch--
		execute(@sch)

		update #T_Records set SurveyResult = sr.ResultId
			from #T_Records t,
					vxi_ivr..Survey sv,
					vxi_ivr..SurveyResult sr
			where t.StartDate = vxi_def.dbo.func_day(sv.StartTime)
				and sv.CallID = t.UCID
				and str(sr.ResultId, 1) = sv.Dtmf
				and len(rtrim(sv.CallID)) > 0
				and sv.StartTime between @StartTime_begin and @StartTime_end
				and t.rownum = 1
	
		set @sch = 'select RecordId, Calling, Called, 
							Answer, Finished, Skill, Master, AgentName, StartTime, 
							Seconds, Extension,	SurveyResult, Item01, Item02, Item03, mark 
					from #T_Records'
	end
	
		
	if len(@SurveyResult) > 0 begin
		set @SurveyResult = ',' + @SurveyResult + ','
		select @sch = @sch + ' where charindex('','' + rtrim(SurveyResult) + '','', ''' + @SurveyResult + ''') > 0 '
	end
	
	--Paging--
	declare @cte0 varchar(2000),
			@cte1 varchar(2000),
			@cte2 varchar(2000),
			@SQLString	nvarchar(2000),
			@ParmDefine nvarchar(200)

	set @cte0 = ';with cte0 as('
				+ @sch	
				+ ')'
	set @cte1 = ',cte1 as(
					select top ' + str(@Page * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
	set @cte2 = ',cte2 as(
					select top ' + str((@Page - 1) * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
				
	set @SQLString = @cte0 + ' select @TotalCount = count(*) from cte0';

	set @ParmDefine = N'@TotalCount int OUTPUT';
	execute sp_executesql @SQLString, @ParmDefine, @TotalCount = @TotalCount OUTPUT;
	
	--print @TotalCount--
								
	set @sch = @cte0 + @cte1 + @cte2
				+ 'select top ' + str(@PageSize) + ' * from cte1 c1'
				+ ' where not exists(select 1 from cte2 c2
										where c1.RecordId = c2.RecordId
										)' 
										
	--print @sch

	execute(@sch)
	
	IF OBJECT_ID('tempdb..#T_Records') IS NOT NULL BEGIN
		DROP TABLE #T_Records
		PRINT 'delete temp table #T_Records'
	END
	
	return @TotalCount
END





GO
/****** Object:  StoredProcedure [dbo].[sp_sch_records_old3]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================
-- Author:		fei yu
-- Create date: 03/24/2008
-- Description:	<Description,,>
/* Example: 
exec sp_sch_records @ItemKey=2,@ItemValue='item02',
					@Finished=1
exec sp_sch_records @recordid=20130805000008
					--,@TaskList='10,20,103,206'
					--,@GroupList='10,20,103,206'
					--,@ExtList='10,20,103,206'
					--,@AgentList='10,20,103,206'
					,@SkillList='10,20,103,206'
exec sp_sch_records @num_begin=0,@num_end=30000
					,@custom='913918276356'
					,@StartTime_begin='20130529 10:10'
					,@StartTime_end='20130529 23:59'
					,@baudioasr=1
					,@audioasr=''		
					,@PageSize=5
					,@Page=3			
exec sp_sch_records @calltype=1, @SchMode = 3
exec sp_sch_records @bLabel=1, @label='asdfa'
					,@SurveyResult='1'
					
exec sp_sch_records @num_begin=0,@num_end=30000
					,@StartTime_begin='20110529 10:10'
					,@StartTime_end='20140529 23:59'
					,@audioasr='
					,@asritem='0'	
					
exec sp_sch_records @num_begin=0
					,@num_end=30000
					,@SkillList='10,20,103,206'
*/
-- ====================================================
CREATE PROCEDURE [dbo].[sp_sch_records_old3]
	@recordid			bigint = 0,
	@num_begin			int = 0,
	@num_end			int = 0,
	@TaskList			varchar(200) = '',
	@GroupList			varchar(200) = '',
	@prjid				varchar(20) = '',
	@calltype			varchar(1) = null,
	@UcdId				bigint = 0,
	@Calling			varchar(20) = '',
	@Called				varchar(20) = '',
	@Answer				varchar(20) = '',
	@StartTime_begin	datetime = null,
	@StartTime_end		datetime = null,
	@AgentList			varchar(200) = '',
	@SkillList			varchar(200) = '',
	@ExtList			varchar(200) = '',
	@ItemNo				tinyint = 0,
	@Value				varchar(50) = '',
	@bLabel				bit = 0,
	@Label				varchar(2000) = '',
	@custom				varchar(20) = '',
	@audioasr			varchar(500) = '',
	
	@baudioasr			bit = 0,	--语音内容搜索是否包含搜索词
	@asritem			int=0,		--asr检所选项
	
	@confidence			int = 60,
	@ItemKey			tinyint = 0,
	@ItemValue			varchar(20) = '',
	@Finished			tinyint = 0,
	@SurveyResult		varchar(20) = '',
	@SchMode			tinyint = 0,
	-- Paging --	
	@PageSize			int = 8000,		-- 页尺寸
	@Page				int = 1,		-- 页码
	@TotalCount			int = 1,		-- 记录总数
    -- hold,mute,confer统计
	@MutetimeFrom	    int = 0, 
	@MutetimeTo	        int = 0, 
	@HoldtimeFrom	    int = 0, 
	@HoldtimeTo	        int = 0, 
	@ConferencetimeFrom	int = 0, 
	@ConferencetimeTo	int = 0
AS
/*
@calltype-[0:Inner,1-Inbound,2-Outbound]
@SchMode-[0:Default,1-YongDa,2-NongXin,3-Banggo]
*/
BEGIN


	declare @sch		varchar(4000),
			@Item		varchar(20),
			@order_str	varchar(200),
			@sch1		varchar(4000),
			@sch2		varchar(4000),
			@audioasrs	varchar(500),
			@asrresult	varchar(20), --语音范围
			@basr		bit,
			@ind        int,		  --搜索词个数1
			@ind1       int,		  --搜索词个数2
			@ind2       int,		  --搜索词个数3（既有空格又有逗号分隔）
			@var		int,		  --判断是否包含逗号	
			@spa        int,		  --判断是否包含空格
			@a			int,		  --循环使用变量1
			@b			int			  --循环使用变量1
			
	set @prjid = ltrim(rtrim(isnull(@prjid, '')))
	set @Calling = ltrim(rtrim(isnull(@Calling, ''))) 
	set @ExtList = ltrim(rtrim(isnull(@ExtList, ''))) 
	set @Called	= ltrim(rtrim(isnull(@Called, ''))) 
	set @Answer	= ltrim(rtrim(isnull(@Answer, ''))) 
	set @AgentList	= ltrim(rtrim(isnull(@AgentList, ''))) 
	set @SkillList = ltrim(rtrim(isnull(@SkillList, '')))
	set @TaskList = ltrim(rtrim(isnull(@TaskList, '')))
	set @GroupList = ltrim(rtrim(isnull(@GroupList, '')))
	set @label	= ltrim(rtrim(isnull(@label, ''))) 
	set @custom	= ltrim(rtrim(isnull(@custom, ''))) 
	set @Value = ltrim(rtrim(isnull(@Value, '')))
	set @bLabel = isnull(@bLabel, 0)
	set @Label = ltrim(rtrim(isnull(@Label, '')))
	set @order_str = ' order by m.starttime desc'
	set @SurveyResult = isnull(rtrim(@SurveyResult), '')
	set @SchMode = isnull(@SchMode, 0)
	
	set @audioasr = ltrim(rtrim(isnull(@audioasr, '')))
	set @baudioasr = isnull(@baudioasr, 0)	--语音内容是否包含
	select @basr = 0

	if @audioasr != '' set @basr = 1

	if @SchMode = 1 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension,m.Established, 
							CallType = case when m.Inbound = 1 and m.Outbound = 0 then 1
											when m.Inbound = 0 and m.Outbound = 1 then 2
										else 0 end, 
							m.mark,''<a href=http://127.0.0.1/record/''+SUBSTRING(cast(m.RecordId as varchar(14)),1,8)+''/''+cast(m.Extension as varchar(4))+''/''+cast(m.RecordId as varchar(14))+''/''+cast(m.RecordId as varchar(14))+''.wav>下载</a>'' as DownLoad'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent '  
	end
	else if @SchMode = 2 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension,m.Established'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  --+ ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	else begin
		create table #T_records(RecordId bigint,Calling varchar(20),Called varchar(20),Answer varchar(20),Finished tinyint,
								Skill varchar(20),Master varchar(20),Established bit,AgentName varchar(50),StartTime datetime,StartDate int,Seconds int,
								Extension varchar(20),SurveyResult int,Item01 varchar(50),Item02 varchar(50),Item03 varchar(50),mark varchar(10),
								UCID varchar(50),rownum int,muteTime int, holdTime int, conferenceTime int)
		set @sch = 'insert into #T_records(RecordId,Calling,Called,Answer,Finished,Skill,Master,Established,AgentName,StartTime,
											StartDate,Seconds,Extension,Item01,Item02,Item03,mark,UCID,rownum,muteTime,holdTime,conferenceTime)
					select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master,m.Established, a.AgentName, m.StartTime, m.StartDate,
							m.Seconds, m.Extension,	e.Item01, e.Item02, e.Item03, m.mark, m.UCID,
							rownum = row_number() over(partition by m.StartDate,m.UCID order by m.StartTime desc),
							isnull(ra.muteTime, 0) muteTime, isnull(ra.holdTime, 0) holdTime, isnull(ra.conferenceTime, 0) conferenceTime'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  --+ ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
		  -- hold,mute,confer统计
		  +	'left join (
						 select recadd.recordid, 
							sum(case when recadd.eventtype = 0 then 1 else 0 end) holdTime,
							sum(case when recadd.eventtype = 1 then 1 else 0 end) conferenceTime,
							sum(case when recadd.eventtype = 2 then 1 else 0 end) muteTime
						 from RecAdditional recadd
						 group by recordid
						) ra on m.recordid = ra.recordid ' 
	end
	
	CREATE TABLE #T_RecAsr (RecordId bigint,AsrResult text) 
	
	IF OBJECT_ID('tempdb..#T_RecAsr') IS NOT NULL BEGIN
		 set @asrresult = 'AsrResult'
	END
	
    if isnull(@asritem, 0) != 4 begin
		INSERT  INTO #T_RecAsr
		select * from vxi_rec.dbo.Format_AsrResult(@asritem)
	end

	if @basr = 1 set @sch = @sch + ' left join #T_RecAsr s on s.recordid = m.recordid'

	set @sch = @sch + ' where m.Finished >= 1 and m.seconds > 1 ' --and isnull(m.AssRec, 0) = 0'
	
if @basr = 1 begin
	set @var=charindex('+',@audioasr)			 --判断是否包含加号
	set @spa=charindex(' ',rtrim(@audioasr))	 --判断是否包含空格
		if @spa>0 begin
				set @audioasr=dbo.TrimString(@audioasr)
				set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1	
--a+b  cc d+e+f				
				if @var>0 begin
							if @baudioasr = 1 begin
									set @a=1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
									set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @b=1
									set @sch1 = ' and ( ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
									while @b<@ind1 begin
												set @sch1 = @sch1 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
												set @b=@b+1
									end	
									set @sch1 = @sch1 + ')' 

									while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
									set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
									end
									set @sch =@sch +@sch1+')'
							end
							else begin
									set @a=1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
									set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @b=1
									set @sch1 = ' and ( ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
									while @b<@ind1 begin
												set @sch1 = @sch1 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b) + '%'''
												set @b=@b+1
									end	
									set @sch1 = @sch1 + ')' 

									while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
									set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
									end
									set @sch =@sch +@sch1+')'
							end
					end
--aa ccc ddddd
					else begin	
						if @baudioasr=1 begin
								set @a=1
								set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
								while @a<@ind begin
									set @sch1 =@sch1+'and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
									set @a=@a+1
								end
								set @sch = @sch + ' and ('+	@sch1 +')' 
						end
						else begin
								set @a=1
								set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
								while @a<@ind begin
									set @sch1 = @sch1 + ' or '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
									set @a=@a+1
								end
								set @sch = @sch + ' and ('+	@sch1 +')' 
						end
					end
		
		end
------------------------------------------
		else begin
--a+c+bss
			if @var>0 begin
				set @ind=(len(replace(@audioasr,'+','--'))-len(@audioasr))+1
							if @baudioasr = 1 begin
									set @a=1
									set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
									while @a<@ind  begin
										set @sch1 =@sch1+'or '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end
							else begin
									set @a=1
									set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
									while @a<@ind begin
										set @sch1 = @sch1 + ' and '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end		
			end
--a
			else begin
							if @baudioasr = 1 begin
									set @sch1 = 'and '+@asrresult+' not like ''%' + @audioasr+ '%'''	
									set @sch = @sch+@sch1
							end
							else begin
									set @sch1 = 'and '+@asrresult+' like ''%' +@audioasr + '%'''	
									set @sch = @sch+@sch1
							end			
			end
	end
end	

	if @bLabel = 1 begin
		if len(@Label) > 0 begin
			set @Label = ',' + @Label + ',' 
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid 
									and charindex('','' + rtrim(b.Title) + '','', ''' + @Label + ''') > 0)'
		end
		else begin
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid)'
		end
	end
		
	if isnull(@calltype, '') != '' begin
		select @sch = @sch + case when @calltype = 1 then ' and m.Inbound = 1 and m.Outbound = 0'
									when @calltype = 2 then ' and m.Inbound = 0 and m.Outbound = 1'
								else ' and m.Inbound = 0 and m.Outbound = 0' 
								end
	end
    else if (@custom != '')  begin
		--select @sch = @sch + ' and ((m.Inbound = 1 and m.Outbound = 0 and m.Calling like ''' 
		--			+ @custom + '%'') or (m.Inbound = 0 and m.Outbound = 1 and m.Called like ''' + @custom + '%''))' 
		select @sch = @sch + ' and (( m.Calling like ''' 
					+ @custom + '%'') or ( m.Called like ''' + @custom + '%''))' 
	end

	if @recordid != 0
		select @sch = @sch + ' and m.recordid = ' + convert(varchar, @recordid)
		
	if @num_begin  != 0
		select @sch = @sch + ' and m.seconds >= ' + convert(varchar, @num_begin )

	if @num_end != 0
		select @sch = @sch + ' and m.seconds <= ' + convert(varchar, @num_end)

	-- hold mute confer 统计
	if (@MutetimeTo !=0)  
		select @sch = @sch + ' and isnull(ra.muteTime, 0) between ' + str(@MutetimeFrom) + ' and ' + str(@MutetimeTo) 
	if (@HoldtimeTo !=0)  
		select @sch = @sch + ' and isnull(ra.holdTime, 0) between ' + str(@HoldtimeFrom) + ' and ' + str(@HoldtimeTo) 
	if (@ConferencetimeTo !=0)  
		select @sch = @sch + ' and isnull(ra.conferenceTime, 0) between ' + str(@ConferencetimeFrom) + ' and ' + str(@ConferencetimeTo) 

	if len(@TaskList) > 0 begin
		set @TaskList = ',' + @TaskList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.TaskId) + '','', ''' + @TaskList + ''') > 0 '
	end

	if Len(@GroupList) > 0 begin
		set @GroupList = ',' + @GroupList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, g.groupid) + '','', ''' + @GroupList + ''') > 0 '
	end

	if @prjid != ''
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.prjid) + '','', ''' + @prjid + ''') > 0 '

	if @UcdId != 0
		select @sch = @sch + ' and m.UcdId = ' + convert(varchar, @UcdId)

	if @Calling != ''
		select @sch = @sch + ' and m.Calling like ''%' + @Calling + '%'''

	if @Called != ''
		select @sch = @sch + ' and m.Called like ''%' + @Called + '%'''

	if @Answer != ''
		select @sch = @sch + ' and Answer like ''%' + @Answer + '%'''
		
	if @StartTime_begin is not null and @StartTime_end is not null begin
		select @sch = @sch + ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''
							+ ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + ''''
	end
	else begin
		select @sch = @sch + ' and m.RecordId > ' + convert(varchar(20), dbo.time_to_bigint(@StartTime_begin,1) / 10000 * 1000000)
							+ ' and m.RecordId < ' + convert(varchar(20), dbo.time_to_bigint(@StartTime_end,1) / 10000 * 1000000 + 999999)
	end

	if len(@AgentList) > 0 begin
		set @AgentList = ',' + @AgentList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.agent) + '','' ,''' + @AgentList + ''') > 0 '
	end

	if len(@SkillList) > 0 begin
		set @SkillList = ',' + @SkillList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.skill) + '','' ,''' + @SkillList + ''') > 0 '
	end

	if len(@ExtList) > 0 begin
		set @ExtList = ',' + @ExtList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.Extension) + '','', ''' + @ExtList + ''') > 0 '
	end

	if not (@ItemNo is null or @ItemNo = 0 or @ItemNo > 10 or @Value ='')  begin
		if @ItemNo = 10  begin
			select @Item = ' e.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item = ' e.Item0' + cast(@ItemNo as varchar(10))	 
		end
		set @Value =  @Value + '%'
		select @sch = @sch + ' and ' + @item + ' like '''+ @Value +''''
	end
	
	if isnull(@ItemKey, 0) > 0 begin
		set @Item = case @ItemKey
							when 1 then 'e.Item01'
							when 2 then 'e.Item02'
							when 3 then 'e.Item03'
					else '' end
					
		if len(@Item) > 0 and len(@ItemValue) > 0 begin
			select @sch = @sch + ' and ' + @Item + ' = ''' + @ItemValue + ''''
		end
	end
	
	if isnull(@Finished, 0) > 0 begin
		select @sch = @sch + ' and m.Finished = ' + str(@Finished)
	end
	
	if @SchMode not in (1,2) begin
		print @sch--
		execute(@sch)

		update #T_Records set SurveyResult = sr.ResultId
			from #T_Records t,
					vxi_ivr..Survey sv,
					vxi_ivr..SurveyResult sr
			where t.StartDate = dbo.func_day(sv.StartTime)
				and sv.CallID = t.UCID
				and str(sr.ResultId, 1) = sv.Dtmf
				and len(rtrim(sv.CallID)) > 0
				and sv.StartTime between @StartTime_begin and @StartTime_end
				and t.rownum = 1
	
		set @sch = 'select RecordId, Calling, Called, 
							Answer, Finished, Skill, Master, AgentName, StartTime, 
							Seconds, Extension,Established,SurveyResult,Item01,Item02,Item03,mark,muteTime,holdTime,conferenceTime 
					from #T_Records'
	end
	
		
	if len(@SurveyResult) > 0 begin
		set @SurveyResult = ',' + @SurveyResult + ','
		select @sch = @sch + ' where charindex('','' + rtrim(SurveyResult) + '','', ''' + @SurveyResult + ''') > 0 '
	end
	
	--Paging--
	declare @cte0 varchar(2000),
			@cte1 varchar(2000),
			@cte2 varchar(2000),
			@SQLString	nvarchar(2000),
			@ParmDefine nvarchar(200)

	set @cte0 = ';with cte0 as('
				+ @sch	
				+ ')'
	set @cte1 = ',cte1 as(
					select top ' + str(@Page * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
	set @cte2 = ',cte2 as(
					select top ' + str((@Page - 1) * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
				
	set @SQLString = @cte0 + ' select @TotalCount = count(*) from cte0';

	set @ParmDefine = N'@TotalCount int OUTPUT';
	execute sp_executesql @SQLString, @ParmDefine, @TotalCount = @TotalCount OUTPUT;
	
	--print @TotalCount--
								
	set @sch = @cte0 + @cte1 + @cte2
				+ 'select top ' + str(@PageSize) + ' * from cte1 c1'
				+ ' where not exists(select 1 from cte2 c2
										where c1.RecordId = c2.RecordId
										)' 
										
	--print @sch

	execute(@sch)
	
	IF OBJECT_ID('tempdb..#T_Records') IS NOT NULL BEGIN
		DROP TABLE #T_Records
		PRINT 'delete temp table #T_Records'
	END
	
	IF OBJECT_ID('tempdb..#T_RecAsr') IS NOT NULL BEGIN
		DROP TABLE #T_RecAsr
		PRINT 'delete temp table #T_RecAsr'
	END
	
	
	return @TotalCount
END

GO
/****** Object:  StoredProcedure [dbo].[sp_sch_records_test]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================
-- Author:		fei yu
-- Create date: 03/24/2008
-- Description:	<Description,,>
/* Example: 
exec sp_sch_records_test @audioasr='中华人民共和国'
exec sp_sch_records_test @ItemKey=2,@ItemValue='item02',
					@Finished=1
exec sp_sch_records_test @recordid=20100604000001
					--,@TaskList='10,20,103,206'
					--,@GroupList='10,20,103,206'
					--,@ExtList='10,20,103,206'
					--,@AgentList='10,20,103,206'
					,@SkillList='10,20,103,206'
exec sp_sch_records_test @num_begin=0,@num_end=30000
					,@custom=''
					,@StartTime_begin='20130529 10:10'
					,@StartTime_end='20130529 23:59'
					,@baudioasr=1
					,@audioasr='三 六'		
					,@PageSize=5
					,@Page=3			
exec sp_sch_records_test @calltype=1, @SchMode = 3,@SurveyResult='5'
exec sp_sch_records_test @bLabel=1, @label='asdfa'
					,@SurveyResult='1'
*/
-- ====================================================
CREATE PROCEDURE [dbo].[sp_sch_records_test]
	@recordid			bigint = 0,
	@num_begin			int = 0,
	@num_end			int = 0,
	@TaskList			varchar(200) = '',
	@GroupList			varchar(200) = '',
	@prjid				varchar(20) = '',
	@calltype			varchar(1) = null,
	@UcdId				bigint = 0,
	@Calling			varchar(20) = '',
	@Called				varchar(20) = '',
	@Answer				varchar(20) = '',
	@StartTime_begin	datetime = null,
	@StartTime_end		datetime = null,
	@AgentList			varchar(200) = '',
	@SkillList			varchar(200) = '',
	@ExtList			varchar(200) = '',
	@ItemNo				tinyint = 0,
	@Value				varchar(50) = '',
	@bLabel				bit = 0,
	@Label				varchar(2000) = '',
	@custom				varchar(20) = '',
	@audioasr			varchar(500) = '',
	
	@baudioasr			bit = 0,	--语音内容搜索是否包含搜索词
	@asritem			int=0,		--asr检所选项
	
	@confidence			int = 60,
	@ItemKey			tinyint = 0,
	@ItemValue			varchar(20) = '',
	@Finished			tinyint = 0,
	@SurveyResult		varchar(20) = '',
	@SchMode			tinyint = 0,
	-- Paging --	
	@PageSize			int = 8000,		-- 页尺寸
	@Page				int = 1,		-- 页码
	@TotalCount			int = 1			-- 记录总数
	
AS
/*
@calltype-[0:Inner,1-Inbound,2-Outbound]
@SchMode-[0:Default,1-YongDa,2-NongXin,3-Banggo]
*/
BEGIN
	declare @sch		varchar(4000),
			@Item		varchar(20),
			@order_str	varchar(200),
			@sch1		varchar(4000),
			@sch2		varchar(4000),
			@audioasrs	varchar(500),
			@asrresult	varchar(20), --语音范围
			@basr		bit,
			@ind        int,		  --搜索词个数1
			@ind1       int,		  --搜索词个数2
			@ind2       int,		  --搜索词个数3（既有空格又有逗号分隔）
			@var		int,		  --判断是否包含逗号	
			@spa        int,		  --判断是否包含空格
			@a			int,		  --循环使用变量1
			@b			int			  --循环使用变量1
			
	set @prjid = ltrim(rtrim(isnull(@prjid, '')))
	set @Calling = ltrim(rtrim(isnull(@Calling, ''))) 
	set @ExtList = ltrim(rtrim(isnull(@ExtList, ''))) 
	set @Called	= ltrim(rtrim(isnull(@Called, ''))) 
	set @Answer	= ltrim(rtrim(isnull(@Answer, ''))) 
	set @AgentList	= ltrim(rtrim(isnull(@AgentList, ''))) 
	set @SkillList = ltrim(rtrim(isnull(@SkillList, '')))
	set @TaskList = ltrim(rtrim(isnull(@TaskList, '')))
	set @GroupList = ltrim(rtrim(isnull(@GroupList, '')))
	set @label	= ltrim(rtrim(isnull(@label, ''))) 
	set @custom	= ltrim(rtrim(isnull(@custom, ''))) 
	set @Value = ltrim(rtrim(isnull(@Value, '')))
	set @bLabel = isnull(@bLabel, 0)
	set @Label = ltrim(rtrim(isnull(@Label, '')))
	set @order_str = ' order by m.starttime desc'
	set @SurveyResult = isnull(rtrim(@SurveyResult), '')
	set @SchMode = isnull(@SchMode, 0)
	
	set @audioasr = ltrim(rtrim(isnull(@audioasr, '')))
	set @baudioasr = isnull(@baudioasr, 0)	--语音内容是否包含
	select @basr = 0

	if @audioasr != '' set @basr = 1

	if @SchMode = 1 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension, 
							CallType = case when m.Inbound = 1 and m.Outbound = 0 then 1
											when m.Inbound = 0 and m.Outbound = 1 then 2
										else 0 end, 
							m.mark,''<a href=http://127.0.0.1/record/''+SUBSTRING(cast(m.RecordId as varchar(14)),1,8)+''/''+cast(m.Extension as varchar(4))+''/''+cast(m.RecordId as varchar(14))+''/''+cast(m.RecordId as varchar(14))+''.wav>下载</a>'' as DownLoad'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent '  
	end
	else if @SchMode = 2 begin
		set @sch = 'select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, 
							m.Seconds, m.Extension'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	else begin
		create table #T_records(RecordId bigint,Calling varchar(20),Called varchar(20),Answer varchar(20),Finished tinyint,
								Skill varchar(20),Master varchar(20),AgentName varchar(50),StartTime datetime,StartDate int,Seconds int,
								Extension varchar(20),SurveyResult int,Item01 varchar(50),Item02 varchar(50),Item03 varchar(50),mark varchar(10),
								UCID varchar(50),rownum int)
		set @sch = 'insert into #T_records(RecordId,Calling,Called,Answer,Finished,Skill,Master,AgentName,StartTime,
											StartDate,Seconds,Extension,Item01,Item02,Item03,mark,UCID,rownum)
					select m.RecordId, m.Calling, m.Called, 
							m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, m.StartDate,
							m.Seconds, m.Extension,	e.Item01, e.Item02, e.Item03, m.mark, m.UCID,
							rownum = row_number() over(partition by m.StartDate,m.UCID order by m.StartTime desc)'
		  + ' from vxi_rec..records m'
		  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid'
		  + ' left join vxi_sys..Agent a on a.agent = m.agent' 
		  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
		  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
	end
	
	if @asritem = 0 begin
			set @asrresult = 'asrresult'
	end
	else if @asritem = 1 begin
			set @asrresult = 'asrresultA'
	end
	else begin
			set @asrresult = 'asrresultB'
	end

	if @basr = 1 set @sch = @sch + ' left join vxi_rec..recasr s on s.recordid = m.recordid'

	set @sch = @sch + ' where m.Finished >= 1 and m.seconds > 1 ' --and isnull(m.AssRec, 0) = 0'
	
if @basr = 1 begin
	set @var=charindex('+',@audioasr)			 --判断是否包含加号
	set @spa=charindex(' ',rtrim(@audioasr))	 --判断是否包含空格
		if @spa>0 begin
				set @audioasr=dbo.TrimString(@audioasr)
				set @ind=(len(replace(@audioasr,',','--'))-len(@audioasr))+1	
--a+b  cc d+e+f				
				if @var>0 begin
							if @baudioasr = 1 begin
									set @a=1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
									set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @b=1
									set @sch1 = ' and ( ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
									while @b<@ind1 begin
												set @sch1 = @sch1 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
												set @b=@b+1
									end	
									set @sch1 = @sch1 + ')' 

									while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
									set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
									end
									set @sch =@sch +@sch1+')'
							end
							else begin
									set @a=1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',1)
									set @ind1=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @b=1
									set @sch1 = ' and ( ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''	
									while @b<@ind1 begin
												set @sch1 = @sch1 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b) + '%'''
												set @b=@b+1
									end	
									set @sch1 = @sch1 + ')' 

									while @a<@ind begin
									set @a=@a+1
									set @audioasrs=dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a)
									set @ind2=(len(replace(@audioasrs,'+','--'))-len(@audioasrs))+1
									set @sch2 = ' or ( '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',1) + '%'''
									set @b=1
									while @b<@ind2 begin
											set @sch2 = @sch2 + ' and '+@asrresult+'  like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasrs,'+',@b+1) + '%'''
											set @b=@b+1
									end
									set @sch2 =@sch2 +')'
									set @sch1 =@sch1 +@sch2
									end
									set @sch =@sch +@sch1+')'
							end
					end
--aa ccc ddddd
					else begin	
						if @baudioasr=1 begin
								set @a=1
								set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
								while @a<@ind begin
									set @sch1 =@sch1+'and '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
									set @a=@a+1
								end
								set @sch = @sch + ' and ('+	@sch1 +')' 
						end
						else begin
								set @a=1
								set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a) + '%'''
								while @a<@ind begin
									set @sch1 = @sch1 + ' or '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,',',@a+1) + '%'''
									set @a=@a+1
								end
								set @sch = @sch + ' and ('+	@sch1 +')' 
						end
					end
		
		end
------------------------------------------
		else begin
--a+c+bss
			if @var>0 begin
				set @ind=(len(replace(@audioasr,'+','--'))-len(@audioasr))+1
							if @baudioasr = 1 begin
									set @a=1
									set @sch1 =@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
									while @a<@ind  begin
										set @sch1 =@sch1+'or '+@asrresult+' not like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end
							else begin
									set @a=1
									set @sch1 =@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a) + '%'''
									while @a<@ind begin
										set @sch1 = @sch1 + ' and '+@asrresult+' like ''%' + dbo.Get_StrArrayStrOfIndex(@audioasr,'+',@a+1) + '%'''
										set @a=@a+1
									end
									set @sch = @sch + ' and ('+	@sch1 +')' 
							end		
			end
--a
			else begin
							if @baudioasr = 1 begin
									set @sch1 = 'and '+@asrresult+' not like ''%' + @audioasr+ '%'''	
									set @sch = @sch+@sch1
							end
							else begin
									set @sch1 = 'and '+@asrresult+' like ''%' +@audioasr + '%'''	
									set @sch = @sch+@sch1
							end			
			end
	end
end	

	if @bLabel = 1 begin
		if len(@Label) > 0 begin
			set @Label = ',' + @Label + ',' 
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid 
									and charindex('','' + rtrim(b.Title) + '','', ''' + @Label + ''') > 0)'
		end
		else begin
			select @sch = @sch + ' and exists(select 1 from vxi_rec..label b where b.recordid = m.recordid)'
		end
	end
		
	if isnull(@calltype, '') != '' begin
		select @sch = @sch + case when @calltype = 1 then ' and m.Inbound = 1 and m.Outbound = 0'
									when @calltype = 2 then ' and m.Inbound = 0 and m.Outbound = 1'
								else ' and m.Inbound = 0 and m.Outbound = 0' 
								end
	end
    else if (@custom != '')  begin
		select @sch = @sch + ' and ((m.Inbound = 1 and m.Outbound = 0 and m.Calling like ''' 
					+ @custom + '%'') or (m.Inbound = 0 and m.Outbound = 1 and m.Called like ''' + @custom + '%''))' 
	end

	if @recordid != 0
		select @sch = @sch + ' and m.recordid = ' + convert(varchar, @recordid)
		
	if @num_begin  != 0
		select @sch = @sch + ' and m.seconds > ' + convert(varchar, @num_begin )

	if @num_end != 0
		select @sch = @sch + ' and m.seconds < ' + convert(varchar, @num_end)

	if len(@TaskList) > 0 begin
		set @TaskList = ',' + @TaskList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.TaskId) + '','', ''' + @TaskList + ''') > 0 '
	end

	if Len(@GroupList) > 0 begin
		set @GroupList = ',' + @GroupList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, g.groupid) + '','', ''' + @GroupList + ''') > 0 '
	end

	if @prjid != ''
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.prjid) + '','', ''' + @prjid + ''') > 0 '

	if @UcdId != 0
		select @sch = @sch + ' and m.UcdId = ' + convert(varchar, @UcdId)

	if @Calling != ''
		select @sch = @sch + ' and m.Calling like ''' + @Calling + '%'''

	if @Called != ''
		select @sch = @sch + ' and m.Called like ''' + @Called + '%'''

	if @Answer != ''
		select @sch = @sch + ' and Answer = ''' + @Answer + ''''
		
	/*if @StartTime_begin is not null
		select @sch = @sch + ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''

	if @StartTime_end is not null
		select @sch = @sch + ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + '''' */

	if @StartTime_begin is not null and @StartTime_end is not null
		select @sch = @sch + ' and m.RecordId > ' + convert(varchar(20), vxi_def.dbo.time_to_bigint(@StartTime_begin,1) / 10000 * 1000000)
							+ ' and m.RecordId < ' + convert(varchar(20), vxi_def.dbo.time_to_bigint(@StartTime_end,1) / 10000 * 1000000 + 999999)
							+ ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''
							+ ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + ''''

	if len(@AgentList) > 0 begin
		set @AgentList = ',' + @AgentList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.agent) + '','' ,''' + @AgentList + ''') > 0 '
	end

	if len(@SkillList) > 0 begin
		set @SkillList = ',' + @SkillList + ','
		select @sch = @sch + ' and charindex('','' + rtrim(m.skill) + '','' ,''' + @SkillList + ''') > 0 '
	end

	if len(@ExtList) > 0 begin
		set @ExtList = ',' + @ExtList + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, m.Extension) + '','', ''' + @ExtList + ''') > 0 '
	end
	


	if not (@ItemNo is null or @ItemNo = 0 or @ItemNo > 10 or @Value ='')  begin
		if @ItemNo = 10  begin
			select @Item = ' e.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item = ' e.Item0' + cast(@ItemNo as varchar(10))	 
		end
		set @Value =  @Value + '%'
		select @sch = @sch + ' and ' + @item + ' like '''+ @Value +''''
	end
	
	if isnull(@ItemKey, 0) > 0 begin
		set @Item = case @ItemKey
							when 1 then 'e.Item01'
							when 2 then 'e.Item02'
							when 3 then 'e.Item03'
					else '' end
					
		if len(@Item) > 0 and len(@ItemValue) > 0 begin
			select @sch = @sch + ' and ' + @Item + ' = ''' + @ItemValue + ''''
		end
	end
	
	if isnull(@Finished, 0) > 0 begin
		select @sch = @sch + ' and m.Finished = ' + str(@Finished)
	end
	
	if @SchMode not in (1,2) begin
		--print @sch--
		execute(@sch)

		update #T_Records set SurveyResult = sr.ResultId
			from #T_Records t,
					vxi_ivr..Survey sv,
					vxi_ivr..SurveyResult sr
			where 
			t.StartDate = vxi_def.dbo.func_day(sv.StartTime) and 
				sv.CallID = t.UCID
				and str(sr.ResultId, 1) = sv.Dtmf
				and len(rtrim(sv.CallID)) > 0
				and sv.StartTime between @StartTime_begin and @StartTime_end
				and t.rownum = 1
	
		set @sch = 'select RecordId, Calling, Called, 
							Answer, Finished, Skill, Master, AgentName, StartTime, 
							Seconds, Extension,	SurveyResult, Item01, Item02, Item03, mark 
					from #T_Records '
	end
	
	
	if len(@SurveyResult) > 0 begin
		set @SurveyResult = ',' + @SurveyResult + ','
		select @sch = @sch + ' where charindex('','' + rtrim(SurveyResult) + '','', ''' + @SurveyResult + ''') > 0 '
	end
	
	--Paging--
	declare @cte0 varchar(2000),
			@cte1 varchar(2000),
			@cte2 varchar(2000),
			@SQLString	nvarchar(2000),
			@ParmDefine nvarchar(200)

	set @cte0 = ';with cte0 as('
				+ @sch	
				+ ')'
	set @cte1 = ',cte1 as(
					select top ' + str(@Page * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
	set @cte2 = ',cte2 as(
					select top ' + str((@Page - 1) * @PageSize) + ' * from cte0 m'
					+ @order_str
				+ ')'
				
	set @SQLString = @cte0 + ' select @TotalCount = count(*) from cte0';
	

	set @ParmDefine = N'@TotalCount int OUTPUT';
	execute sp_executesql @SQLString, @ParmDefine, @TotalCount = @TotalCount OUTPUT;
	
	--print @TotalCount--
								
	set @sch = @cte0 + @cte1 + @cte2
				+ 'select top ' + str(@PageSize) + ' * from cte1 c1'
				+ ' where not exists(select 1 from cte2 c2
										where c1.RecordId = c2.RecordId
										)' 
										
	--print @sch

	execute(@sch)
	
	IF OBJECT_ID('tempdb..#T_Records') IS NOT NULL BEGIN
		DROP TABLE #T_Records
		PRINT 'delete temp table #T_Records'
	END
	
	return @TotalCount
END
GO
/****** Object:  StoredProcedure [dbo].[sp_schsql_submit]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =====================================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2012.4.23>
-- Description:	<Description,,>
/* Example: 
exec sp_schsql_submit @SchSql='select distinct m.RecordId, m.Calling, m.Called, 
								m.Answer, m.Finished, m.Skill, m.Agent as Master, a.AgentName, m.StartTime, 
								m.Seconds, m.Extension, e.Item01, e.Item02, e.Item03, m.mark 
			from vxi_rec..records m left join vxi_rec..taskrec r on r.recordid = m.recordid 
			left join vxi_sys..Agent a on a.agent = m.agent 
			left join vxi_rec..grouprec g on g.recordid = m.recordid 
			left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1 where m.Finished >= 1 
				and m.seconds > 1  and m.seconds < 30000 
				and m.StartTime > ''2011-08-01 00:00:00'' 
				and m.StartTime < ''2011-08-31 23:59:00'''
						,@OrderSql='StartTime'
						,@OrderType=1
						,@PageSize=5
						,@Page=1
*/
-- ====================================================
CREATE PROCEDURE [dbo].[sp_schsql_submit]
	@SchSql				varchar(4000),	-- 数据源查询语句
	@OrderSql			varchar(100),	-- 排序字段
	@OrderType			bit = 0,		-- 升序/降序
	@PageSize			tinyint = 50,	-- 页尺寸
	@Page				int = 1			-- 页码
	
AS
BEGIN
	declare @cte0 varchar(2000),
			@cte1 varchar(2000),
			@cte2 varchar(2000),
			@SQLString	nvarchar(2000),
			@ParmDefine nvarchar(200),
			@TotalCount	int				-- 记录总数
			
	set @OrderSql = ' Order by ' + rtrim(@OrderSql)
	
	if @OrderType = 0 begin
		set @OrderSql = @OrderSql + ' Asc'
	end
	else begin
		set @OrderSql = @OrderSql + ' Desc'
	end

	if len(rtrim(@SchSql)) > 0 begin
		set @cte0 = ';with cte0 as('
					+ @SchSql	
					+ ')'
		set @cte1 = ',cte1 as(
						select top ' + str(@Page * @PageSize) + ' * from cte0 m'
						+ @OrderSql
					+ ')'
		set @cte2 = ',cte2 as(
						select top ' + str((@Page - 1) * @PageSize) + ' * from cte0 m'
						+ @OrderSql
					+ ')'
					
		set @SQLString = @cte0 + ' select @TotalCount = count(*) from cte0';
		--print @SQLString--
		set @ParmDefine = N'@TotalCount int OUTPUT';
		execute sp_executesql @SQLString, @ParmDefine, @TotalCount = @TotalCount OUTPUT;
		
		--print @TotalCount--
									
		set @SchSql = @cte0 + @cte1 + @cte2
						+ 'select top ' + str(@PageSize) + ' * from cte1 c1'
						+ ' where not exists(select 1 from cte2 c2
												where c1.RecordId = c2.RecordId)'
											
		print @SchSql--

		execute(@SchSql)
	end
	
	return isnull(@TotalCount, 0)
END
GO
/****** Object:  StoredProcedure [dbo].[sp_stop_records]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =====================================================
/*

 ---查询出 要停止录音的记录
 SELECT 
	  RecordId
      ,Called
      ,Calling
      ,CallID
      ,Agent
      ,1 flag
      ,StartTime
  FROM vxi_rec.dbo.Records r
where finished = 1 and exists (
 select * from [vxi_rec].[dbo].[Stoplist] s where 
	s.agent = r.agent and s.callid = r.CallID 
	and datediff(hh,s.createdate,r.starttime) between 0 and 2
	and s.called like '%'+r.called and s.Calling like '%'+r.Calling
	and flag = 1 and doFlag <>1
 )
 --停过 又要取消的
  SELECT 
	  RecordId
      ,Called
      ,Calling
      ,CallID
      ,Agent
      ,1 flag
      ,StartTime
  FROM vxi_rec.dbo.Records r
where finished = 0 and exists (
 select * from [vxi_rec].[dbo].[Stoplist] s where 
	s.agent = r.agent and s.callid = r.CallID 
	and datediff(hh,s.createdate,r.starttime) between 0 and 2
	and s.called like '%'+r.called and s.Calling like '%'+r.Calling
	and flag = 0 and doFlag =1
 )
 

*/
--exec [dbo].[sp_stop_records]
-- ====================================================
CREATE PROCEDURE [dbo].[sp_stop_records]
	
AS

BEGIN


	declare @recordid	bigint,
			@resid		varchar(80),
			@TotalCount int
	CREATE TABLE #T_RecAsr (RecordId bigint,resid varchar(80)) 
	
	 ---查询出 要停止录音的记录
	 insert into #T_RecAsr
	 SELECT 
		  r.RecordId
		  ,s.responseid as resid
	  FROM vxi_rec.dbo.Records r, [vxi_rec].[dbo].[Stoplist] s
	  where r .finished = 1 and
		s.agent = r.agent and s.callid = r.CallID 
		and datediff(hh,s.createdate,r.starttime) between 0 and 2
		and s.called like '%'+r.called and s.Calling like '%'+r.Calling
		and flag = 1 and doFlag <>1

	select @TotalCount = count(*) from 		 #T_RecAsr 
	print 'stop:' + str(@TotalCount)
	update 	vxi_rec.dbo.Records set finished = 0 where RecordId in (select RecordId from #T_RecAsr)
	update [vxi_rec].[dbo].[Stoplist] set doFlag = 1  where responseid in (select resid from #T_RecAsr)
	
	delete from  #T_RecAsr
	
	insert into #T_RecAsr
	 SELECT 
		  r.RecordId
		  ,s.responseid as resid
	  FROM vxi_rec.dbo.Records r , [vxi_rec].[dbo].[Stoplist] s
	  where r .finished = 0 and
		s.agent = r.agent and s.callid = r.CallID 
		and datediff(hh,s.createdate,r.starttime) between 0 and 2
		and s.called like '%'+r.called and s.Calling like '%'+r.Calling
		and flag = 0 and doFlag =1

	select @TotalCount = count(*) from 		 #T_RecAsr 
	print 'canCelstop:' + str(@TotalCount)
	update 	vxi_rec.dbo.Records set finished = 1 where RecordId in (select RecordId from #T_RecAsr)
	update [vxi_rec].[dbo].[Stoplist] set doFlag = 0  where responseid in (select resid from #T_RecAsr)
	
	IF OBJECT_ID('tempdb..#T_RecAsr') IS NOT NULL BEGIN
		DROP TABLE #T_RecAsr
		PRINT 'delete temp table #T_RecAsr'
	END
	
	return @TotalCount
END



GO
/****** Object:  StoredProcedure [dbo].[usp_update_rt_trs]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_update_rt_trs]
    @Station   varchar(50),
    @Extension varchar(50),
    @Agent     varchar(50),
    @TrsEnable bit,
    @TrsLogin  bit
    
AS
BEGIN

    IF EXISTS ( SELECT 1 FROM dbo.RtTrs WHERE Station=@Station) BEGIN
        UPDATE dbo.RtTrs SET Extension=@Extension, Agent=@Agent, TrsEnable=@TrsEnable, TrsLogin=@TrsLogin WHERE Station=@Station
    END
    ELSE BEGIN
       INSERT INTO dbo.RtTrs (Station, Extension, Agent, TrsEnable, TrsLogin) VALUES (@Station, @Extension, @Agent, @TrsEnable, @TrsLogin)
    END

END


GO
/****** Object:  UserDefinedFunction [dbo].[avg_str]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE FUNCTION [dbo].[avg_str](@sumval int, @numval int, @is_percent int)
RETURNS varchar(40) AS  
BEGIN 
	
	declare @result varchar(40)

	if @numval <> 0 begin

		if isnull(@is_percent, 0) = 0 begin --非百分比
			--set @result = cast(Round(cast(@sumval as numeric(38, 6)) / @numval, 2) as varchar(40))
			--set @result = left(@result, len(@result) - 4)
			set @result = ltrim(str(Round(cast(@sumval as numeric(38, 6)) / @numval, 2), 40, 2))
		end
		else begin
			--set @result = cast(Round(cast(@sumval as numeric(38, 6)) / @numval * 100, 2) as varchar(40))
			--set @result = left(@result, len(@result) - 4) + '%'
			set @result = ltrim(str(Round(cast(@sumval as numeric(38, 6)) / @numval * 100, 2), 40, 2)) + '%'
		end

	end
	else begin
		return ''
	end
	
	return @result
END



GO
/****** Object:  UserDefinedFunction [dbo].[find_match_prjid]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE      FUNCTION [dbo].[find_match_prjid] (@TrunkGroupId smallint, 
								  @Skill varchar(20), 
								  @Agent varchar(20), 
								  @Extension varchar(20), 
								  @Route varchar(20), 
								  @Calling varchar(20), 
								  @Called varchar(20)
								 )
RETURNS int AS  
BEGIN 

	declare @Result int

	select Top 1 @Result = PrjId from vxi_sys..PrjItem 
		where (Enabled = 1)	-- 
			and ( 
				 ( Type = 5 and charindex(',' + case when len(@TrunkGroupId) > 0 then rtrim(cast(@TrunkGroupId as varchar(10))) 
													else '' end + ',',',' + Items + ',') > 0)	-- Trunk Group
		   		 or ( Type = 3 and charindex(',' + case when len(@Skill) > 0 then rtrim(@Skill) else '' end + ',',',' + Items + ',') > 0) -- Skill
				 or ( Type = 1 and charindex(',' + case when len(@Agent) > 0 then rtrim(@Agent) else '' end + ',' ,',' + Items + ',') > 0) -- Agent
		   		 or ( Type = 2 and charindex(',' + case when len(@Extension) > 0 then rtrim(@Extension) else '' end + ',', ',' + Items + ',') >0) -- Extension
		   		 or ( Type = 4 and charindex(',' + case when len(@Route) > 0 then rtrim(@Route) else '' end + ',', ','+ Items + ',') > 0) -- Route
		   		 or ( Type = 7 and charindex(',' + case when len(@Called) > 0 then rtrim(@Called) else '' end + ',',',' + Items + ',') >0) -- Called
		   		 or ( Type = 6 and charindex(',' + case when len(@Calling) > 0 then rtrim(@Calling) else '' end + ',',',' + Items +',')>0) -- Calling
				)
	return isnull(@Result, -1)

END




GO
/****** Object:  UserDefinedFunction [dbo].[Format_AsrResult]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[Format_AsrResult]  ------- 针对传入的检索参数，格式化asr内容
(
 @asritem	int=0
)
RETURNS @AsrResult  TABLE
(
 RecordId	bigint  NOT NULL,
 AsrResult  text	NULL
)
AS
BEGIN
  
  	if @asritem = 0 begin
			INSERT INTO @AsrResult 
			SELECT  RecordId,convert(varchar(max),asrresult)+'&'+convert(varchar(max),asrresultA)+'&'+ convert(varchar(max),asrresultB) from vxi_rec..RecAsr
	end
	else if @asritem = 1 begin
			INSERT INTO @AsrResult 
			SELECT  RecordId,convert(varchar(max),asrresultA) from vxi_rec..RecAsr
	end
	else if @asritem = 2 begin
			INSERT INTO @AsrResult 
			SELECT  RecordId,convert(varchar(max),asrresultB) from vxi_rec..RecAsr		
	end
	else begin
			INSERT INTO @AsrResult 
			SELECT  RecordId,convert(varchar(max),asrresult) from vxi_rec..RecAsr
	end      
 
 RETURN
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_day]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[func_day] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END 
GO
/****** Object:  UserDefinedFunction [dbo].[Get_StrArrayLength]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create function [dbo].[Get_StrArrayLength]
(
  @str varchar(100),  --要分割的字符串
  @split varchar(2)  --分隔符号
)
returns int
as
begin
  declare @location int
  declare @start int
  declare @length int

  set @str=ltrim(rtrim(@str))
  set @location=charindex(@split,@str)
  set @length=1
  while @location<>0
  begin
    set @start=@location+1
    set @location=charindex(@split,@str,@start)
    set @length=@length+1
  end
  return @length
end


GO
/****** Object:  UserDefinedFunction [dbo].[Get_StrArrayStrOfIndex]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE function [dbo].[Get_StrArrayStrOfIndex]
(
 @str varchar(1024),  --要分割的字符串
 @split varchar(10),  --分隔符号
 @index int			  --取第几个元素
)
returns varchar(1024)
as
begin
 declare @location int 
 declare @start int		
 declare @next int
 declare @seed int
 set @str=ltrim(rtrim(@str))
 set @start=1
 set @next=1
 set @seed=len(@split)		
 set @location=charindex(@split,@str)
 while @location<>0 and @index>@next
   begin
	set @start=@location+@seed
    set @location=charindex(@split,@str,@start)
    set @next=@next+1
   end
 if @location =0 select @location =len(@str)+1

--这儿存在两种情况：1、字符串不存在分隔符号 2、字符串中存在分隔符号，跳出while循环后，@location为0，那默认为字符串后边有一个分隔符号。
 return substring(@str,@start,@location-@start)
end




GO
/****** Object:  UserDefinedFunction [dbo].[is_same_directory]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[is_same_directory]
(
	-- Add the parameters for the function here
	@dir1 varchar(300), @dir2 varchar(300)
)
RETURNS bit
AS
BEGIN

	if len(@dir1) > 0 begin
		set @dir1 = replace(@dir1, '\', '/')
		if right(@dir1, 1) != '/' begin
			set @dir1 = @dir1 + '/'
		end
	end

	if len(@dir2) > 0 begin
		set @dir2 = replace(@dir2, '\', '/')
		if right(@dir2, 1) != '/' begin
			set @dir2 = @dir2 + '/'
		end
	end

	return case when @dir1 = @dir2 then 1 else 0 end

END

GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_time]    Script Date: 2016/9/5 13:24:59 ******/
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
/****** Object:  UserDefinedFunction [dbo].[time_to_bigint]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create  FUNCTION [dbo].[time_to_bigint] (@time datetime, @unit int)
RETURNS bigint AS
BEGIN 

	declare @result bigint, @idate bigint, @itime bigint

	select  	@idate = year(@time) * 10000 + month(@time) * 100 + day(@time), 
		@itime = datepart(hour, @time) * 100 + datepart(minute, @time) / @unit * @unit

	select @result = 10000 * @idate + @itime
	return @result
END
GO
/****** Object:  UserDefinedFunction [dbo].[TrimString]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE function [dbo].[TrimString] 
(
  @str nvarchar(100)  --要分割的字符串
)
returns nvarchar(100)
as
begin
    declare @i int
    SELECT @str =REPLACE(LTRIM(RTRIM(@str)), ',', ' ')
    SET @i=CHARINDEX('  ',@str)
    WHILE @i >= 1
    begin
        select @str=REPLACE(LTRIM(RTRIM(@str)), '  ', ' ')
        set @i=CHARINDEX('  ',@str)
    end
    select @str =REPLACE(LTRIM(RTRIM(@str)), ' ', ',')
    declare @temptable table (tempstr nvarchar(100))
declare @next int  
declare @totalno int
set @next=1
set @totalno=dbo.Get_StrArrayLength(@str,',')
while @next<=@totalno
begin
insert into @temptable ([tempstr]) values  (dbo.Get_StrArrayStrOfIndex(@str,',',@next))
set @next=@next+1
end
    set @str=(select tempstr+',' from @temptable order by tempstr for xml path(''))
    return left(@str,len(@str)-1)
end


GO
/****** Object:  Table [asr].[Package]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [asr].[Package](
	[PkgID] [int] NOT NULL,
	[Words] [varchar](200) NULL,
	[Description] [varchar](100) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Package_1] PRIMARY KEY CLUSTERED 
(
	[PkgID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [asr].[Word]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [asr].[Word](
	[LogId] [int] IDENTITY(1,1) NOT NULL,
	[WordID] [int] NOT NULL,
	[Word] [varchar](40) NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Word] PRIMARY KEY CLUSTERED 
(
	[LogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [asr].[Words]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [asr].[Words](
	[WordID] [int] NOT NULL,
	[Decription] [varchar](200) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_AsrWords] PRIMARY KEY CLUSTERED 
(
	[WordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[_Store]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[_Store](
	[FtpId] [smallint] NOT NULL,
	[SortId] [int] NOT NULL,
	[Station] [char](20) NOT NULL,
	[Folder] [varchar](60) NOT NULL,
	[Port] [int] NULL,
	[Drive] [char](1) NOT NULL,
	[RealFolder] [varchar](100) NULL,
	[Priority] [tinyint] NOT NULL,
	[Username] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[AutoBackup] [bit] NOT NULL,
	[DestFolder] [varchar](100) NULL,
	[BackupDays] [smallint] NULL,
	[BackupTime] [int] NULL,
	[KeepDays] [smallint] NULL,
	[Type] [tinyint] NULL,
	[Enabled] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[FtpId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[_Task]    Script Date: 2016/9/5 13:24:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[_Task](
	[TaskID] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[TaskName] [varchar](50) NOT NULL,
	[Items] [text] NULL,
	[TaskType] [tinyint] NULL,
	[DevType] [tinyint] NULL,
	[Quality] [tinyint] NULL,
	[Encry] [bit] NOT NULL,
	[State] [tinyint] NULL,
	[WeekMark] [int] NULL,
	[MonthMark] [int] NULL,
	[DateStart] [int] NULL,
	[DateEnd] [int] NULL,
	[TimeStart] [int] NULL,
	[TimeEnd] [int] NULL,
	[RecFlag] [tinyint] NULL,
	[Priority] [smallint] NULL,
	[RecPercent] [tinyint] NULL,
	[ScrPercent] [tinyint] NULL,
	[Enabled] [bit] NOT NULL,
	[RecStorage] [smallint] NULL,
	[ScrStorage] [smallint] NULL,
	[AsrEnabled] [bit] NULL,
	[AsrFlag] [int] NOT NULL,
	[AsrPercent] [tinyint] NULL,
	[AsrPkgs] [varchar](60) NULL,
	[TransferEnabled] [bit] NULL,
	[FullTimeEnabled] [bit] NULL,
	[VideoPercent] [tinyint] NULL,
	[AviPercent] [tinyint] NULL,
PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[EncryKeys]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EncryKeys](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NULL,
	[TaskId] [int] NULL,
	[BeginDate] [int] NOT NULL,
	[EndDate] [int] NOT NULL,
	[KeyInfo] [varchar](200) NOT NULL,
 CONSTRAINT [PK_EncryKeys] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Filter]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Filter](
	[Phone] [varchar](20) NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Filter] PRIMARY KEY CLUSTERED 
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FormRec]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FormRec](
	[RecordId] [bigint] NOT NULL,
	[Userid] [int] NULL,
	[UpdateDate] [datetime] NULL,
	[Flag] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_FormRec] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GroupRec]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupRec](
	[RecordId] [bigint] NOT NULL,
	[GroupId] [int] NOT NULL,
 CONSTRAINT [PK_GroupRec] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Label]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Label](
	[RecordId] [bigint] NOT NULL,
	[Label] [int] NOT NULL,
	[Title] [varchar](100) NULL,
	[Note] [text] NULL,
	[Writer] [varchar](20) NULL,
	[LabelTime] [datetime] NULL,
	[Flag] [int] NULL,
 CONSTRAINT [PK_Label] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[Label] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Modules]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Modules](
	[ModId] [char](30) NOT NULL,
	[ModName] [char](100) NOT NULL,
	[ModIndex] [int] NULL,
	[ParentId] [char](30) NULL,
	[SortId] [int] NULL,
	[CtrlLoc] [tinyint] NOT NULL,
	[VisitPriv] [tinyint] NULL,
	[TabPriv] [tinyint] NULL,
	[SubPriv] [tinyint] NULL,
	[BtnMark] [int] NULL,
	[TabName] [char](50) NOT NULL,
	[TabKey] [char](30) NOT NULL,
	[IntTabKey] [bit] NULL,
	[AutoTabKey] [bit] NULL,
	[Pickup] [bit] NULL,
	[SubTabName] [char](50) NULL,
	[SubTabKey] [char](30) NULL,
	[IntSubKey] [bit] NULL,
	[AutoSubKey] [bit] NULL,
	[DataWin] [varchar](50) NULL,
	[ModPage] [varchar](50) NULL,
	[InitPage] [varchar](50) NULL,
	[MaxRows] [int] NULL,
	[SchType] [tinyint] NULL,
	[SchPage] [varchar](50) NULL,
	[CalPage] [varchar](50) NULL,
	[ComboPage] [varchar](50) NULL,
	[EditPage] [varchar](50) NULL,
	[ViewPage] [varchar](50) NULL,
	[BatAddPage] [varchar](50) NULL,
	[BatDelPage] [varchar](50) NULL,
	[ViewSP] [varchar](200) NULL,
	[InputPage] [varchar](50) NULL,
	[SubSchPage] [varchar](50) NULL,
	[SubEditPage] [varchar](50) NULL,
	[SubViewPage] [varchar](50) NULL,
	[SubViewSP] [varchar](200) NULL,
	[InitSP] [varchar](200) NULL,
	[AckSP] [varchar](200) NULL,
	[UnackSP] [varchar](200) NULL,
	[SchSP] [text] NULL,
	[SubSchSP] [varchar](200) NULL,
	[SubListSP] [varchar](200) NULL,
	[SubInsertSP] [varchar](200) NULL,
	[OnEnter] [varchar](100) NULL,
	[OnLeave] [varchar](100) NULL,
	[OnInsert] [varchar](300) NULL,
	[OnUpdate] [varchar](300) NULL,
	[OnDelete] [varchar](300) NULL,
	[OnSubInsert] [varchar](300) NULL,
	[OnSubUpdate] [varchar](300) NULL,
	[OnSubDelete] [varchar](300) NULL,
	[Chart] [varchar](20) NULL,
	[AxisX] [varchar](20) NULL,
	[AxisY] [varchar](100) NULL,
	[UnitX] [varchar](50) NULL,
	[UnitY] [varchar](50) NULL,
	[Chart1] [varchar](20) NULL,
	[AxisY1] [varchar](100) NULL,
	[UnitY1] [varchar](50) NULL,
	[Chart2] [varchar](20) NULL,
	[AxisY2] [varchar](100) NULL,
	[UnitY2] [varchar](50) NULL,
	[PrintMark] [tinyint] NULL,
	[Summary] [text] NULL,
	[Flow] [text] NULL,
	[Filter] [text] NULL,
	[SortKeys] [text] NULL,
	[Fields] [text] NULL,
	[FieldX] [text] NULL,
	[StatFields] [text] NULL,
	[SchFields] [text] NULL,
	[SubSchFields] [text] NULL,
	[SubListFields] [text] NULL,
	[Relation] [text] NULL,
	[Formats] [text] NULL,
	[PickLinks] [text] NULL,
	[InitSQL] [text] NULL,
	[NewKeySQL] [text] NULL,
	[SchItems] [text] NULL,
	[SchSQL] [text] NULL,
	[ViewSQL] [text] NULL,
	[EditSQL] [text] NULL,
	[InsertSQL] [text] NULL,
	[UpdateSQL] [text] NULL,
	[DeleteSQL] [text] NULL,
	[SubSchItems] [text] NULL,
	[NewSubKeySQL] [text] NULL,
	[SubSchSQL] [text] NULL,
	[SubListSQL] [text] NULL,
	[SubEditSQL] [text] NULL,
	[SubViewSQL] [text] NULL,
	[SubInsertSQL] [text] NULL,
	[SubUpdateSQL] [text] NULL,
	[SubDeleteSQL] [text] NULL,
	[Template] [text] NULL,
	[Prompts] [text] NULL,
	[Visible] [bit] NULL,
	[KeyPerson] [varchar](50) NULL,
	[KeyGroup] [varchar](50) NULL,
	[KeyDept] [varchar](50) NULL,
	[SchLocks] [tinyint] NULL,
	[SubLocks] [tinyint] NULL,
	[LstLocks] [tinyint] NULL,
	[SchExTpl] [varchar](50) NULL,
	[ExTpl] [varchar](50) NULL,
	[SubExTpl] [varchar](50) NULL,
	[Show3D] [bit] NULL,
	[AddLink] [bit] NULL,
	[Acked] [bit] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Modules] PRIMARY KEY CLUSTERED 
(
	[ModId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Monitor]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Monitor](
	[Monitor] [int] NOT NULL,
	[UserId] [varchar](20) NULL,
	[RecordId] [bigint] NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
 CONSTRAINT [PK_Monitor] PRIMARY KEY CLUSTERED 
(
	[Monitor] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PrjRec]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PrjRec](
	[RecordId] [bigint] NOT NULL,
	[PrjId] [int] NOT NULL,
 CONSTRAINT [PK_PrjRec] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[PrjId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[RecAdditional]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecAdditional](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RecordId] [bigint] NULL,
	[CallId] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[EventType] [int] NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[StartSec] [int] NULL,
 CONSTRAINT [PK__RecAdditional__04AFB25B] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecAsr]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecAsr](
	[RecordId] [bigint] NOT NULL,
	[AsrResult] [text] NULL,
	[AsrResultA] [text] NULL,
	[AsrResultB] [text] NULL,
	[Confidence] [smallint] NULL,
	[ConfidenceA] [smallint] NULL,
	[ConfidenceB] [smallint] NULL,
 CONSTRAINT [PK_RecAsr] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_RecAsr] UNIQUE NONCLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[RecBizType]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecBizType](
	[BizType] [tinyint] NOT NULL,
	[BizName] [varchar](20) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_RecBizType] PRIMARY KEY CLUSTERED 
(
	[BizType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecExts]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecExts](
	[RecordId] [bigint] NOT NULL,
	[Item01] [varchar](50) NULL,
	[Item02] [varchar](50) NULL,
	[Item03] [varchar](50) NULL,
	[Item04] [varchar](50) NULL,
	[Item05] [varchar](50) NULL,
	[Item06] [varchar](50) NULL,
	[Item07] [varchar](50) NULL,
	[Item08] [varchar](50) NULL,
	[Item09] [varchar](50) NULL,
	[Item10] [varchar](50) NULL,
	[Note] [varchar](1000) NULL,
	[ItemTime] [datetime] NULL,
	[Handler] [varchar](20) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_RecExts] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecOpinion]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecOpinion](
	[RecordId] [bigint] NOT NULL,
	[BizTypeList] [varchar](20) NULL,
	[Suggestion] [varchar](500) NULL,
	[Feedback] [varchar](500) NULL,
 CONSTRAINT [PK_RecOpinion] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Records]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Records](
	[RecordId] [bigint] NOT NULL,
	[UcdId] [bigint] NULL,
	[CallID] [int] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Answer] [varchar](50) NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[Seconds]  AS ((isnull([TimeLen],(0))+(500))/(1000)),
	[Agent] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Route] [varchar](20) NULL,
	[Trunk] [varchar](20) NULL,
	[TrunkGroupId] [smallint] NULL,
	[VideoURL] [smallint] NULL,
	[AudioURL] [smallint] NULL,
	[Channel] [varchar](20) NULL,
	[Extension] [varchar](20) NULL,
	[VoiceType] [tinyint] NULL,
	[StartDate] [int] NULL,
	[StartHour] [tinyint] NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[PrjId] [int] NULL,
	[finished] [tinyint] NULL,
	[ActFlag] [int] NULL,
	[Labeled] [bit] NULL,
	[FileCount] [smallint] NULL,
	[DataEncry] [bit] NULL,
	[Mark] [varchar](10) NULL,
	[AssRec] [bigint] NULL,
	[Established] [bit] NULL,
	[VideoType] [int] NULL,
	[EncryKey] [nvarchar](max) NULL,
	[TaskEncry] [bit] NULL,
	[ChatSession] [varchar](100) NULL,
 CONSTRAINT [PK_Records] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RepWords]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RepWords](
	[WordID] [int] NOT NULL,
	[Word] [varchar](50) NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_RepWords] PRIMARY KEY CLUSTERED 
(
	[WordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RtTrs]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RtTrs](
	[Station] [varchar](50) NOT NULL,
	[Extension] [varchar](50) NULL,
	[Agent] [varchar](50) NULL,
	[TrsEnable] [bit] NOT NULL,
	[TrsLogin] [bit] NOT NULL,
 CONSTRAINT [PK_RtTrs] PRIMARY KEY CLUSTERED 
(
	[Station] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[scloc]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[scloc](
	[id] [int] NULL,
	[ReportDate] [varchar](50) NULL,
	[SourceOfCall] [varchar](50) NULL,
	[Total] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Stoplist]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[Stoplist](
	[responseId] [varchar](50) NOT NULL,
	[Called] [varchar](30) NULL,
	[Calling] [varchar](30) NULL,
	[Callid] [varchar](30) NULL,
	[Agent] [varchar](30) NULL,
	[Device] [varchar](10) NULL,
	[UUI] [varchar](50) NULL,
	[flag] [bit] NULL,
	[AgentIp] [varchar](30) NULL,
	[CreateDate] [datetime] NULL,
	[doFlag] [bit] NULL,
 CONSTRAINT [PK_Viplist] PRIMARY KEY CLUSTERED 
(
	[responseId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Store]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Store](
	[FtpId] [smallint] NOT NULL,
	[SortId] [int] NOT NULL,
	[Station] [char](20) NOT NULL,
	[Folder] [varchar](60) NOT NULL,
	[Port] [int] NULL,
	[Drive] [char](1) NOT NULL,
	[Encry] [bit] NOT NULL,
	[RealFolder] [varchar](100) NULL,
	[Priority] [tinyint] NOT NULL,
	[Username] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[AutoBackup] [bit] NOT NULL,
	[DestFolder] [varchar](100) NULL,
	[BackupDays] [smallint] NULL,
	[BackupTime] [int] NULL,
	[KeepDays] [smallint] NULL,
	[Type] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Store] PRIMARY KEY CLUSTERED 
(
	[FtpId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_Storage] UNIQUE NONCLUSTERED 
(
	[Station] ASC,
	[Folder] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StoreType]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StoreType](
	[StoreType] [tinyint] NOT NULL,
	[TypeName] [varchar](20) NULL,
 CONSTRAINT [PK_StoreType] PRIMARY KEY CLUSTERED 
(
	[StoreType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Task]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Task](
	[TaskID] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[TaskName] [varchar](50) NOT NULL,
	[Items] [text] NULL,
	[TaskType] [tinyint] NULL,
	[DevType] [tinyint] NULL,
	[Quality] [tinyint] NULL,
	[State] [tinyint] NULL,
	[WeekMark] [int] NULL,
	[MonthMark] [int] NULL,
	[DateStart] [int] NULL,
	[DateEnd] [int] NULL,
	[TimeStart] [int] NULL,
	[TimeEnd] [int] NULL,
	[RecFlag] [tinyint] NULL,
	[Priority] [smallint] NULL,
	[RecPercent] [tinyint] NULL,
	[ScrPercent] [tinyint] NULL,
	[Enabled] [bit] NOT NULL,
	[RecStorage] [smallint] NULL,
	[ScrStorage] [smallint] NULL,
	[AsrEnabled] [bit] NULL,
	[AsrFlag] [int] NOT NULL,
	[AsrPercent] [tinyint] NULL,
	[AsrPkgs] [varchar](60) NULL,
	[TransferEnabled] [bit] NULL,
	[FullTimeEnabled] [bit] NULL,
	[VideoPercent] [tinyint] NULL,
 CONSTRAINT [PK_Task] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TaskItem]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TaskItem](
	[TaskId] [int] NOT NULL,
	[SortId] [int] NOT NULL,
	[Items] [varchar](20) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_TaskItem] PRIMARY KEY CLUSTERED 
(
	[TaskId] ASC,
	[SortId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TaskRec]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaskRec](
	[RecordId] [bigint] NOT NULL,
	[TaskId] [int] NOT NULL,
 CONSTRAINT [PK_TaskRec] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[TaskId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TaskType]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TaskType](
	[TaskType] [tinyint] NOT NULL,
	[TypeName] [varchar](20) NULL,
 CONSTRAINT [PK_TaskType] PRIMARY KEY CLUSTERED 
(
	[TaskType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VideoType]    Script Date: 2016/9/5 13:25:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VideoType](
	[VideoType] [tinyint] NOT NULL,
	[Description] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_Folder]  DEFAULT ('/') FOR [Folder]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_Drive]  DEFAULT ('C') FOR [Drive]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_Priority]  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_Username]  DEFAULT ('') FOR [Username]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_Password]  DEFAULT ('') FOR [Password]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_AutoBackup]  DEFAULT ((0)) FOR [AutoBackup]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_BackupDays]  DEFAULT ((365)) FOR [BackupDays]
GO
ALTER TABLE [dbo].[_Store] ADD  CONSTRAINT [DF__Store_Type]  DEFAULT ((3)) FOR [Type]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_TaskType]  DEFAULT ((0)) FOR [TaskType]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_DevType]  DEFAULT ((0)) FOR [DevType]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_Quality]  DEFAULT ((2)) FOR [Quality]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_Encry]  DEFAULT ((0)) FOR [Encry]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_State]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_WeekMark]  DEFAULT ((0)) FOR [WeekMark]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_RecFlag]  DEFAULT ((0)) FOR [RecFlag]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_Priority]  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_RecPercent]  DEFAULT ((100)) FOR [RecPercent]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_ScrPercent]  DEFAULT ((100)) FOR [ScrPercent]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_AsrEnabled]  DEFAULT ((0)) FOR [AsrEnabled]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_AsrFlag]  DEFAULT ((0)) FOR [AsrFlag]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_AsrPercent]  DEFAULT ((100)) FOR [AsrPercent]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_TransferEnabled]  DEFAULT ((0)) FOR [TransferEnabled]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_FullTimeEnabled]  DEFAULT ((0)) FOR [FullTimeEnabled]
GO
ALTER TABLE [dbo].[_Task] ADD  CONSTRAINT [DF__Task_AviPercent]  DEFAULT ((0)) FOR [AviPercent]
GO
ALTER TABLE [dbo].[Filter] ADD  CONSTRAINT [DF_Filter_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_ModIndex]  DEFAULT ((100)) FOR [ModIndex]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_TabPriv]  DEFAULT ((15)) FOR [TabPriv]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_SubPriv]  DEFAULT ((15)) FOR [SubPriv]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_BtnMark]  DEFAULT (0xFFFFFFFF) FOR [BtnMark]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_MaxRows]  DEFAULT ((1000)) FOR [MaxRows]
GO
ALTER TABLE [dbo].[Modules] ADD  CONSTRAINT [DF_Modules_visibility]  DEFAULT ((1)) FOR [Visible]
GO
ALTER TABLE [dbo].[RecAdditional] ADD  CONSTRAINT [DF__RecAdditi__CallI__05A3D694]  DEFAULT ((0)) FOR [CallId]
GO
ALTER TABLE [dbo].[RecAsr] ADD  CONSTRAINT [DF_RecAsr_ConfidenceA]  DEFAULT ((0)) FOR [ConfidenceA]
GO
ALTER TABLE [dbo].[RecAsr] ADD  CONSTRAINT [DF_RecAsr_ConfidenceB]  DEFAULT ((0)) FOR [ConfidenceB]
GO
ALTER TABLE [dbo].[RecBizType] ADD  CONSTRAINT [DF_RecBizType_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[RecExts] ADD  CONSTRAINT [DF_RecExts_ItemTime]  DEFAULT (getdate()) FOR [ItemTime]
GO
ALTER TABLE [dbo].[RecExts] ADD  CONSTRAINT [DF_RecExts_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_PrjId]  DEFAULT ((-1)) FOR [PrjId]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_FileCount]  DEFAULT ((1)) FOR [FileCount]
GO
ALTER TABLE [dbo].[Stoplist] ADD  CONSTRAINT [DF_Stoplist_flag]  DEFAULT ((1)) FOR [flag]
GO
ALTER TABLE [dbo].[Stoplist] ADD  DEFAULT (getdate()) FOR [CreateDate]
GO
ALTER TABLE [dbo].[Stoplist] ADD  CONSTRAINT [DF_Stoplist_doFlag]  DEFAULT ((0)) FOR [doFlag]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Folder]  DEFAULT ('/') FOR [Folder]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Drive]  DEFAULT ('C') FOR [Drive]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Priority]  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Username]  DEFAULT ('') FOR [Username]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Password]  DEFAULT ('') FOR [Password]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_AutoBackup]  DEFAULT ((0)) FOR [AutoBackup]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_KeepDays]  DEFAULT ((365)) FOR [KeepDays]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Store_Type]  DEFAULT ((3)) FOR [Type]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_AgentSeleType]  DEFAULT ((0)) FOR [TaskType]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_TimeRangeType]  DEFAULT ((0)) FOR [DevType]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_Quality]  DEFAULT ((2)) FOR [Quality]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_State]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_WeekState_1]  DEFAULT ((0)) FOR [WeekMark]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_MonthState_1]  DEFAULT ((0)) FOR [MonthMark]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_RecFlag]  DEFAULT ((0)) FOR [RecFlag]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_Priority]  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_RecPercent]  DEFAULT ((100)) FOR [RecPercent]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_ScrPercent]  DEFAULT ((100)) FOR [ScrPercent]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_AsrEnabled]  DEFAULT ((0)) FOR [AsrEnabled]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_AsrFlag]  DEFAULT ((0)) FOR [AsrFlag]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_AsrPercent]  DEFAULT ((100)) FOR [AsrPercent]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_TransferEnabled]  DEFAULT ((0)) FOR [TransferEnabled]
GO
ALTER TABLE [dbo].[Task] ADD  CONSTRAINT [DF_Task_FullTimeEnabled]  DEFAULT ((0)) FOR [FullTimeEnabled]
GO
ALTER TABLE [asr].[Word]  WITH CHECK ADD  CONSTRAINT [FK_Word_Words] FOREIGN KEY([WordID])
REFERENCES [asr].[Words] ([WordID])
GO
ALTER TABLE [asr].[Word] CHECK CONSTRAINT [FK_Word_Words]
GO
ALTER TABLE [dbo].[FormRec]  WITH NOCHECK ADD  CONSTRAINT [FK_FormRec_Records] FOREIGN KEY([RecordId])
REFERENCES [dbo].[Records] ([RecordId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[FormRec] CHECK CONSTRAINT [FK_FormRec_Records]
GO
ALTER TABLE [dbo].[GroupRec]  WITH NOCHECK ADD  CONSTRAINT [FK_GroupRec_Records] FOREIGN KEY([RecordId])
REFERENCES [dbo].[Records] ([RecordId])
GO
ALTER TABLE [dbo].[GroupRec] CHECK CONSTRAINT [FK_GroupRec_Records]
GO
ALTER TABLE [dbo].[Label]  WITH NOCHECK ADD  CONSTRAINT [FK_Label_Records] FOREIGN KEY([RecordId])
REFERENCES [dbo].[Records] ([RecordId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Label] CHECK CONSTRAINT [FK_Label_Records]
GO
ALTER TABLE [dbo].[Monitor]  WITH NOCHECK ADD  CONSTRAINT [FK_Monitor_Records] FOREIGN KEY([RecordId])
REFERENCES [dbo].[Records] ([RecordId])
ON UPDATE CASCADE
GO
ALTER TABLE [dbo].[Monitor] CHECK CONSTRAINT [FK_Monitor_Records]
GO
ALTER TABLE [dbo].[TaskItem]  WITH NOCHECK ADD  CONSTRAINT [FK_TaskItem_Task] FOREIGN KEY([TaskId])
REFERENCES [dbo].[Task] ([TaskID])
GO
ALTER TABLE [dbo].[TaskItem] CHECK CONSTRAINT [FK_TaskItem_Task]
GO
ALTER TABLE [dbo].[TaskRec]  WITH NOCHECK ADD  CONSTRAINT [FK_TaskRec_Records] FOREIGN KEY([RecordId])
REFERENCES [dbo].[Records] ([RecordId])
GO
ALTER TABLE [dbo].[TaskRec] CHECK CONSTRAINT [FK_TaskRec_Records]
GO
ALTER TABLE [dbo].[TaskRec]  WITH NOCHECK ADD  CONSTRAINT [FK_TaskRec_Task] FOREIGN KEY([TaskId])
REFERENCES [dbo].[Task] ([TaskID])
GO
ALTER TABLE [dbo].[TaskRec] CHECK CONSTRAINT [FK_TaskRec_Task]
GO
