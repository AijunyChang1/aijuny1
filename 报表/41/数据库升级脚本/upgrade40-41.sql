use visionlog40

CREATE TABLE ScreenCfg(
	ScreenCfgID int identity(1,1) primary key,
	ScreenCfgName varchar(50) not null,
	Description varchar(1000),
	StartDate varchar(8),
	EndDate varchar(8),
	ScrFtpID smallint,
	VideoEnabled tinyint,
	VideoFtpID smallint,
	VideoZoomScale smallint,
	Enabled bit
)
GO

CREATE TABLE [dbo].[Address_NoNeedStatic](
       [Address] [nchar](10) NULL,
       [Station] [nvarchar](50) NULL
) ON [PRIMARY]

GO

CREATE TABLE [dbo].[Station_NoNeedStatic](
       [StationName] [nvarchar](50) NULL
) ON [PRIMARY]

/*
CREATE TABLE EncryKeys(
	Id int identity(1,1) primary key,
	ProjectId int,
	StartDate datetime not null,
	EndDate datetime not null,
	PasswordBits int,
	Password varchar(50),
	KeyInfo varchar(256) not null
)
GO
*/

/****** Object:  Table [dbo].[RecordsEvtCaculate]    Script Date: 12/19/2016 10:21:45 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[RecordsEvtCaculate](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[RecordId] [bigint] NULL,
	[holdCnt] [int] NULL,
	[ConfCnt] [int] NULL,
	[MuteCnt] [int] NULL,
	[holdRate] [numeric](6, 2) NULL,
	[ConfRate] [numeric](6, 2) NULL,
	[MuteRate] [numeric](6, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

create unique nonclustered index IX_REC_RecordId on [dbo].[RecordsEvtCaculate]([RecordId]);

GO
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ETL_LOG](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[MinLsn] [binary](10) NULL,
	[FromTB] [varchar](50) NULL,
	[ToTB] [varchar](50) NULL,
	[MaxLsn] [binary](10) NULL,
	[MinTmStamp] [bigint] NULL,
	[MaxTmStamp] [bigint] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

--EXEC sp_rename 'EncryKeys.BeginDate', 'StartDate', 'column'
AlTER TABLE EncryKeys ADD PasswordBits int
ALTER TABLE EncryKeys ADD Password varchar(50)
ALTER TABLE Records ADD TmStamp timestamp
alter table Records add SiteID int

GO

CREATE TABLE RecordMutes(
	Id int identity(1,1) primary key,
	RecordId bigint,
	StartTime int,
	Timelen int,
	isExpected bit
)
GO

USE [VisionLog40]
GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records]    Script Date: 12/19/2016 10:07:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example: 
exec VisionLog41..usp_sch_records '0','','','','','','2016-09-01','2016-09-09','00:00','23:59'
,null,'','',0,1439,'','recordId','0','','','','','','','','','','','','','','','','','',''
,'0','30','0','30','0','30','1','','','',1,20,''
*/	 

ALTER PROCEDURE [dbo].[usp_sch_records] 
	@LogID				int = 0, 
	@GroupID			int = 0, 
	@AgentID			varchar(4000)  = '', 
	@AgentID_p			varchar(4000)  = '',
	@Address			varchar(4000)  = '',
	@Address_p			varchar(4000)  = '',
	@DateBegin 			varchar(20)  = '20000101', 
	@DateEnd			varchar(20)  = '20790101', 
	@TimeBegin			varchar(20)  = '00:00:00', 
	@TimeEnd			varchar(20)  = '23:59:59.999', 
	@Label				varchar(20) = '', 
	@AddressGroup		varchar(4000)  = '', 
	@AddressGroup_p		varchar(4000)  = '',
	@CalltimeFrom		float = 0, 
	@CalltimeTo			float = 0, 
	@RecordID			bigint = 0, 
	@Orderby			varchar(20) = 'RecordId', 
	@Labeled			bit = 0, 
	@TrunkGroup 		varchar(2000) = '',
	@ProjId				varchar(200) = '',
	@Acd				varchar(2000) = '',
	@Direction			varchar(20) = 'all',
	@CustmoerPhone		varchar(50) = '',
	@Calling			varchar(50) = '',
	@Called				varchar(2000) = '',
	@AgentGroupId		varchar(2000) = '',
	@AgentGroupId_p		varchar(2000) = '',
	@uui				varchar(100) = '',
	@ItemNo				tinyint = 0,
	@Value				varchar(50) = '',
	@UCID				varchar(20) = '',
	@recordType			varchar(20) = '', --'':所有,1:音频,2:截屏,3:视频
	@MutetimeFrom		int = 0, 
	@MutetimeTo			int = 0, 
	@HoldtimeFrom		int = 0, 
	@HoldtimeTo			int = 0, 
	@ConferencetimeFrom	int = 0, 
	@ConferencetimeTo	int = 0,
	@bAdmin				bit = 0,		-- 是否管理员
	@transInCount		int = null,		-- 转移内部
	@transOutCount		int = null,		-- 转移外部
	@confsCount			int = null,		-- 会议
	@StartPage			int =1,
	@EndPage			int =50,
	@SiteID				int=0,
	
	@holdRate numeric(10,2)=0,
	@ConfRate numeric(10,2)=0,
	@MuteRate numeric(10,2)=0
	
	--@TotalPage			int	out
