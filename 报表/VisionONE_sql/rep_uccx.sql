USE [master]
GO
CREATE DATABASE [rep_uccx]
GO

USE [rep_uccx]
GO
/****** Object:  StoredProcedure [dbo].[ACD_sync]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[ACD_sync]--- 同步_hds内的t_Termination_Call_Detail
AS
DECLARE @DBLink VARCHAR(20)
DECLARE @SqlStr VARCHAR(4000)
BEGIN
SELECT @DBLink = Server FROM rep_uccx.dbo.Link_Table
SET @SqlStr = '
 insert into AgentConnectionDetail
	 select sessionID
      ,sessionSeqNum
      ,nodeID
      ,profileID
      ,resourceID
      ,dateadd(hh,8,startDateTime) as startDateTime
      ,dateadd(hh,8,endDateTime) as endDateTime
      ,qIndex
      ,gmtOffset
      ,ringTime
      ,talkTime
      ,holdTime
      ,workTime
      ,callWrapupData
      ,callResult
      ,dialingListID 
     from ' + @DBLink + '.db_cra.dbo.AgentConnectionDetail m
	 where not exists(select 1 from AgentConnectionDetail s 
						where m.sessionID = s.sessionID
							and m.sessionSeqNum = s.sessionSeqNum
							and m.nodeID = s.nodeID
							and m.profileID = s.profileID
							and m.resourceID = s.resourceID
							and m.qIndex = s.qIndex)
 '
--PRINT @SqlStr 
EXEC (@SqlStr)
END

GO
/****** Object:  StoredProcedure [dbo].[ASD_sync]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--author haigang.chen@vxichina.com

CREATE PROCEDURE [dbo].[ASD_sync]--- 同步_hds内的[dbo.AgentStateDetail]
AS
DECLARE @DBLink VARCHAR(20)
DECLARE @SqlStr VARCHAR(4000)
BEGIN
SELECT @DBLink = Server FROM rep_uccx.dbo.Link_Table
SET @SqlStr = '
 insert into AgentStateDetail
	 select agentID
      ,dateadd(hh,8,eventDateTime) as eventDateTime
      ,gmtOffset
      ,eventType
      ,reasonCode
      ,profileID
     from ' + @DBLink + '.db_cra.dbo.AgentStateDetail m
	 where not exists(select 1 from dbo.AgentStateDetail s 
						where m.agentID = s.agentID
							and dateadd(hh,8,m.eventDateTime) = s.eventDateTime
							and m.eventType = s.eventType
							and m.reasonCode = s.reasonCode
							and m.profileID = s.profileID
						)
 '
--PRINT @SqlStr 
EXEC (@SqlStr)
END

GO
/****** Object:  StoredProcedure [dbo].[CCD_sync]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CCD_sync]--- 同步_hds内的t_Termination_Call_Detail
AS
DECLARE @DBLink VARCHAR(20)
DECLARE @SqlStr VARCHAR(4000)
BEGIN
SELECT @DBLink = Server FROM rep_uccx.dbo.Link_Table
SET @SqlStr = '
 insert into ContactCallDetail
	 select sessionID
      ,sessionSeqNum
      ,nodeID
      ,profileID
      ,contactType
      ,contactDisposition
      ,dispositionReason
      ,originatorType
      ,originatorID
      ,originatorDN
      ,destinationType
      ,destinationID
      ,destinationDN
      ,dateadd(hh,8,startDateTime) as startDateTime
      ,dateadd(hh,8,endDateTime) as endDateTime
      ,gmtOffset
      ,calledNumber
      ,origCalledNumber
      ,applicationTaskID
      ,applicationID
      ,applicationName
      ,connectTime
      ,customVariable1
      ,customVariable2
      ,customVariable3
      ,customVariable4
      ,customVariable5
      ,customVariable6
      ,customVariable7
      ,customVariable8
      ,customVariable9
      ,customVariable10
      ,accountNumber
      ,callerEnteredDigits
      ,badCallTag
      ,transfer
      ,redirect
      ,conference
      ,flowout
      ,metServiceLevel
      ,campaignID
	  ,NULL as OrigProtocolCallRef
	  ,NULL as DestProtocolCallRef
	  ,NULL as CallResult
	  ,NULL as dialinglistid
     from ' + @DBLink + '.db_cra.dbo.ContactCallDetail m
	 where not exists(select 1 from ContactCallDetail s 
						where m.sessionID = s.sessionID
							and m.sessionSeqNum = s.sessionSeqNum
							and m.nodeID = s.nodeID
							and m.profileID = s.profileID)
 '
--PRINT @SqlStr 
EXEC (@SqlStr)
END

GO
/****** Object:  StoredProcedure [dbo].[CQD_sync]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CQD_sync]--- 同步_hds内的[ContactQueueDetail]
AS
DECLARE @DBLink VARCHAR(20)
DECLARE @SqlStr VARCHAR(4000)
BEGIN
SELECT @DBLink = Server FROM rep_uccx.dbo.Link_Table
SET @SqlStr = '
 insert into ContactQueueDetail
	 select * from ' + @DBLink + '.db_cra.dbo.ContactQueueDetail m
	 where not exists(select 1 from ContactQueueDetail s 
						where m.sessionID = s.sessionID
							and m.sessionSeqNum = s.sessionSeqNum
							and m.nodeID = s.nodeID
							and m.profileID = s.profileID)
 '
--PRINT @SqlStr 
EXEC (@SqlStr)
END

GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_agent_work_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.07.04>
-- Description:	坐席工作统计报表
/*
Example:
exec [sp_agent_work_total] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_agent_work_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Agent		NVARCHAR(50)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
	@IsNeedTotal SMALLINT = NULL,
    @UserID     NVARCHAR(50)	= NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	declare @tempCount			int
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end

    DELETE FROM [iReport_ag_w_total] WHERE [UserID]=@UserID
	
	create table #T_AgentWorkTotal(
		period					varchar(30),	--周期
		segment					varchar(20),	--时间段
		beginTime				datetime	,	--start
		endTime					datetime	,	--end time segment
		
		agent					varchar(50),	--坐席工号	
		agentName				varchar(50)	--坐席名称	
		--,loginDuration			int,			--总登录时长	该坐席的总登录时长
		--answer					int ,			--坐席应答电话量	呼入该坐席的坐席应答数
		--abandon					int ,			--放弃呼叫数	呼入该坐席的放弃呼叫数
		--transfer				int ,			--转接呼叫数	针对该坐席的转接数
		--avgInboundDuration		int ,			--呼入平均时长	呼入该坐席的总时长/呼入该坐席的总呼入数
		--inboundTotalDuration	int,			--呼入总时长	呼入该坐席的总时长
		--fifteenAnswerRate		varchar(10) ,	--15秒内应答率	呼入坐席在15秒振铃时长内的应答数/总呼应答数
		
		--outboundTotal			int ,			--呼出数	坐席的呼出数
		--avgOutboundDuration		float,			--平均呼出通话时长	坐席呼出有应答的通话时长
		--outboundTotalDuration	int,			--呼出总时长	坐席呼出的总时长
		
		--readyDuration			int,			--就绪时长	坐席就绪状态的时长
		--inboundTalkDuration	    int,			--呼入通话时长	呼入时该坐席的应答时长
		--notready1Duration		int,			--用餐时长	用户置忙状态的用餐时长
		--notready2Duration		int,			--会议时长	用户置忙状态的会议时长
		--notready3Frequency		int,			--培训次数	
		--notready3Duration		int,			--培训时长	用户置忙状态的培训时长
		--notready4Frequency		int,			--休息次数	
		--notready4Duration		int,			--休息时长	

		--workFormTotal			int,			--工单总数	当前时间坐席所创建的工单数量
		--firstSolveRate			varchar(10),	--一线解决率	坐席自行处理的工单数/工单总数量
		--secondSolveRate			varchar(10),	--二线解决率	工单总数量减去坐席自行处理的工单数后再除以工单总数量
		--speedAnswerRate			varchar(10)		--快速应答率	15秒内应答数除以总应答数
	)
	
	set @strSql = ' insert into #T_AgentWorkTotal '
	declare @date1 datetime,@date2 datetime
	set @date1 = @DateBegin
	set @date2 = @DateEnd
	
	create table #temp_period (period varchar(20),beginTime datetime,endTime datetime)
	
	--周期特性 小时
	if ( lower(@GroupLevel) = 'hour' ) begin 
		--ALTER TABLE #temp_period ADD segment varchar(20)
		insert into #temp_period 
			select  period, CONVERT(datetime,period + ' ' + sBegin + '.000', 120) as beginTime, CONVERT(datetime,period + ' ' + sEnd + '.998', 120)  as endTime --,segment
			from (
				select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m , dbo.V_TimeSegment t
			
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
       	--print @strsql	
end

	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		insert into #temp_period 
			select  convert(varchar(7),dateadd(mm,number,@date1),120) as period,
				dateadd(ss,0,dateadd(mm,number,@date1)) as beginTime,dateadd(ss,-1,dateadd(mm,number+1,@date1)) as  endTime
			from master..spt_values where type='p' and number <= datediff(mm,@date1,@date2)
		
		update #temp_period	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_period) 	
		update #temp_period	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_period) 
		--select * from #temp_period
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		insert into #temp_period 

			select distinct dbo.week_series_to_str(dateadd(dd,number,@date1),0) as period,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ),112) as starttime,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ) + ' 23:59:59',120) +6 as endtime
			 from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			 
		update #temp_period	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_period) 	
		update #temp_period	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_period) 
		--select * from #temp_period
		
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		insert into #temp_period 
			select period, CONVERT(datetime,period + '-01-01 00:00:00', 120) as beginTime, CONVERT(datetime,period + '-12-31 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(4),dateadd(yy,number,@date1),120) from master..spt_values where type='p' and number <= datediff(yy,@date1,@date2)
			) m
		--更新开始时间 结束时间
		update #temp_period	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_period) 	
		update #temp_period	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_period) 
		
		--select * from #temp_period
		set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	--周期特性 日
	else begin 
		insert into #temp_period 
			select period, CONVERT(datetime,period + ' 00:00:00', 120) as beginTime, CONVERT(datetime,period + ' 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m
		
		set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	
	if (len(@agent) > 0) set @strSql = @strSql + ' where agent = ''' + @agent + ''''
	
	--print @strSQL
	
	EXECUTE(@strSQL)
	
	/*

	select @tempCount = count(*) from #T_AgentWorkTotal
		
	--判断有数据 计算 登陆时长

	if (@tempCount > 0 ) begin
	
		declare @tempAgent			nvarchar(50)
		declare @tempStartTime		datetime
		declare @tempEndTime		datetime
		declare @tempDuration		int
		
		declare @tempreadyDuration int
		declare @tempnotready1Duration		int			--用餐时长	用户置忙状态的用餐时长
		declare @tempnotready2Duration		int			--会议时长	用户置忙状态的会议时长
		declare @tempnotready3Duration		int			--培训时长	用户置忙状态的培训时长
		declare @tempnotready4Duration		int			--休息时长	

	   DECLARE tracetime CURSOR FOR
	   select agent,beginTime,endTime from #T_AgentWorkTotal
	   OPEN tracetime
	   FETCH NEXT FROM tracetime INTO @tempAgent,@tempStartTime,@tempEndTime
			WHILE (@@FETCH_STATUS=0)
			BEGIN
			--1 平均时长 2放弃数 3应答数 4转移数 其他 总时长
				--计算时长  
			   exec @tempDuration  = dbo.sp_sum_login_time	    @tempStartTime,@tempEndTime,@tempAgent

			   --ready duration

			   exec @tempreadyDuration = dbo.sp_sum_ready_time	    @tempStartTime,@tempEndTime,@tempAgent,'0'
			   --notready duration
			   /*exec @tempnotready1Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,1,'0'
			   exec @tempnotready2Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,2,'0'
			   exec @tempnotready3Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,3,'0'
			   exec @tempnotready4Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,4,'0'
				*/

			   update #T_AgentWorkTotal set loginDuration= @tempDuration,
						readyDuration=@tempreadyDuration,
						notready1Duration=@tempnotready1Duration,
						notready2Duration=@tempnotready2Duration,
						notready3Duration=@tempnotready3Duration,
						notready4Duration=@tempnotready4Duration
						
			    where agent = @tempAgent and beginTime = @tempStartTime and endTime = @tempEndTime

			FETCH NEXT FROM tracetime INTO @tempAgent,@tempStartTime,@tempEndTime
			END
		CLOSE tracetime
		DEALLOCATE tracetime    
	
	end
	*/
	
	/*
	if ( lower(@GroupLevel) = 'hour' ) begin
		select period,segment,agent ,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_AgentWorkTotal
	end
	else begin
		select period,agent,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_AgentWorkTotal
	end
	*/
	declare @tempMinStartTime 	datetime 
	declare @tempMaxEndTime 	datetime
		
	select @tempMinStartTime = convert(datetime,@DateBegin,120) 
	select @tempMaxEndTime	 = convert(datetime,@DateEnd + ' 23:59:59.998',120) 

	
	;with b as (
			select m.transfer,m.contactDisposition as contactDisposition
			,(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
			,s.startdatetime,
			(datediff(s,s.startDateTime,s.endDateTime)) callDuration,
			s.ringtime,
			s.talktime
			from ContactCallDetail m , AgentConnectionDetail s
			where  s.sessionID = m.sessionID  and s.nodeID = m.nodeID
					and s.profileID = m.profileID and m.sessionSeqNum = 0
					and s.startDateTime between @tempMinStartTime and @tempMaxEndTime 
	) ,c as (		
		select r.resourceLoginId as agent ,
				m.startDateTime,
				m.connectTime
				from dbo.ContactCallDetail m ,dbo.Resource r	
		where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1
		 and m.contacttype = 2 and m.destinationType = 3  and
		 m.startDateTime between @tempMinStartTime and @tempMaxEndTime 
	) , d as (
		select t.agent,t.period,t.beginTime,t.EndTime, count(1) as outbound,sum(connectTime) outboundDuration 
		from c ,#T_AgentWorkTotal t where c.agent = t.agent and c.startdatetime between t.beginTime and t.endTime
		group by t.agent,t.period,t.beginTime,t.EndTime
	),e as (
	
	select  t.agent,t.agentName,t.period,t.beginTime,t.EndTime,
	
	sum(case when b.contactDisposition=1 then 1 else 0 end ) as abandon,
    sum(case when b.contactDisposition=2 then 1 else 0 end ) as answer,
    sum(cast(b.transfer as smallint) ) as transfer,
    avg(callDuration) as avgInboundDuration,
    sum(callDuration) as inboundTotalDuration,
    sum(case when b.contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
    sum(talktime) as inboundTalkDuration
    from #T_AgentWorkTotal t,b where 
	 b.agent = t.agent and (b.startdatetime between t.beginTime and t.endTime)
	group by t.agent,t.agentName,t.period,t.beginTime,t.EndTime
	
	), asd as (
		select eventtype,eventdatetime,reasoncode,t.resourceLoginID agent,a.profileID from dbo.AgentStateDetail a , dbo.Resource t where t.resourceID=a.agentID and a.profileID = t.profileID
		and a.eventDateTime between @tempMinStartTime and @tempMaxEndTime and eventtype<>7
	), f as (
		select  agent, eventtype,eventDateTime,reasonCode
		,( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime  order by eventDateTime) nextTime
		--,(case when eventtype=1 then (( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime and b.eventtype=7  order by eventDateTime) ) else NULL end) nextLogTime
		from asd a
	), g as (
		
	select t.agent,t.period,t.beginTime,t.EndTime,
 
    sum(case 
		when (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
		when (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
		when (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
		when (f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
		else 0 end ) as loginduration,
	sum(case 
		when (f.eventtype=3 and f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
		when (f.eventtype=3 and f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
		when (f.eventtype=3 and f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
		when (f.eventtype=3 and f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
		else 0 end ) as readduration,
	sum(case 
		when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
		when (f.eventtype=2 and f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
		when (f.eventtype=2 and f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
		when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
		else 0 end ) as ACWDuration,	
	count(case  when (f.eventtype=2 ) then 1   end ) as ACW

    from f,#T_AgentWorkTotal t
		where f.agent = t.agent and 
		( (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime) or
		  (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime) or
		  (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) or
		  (f.eventDateTime < t.beginTime and f.nextTime > t.endTime) )

	group by t.agent,t.period,t.beginTime,t.EndTime
	)
	 --select * from g
 
	INSERT INTO [iReport_ag_w_total]
           ([UserID]
           ,[agent]
           ,[agentName]
           ,[period]
           ,[beginTime]
           ,[EndTime]
           ,[segment]
           ,[abandon]
           ,[answer]
           ,[transfer]
           ,[avgInboundDuration]
           ,[inboundTotalDuration]
           ,[fifteenAnswerRate]
           ,[speedAnswerRate]
           ,[inboundTalkDuration]
           ,[outbound]
           ,[outboundDuration]
           ,[acw]
           ,[loginDuration]
           ,[readyDuration]
           ,[acwDuration]
           ,[workFormTotal]
           ,[firstSolveRate]
           ,[secondSolveRate])
	select @UserID,t.agent,t.agentName+'(' + t.agent + ')' as agentName,
		t.period, convert(varchar(20),t.beginTime,120), convert(varchar(20),t.EndTime,120),
		substring (convert (varchar(20),t.beginTime,108),4,5) + '~' + substring (convert (varchar(20),t.endTime,108),4,5) segment,
		ISNULL(abandon,0) abandon,ISNULL(answer,0) answer,ISNULL(transfer,0) transfer,dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
		ISNULL(dbo.avg_str(fifAnser,answer,1),0) as fifteenAnswerRate,
		ISNULL(dbo.avg_str(fifAnser,answer,1),0) as speedAnswerRate,
		dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
		ISNULL( outbound,0)outbound,dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration   
		,acw,
		dbo.sec_to_time(isnull(g.loginduration,0)) loginDuration,
		dbo.sec_to_time(isnull(g.readduration,0)) readyDuration,
		dbo.sec_to_time(isnull(g.acwDuration,0)) acwDuration,
		NULL workFormTotal,
		NULL firstSolveRate,NULL secondSolveRate
		
		 from e as t
		left join d as c on  c.agent = t.agent and  c.beginTime = t.beginTime and c.EndTime = t.EndTime
		left join g      on  g.agent = t.agent and  g.beginTime = t.beginTime and g.EndTime = t.EndTime
 
	
	IF OBJECT_ID('tempdb..#temp_period') IS NOT NULL BEGIN
		DROP TABLE #temp_period
		PRINT 'delete temp table #temp_period'
	END
	
	IF OBJECT_ID('tempdb..#T_AgentWorkTotal') IS NOT NULL BEGIN
		DROP TABLE #T_AgentWorkTotal
		PRINT 'delete temp table #T_AgentWorkTotal'
	END
	return @@rowcount
END






GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_call_inbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	呼入明细报表
/*
Example:
exec sp_call_inbound @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@Calling='',@CallResult=''
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_call_inbound]
    @DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Calling	NVARCHAR(30)	= NULL,
	@CallResult NVARCHAR(30)	= NULL,
    @UserID     NVARCHAR(50)	= NULL  -- Add For iReport 
AS 

BEGIN
declare @DT_Begin			datetime,
		@DT_End				datetime,
		@strSql				NVARCHAR(MAX)
			
--	if isdate(@DateBegin) != 1  begin
--		set @DateBegin = convert(varchar(10), getdate(), 121)
--	end
--	
--	if isdate(@DateEnd) != 1 begin
--		set @DateEnd = convert(varchar(10), getdate(), 121)
--	end
--
--	SET @DateBegin = @DateBegin + ' 00:00:00'
--	SET @DateEnd   = @DateEnd   + ' 23:59:59'
	IF (@CallResult='全部')  
    BEGIN SET @CallResult='0' END
    ELSE IF (@CallResult='放弃') BEGIN SET @CallResult='1' END
    ELSE IF (@CallResult='成功') BEGIN SET @CallResult='2' END
    ELSE IF (@CallResult='失败') BEGIN SET @CallResult='3' END
    ELSE BEGIN SET @CallResult='0' END 
    

	SET @strSql = 'select '''+ @UserID +''', originatorDN as calling ,destinationDN as called,convert(varchar(20), m.startDateTime, 120) as recordTime,
	
	isnull((select extension from dbo.Resource r where r.resourceID = s.resourceID and r.profileId = s.profileID  ),calledNumber) as extension,
	
	connectTime as totalTime ,
		(select top 1 queuetime from ContactQueueDetail s 
								where s.sessionID = m.sessionID 
									and s.nodeID = m.nodeID
									and s.profileID = m.profileID
									and s.sessionSeqNum = 0) as queuetime,
		s.ringtime ,
		(case contactDisposition	when 1 then ''放弃'' when 2 then ''成功'' else ''失败'' end ) callresult
									
		from ContactCallDetail m 
		left join AgentConnectionDetail s 
		on s.sessionID = m.sessionID  and s.nodeID = m.nodeID and s.profileID = m.profileID and s.sessionSeqNum = m.sessionSeqNum
		where contactType =1 and originatorType = 3 and m.sessionSeqNum = 0 '	
		
		+ ' and convert(varchar(10), m.startDateTime, 23) BETWEEN ''' + @DateBegin + ''' And ''' + @DateEnd + ''''
	
	IF LEN(@Calling) > 0     set  @strSql = @strSql + ' and m.originatorDN like ''' + @Calling + '%'''
	
	IF (@CallResult = 1)  set  @strSql = @strSql + ' and m.contactDisposition = ' + @CallResult 
	
	IF (@CallResult = 2)  set  @strSql = @strSql + ' and m.contactDisposition = ' + @CallResult 
	
	IF (@CallResult > 2)  set  @strSql = @strSql + ' and m.contactDisposition > ' + @CallResult 
	
--  Begin:  Add For iReport
    DELETE FROM [iReport_Call_Inbound] WHERE [UserID] = @UserID

    SET @strSql = 'INSERT INTO [iReport_Call_Inbound]
				   ([UserID]
				   ,[CallingID]
				   ,[CalledID]
				   ,[CallinDateTime]
				   ,[ExtensionNo]
				   ,[CallinTotalDuration]
				   ,[CallQueueDuration]
				   ,[CallRingDuration]
				   ,[CallResult]) ' + @strSql
--  End  :  Add For iReport

	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_inbound] error '  
--	 SELECT calling = NULL, called = NULL, recordTime = NULL, extension = NULL, 
--		totalTime = NULL, queuetime = NULL, ringtime = NULL, callResult = NULL
--  Begin:  Add For iReport
     INSERT INTO [iReport_Call_Inbound]
				 ([UserID]
				 ,[CallingID]
				 ,[CalledID]
				 ,[ExtensionNo]
				 ,[CallinDateTime]
				 ,[CallinTotalDuration]
				 ,[CallQueueDuration]
				 ,[CallRingDuration]
				 ,[CallResult])
                 VALUES(
                 @UserID,
                 '--',
                 '--',
                 '--',
                 '--',
                 '--',
                 '--',
                 '--',
                 '--'
                 )
--  End  :  Add For iReport              
	RETURN -1;
END








GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_call_inbound_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.18>
-- Description:	呼入汇总报表
/*
Example:
exec [sp_call_inbound_total] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_call_inbound_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
	@IsNeedTotal SMALLINT       = NULL,
    @UserID     NVARCHAR(50)	= NULL
AS 
	declare @DT_Begin			datetime,
			@DT_End				datetime,
            @EXESQL  			NVARCHAR(MAX),        
			@strColumn			NVARCHAR(30),
			@strSegment			NVARCHAR(10),
            @Segment_Value      NVARCHAR(50)
BEGIN
		
--	if isdate(@DateBegin) != 1  begin
--		set @DateBegin = convert(varchar(10), getdate(), 121)
--	end
--	
--	if isdate(@DateEnd) != 1 begin
--		set @DateEnd = convert(varchar(10), getdate(), 121)
--	end
	IF (@GroupLevel='时')  
    BEGIN SET @GroupLevel='0' END
    ELSE IF (@GroupLevel='天') BEGIN SET @GroupLevel='1' END     
    ELSE IF (@GroupLevel='月') BEGIN SET @GroupLevel='2' END
    ELSE IF (@GroupLevel='周') BEGIN SET @GroupLevel='3' END
    ELSE IF (@GroupLevel='年') BEGIN SET @GroupLevel='4' END
    ELSE BEGIN SET @GroupLevel='1' END 

	
    DELETE FROM [iReport_Call_Inbound_Total] WHERE [UserID] = @UserID

	set @strSegment = ''
	
	if ( lower(@GroupLevel) = '0' ) begin
		set @strColumn = ' sTime '
		set @strSegment = ' ,segment '
        set @Segment_Value = ''
	end
	else if ( lower(@GroupLevel) = '2' ) begin 
		set @strColumn = ' sMonth '   
        set @strSegment = '' 
        set @Segment_Value = ',''00:00:00~23:59:59'' AS segment '   
	end
	else if ( lower(@GroupLevel) = '3' ) begin 
		set @strColumn = ' sWeek '
        set @strSegment = '' 
        set @Segment_Value = ',''00:00:00~23:59:59'' AS segment '
	end
	else if ( lower(@GroupLevel) = '4' ) begin 
		set @strColumn = ' sYear '
        set @strSegment = '' 
        set @Segment_Value = ',''00:00:00~23:59:59'' AS segment '
	end
	else begin 
		set @strColumn = ' sTime '
        set @strSegment = '' 
        set @Segment_Value = ',''00:00:00~23:59:59'' AS segment '
	end

	SET @EXESQL = 'select '+ @strColumn
					+ @strSegment + 
				    ',count ( * ) as total
					,count ( case contactDisposition when 2 then 1 end ) as answerTotal--应答数
					,count ( case when contactDisposition > 2 then 1 end ) as failTotal--失败数
					,count ( case when contactDisposition =1 then 1 end ) as abandonTotal--放弃数
					,count ( case when ringtime>0 and contactDisposition=1 then 1 end ) as agentLossTotal--坐席呼损数
					,count ( case when isnull(ringtime,0) <=0 and contactDisposition=1 and isnull(queuetime,0) > 0 then 1 end ) as queueLossTotal--排队呼损
					,count ( case when isnull(ringtime,0) <=0 and contactDisposition=1 and isnull(queuetime,0) <= 0 then 1 end ) as ivrLossTotal--ivr 呼损
					--,count ( case when ringtime > 0 and contactDisposition=2 and isnull(queuetime,0) > 0 then 1 end ) as afterQueueHandleTotal--排队后接通数
					,sum   ( case when ringtime > 0 and contactDisposition=2 and isnull(queuetime,0) > 0 then isnull(queuetime,0) else 0 end  ) as afterQueueHandleTimeTotal--排队接通后 总排队时间
					,count ( case when isnull(queuetime,0) > 0 then 1 end ) as queueTotal--排队数
					,sum   ( case when isnull(queuetime,0) > 0 then isnull(queuetime,0) else 0 end  ) as queueTimeTotal--排队总时间
					,sum	  ( ISNULL(queuetime,0)+ISNULL(ringtime,0)) as waitTimeTotal--应答总时间
				  INTO #Temp_A
                  from (select * from [V_CallInbound] where sTime BETWEEN ''' + @DateBegin + ''' And ''' + @DateEnd + ''' ) A
				  group by '+ @strColumn + @strSegment 

	SET @EXESQL = @EXESQL + '
						   INSERT INTO [iReport_Call_Inbound_Total]
						   ([UserID]
						   ,[StaticLevel]
						   ,[Segment]
						   ,[Total]
						   ,[AnswerTotal]
						   ,[AnswerRate]
						   ,[AgentLostTotal]
						   ,[WaitLostTotal]
						   ,[AbandonTotal]
						   ,[LostRate]
						   ,[AverageAnswerTime]
						   --,[AverageHandleTime]
						   ,[AverageQueueTime]) '
						   + 
						   'select '''+@UserID +''', '+ @strColumn + @Segment_Value + @strSegment + ' 
								,total
								,answerTotal
								,dbo.avg_str(answerTotal,total,1) as answerRate
								,agentLossTotal
								,(queueLossTotal + ivrLossTotal) as waitLossTotal
								,abandonTotal
								,dbo.avg_str(abandonTotal,total,1) as lossRate
								,dbo.avg_str(waitTimeTotal,total,0) as avgAnswerTime
								--,dbo.avg_str(afterQueueHandleTimeTotal,afterQueueHandleTotal,0) as avgHandleQueueTime
								,dbo.avg_str(queueTimeTotal,queueTotal,0) as avgQueueTime
						   from  #Temp_A ORDER BY '+ @strColumn + @strSegment 
	 
	if ( @IsNeedTotal = 1 ) 
    begin
        set @Segment_Value = ',''--:--:--'''
			
		set @EXESQL = @EXESQL + '
							   INSERT INTO [iReport_Call_Inbound_Total]
							   ([UserID]
							   ,[StaticLevel]
							   ,[Segment]
							   ,[Total]
							   ,[AnswerTotal]
							   ,[AnswerRate]
							   ,[AgentLostTotal]
							   ,[WaitLostTotal]
							   ,[AbandonTotal]
							   ,[LostRate]
							   ,[AverageAnswerTime]
							   --,[AverageHandleTime]
							   ,[AverageQueueTime]) '
							   +  'select '''+@UserID+''', ''TOTAL'''+ @Segment_Value + '
									,SUM(total) as total,
									SUM(answerTotal) as answerTotal,
									dbo.avg_str(SUM(answerTotal),SUM(total),1) as answerRate,
									SUM(agentLossTotal) as agentLossTotal,
									SUM(queueLossTotal + ivrLossTotal) as waitLossTotal,
									SUM(abandonTotal) as abandonTotal,
									dbo.avg_str(SUM(abandonTotal),SUM(total),1) as lossRate,
									dbo.avg_str(Sum(waitTimeTotal),sum(total),0) as avgAnswerTime,
									--dbo.avg_str(Sum(afterQueueHandleTimeTotal),sum(afterQueueHandleTotal),0) as avgHandleQueueTime,
									dbo.avg_str(Sum(queueTimeTotal),sum(queueTotal),0) as avgQueueTime 
								from #Temp_A '
	end
	
	PRINT @EXESQL

		
	BEGIN TRY        
		EXECUTE(@EXESQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_inbound_total] error '  
        INSERT INTO [iReport_Call_Inbound_Total]
           ([UserID]
           ,[StaticLevel]
           ,[Segment]
           ,[Total]
           ,[AnswerTotal]
           ,[AnswerRate]
           ,[AgentLostTotal]
           ,[WaitLostTotal]
           ,[AbandonTotal]
           ,[LostRate]
           ,[AverageAnswerTime]
           ,[AverageHandleTime]
           ,[AverageQueueTime])
        VALUES
           (@UserID
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--')

	RETURN -1;  
END





GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_call_loss_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.07.02>
-- Description:	呼损统计报表
/*
Example:
exec sp_call_loss_total @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14'
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_call_loss_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Called     NVARCHAR(50)	= NULL,
    @UserID     NVARCHAR(50)	= NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	
--			
--	if isdate(@DateBegin) != 1  begin
--		set @DateBegin = convert(varchar(10), getdate(), 121)
--	end
--	
--	if isdate(@DateEnd) != 1 begin
--		set @DateEnd = convert(varchar(10), getdate(), 121)
--	end
	
    DELETE FROM [iReport_Call_LostTotal] WHERE UserID=@UserID 

    SET @strSql = 'INSERT INTO [iReport_Call_LostTotal]
           ([UserID]
           ,[segment]
           ,[CalledNew]
           ,[abandonTotal]
           ,[fifLoss]
           ,[thirtyLoss]
           ,[sixLoss]
           ,[eightLoss]
           ,[overEightLoss])'

    select @Called=isnull(@Called,'')

	SET @strSql = @strSql + 'select '''+@UserID+''','''+ @DateBegin + '～' + @DateEnd +''' as segment, calledNew,' 

	SET @strSql = @strSql
		+ ' count( case when (contactDisposition=1) then 1 end) as abandonTotal,
			count ( case when (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 15 and contactDisposition=1)  then 1 end ) as fifLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 16  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 30 ) and contactDisposition=1 )then 1 end ) as thirtyLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 31  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 60 ) and contactDisposition=1 )then 1 end ) as sixLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 61  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 180 ) and contactDisposition=1 )then 1 end ) as eightLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   > 180 and contactDisposition=1  )then 1 end ) as overEightLoss  
		from (
			select m.* '
			
	if (len(@Called) > 0 ) 
      begin
		SET @strSql = @strSql + ' ,(case when  (len(m.called) >=13 and SUBSTRING(m.called,1,3) = ''901''  )
				then SUBSTRING(m.called,3,11) 
				 when  (len(m.called) >=13 and SUBSTRING(m.called,1,3) = ''900''  )
				then SUBSTRING(m.called,3,len(m.called)-2) 
				when (len(m.called) >=10 and SUBSTRING(m.called,1,2) = ''91'' )
				then  SUBSTRING(m.called,2,11) 
				when (len(m.called) >=5 and SUBSTRING(m.called,1,1) = ''9'' )
				then  SUBSTRING(m.called,2,len(m.called)-1) 
				else m.called end) calledNew '
	 end
    else
      begin
         SET @strSql = @strSql +',m.called as calledNew '
      end
	
	SET @strSql = @strSql + ' from (
			select	m.startDateTime, 
					CONVERT(varchar(10), m.startDateTime, 23) as sTime,
					--CONVERT(varchar(4), m.startDateTime, 23) as sYear		,
					--CONVERT(varchar(7), m.startDateTime, 23) as sMonth,
					--dbo.week_series_to_str(m.startDateTime,0) as sWeek,
					--(select segment  from dbo.V_Timesegment vt where CONVERT(varchar(12), m.startDateTime, 108) between vt.sBegin and vt.sEnd) as segment,
					(case when m.connectTime>0 then m.contactDisposition else 1 end ) as contactDisposition,
					(select top 1 queuetime from ContactQueueDetail s 
											where s.sessionID = m.sessionID  and s.nodeID = m.nodeID
												and s.profileID = m.profileID and s.sessionSeqNum = 0) as queuetime,
					(select top 1 ringtime  from AgentConnectionDetail s 
											where s.sessionID = m.sessionID  and s.nodeID = m.nodeID
												and s.profileID = m.profileID and s.sessionSeqNum = 0) as ringtime ,'
												
	if (len(@Called) > 0 ) 
     begin
		SET @strSql = @strSql + ' isnull(rtrim(ltrim((case when (contactType = 1  and originatorType = 3 ) then 					
						isnull((select top 1 r.extension from AgentConnectionDetail s ,dbo.Resource r
											where s.sessionID = m.sessionID  and s.nodeID = m.nodeID
												and s.profileID = m.profileID and s.sessionSeqNum = 0
												and s.resourceID = r.resourceID  and s.profileID = r.profileID
						) ,destinationDN) else REPLACE(m.calledNumber, ''#'', '''') end))),'''') as called ,'
	 end
    else
     begin
       SET @strSql = @strSql +'''All'' as called ,'
     end
	
	SET @strSql = @strSql + ' connectTime
			from ContactCallDetail m
			where  ( (contactType = 1  and originatorType = 3 )
					   or  (m.originatorType = 1  and m.contacttype = 2  and m.destinationType = 3  ) 
					) and sessionSeqNum = 0
			) m where sTime BETWEEN ''' + @DateBegin  + ''' And ''' + @DateEnd  + ''' ) m'
			
	if (len(@Called) > 0 ) begin
		SET @strSql = @strSql + ' group by calledNew having calledNew = ''' + @Called + ''''
	end
    else
    begin
        SET @strSql = @strSql + ' group by calledNew having calledNew = ''All'''
    end 

	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_loss_total] error '  
	INSERT INTO [iReport_Call_LostTotal]
           ([UserID]
           ,[segment]
           ,[CalledNew]
           ,[abandonTotal]
           ,[fifLoss]
           ,[thirtyLoss]
           ,[sixLoss]
           ,[eightLoss]
           ,[overEightLoss])
     VALUES
           (@UserID
           ,@DateBegin + '～' + @DateEnd
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--')
--	 SELECT segment = NULL, abandonTotal = NULL, fifLoss = NULL, 
--		thirtyLoss = NULL, sixLoss = NULL, eightLoss = NULL, overEightLoss = NULL,maxLoss=NULL,
--		calledNew = NULL
	RETURN -1;  
END




GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_call_outbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	呼出明细报表
/*
Example:
exec [sp_call_outbound] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@Agent='',@CallResult=''
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_call_outbound]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Agent		NVARCHAR(30)	= NULL,
	@CallResult NVARCHAR(30)	= NULL,
    @UserID     NVARCHAR(30)	= NULL
AS 
BEGIN
	declare @DT_Begin			datetime,
			@DT_End				datetime,
			@strSql				NVARCHAR(MAX)
			
--	if isdate(@DateBegin) != 1  begin
--		set @DateBegin = convert(varchar(10), getdate(), 121)
--	end
--	
--	if isdate(@DateEnd) != 1 begin
--		set @DateEnd = convert(varchar(10), getdate(), 121)
--	end

	--select @DT_Begin = @DateBegin + ' 00:00:00',
		   --@DT_End   = @DateEnd   + ' 23:59:59'
	IF (@CallResult='全部')  
    BEGIN SET @CallResult='-1' END
    ELSE IF (@CallResult='成功') BEGIN SET @CallResult='1' END
    ELSE IF (@CallResult='失败') BEGIN SET @CallResult='0' END
    ELSE BEGIN SET @CallResult='-1' END 

    DELETE FROM [iReport_Call_Outbound] WHERE [UserID]=@UserID

	SET @strSql = 'select '''+ @UserID +''', r.resourceName+''('' + r.resourceLoginId + '')'' as agent,
		convert(varchar(20), m.startDateTime, 120) as recordTime,m.calledNumber as called,m.connecttime as totalTime,
		(case when m.connectTime>0 then ''成功'' else ''失败'' end ) callresult
		from dbo.ContactCallDetail m ,dbo.Resource r
		where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1 and m.contacttype = 2 and m.destinationType = 3 '	
		+ ' and convert(varchar(10), m.startDateTime, 23) BETWEEN ''' + @DateBegin + ''' And ''' + @DateEnd + ''''
	
	IF LEN(@Agent) > 0     set  @strSql = @strSql + ' and r.resourceLoginId = ''' + @Agent + ''''
	
	IF (@CallResult = '1')  set  @strSql = @strSql + ' and m.connectTime > 0 '
	
	IF (@CallResult = '0')  set  @strSql = @strSql + ' and m.connectTime = 0 '
	
    SET @strSql = 'INSERT INTO [iReport_Call_Outbound]
				   ([UserID]
				   ,[Agent]
				   ,[RecordDateTime]
				   ,[CalledID]
				   ,[CallTotalTime]
				   ,[CallResult]) ' + @strSql
	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_outbound] error '  
--	 SELECT agent = NULL, agentName = NULL, recordTime = NULL, called = NULL, 
--		totalTime = NULL, callResult = NULL
    INSERT INTO [iReport_Call_Outbound]
           ([UserID]
           ,[Agent]
           ,[RecordDateTime]
           ,[CalledID]
           ,[CallTotalTime]
           ,[CallResult])
     VALUES
           (@UserID
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--')

	RETURN -1;  
END




GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_call_time_analysis]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.18>
-- Description:	呼叫时长分析统计
/*
Example:
exec sp_call_time_analysis @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14'
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_call_time_analysis]
	@DateBegin	NVARCHAR(50)	= NULL,
	@DateEnd	NVARCHAR(50)	= NULL,
    @UserID     NVARCHAR(50)	= NULL 
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
			
--	if isdate(@DateBegin) != 1  begin
--		set @DateBegin = convert(varchar(10), getdate(), 121)
--	end
--	
--	if isdate(@DateEnd) != 1 begin
--		set @DateEnd = convert(varchar(10), getdate(), 121)
--	end

	DELETE FROM [iReport_CallTime_Analysis] WHERE UserID = @UserID

	SET @strSql = 'INSERT INTO [iReport_CallTime_Analysis]
           ([UserID]
           ,[Segment]
           ,[TotalAnswer]
           ,[FifWaitTime]
           ,[ThirtyWaitTime]
           ,[SixWaitTime]
           ,[EightWaitTime]
           ,[OverEightWatiTime]
           ,[MaxWaitTime])'

	SET @strSql = @strSql + 'select '''+@UserID+''', '''+ @DateBegin + '～' + @DateEnd +''' as segment,' 
		+ ' count ( case contactDisposition when 2 then 1 end ) as answerTotal,
			count ( case when (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 15 )  then 1 end ) as fifWaitTime ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 16  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 30 )  )then 1 end ) as thirtyWaitTime ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 31  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 60 )  )then 1 end ) as sixWaitTime ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 61  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 180 )  )then 1 end ) as eightWaitTime ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   > 180   )then 1 end ) as overEightWaitTime ,
			dbo.sec_to_time(( select max(ISNULL(queuetime,0)+ISNULL(ringtime,0)) from  [V_CallInbound] where sTime BETWEEN ''' + @DateBegin  + ''' And ''' + @DateEnd  + '''  and contactDisposition=2)) as maxWaitTime
		from  [V_CallInbound] where sTime BETWEEN ''' + @DateBegin  + ''' And ''' + @DateEnd  + '''  and contactDisposition=2 '
	
    PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_time_analysis] error '  
	INSERT INTO [rep_uccx].[dbo].[iReport_CallTime_Analysis]
           ([UserID]
           ,[Segment]
           ,[TotalAnswer]
           ,[FifWaitTime]
           ,[ThirtyWaitTime]
           ,[SixWaitTime]
           ,[EightWaitTime]
           ,[OverEightWatiTime]
           ,[MaxWaitTime])
     VALUES
           (@UserID
           ,@DateBegin + '～' + @DateEnd
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--'
           ,'--')

--	 SELECT segment = NULL, answerTotal = NULL, waitTimeTotal = NULL, fifWaitTime = NULL, 
--		thirtyWaitTime = NULL, sixWaitTime = NULL, eightWaitTime = NULL, overEightWaitTime = NULL,maxWaitTime=NULL
	RETURN -1;  
END


GO
/****** Object:  StoredProcedure [dbo].[iReport_sp_service_operation_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.07.05>
-- Description:	服务台运行统计报表
/*
Example:
exec [sp_service_operation_total] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[iReport_sp_service_operation_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
    @UserID     NVARCHAR(50)	= NULL
	--,@IsNeedTotal SMALLINT = NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	declare @tempCount			int
			
--	if isdate(@DateBegin) != 1  begin
--		set @DateBegin = convert(varchar(10), getdate(), 121)
--	end
--	
--	if isdate(@DateEnd) != 1 begin
--		set @DateEnd = convert(varchar(10), getdate(), 121)
--	end

    DELETE FROM [iReport_Se_Op_Total] WHERE [UserID]=@UserID
	
	create table #T_ServiceOperationTotal(
	
		period					varchar(30),	--周期
		segment					varchar(20),	--时间段
		beginTime				datetime	,	--start
		endTime					datetime	--,	--end time segment
		/*
		inboundTotal			int	,			--总进线量	总进线量=到达坐席数+IVR呼损数
		ivrLossTotal			int,			--IVR呼损数	还没分配到坐席就挂断的呼入数
		toAgentTotal			int,			--到达坐席量	已经分配到坐席的呼入数
		agentAnswerTotal		int,			--坐席应答电话量	
		agentAnswerRate			varchar(20),	--坐席应答率	
		holdDuration			int,			--保持/咨询时长	
		holdFrequency			int,			--保持/咨询次数	
		avgHoldDuration			float,			--保持/咨询平均时长	
		maxQueueTime			int,			--最大排队时长	
		avgQueueTime			float,			--平均排队时长	
		avgRingTime				float,			--平均振铃时长	
		readyNumber				int,			--阶段坐席就绪人数	
		loginDurationTotal		int,			--总登录时长	
		--agentNumber				int,			--坐席数	
		avgInboundTalkDuration	float,			--平均呼入通话时长	
		avgAcwDuration			float,			--平均呼入话后整理时长	
		inboundAHT				float,			--平均呼入处理时长	
		agentOutboundTotal		int,			--客服呼出量	
		outboundAvgTalkDuration	float,			--平均呼出通话时长	
		outboundAvgACWDuration	int,			--平均呼出话后整理时长		
		outboundAgentNumber		int,			--坐席外呼人数	
		outboundDurationTotal	int,			--坐席外呼时长
		
		notready1Number	        int, --会议人数 
		notready1Duration       int, --会议时长 
		notready2Number	        int, --小休人数 
		notready2Duration       int, --小休时长 
		notready3Number		    int, --用餐人数 
		notready3Duration       int, --用餐时长
		notready4Number	        int, --洗手人数 
		notready4Duration       int, --洗手时长 

		workFormTotal			int,			--工单总数	当前时间坐席所创建的工单数量
		firstSolveRate			varchar(10),	--一线解决率	坐席自行处理的工单数/工单总数量
		secondSolveRate			varchar(10)	--二线解决率	工单总数量减去坐席自行处理的工单数后再除以工单总数量
		
		*/
		,row_num int
	)
	
	set @strSql = ' insert into #T_ServiceOperationTotal '
	declare @date1 datetime,@date2 datetime
	set @date1 = @DateBegin
	set @date2 = @DateEnd
	
	create table #temp_periodS (period varchar(20),beginTime datetime,endTime datetime)
	
	--周期特性 小时
	if ( lower(@GroupLevel) = 'hour' ) begin 
		ALTER TABLE #temp_periodS ADD segment varchar(20)
		insert into #temp_periodS 
			select  period, CONVERT(datetime,period + ' ' + sBegin + '.000', 120) as beginTime, CONVERT(datetime,period + ' ' + sEnd + '.998', 120)  as endTime,segment
			from (
				select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m , dbo.V_TimeSegment t
			
		set @strSql = @strSql + ' (period,beginTime,endTime,segment,row_num) SELECT top 2000 p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		insert into #temp_periodS 
			select  convert(varchar(7),dateadd(mm,number,@date1),120) as period,
				dateadd(ss,0,dateadd(mm,number,@date1)) as beginTime,dateadd(ss,-1,dateadd(mm,number+1,@date1)) as  endTime
			from master..spt_values where type='p' and number <= datediff(mm,@date1,@date2)
		
		update #temp_periodS	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_periodS) 	
		update #temp_periodS	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_periodS) 
		--select * from #temp_periodS
		set @strSql = @strSql + ' (period,beginTime,endTime,row_num) SELECT p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		insert into #temp_periodS 

			select distinct dbo.week_series_to_str(dateadd(dd,number,@date1),0) as period,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ),112) as starttime,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ) + ' 23:59:59',120) +6 as endtime
			 from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			 
		update #temp_periodS	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_periodS) 	
		update #temp_periodS	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_periodS) 
		--select * from #temp_periodS
		
		set @strSql = @strSql + ' (period,beginTime,endTime,row_num) SELECT top 2000 p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		insert into #temp_periodS 
			select period, CONVERT(datetime,period + '-01-01 00:00:00', 120) as beginTime, CONVERT(datetime,period + '-12-31 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(4),dateadd(yy,number,@date1),120) from master..spt_values where type='p' and number <= datediff(yy,@date1,@date2)
			) m
		--更新开始时间 结束时间
		update #temp_periodS	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_periodS) 	
		update #temp_periodS	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_periodS) 
		
		--select * from #temp_periodS
		set @strSql = @strSql +  ' (period,beginTime,endTime,row_num) SELECT p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	--周期特性 日
	else begin 
		insert into #temp_periodS 
			select period, CONVERT(datetime,period + ' 00:00:00', 120) as beginTime, CONVERT(datetime,period + ' 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m
		
		set @strSql = @strSql +  ' (period,beginTime,endTime,row_num) SELECT top 1000 p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	EXECUTE(@strSQL)
	
	
	
	--select @tempCount = isnull(count(*),0) from #T_ServiceOperationTotal
	
	declare @tempMinStartTime 	datetime 
	declare @tempMaxEndTime 	datetime
		
	select @tempMinStartTime = min(beginTime) from #T_ServiceOperationTotal
	select @tempMaxEndTime	 = max(endTime)   from #T_ServiceOperationTotal
	
	--select * from #T_ServiceOperationTotal
	/*
	if ( lower(@GroupLevel) = 'hour' ) begin
		select period,segment,agent ,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_ServiceOperationTotal
	end
	else begin
		select period,agent,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_ServiceOperationTotal
	end
	*/

	;with a as (
	select 
		t.period,t.segment,t.beginTime,t.endTime,t.row_num,
		count(t.row_num) as inboundTotal,
		count ( case when (ringtime <=0 and contactDisposition=1) then 1 end ) as ivrLossTotal,
		count ( case when (ringtime >0 ) then 1 end ) as toAgentTotal,
		count ( case when contactDisposition =2 then 1 end ) as agentAnswerTotal,
		dbo.avg_str(count ( case when contactDisposition =2 then 1 end ),count ( case when (ringtime >0 ) then 1 end ),1) agentAnswerRate,
		dbo.sec_to_time(sum(isnull(holdtime,0))) as holdDuration,
		count ( case when (holdtime >0 ) then 1 end ) as holdFrequency,
		dbo.sec_to_time(cast ( dbo.avg_str(sum(isnull(holdtime,0)),count ( case when (holdtime >0 ) then 1 end ),0) as float ) ) as avgHoldDuration,
		max(queueTime) as maxQueueTime,
		dbo.avg_str(sum(isnull(queueTime,0)),count ( case when (queueTime >0 ) then 1 end ),0) as avgQueueTime,
		dbo.avg_str(sum(isnull(ringTime,0)), count ( case when (ringtime  >0 ) then 1 end ) ,0) as avgRingTime,
		dbo.sec_to_time( cast (dbo.avg_str(sum(isnull(talkTime,0)),count ( case when contactDisposition =2 then 1 end ),0) as float) ) as avgInboundTalkDuration,
		dbo.sec_to_time( cast (dbo.avg_str(sum(isnull(workTime,0)),count ( case when contactDisposition =2 then 1 end ),0) as float) ) as avgAcwDuration,
		dbo.sec_to_time( cast (dbo.avg_str(sum(isnull(ringTime,0)) + sum(isnull(talkTime,0)) + sum(isnull(workTime,0)),count ( case when contactDisposition =2 then 1 end ),0) as float) ) as inboundAHT
	from #T_ServiceOperationTotal t,V_CallInbound t2
	where t2.startDateTime BETWEEN t.beginTime And t.endTime 
	group by t.row_num,t.period,t.segment,t.beginTime,t.endTime
	
	),b as (
		select 
			t.row_num,
			count(t.row_num) as agentOutboundTotal,
			dbo.sec_to_time( cast (dbo.avg_str(sum(connectTime),count(t.row_num),0) as float) ) as outboundAvgTalkDuration,
			dbo.sec_to_time( cast (dbo.avg_str(sum(worktime),count(t.row_num),0) as float) ) as outboundAvgACWDuration,
			dbo.sec_to_time(sum(connectTime)) as outboundDurationTotal,
			count(distinct agent) as outboundAgentNumber
			
		from  #T_ServiceOperationTotal t,V_CallOutbound t2
		where t2.startDateTime BETWEEN t.beginTime And t.endTime 
		group by t.row_num,t.period,t.segment,t.beginTime,t.endTime
	), asd as (
		select eventtype,eventdatetime,reasoncode,t.resourceLoginID agent,a.profileID from dbo.AgentStateDetail a , dbo.Resource t where t.resourceID=a.agentID and a.profileID = t.profileID
		and a.eventDateTime between @tempMinStartTime and dateadd(day,1,@tempMaxEndTime )
	), f as (
		select  agent, eventtype,eventDateTime,reasonCode
		,( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime  order by eventDateTime) nextTime
		--,(case when eventtype=1 then (( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime and b.eventtype=7  order by eventDateTime) ) else NULL end) nextLogTime
		from asd a 
	), g as (
		
		select  f.agent,t.row_num,
			  sum(case 
			when (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(ms,t.beginTime,f.nextTime)
			when (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(ms,f.eventDateTime,t.endTime)
			when (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(ms,f.eventDateTime,f.nextTime)
			when (f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(ms,t.beginTime,t.endTime)
			else 0 end ) as loginduration ,
		count(case  when (f.eventtype=3 ) then 1   end ) as readyNumber,
		sum(case 
			when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
			when (f.eventtype=2 and f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
			when (f.eventtype=2 and f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
			when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
			else 0 end ) as ACWDuration,	
		count(case  when (f.eventtype=2 ) then 1   end ) as ACW

		from f,#T_ServiceOperationTotal t
		
		where ( (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime) or
		  (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime) or
		  (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) or
		  (f.eventDateTime < t.beginTime and f.nextTime > t.endTime) )

		group by f.agent,t.row_num,t.period,t.segment,t.beginTime,t.endTime
		
	) , c as (
		select row_num,dbo.sec_to_time(sum(loginDuration/1000)) as loginDurationTotal,
					count( case when readyNumber>0 then 1 end) as readyNumber,
					count( case when ACW>0 then 1 end) as ACW,
					dbo.sec_to_time(sum(ACWDuration)) as ACWDuration
		from g group by row_num
	)
	 

	INSERT INTO [iReport_Se_Op_Total]
           ([UserID]
           ,[period]
           ,[segment]
           ,[beginTime]
           ,[endTime]
           ,[inboundTotal]
           ,[ivrLossTotal]
           ,[toAgentTotal]
           ,[agentAnswerTotal]
           ,[agentAnswerRate]
           ,[holdDuration]
           ,[holdFrequency]
           ,[avgHoldDuration]
           ,[maxQueueTime]
           ,[avgQueueTime]
           ,[avgRingTime]
           ,[avgInboundTalkDuration]
           ,[avgAcwDuration]
           ,[inboundAHT]
           ,[agentOutboundTotal]
           ,[outboundAvgTalkDuration]
           ,[outboundAvgACWDuration]
           ,[outboundDurationTotal]
           ,[outboundAgentNumber]
           ,[loginDurationTotal]
           ,[readyNumber]
           ,[acw]
           ,[acwDuration]
           ,[workFormTotal]
           ,[firstSolveRate]
           ,[secondSolveRate])
	select
        @UserID, 
		t.period,t.segment,convert(varchar(20),t.beginTime,120),convert(varchar(20),t.endTime,120),
		t.inboundTotal,t.ivrLossTotal,t.toAgentTotal,t.agentAnswerTotal,
		t.agentAnswerRate,
		t.holdDuration,
		t.holdFrequency,
		t.avgHoldDuration,
		t.maxQueueTime,
		t.avgQueueTime,
		t.avgRingTime,
		t.avgInboundTalkDuration,
		t.avgAcwDuration,
		t.inboundAHT,
		b.agentOutboundTotal,b.outboundAvgTalkDuration,
		b.outboundAvgACWDuration,b.outboundDurationTotal,b.outboundAgentNumber,
		c.loginDurationTotal,c.readyNumber,
		c.acw,
		c.acwDuration,
		NULL workFormTotal,NULL firstSolveRate,NULL secondSolveRate
	from a as t
	left join b on  t.row_num = b.row_num
	left join c on	c.row_num = t.row_num
	
	IF OBJECT_ID('tempdb..#temp_periodS') IS NOT NULL BEGIN
		DROP TABLE #temp_periodS
		PRINT 'delete temp table #temp_periodS'
	END
	
	/*
	IF OBJECT_ID('tempdb..#T_ServiceAgent') IS NOT NULL BEGIN
		DROP TABLE #T_ServiceAgent
		PRINT 'delete temp table #T_ServiceAgent'
	END
	*/
	
	IF OBJECT_ID('tempdb..#T_ServiceOperationTotal') IS NOT NULL BEGIN
		DROP TABLE #T_ServiceOperationTotal
		PRINT 'delete temp table #T_ServiceOperationTotal'
	END
	
	return @@rowcount
END






GO
/****** Object:  StoredProcedure [dbo].[Resource_sync]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Resource_sync]
AS
DECLARE @DBLink VARCHAR(20)
DECLARE @SqlStr VARCHAR(2000)
BEGIN
SELECT @DBLink = Server FROM rep_uccx.dbo.Link_Table
DELETE FROM rep_uccx.dbo.Resource 
SET @SqlStr = '
 INSERT INTO rep_uccx.dbo.Resource
 select * from ' + @DBLink + '.db_cra.dbo.Resource
 '
--PRINT @@SqlStr 
EXEC (@SqlStr)
END

GO
/****** Object:  StoredProcedure [dbo].[RG_sync]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[RG_sync]--- 同步db_cra内的resourcegroup
AS
DECLARE @DBLink VARCHAR(20)
DECLARE @SqlStr VARCHAR(4000)
BEGIN
SELECT @DBLink = Server FROM rep_uccx.dbo.Link_Table
DELETE FROM rep_uccx.dbo.resourceGroup
SET @SqlStr = '
 insert into resourceGroup
	 select [resourceGroupID]
      ,[profileID]
      ,[resourceGroupName]
      ,[active]
      ,[dateInactive] 
     from ' + @DBLink + '.db_cra.informix.resourceGroup m
	 where not exists(select 1 from resourceGroup s 
						where m.resourceGroupID = s.resourceGroupID
							and m.profileID = s.profileID)
 '
--PRINT @SqlStr 
EXEC (@SqlStr)
END


GO
/****** Object:  StoredProcedure [dbo].[sp_agent_state_sequence]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ===============================================
-- Author:		<yibin.wu@vxichina.com>
-- Create date: <2014.1.9>
-- Description:	坐席工作状态序列(uccx)
/*
Example:
exec [sp_agent_state_sequence] 
			@datebegin='20121024'
			,@dateend='20121025'
			,@timebegin='0'
			,@timeend='235959'
			,@agent='1002'
			,@ux_event=7
*/
-- ===============================================
CREATE PROCEDURE [dbo].[sp_agent_state_sequence]
	@datebegin	int			= null,
	@dateend	int			= null,
	@timebegin	int			= 0,
	@timeend	int			= 235959,
	@agent		varchar(200)= null,
	@ux_event	smallint	= null	--坐席状态[1-logged-in;2-not ready;3-ready;4-reserved;5-talking;6-work;7-logout]
AS 
BEGIN

	declare @f_begindate	datetime,
			@f_enddate		datetime
			
	set @agent = isnull(rtrim(@agent), '')
	set @ux_event = isnull(@ux_event, 0)

	if isdate(@datebegin) != 1  begin
		set @datebegin = convert(varchar(8), getdate(), 112)
	end
	
	if isdate(@dateend) != 1 begin
		set @dateend = convert(varchar(8), getdate(), 112)
	end
	
	if @timebegin is null set @timebegin = 0
	if @timeend is null set @timeend = 235959
	
	select @f_begindate = convert(varchar(8),@datebegin) + ' 00:00:00.000',
			@f_enddate = convert(varchar(8),@dateend) + ' 23:59:59.997'

	create table #t_asd(agent varchar(20),eventdatetime datetime,eventtime int,eventtype tinyint,rownum int,statusinterval int)
	create index #ix_t_asd on #t_asd(agent,eventdatetime)
	
	;with cte as(
		select agent = r.resourceloginid,
				eventdatetime,
				eventtime = datepart(hour, eventdatetime) * 10000 
							+ datepart(minute, eventdatetime) * 100 
							+ datepart(second, eventdatetime),
				eventtype,
				rownum = row_number() over(partition by ad.agentid order by ad.eventdatetime)
			from agentstatedetail ad
				left join resource r on r.resourceid = ad.agentid and r.profileid = ad.profileid
			where ad.eventdatetime between @f_begindate and @f_enddate
				and (@agent = '' or charindex(','+convert(varchar,r.resourceloginid)+',',','+@agent+',') > 0)
				and (@ux_event = 0 or ad.eventtype = @ux_event)
	)
	insert into #t_asd(agent,eventdatetime,eventtype,rownum)
		select agent,eventdatetime,eventtype,rownum 
			from cte
			where eventtime >= case when @timebegin > 0 then @timebegin else eventtime end
				and eventtime <= case when @timeend < 235959 then @timeend else eventtime end
		
	update t1 set statusinterval = datediff(s,t1.eventdatetime,t2.eventdatetime)
		from #t_asd t1, #t_asd t2
		where t1.agent = t2.agent
			and t2.rownum - t1.rownum = 1
	
	select agent,
			starttime = eventdatetime,
			ux_event = eventtype,
			statusinterval
		from #t_asd
		order by agent,eventdatetime
	
	if OBJECT_ID('tempdb..#t_asd') IS NOT NULL begin
		truncate table #t_asd
		drop table #t_asd
		print 'delete temp table #t_asd'
	end
END




GO
/****** Object:  StoredProcedure [dbo].[sp_agent_work_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.07.04>
-- Description:	坐席工作统计报表
/*
Example:
exec [sp_agent_work_total] @DateBegin='2014-01-02'
					,@DateEnd='2014-01-07'
					,@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_agent_work_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Agent		NVARCHAR(50)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
	@IsNeedTotal SMALLINT = NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	declare @tempCount			int
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end
	
	create table #T_AgentWorkTotal(
		period					varchar(30),	--周期
		segment					varchar(20),	--时间段
		beginTime				datetime	,	--start
		endTime					datetime	,	--end time segment
		
		agent					varchar(50),	--坐席工号	
		agentName				varchar(50)	--坐席名称	
		--,loginDuration			int,			--总登录时长	该坐席的总登录时长
		--answer					int ,			--坐席应答电话量	呼入该坐席的坐席应答数
		--abandon					int ,			--放弃呼叫数	呼入该坐席的放弃呼叫数
		--transfer				int ,			--转接呼叫数	针对该坐席的转接数
		--avgInboundDuration		int ,			--呼入平均时长	呼入该坐席的总时长/呼入该坐席的总呼入数
		--inboundTotalDuration	int,			--呼入总时长	呼入该坐席的总时长
		--fifteenAnswerRate		varchar(10) ,	--15秒内应答率	呼入坐席在15秒振铃时长内的应答数/总呼应答数
		
		--outboundTotal			int ,			--呼出数	坐席的呼出数
		--avgOutboundDuration		float,			--平均呼出通话时长	坐席呼出有应答的通话时长
		--outboundTotalDuration	int,			--呼出总时长	坐席呼出的总时长
		
		--readyDuration			int,			--就绪时长	坐席就绪状态的时长
		--inboundTalkDuration	    int,			--呼入通话时长	呼入时该坐席的应答时长
		--notready1Duration		int,			--用餐时长	用户置忙状态的用餐时长
		--notready2Duration		int,			--会议时长	用户置忙状态的会议时长
		--notready3Frequency		int,			--培训次数	
		--notready3Duration		int,			--培训时长	用户置忙状态的培训时长
		--notready4Frequency		int,			--休息次数	
		--notready4Duration		int,			--休息时长	

		--workFormTotal			int,			--工单总数	当前时间坐席所创建的工单数量
		--firstSolveRate			varchar(10),	--一线解决率	坐席自行处理的工单数/工单总数量
		--secondSolveRate			varchar(10),	--二线解决率	工单总数量减去坐席自行处理的工单数后再除以工单总数量
		--speedAnswerRate			varchar(10)		--快速应答率	15秒内应答数除以总应答数
	)
	
	set @strSql = ' insert into #T_AgentWorkTotal '
	declare @date1 datetime,@date2 datetime
	set @date1 = @DateBegin
	set @date2 = @DateEnd
	
	create table #temp_period (period varchar(20),beginTime datetime,endTime datetime)
	
	--周期特性 小时
	if ( lower(@GroupLevel) = 'hour' ) begin 
		--ALTER TABLE #temp_period ADD segment varchar(20)
		insert into #temp_period 
			select  period, CONVERT(datetime,period + ' ' + sBegin + '.000', 120) as beginTime, CONVERT(datetime,period + ' ' + sEnd + '.998', 120)  as endTime --,segment
			from (
				select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m , dbo.V_TimeSegment t
			
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
       	--print @strsql	
end

	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		insert into #temp_period 
			select  convert(varchar(7),dateadd(mm,number,@date1),120) as period,
				dateadd(ss,0,dateadd(mm,number,@date1)) as beginTime,dateadd(ss,-1,dateadd(mm,number+1,@date1)) as  endTime
			from master..spt_values where type='p' and number <= datediff(mm,@date1,@date2)
		
		update #temp_period	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_period) 	
		update #temp_period	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_period) 
		--select * from #temp_period
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		insert into #temp_period 

			select distinct dbo.week_series_to_str(dateadd(dd,number,@date1),0) as period,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ),112) as starttime,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ) + ' 23:59:59',120) +6 as endtime
			 from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			 
		update #temp_period	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_period) 	
		update #temp_period	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_period) 
		--select * from #temp_period
		
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		insert into #temp_period 
			select period, CONVERT(datetime,period + '-01-01 00:00:00', 120) as beginTime, CONVERT(datetime,period + '-12-31 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(4),dateadd(yy,number,@date1),120) from master..spt_values where type='p' and number <= datediff(yy,@date1,@date2)
			) m
		--更新开始时间 结束时间
		update #temp_period	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_period) 	
		update #temp_period	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_period) 
		
		--select * from #temp_period
		set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	--周期特性 日
	else begin 
		insert into #temp_period 
			select period, CONVERT(datetime,period + ' 00:00:00', 120) as beginTime, CONVERT(datetime,period + ' 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m
		
		set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT * FROM [dbo].[V_Agent] a,#temp_period p '
	end
	
	if (len(@agent) > 0) set @strSql = @strSql + ' where agent = ''' + @agent + ''''
	
	print @strSQL
	
	EXECUTE(@strSQL)
	
	/*

	select @tempCount = count(*) from #T_AgentWorkTotal
		
	--判断有数据 计算 登陆时长

	if (@tempCount > 0 ) begin
	
		declare @tempAgent			nvarchar(50)
		declare @tempStartTime		datetime
		declare @tempEndTime		datetime
		declare @tempDuration		int
		
		declare @tempreadyDuration int
		declare @tempnotready1Duration		int			--用餐时长	用户置忙状态的用餐时长
		declare @tempnotready2Duration		int			--会议时长	用户置忙状态的会议时长
		declare @tempnotready3Duration		int			--培训时长	用户置忙状态的培训时长
		declare @tempnotready4Duration		int			--休息时长	

	   DECLARE tracetime CURSOR FOR
	   select agent,beginTime,endTime from #T_AgentWorkTotal
	   OPEN tracetime
	   FETCH NEXT FROM tracetime INTO @tempAgent,@tempStartTime,@tempEndTime
			WHILE (@@FETCH_STATUS=0)
			BEGIN
			--1 平均时长 2放弃数 3应答数 4转移数 其他 总时长
				--计算时长  
			   exec @tempDuration  = dbo.sp_sum_login_time	    @tempStartTime,@tempEndTime,@tempAgent

			   --ready duration

			   exec @tempreadyDuration = dbo.sp_sum_ready_time	    @tempStartTime,@tempEndTime,@tempAgent,'0'
			   --notready duration
			   /*exec @tempnotready1Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,1,'0'
			   exec @tempnotready2Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,2,'0'
			   exec @tempnotready3Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,3,'0'
			   exec @tempnotready4Duration  = dbo.sp_sum_notready_time	  @tempStartTime,@tempEndTime,@tempAgent,4,'0'
				*/

			   update #T_AgentWorkTotal set loginDuration= @tempDuration,
						readyDuration=@tempreadyDuration,
						notready1Duration=@tempnotready1Duration,
						notready2Duration=@tempnotready2Duration,
						notready3Duration=@tempnotready3Duration,
						notready4Duration=@tempnotready4Duration
						
			    where agent = @tempAgent and beginTime = @tempStartTime and endTime = @tempEndTime

			FETCH NEXT FROM tracetime INTO @tempAgent,@tempStartTime,@tempEndTime
			END
		CLOSE tracetime
		DEALLOCATE tracetime    
	
	end
	*/
	
	/*
	if ( lower(@GroupLevel) = 'hour' ) begin
		select period,segment,agent ,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_AgentWorkTotal
	end
	else begin
		select period,agent,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_AgentWorkTotal
	end
	*/
	declare @tempMinStartTime 	datetime 
	declare @tempMaxEndTime 	datetime
		
	select @tempMinStartTime = convert(datetime,@DateBegin,120) 
	select @tempMaxEndTime	 = convert(datetime,@DateEnd + ' 23:59:59.998',120) 

	
	;with b as (
			select m.transfer,m.contactDisposition as contactDisposition
			,(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
			,s.startdatetime,
			(datediff(s,s.startDateTime,s.endDateTime)) callDuration,
			s.ringtime,
			s.talktime
			from ContactCallDetail m , AgentConnectionDetail s
			where  s.sessionID = m.sessionID  and s.nodeID = m.nodeID
					and s.profileID = m.profileID and m.sessionSeqNum = 0
					and s.startDateTime between @tempMinStartTime and @tempMaxEndTime 
	) ,c as (		
		select r.resourceLoginId as agent ,
				m.startDateTime,
				m.connectTime
				from dbo.ContactCallDetail m ,dbo.Resource r	
		where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1
		 and m.contacttype = 2 and m.destinationType = 3  and
		 m.startDateTime between @tempMinStartTime and @tempMaxEndTime 
	) , d as (
		select t.agent,t.period,t.beginTime,t.EndTime, count(1) as outbound,sum(connectTime) outboundDuration 
		from c ,#T_AgentWorkTotal t where c.agent = t.agent and c.startdatetime between t.beginTime and t.endTime
		group by t.agent,t.period,t.beginTime,t.EndTime
	),e as (
	
	select  t.agent,t.agentName,t.period,t.beginTime,t.EndTime,
	
	sum(case when b.contactDisposition=1 then 1 else 0 end ) as abandon,
    sum(case when b.contactDisposition=2 then 1 else 0 end ) as answer,
    sum(cast(b.transfer as smallint) ) as transfer,
    avg(callDuration) as avgInboundDuration,
    sum(callDuration) as inboundTotalDuration,
    sum(case when b.contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
    sum(talktime) as inboundTalkDuration
    from #T_AgentWorkTotal t,b where 
	 b.agent = t.agent and (b.startdatetime between t.beginTime and t.endTime)
	group by t.agent,t.agentName,t.period,t.beginTime,t.EndTime
	
	), asd as (
		select eventtype,eventdatetime,reasoncode,t.resourceLoginID agent,a.profileID 
			from dbo.AgentStateDetail a , dbo.Resource t 
			where t.resourceID=a.agentID and a.profileID = t.profileID
		and a.eventDateTime between @tempMinStartTime and @tempMaxEndTime and eventtype<>7
	), f as (
		select  agent, eventtype,eventDateTime,reasonCode
		,( select top 1 eventDateTime from asd b 
			where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime  order by eventDateTime) nextTime
		--,(case when eventtype=1 then (( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime and b.eventtype=7  order by eventDateTime) ) else NULL end) nextLogTime
		from asd a
	), g as (
		
	select t.agent,t.period,t.beginTime,t.EndTime,
 
    sum(case when (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
			--when (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime) then  datediff(s,t.beginTime,f.nextTime) 
			--when (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime) then  datediff(s,f.eventDateTime,t.endTime)
			when (f.eventDateTime < t.beginTime and f.nextTime > t.endTime) then  datediff(s,t.beginTime,t.endTime)
			else 0 end) as loginduration,
	sum(case 
		--when (f.eventtype=3 and f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
		--when (f.eventtype=3 and f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
		when (f.eventtype=3 and f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
		when (f.eventtype=3 and f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
		else 0 end ) as readduration,
	sum(case 
		--when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
		--when (f.eventtype=2 and f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
		when (f.eventtype=2 and f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
		when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
		else 0 end ) as ACWDuration,	
	count(case  when (f.eventtype=2 ) then 1   end ) as ACW

    from f,#T_AgentWorkTotal t
		where f.agent = t.agent 
		and 
		( (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) or
		  (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime) or
		  (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime) or
		  (f.eventDateTime < t.beginTime and f.nextTime > t.endTime) )

	group by t.agent,t.period,t.beginTime,t.EndTime
	)
	 --select * from g
 
	select t.agent,
		--t.agentName+'(' + t.agent + ')' as agentName,
		t.period,t.beginTime,t.EndTime,
		substring (convert (varchar(20),t.beginTime,108),4,5) + '~' + substring (convert (varchar(20),t.endTime,108),4,5) segment,
		ISNULL(abandon,0) abandon,ISNULL(answer,0) answer,ISNULL(transfer,0) transfer,dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
		ISNULL(dbo.avg_str(fifAnser,answer,1),0) as fifteenAnswerRate,
	--	ISNULL(dbo.avg_str(fifAnser,answer,1),0) as speedAnswerRate,
		dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
		ISNULL( outbound,0)outbound,dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration   
		,acw,
		dbo.sec_to_time(isnull(g.loginduration,0)) loginDuration,
		dbo.sec_to_time(isnull(g.readduration,0)) readyDuration,
		dbo.sec_to_time(isnull(g.acwDuration,0)) acwDuration
	--	,NULL workFormTotal,
	--	NULL firstSolveRate,NULL secondSolveRate
		
		 from e as t
		left join d as c on  c.agent = t.agent and  c.beginTime = t.beginTime and c.EndTime = t.EndTime
		left join g      on  g.agent = t.agent and  g.beginTime = t.beginTime and g.EndTime = t.EndTime
 
	
	IF OBJECT_ID('tempdb..#temp_period') IS NOT NULL BEGIN
		DROP TABLE #temp_period
		PRINT 'delete temp table #temp_period'
	END
	
	IF OBJECT_ID('tempdb..#T_AgentWorkTotal') IS NOT NULL BEGIN
		DROP TABLE #T_AgentWorkTotal
		PRINT 'delete temp table #T_AgentWorkTotal'
	END
	return @@rowcount
END




GO
/****** Object:  StoredProcedure [dbo].[sp_agent_work_total_new]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2014.07.10>
-- Description:	坐席工作统计报表
/*
Example:
exec [sp_agent_work_total_new] @DateBegin='2012-08-01'
					,@DateEnd='2012-08-01',@GroupLevel= 'hour'
						,@Agent = '1039'
					,@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_agent_work_total_new]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Agent		NVARCHAR(50)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
	@IsNeedTotal SMALLINT = NULL
AS 
BEGIN

	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end
	
	
	
	declare @tempMinStartTime 	datetime 
	declare @tempMaxEndTime 	datetime
		
	select @tempMinStartTime = convert(datetime,@DateBegin,120) 
	select @tempMaxEndTime	 = convert(datetime,@DateEnd + ' 23:59:59.998',120) 

	--select * from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime 
	--select * from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime 

	if ( lower(@GroupLevel) = 'hour' ) begin 
       	if ( len(@Agent) > 0) begin
			;with a as (
					select  agent,sTime,segment,
					sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
					sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
					sum(cast(transfer as smallint) ) as transfer,
					avg(callDuration) as avgInboundDuration,
					sum(callDuration) as inboundTotalDuration,
					sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
					sum(talktime) as inboundTalkDuration
					from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
					group by agent,sTime,segment
			) , b as (
				select  agent,sTime,segment,
					count(1) as outbound,sum(connectTime) outboundDuration 
						from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
						group by agent,sTime,segment
			), c as (
				select  agent,sTime,segment,
					sum (
						case when eventtype = 1 then
							datediff(s,eventDateTime,(case when nextTime > dateadd(hour,1,convert(datetime,convert(varchar(13),eventDateTime,120)+':00:00',120)) then dateadd(hour,1,convert(datetime,convert(varchar(13),eventDateTime,120)+':00:00',120)) else nextTime end))
						else 0 end
					) loginduration,
					sum (
						case when eventtype = 3 then
							datediff(s,eventDateTime,(case when nextTime > dateadd(hour,1,convert(datetime,convert(varchar(13),eventDateTime,120)+':00:00',120)) then dateadd(hour,1,convert(datetime,convert(varchar(13),eventDateTime,120)+':00:00',120)) else nextTime end))
						else 0 end
					)	readduration,
					sum (
						case when eventtype = 6 then
							datediff(s,eventDateTime,(case when nextTime > dateadd(hour,1,convert(datetime,convert(varchar(13),eventDateTime,120)+':00:00',120)) then dateadd(hour,1,convert(datetime,convert(varchar(13),eventDateTime,120)+':00:00',120)) else nextTime end))
						else 0 end
					)	acwDuration,
					sum (
						case when eventtype = 6 then
							1
						else 0 end
					)	acw
				from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
				group by agent,sTime,segment
			)
				select	c.agent,
						c.sTime as period,c.segment,
						ISNULL(abandon,0) abandon,
						ISNULL(answer,0) answer,
						ISNULL(transfer,0) transfer,
						dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
						dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
						ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
						dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
						ISNULL( outbound,0)outbound,
						dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
						dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
						dbo.sec_to_time(isnull(readduration,0)) readyDuration,
						dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

			  from c
						left join a on a.agent = c.agent and a.sTime = c.sTime
						left join b on b.agent = c.agent and b.sTime = c.sTime
		end
		else begin
			;with a as (
						select  agent,sTime,segment,
						sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
						sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
						sum(cast(transfer as smallint) ) as transfer,
						avg(callDuration) as avgInboundDuration,
						sum(callDuration) as inboundTotalDuration,
						sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
						sum(talktime) as inboundTalkDuration
						from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
						group by agent,sTime,segment 
				) , b as (
					select  agent,sTime,segment,
						count(1) as outbound,sum(connectTime) outboundDuration 
							from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
							group by agent,sTime,segment
				), c as (
					select  agent,sTime,segment,
						sum (
							case when eventtype = 1 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						) loginduration,
						sum (
							case when eventtype = 3 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	readduration,
						sum (
							case when eventtype = 6 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	acwDuration,
						sum (
							case when eventtype = 6 then
								1
							else 0 end
						)	acw
					from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime 
					group by agent,sTime,segment
				)
					select	c.agent,
							c.sTime as period,c.segment,
							ISNULL(abandon,0) abandon,
							ISNULL(answer,0) answer,
							ISNULL(transfer,0) transfer,
							dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
							dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
							ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
							dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
							ISNULL( outbound,0)outbound,
							dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
							dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
							dbo.sec_to_time(isnull(readduration,0)) readyDuration,
							dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

				  from c
							left join a on a.agent = c.agent and a.sTime = c.sTime
							left join b on b.agent = c.agent and b.sTime = c.sTime
		end
	end
	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		if ( len(@Agent) > 0) begin
			;with a as (
					select  agent,sMonth,
					sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
					sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
					sum(cast(transfer as smallint) ) as transfer,
					avg(callDuration) as avgInboundDuration,
					sum(callDuration) as inboundTotalDuration,
					sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
					sum(talktime) as inboundTalkDuration
					from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
					group by agent,sMonth 
			) , b as (
				select  agent,sMonth,
					count(1) as outbound,sum(connectTime) outboundDuration 
						from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
						group by agent,sMonth
			), c as (
				select  agent,sMonth,
					sum (
						case when eventtype = 1 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					) loginduration,
					sum (
						case when eventtype = 3 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	readduration,
					sum (
						case when eventtype = 6 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	acwDuration,
					sum (
						case when eventtype = 6 then
							1
						else 0 end
					)	acw
				from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
				group by agent,sMonth
			)
				select	c.agent,
						c.sMonth as period,
						ISNULL(abandon,0) abandon,
						ISNULL(answer,0) answer,
						ISNULL(transfer,0) transfer,
						dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
						dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
						ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
						dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
						ISNULL( outbound,0)outbound,
						dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
						dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
						dbo.sec_to_time(isnull(readduration,0)) readyDuration,
						dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

			  from c
						left join a on a.agent = c.agent and a.sMonth = c.sMonth
						left join b on b.agent = c.agent and b.sMonth = c.sMonth
		end
		else begin
			;with a as (
						select  agent,sMonth,
						sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
						sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
						sum(cast(transfer as smallint) ) as transfer,
						avg(callDuration) as avgInboundDuration,
						sum(callDuration) as inboundTotalDuration,
						sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
						sum(talktime) as inboundTalkDuration
						from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
						group by agent,sMonth 
				) , b as (
					select  agent,sMonth,
						count(1) as outbound,sum(connectTime) outboundDuration 
							from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
							group by agent,sMonth
				), c as (
					select  agent,sMonth,
						sum (
							case when eventtype = 1 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						) loginduration,
						sum (
							case when eventtype = 3 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	readduration,
						sum (
							case when eventtype = 6 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	acwDuration,
						sum (
							case when eventtype = 6 then
								1
							else 0 end
						)	acw
					from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime 
					group by agent,sMonth
				)
					select	c.agent,
							c.sMonth as period,
							ISNULL(abandon,0) abandon,
							ISNULL(answer,0) answer,
							ISNULL(transfer,0) transfer,
							dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
							dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
							ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
							dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
							ISNULL( outbound,0)outbound,
							dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
							dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
							dbo.sec_to_time(isnull(readduration,0)) readyDuration,
							dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

				  from c
							left join a on a.agent = c.agent and a.sMonth = c.sMonth
							left join b on b.agent = c.agent and b.sMonth = c.sMonth
		end	
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		if ( len(@Agent) > 0) begin
			;with a as (
					select  agent,sWeek,
					sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
					sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
					sum(cast(transfer as smallint) ) as transfer,
					avg(callDuration) as avgInboundDuration,
					sum(callDuration) as inboundTotalDuration,
					sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
					sum(talktime) as inboundTalkDuration
					from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
					group by agent,sWeek 
			) , b as (
				select  agent,sWeek,
					count(1) as outbound,sum(connectTime) outboundDuration 
						from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
						group by agent,sWeek
			), c as (
				select  agent,sWeek,
					sum (
						case when eventtype = 1 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					) loginduration,
					sum (
						case when eventtype = 3 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	readduration,
					sum (
						case when eventtype = 6 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	acwDuration,
					sum (
						case when eventtype = 6 then
							1
						else 0 end
					)	acw
				from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
				group by agent,sWeek
			)
				select	c.agent,
						c.sWeek as period,
						ISNULL(abandon,0) abandon,
						ISNULL(answer,0) answer,
						ISNULL(transfer,0) transfer,
						dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
						dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
						ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
						dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
						ISNULL( outbound,0)outbound,
						dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
						dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
						dbo.sec_to_time(isnull(readduration,0)) readyDuration,
						dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

			  from c
						left join a on a.agent = c.agent and a.sWeek = c.sWeek
						left join b on b.agent = c.agent and b.sWeek = c.sWeek
		end
		else begin
			;with a as (
						select  agent,sWeek,
						sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
						sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
						sum(cast(transfer as smallint) ) as transfer,
						avg(callDuration) as avgInboundDuration,
						sum(callDuration) as inboundTotalDuration,
						sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
						sum(talktime) as inboundTalkDuration
						from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
						group by agent,sWeek 
				) , b as (
					select  agent,sWeek,
						count(1) as outbound,sum(connectTime) outboundDuration 
							from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
							group by agent,sWeek
				), c as (
					select  agent,sWeek,
						sum (
							case when eventtype = 1 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						) loginduration,
						sum (
							case when eventtype = 3 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	readduration,
						sum (
							case when eventtype = 6 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	acwDuration,
						sum (
							case when eventtype = 6 then
								1
							else 0 end
						)	acw
					from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime 
					group by agent,sWeek
				)
					select	c.agent,
							c.sWeek as period,
							ISNULL(abandon,0) abandon,
							ISNULL(answer,0) answer,
							ISNULL(transfer,0) transfer,
							dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
							dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
							ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
							dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
							ISNULL( outbound,0)outbound,
							dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
							dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
							dbo.sec_to_time(isnull(readduration,0)) readyDuration,
							dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

				  from c
							left join a on a.agent = c.agent and a.sWeek = c.sWeek
							left join b on b.agent = c.agent and b.sWeek = c.sWeek
		end	
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		if ( len(@Agent) > 0) begin
			;with a as (
					select  agent,sYear,
					sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
					sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
					sum(cast(transfer as smallint) ) as transfer,
					avg(callDuration) as avgInboundDuration,
					sum(callDuration) as inboundTotalDuration,
					sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
					sum(talktime) as inboundTalkDuration
					from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
					group by agent,sYear 
			) , b as (
				select  agent,sYear,
					count(1) as outbound,sum(connectTime) outboundDuration 
						from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
						group by agent,sYear
			), c as (
				select  agent,sYear,
					sum (
						case when eventtype = 1 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					) loginduration,
					sum (
						case when eventtype = 3 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	readduration,
					sum (
						case when eventtype = 6 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	acwDuration,
					sum (
						case when eventtype = 6 then
							1
						else 0 end
					)	acw
				from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
				group by agent,sYear
			)
				select	c.agent,
						c.sYear as period,
						ISNULL(abandon,0) abandon,
						ISNULL(answer,0) answer,
						ISNULL(transfer,0) transfer,
						dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
						dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
						ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
						dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
						ISNULL( outbound,0)outbound,
						dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
						dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
						dbo.sec_to_time(isnull(readduration,0)) readyDuration,
						dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

			  from c
						left join a on a.agent = c.agent and a.sYear = c.sYear
						left join b on b.agent = c.agent and b.sYear = c.sYear
		end
		else begin
			;with a as (
						select  agent,sYear,
						sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
						sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
						sum(cast(transfer as smallint) ) as transfer,
						avg(callDuration) as avgInboundDuration,
						sum(callDuration) as inboundTotalDuration,
						sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
						sum(talktime) as inboundTalkDuration
						from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
						group by agent,sYear 
				) , b as (
					select  agent,sYear,
						count(1) as outbound,sum(connectTime) outboundDuration 
							from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
							group by agent,sYear
				), c as (
					select  agent,sYear,
						sum (
							case when eventtype = 1 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						) loginduration,
						sum (
							case when eventtype = 3 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	readduration,
						sum (
							case when eventtype = 6 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	acwDuration,
						sum (
							case when eventtype = 6 then
								1
							else 0 end
						)	acw
					from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime 
					group by agent,sYear
				)
					select	c.agent,
							c.sYear as period,
							ISNULL(abandon,0) abandon,
							ISNULL(answer,0) answer,
							ISNULL(transfer,0) transfer,
							dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
							dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
							ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
							dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
							ISNULL( outbound,0)outbound,
							dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
							dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
							dbo.sec_to_time(isnull(readduration,0)) readyDuration,
							dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

				  from c
							left join a on a.agent = c.agent and a.sYear = c.sYear
							left join b on b.agent = c.agent and b.sYear = c.sYear
		end
	end
	--周期特性 日
	else begin 
		if ( len(@Agent) > 0) begin
			;with a as (
					select  agent,sTime,
					sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
					sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
					sum(cast(transfer as smallint) ) as transfer,
					avg(callDuration) as avgInboundDuration,
					sum(callDuration) as inboundTotalDuration,
					sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
					sum(talktime) as inboundTalkDuration
					from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
					group by agent,sTime 
			) , b as (
				select  agent,sTime,
					count(1) as outbound,sum(connectTime) outboundDuration 
						from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
						group by agent,sTime
			), c as (
				select  agent,sTime,
					sum (
						case when eventtype = 1 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					) loginduration,
					sum (
						case when eventtype = 3 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	readduration,
					sum (
						case when eventtype = 6 then
							datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
						else 0 end
					)	acwDuration,
					sum (
						case when eventtype = 6 then
							1
						else 0 end
					)	acw
				from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime and agent = @Agent
				group by agent,sTime
			)
				select	c.agent,
						c.sTime as period,
						ISNULL(abandon,0) abandon,
						ISNULL(answer,0) answer,
						ISNULL(transfer,0) transfer,
						dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
						dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
						ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
						dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
						ISNULL( outbound,0)outbound,
						dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
						dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
						dbo.sec_to_time(isnull(readduration,0)) readyDuration,
						dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

			  from c
						left join a on a.agent = c.agent and a.sTime = c.sTime
						left join b on b.agent = c.agent and b.sTime = c.sTime
		end
		else begin
			;with a as (
						select  agent,sTime,
						sum(case when contactDisposition=1 then 1 else 0 end ) as abandon,
						sum(case when contactDisposition=2 then 1 else 0 end ) as answer,
						sum(cast(transfer as smallint) ) as transfer,
						avg(callDuration) as avgInboundDuration,
						sum(callDuration) as inboundTotalDuration,
						sum(case when contactDisposition=2 and  ringtime <=15  then 1 else 0 end ) as fifAnser,
						sum(talktime) as inboundTalkDuration
						from dbo.V_CallInbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
						group by agent,sTime 
				) , b as (
					select  agent,sTime,
						count(1) as outbound,sum(connectTime) outboundDuration 
							from dbo.V_CallOutbound where startDateTime between @tempMinStartTime and @tempMaxEndTime and agent is not null
							group by agent,sTime
				), c as (
					select  agent,sTime,
						sum (
							case when eventtype = 1 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						) loginduration,
						sum (
							case when eventtype = 3 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	readduration,
						sum (
							case when eventtype = 6 then
								datediff(s,eventDateTime,(case when nextTime > @tempMaxEndTime then @tempMaxEndTime else nextTime end))
							else 0 end
						)	acwDuration,
						sum (
							case when eventtype = 6 then
								1
							else 0 end
						)	acw
					from dbo.V_AgentState where eventDateTime between @tempMinStartTime and @tempMaxEndTime 
					group by agent,sTime
				)
					select	c.agent,
							c.sTime as period,
							ISNULL(abandon,0) abandon,
							ISNULL(answer,0) answer,
							ISNULL(transfer,0) transfer,
							dbo.sec_to_time(isnull(avgInboundDuration,0)) avgInboundDuration,
							dbo.sec_to_time(isnull(inboundTotalDuration,0)) inboundTotalDuration,
							ISNULL(dbo.avg_str(fifAnser,ISNULL(answer,0) + ISNULL(abandon,0),1),0) as fifteenAnswerRate,
							dbo.sec_to_time(isnull(inboundTalkDuration,0)) inboundTalkDuration,
							ISNULL( outbound,0)outbound,
							dbo.sec_to_time(isnull(outboundDuration,0)) outboundDuration ,
							dbo.sec_to_time(isnull(loginduration,0)) loginDuration,
							dbo.sec_to_time(isnull(readduration,0)) readyDuration,
							dbo.sec_to_time(isnull(acwDuration,0)) acwDuration ,acw

				  from c
							left join a on a.agent = c.agent and a.sTime = c.sTime
							left join b on b.agent = c.agent and b.sTime = c.sTime
		end
	end
	 

	return @@rowcount
END






GO
/****** Object:  StoredProcedure [dbo].[sp_call_abandon_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.18>
-- Description:	大屏历史数据报表
/*
Example:
exec [sp_call_abandon_total] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@TimeBegin='00:00',@TimeEnd='23:59'
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_call_abandon_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@TimeBegin	NVARCHAR(8)	= NULL,
	@TimeEnd	NVARCHAR(8)	= NULL
AS 
BEGIN
	declare @DT_Begin			datetime,
			@DT_End				datetime,
			@outboundTotal		NVARCHAR(30),
			@strSql				NVARCHAR(MAX)
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end
	
	if (@TimeBegin is null or len(@TimeBegin)=0) begin
		set @TimeBegin = '00:00'
	end
	
	if (@TimeEnd is null or len(@TimeEnd)=0) begin
		set @TimeEnd = '23:59'
	end
	
	select @outboundTotal=COUNT(*) from dbo.ContactCallDetail m ,dbo.Resource r where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1 and m.contacttype = 2 and m.destinationType = 3  and convert(varchar(16), m.startDateTime, 121) BETWEEN (@DateBegin + ' ' + @TimeBegin) And (@DateEnd + ' ' + @TimeEnd)
	
	SET @strSql = ';WITH cte1 as(
        select * from [V_CallInbound] where (sTime BETWEEN ''' + @DateBegin + ''' And ''' + @DateEnd + ''') and (segment between ''' + @TimeBegin + ''' And ''' + @TimeEnd + ''')
	),cte2 as (
	select COUNT ( * ) as total,--呼入总数
		count ( case when isnull(ringtime,0)>0   then 1 end ) as agentTotal,--转人工数
		count ( case contactDisposition when 2 then 1 end ) as answerTotal,--应答总数
		count ( case when isnull(ringtime,0) <=0 and contactDisposition=1 and isnull(queuetime,0) <= 0 then 1 end ) as ivrAbandon,--ivr 放弃数
		count ( case when isnull(ringtime,0) <=0 and contactDisposition=1 and isnull(queuetime,0) > 0 then 1 end ) as queueAbandon,--队列放弃数
		count ( case when isnull(ringtime,0)>0 and contactDisposition=1 then 1 end ) as agentAbandon--坐席放弃数数
		from cte1
	)
	select cte2.*,' + @outboundTotal + ' as outboundTotal from cte2'
	
	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_abandon_total] error '  
	 SELECT  
		total = NULL,
		outboundTotal = NULL,
		agentTotal = NULL,
		answerTotal = NULL,
		ivrAbandon = NULL,
		queueAbandon = NULL,
		agentAbandon = NULL
	RETURN -1;  
END

GO
/****** Object:  StoredProcedure [dbo].[sp_call_inbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	呼入明细报表
/*
Example:
exec sp_call_inbound @DateBegin='20140121'
					,@DateEnd='20140121'
					,@Calling='',@CallResult=''
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_call_inbound]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Calling	NVARCHAR(30)	= NULL,
	@CallResult NVARCHAR(30)	= NULL
AS 
BEGIN
	declare @DT_Begin			datetime,
			@DT_End				datetime,
			@strSql				NVARCHAR(MAX)
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end

	--select @DT_Begin = @DateBegin + ' 00:00:00',
		   --@DT_End   = @DateEnd   + ' 23:59:59'
	
	SET @strSql = 'select originatorDN as calling ,destinationDN as called,m.startDateTime as recordTime,
	isnull(r.extension,'''') as extension,isnull(r.resourcegroupid,rg.resourcegroupid) resourcegroupid,
	connectTime as totalTime ,
		(select top 1 queuetime from ContactQueueDetail s 
								where s.sessionID = m.sessionID 
									and s.nodeID = m.nodeID
									and s.profileID = m.profileID
									and s.sessionSeqNum = 0) as queuetime,
		s.ringtime ,
		(case contactDisposition	when 1 then ''放弃'' when 2 then ''成功'' else ''失败'' end ) callresult
									
		from ContactCallDetail m 
		left join AgentConnectionDetail s 
			on s.sessionID = m.sessionID  and s.nodeID = m.nodeID and s.profileID = m.profileID and s.sessionSeqNum = m.sessionSeqNum
		left join dbo.Resource r on r.resourceID = s.resourceID and r.profileId = s.profileID
		left join dbo.ResourceGroup rg on rg.resourcegroupname = m.customvariable1 and rg.profileID = m.profileID
		where contactType =1 and originatorType = 3 and m.sessionSeqNum = 0 '	
		
		+ ' and convert(varchar(10), m.startDateTime, 112) BETWEEN ''' + @DateBegin + ''' And ''' + @DateEnd + ''''
	
	IF LEN(@Calling) > 0     set  @strSql = @strSql + ' and m.originatorDN = ''' + @Calling + ''''
	
	IF (@CallResult = 1)  set  @strSql = @strSql + ' and m.contactDisposition = ' + @CallResult 
	
	IF (@CallResult = 2)  set  @strSql = @strSql + ' and m.contactDisposition = ' + @CallResult 
	
	IF (@CallResult > 2)  set  @strSql = @strSql + ' and m.contactDisposition > ' + @CallResult 
	
	set @strSql = @strSql + ' order by m.startDateTime'
	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_inbound] error '  
	 SELECT calling = NULL, called = NULL, recordTime = NULL, extension = NULL, 
		totalTime = NULL, queuetime = NULL, ringtime = NULL, callResult = NULL
	RETURN -1;  
END

GO
/****** Object:  StoredProcedure [dbo].[sp_call_inbound_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.18>
-- Description:	呼入汇总报表
/*
Example:
exec [sp_call_inbound_total] @DateBegin='20140121'
					,@DateEnd='20140121'
					,@resourceGroupID=5
					,@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_call_inbound_total]
	@DateBegin			NVARCHAR(10)	= NULL,
	@DateEnd			NVARCHAR(10)	= NULL,
	@GroupLevel			NVARCHAR(10)	= NULL,
	@resourceGroupID	INT				= NULL	-- 资源分组
	--,@IsNeedTotal SMALLINT = NULL
AS 
BEGIN
	declare @DT_Begin			NVARCHAR(30),
			@DT_End				NVARCHAR(30),
			@strSql				NVARCHAR(MAX),
			@strColumn			NVARCHAR(30),
			@strSegment			NVARCHAR(10),
			@IsNeedTotal		SMALLINT
			
	set @IsNeedTotal=1
	set @resourceGroupID = ISNULL(@resourceGroupID, 0)
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end
	
	set @strSegment = ''
	set @DT_Begin = rtrim(@DateBegin) + ' 00:00:00.000'
	set @DT_End = rtrim(@DateEnd) + ' 23:59:59.997'
	
	if ( lower(@GroupLevel) = 'hour' ) begin
		set @strColumn = ' sTime '
		set @strSegment = ' ,segment '
	end
	else if ( lower(@GroupLevel) = 'month' ) begin 
		set @strColumn = ' sMonth '
	end
	else if ( lower(@GroupLevel) = 'week' ) begin 
		set @strColumn = ' sWeek '
	end
	else if ( lower(@GroupLevel) = 'year' ) begin 
		set @strColumn = ' sYear '
	end
	
	else begin 
		set @strColumn = ' sTime '
	end
	
	SET @strSql = ';WITH cte1 as(
        select m.*,isnull(r.resourcegroupid,rg.resourcegroupid) resourcegroupid from [V_CallInbound] m
				left join dbo.Resource r on r.resourceID = m.resourceID and r.profileId = m.profileID
				left join dbo.ResourceGroup rg on rg.resourcegroupname = m.customvariable1 and rg.profileID = m.profileID 
			where startDateTime BETWEEN ''' + @DT_Begin + ''' And ''' + @DT_End + '''
				and ('+str(@resourceGroupID) + ' = 0 or r.resourceGroupID = ' + str(@resourceGroupID) + ')
				and ('+str(@resourceGroupID) + ' = 0 or rg.resourceGroupID = ' + str(@resourceGroupID) + ')
	),cte2 as (
	select ' + @strColumn + ' as sTime ' + @strSegment + '
		,resourceGroupID
		,COUNT ( * ) as total,
		count ( case contactDisposition when 2 then 1 end ) as answerTotal,--应答数
		count ( case when contactDisposition > 2 then 1 end ) as failTotal,--失败数
		count ( case when contactDisposition =1 then 1 end ) as abandonTotal,--放弃数
		count ( case when ringtime>0 and contactDisposition=1 then 1 end ) as agentLossTotal,--坐席呼损数
		count ( case when isnull(ringtime,0) <=0 and contactDisposition=1 and isnull(queuetime,0) > 0 then 1 end ) as queueLossTotal,--排队呼损
		count ( case when isnull(ringtime,0) <=0 and contactDisposition=1 and isnull(queuetime,0) <= 0 then 1 end ) as ivrLossTotal,--ivr 呼损
		count ( case when ringtime > 0 and contactDisposition=2 and isnull(queuetime,0) > 0 then 1 end ) as afterQueueHandleTotal,--排队后接通数
		sum   ( case when ringtime > 0 and contactDisposition=2 and isnull(queuetime,0) > 0 then isnull(queuetime,0) else 0 end  ) as afterQueueHandleTimeTotal,--排队接通后 总排队时间
		count ( case when isnull(queuetime,0) > 0 then 1 end ) as queueTotal,--排队数
		sum   ( case when isnull(queuetime,0) > 0 then isnull(queuetime,0) else 0 end  ) as queueTimeTotal,--排队总时间
		sum	  ( ISNULL(queuetime,0)+ISNULL(ringtime,0)) as waitTimeTotal--应答总时间
	 from cte1 group by ' + @strColumn + @strSegment + ',resourceGroupID 
	)
	select sTime ' + @strSegment + '
			,resourcegroupid 
			,total,
			answerTotal,
			dbo.avg_str(answerTotal,total,1) as answerRate,
			agentLossTotal,
			(queueLossTotal + ivrLossTotal) as waitLossTotal,
			abandonTotal,
			dbo.avg_str(abandonTotal,total,1) as lossRate,
			dbo.avg_str(waitTimeTotal,total,0) as avgAnswerTime,
			dbo.avg_str(afterQueueHandleTimeTotal,afterQueueHandleTotal,0) as avgHandleQueueTime,
			dbo.avg_str(queueTimeTotal,queueTotal,0) as avgQueueTime
	from cte2 '
 
	if ( @IsNeedTotal = 1 ) begin
		if ( Lower(@GroupLevel) =  'hour' ) begin
			set @strSegment = ' ,'''' as segment '
		end
		
		set @strSql = @strSql + '
		union select ''Total'' as sTime ' + @strSegment + '
			,null
			,SUM(total) as total,
			SUM(answerTotal) as answerTotal,
			dbo.avg_str(SUM(answerTotal),SUM(total),1) as answerRate,
			SUM(agentLossTotal) as agentLossTotal,
			SUM(queueLossTotal + ivrLossTotal) as waitLossTotal,
			SUM(abandonTotal) as abandonTotal,
			dbo.avg_str(SUM(abandonTotal),SUM(total),1) as lossRate,
			dbo.avg_str(Sum(waitTimeTotal),sum(total),0) as avgAnswerTime,
			dbo.avg_str(Sum(afterQueueHandleTimeTotal),sum(afterQueueHandleTotal),0) as avgHandleQueueTime,
			dbo.avg_str(Sum(queueTimeTotal),sum(queueTotal),0) as avgQueueTime 
		from cte2 '
	end
	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY 
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_inbound_total] error '  
	 SELECT  sTime = NULL,
		resourcegroupid = null,
		total = NULL,
		answerTotal = NULL,
		answerRate = NULL,
		agentLossTotal = NULL,
		waitLossTotal = NULL,
		abandonTotal = NULL,
		lossRate = NULL,
		avgAnswerTime = NULL,
		avgHandleQueueTime = NULL,
		avgQueueTime = NULL
	RETURN -1;  
END




GO
/****** Object:  StoredProcedure [dbo].[sp_call_loss_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.07.02>
-- Description:	呼损统计报表
/*
Example:
exec sp_call_loss_total @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14'
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_call_loss_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Called     NVARCHAR(50)	= NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end
	
	select @Called=isnull(@Called,'')
	
	SET @strSql = 'select '''+ @DateBegin + '～' + @DateEnd +''' as segment,' 
	if (len(@Called) > 0 ) begin
		SET @strSql = @strSql + ' calledNew,'
	end
	SET @strSql = @strSql
		+ ' count( case when (contactDisposition=1) then 1 end) as abandonTotal,
			count ( case when (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 15 and contactDisposition=1)  then 1 end ) as fifLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 16  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 30 ) and contactDisposition=1 )then 1 end ) as thirtyLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 31  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 60 ) and contactDisposition=1 )then 1 end ) as sixLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 61  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 180 ) and contactDisposition=1 )then 1 end ) as eightLoss ,
			count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   > 180 and contactDisposition=1  )then 1 end ) as overEightLoss  
		from (
			select m.* '
			
	if (len(@Called) > 0 ) begin
		SET @strSql = @strSql + ' ,(case when  (len(m.called) >=13 and SUBSTRING(m.called,1,3) = ''901''  )
				then SUBSTRING(m.called,3,11) 
				 when  (len(m.called) >=13 and SUBSTRING(m.called,1,3) = ''900''  )
				then SUBSTRING(m.called,3,len(m.called)-2) 
				when (len(m.called) >=10 and SUBSTRING(m.called,1,2) = ''91'' )
				then  SUBSTRING(m.called,2,11) 
				when (len(m.called) >=5 and SUBSTRING(m.called,1,1) = ''9'' )
				then  SUBSTRING(m.called,2,len(m.called)-1) 
				else m.called end) calledNew '
	end
	
	SET @strSql = @strSql + ' from (
			select	m.startDateTime, 
					CONVERT(varchar(10), m.startDateTime, 23) as sTime,
					--CONVERT(varchar(4), m.startDateTime, 23) as sYear		,
					--CONVERT(varchar(7), m.startDateTime, 23) as sMonth,
					--dbo.week_series_to_str(m.startDateTime,0) as sWeek,
					--(select segment  from dbo.V_Timesegment vt where CONVERT(varchar(12), m.startDateTime, 108) between vt.sBegin and vt.sEnd) as segment,
					(case when m.connectTime>0 then m.contactDisposition else 1 end ) as contactDisposition,
					(select top 1 queuetime from ContactQueueDetail s 
											where s.sessionID = m.sessionID  and s.nodeID = m.nodeID
												and s.profileID = m.profileID and s.sessionSeqNum = 0) as queuetime,
					(select top 1 ringtime  from AgentConnectionDetail s 
											where s.sessionID = m.sessionID  and s.nodeID = m.nodeID
												and s.profileID = m.profileID and s.sessionSeqNum = 0) as ringtime ,'
												
	if (len(@Called) > 0 ) begin
		SET @strSql = @strSql + ' isnull(rtrim(ltrim((case when (contactType = 1  and originatorType = 3 ) then 					
						isnull((select top 1 r.extension from AgentConnectionDetail s ,dbo.Resource r
											where s.sessionID = m.sessionID  and s.nodeID = m.nodeID
												and s.profileID = m.profileID and s.sessionSeqNum = 0
												and s.resourceID = r.resourceID  and s.profileID = r.profileID
						) ,destinationDN) else REPLACE(m.calledNumber, ''#'', '''') end))),'''') as called ,'
	end
	
	SET @strSql = @strSql + ' connectTime
			from ContactCallDetail m
			where  ( (contactType = 1  and originatorType = 3 )
					   or  (m.originatorType = 1  and m.contacttype = 2  and m.destinationType = 3  ) 
					) and sessionSeqNum = 0
			) m where sTime BETWEEN ''' + @DateBegin  + ''' And ''' + @DateEnd  + ''' ) m'
			
	if (len(@Called) > 0 ) begin
		SET @strSql = @strSql + ' group by calledNew having calledNew = ''' + @Called + ''''
	end
	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_loss_total] error '  
	 SELECT segment = NULL, abandonTotal = NULL, fifLoss = NULL, 
		thirtyLoss = NULL, sixLoss = NULL, eightLoss = NULL, overEightLoss = NULL,maxLoss=NULL,
		calledNew = NULL
	RETURN -1;  
END



GO
/****** Object:  StoredProcedure [dbo].[sp_call_outbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	呼出明细报表
/*
Example:
exec [sp_call_outbound] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@Agent='',@CallResult=''
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_call_outbound]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@Agent		NVARCHAR(30)	= NULL,
	@CallResult NVARCHAR(30)	= NULL
AS 
BEGIN
	declare @DT_Begin			datetime,
			@DT_End				datetime,
			@strSql				NVARCHAR(MAX)
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end

	--select @DT_Begin = @DateBegin + ' 00:00:00',
		   --@DT_End   = @DateEnd   + ' 23:59:59'
	
	SET @strSql = 'select r.resourceName+''('' + r.resourceLoginId + '')'' as agent,
		m.startDateTime as recordTime,m.calledNumber as called,m.connecttime as totalTime,
		(case when m.connectTime>0 then ''成功'' else ''失败'' end ) callresult
		from dbo.ContactCallDetail m ,dbo.Resource r
		where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1 and m.contacttype = 2 and m.destinationType = 3 '	
		+ ' and convert(varchar(10), m.startDateTime, 112) BETWEEN ''' + @DateBegin + ''' And ''' + @DateEnd + ''''
	
	IF LEN(@Agent) > 0     set  @strSql = @strSql + ' and r.resourceLoginId = ''' + @Agent + ''''
	
	IF (@CallResult = 1)  set  @strSql = @strSql + ' and m.connectTime > 0 '
	
	IF (@CallResult <> 1)  set  @strSql = @strSql + ' and m.connectTime = 0 '
	
	
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_outbound] error '  
	 SELECT agent = NULL, agentName = NULL, recordTime = NULL, called = NULL, 
		totalTime = NULL, callResult = NULL
	RETURN -1;  
END

GO
/****** Object:  StoredProcedure [dbo].[sp_call_time_analysis]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.18>
-- Description:	呼叫时长分析统计
/*
Example:
exec sp_call_time_analysis @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14'
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_call_time_analysis]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end

	SET @strSql = 'select '''+ @DateBegin + '～' + @DateEnd +''' as segment,' 
		+ ' count ( case contactDisposition when 2 then 1 end ) as answerTotal,
			
			dbo.sec_to_time(count ( case when (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 15 )  then 1 end )) as fifWaitTime ,
			dbo.sec_to_time(count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 16  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 30 )  )then 1 end )) as thirtyWaitTime ,
			dbo.sec_to_time(count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 31  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 60 )  )then 1 end )) as sixWaitTime ,
			dbo.sec_to_time(count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   >= 61  and (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   <= 180 )  )then 1 end )) as eightWaitTime ,
			dbo.sec_to_time(count ( case when  (( ISNULL(queuetime,0)+ISNULL(ringtime,0))   > 180   )then 1 end )) as overEightWaitTime ,
			dbo.sec_to_time(( select max(ISNULL(queuetime,0)+ISNULL(ringtime,0)) from  [V_CallInbound] where sTime BETWEEN ''' + @DateBegin  + ''' And ''' + @DateEnd  + '''  and contactDisposition=2)) as maxWaitTime
		from  [V_CallInbound] where sTime BETWEEN ''' + @DateBegin  + ''' And ''' + @DateEnd  + '''  and contactDisposition=2 '
	PRINT @strSql
	
	BEGIN TRY  
		EXECUTE(@strSQL)--EXEC sp_executesql @strSQL   
	END TRY  
	
	BEGIN CATCH  
		GOTO ERROR_END              
		RETURN -1  
	END CATCH  
	RETURN @@rowcount  
	ERROR_END:   
	PRINT ' [sp_call_time_analysis] error '  
	 SELECT segment = NULL, answerTotal = NULL, waitTimeTotal = NULL, fifWaitTime = NULL, 
		thirtyWaitTime = NULL, sixWaitTime = NULL, eightWaitTime = NULL, overEightWaitTime = NULL,maxWaitTime=NULL
	RETURN -1;  
END

GO
/****** Object:  StoredProcedure [dbo].[sp_service_operation_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.07.05>
-- Description:	服务台运行统计报表
/*
Example:
exec [sp_service_operation_total] @DateBegin='2013-01-14'
					,@DateEnd='2013-06-14',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_service_operation_total]
	@DateBegin	NVARCHAR(10)	= NULL,
	@DateEnd	NVARCHAR(10)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL
	--,@IsNeedTotal SMALLINT = NULL
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	declare @tempCount			int
			
	if isdate(@DateBegin) != 1  begin
		set @DateBegin = convert(varchar(10), getdate(), 121)
	end
	
	if isdate(@DateEnd) != 1 begin
		set @DateEnd = convert(varchar(10), getdate(), 121)
	end
	
	create table #T_ServiceOperationTotal(
	
		period					varchar(30),	--周期
		segment					varchar(20),	--时间段
		beginTime				datetime	,	--start
		endTime					datetime	--,	--end time segment
		/*
		inboundTotal			int	,			--总进线量	总进线量=到达坐席数+IVR呼损数
		ivrLossTotal			int,			--IVR呼损数	还没分配到坐席就挂断的呼入数
		toAgentTotal			int,			--到达坐席量	已经分配到坐席的呼入数
		agentAnswerTotal		int,			--坐席应答电话量	
		agentAnswerRate			varchar(20),	--坐席应答率	
		holdDuration			int,			--保持/咨询时长	
		holdFrequency			int,			--保持/咨询次数	
		avgHoldDuration			float,			--保持/咨询平均时长	
		maxQueueTime			int,			--最大排队时长	
		avgQueueTime			float,			--平均排队时长	
		avgRingTime				float,			--平均振铃时长	
		readyNumber				int,			--阶段坐席就绪人数	
		loginDurationTotal		int,			--总登录时长	
		--agentNumber				int,			--坐席数	
		avgInboundTalkDuration	float,			--平均呼入通话时长	
		avgAcwDuration			float,			--平均呼入话后整理时长	
		inboundAHT				float,			--平均呼入处理时长	
		agentOutboundTotal		int,			--客服呼出量	
		outboundAvgTalkDuration	float,			--平均呼出通话时长	
		outboundAvgACWDuration	int,			--平均呼出话后整理时长		
		outboundAgentNumber		int,			--坐席外呼人数	
		outboundDurationTotal	int,			--坐席外呼时长
		
		notready1Number	        int, --会议人数 
		notready1Duration       int, --会议时长 
		notready2Number	        int, --小休人数 
		notready2Duration       int, --小休时长 
		notready3Number		    int, --用餐人数 
		notready3Duration       int, --用餐时长
		notready4Number	        int, --洗手人数 
		notready4Duration       int, --洗手时长 

		workFormTotal			int,			--工单总数	当前时间坐席所创建的工单数量
		firstSolveRate			varchar(10),	--一线解决率	坐席自行处理的工单数/工单总数量
		secondSolveRate			varchar(10)	--二线解决率	工单总数量减去坐席自行处理的工单数后再除以工单总数量
		
		*/
		,row_num int
	)
	
	set @strSql = ' insert into #T_ServiceOperationTotal '
	declare @date1 datetime,@date2 datetime
	set @date1 = @DateBegin
	set @date2 = @DateEnd
	
	create table #temp_periodS (period varchar(20),beginTime datetime,endTime datetime)
	
	--周期特性 小时
	if ( lower(@GroupLevel) = 'hour' ) begin 
		ALTER TABLE #temp_periodS ADD segment varchar(20)
		insert into #temp_periodS 
			select  period, CONVERT(datetime,period + ' ' + sBegin + '.000', 120) as beginTime, CONVERT(datetime,period + ' ' + sEnd + '.998', 120)  as endTime,segment
			from (
				select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m , dbo.V_TimeSegment t
			
		set @strSql = @strSql + ' (period,beginTime,endTime,segment,row_num) SELECT top 2000 p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		insert into #temp_periodS 
			select  convert(varchar(7),dateadd(mm,number,@date1),120) as period,
				dateadd(ss,0,dateadd(mm,number,@date1)) as beginTime,dateadd(ss,-1,dateadd(mm,number+1,@date1)) as  endTime
			from master..spt_values where type='p' and number <= datediff(mm,@date1,@date2)
		
		update #temp_periodS	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_periodS) 	
		update #temp_periodS	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_periodS) 
		--select * from #temp_periodS
		set @strSql = @strSql + ' (period,beginTime,endTime,row_num) SELECT p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		insert into #temp_periodS 

			select distinct dbo.week_series_to_str(dateadd(dd,number,@date1),0) as period,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ),112) as starttime,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ) + ' 23:59:59',120) +6 as endtime
			 from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			 
		update #temp_periodS	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_periodS) 	
		update #temp_periodS	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_periodS) 
		--select * from #temp_periodS
		
		set @strSql = @strSql + ' (period,beginTime,endTime,row_num) SELECT top 2000 p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		insert into #temp_periodS 
			select period, CONVERT(datetime,period + '-01-01 00:00:00', 120) as beginTime, CONVERT(datetime,period + '-12-31 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(4),dateadd(yy,number,@date1),120) from master..spt_values where type='p' and number <= datediff(yy,@date1,@date2)
			) m
		--更新开始时间 结束时间
		update #temp_periodS	 set beginTime = CONVERT(datetime,@DateBegin + ' 00:00:00', 120) where beginTime = (select min(beginTime) from #temp_periodS) 	
		update #temp_periodS	 set endTime = CONVERT(datetime,@DateEnd + ' 23:59:59', 120) where endTime = (select max(endTime) from #temp_periodS) 
		
		--select * from #temp_periodS
		set @strSql = @strSql +  ' (period,beginTime,endTime,row_num) SELECT p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	--周期特性 日
	else begin 
		insert into #temp_periodS 
			select period, CONVERT(datetime,period + ' 00:00:00', 120) as beginTime, CONVERT(datetime,period + ' 23:59:59', 120)  as endTime
			from (
			select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m
		
		set @strSql = @strSql +  ' (period,beginTime,endTime,row_num) SELECT top 1000 p.*,row_number() over(order by p.beginTime) FROM #temp_periodS p '
	end
	
	EXECUTE(@strSQL)
	
	
	
	--select @tempCount = isnull(count(*),0) from #T_ServiceOperationTotal
	
	declare @tempMinStartTime 	datetime 
	declare @tempMaxEndTime 	datetime
		
	select @tempMinStartTime = min(beginTime) from #T_ServiceOperationTotal
	select @tempMaxEndTime	 = max(endTime)   from #T_ServiceOperationTotal
	
	--select * from #T_ServiceOperationTotal
	/*
	if ( lower(@GroupLevel) = 'hour' ) begin
		select period,segment,agent ,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_ServiceOperationTotal
	end
	else begin
		select period,agent,agentName,beginTime,endTime,loginDuration,answer,transfer,abandon,inboundTotalDuration,avgInboundDuration,fifteenAnswerRate,outboundTotal,outboundTotalDuration,avgOutboundDuration,inboundTalkDuration,readyDuration,notready1Duration,speedAnswerRate from #T_ServiceOperationTotal
	end
	*/

	;with a as (
	select 
		t.period,t.segment,t.beginTime,t.endTime,t.row_num,
		count(t.row_num) as inboundTotal,
		count ( case when (ringtime <=0 and contactDisposition=1) then 1 end ) as ivrLossTotal,
		count ( case when (ringtime >0 ) then 1 end ) as toAgentTotal,
		count ( case when contactDisposition =2 then 1 end ) as agentAnswerTotal,
		dbo.avg_str(count ( case when contactDisposition =2 then 1 end ),count ( case when (ringtime >0 ) then 1 end ),1) agentAnswerRate,
		dbo.sec_to_time(sum(isnull(holdtime,0))) as holdDuration,
		count ( case when (holdtime >0 ) then 1 end ) as holdFrequency,
		dbo.sec_to_time(cast ( dbo.avg_str(sum(isnull(holdtime,0)),count ( case when (holdtime >0 ) then 1 end ),0) as float ) ) as avgHoldDuration,
		max(queueTime) as maxQueueTime,
		dbo.avg_str(sum(isnull(queueTime,0)),count ( case when (queueTime >0 ) then 1 end ),0) as avgQueueTime,
		dbo.avg_str(sum(isnull(ringTime,0)), count ( case when (ringtime  >0 ) then 1 end ) ,0) as avgRingTime,
		dbo.sec_to_time( cast (dbo.avg_str(sum(isnull(talkTime,0)),count ( case when contactDisposition =2 then 1 end ),0) as float) ) as avgInboundTalkDuration,
		dbo.sec_to_time( cast (dbo.avg_str(sum(isnull(workTime,0)),count ( case when contactDisposition =2 then 1 end ),0) as float) ) as avgAcwDuration,
		dbo.sec_to_time( cast (dbo.avg_str(sum(isnull(ringTime,0)) + sum(isnull(talkTime,0)) + sum(isnull(workTime,0)),count ( case when contactDisposition =2 then 1 end ),0) as float) ) as inboundAHT
	from #T_ServiceOperationTotal t,V_CallInbound t2
	where t2.startDateTime BETWEEN t.beginTime And t.endTime 
	group by t.row_num,t.period,t.segment,t.beginTime,t.endTime
	
	),b as (
		select 
			t.row_num,
			count(t.row_num) as agentOutboundTotal,
			dbo.sec_to_time( cast (dbo.avg_str(sum(connectTime),count(t.row_num),0) as float) ) as outboundAvgTalkDuration,
			dbo.sec_to_time( cast (dbo.avg_str(sum(worktime),count(t.row_num),0) as float) ) as outboundAvgACWDuration,
			dbo.sec_to_time(sum(connectTime)) as outboundDurationTotal,
			count(distinct agent) as outboundAgentNumber
			
		from  #T_ServiceOperationTotal t,V_CallOutbound t2
		where t2.startDateTime BETWEEN t.beginTime And t.endTime 
		group by t.row_num,t.period,t.segment,t.beginTime,t.endTime
	), asd as (
		select eventtype,eventdatetime,reasoncode,t.resourceLoginID agent,a.profileID from dbo.AgentStateDetail a , dbo.Resource t where t.resourceID=a.agentID and a.profileID = t.profileID
		and a.eventDateTime between @tempMinStartTime and dateadd(day,1,@tempMaxEndTime )
	), f as (
		select  agent, eventtype,eventDateTime,reasonCode
		,( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime  order by eventDateTime) nextTime
		--,(case when eventtype=1 then (( select top 1 eventDateTime from asd b where  b.agent=a.agent  and b.profileID=a.profileID  and b.eventDateTime > a.eventDateTime and b.eventtype=7  order by eventDateTime) ) else NULL end) nextLogTime
		from asd a 
	), g as (
		
		select  f.agent,t.row_num,
			  sum(case 
			when (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(ms,t.beginTime,f.nextTime)
			when (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(ms,f.eventDateTime,t.endTime)
			when (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(ms,f.eventDateTime,f.nextTime)
			when (f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(ms,t.beginTime,t.endTime)
			else 0 end ) as loginduration ,
		count(case  when (f.eventtype=3 ) then 1   end ) as readyNumber,
		sum(case 
			when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime)   then  datediff(s,t.beginTime,f.nextTime)
			when (f.eventtype=2 and f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime)   then  datediff(s,f.eventDateTime,t.endTime)
			when (f.eventtype=2 and f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) then  datediff(s,f.eventDateTime,f.nextTime)
			when (f.eventtype=2 and f.eventDateTime < t.beginTime and f.nextTime > t.endTime  ) then  datediff(s,t.beginTime,t.endTime)
			else 0 end ) as ACWDuration,	
		count(case  when (f.eventtype=2 ) then 1   end ) as ACW

		from f,#T_ServiceOperationTotal t
		
		where ( (f.eventDateTime < t.beginTime and f.nextTime < t.endTime and f.nextTime > t.begintime) or
		  (f.eventDateTime > t.beginTime and f.nextTime > t.endTime and f.eventDateTime < t.endtime) or
		  (f.eventDateTime >= t.beginTime and f.nextTime <= t.endTime) or
		  (f.eventDateTime < t.beginTime and f.nextTime > t.endTime) )

		group by f.agent,t.row_num,t.period,t.segment,t.beginTime,t.endTime
		
	) , c as (
		select row_num,dbo.sec_to_time(sum(loginDuration/1000)) as loginDurationTotal,
					count( case when readyNumber>0 then 1 end) as readyNumber,
					count( case when ACW>0 then 1 end) as ACW,
					dbo.sec_to_time(sum(ACWDuration)) as ACWDuration
		from g group by row_num
	)
	 


	select 
		t.period,t.segment,t.beginTime,t.endTime,
		t.inboundTotal,t.ivrLossTotal,t.toAgentTotal,t.agentAnswerTotal,
		t.agentAnswerRate,
		t.holdDuration,
		t.holdFrequency,
		t.avgHoldDuration,
		t.maxQueueTime,
		t.avgQueueTime,
		t.avgRingTime,
		t.avgInboundTalkDuration,
		t.avgAcwDuration,
		t.inboundAHT,
	
		b.agentOutboundTotal,b.outboundAvgTalkDuration,
		b.outboundAvgACWDuration,b.outboundDurationTotal,b.outboundAgentNumber,
		
		c.loginDurationTotal,c.readyNumber,
		c.acw,
		c.acwDuration,
		NULL workFormTotal,NULL firstSolveRate,NULL secondSolveRate
		
	from a as t
	left join b on  t.row_num = b.row_num
	left join c on	c.row_num = t.row_num
	
	IF OBJECT_ID('tempdb..#temp_periodS') IS NOT NULL BEGIN
		DROP TABLE #temp_periodS
		PRINT 'delete temp table #temp_periodS'
	END
	
	/*
	IF OBJECT_ID('tempdb..#T_ServiceAgent') IS NOT NULL BEGIN
		DROP TABLE #T_ServiceAgent
		PRINT 'delete temp table #T_ServiceAgent'
	END
	*/
	
	IF OBJECT_ID('tempdb..#T_ServiceOperationTotal') IS NOT NULL BEGIN
		DROP TABLE #T_ServiceOperationTotal
		PRINT 'delete temp table #T_ServiceOperationTotal'
	END
	
	return @@rowcount
END




GO
/****** Object:  StoredProcedure [dbo].[sp_sum_agent_inbound_info]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	计算坐席放弃数 转接数，应答数等
/*
Example:
exec sp_sum_agent_inbound_info @DateBegin,@DateEnd,@Agent
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_sum_agent_inbound_info]
	@DateBegin	datetime	= NULL,
	@DateEnd	datetime	= NULL,
	@Agent		NVARCHAR(50)	= NULL,
	@Type		char(1)		= NULL
	--1 平均时长 2放弃数 3应答数 4转移数 其他 总时长
	--5 呼入坐席在15秒振铃时长内的应答数
	--6 呼出数
AS 
BEGIN
	declare @duration int
	if (@Type = '1' ) begin
		
		--平均时长
		select @duration = sum(duration)/count(*) from 
		(
		select 
		(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
		,
		(datediff(s,startDateTime,endDateTime)) duration
		 from AgentConnectionDetail s
		where s.startDateTime between @DateBegin and @DateEnd 
		) m group by agent having  agent=@Agent
		
	end
	else if (@type = '2') begin
		--放弃数
			select @duration = count(*) from 
			(
			select 
			(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
			,
			(select contactDisposition from ContactCallDetail m 
				where  s.sessionID = m.sessionID  and s.nodeID = m.nodeID
						and s.profileID = m.profileID and m.sessionSeqNum = 0 ) contactDisposition
			 from AgentConnectionDetail s
			where s.startDateTime between @DateBegin and @DateEnd 
			) m group by agent,contactDisposition having contactDisposition=1 and agent=@Agent
			
	end
	else if (@type = '3') begin
	
		--应答数
		select @duration = count(*) from 
		(
		select 
		(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
		,
		(select contactDisposition from ContactCallDetail m 
			where  s.sessionID = m.sessionID  and s.nodeID = m.nodeID
					and s.profileID = m.profileID and m.sessionSeqNum = 0 ) contactDisposition
		 from AgentConnectionDetail s
		where s.startDateTime between @DateBegin and @DateEnd 
		) m group by agent,contactDisposition having contactDisposition=2 and agent=@Agent
		
	end
	
	else if (@type = '4') begin
		--转移数
		select @duration = count(*) from 
		(
		select 
		(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
		,
		(select transfer from ContactCallDetail m 
			where  s.sessionID = m.sessionID  and s.nodeID = m.nodeID
					and s.profileID = m.profileID and m.sessionSeqNum = 0 ) transfer
		 from AgentConnectionDetail s
		where s.startDateTime between @DateBegin and @DateEnd 
		) m group by agent,transfer having transfer=1 and agent=@Agent
	
	end
	else if (@type = '5') begin
	
		--呼入坐席在15秒振铃时长内的应答数
		select @duration = count(*) from 
		(
		select 
		(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
		,
		(select contactDisposition from ContactCallDetail m 
			where  s.sessionID = m.sessionID  and s.nodeID = m.nodeID
					and s.profileID = m.profileID and m.sessionSeqNum = 0 ) contactDisposition,
		ringtime
		 from AgentConnectionDetail s
		where s.startDateTime between @DateBegin and @DateEnd 
		) m where agent=@Agent and ringtime <=15 and contactDisposition=2
		
	end
	
	else if (@type = '6') begin
		--坐席呼出数
		select @duration = count(*)  from (
		select r.resourceLoginId as agent
				from dbo.ContactCallDetail m ,dbo.Resource r	
		where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1
		 and m.contacttype = 2 and m.destinationType = 3  and
		 m.startDateTime between @DateBegin and @DateEnd 
		 )  m where agent=@agent
	end
	else if (@type = '7') begin
		--坐席呼出总时长
		select @duration = sum(connectTime)  from (
		select r.resourceLoginId as agent,
				connectTime
				from dbo.ContactCallDetail m ,dbo.Resource r	
		where   m.originatorID = r.resourceID and m.profileID = r.profileID and m.originatorType = 1
		 and m.contacttype = 2 and m.destinationType = 3  and
		 m.startDateTime between @DateBegin and @DateEnd 
		 )  m where agent=@agent
	end
	else if (@type = '8') begin
		--坐席呼入通话时长
		select @duration = sum(talktime) from 
		(
		select 
		(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
		,
		talktime
		 from AgentConnectionDetail s
		where s.startDateTime between @DateBegin and @DateEnd 
		) m group by agent having  agent=@Agent
	end
	else begin 
		--总时长
		select @duration = sum(duration) from 
		(
		select 
		(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
		,
		(datediff(s,startDateTime,endDateTime)) duration
		 from AgentConnectionDetail s
		where s.startDateTime between @DateBegin and @DateEnd 
		) m group by agent having  agent=@Agent
	end
	
	RETURN @duration
END


select s.*,(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent from AgentConnectionDetail s where ringtime >15
GO
/****** Object:  StoredProcedure [dbo].[sp_sum_login_time]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	计算登陆时长
/*
Example:
exec sp_sum_login_time @DateBegin,@DateEnd,@Agent
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_sum_login_time]
	@DateBegin	datetime	= NULL,
	@DateEnd	datetime	= NULL,
	@Agent		NVARCHAR(50)	= NULL
AS 
BEGIN
	declare @left datetime
	declare @leftType int 
	declare @right datetime
	declare @rightType int 
	declare @duration int

	set @duration = 0
	create table #temp_login ( d datetime,t int)
	
	select top 1 @left = eventDateTime,@leftType = eventType from dbo.AgentStateDetail a  where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and eventDateTime <= @DateBegin and (eventType = 1 or eventType = 7)  order by eventDateTime desc
	
	select top 1 @right = eventDateTime,@rightType = eventType from dbo.AgentStateDetail a where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and eventDateTime >= @DateEnd and (eventType = 1 or eventType = 7)  order by eventDateTime asc
	
	If (@left IS NOT NULL) Begin 
		If (@leftType =1 ) insert into #temp_login values(@DateBegin,1)
	End
	
	insert into #temp_login select eventDateTime as d, eventType as t  from dbo.AgentStateDetail a where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and (eventDateTime >  @DateBegin and eventDateTime < @DateEnd) and (eventType = 1 or eventType = 7) order by eventDateTime asc
	
	
	If (@right IS NOT NULL) Begin
		If (@rightType =7 ) insert into #temp_login values(@DateEnd,7)
	End
	ELSE Begin
		select @rightType=t from #temp_login order by d desc
		If (@rightType = 1 ) insert into #temp_login values(@DateEnd,7)
	End

	--(select d,t,ROW_NUMBER() over(order by d) as row_num from #temp_login where t = 1) 
	--Union
	--(select d,t,ROW_NUMBER() over(order by d) as row_num from #temp_login where t = 7) 
	
	select @duration=SUM(datediff(S,l,r)) from 
	(select d as l,ROW_NUMBER() over(order by d) as row_num from #temp_login where t = 1) t1,
	(select d as r,ROW_NUMBER() over(order by d) as row_num from #temp_login where t = 7) t2
	where t1.row_num = t2.row_num
	drop table #temp_login
	
	set @duration=isnull(@duration,0)
	RETURN @duration
END

GO
/****** Object:  StoredProcedure [dbo].[sp_sum_notready_time]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	计算notready时长 或者次数
/*
Example:
exec [sp_sum_notready_time] @DateBegin,@DateEnd,@Agent
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_sum_notready_time]
	@DateBegin	datetime	= NULL,
	@DateEnd	datetime	= NULL,
	@Agent		NVARCHAR(50)	= NULL,
	@resoncode	int	= -1,
	@type		char(1) --1 times other duration
AS 
BEGIN

	declare @left datetime
	declare @leftType int 
	declare @leftCode smallint 
	declare @right datetime
	declare @rightType int 
	declare @rightCode smallint 
	declare @duration int
	set @duration=0
	create table #temp_notready ( d datetime,t int)
	
	select top 1 @left = eventDateTime,@leftType = (case when (eventType=2 and reasonCode = @resoncode) then 3 else 7 end) from dbo.AgentStateDetail a  where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and eventDateTime <= @DateBegin  order by eventDateTime desc
	
	--select top 1 @right = eventDateTime,@rightType = (case when eventType=3 then 3 else 7 end) from dbo.AgentStateDetail a where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and eventDateTime >= @DateEnd order by eventDateTime asc
	
	If (@left IS NOT NULL) Begin 
		If (@leftType =3 ) insert into #temp_notready values(@DateBegin,3)
	End
	
	--插入notready数据
	insert into #temp_notready select eventDateTime as d, 3 as t  from dbo.AgentStateDetail a 
		where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and 
			t.resourceID=a.agentID and a.profileID = t.profileID) and (eventDateTime >  @DateBegin and eventDateTime < @DateEnd) and eventType=2 and reasonCode = @resoncode order by eventDateTime asc
	
	if (@type = '1') begin 
		select @duration=count(1) from #temp_notready where t=3
		drop table #temp_notready
		RETURN @duration
	end
	
	;with cte0 as (
		select * from dbo.AgentStateDetail a
		where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and 
			t.resourceID=a.agentID and a.profileID = t.profileID) and (eventDateTime >  @DateBegin and eventDateTime < @DateEnd) 
	), cte1 as (
		select * from cte0 where eventType=2 and reasonCode = @resoncode
	), cte2 as (
		select * from cte0 where (eventType<>2) or (eventType=2 and reasonCode <> @resoncode)
	), cte3 as (
		select 
			(select top 1 b.eventDateTime from cte2 b where b.eventDateTime > a.eventDateTime order by b.eventDateTime asc ) as   eventDateTime
		from cte1 a --取 notready的下一挑数据
	)
	--插入notready 数据 
	insert into #temp_notready select eventDateTime as d, 7 as t  from cte2 where exists (select 1 from cte3 t where t.eventDateTime=cte2.eventDateTime)
	
	--最后一条是ready
	select @rightType=t from #temp_notready order by d desc
	If (@rightType = 3) insert into #temp_notready values(@DateEnd,7)

	/*(select d,t,ROW_NUMBER() over(order by d) as row_num from #temp_notready where t = 3) 
	Union
	(select d,t,ROW_NUMBER() over(order by d) as row_num from #temp_notready where t = 7) */
	

	select @duration=SUM(datediff(ss,l,r)) from 
		(select d as l,ROW_NUMBER() over(order by d) as row_num from #temp_notready where t = 3) t1,
		(select d as r,ROW_NUMBER() over(order by d) as row_num from #temp_notready where t = 7) t2
		where t1.row_num = t2.row_num
		
	drop table #temp_notready
	set @duration=isnull(@duration,0)
	RETURN @duration
END



GO
/****** Object:  StoredProcedure [dbo].[sp_sum_ready_time]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	计算ready时长
/*
Example:
exec sp_sum_ready_time @DateBegin,@DateEnd,@Agent
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_sum_ready_time]
	@DateBegin	datetime	= NULL,
	@DateEnd	datetime	= NULL,
	@Agent		NVARCHAR(50)	= NULL,
	@type		char(1) --1 times other duration
AS 
BEGIN

	declare @left datetime
	declare @leftType int 
	declare @right datetime
	declare @rightType int 
	declare @duration int
	set @duration=0
	create table #temp_ready ( d datetime,t int)
	
	select top 1 @left = eventDateTime,@leftType = (case when eventType=3 then 3 else 7 end) from dbo.AgentStateDetail a  where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and eventDateTime <= @DateBegin  order by eventDateTime desc
	
	--select top 1 @right = eventDateTime,@rightType = (case when eventType=3 then 3 else 7 end) from dbo.AgentStateDetail a where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and t.resourceID=a.agentID and a.profileID = t.profileID) and eventDateTime >= @DateEnd order by eventDateTime asc
	
	If (@left IS NOT NULL) Begin 
		If (@leftType =3 ) insert into #temp_ready values(@DateBegin,3)
	End
	
	--插入ready数据
	insert into #temp_ready select eventDateTime as d, 3 as t  from dbo.AgentStateDetail a 
		where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and 
			t.resourceID=a.agentID and a.profileID = t.profileID) and (eventDateTime >  @DateBegin and eventDateTime < @DateEnd) and eventtype=3 order by eventDateTime asc
			
	if (@type = '1') begin 
		select @duration=count(1) from #temp_ready where t=3
		drop table #temp_ready
		RETURN @duration
	end

	;with cte0 as (
		select * from dbo.AgentStateDetail a
		where exists (select 1 from dbo.Resource t where t.resourceLoginID=@Agent and 
			t.resourceID=a.agentID and a.profileID = t.profileID) and (eventDateTime >  @DateBegin and eventDateTime < @DateEnd) 
	), cte1 as (
		select * from cte0 where eventType =3 
	), cte2 as (
		select * from cte0 where eventType<>3 
	), cte3 as (
		select 
			(select top 1 b.eventDateTime from cte2 b where b.eventDateTime > a.eventDateTime order by b.eventDateTime asc ) as   eventDateTime
		from cte1 a --取 ready的下一挑数据
	)
	--插入非ready 数据 
	insert into #temp_ready select eventDateTime as d, 7 as t  from cte2 where exists (select 1 from cte3 t where t.eventDateTime=cte2.eventDateTime)
	
	--最后一条是ready
	select @rightType=t from #temp_ready order by d desc
	If (@rightType = 3) insert into #temp_ready values(@DateEnd,7)

	/*(select d,t,ROW_NUMBER() over(order by d) as row_num from #temp_ready where t = 3) 
	Union
	(select d,t,ROW_NUMBER() over(order by d) as row_num from #temp_ready where t = 7) */
	
	select @duration=SUM(datediff(ss,l,r)) from 
	(select d as l,ROW_NUMBER() over(order by d) as row_num from #temp_ready where t = 3) t1,
	(select d as r,ROW_NUMBER() over(order by d) as row_num from #temp_ready where t = 7) t2
	where t1.row_num = t2.row_num
	
	drop table #temp_ready
	set @duration=isnull(@duration,0)
	RETURN @duration
END

GO
/****** Object:  UserDefinedFunction [dbo].[avg_str]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--print '[' + dbo.avg_str(1, 6, 0) + ']'

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
/****** Object:  UserDefinedFunction [dbo].[int_date_week]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--返回日期所在周的第一天的日期
create  FUNCTION [dbo].[int_date_week] (@Date INT)
RETURNS INT AS
BEGIN 
	DECLARE	@DateTime DATETIME
	
	SET @DateTime = CAST(@Date AS VARCHAR(8))
	
	SET @DateTime = DATEADD(DAY, DATEPART(weekday, @DateTime)*(-1) + 1, @DateTime)
	
	SET @Date = YEAR(@DateTime) *10000 + MONTH(@DateTime)*100 + DAY(@DateTime)
	
	RETURN @Date
	
END

GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_time]    Script Date: 2016/9/5 16:46:42 ******/
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
/****** Object:  UserDefinedFunction [dbo].[sec_to_time]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--select [dbo].[sec_to_time](6522)
CREATE FUNCTION [dbo].[sec_to_time] (@time int )
RETURNS varchar(20) AS  
BEGIN 
	declare  @hour  int, @min int, @sec int, @retval varchar (20)
	
	select @sec = @time % 60, 	@time = @time / 60
	select @min = @time % 60, 	@time = @time / 60
	select @hour = @time, 	@retval = ''

	if @hour < 10 	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@hour)) + ':'
	if @min < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@min)) + ':'
	if @sec < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@sec)) 

	return @retval

END
GO
/****** Object:  UserDefinedFunction [dbo].[sum_login_time]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--print dbo.sum_login_time('agent',startime,endtime')


CREATE FUNCTION [dbo].[sum_login_time] (@agent varchar,@s datetime, @d datetime)
RETURNS int AS  
BEGIN
	declare @ledt datetime
	declare @let int 
	declare @redt datetime
	declare @ret int 
	declare @restime int
	
	select top 1 @ledt = eventDateTime , @let = eventType from dbo.AgentStateDetail where agentID= @agent and (eventDateTime between @s and @d) order by eventDateTime
	
	select top 1 @redt = eventDateTime , @ret = eventType from dbo.AgentStateDetail where agentID= @agent and (eventDateTime between @s and @d) order by eventDateTime	desc
	
	--select @restime = DATEDIFF(s,@ledt,@redt)
	
	If ( (@ledt IS NULL) AND (@redt IS NULL)) Begin 
		set @restime = 1
	End
	Else If ((@ledt IS NULL) AND (@redt IS NOT NULL) ) Begin
		set @restime = 2
	End
	Else If ((@ledt IS NOT NULL) AND (@redt IS NULL)) Begin
		set @restime = 3
	End
	Else Begin 
		set @restime = 4
	End
	return @restime
	
END

GO
/****** Object:  UserDefinedFunction [dbo].[week_series_to_str]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--print dbo.week_series_to_str('20050201', 0)
--print dbo.week_series_to_str('20050201', dbo.week_series('20050201', '20050209'))

CREATE FUNCTION [dbo].[week_series_to_str](@base_date datetime, @week_series int)
RETURNS varchar(18) AS  
BEGIN
	declare @begin_date int
	declare @tempDate datetime
	set @begin_date = dbo.int_date_week( convert(varchar(8), @base_date, 112) )
	set @tempDate = convert(datetime,cast(@begin_date  as varchar(8)),112) +6
	return cast(@begin_date as varchar(8))+ '～' + convert(varchar(8), @tempDate, 112) 
END
GO
/****** Object:  Table [dbo].[AgentConnectionDetail]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgentConnectionDetail](
	[sessionID] [decimal](18, 0) NOT NULL,
	[sessionSeqNum] [smallint] NOT NULL,
	[nodeID] [smallint] NOT NULL,
	[profileID] [int] NOT NULL,
	[resourceID] [int] NOT NULL,
	[startDateTime] [datetime] NOT NULL,
	[endDateTime] [datetime] NOT NULL,
	[qIndex] [tinyint] NOT NULL,
	[gmtOffset] [smallint] NOT NULL,
	[ringTime] [smallint] NULL,
	[talkTime] [smallint] NULL,
	[holdTime] [smallint] NULL,
	[workTime] [smallint] NULL,
	[callWrapupData] [nvarchar](40) NULL,
	[callResult] [smallint] NULL,
	[dialingListID] [int] NULL,
 CONSTRAINT [PK_AgentConnectionDetail] PRIMARY KEY NONCLUSTERED 
(
	[sessionID] ASC,
	[sessionSeqNum] ASC,
	[nodeID] ASC,
	[resourceID] ASC,
	[qIndex] ASC,
	[profileID] ASC,
	[startDateTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[AgentStateDetail]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AgentStateDetail](
	[agentID] [int] NOT NULL,
	[eventDateTime] [datetime] NOT NULL,
	[gmtOffset] [smallint] NOT NULL,
	[eventType] [tinyint] NOT NULL,
	[reasonCode] [smallint] NOT NULL,
	[profileID] [int] NOT NULL,
 CONSTRAINT [PK_AgentStatusDetail] PRIMARY KEY NONCLUSTERED 
(
	[agentID] ASC,
	[eventDateTime] ASC,
	[eventType] ASC,
	[reasonCode] ASC,
	[profileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ContactCallDetail]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ContactCallDetail](
	[sessionID] [decimal](18, 0) NOT NULL,
	[sessionSeqNum] [smallint] NOT NULL,
	[nodeID] [smallint] NOT NULL,
	[profileID] [int] NOT NULL,
	[contactType] [tinyint] NOT NULL,
	[contactDisposition] [tinyint] NOT NULL,
	[dispositionReason] [varchar](100) NULL,
	[originatorType] [tinyint] NOT NULL,
	[originatorID] [int] NULL,
	[originatorDN] [nvarchar](30) NULL,
	[destinationType] [tinyint] NULL,
	[destinationID] [int] NULL,
	[destinationDN] [nvarchar](30) NULL,
	[startDateTime] [datetime] NOT NULL,
	[endDateTime] [datetime] NOT NULL,
	[gmtOffset] [smallint] NOT NULL,
	[calledNumber] [nvarchar](30) NULL,
	[origCalledNumber] [nvarchar](30) NULL,
	[applicationTaskID] [decimal](18, 0) NULL,
	[applicationID] [int] NULL,
	[applicationName] [nvarchar](30) NULL,
	[connectTime] [smallint] NULL,
	[customVariable1] [varchar](40) NULL,
	[customVariable2] [varchar](40) NULL,
	[customVariable3] [varchar](40) NULL,
	[customVariable4] [varchar](40) NULL,
	[customVariable5] [varchar](40) NULL,
	[customVariable6] [varchar](40) NULL,
	[customVariable7] [varchar](40) NULL,
	[customVariable8] [varchar](40) NULL,
	[customVariable9] [varchar](40) NULL,
	[customVariable10] [varchar](40) NULL,
	[accountNumber] [varchar](40) NULL,
	[callerEnteredDigits] [varchar](40) NULL,
	[badCallTag] [char](1) NULL,
	[transfer] [bit] NULL,
	[redirect] [bit] NULL,
	[conference] [bit] NULL,
	[flowout] [bit] NULL,
	[metServiceLevel] [bit] NULL,
	[campaignID] [int] NULL,
	[OrigProtocolCallRef] [varchar](32) NULL,
	[DestProtocolCallRef] [varchar](32) NULL,
	[CallResult] [smallint] NULL,
	[dialinglistid] [int] NULL,
 CONSTRAINT [PK_ContactCallDetail] PRIMARY KEY NONCLUSTERED 
(
	[sessionID] ASC,
	[sessionSeqNum] ASC,
	[nodeID] ASC,
	[profileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ContactQueueDetail]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ContactQueueDetail](
	[sessionID] [decimal](18, 0) NOT NULL,
	[sessionSeqNum] [smallint] NOT NULL,
	[profileID] [int] NOT NULL,
	[nodeID] [smallint] NOT NULL,
	[targetID] [int] NOT NULL,
	[targetType] [tinyint] NOT NULL,
	[qIndex] [tinyint] NOT NULL,
	[queueOrder] [tinyint] NOT NULL,
	[disposition] [tinyint] NULL,
	[metServiceLevel] [bit] NULL,
	[queueTime] [smallint] NULL,
 CONSTRAINT [PK_ContactQueueDetail] PRIMARY KEY NONCLUSTERED 
(
	[sessionID] ASC,
	[sessionSeqNum] ASC,
	[nodeID] ASC,
	[profileID] ASC,
	[qIndex] ASC,
	[targetID] ASC,
	[targetType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_ag_w_total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_ag_w_total](
	[UserID] [nvarchar](50) NULL,
	[agent] [nvarchar](50) NULL,
	[agentName] [nvarchar](50) NULL,
	[period] [nvarchar](50) NULL,
	[beginTime] [nvarchar](50) NULL,
	[EndTime] [nvarchar](50) NULL,
	[segment] [nvarchar](50) NULL,
	[abandon] [nvarchar](50) NULL,
	[answer] [nvarchar](50) NULL,
	[transfer] [nvarchar](50) NULL,
	[avgInboundDuration] [nvarchar](50) NULL,
	[inboundTotalDuration] [nvarchar](50) NULL,
	[fifteenAnswerRate] [nvarchar](50) NULL,
	[speedAnswerRate] [nvarchar](50) NULL,
	[inboundTalkDuration] [nvarchar](50) NULL,
	[outbound] [nvarchar](50) NULL,
	[outboundDuration] [nvarchar](50) NULL,
	[acw] [nvarchar](50) NULL,
	[loginDuration] [nvarchar](50) NULL,
	[readyDuration] [nvarchar](50) NULL,
	[acwDuration] [nvarchar](50) NULL,
	[workFormTotal] [nvarchar](50) NULL,
	[firstSolveRate] [nvarchar](50) NULL,
	[secondSolveRate] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_Call_Inbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_Call_Inbound](
	[UserID] [nvarchar](50) NULL,
	[CallingID] [nvarchar](50) NULL,
	[CalledID] [nvarchar](50) NULL,
	[ExtensionNo] [nvarchar](50) NULL,
	[CallinDateTime] [nvarchar](50) NULL,
	[CallinTotalDuration] [nvarchar](50) NULL,
	[CallQueueDuration] [nvarchar](50) NULL,
	[CallRingDuration] [nvarchar](50) NULL,
	[CallResult] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_Call_Inbound_Total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_Call_Inbound_Total](
	[UserID] [nvarchar](50) NULL,
	[StaticLevel] [nvarchar](50) NULL,
	[Segment] [nvarchar](50) NULL,
	[Total] [nvarchar](50) NULL,
	[AnswerTotal] [nvarchar](50) NULL,
	[AnswerRate] [nvarchar](50) NULL,
	[AgentLostTotal] [nvarchar](50) NULL,
	[WaitLostTotal] [nvarchar](50) NULL,
	[AbandonTotal] [nvarchar](50) NULL,
	[LostRate] [nvarchar](50) NULL,
	[AverageAnswerTime] [nvarchar](50) NULL,
	[AverageHandleTime] [nvarchar](50) NULL,
	[AverageQueueTime] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_Call_LostTotal]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_Call_LostTotal](
	[UserID] [nvarchar](50) NULL,
	[segment] [nvarchar](50) NULL,
	[abandonTotal] [nvarchar](50) NULL,
	[fifLoss] [nvarchar](50) NULL,
	[thirtyLoss] [nvarchar](50) NULL,
	[sixLoss] [nvarchar](50) NULL,
	[eightLoss] [nvarchar](50) NULL,
	[overEightLoss] [nvarchar](50) NULL,
	[CalledNew] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_Call_Outbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_Call_Outbound](
	[UserID] [nvarchar](50) NULL,
	[Agent] [nvarchar](50) NULL,
	[RecordDateTime] [nvarchar](50) NULL,
	[CalledID] [nvarchar](50) NULL,
	[CallTotalTime] [nvarchar](50) NULL,
	[CallResult] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_CallTime_Analysis]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_CallTime_Analysis](
	[UserID] [nvarchar](50) NULL,
	[Segment] [nvarchar](50) NULL,
	[TotalAnswer] [nvarchar](50) NULL,
	[FifWaitTime] [nvarchar](50) NULL,
	[ThirtyWaitTime] [nvarchar](50) NULL,
	[SixWaitTime] [nvarchar](50) NULL,
	[EightWaitTime] [nvarchar](50) NULL,
	[OverEightWatiTime] [nvarchar](50) NULL,
	[MaxWaitTime] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[iReport_Se_Op_Total]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[iReport_Se_Op_Total](
	[UserID] [nvarchar](50) NULL,
	[period] [nvarchar](50) NULL,
	[segment] [nvarchar](50) NULL,
	[beginTime] [nvarchar](50) NULL,
	[endTime] [nvarchar](50) NULL,
	[inboundTotal] [nvarchar](50) NULL,
	[ivrLossTotal] [nvarchar](50) NULL,
	[toAgentTotal] [nvarchar](50) NULL,
	[agentAnswerTotal] [nvarchar](50) NULL,
	[agentAnswerRate] [nvarchar](50) NULL,
	[holdDuration] [nvarchar](50) NULL,
	[holdFrequency] [nvarchar](50) NULL,
	[avgHoldDuration] [nvarchar](50) NULL,
	[maxQueueTime] [nvarchar](50) NULL,
	[avgQueueTime] [nvarchar](50) NULL,
	[avgRingTime] [nvarchar](50) NULL,
	[avgInboundTalkDuration] [nvarchar](50) NULL,
	[avgAcwDuration] [nvarchar](50) NULL,
	[inboundAHT] [nvarchar](50) NULL,
	[agentOutboundTotal] [nvarchar](50) NULL,
	[outboundAvgTalkDuration] [nvarchar](50) NULL,
	[outboundAvgACWDuration] [nvarchar](50) NULL,
	[outboundDurationTotal] [nvarchar](50) NULL,
	[outboundAgentNumber] [nvarchar](50) NULL,
	[loginDurationTotal] [nvarchar](50) NULL,
	[readyNumber] [nvarchar](50) NULL,
	[acw] [nvarchar](50) NULL,
	[acwDuration] [nvarchar](50) NULL,
	[workFormTotal] [nvarchar](50) NULL,
	[firstSolveRate] [nvarchar](50) NULL,
	[secondSolveRate] [nvarchar](50) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Link_Table]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Link_Table](
	[Server] [varchar](16) NULL,
	[IP] [varchar](20) NULL,
	[UserName] [varchar](20) NULL,
	[Password] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Resource]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Resource](
	[resourceID] [int] NOT NULL,
	[profileID] [int] NOT NULL,
	[resourceLoginID] [nvarchar](50) NOT NULL,
	[resourceName] [nvarchar](50) NOT NULL,
	[resourceGroupID] [int] NULL,
	[resourceType] [tinyint] NOT NULL,
	[active] [bit] NOT NULL,
	[autoAvail] [bit] NOT NULL,
	[extension] [nvarchar](50) NOT NULL,
	[orderInRG] [int] NULL,
	[dateInactive] [datetime] NULL,
	[resourceSkillMapID] [int] NOT NULL,
	[assignedTeamID] [int] NOT NULL,
	[resourceFirstName] [nvarchar](50) NOT NULL,
	[resourceLastName] [nvarchar](50) NOT NULL,
 CONSTRAINT [PK_Resource] PRIMARY KEY NONCLUSTERED 
(
	[resourceID] ASC,
	[profileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ResourceGroup]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ResourceGroup](
	[resourceGroupID] [int] NOT NULL,
	[profileID] [int] NOT NULL,
	[resourceGroupName] [nvarchar](50) NULL,
	[active] [bit] NULL,
	[dateInactive] [datetime] NULL,
 CONSTRAINT [PK_ResourceGroup] PRIMARY KEY NONCLUSTERED 
(
	[resourceGroupID] ASC,
	[profileID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  View [dbo].[V_TimeSegment]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_TimeSegment]
AS
SELECT RIGHT(100 + number, 2) + ':00-' + RIGHT(100 + number, 2) +
               ':30' as segment,
               RIGHT(100 + number, 2) + ':00:01' sBegin,
               RIGHT(100 + number, 2) + ':30:00' sEnd
          FROM master.dbo.spt_values
         WHERE type = 'P'
           AND number < 24
           AND number >= 0
        union
        SELECT RIGHT(100 + number, 2) + ':30-' + RIGHT(100 + number + 1, 2) +
               ':00' as segment,
               RIGHT(100 + number, 2) + ':30:01' sBegin,
               (case when RIGHT(100 + number + 1, 2) = 24 then '23:59:59' else 
               RIGHT(100 + number + 1, 2) + ':00:00'
               end)
                sEnd
          FROM master.dbo.spt_values
         WHERE type = 'P'
           AND number < 24
           AND number >= 0

GO
/****** Object:  View [dbo].[V_CallInbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_CallInbound]
AS
SELECT     m.startDateTime, CONVERT(varchar(10), m.startDateTime, 23) AS sTime, CONVERT(varchar(4), m.startDateTime, 23) AS sYear, CONVERT(varchar(7), m.startDateTime, 
                      23) AS sMonth, dbo.week_series_to_str(m.startDateTime, 0) AS sWeek,
                          (SELECT     segment
                            FROM          dbo.V_TimeSegment AS vt
                            WHERE      (CONVERT(varchar(12), m.startDateTime, 108) BETWEEN sBegin AND sEnd)) AS segment, m.contactDisposition,
                          (SELECT     TOP (1) queueTime
                            FROM          dbo.ContactQueueDetail AS s
                            WHERE      (sessionID = m.sessionID) AND (nodeID = m.nodeID) AND (profileID = m.profileID) AND (sessionSeqNum = 0)) AS queuetime, s.ringTime, s.holdTime, 
                      s.talkTime, s.workTime, s.resourceID, s.profileID, m.customvariable1,
			(select resourceLoginID from resource r where s.resourceID = r.resourceID and s.profileID = r.profileID ) as agent
			,(datediff(s,s.startDateTime,s.endDateTime)) callDuration,transfer
FROM         dbo.ContactCallDetail AS m LEFT OUTER JOIN
                      dbo.AgentConnectionDetail AS s ON s.sessionID = m.sessionID AND s.nodeID = m.nodeID AND s.profileID = m.profileID AND 
                      s.sessionSeqNum = m.sessionSeqNum
WHERE     (m.contactType = 1) AND (m.originatorType = 3) AND (m.sessionSeqNum = 0)

GO
/****** Object:  View [dbo].[V_CallOutbound]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE VIEW [dbo].[V_CallOutbound]
AS
select m.startDateTime, CONVERT(varchar(10), m.startDateTime, 23) as sTime,
               CONVERT(varchar(4), m.startDateTime, 23) as sYear		,
				CONVERT(varchar(7), m.startDateTime, 23) as sMonth,
				dbo.week_series_to_str(m.startDateTime,0) as sWeek,
               (select segment  from dbo.V_Timesegment vt where CONVERT(varchar(12), m.startDateTime, 108) between vt.sBegin and vt.sEnd) as segment,
               contactDisposition,
               (select top 1 queuetime from ContactQueueDetail s 
								where s.sessionID = m.sessionID 
									and s.nodeID = m.nodeID
									and s.profileID = m.profileID
									and s.sessionSeqNum = 0) as queuetime,
               s.ringtime,s.holdtime,
               s.talktime,s.worktime,
               r.resourceLoginId as agent,r.resourceName as agentName,
               connectTime
          from ContactCallDetail m 
			left join dbo.Resource r
			on
			m.originatorID = r.resourceID 
			and m.profileID = r.profileID 
			left join AgentConnectionDetail s 
			on
			 s.sessionID = m.sessionID 
			and s.nodeID = m.nodeID
			and s.profileID = m.profileID
			and s.sessionSeqNum = 0
         where ( m.sessionSeqNum = 0 and m.originatorType = 1  and m.contacttype = 2  and m.destinationType = 3  ) 





GO
/****** Object:  View [dbo].[V_AgentStateBase]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_AgentStateBase]
AS
 
select  (select resourceLoginID from resource r where a.agentID = r.resourceID and a.profileID = r.profileID ) as agent, eventtype,eventDateTime from  dbo.AgentStateDetail a  


GO
/****** Object:  View [dbo].[V_AgentState]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[V_AgentState]
AS
 
select  agent, eventtype,eventDateTime 
		,
		isnull((case when eventtype = 1 then 
					( select top 1 eventDateTime from  dbo.V_AgentStateBase b  where  b.agent=a.agent and b.eventDateTime > a.eventDateTime and ( b.eventtype=7 or b.eventtype=1 ) order by eventDateTime)  
				else   
					( select top 1 eventDateTime from  dbo.V_AgentStateBase b  where  b.agent=a.agent and b.eventDateTime > a.eventDateTime  order by eventDateTime)  
				 end ),getdate())
		 as nextTime
		 , CONVERT(varchar(10), eventDateTime, 23) AS sTime, CONVERT(varchar(4),eventDateTime, 23) AS sYear, 
			CONVERT(varchar(7), eventDateTime, 23) AS sMonth, dbo.week_series_to_str(eventDateTime, 0) AS sWeek,
                          (SELECT     segment
                            FROM          dbo.V_TimeSegment AS vt
                            WHERE      (CONVERT(varchar(12), eventDateTime, 108) BETWEEN sBegin AND sEnd)) AS segment 
		from  dbo.V_AgentStateBase a where a.eventtype = 1 or a.eventtype = 3 or a.eventtype = 6
 

GO
/****** Object:  View [dbo].[V_Agent]    Script Date: 2016/9/5 16:46:42 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW [dbo].[V_Agent]
AS
SELECT     resourceLoginID AS agent, RTRIM(LTRIM(resourceName)) AS agentName
FROM         dbo.Resource
GROUP BY resourceLoginID, RTRIM(LTRIM(resourceName))

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
         Begin Table = "Resource"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 217
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
      Begin ColumnWidths = 12
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Agent'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_Agent'
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_TimeSegment'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_TimeSegment'
GO