AS
BEGIN

	IF OBJECT_ID('tempdb..#t_record') IS NOT NULL BEGIN
		DROP TABLE #t_record
		PRINT 'drop temp table #t_record'
	END
	create table #t_record(recordid bigint)
	create index #ix_t_record on #t_record(recordid)

	IF OBJECT_ID('tempdb..#t_agent') IS NOT NULL BEGIN
		drop table #t_agent
	END
	create table #t_agent(Master varchar(20))
	create index #ix_t_agent on #t_agent(master)

	 IF OBJECT_ID('tempdb..#MIDTABLE') IS NOT NULL BEGIN
		drop table #MIDTABLE
	END
	 create table #MIDTABLE([MIDNAME] varchar(50),[MIDVALUE] varchar(100));

 	IF OBJECT_ID('tempdb..#PARAMETER') IS NOT NULL BEGIN
		drop table #PARAMETER
	END
 create table #PARAMETER(ParaName nvarchar(30),ParaValue nvarchar(100));
  
  	IF OBJECT_ID('tempdb..#agent2') IS NOT NULL BEGIN
		drop table #agent2
	END
	create table #agent2(Agentid varchar(20));
	
	declare @tTimeBegin datetime
	declare @tTimeEnd datetime
	
	set @tTimeBegin = cast(@DateBegin + ' ' + @TimeBegin as datetime)
	set @tTimeEnd = cast(@DateEnd + ' ' + @TimeEnd as datetime)
		
		
	declare @sch			varchar(max),
			@sch_p			varchar(max),
			@Item1			varchar(20), 
			@Item2			varchar(20),
			@GroupAgent		varchar(max),
			@GroupAddress	varchar(max),
			@cur_date_value varchar(50),
			@bPrivilege		bit
			
	set @cur_date_value = floor(cast(getdate() as float))
	set @bPrivilege = 0
	
	set @sch = 	'select distinct top 100 percent r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel
						,r.RecURL,r.ScrURL,r.VideoURL,r.StartTime,r.Seconds,r.State
			   			,ra.MuteCnt as muteTime,ra.holdCnt as holdTime,ra.ConfCnt as conferenceTime
			   			,ra.holdRate,ra.ConfRate,ra.MuteRate
			   			,r.RecFlag,r.ScrFlag,r.VideoFlag,r.StartDate,r.StartHour,r.Backuped,r.Checked Checked1,r.Direction,r.ProjId
			   			,r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI
			   			,a.agentname,p.projname,isnull(r.DataEncrypted,0) dataencrypted,r.trunk
			   			,re.item01, re.item02,re.item03
			   			/*, null item04,
			   			null item05, null item06,
			   			null item07, null item08,
			   			null item09, null item10,
			   			null note, null itemtime,
			   			null handler */
					from records r 
						left join dbo.RecordsEvtCaculate ra on r.recordid = ra.recordid
						left join [dbo].[RecExts]re on r.recordid = case when re.recordid = 0 then re.UCID else re.recordid end
			   			/*left join connection c on c.recordid = r.recordid*/ 
			   			left join agentgrouprec g on g.recordid=r.recordid
			   			--left join taskrec t on t.recordid=r.recordid 
			   			left join agent a on a.agentid=r.master
			   			left join project p on r.projid=p.projid
			   			left join Storage vs on r.VideoUrl = vs.FtpID '
	
	/*权限控制录音记录取舍Begin*/

	if len(@AgentID_p) = 0 and len(@Address_p) = 0 and len(@AgentGroupId_p) = 0 and len(@AddressGroup_p) = 0
		goto _NEXT

	if len(@AgentID_p) > 0 begin
		
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AgentID_p' as ParaName,ParamKey as ParaValue from dbo.ufnSplitStringToTable(@AgentID_p,',');
				
		insert into #t_record(recordid) 
			select recordid 
			from records r 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			AND r.[master] IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'AgentID_p');
	end
	if len(@Address_p) > 0 begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'Address_p',ParamKey from dbo.ufnSplitStringToTable(@Address_p,',');

		insert into #t_record(recordid) 
			select recordid 
			from records r 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			AND r.extension IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'Address_p');
	end

	if len(@AgentGroupId_p) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AgentGroupId_p' as ParaName,ParamKey as ParaValue from dbo.ufnSplitStringToTable(@AgentGroupId_p,',');
		
		insert into #t_record(recordid) 
			select recordid 
			from records r, GroupAgent g 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			and r.[Master] = g.agentid
			AND g.groupid IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'AgentGroupId_p'); 

	end
	if len(@AddressGroup_p) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AddressGroup_p' as ParaName,ParamKey as ParaValue from dbo.ufnSplitStringToTable(@AddressGroup_p,',');
		insert into #t_record(recordid) 
			select recordid 
			from records r, GroupAddress g 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			and r.extension = g.[Address]
			AND g.groupid IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'AddressGroup_p'); 

	end
	
	set @bPrivilege = 1
	
	/*权限控制录音记录取舍End*/
	
	_NEXT:
	IF @SiteID >=1
	begin
		insert into #agent2(Agentid)
		select [Master] as agentid from dbo.records where [SiteID] =@SiteID;
	end;
	if exists(select Agentid from #agent2)
	begin
		if(@AgentGroupId !='' and @AgentID !='')
		begin
			insert into #t_agent([Master])
			select a.agentid from #agent2 a inner join dbo.GroupAgent ga on a.agentid = ga.agentid
				inner join dbo.ufnSplitStringToTable(@AgentGroupId,',') b on ga.groupid = b.ParamKey
				inner join dbo.ufnSplitStringToTable(@AgentID,',')c on a.agentid = c.ParamKey;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		else if(@AgentGroupId !='' and @AgentID ='')
		begin
			insert into #t_agent([Master])
			select a.agentid from #agent2 a inner join dbo.GroupAgent ga on a.agentid = ga.agentid
				inner join dbo.ufnSplitStringToTable(@AgentGroupId,',') b on ga.groupid = b.ParamKey;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		else if(@AgentGroupId ='' and @AgentID !='')
		begin
			insert into #t_agent([Master])
			select a.agentid from #agent2 a inner join dbo.ufnSplitStringToTable(@AgentID,',')c on a.agentid = c.ParamKey;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		else
		begin
			insert into #t_agent([Master])
			select agentid from #agent2;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		
	end 
	else 
	begin
		if(@AgentGroupId !='' and @AgentID !='')
		begin
			insert into #t_agent([Master])
			select ga.agentid from dbo.GroupAgent ga
				inner join dbo.ufnSplitStringToTable(@AgentGroupId,',') b on ga.groupid = b.ParamKey
				inner join dbo.ufnSplitStringToTable(@AgentID,',')c on ga.agentid = c.ParamKey;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		else if(@AgentGroupId !='' and @AgentID ='')
		begin
			insert into #t_agent([Master])
			select ga.agentid from dbo.GroupAgent ga
				inner join dbo.ufnSplitStringToTable(@AgentGroupId,',') b on ga.groupid = b.ParamKey;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		else if(@AgentGroupId ='' and @AgentID !='')
		begin
			insert into #t_agent([Master])
			select c.ParamKey as agentid from dbo.ufnSplitStringToTable(@AgentID,',')c ;
			select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] ';
		end
		else
			begin
				select @sch = @sch
			end
	
	end ;
	set @sch = @sch + ' where 1 = 1'
	if @RecordID = ''
		set @sch = @sch + ' and	(StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')'
	

	if @GroupID !=0 
		set @sch = @sch + ' and g.groupid = ' + convert(varchar, @GroupID)
	
	if @uui != ''
		set @sch = @sch + ' and r.uui  like ''%' +  @uui + '%'''
		 
	if len(@Address) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'Address',ParamKey from dbo.ufnSplitStringToTable(@Address,',');

		set @sch = @sch + ' and r.[extension] in (SELECT ParaValue FROM #PARAMETER WHERE ParaName =N''Address'') '
	end
	
	if len(@acd) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'acd',ParamKey from dbo.ufnSplitStringToTable(@acd,',');
		set @sch = @sch + ' and r.[acd] in (SELECT ParaValue FROM #PARAMETER WHERE ParaName =N''acd'') '
	end

	if len(@CustmoerPhone) <8
	begin
		set @sch = @sch + ' and (r.answer = '+''''+@CustmoerPhone+''''+ ' or r.extension = '+''''+@CustmoerPhone+''''+' or r.calling = '+''''+@CustmoerPhone+''''+' or r.called = '+''''+@CustmoerPhone+''''+')'
	end
	else
	begin
		set @sch = @sch + ' and (CHARINDEX(r.answer,'+''''+@CustmoerPhone+''''+')>=1 or CHARINDEX(r.extension,'+''''+@CustmoerPhone+''''+')>=1 or CHARINDEX(r.calling,'+''''+@CustmoerPhone+''''+')>=1 or CHARINDEX(r.called,'+''''+@CustmoerPhone+''''+')>=1)'
		--set @sch = @sch + ' and (r.answer like '+''''+'%'+@CustmoerPhone+'%'+''''+ ' or r.extension like '+''''+'%'+@CustmoerPhone+'%'+''''+' or r.calling like '+''''+'%'+@CustmoerPhone+'%'+''''+' or r.called like '+''''+'%'+@CustmoerPhone+'%'+''''+')' 
	end
	
	if len(@Calling) > 0 begin
	
			set @Calling = case when @Calling like '%[/%/_/[/]]%' ESCAPE '/' then @Calling
						   else '%' + @Calling + '%'
					  end
		set @sch = @sch + ' and r.calling like ''' +  @Calling + ''''
	end
	
	if len(@Called) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'Called',ParamKey from dbo.ufnSplitStringToTable(@Called,',');

		select @sch = @sch + ' and (r.[answer] in (SELECT ParaValue FROM #PARAMETER WHERE ParaName =N''Called'') or r.[called] in (SELECT ParaValue FROM #PARAMETER WHERE ParaName =N''Called''))'

	end
	
	if len(@AddressGroup) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AddressGroup' as ParaName,ParamKey as ParaValue from dbo.ufnSplitStringToTable(@AddressGroup,',');
		INSERT INTO #MIDTABLE([MIDNAME],[MIDVALUE])
		select 'GroupAddress',[Address]
			from GroupAddress
			where groupid IN(SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'AddressGroup');
			
		select @sch = @sch + ' and r.extension IN(SELECT [MIDVALUE] FROM #MIDTABLE WHERE [MIDNAME] = ''GroupAddress'')';
	end

	if (@Label !='')  
		set @sch = @sch + ' and r.RecordID in (select distinct RecordID from Label where Label like''%' + rtrim(ltrim(@Label)) + '%'')' 
	else if (@Labeled = 1)  
		set @sch = @sch + ' and r.checked = 1 ' 
	if (@CalltimeTo !=0)  
		set @sch = @sch + ' and r.seconds between ' + str(@CalltimeFrom*60) + ' and ' + str(@CalltimeTo*60) 
	if (@MutetimeTo !=0)  
		set @sch = @sch + ' and ra.MuteCnt between ' + str(@MutetimeFrom) + ' and ' + str(@MutetimeTo) 
	if (@HoldtimeTo !=0)  
		set @sch = @sch + ' and ra.holdCnt between ' + str(@HoldtimeFrom) + ' and ' + str(@HoldtimeTo) 
	if (@ConferencetimeTo !=0)  
		set @sch = @sch + ' and ra.ConfCnt between ' + str(@ConferencetimeFrom) + ' and ' + str(@ConferencetimeTo) 
	if (@RecordID !=0)  begin
		set @sch = @sch + ' and r.RecordID=' + cast(@RecordID as varchar(20))		
	end
	else begin
		if (@UCID != '') begin
			set @sch = @sch + ' and r.ucid like ''' + ltrim(@UCID) + '%'''
		end
	end

	if len(@TrunkGroup) > 0 begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'TrunkGroup',ParamKey from dbo.ufnSplitStringToTable(@TrunkGroup,',');

		select @sch = @sch + ' AND r.channel/1000 IN(SELECT ParaValue FROM #PARAMETER WHERE ParaName = N''TrunkGroup'' ) '

	end
		
	if len(@projId) > 0 
	begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'projId',ParamKey from dbo.ufnSplitStringToTable(@projId,',');

		select @sch = @sch + ' and r.projId IN(SELECT ParaValue FROM #PARAMETER WHERE ParaName = N''projId'' ) ';

	end

	set @direction = isnull(@direction, '')
	if (@direction = 'in' or @direction = 'inbound') begin
		set @sch = @sch + ' and inbound = 1 and outbound = 0'
	end
	if (@direction = 'out' or @direction = 'outbound') begin
		set @sch = @sch + ' and inbound = 0 and outbound = 1'
	end
	if (@direction = 'inner') begin
		set @sch = @sch + ' and inbound = 0 and outbound = 0'
	end
	
	if @recordType != ''
	begin
		if charindex(',1,', ',' + @recordType + ',', 0) > 0
			set @sch = @sch + ' and r.RecFlag=1'
		if charindex(',2,', ',' + @recordType + ',', 0) > 0
			set @sch = @sch + ' and r.ScrFlag=1'
		if charindex(',3,', ',' + @recordType + ',', 0) > 0
			set @sch = @sch + ' and r.VideoFlag=1'
	end
	
	set @sch = @sch + ' and (r.RecFlag=1 or r.ScrFlag=1 or r.VideoFlag=1)'
	
	if @transInCount is not null
	begin
		if @transInCount = 0
			set @sch = @sch + ' and r.transInCount=0'
		if @transInCount = 1
			set @sch = @sch + ' and r.transInCount>0'
	end
	if @transOutCount is not null
	begin
		if @transOutCount = 0
			set @sch = @sch + ' and r.transOutCount=0'
		if @transOutCount = 1
			set @sch = @sch + ' and r.transOutCount>0'
	end
	if @confsCount is not null
	begin
		if @confsCount = 0
			set @sch = @sch + ' and r.confsCount=0'
		if @confsCount = 1
			set @sch = @sch + ' and r.confsCount>0'
	end
	if @holdRate>0
	begin
		set @sch = @sch +' and holdRate >='+@holdRate;
	end
	if @ConfRate>0
	begin
		set @sch = @sch +' and ConfRate >='+@ConfRate;
	end
	if @MuteRate>0
	begin
		set @sch = @sch +' and MuteRate >='+@MuteRate;
	end
	if (@LogID >1) 
	begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  
		begin 
			declare @sch_agent varchar(1000) 
			declare @agents_all varchar(1000) 
			declare @groups_all varchar(1000) 
			set @agents_all = (select agents from supervisor where logid=@logID) 
			set @agents_all = ltrim(rtrim(isnull(@agents_all, ''))) 
			if (@agents_all !='') 
				--set @agents_all =  'c.agent in (' + ltrim(rtrim(@agents_all)) + ') or r.master in (' + ltrim(rtrim(@agents_all)) + ')'
				set @agents_all =  'r.master in (' + ltrim(rtrim(@agents_all)) + ')'
			else 
				set @agents_all = '' 
			set @groups_all = (select groups from supervisor where logid=@logID) 
			set @groups_all = ltrim(rtrim(isnull(@groups_all, ''))) 
			if (@groups_all !='') 
				set @groups_all = 'g. groupid in (' + @groups_all+ ')' 
			else 
				set @groups_all = ' ' 
			if (@agents_all !='' and @groups_all !='')  
				set @sch_agent = ' and (' + @agents_all + ' or ' + @groups_all + ')' 
			else if (@agents_all !='' or @groups_all !='') 
				set @sch_agent = ' and (' + @agents_all + @groups_all + ')' 
			else  
				set @sch_agent = ' and (r.master= ''1'')' 
				--set @sch_agent = ' and (c.agent= ''1'')' 
			set @sch = @sch + @sch_agent 
		end
	end
		
		set @sch = 'select *,row_number()over(order by t.'+@Orderby+' desc)as oder into ##t from (' 
			 + @sch  + ' and r.seconds>0 '
			 + case when @bPrivilege > 0 then '
						and exists(select 1 from #t_record tr 
										where tr.recordid = r.recordid)' else '' end
			 + ') t '
			 --+ ' order by t.' + @Orderby + ' desc '
			 

	--select @sch

	execute(@sch) ;

	declare @TotalPage int
	set @TotalPage=(select max(oder) from ##t);
	select * from ##t where oder between @StartPage and @EndPage;
	
	select @TotalPage total

		drop table ##t;
		DROP TABLE #t_record;
		DROP TABLE #t_agent;
		drop table #agent2;
		drop table #MIDTABLE;
		drop table #PARAMETER;
	
END
GO

USE [VisionLog40]
GO
/****** Object:  StoredProcedure [dbo].[usp_Get_ScreenFailStation]    Script Date: 2016/12/20 9:29:44 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROCEDURE [dbo].[usp_Get_ScreenFailStation]  
  @IN_BeginDate varchar(10)='', 
  @IN_EndDate varchar(10)=''
AS   
BEGIN     
----GroupId	GROUPNAME
----1015	AT&T MCU
----1018	AT&T UM
----1022	AT&T UV ICM ES
----1023	AT&T UV ICM MK
----1029	AT&T UVerse Blue MK
----1030	AT&T Uverse Blue QC
----1031	AT&T Uverse Blue WM
----1034	AT&T Uverse ICM QC1 C
----1037	AT&T Valuemarket agents DV 	 
       

   SELECT A.*,B.GroupId INTO #T_AA FROM (
   SELECT Extension,TrsStation,Master As AgentID,SUM(SCRFLAG) AS Have_Scree,SUM(CASE WHEN scrflag=0 THEN 1 ELSE 0 END) As  No_Screen
   FROM RECORDS 
   WHERE STARTDATE>=replace(@IN_BeginDate,'-','') AND STARTDATE<=replace(@IN_EndDate,'-','') 
         AND TrsStation NOT IN (SELECT Stationname FROM  station_noNeedStatic) 
		 AND master IN (SELECT  agentid FROM groupagent WHERE groupid in (1015,1018,1022,1023,1029,1030,1031,1034,1037) )
   GROUP BY extension,TrsStation,Master
   ) A, GroupAgent B WHERE A.Have_Scree=0 and A.No_Screen>=1 AND A.AgentID=B.AgentId

   SELECT #T_AA.Extension,#T_AA.TrsStation,#T_AA.AgentID,BB.GroupName,#T_AA.No_Screen
   FROM #T_AA
   LEFT JOIN AgentGroup BB ON #T_AA.GroupId=BB.GroupId
   WHERE BB.GroupId<>1002
   ORDER BY BB.GROUPNAME DESC

END
GO

alter table Project drop column Items
GO
alter table Project drop column Head01
GO
alter table Project drop column Head02
GO
alter table Project drop column Head03
GO
alter table Project drop column Head04
GO
alter table Project drop column Head05
GO
alter table Project drop column Head06
GO
alter table Project drop column Head07
GO
alter table Project drop column Head08
GO
alter table Project drop column Head09
GO
alter table Project drop column Head10
GO

alter table Project add TimeRangeType tinyint
GO
alter table Project add WeekState int
GO
alter table Project add MonthState int
GO
alter table Project add date_start varchar(8)
GO
alter table Project add date_end varchar(8)
GO
alter table Project add time_start varchar(8)
GO
alter table Project add time_end varchar(8)
GO
alter table Project add RecPercent tinyint
GO
alter table Project add ScrPercent tinyint
GO
alter table Project add VideoPercent tinyint
GO
alter table Project add DataEncry bit
GO
alter table Project add AutoBackup bit
GO
alter table Project add DestFolder varchar(256)
GO
alter table Project add BackupDays smallint
GO
alter table Project add BackupTime smallint
GO
alter table Project add RecKeepDays smallint
GO
alter table Project add ScrKeepDays smallint
GO
alter table Project add VideoKeepDays smallint
GO
alter table Project add TransStopRecord bit
GO

ALTER TABLE [dbo].[Records] DROP CONSTRAINT [DF_Records_DataEncry]
alter table Records alter column DataEncrypted int
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_DataEncry]  DEFAULT ((0)) FOR [DataEncrypted]

GO
alter table RecExts drop constraint PK_RecExts
GO
alter table RecExts add constraint PK_RecExts primary key (RecordId)
GO

alter table ProjItemType add Enabled bit
GO

use visionlog40
GO
update ProjItemType set enabled =1 where (type = 3) or (type = 4)
GO

use vxi_common

alter table Employee add LoginCount int
GO
update employee set LoginCount=1 where id=1
update employee set LoginCount=0 where id != 1 and password='8ddcff3a80f4189ca1c9d4d902c3c909'

declare @dictionary_tableid1 int
declare @dictionary_col1 int, @dictionary_col2 int, @dictionary_col3 int, @dictionary_col4 int, @dictionary_col5 int
declare @dictionary_col6 int, @dictionary_col7 int, @dictionary_col8 int, @dictionary_col9 int, @dictionary_col10 int
declare @optiongroupid int

--ScreenCfg
insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'ScreenCfg', null, null, 'Table     ', null, null, null, null, null, null, null, null, null, null, null, null, null, null, 'VisionLog40', null, null, null, null, null, null, null, null, null, null, 'dbo');
set @dictionary_tableid1=@@identity

insert into Module(Code, AppId, Name, keyword, ModuleGroup, CRUDX, entryForExt, entry, Sequence, DictionaryID, EntityName, parentId, SubMode, SearchPage, EditPage, ViewPage, smallIcon, BigIcon, defaultValueDefine, hiddenFieldDefine, readonlyFieldDefine, ConverterFieldDefine, fieldTitleDefine, columnWidthDefine, isMenu, isReport, openMode, iframe, reloadOnclick, whereSql) values('22P19', 22, '录屏配置', 'module_22P19', null, '111111', '/simple/commonSimpleList!default.action', '/simple/commonSimpleList!default.action', 19, @dictionary_tableid1, 'com.vxichina.products.visionone.po.visionlog.ScreenCfg', null, '', 'commonSimpleList_jq.jsp', '', '', 'icon-gears', '', null, '', '', null, null, null, null, 'N', 'T', 1, 1, null);

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'ScreenCfgID', '', 'ID', 'Field     ', 'ScreenCfg', '', 'int       ', 'FSUI006', null, null, null, null, 10, 1, 0, 1, null, 0, 'VisionLog40', null, null, 1, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col1=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'ScreenCfgName', 'visionlog.dictionary.ScreenCfg.ScreenCfgName', '名称', 'Field     ', 'ScreenCfg', '', 'varchar   ', 'FSUI001', null, null, null, null, 50, 0, 0, 0, null, 0, 'VisionLog40', null, null, 2, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col2=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'Description', 'visionlog.dictionary.ScreenCfg.Description', '描述', 'Field     ', 'ScreenCfg', '', 'varchar   ', 'FSUI002', null, null, null, null, 1000, 0, 0, 0, null, 1, 'VisionLog40', null, null, 3, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col3=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'StartDate', 'visionlog.dictionary.ScreenCfg.StartDate', '开始日期', 'Field     ', 'ScreenCfg', '', 'varchar   ', 'FSUI008', null, 'yyyyMMdd', null, null, 8, 0, 0, 0, null, 1, 'VisionLog40', null, null, 4, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col4=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'EndDate', 'visionlog.dictionary.ScreenCfg.EndDate', '结束日期', 'Field     ', 'ScreenCfg', '', 'varchar   ', 'FSUI008', null, 'yyyyMMdd', null, null, 8, 0, 0, 0, null, 1, 'VisionLog40', null, null, 5, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col5=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'ScrFtpID', 'visionlog.dictionary.ScreenCfg.ScrFtpID', '图像存储', 'Field     ', 'ScreenCfg', 'Storage.ftpId', 'smallint  ', 'FSUI003', 'select ftpid,station + ''('' + folder + '')'' station from visionlog40..Storage', null, null, null, 5, 0, 0, 0, null, 1, 'VisionLog40', null, null, 6, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col6=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'VideoEnabled', 'visionlog.dictionary.ScreenCfg.VideoEnabled', '是否录制视频', 'Field     ', 'ScreenCfg', '', 'tinyint   ', 'FSUI003', '1:Yes;0:No', null, null, null, 5, 0, 0, 0, null, 1, 'VisionLog40', null, null, 7, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col7=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'VideoFtpID', 'visionlog.dictionary.ScreenCfg.VideoFtpID', '视频存储', 'Field     ', 'ScreenCfg', 'Storage.ftpId', 'smallint  ', 'FSUI003', 'select ftpid,station + ''('' + folder + '')'' station from visionlog40..Storage', null, null, null, 5, 0, 0, 0, null, 1, 'VisionLog40', null, null, 8, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col8=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'VideoZoomScale', 'visionlog.dictionary.ScreenCfg.VideoZoomScale', '视频缩放比', 'Field     ', 'ScreenCfg', '', 'smallint  ', 'FSUI001', '', 'FSVT001', null, null, 5, 0, 0, 0, null, 1, 'VisionLog40', null, null, 9, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col9=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(22, 'Enabled', 'visionlog.dictionary.ScreenCfg.Enabled', '状态', 'Field     ', 'ScreenCfg', '', 'bit       ', 'FSUI003', 'true:Enable;false:Disable', null, null, null, 1, 0, 0, 0, null, 1, 'VisionLog40', null, null, 10, null, null, null, null, null, null, null, 'dbo');
set @dictionary_col10=@@identity

insert into SearchCondition(moduleCode, DictionaryID, UIType, uisize, options, CanEmpty, SearchMode, sequence, defaultValue, readonly, format, reloadGridHead, displayAll, keyword) values('22P19', @dictionary_col2, 'FSUI001', null, '', 1, 'FSSM002', 1, '', 0, '', 0, null, null);
insert into SearchCondition(moduleCode, DictionaryID, UIType, uisize, options, CanEmpty, SearchMode, sequence, defaultValue, readonly, format, reloadGridHead, displayAll, keyword) values('22P19', @dictionary_col10, 'FSUI003', null, 'true:Enable;false:Disable', 1, 'FSSM001', 2, '', 0, '', 0, null, null);

insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col2, 1, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col3, 2, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col4, 3, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col5, 4, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col6, 5, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col7, 6, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col8, 7, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col9, 8, 'default   ', null, null, '', '', '');
insert into SearchResult(ModuleCode, DictionaryID, Sequence, sort, DisplayFormat, Label, Prefix, gridRenderer, converter) values('22P19     ', @dictionary_col10, 9, 'default   ', null, null, '', '', '');

insert into I18ndict(keyword, language, name) values('module_22P19', 'zh', '录屏配置');
insert into I18ndict(keyword, language, name) values('module_22P19', 'en', 'Screenshot & Video Configuration');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.ScreenCfgName', 'zh', '名称');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.ScreenCfgName', 'en', 'Name');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.Description', 'zh', '描述');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.Description', 'en', 'Description');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.StartDate', 'zh', '开始日期');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.StartDate', 'en', 'Start Date');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.EndDate', 'zh', '结束日期');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.EndDate', 'en', 'End Date');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.ScrFtpID', 'zh', '图像存储');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.ScrFtpID', 'en', 'Screenshot Storage');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.VideoEnabled', 'zh', '是否录音视频');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.VideoEnabled', 'en', 'Video Enabled');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.VideoFtpID', 'zh', '视频存储');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.VideoFtpID', 'en', 'Video Storage');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.VideoZoomScale', 'zh', '视频缩放比');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.VideoZoomScale', 'en', 'Video ZoomScale Ratio');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.Enabled', 'zh', '状态');
insert into I18ndict(keyword, language, name) values('visionlog.dictionary.ScreenCfg.Enabled', 'en', 'Status');
insert into I18ndict(keyword, language, name) values('visionlog.timetype.monthly', 'zh', '每月');
insert into I18ndict(keyword, language, name) values('visionlog.timetype.monthly', 'en', 'Monthly');

insert into RoleModule(RoleId, ModuleCode, CRUDX) values(13, '22P19', '11111');

insert into OptionGroup(KeyWord, GroupName, GroupCode, parentId, StartDate, EndDate, builtin, itemSQL) values('visionlog.timetype', '时间类型', null, null, null, null, null, null);
set @optiongroupid=@@identity

insert into OptionItem(KeyWord, ItemName, ItemCode, GroupID, ParentID, StartDate, EndDate, status, builtin, orderNo) values('visionlog.timetype.range', '按范围', '1', @optiongroupid, null, null, null, 1, null, null);
insert into OptionItem(KeyWord, ItemName, ItemCode, GroupID, ParentID, StartDate, EndDate, status, builtin, orderNo) values('visionlog.timetype.weekly', '每周', '2', @optiongroupid, null, null, null, 1, null, null);
insert into OptionItem(KeyWord, ItemName, ItemCode, GroupID, ParentID, StartDate, EndDate, status, builtin, orderNo) values('visionlog.timetype.monthly', '每月', '3', @optiongroupid, null, null, null, 1, null, null);

update module set entryForExt='/visionone/project!showMain.action', entry='/visionone/project!showMain.action' where code='22P16'

delete from RoleModule where ModuleCode='24P01'

insert into Module(Code, AppId, Name, keyword, ModuleGroup, CRUDX, entryForExt, entry, Sequence, DictionaryID, EntityName, parentId, SubMode, SearchPage, EditPage, ViewPage, smallIcon, BigIcon, defaultValueDefine, hiddenFieldDefine, readonlyFieldDefine, ConverterFieldDefine, fieldTitleDefine, columnWidthDefine, isMenu, isReport, openMode, iframe, reloadOnclick, whereSql) values('22P20', 22, '加密管理', 'module_22P20', null, '111111', '/visionone/encry_keys!showMain.action', '/visionone/encry_keys!showMain.action', 20, null, null, null, '', null, '', '', 'icon-gears', '', null, '', '', null, null, null, null, 'N', 'T', 1, 1, null);
insert into RoleModule(RoleId, ModuleCode, CRUDX) values(13, '22P20', '11111');

insert into I18ndict(keyword, language, name) values('module_22P20', 'zh', '加密管理');
insert into I18ndict(keyword, language, name) values('module_22P20', 'en', 'Encryption Management');

update Dictionary set options='select type,dbo.fuc_transferKeyword(typename,''en'') typename from VisionLog41..ProjItemType where enabled=1' where id=3333
update SearchCondition set options='select type,dbo.fuc_transferKeyword(typename,''en'') typename from VisionLog41..ProjItemType where enabled=1' where id=1030

use vxi_common

alter table SysOperateLog add OperateRemote nvarchar(500)
go
update SysOperateLog set operateRemote=operateComment, operateComment='' where charindex('IP:', operateComment, 0) > 0

insert into I18NDict
select 'sysoperate.records.search','zh','录音记录查询'
insert into I18NDict
select 'sysoperate.records.search','en','Serch Records'

insert into I18NDict
select 'sysoperate.records.play','zh','录音播放'
insert into I18NDict
select 'sysoperate.records.play','en','Play Record'

insert into I18NDict
select 'sysoperate.records.screenshots','zh','截屏播放'
insert into I18NDict
select 'sysoperate.records.screenshots','en','Play Screenshots'

insert into I18NDict
select 'sysoperate.records.package','zh','录音打包'
insert into I18NDict
select 'sysoperate.records.package','en','Package Records'

insert into I18NDict
select 'sysoperate.records.download','zh','录音下载'
insert into I18NDict
select 'sysoperate.records.download','en','Download Record'

insert into I18NDict
select 'sysoperate.records.download.batch','zh','录音批量下载'
insert into I18NDict
select 'sysoperate.records.download.batch','en','Batch Download Records'

insert into I18NDict
select 'sysoperate.records.export','zh','录音数据导出'
insert into I18NDict
select 'sysoperate.records.export','en','Export Records'
GO
declare @id1 int, @id2 int, @id3 int, @id4 int

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(25, 'usp_Get_ScreenFailStation(?,?)', null, null, 'Procedure ', null, null, null, null, null, null, null, null, null, 0, null, 0, 0, null, 'VisionLog41', null, null, null, null, null, null, null, null, null, null, 'dbo');
set @id1=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(25, 'datebegin', 'usp_Get_ScreenFailStation.DateBegin', '开始日期', 'Field     ', 'usp_Get_ScreenFailStation(?,?)', '', 'varchar   ', 'FSUI006', '', null, '       ', '', 10, 0, 1, 0, null, null, 'VisionLog41', null, null, 1, null, null, null, null, null, null, null, 'dbo');
set @id2=@@identity

insert into Dictionary(AppId, keyName, keyword, value, type, tableName, tableReferenced, DataType, UIType, options, displayformat, ValidationType, Regex, Datalength, isIdentity, isNull, isPrimaryKey, isUnique, canEmpty, dbName, defaultValue, gridRenderer, sortOrder, hiddenLabel, readonly, casecadeId, casecadeId1, casecadeId2, isExclusiveLine, showInResult, schemaName) values(25, 'dateend', 'usp_Get_ScreenFailStation.DateEnd', '结束日期', 'Field     ', 'usp_Get_ScreenFailStation(?,?)', '', 'varchar   ', 'FSUI006', '', null, '       ', '', 10, 0, 1, 0, null, null, 'VisionLog41', null, null, 2, null, null, null, null, null, null, null, 'dbo');
set @id3=@@identity

insert into Report(appId, title, spName, Conditions, HeadFixed, headLabel, ShowRptName, ShowRptCreater, CreaterLayout, ShowRptCondition, ConditionLayout, SummayLayout, DownloadType, DataGenType, ShowIndex, Type, designFile, HeadDelim, paged, groupby) values(25, 'TRS监控', 'VisionLog41.usp_Get_ScreenFailStation(?,?)', null, 0, null, 1, 1, null, 1, '1', null, null, null, null, 'Simple', null, '*', 1, null);
set @id4=@@identity

--insert into Module(Code, AppId, Name, keyword, ModuleGroup, CRUDX, entryForExt, entry, Sequence, DictionaryID, EntityName, parentId, SubMode, SearchPage, EditPage, ViewPage, smallIcon, BigIcon, defaultValueDefine, hiddenFieldDefine, readonlyFieldDefine, ConverterFieldDefine, fieldTitleDefine, columnWidthDefine, isMenu, isReport, openMode, iframe, reloadOnclick, whereSql) values('25P01', 25, 'TRS监控', 'module_25P01', null, '111111', '/callcenter/report_manager!showMain.action?id=' + cast(@id4 as varchar(10)) + '&mid=25P01', '/callcenter/report_manager!showMain.action?id=' + cast(@id4 as varchar(10)) + '&mid=25P01', 1, @id1, null, null, '', 'commonSimpleList_jq.jsp', '', '', 'icon-gears', '', null, '', '', null, null, null, null, 'N', 'T', 1, 1, null);

insert into SearchCondition(moduleCode, DictionaryID, UIType, uisize, options, CanEmpty, SearchMode, sequence, defaultValue, readonly, format, reloadGridHead, displayAll, keyword) values('25P01', @id2, 'FSUI008', null, '', 1, 'FSSM001', 1, '%SYS_DATETIME%', 0, 'yyyy-MM-dd', 0, null, null);
insert into SearchCondition(moduleCode, DictionaryID, UIType, uisize, options, CanEmpty, SearchMode, sequence, defaultValue, readonly, format, reloadGridHead, displayAll, keyword) values('25P01', @id3, 'FSUI008', null, '', 1, 'FSSM001', 1, '%SYS_DATETIME%', 0, 'yyyy-MM-dd', 0, null, null);

insert into I18Ndict(keyword, language, name) values('module_25P01', 'zh', 'TRS监控');
insert into I18Ndict(keyword, language, name) values('module_25P01', 'en', 'TRS Monitor');
insert into I18Ndict(keyword, language, name) values('usp_Get_ScreenFailStation.DateBegin', 'zh', '开始日期');
insert into I18Ndict(keyword, language, name) values('usp_Get_ScreenFailStation.DateBegin', 'en', 'Start Date');
insert into I18Ndict(keyword, language, name) values('usp_Get_ScreenFailStation.DateEnd', 'zh', '结束日期');
insert into I18Ndict(keyword, language, name) values('usp_Get_ScreenFailStation.DateEnd', 'en', 'End Date');


Use vxi_common
update dictionary set dbname='VisionLog41' where dbname='VisionLog40'
update dictionary set options=replace(options,'VisionLog40','VisionLog41') where options like'%visionlog40%'
update SearchCondition set options=replace(options,'VisionLog40','VisionLog41') where options like'%visionlog40%'
update report set spname=replace(spname,'VisionLog40','VisionLog41') where spname like '%visionlog40%'

USE master 
--改逻辑名 


ALTER DATABASE visionlog40 MODIFY FILE(NAME='visionlog40',NEWNAME='visionlog41')
GO 
ALTER DATABASE visionlog40 MODIFY FILE(NAME='visionlog40_log',NEWNAME='visionlog41_log') -- 
GO 
declare @fullpath varchar(200);
declare @path varchar(200);
declare @rightpath varchar(200);
declare @pos int;

select  @fullpath=filename from master..sysdatabases where name = 'visionlog40'
print @fullpath
select @path =reverse(right(reverse(@fullpath),len(@fullpath)+1-charindex('\',reverse(@fullpath))))
print @path

--改数据库名
  DECLARE @sql nvarchar(500)   
  DECLARE @spid int
  SET @sql='declare getspid cursor for select spid from sysprocesses   where dbid=db_id('''+'visionlog40'+''')'
  EXECUTE (@sql)   OPEN getspid   FETCH NEXT FROM getspid INTO @spid
  WHILE @@fetch_status<>-1
      BEGIN
       EXECUTE('kill '+@spid)
       FETCH NEXT FROM getspid INTO @spid    
      END
  CLOSE getspid
  DEALLOCATE getspid
print @path
EXEC sys.sp_renamedb @dbname = 'visionlog40',@newname = 'visionlog41'  

print @path
--分离数据库
/* 
EXEC sp_detach_db 'visionlog41'
print @path
--打开xp_cmdshell功能 

EXEC sp_configure 'show advanced options', 1
--GO 
RECONFIGURE 
--GO 
EXEC sp_configure 'xp_cmdshell', 1 
--GO 
RECONFIGURE 
--GO 

declare @cmd varchar(200)
select @cmd = 'ren "'+rtrim(ltrim(@path)) + 'visionlog40.mdf" "visionlog41.mdf"'
print @cmd
EXEC xp_cmdshell @cmd

---- --改物理名 
--EXEC xp_cmdshell 'ren C:\Users\Administrator\Desktop\YQBlogAA_log.ldf YQBlog_log.ldf'--
set @cmd = 'ren "' + @path + 'visionlog40_log.ldf" '+ 'visionlog41_log.ldf'
print @cmd

EXEC xp_cmdshell @cmd


---- --重新附加 
--EXEC sp_attach_db @dbname = N'visionlog41',   
--@filename1 = N'C:\Users\Administrator\Desktop\YQBlog.mdf',   
--@filename2 = N'C:\Users\Administrator\Desktop\YQBlog_log.ldf' 
declare @filename1 varchar(200) 
declare @filename2 varchar(200) 
set @filename1 = @path+'visionlog41.mdf'
set @filename2 = @path+'visionlog41_log.ldf' 

--EXEC sp_attach_db @dbname = N'visionlog41', @filename1, @filename2
EXEC sp_attach_db 'visionlog41', @filename1, @filename2
*/