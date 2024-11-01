USE [master]
GO
CREATE DATABASE [vxi_chat]
GO

USE [vxi_chat]
GO
/****** Object:  StoredProcedure [dbo].[sp_agent_login_total]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:		<SHUAIMENG.SUN@vxichina.com>
-- Create date: <2013.08.05>
-- Description:	访问来源统计报表
--exec [dbo].[sp_agent_login_total] @DateBegin=20110101 ,@DateEnd = 20130809,@Preload=0,@Agent='1000'
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_agent_login_total]
	@DateBegin	NVARCHAR(10) =NULL,
	@DateEnd	NVARCHAR(10)  =NULL,
	@Agent		NVARCHAR(50)= NULL,
	@Preload	BIT = 0				-- 仅预览表标题
AS
BEGIN

 	;WITH cte as(
				  SELECT [LogID] ,[Agent],[Skills],[Finish],[Flag] ,[StartTime],
					(case when ( convert(varchar(10),endTime,120) > convert(varchar(10),[StartTime],120) ) then
						datediff(ss,starttime, dateadd(day,1, convert(datetime,convert(varchar(10),[StartTime],120),120))  )
						else isnull([TimeLen]/1000,datediff(ss,starttime,getdate())) end)as timelen 
					
					,[EndTime] ,[ReadyLen],[cause]
				  FROM [vxi_chat].[dbo].[Login] 
				  where  agent = case when len(@Agent) > 0 then @Agent else agent end
						AND convert(varchar(8),[StartTime],112) between @DateBegin and @DateEnd
		)
		 select convert(varchar(10),[StartTime],120) startdt,agent,min(StartTime) ftime,max(endTime) etime,sum(timelen) tlen,
sum(case when ReadyLen <0 then 0 else ReadyLen end)/1000 ReadyLen from cte group by agent, convert(varchar(10),[StartTime],120)

END

GO
/****** Object:  StoredProcedure [dbo].[sp_agent_work_total]    Script Date: 2016/9/5 13:35:12 ******/
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
exec [sp_agent_work_total] @SDateBegin='2013-01-14'
					,@SDateEnd='2013-06-14',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_agent_work_total]
	@DateBegin	NVARCHAR(10) =NULL,
	@DateEnd		NVARCHAR(10)  =NULL,
	@TimeBegin		NVARCHAR(10)	=NULL,
	@TimeEnd		NVARCHAR(10)	=NULL, 
	@Agent		NVARCHAR(50)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
	@Preload	BIT = 0				-- 仅预览表标题
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	declare @tempCount			int
	
	declare @SDateBegin	NVARCHAR(10)
	declare @SDateEnd	NVARCHAR(10)
	declare @STimeBegin	NVARCHAR(10)
	declare @STimeEnd	NVARCHAR(10) 
	
	
	set @SDateBegin = convert(varchar(10),convert(datetime,@DateBegin,112),120) 
	set @SDateEnd =   convert(varchar(10),convert(datetime,@DateEnd,112),120) 

	--select @TimeBegin = @TimeBegin / 100,@TimeEnd = @TimeEnd / 100

	IF (@TimeBegin is null) begin
		set @STimeBegin='00:00'
	end
	else begin 
		set @TimeBegin = right('000000'+ cast(@TimeBegin as varchar(6)),6)
		set @STimeBegin = SUBSTRING(@TimeBegin,1,2) + ':' + SUBSTRING(@TimeBegin,3,2)
	end
	IF (@TimeEnd is null) begin
		set @STimeEnd='23:59'
	end
	else begin 
		set @TimeEnd = right('000000'+ cast(@TimeEnd as varchar(6)),6)
		set @STimeEnd = SUBSTRING(@TimeEnd,1,2) + ':' + SUBSTRING(@TimeEnd,3,2)
	end

	--select @TimeBegin,@TimeEnd,@STimeBegin,@STimeEnd
	
	create table #T_AgentChatTotal(
		period					varchar(30),	--周期
		segment					varchar(20),	--时间段
		beginTime				datetime	,	--start
		endTime					datetime	,	--end time segment
		
		agent					varchar(50),	--坐席工号	
		agentName				varchar(50),	--坐席名称	
		firstTime				float,
		avgTime					float,
		chatTotal				int,
		answerTotal				int,
		customerAbandon			int,
		agentAbandon			int,
		answerRate				varchar(10),
		sixtyTotal				int,
		sixtyRate				varchar(10),
		aht						int,
		loginDuration			int			--总登录时长	该坐席的总登录时长
	)
	
	set @strSql = ' insert into #T_AgentChatTotal '
	declare @date1 datetime,@date2 datetime
	set @date1 = @SDateBegin
	set @date2 = @SDateEnd
	
	create table #t_chat_period (period varchar(20),beginTime datetime,endTime datetime)
	
	--周期特性 小时
	if ( lower(@GroupLevel) = 'hour' ) begin 
		ALTER TABLE #t_chat_period ADD segment varchar(20)
		--select @STimeBegin,@STimeEnd
		insert into #t_chat_period 
			--select * from (
			select  period, CONVERT(datetime,period + ' ' + sBegin, 120) as beginTime, CONVERT(datetime,period + ' ' + sEnd, 120)  as endTime,segment
			from (
				select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m ,V_HourSegment t where t.segment between @STimeBegin and @STimeEnd
			--) 
			--p where 
			--exists ( select 1 from dbo.sdr r where r.sdrtime between p.begintime and p.endtime )
			
		update #t_chat_period	 set beginTime = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin + ':00', 120) where beginTime = (select min(beginTime) from #t_chat_period) 	
		update #t_chat_period	 set endTime = dateadd(mi,1,CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120) ) where endTime = (select max(endTime) from #t_chat_period) 
		--select * from #t_chat_period
		--set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime,segment) SELECT top 500 agent ,agentName,period,beginTime,endTime,segment FROM [dbo].[V_Agent] a,#t_chat_period p '
	end
	
	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		insert into #t_chat_period 
			select  convert(varchar(7),dateadd(mm,number,@date1),120) as period,
				dateadd(ss,0,dateadd(mm,number,@date1)) as beginTime,dateadd(ss,0,dateadd(mm,number+1,@date1)) as  endTime
			from master..spt_values where type='p' and number <= datediff(mm,@date1,@date2)
		
		update #t_chat_period	 set beginTime = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin + ':00', 120) where beginTime = (select min(beginTime) from #t_chat_period) 	
		update #t_chat_period	 set endTime = dateadd(mi,1,CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120) ) where endTime = (select max(endTime) from #t_chat_period) 
		--select * from #t_chat_period
		--set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT top 500 agent ,agentName,period,beginTime,endTime FROM [dbo].[V_Agent] a,#t_chat_period p '
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		insert into #t_chat_period 

			select distinct dbo.week_series_to_str(dateadd(dd,number,@date1),0) as period,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ),112) as starttime,
				convert(datetime,cast( dbo.int_date_week (convert(varchar(8), dateadd(dd,number,@date1), 112)) as varchar(8) ),112) +7 as endtime
			 from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			 
		update #t_chat_period	 set beginTime = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin + ':00', 120) where beginTime = (select min(beginTime) from #t_chat_period) 	
		update #t_chat_period	 set endTime = dateadd(mi,1,CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120) ) where endTime = (select max(endTime) from #t_chat_period) 
		--select * from #t_chat_period
		
		--set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime) SELECT top 500 agent ,agentName,period,beginTime,endTime FROM [dbo].[V_Agent] a,#t_chat_period p '
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		insert into #t_chat_period 
			select period, CONVERT(datetime,period + '-01-01 00:00:00', 120) as beginTime, 
			dateadd(year,1 ,CONVERT(datetime,period + '-01-01 00:00:00', 120))as endTime
			from (
			select [period]=convert(varchar(4),dateadd(yy,number,@date1),120) from master..spt_values where type='p' and number <= datediff(yy,@date1,@date2)
			) m
		--更新开始时间 结束时间
		update #t_chat_period	 set beginTime = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin + ':00', 120) where beginTime = (select min(beginTime) from #t_chat_period) 	
		update #t_chat_period	 set endTime = dateadd(mi,1,CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120) ) where endTime = (select max(endTime) from #t_chat_period) 
		
		--select * from #t_chat_period
		--set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT top 500 agent ,agentName,period,beginTime,endTime FROM [dbo].[V_Agent] a,#t_chat_period p '
	end
	--周期特性 日
	else begin 
		insert into #t_chat_period 
			
			select period, CONVERT(datetime,period + ' 00:00:00', 120) as beginTime, dateadd(day,1 ,CONVERT(datetime,period + ' 00:00:00', 120) )  as endTime
			from (
			select [period]=convert(varchar(10),dateadd(dd,number,@date1),120) from master..spt_values where type='p' and number <= datediff(dd,@date1,@date2)
			) m
		update #t_chat_period	 set beginTime = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin + ':00', 120) where beginTime = (select min(beginTime) from #t_chat_period) 	
		update #t_chat_period	 set endTime = dateadd(mi,1,CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120) ) where endTime = (select max(endTime) from #t_chat_period) 
		--SELECT * FROM [dbo].[V_Agent] a,#t_chat_period p
		--set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT  top 500 agent ,agentName,period,beginTime,endTime FROM [dbo].[V_Agent] a,#t_chat_period p '
	end
	
	
	if ( lower(@GroupLevel) = 'hour' ) begin 
		set @strSql = @strSql + ' (agent ,agentName,period,beginTime,endTime,segment) SELECT top 2000 agent ,agentName,period,beginTime,endTime,segment FROM [dbo].[V_Agent] a,#t_chat_period p  '
	end
	else begin 
		set @strSql = @strSql +  ' (agent ,agentName,period,beginTime,endTime) SELECT  top 2000 agent ,agentName,period,beginTime,endTime FROM [dbo].[V_Agent] a,#t_chat_period p '
	end
	
	if (len(@agent) > 0) set @strSql = @strSql + ' where agent = ''' + @agent + ''''
	
	EXECUTE(@strSQL)
	--select *  from #T_AgentChatTotal
	
	select @tempCount = count(*) from #T_AgentChatTotal  where 0=(@Preload)
	--判断有数据 计算 登陆时长
	
	if (@tempCount > 0 ) begin
		
		declare @calcResponseTimeCount int
		exec @calcResponseTimeCount = dbo.[sp_response_time]
		print 'calc reponse time ' + cast(@calcResponseTimeCount as  varchar) +' row'
		
		declare @tempAgent			nvarchar(50)
		declare @tempStartTime		datetime
		declare @tempEndTime		datetime
		declare @tempFirstTime		float
		declare @tempAvgTime		float
		declare @tempchatTotal				int
		declare @tempanswerTotal				int
		declare @tempcustomerAbandon			int
		declare @tempagentAbandon			int
		declare @tempSixtyTotal int
		declare @tempLoginDruation int
		declare @temphandleDuration bigint
		
	   DECLARE tracetime CURSOR FOR
	   select agent,beginTime,endTime from #T_AgentChatTotal
	   OPEN tracetime
	   FETCH NEXT FROM tracetime INTO @tempAgent,@tempStartTime,@tempEndTime
			WHILE (@@FETCH_STATUS=0)
			BEGIN
			--1 平均时长 2放弃数 3应答数 4转移数 其他 总时长
				--计算时长  
			   exec @tempLoginDruation  = dbo.sp_sum_login_time	    @tempStartTime,@tempEndTime,@tempAgent
			   select 
			   @tempFirstTime =  dbo.avg_str( sum(isnull(firstTime,0)),count(1)*1000,0),
			   @tempAvgTime  = dbo.avg_str( sum(isnull(avgTime,0)),count(1)*1000,0),
			   @tempchatTotal = count(1),
			   @tempanswerTotal = count(case when agentMsgCount>0 then 1 end),
			   @tempagentAbandon = count(case when agentMsgCount=0 and msgCount>0 then 1 end),
			   @tempcustomerAbandon = count(case when (agentMsgCount = msgCount)  then 1 end),
			   @tempSixtyTotal =  count(case when (agentMsgCount>0 and firstTime <= 60000)  then 1 end),
			   @temphandleDuration = sum(isnull(onEnd,0))/count(1)/1000
			    from v_sdr_new where agent=@tempAgent and sdrtime >= @tempStartTime and sdrtime < @tempEndTime
				
				if (@tempchatTotal>0 and @tempLoginDruation < @temphandleDuration) begin
					set @tempLoginDruation = @temphandleDuration
				end
				
				update #T_AgentChatTotal set firstTime=@tempFirstTime,avgTime=@tempAvgTime		,
				chatTotal=@tempchatTotal,answerTotal=@tempanswerTotal,agentAbandon=@tempagentAbandon,
				customerAbandon = @tempcustomerAbandon,answerRate = dbo.avg_str(@tempanswerTotal,@tempchatTotal,1)
				,sixtyTotal = @tempSixtyTotal,sixtyRate=dbo.avg_str(@tempSixtyTotal,@tempanswerTotal,1)
				,loginDuration = @tempLoginDruation,
				aht =@temphandleDuration
			   where agent = @tempAgent and beginTime = @tempStartTime and endTime = @tempEndTime
			FETCH NEXT FROM tracetime INTO @tempAgent,@tempStartTime,@tempEndTime
			END
		CLOSE tracetime
		DEALLOCATE tracetime    
		
	end
	
	--select * from #T_AgentChatTotal where chatTotal > 0 
	set @strSQL = '
	;with cte0 as (
		select period as dt ,answerTotal as sc ,
				loginDuration as st ,
				agent,
				
				period as wn,
				begintime as bwn ,
				dateadd(ss,-1,endtime) as ewn,
				segment as time1 ,
				chatTotal as tc,
				aht as at ,
				firstTime as aft,
				answerRate as re,
				sixtyRate as ser,
				avgTime as art,
				sixtyTotal as ssc,
				customerAbandon as kc,
				agentAbandon,
				row_number() over(order by period,agent) as row_num
	 from #T_AgentChatTotal where chatTotal > 0 
	 union 
	 select ''Total'' as dt,sum(answerTotal) as sc ,
				sum(loginDuration) as st ,
				NULL as agent ,
				NULL as wn,
				NULL as bwn ,
				NULL as ewn,
				NULL as time1 ,
				sum(chatTotal) as tc,
				sum(aht)/count(1) as at ,
				dbo.avg_str(sum(firstTime),count(1),0) as aft,
				dbo.avg_str(sum(answerTotal),sum(chatTotal),1) as re,
				dbo.avg_str(sum(sixtyTotal),sum(answerTotal),1) as ser,
				dbo.avg_str(sum(avgTime),count(1),0) as art,
				sum(sixtyTotal) as ssc,
				sum(customerAbandon) as kc,
				sum(agentAbandon) as agentAbandon,
				' + str(@tempCount+1) + ' as row_num
	 from #T_AgentChatTotal where chatTotal > 0 
	)
	'
	select @Preload = isnull(@Preload,1)
	
	if ( lower(@GroupLevel) = 'hour' ) begin 
		set @strSQL = @strSQL + ' select dt,time1,agent,tc,sc,re,at,aft,art,ser,ssc,st,kc,agentAbandon  from cte0 m where 0='  + str(@Preload)+ ' order by row_num '
	end
	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		set @strSQL = @strSQL + ' select dt,agent,tc,sc,re,at,aft,art,ser,ssc,st,kc,agentAbandon  from cte0 m where 0='  + str(@Preload)+ ' order by row_num '
	end
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		set @strSQL = @strSQL + ' select dt,agent,tc,sc,re,at,aft,art,ser,ssc,st,kc,agentAbandon  from cte0 m  where 0='  + str(@Preload)+ ' order by row_num '
	end
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		set @strSQL = @strSQL + ' select dt,agent,tc,sc,re,at,aft,art,ser,ssc,st,kc,agentAbandon  from cte0 m  where 0='  + str(@Preload)+ ' order by row_num '
	end
	--周期特性 日
	else begin 
		set @strSQL = @strSQL + ' select dt,agent,tc,sc,re,at,aft,art,ser,ssc,st,kc,agentAbandon  from cte0 m  where 0='  + str(@Preload)+ ' order by row_num '
	end
	--print @strSQL
	EXECUTE(@strSQL)
		
	IF OBJECT_ID('tempdb..#t_chat_period') IS NOT NULL BEGIN
		DROP TABLE #t_chat_period
		PRINT 'delete temp table #t_chat_period'
	END
	
	IF OBJECT_ID('tempdb..#T_AgentChatTotal') IS NOT NULL BEGIN
		DROP TABLE #T_AgentChatTotal
		PRINT 'delete temp table #T_AgentChatTotal'
	END
	return @@rowcount
END



GO
/****** Object:  StoredProcedure [dbo].[sp_agent_work_url_total]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.08.05>
-- Description:	chat 坐席 访问 来源 统计报表
/*
Example:
exec [sp_agent_work_url_total] @DateBegin='20130114'
					,@DateEnd='20130814',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_agent_work_url_total]
	@DateBegin	NVARCHAR(10) =NULL,
	@DateEnd		NVARCHAR(10)  =NULL,
	@TimeBegin		NVARCHAR(10)	=NULL,
	@TimeEnd		NVARCHAR(10)	=NULL, 
	@Agent		NVARCHAR(50)	= NULL,
	@GroupLevel	NVARCHAR(10)	= NULL,
	@urlName	NVARCHAR(50)	=NULL, 
	@Preload	BIT = 0				-- 仅预览表标题
AS 
BEGIN
	declare @strSql				NVARCHAR(MAX)
	declare @tempCount			int
	
	declare @SDateBegin	NVARCHAR(10)
	declare @SDateEnd	NVARCHAR(10)
	declare @STimeBegin	NVARCHAR(10)
	declare @STimeEnd	NVARCHAR(12) 
	
	set @urlName = isnull(@urlName,'')
	set @Agent = isnull(@Agent,'')
	
	if (@DateBegin is null or len(@DateBegin) =0) begin
		set @SDateBegin = convert(varchar(10),getdate(),120) 
	end else begin
		set @SDateBegin = convert(varchar(10),convert(datetime,@DateBegin,112),120) 
	end
	if (@DateEnd is null or len(@DateEnd) =0) begin
		set @SDateEnd = convert(varchar(10),getdate(),120) 
	end else begin
		set @SDateEnd =   convert(varchar(10),convert(datetime,@DateEnd,112),120) 
	end

	--select @TimeBegin = @TimeBegin / 100,@TimeEnd = @TimeEnd / 100

	IF (@TimeBegin is null or len(@TimeBegin) =0) begin
		set @STimeBegin='00:00:00'
	end
	else begin 
		set @TimeBegin = right('000000'+ cast(@TimeBegin as varchar(6)),6)
		set @STimeBegin = SUBSTRING(@TimeBegin,1,2) + ':' + SUBSTRING(@TimeBegin,3,2) + ':' + SUBSTRING(@TimeEnd,5,2)
	end
	IF (@TimeEnd is null or len(@TimeEnd) =0) begin
		set @STimeEnd='23:59:59.998'
	end
	else begin 
		set @TimeEnd = right('000000'+ cast(@TimeEnd as varchar(6)),6)
		set @STimeEnd = SUBSTRING(@TimeEnd,1,2) + ':' + SUBSTRING(@TimeEnd,3,2)+ ':' + SUBSTRING(@TimeEnd,5,2)
		if (SUBSTRING(@TimeEnd,5,2)=59) begin
		set @STimeEnd = @STimeEnd + '.998'
		end
	end
	

	declare @calcResponseTimeCount int
	exec @calcResponseTimeCount = dbo.[sp_response_time]
	print 'calc reponse time ' + cast(@calcResponseTimeCount as  varchar) +' row'	
	
	declare @startTime datetime
	declare @endTime datetime

	set @startTime = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin  , 120)
	set @endTime = CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120)
	--select @SDateBegin,@STimeBegin,@SDateEnd,@STimeEnd,@startTime,@endTime
	;with a as (
		select 
		convert(varchar(10),sdrtime,120) period
		,v.segment as segment
		,CONVERT(datetime,convert(varchar(10),sdrtime,120) + ' ' + v.sBegin, 120) as beginTime
		,CONVERT(datetime,convert(varchar(10),sdrtime,120) + ' ' + v.sEnd + '.998' , 120) as endTime
		,agent
		,urlName
		,firstTime
		,avgTime
		,agentMsgCount
		,msgCount
		,n.onEnd
		 from dbo.V_SDR_NEW n , dbo.V_HourSegment v where (CONVERT(varchar(12), n.sdrtime, 108) BETWEEN v.sBegin AND v.sEnd )
		and n.sdrtime between @startTime and @endTime and @Preload=0 and (len(@urlName)=0 or  @urlName=n.urlName  )
		and (len(@agent)=0 or  @agent=n.agent  )
	), b as (
		select 
		distinct 
		CONVERT(datetime,convert(varchar(10),sdrtime,120) + ' ' + v.sBegin, 120) as beginTime
		,CONVERT(datetime,convert(varchar(10),sdrtime,120) + ' ' + v.sEnd + '.998' , 120) as endTime
		,agent
		,convert(varchar(10),sdrtime,120) period
		,v.segment as segment
		 from dbo.V_SDR_NEW n , dbo.V_HourSegment v where (CONVERT(varchar(12), n.sdrtime, 108) BETWEEN v.sBegin AND v.sEnd )
		and n.sdrtime between @startTime and @endTime and @Preload=0 and  (len(@urlName)=0 or  @urlName=n.urlName  )
		and (len(@agent)=0 or  @agent=n.agent  )
	) , c as (
		SELECT   
			t.agent ,t.period,t.segment,
			sum(case 
			when (f.StartTime < t.beginTime and f.EndTime < t.endTime and f.EndTime > t.begintime)   then  datediff(ms,t.beginTime,f.EndTime)
			when (f.StartTime > t.beginTime and f.EndTime > t.endTime and f.StartTime < t.endtime)   then  datediff(ms,f.StartTime,t.endTime)
			when (f.StartTime >= t.beginTime and f.EndTime <= t.endTime) then  datediff(ms,f.StartTime,f.EndTime)
			when (f.StartTime < t.beginTime and f.EndTime > t.endTime  ) then  datediff(ms,t.beginTime,t.endTime)
			else 0 end )/1000 as loginduration
		FROM b as  t, vxi_chat.dbo.Login f
		where (t.agent = f.agent ) and 
			( (f.StartTime < t.beginTime and f.EndTime < t.endTime and f.EndTime > t.begintime) or
			  (f.StartTime > t.beginTime and f.EndTime > t.endTime and f.StartTime < t.endtime) or
			  (f.StartTime >= t.beginTime and f.EndTime <= t.endTime) or
			  (f.StartTime < t.beginTime and f.EndTime > t.endTime))
		group by t.agent ,t.period,t.segment
	) ,d as (
		select 
		agent,
		urlName,
		period dt,
		segment time1,
		count(1) tc,
		count(case when agentMsgCount>0 then 1 end) sc,
		sum(isnull(onEnd,0))/count(1)/1000 at,
		dbo.avg_str( sum(isnull(firstTime,0)),count(1)*1000,0) as aft,
		sum(isnull(firstTime,0))/count(1)/1000 as  firstTime,
		dbo.avg_str(count(case when agentMsgCount>0 then 1 end),count(1),1) re,
		dbo.avg_str(count(case when (agentMsgCount>0 and firstTime <= 60000)  then 1 end),count(case when agentMsgCount>0 then 1 end),1) as ser,
		dbo.avg_str( sum(isnull(avgTime,0)),count(1)*1000,0) art,
		sum(isnull(avgTime,0))/count(1)/1000 as  avgTime,
		count(case when (agentMsgCount>0 and firstTime <= 60000)  then 1 end) as ssc,
		count(case when (agentMsgCount = msgCount)  then 1 end) as kc,
		count(case when agentMsgCount=0 and msgCount>0 then 1 end) agentAbandon,
		isnull((select loginduration from c where a.agent=c.agent and a.period = c.period and a.segment=c.segment),0) as st
		from a group by agent,period,segment,urlName
	)
	select dt,sc,st,agent,urlName,time1,tc,at,aft,re,ser,art,ssc,kc,agentAbandon from d
	union 
	select 'Total' as dt,sum(sc) as sc ,
				sum(st) as st ,
				'' as agent ,
				'' as urlName,
				'' as time1,
				sum(tc) as tc,
				sum(at)/count(1) as at ,
				dbo.avg_str(sum(firstTime),count(1),0) as aft,
				dbo.avg_str(sum(sc),sum(tc),1) as re,
				dbo.avg_str(sum(ssc),sum(sc),1) as ser,
				dbo.avg_str(sum(avgTime),count(1),0) as art,
				sum(ssc) as ssc,
				sum(kc) as kc,
				sum(agentAbandon) as agentAbandon
	from d
	
--exec [sp_agent_work_url_total] @DateBegin='20130701' ,@DateEnd='20130814' ,@TimeBegin=130000 ,@TimeEnd=235900 ,@urlName='',@agent='1000'
	
	return @@rowcount
END




GO
/****** Object:  StoredProcedure [dbo].[sp_calc_avg_response_time]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	计算首次响应时间，平均响应时间
/*
Example:
exec sp_calc_avg_response_time @DateBegin,@DateEnd,@Agent
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_calc_avg_response_time]
	@Sdrid bigint = 0
AS 
BEGIN
	declare @FirstResponse int
	declare @AvgRepsonse int
	declare @temp_count int
	create table #t_avg_time(
		type smallint,
		subid bigint,
		sTime datetime,
		num int,
		row_num int
	)
	;with cte1 as (
		select * from dbo.SDRTrace s where sdrid=@Sdrid and 
		
		not exists (select 1 from dbo.V_agent a where s.account = a.agent)
	), cte2 as (
		select c1.subid ,sTime
		,(select top 1 c1.subid-c2.subid from cte1 c2 where c2.sTime<c1.sTime 
		and c2.subid < c1.subid order by c2.sTime desc) as preSeque
		from cte1 c1 
	),cte3 as (
		select subid,preseque,sTime,
		(select top 1 subid from cte2 d where d.subid>c.subid and isnull(d.preSeque,0)<>1) as  nextseQue
		
		from cte2 c where isnull(preSeque,0)<>1
	),cte4 as (
		select subid,preseque,sTime,
		isnull((select count(*) from cte2 where preSeque=1 and cte2.subid >cte3.subid and cte2.subid < cte3.nextseQue),0)+1
		as isEqual
		 from cte3 
	)
	insert into #t_avg_time select 3 type,subid,sTime,isEqual as num,ROW_NUMBER() over(order by subid) as row_num from cte4 
	
	;with cte_a1 as (
		select * from dbo.SDRTrace s where sdrid=@Sdrid and 
		exists (select 1 from dbo.V_agent a where s.account = a.agent)
	), cte_a2 as (
		select c1.subid ,sTime
		,(select top 1 c1.subid-c2.subid from cte_a1 c2 where c2.sTime<c1.sTime 
		and c2.subid < c1.subid order by c2.sTime desc) as preSeque
		from cte_a1 c1 
	)
	insert into #t_avg_time select 1 type,subid,sTime,1 num,ROW_NUMBER() over(order by subid) as row_num from cte_a2 where isnull(preSeQue,0) <>1

	select @FirstResponse=(datediff(ms,t1.sTime,t2.sTime)/t1.num) from 
	(select sTime,num,row_num from #t_avg_time where type=3) t1,
	(select sTime,row_num from #t_avg_time where type=1) t2
	where t1.row_num = 1 and t2.row_num =1
	
	--select @FirstResponse ,@AvgRepsonse
	
	
	
	select @FirstResponse=isnull(@FirstResponse,0)
	if (@FirstResponse is not null and @FirstResponse < 0) begin
		--select SDRTime from dbo.SDR where sdrid=@Sdrid
		--select sTime from #t_avg_time where type=1 and row_num=1
		
		set @FirstResponse = 0
		/*
		datediff(ms,
		(select SDRTime from dbo.SDR where sdrid=@Sdrid),
		(select sTime from #t_avg_time where type=1 and row_num=1)
		)
		*/
		declare @myTempCount int
			
		select @AvgRepsonse=sum((abs(datediff(ms,t1.sTime,t2.sTime))/t1.num)),@myTempCount=count(t1.row_num)  from 
		(select sTime,num,row_num from #t_avg_time where type=3) t1,
		(select sTime,(row_num-1) as row_num2 from #t_avg_time where type=1) t2
		where t1.row_num = t2.row_num2
		
		set @AvgRepsonse = (@AvgRepsonse + @FirstResponse)/ (@myTempCount +1)
		--set @FirstResponse = 0
		
	end 
	else begin
		select @AvgRepsonse=sum((abs(datediff(ms,t1.sTime,t2.sTime))/t1.num))/count(t1.row_num)  from 
		(select sTime,num,row_num from #t_avg_time where type=3) t1,
		(select sTime,row_num from #t_avg_time where type=1) t2
		where t1.row_num = t2.row_num
	end
	
	select @AvgRepsonse=isnull(@AvgRepsonse,0)
	
	DROP TABLE #t_avg_time
	

	select @temp_count=count(1) from dbo.sdrinfo where sdrid=@Sdrid
	if(@temp_count >=1) begin
		update dbo.sdrinfo set firstTime = @FirstResponse,avgTime=@AvgRepsonse,onCalc=1 where sdrid=@Sdrid
	end
	
	else begin
		insert into dbo.sdrinfo (sdrid,firstTime,avgTime,onCalc) values(@Sdrid,@FirstResponse,@AvgRepsonse,1)
	end
	
	IF OBJECT_ID('tempdb..#t_avg_time') IS NOT NULL BEGIN
		DROP TABLE #t_avg_time
		PRINT 'delete temp table #t_avg_time'
	END
	return @FirstResponse
END



GO
/****** Object:  StoredProcedure [dbo].[sp_chat_hm_total]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2014.07.25>
-- Description:	chat HM 工作统计报表
-- exec [dbo].[sp_chat_hm_total] @DateBegin	=20140924, @DateEnd=20140924 ,@grouplevel='hour'
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_chat_hm_total]
	@DateBegin	NVARCHAR(10) =NULL,
	@DateEnd		NVARCHAR(10)  =NULL,
	@TimeBegin		NVARCHAR(10)	=NULL,
	@TimeEnd		NVARCHAR(10)	=NULL, 
	@GroupLevel	NVARCHAR(10)	= NULL,
	@Preload	BIT = 0				-- 仅预览表标题
AS
BEGIN
	declare @strSql				VARCHAR(max)
	declare @strSql2				VARCHAR(max)
	declare @strGroup			NVARCHAR(30)
	declare @strColumn			NVARCHAR(30)
	
	declare @SDateBegin	NVARCHAR(10)
	declare @SDateEnd	NVARCHAR(10)
	declare @STimeBegin	NVARCHAR(10)
	declare @STimeEnd	NVARCHAR(10) 
	
	
	set @SDateBegin = convert(varchar(10),convert(datetime,@DateBegin,112),120) 
	set @SDateEnd =   convert(varchar(10),convert(datetime,@DateEnd,112),120) 

	--select @TimeBegin = @TimeBegin / 100,@TimeEnd = @TimeEnd / 100

	IF (@TimeBegin is null) begin
		set @STimeBegin='00:00'
	end
	else begin 
		set @TimeBegin = right('000000'+ cast(@TimeBegin as varchar(6)),6)
		set @STimeBegin = SUBSTRING(@TimeBegin,1,2) + ':' + SUBSTRING(@TimeBegin,3,2)
	end
	IF (@TimeEnd is null) begin
		set @STimeEnd='23:59'
	end
	else begin 
		set @TimeEnd = right('000000'+ cast(@TimeEnd as varchar(6)),6)
		set @STimeEnd = SUBSTRING(@TimeEnd,1,2) + ':' + SUBSTRING(@TimeEnd,3,2)
	end

	declare @date1 datetime,@date2 datetime
	set @date1 = @SDateBegin
	set @date2 = @SDateEnd
	
	set @date1 = CONVERT(datetime,@SDateBegin + ' ' + @STimeBegin  , 120)
	set @date2 = CONVERT(datetime,@SDateEnd + ' ' + @STimeEnd , 120)


	--周期特性 小时
	if ( lower(@GroupLevel) = 'hour' ) begin 
		set @strGroup = ' sTime,segment '
		set @strColumn = ' sTime as period,segment '
	end
	
	--周期特性 月
	else if ( lower(@GroupLevel) = 'month' ) begin 
		set @strGroup = ' sMonth '
		set @strColumn = ' sMonth as period '
	end
	
	--周期特性 周
	else if ( lower(@GroupLevel) = 'week' ) begin 
		set @strGroup = ' sWeek '
		set @strColumn = ' sWeek as period '
	end
	
	--周期特性 年
	else if ( lower(@GroupLevel) = 'year' ) begin 
		set @strGroup = ' sYear '
		set @strColumn = ' sYear as period '
	end
	--周期特性 日
	else begin 
		set @strGroup = ' sTime '
		set @strColumn = ' sTime as period '
	end
	 --set @strSql = ';with k as (select	s.SDRTime as viatime, CONVERT(varchar(10), s.SDRTime, 23) AS sTime, CONVERT(varchar(4), s.SDRTime, 23) AS sYear, CONVERT(varchar(7), s.SDRTime, 23) AS sMonth, dbo.week_series_to_str(s.SDRTime, 0) AS sWeek,(SELECT     segment  FROM  dbo.V_HourSegment AS vt  WHERE  (CONVERT(varchar(12), s.SDRTime, 108) BETWEEN sBegin AND sEnd)) AS segment,isnull((datediff(s,s.SDRTime,(select stime from ( select  ROW_NUMBER() OVER(order by subid ) as row_num,stime  from  dbo.sdrtrace st where st.sdrid = s.sdrid and  (account) in (select agent from dbo.users) ) sdrtraceTemp where row_num = 2) )),isnull(s.onEnd,0)/1000) waittime,(case when s.agentMsgCount=1 and s.onEnd > 5000 then 1 else 0 end) as abandoned,(case when s.agentMsgCount<>1 and s.onEnd > 5000  then 1 else 0 end) as  answered,isnull(s.onEnd,0)/1000 as HT,s.agentMsgCount,s.msgCount,isnull(hs.surveyed,0) surveyed,(case when hs.score4=4 or hs.score4=5 then 1 else 0 end) as CsiNumber,(case when hs.score2=9 or hs.score2=10 then 1 else 0 end) as Nps1,(case when hs.score2>=0 and hs.score2<=6 then 1 else 0 end) as Nps2,isnull(hs.score3,0) as Fcr1, isnull(hs.score3,0) as Fcr2 ,(case when hs.score1 = 1 then 1 else 0 end) as Q1_YES,(case when hs.score1 = 0 then 1 else 0 end) as Q1_NO,(case when hs.score3 = 1 then 1 else 0 end) as Q2_YES,(case when hs.score3 = 0 then 1 else 0 end) as Q2_NO,(case when hs.score2 = 0 then 1 else 0 end) as Q3_OPT0,(case when hs.score2 = 1 then 1 else 0 end) as Q3_OPT1,(case when hs.score2 = 2 then 1 else 0 end) as Q3_OPT2,(case when hs.score2 = 3 then 1 else 0 end) as Q3_OPT3,(case when hs.score2 = 4 then 1 else 0 end) as Q3_OPT4,(case when hs.score2 = 5 then 1 else 0 end) as Q3_OPT5,(case when hs.score2 = 6 then 1 else 0 end) as Q3_OPT6,(case when hs.score2 = 7 then 1 else 0 end) as Q3_OPT7,(case when hs.score2 = 8 then 1 else 0 end) as Q3_OPT8,(case when hs.score2 = 9 then 1 else 0 end) as Q3_OPT9,(case when hs.score2 = 10 then 1 else 0 end) as Q3_OPT10 from dbo.V_SDR_NEW s  left join dbo.HmSurvey hs on hs.sdrid = s.sdrid where   0=' + convert(varchar(1),@Preload) +' and convert(varchar(20),s.SDRTime,120) between ''' + convert(varchar(20),@date1,120) +''' and ''' +  convert(varchar(20),@date2,120) +''')select ' + @strColumn + ',TotalChatReceived,TotalChatAnswered,TotalAnsweredIn60,dbo.avg_str(TotalAnsweredIn60,TotalChatReceived,1) SLA,(case when TotalChatAnswered=0 then 0 else  ( TotalWaittime/TotalChatAnswered ) end)  AWT,TotalAbandoned,dbo.avg_str(TotalAbandoned,TotalChatReceived,1)AbandonedRate ,(case when TotalChatAnswered=0 then 0 else ( TotalHT/TotalChatAnswered ) end) AHT,dbo.avg_str(TotalChatAnswered,TotalChatReceived,1)AnswerRate,NumberofAbandonedFive,TotalSurveyed,dbo.avg_str(TotalCsi,TotalSurveyed,1) CSI,(case when TotalSurveyed=0 then '''' else dbo.avg_str(TotalNps1-TotalNps2,TotalSurveyed,1)  end) NPS,dbo.avg_str(TotalFcr1,TotalFcr2,1) FCR,Q1_YES,Q1_NO,Q2_YES,Q2_NO,Q3_OPT0,Q3_OPT1,Q3_OPT2,Q3_OPT3,Q3_OPT4,Q3_OPT5,Q3_OPT6,Q3_OPT7,Q3_OPT8,Q3_OPT9,Q3_OPT10 from (select ' + @strGroup + ',(sum(answered) + sum(abandoned)) TotalChatReceived,sum(answered) as TotalChatAnswered ,sum(case when answered=1 and waittime<=60 then 1 else 0 end) as TotalAnsweredIn60,sum(case when abandoned=1 or answered=1  then waittime else 0 end) TotalWaittime,sum(abandoned) TotalAbandoned,sum(HT) as TotalHT,sum(case when abandoned=0 and answered=0  and waittime<=5 then 1 else 0 end) as NumberofAbandonedFive,sum(surveyed/1) as TotalSurveyed,sum(CsiNumber) as TotalCsi,sum(Nps1) as TotalNps1,sum(Nps2) as TotalNps2,sum(Fcr1) as TotalFcr1,sum(Fcr2) as TotalFcr2,sum(Q1_YES) as Q1_YES,sum(Q1_NO) as Q1_NO,sum(Q2_YES) as Q2_YES,sum(Q2_NO) as Q2_NO,sum(Q3_OPT0) as Q3_OPT0,sum(Q3_OPT1) as Q3_OPT1,sum(Q3_OPT2) as Q3_OPT2,sum(Q3_OPT3) as Q3_OPT3,sum(Q3_OPT4) as Q3_OPT4,sum(Q3_OPT5) as Q3_OPT5,sum(Q3_OPT6) as Q3_OPT6,sum(Q3_OPT7) as Q3_OPT7,sum(Q3_OPT8) as Q3_OPT8,sum(Q3_OPT9) as Q3_OPT9,sum(Q3_OPT10) as Q3_OPT10 from k group by ' + @strGroup + ') temp'

	 SET @strSql =
		';with k as (select	s.SDRTime as viatime, CONVERT(varchar(10), s.SDRTime, 23) AS sTime, CONVERT(varchar(4), s.SDRTime, 23) AS sYear, CONVERT(varchar(7), s.SDRTime, 23) AS sMonth, dbo.week_series_to_str(s.SDRTime, 0) AS sWeek,(SELECT     segment  FROM  dbo.V_HourSegment AS vt  WHERE  (CONVERT(varchar(12), s.SDRTime, 108) BETWEEN sBegin AND sEnd)) AS segment,isnull((datediff(s,s.SDRTime,(select stime from ( select  ROW_NUMBER() OVER(order by subid ) as row_num,stime  from  dbo.sdrtrace st where st.sdrid = s.sdrid and  (account) in (select agent from dbo.users) ) sdrtraceTemp where row_num = 2) )),isnull(s.onEnd,0)/1000) waittime,(case when s.agentMsgCount=1 and s.onEnd > 5000 then 1 else 0 end) as abandoned,(case when s.agentMsgCount<>1 and s.onEnd > 5000  then 1 else 0 end) as  answered,isnull(s.onEnd,0)/1000 as HT,s.agentMsgCount,s.msgCount,isnull(hs.surveyed,0) surveyed,(case when hs.score4=4 or hs.score4=5 then 1 else 0 end) as CsiNumber,(case when hs.score2=9 or hs.score2=10 then 1 else 0 end) as Nps1,(case when hs.score2>=0 and hs.score2<=6 then 1 else 0 end) as Nps2,(CASE WHEN hs.score1 = 1 AND hs.score3=1 THEN 1 ELSE 0 END) AS Fcr1, isnull(hs.score3,0) as Fcr2 ,(case when hs.score1 = 1 then 1 else 0 end) as Q1_YES,(case when hs.score1 = 0 then 1 else 0 end) as Q1_NO,(case when hs.score3 = 1 then 1 else 0 end) as Q2_YES,(case when hs.score3 = 0 then 1 else 0 end) as Q2_NO,(case when hs.score2 = 0 then 1 else 0 end) as Q3_OPT0,(case when hs.score2 = 1 then 1 else 0 end) as Q3_OPT1,(case when hs.score2 = 2 then 1 else 0 end) as Q3_OPT2,(case when hs.score2 = 3 then 1 else 0 end) as Q3_OPT3,(case when hs.score2 = 4 then 1 else 0 end) as Q3_OPT4,(case when hs.score2 = 5 then 1 else 0 end) as Q3_OPT5,(case when hs.score2 = 6 then 1 else 0 end) as Q3_OPT6,(case when hs.score2 = 7 then 1 else 0 end) as Q3_OPT7,(case when hs.score2 = 8 then 1 else 0 end) as Q3_OPT8,(case when hs.score2 = 9 then 1 else 0 end) as Q3_OPT9,(case when hs.score2 = 10 then 1 else 0 end) as Q3_OPT10,(CASE WHEN hs.score4 = 5 THEN 1 ELSE 0 END) AS Q4_SCORE5 ,(CASE WHEN hs.score4 = 4 THEN 1 ELSE 0 END) AS Q4_SCORE4,(CASE WHEN hs.score4 = 3 THEN 1 ELSE 0 END) AS Q4_SCORE3,(CASE WHEN hs.score4 = 2 THEN 1 ELSE 0 END) AS Q4_SCORE2,(CASE WHEN hs.score4 = 1 THEN 1 ELSE 0 END) AS Q4_SCORE1 from dbo.V_SDR_NEW s  left join dbo.HmSurvey hs on hs.sdrid = s.sdrid where   0='
		+ CONVERT(VARCHAR(1), @Preload)
		+ ' and convert(varchar(20),s.SDRTime,120) between '''
		+ CONVERT(VARCHAR(20), @date1, 120)
		+ ''' and '''
		+ CONVERT(VARCHAR(20), @date2, 120)
		
set @strSql2 =  ''')select ' + @strColumn
	+ ',TotalChatReceived,TotalChatAnswered,TotalAnsweredIn60,dbo.avg_str(TotalAnsweredIn60,TotalChatReceived,1) SLA,(case when TotalChatAnswered=0 then 0 else  ( TotalWaittime/TotalChatAnswered ) end)  AWT,TotalAbandoned,dbo.avg_str(TotalAbandoned,TotalChatReceived,1)AbandonedRate ,(case when TotalChatAnswered=0 then 0 else ( TotalHT/TotalChatAnswered ) end) AHT,dbo.avg_str(TotalChatAnswered,TotalChatReceived,1)AnswerRate,NumberofAbandonedFive,TotalSurveyed,dbo.avg_str(TotalCsi,TotalSurveyed,1) CSI,(case when TotalSurveyed=0 then '''' else dbo.avg_str(TotalNps1-TotalNps2,TotalSurveyed,1)  end) NPS,dbo.avg_str(TotalFcr1,TotalFcr2,1) FCR,Q1_YES,Q1_NO,Q2_YES,Q2_NO,Q3_OPT0,Q3_OPT1,Q3_OPT2,Q3_OPT3,Q3_OPT4,Q3_OPT5,Q3_OPT6,Q3_OPT7,Q3_OPT8,Q3_OPT9,Q3_OPT10,Q4_SCORE5,Q4_SCORE4,Q4_SCORE3,Q4_SCORE2,Q4_SCORE1 from (select '
	+ @strGroup
	+
	',(sum(answered) + sum(abandoned)) TotalChatReceived,sum(answered) as TotalChatAnswered ,sum(case when answered=1 and waittime<=60 then 1 else 0 end) as TotalAnsweredIn60,sum(case when abandoned=1 or answered=1  then waittime else 0 end) TotalWaittime,sum(abandoned) TotalAbandoned,sum(HT) as TotalHT,sum(case when abandoned=0 and answered=0  and waittime<=5 then 1 else 0 end) as NumberofAbandonedFive,sum(surveyed/1) as TotalSurveyed,sum(CsiNumber) as TotalCsi,sum(Nps1) as TotalNps1,sum(Nps2) as TotalNps2,sum(Fcr1) as TotalFcr1,sum(Fcr2) as TotalFcr2,sum(Q1_YES) as Q1_YES,sum(Q1_NO) as Q1_NO,sum(Q2_YES) as Q2_YES,sum(Q2_NO) as Q2_NO,sum(Q3_OPT0) as Q3_OPT0,sum(Q3_OPT1) as Q3_OPT1,sum(Q3_OPT2) as Q3_OPT2,sum(Q3_OPT3) as Q3_OPT3,sum(Q3_OPT4) as Q3_OPT4,sum(Q3_OPT5) as Q3_OPT5,sum(Q3_OPT6) as Q3_OPT6,sum(Q3_OPT7) as Q3_OPT7,sum(Q3_OPT8) as Q3_OPT8,sum(Q3_OPT9) as Q3_OPT9,sum(Q3_OPT10) as Q3_OPT10,Sum(Q4_SCORE5) AS Q4_SCORE5,Sum(Q4_SCORE4) AS Q4_SCORE4,Sum(Q4_SCORE3) AS Q4_SCORE3,Sum(Q4_SCORE2) AS Q4_SCORE2,Sum(Q4_SCORE1) AS Q4_SCORE1 from k group by '
	+ @strGroup + ') temp'
	
--print(@strSql + @strSql2)
	execute (@strSql + @strSql2)
	/*
;with k as (

         select s.SDRTime as viatime, 

      CONVERT(varchar(10), s.SDRTime, 23) AS sTime, 

      CONVERT(varchar(4), s.SDRTime, 23) AS sYear, 

      CONVERT(varchar(7), s.SDRTime, 23) AS sMonth, 

      dbo.week_series_to_str(s.SDRTime, 0) AS sWeek,

        (SELECT     segment  FROM  dbo.V_HourSegment AS vt  WHERE  (CONVERT(varchar(12), s.SDRTime, 108) BETWEEN sBegin AND sEnd)) AS segment

       ,

            isnull((datediff(s,s.SDRTime,(select stime from ( select  ROW_NUMBER() OVER(order by subid ) as row_num,stime  from  dbo.sdrtrace st where st.sdrid = s.sdrid and  (account) in (select agent from dbo.users) ) sdrtraceTemp where row_num = 2) )),isnull(s.onEnd,0)/1000) waittime,

      (case when s.agentMsgCount=1 and s.onEnd > 5000 then 1 else 0 end) as abandoned,

      (case when s.agentMsgCount<>1 and s.onEnd > 5000  then 1 else 0 end) as  answered

      ,isnull(s.onEnd,0)/1000 as HT,

      s.agentMsgCount,s.msgCount,

      isnull(hs.surveyed,0) surveyed,

      (case when hs.score4=4 or hs.score4=5 then 1 else 0 end) as CsiNumber,

      (case when hs.score2=9 or hs.score2=10 then 1 else 0 end) as Nps1,

      (case when hs.score2>=0 and hs.score2<=6 then 1 else 0 end) as Nps2,

      isnull(hs.score3,0) as Fcr1, isnull(hs.score3,0) as Fcr2 

       from dbo.V_SDR_NEW s  

      left join dbo.HmSurvey hs on hs.sdrid = s.sdrid

      where   convert(varchar(20),s.SDRTime,120) between '2014-09-05 00:00:00' and '2014-09-05 23:59:00'

 

   )

   select 

       sTime as period,segment ,TotalChatReceived,TotalChatAnswered,TotalAnsweredIn60,

      dbo.avg_str(TotalAnsweredIn60,TotalChatReceived,1) SLA,

      (case when TotalChatAnswered=0 then 0 else  ( TotalWaittime/TotalChatAnswered ) end)  AWT,

      TotalAbandoned,

      dbo.avg_str(TotalAbandoned,TotalChatReceived,1)AbandonedRate ,

     (case when TotalChatAnswered=0 then 0 else ( TotalHT/TotalChatAnswered ) end) AHT, 

      dbo.avg_str(TotalChatAnswered,TotalChatReceived,1)AnswerRate,

      NumberofAbandonedFive,

      TotalSurveyed,

      dbo.avg_str(TotalCsi,TotalSurveyed,1) CSI,

      (case when TotalSurveyed=0 then 0 else ((TotalNps1/TotalSurveyed)-(TotalNps2/TotalSurveyed))  end) NPS,

      dbo.avg_str(TotalFcr1,TotalFcr2,1) FCR

    from (

      select 

          sTime,segment ,

         (sum(answered) + sum(abandoned)) TotalChatReceived,

         sum(answered) as TotalChatAnswered ,

         sum(case when answered=1 and waittime<=60 then 1 else 0 end) as TotalAnsweredIn60,

         sum(case when abandoned=1 or answered=1  then waittime else 0 end) TotalWaittime,

         sum(abandoned) TotalAbandoned

         ,sum(HT) as TotalHT,

         sum(case when abandoned=0 and answered=0  and waittime<=5 then 1 else 0 end) as NumberofAbandonedFive,

         sum(surveyed/1) as TotalSurveyed,

         sum(CsiNumber) as TotalCsi,

         sum(Nps1) as TotalNps1,

         sum(Nps2) as TotalNps2,

         sum(Fcr1) as TotalFcr1,

         sum(Fcr2) as TotalFcr2

      from k group by  sTime,segment 

   ) temp

*/
	/*
	Example:
	exec [sp_chat_hm_total] @DateBegin='20130714' ,@DateEnd='20141129',@GroupLevel= 'hour' | 'day'| 'week' | 'month' | 'year' 
	Quality Report (Daily, Monthly)
	CSI: (VERY PLEASED-ANSVERED+ PLEASED-ANSVERED)/ TOTAL survey answered
	NPS Chat: (the number of ( 9 +10))/ total surveyed chat – ( the number of (0,1,2,3,4,5,6))/ total surveyed answered
	FCR Chat: the number of ‘Yes’ to question 1 and Question 2 / the number of ‘Yes’ to question 2.
	问题1与问题2的回答都是YES的个数/问题2的回答是YES的个数

	*/
	return @@rowcount
END



GO
/****** Object:  StoredProcedure [dbo].[sp_chat_log_old]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Description: 聊天记录统计
-- Test: 
--	EXEC  [sp_chat_log_new]	 @DateBegin = 20110425 , @DateEnd = 20130426,@GroupLevel = 'hour',@TimeBegin='003000' ,@TimeEnd='235900'
--	EXEC  [sp_chat_log_new]  @DateBegin = 20120101 ,@GroupLevel = 'month'
--	EXEC  [sp_chat_log_new]  @GroupLevel = 'year'
--	EXEC  [sp_chat_log_new]	 @GroupLevel = 'week'		---error
--	EXEC  [sp_chat_log_new]  @GroupLevel = 'month',@agent=''
--	EXEC  [sp_chat_log2]	 @DateBegin = 20130529 , @DateEnd = 20130529,@GroupLevel = 'day'
--	EXEC  [sp_chat_log_new]	 @DateBegin = 20130626 , @DateEnd = 20130626,@GroupLevel = 'hour', @agent='1001'	---error
-- =============================================
CREATE  PROCEDURE  [dbo].[sp_chat_log_old]
	@DateBegin	INT = NULL,
	@DateEnd	INT = NULL,
	@TimeBegin	INT = 0,
	@TimeEnd	INT = 2359, 
	@Agent		VARCHAR(500) = NULL,
	@GroupLevel NVARCHAR(32) = NULL, --Hourly/Daily/Weekly/Monthly/Yearly 时段/日/周/月/年
	@Preload	BIT = 0				-- 仅预览表标题
AS		
	DECLARE @Error INT
BEGIN	
	SET @Error = 0
	SET NOCOUNT ON
	
	SET @Preload = ISNULL(@Preload, 1)
	
	if @Agent='' BEGIN
		set @Agent=null
	END	
	if @GroupLevel='' BEGIN
		set @GroupLevel=null
	END	
	set @GroupLevel = isnull(@GroupLevel, 'day')
	
	
	IF @GroupLevel IS NULL OR @GroupLevel NOT IN('hour', 'day', 'week', 'month', 'year') BEGIN
		RAISERROR('The value of @GroupLevel[%s] must in Hourly/Daily/Weekly/Monthly/Yearly', -1, -1, @GroupLevel)
		SET @Error = -1
		GOTO ERROR_END
	END
	
	select @TimeBegin = @TimeBegin / 100,
			@TimeEnd = @TimeEnd / 100
		
	IF ((NOT @TimeBegin >= 0) OR (NOT @TimeEnd <= 2359) OR (NOT @TimeBegin <= @TimeEnd))
		SELECT @TimeBegin = 0, @TimeEnd = 2359		
----------------------------时报表
	BEGIN TRY	
		IF @GroupLevel = 'hour' BEGIN
			;WITH cte0 as(
				SELECT RIGHT(100+number,2)+':00-'+RIGHT(100+number,2)+':30' as time1,
							RIGHT(100+number,2)+':00:01' time2,
							RIGHT(100+number,2)+':30:00' time3
							FROM master.dbo.spt_values
						   WHERE type = 'P'  AND number < 24 AND number >=0
					  union
						   SELECT RIGHT(100+number,2)+':30-'+RIGHT(100+number+1,2)+':00' as time1,
							RIGHT(100+number,2)+':30:01' time2,
							RIGHT(100+number+1,2)+':00:00' time3
						   FROM master.dbo.spt_values
						   WHERE type = 'P'  AND number < 24 AND number >=0
			),cte1 AS(
					select sdrid,agent,CONVERT(VARCHAR(8),sdrtime,112) dt,sdrtime,F.time1 from 
						(select sdrid,agent,sdrtime from V_SDRWork 
							where CONVERT(VARCHAR(8),sdrtime,112)  between CONVERT(datetime,STR(@DateBegin),120) and CONVERT(datetime,STR(@DateEnd),120) 
						 )A
						inner join cte0 F on CONVERT(varchar(12),sdrtime,108) between F.time2 and F.time3
			), cte2 AS(		--坐席，日期，接待总数，在线时长,首次平均响应时长
					select dt,time1,agent,count(sdrid) sc,sum(t1) st,avg(t2) aft
					from( SELECT A.sdrid,A.agent,B.t2,datediff(s,sdrtime,tst) t1,dt,time1 FROM cte1 A
						  inner join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 is not null
					) tt group by agent,dt,time1	
			),cte3 as(		--会话总数
					 select count(sdrid)tc,dt,time1,agent from cte1 group by agent,dt,time1
			),cte4 as(		--某个时段内每个坐席60秒内接起的电话总量
					--select count(sdrid) ssc,agent,dt,time1
					--from( SELECT A.sdrid,B.t2,agent,dt,time1 FROM cte1 A
					--	  inner join
					--	  V_FirstTime B on A.sdrid=B.sdrid 
					--	  where t2 <=60 and t2 is not null
					--) tt group by agent,dt,time1
					
				select BB.agent,isnull(AA.ssc,0) ssc,BB.dt,BB.time1 from 
				(
				 select count(sdrid) ssc,agent,dt,time1
					from( SELECT A.sdrid,B.t2,agent,dt,time1 FROM	cte1 A
						  inner join
						V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 <=60 and t2 is not null 
					) tt group by agent,dt,time1
				)AA right join 
				( select agent,dt,time1 from cte1 group by agent,dt,time1 ) BB
				on AA.agent=BB.agent
			),cte5 as(		--某时段内每个坐席的平均响应时间
				select outter1.agent,CONVERT(VARCHAR(8),outter1.sdrtime,112) dt,sum(art1)/count(agent)art,outter1.time1
				from (select AA.agent,AA.sdrtime,AA.time1,BB.art1
					from  cte1 AA left join
							(select A.sdrid,sum(A.t)/count(A.sdrid) art1 from 
										(select outter.sdrid,outter.subid,min(outter.tim) t from
												(select a.sdrid,a.stime atime,b.stime btime,b.subid,abs(datediff(s,a.stime,b.stime))tim
												 from	(select sdrid,stime,subid,account from sdrtrace where account in (select agent from vxi_sys..agent)) a
														,(select sdrid,stime,subid,account from sdrtrace where  account not in (select agent from vxi_sys..agent)) b
												where a.sdrid=b.sdrid and a.subid>b.subid
											)outter
											group by outter.subid,outter.sdrid 
							)A GROUP BY A.sdrid) BB
						on AA.sdrid=BB.sdrid
						)outter1
				group by agent,CONVERT(VARCHAR(8),outter1.sdrtime,112),time1
			),
			 cte AS(
				select outter.dt,outter.time1,outter.agent,outter.tc,outter.sc,outter.re,outter.at,outter.aft,outter.art,outter.svclevel,outter.st,outter.ssc,outter.kc
				from(
				select A.dt			--日期
					,A.time1		--日期
					,A.agent		--坐席
					,B.tc			--chat总量
					,A.sc			--接起量
					,ROUND(CAST(A.sc AS FLOAT)/B.tc, 2) re --回复率
					,A.st/B.tc   at --平均处理时间
					,A.aft			--首次平均响应时长
					,D.art			--平均响应时间
					,ROUND(CAST(C.ssc AS FLOAT)/A.sc, 2) svclevel --服务水平
					,A.st			--在线时长
					,C.ssc			--60内接起量
					,(B.tc-A.sc) kc --客户放弃数，未应答数
					from cte2 A,cte3 B,cte4 C,cte5 D
					WHERE A.agent=B.agent
					and	A.agent=C.agent
					and	A.agent=D.agent
					and A.dt=B.dt
					and A.dt=C.dt
					and A.dt=D.dt
					and A.time1=B.time1
					and A.time1=C.time1
					and A.time1=D.time1
					)outter
					where  @Preload = 0 
					AND ISNULL(outter.agent, '') = ISNULL(@Agent, ISNULL(outter.agent, ''))
					AND replace(left(outter.time1,5),':','')>@TimeBegin
					AND replace(right(outter.time1,5),':','')<@TimeEnd
			)
			SELECT  dt,time1,agent,tc,sc,re,at,aft,art,svclevel,ssc,st,kc  FROM cte 
 UNION ALL
			SELECT 'Total' dt	
					,'' time1			--日期
					,'' agent			--坐席
					,sum(tc) tc			--chat总量
					,sum(sc) sc			--接起量
					,ROUND(CAST(sum(sc) AS FLOAT)/sum(tc), 2) re --回复率
					,sum(st)/sum(tc) at --平均处理时间
					,sum(aft)/count(agent)		aft		--首次平均响应时长
					,sum(art)/count(agent)		art		--平均响应时间
					,ROUND(CAST(sum(ssc) AS FLOAT)/sum(sc), 2) svclevel --服务水平
					,sum(ssc)	ssc	--60内接起量
					,sum(st)	st	--在线时长
					,sum(kc)	kc	--客户放弃数，未应答数
					FROM cte
		END
-----------------------周报表
		ELSE IF @GroupLevel = 'week' BEGIN
			;WITH cte1 AS(select sdrid,sdrtime,agent,datepart(week,sdrtime) wn,DATEADD(day,- DATEPART(weekday,CONVERT(VARCHAR(8),sdrtime,112))+1,CONVERT(VARCHAR(8),sdrtime,112)) bwn,DATEADD(day,7 - DATEPART(weekday,CONVERT(VARCHAR(8),sdrtime,112)),CONVERT(VARCHAR(8),sdrtime,112)) ewn  from V_SDRWork 
				 where CONVERT(VARCHAR(8),sdrtime,112)  between CONVERT(datetime,STR(@DateBegin),120) and CONVERT(datetime,STR(@DateEnd),120) 
			), cte2 AS(		--坐席，日期，接待总数，在线时长,首次平均响应时长
					select wn,bwn,ewn,agent,count(sdrid) sc,sum(t1) st,avg(t2) aft
					from( SELECT A.sdrid,A.agent,B.t2,datediff(s,sdrtime,tst) t1,wn,bwn,ewn FROM cte1 A
						  inner join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 is not null
					) tt group by agent,wn,bwn,ewn
			),cte3 as(		--会话总数
					 select count(sdrid)tc,wn,bwn,ewn,agent from cte1 group by agent,wn,bwn,ewn
			),cte4 as(		--某个时段内每个坐席60秒内接起的电话总量
					--select count(sdrid) ssc,agent,wn,bwn,ewn
					--from( SELECT A.sdrid,B.t2,agent,wn,bwn,ewn FROM	cte1 A
					--	  inner join
					--	V_FirstTime B on A.sdrid=B.sdrid 
					--	  where t2 <=60 and t2 is not null 
					--) tt group by agent,wn,bwn,ewn
					
				select BB.agent,isnull(AA.ssc,0) ssc,BB.wn,BB.bwn,BB.ewn from 
				(
				 select count(sdrid) ssc,agent,wn,bwn,ewn
					from( SELECT A.sdrid,B.t2,agent,wn,bwn,ewn FROM	cte1 A
						  inner join
						V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 <=60 and t2 is not null 
					) tt group by agent,wn,bwn,ewn
				)AA right join 
				( select agent,wn,bwn,ewn from cte1 group by agent,wn,bwn,ewn ) BB
				on AA.agent=BB.agent
			),cte5 as(		--某时段内每个坐席的平均响应时间
				select agent,datepart(week,sdrtime) wn,DATEADD(day,- DATEPART(weekday,CONVERT(VARCHAR(8),sdrtime,112))+1,CONVERT(VARCHAR(8),sdrtime,112)) bwn,DATEADD(day,7 - DATEPART(weekday,CONVERT(VARCHAR(8),sdrtime,112)),CONVERT(VARCHAR(8),sdrtime,112)) ewn,sum(art1)/count(agent)art 
				from V_AvgTime
				group by agent,datepart(week,sdrtime),DATEADD(day,- DATEPART(weekday,CONVERT(VARCHAR(8),sdrtime,112))+1,CONVERT(VARCHAR(8),sdrtime,112)),DATEADD(day,7 - DATEPART(weekday,CONVERT(VARCHAR(8),sdrtime,112)),CONVERT(VARCHAR(8),sdrtime,112))
			),
			 cte AS(
				select  CONVERT(varchar(2),outter.wn) wn,CONVERT(varchar(8),outter.bwn,112) bwn,CONVERT(varchar(8),outter.ewn,112) ewn,outter.agent,outter.tc,outter.sc,outter.re,outter.at,outter.aft,outter.art,outter.svclevel,outter.st,outter.ssc,outter.kc
				from(
				select  A.wn,A.bwn,A.ewn		--日期
					,A.agent		--坐席
					,B.tc			--chat总量
					,A.sc			--接起量
					,ROUND(CAST(A.sc AS FLOAT)/B.tc, 2) re --回复率
					,A.st/B.tc   at --平均处理时间
					,A.aft			--首次平均响应时长
					,D.art			--平均响应时间
					,ROUND(CAST(C.ssc AS FLOAT)/A.sc, 2) svclevel --服务水平
					,A.st			--在线时长
					,C.ssc			--60内接起量
					,(B.tc-A.sc) kc --客户放弃数，未应答数
					from cte2 A,cte3 B,cte4 C,cte5 D
					WHERE A.agent=B.agent
					and	A.agent=C.agent
					and	A.agent=D.agent
					and A.wn=B.wn
					and A.wn=C.wn
					and A.wn=D.wn
					and A.bwn=B.bwn
					and A.bwn=C.bwn
					and A.bwn=D.bwn
					and A.ewn=B.ewn
					and A.ewn=C.ewn
					and A.ewn=D.ewn
					)outter
					where  @Preload = 0 
					AND ISNULL(outter.agent, '') = ISNULL(@Agent, ISNULL(outter.agent, ''))
			)
			SELECT wn,bwn,ewn,agent,tc,sc,re,at,aft,art,svclevel,ssc,st,kc FROM cte
 UNION ALL
			SELECT	 'Total' wn	
					,' ' bwn		--日期
					,' ' ewn
					,' ' agent		--坐席
					,sum(tc) tc		--chat总量
					,sum(sc) sc		--接起量
					,ROUND(CAST(sum(sc) AS FLOAT)/sum(tc), 2) re --回复率
					,sum(st)/sum(tc) at --平均处理时间
					,sum(aft)/count(agent)		aft		--首次平均响应时长
					,sum(art)/count(agent)		art		--平均响应时间
					,ROUND(CAST(sum(ssc) AS FLOAT)/sum(sc), 2) svclevel --服务水平
					,sum(ssc)	ssc	--60内接起量
					,sum(st)	st	--在线时长
					,sum(kc)	kc	--客户放弃数，未应答数
					FROM cte 
	END		
-----------------------月报表
		ELSE IF @GroupLevel = 'month' BEGIN
			;WITH cte1 AS(select sdrid,agent,CONVERT(VARCHAR(6),sdrtime,112) dt,sdrtime  from V_SDRWork 
				 where CONVERT(VARCHAR(6),sdrtime,112) between CONVERT(int,left(@DateBegin,6)) and CONVERT(int,left(@DateEnd,6)) 
			), cte2 AS(		--坐席，日期，接待总数，在线时长,首次平均响应时长
					select dt,agent,count(sdrid) sc,sum(t1) st,avg(t2) aft
					from( SELECT A.sdrid,A.agent,B.t2,datediff(s,sdrtime,tst) t1,dt FROM cte1 A
						  inner join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 is not null
					) tt group by agent,dt	
			),cte3 as(		--会话总数
					 select count(sdrid)tc,dt,agent from cte1 group by agent,dt
			),cte4 as(		--某个时段内每个坐席60秒内接起的电话总量
				--	select count(sdrid) ssc,agent,dt
				--	from( SELECT A.sdrid,B.t2,agent,dt FROM	cte1 A
				---		  inner join
				--		V_FirstTime B on A.sdrid=B.sdrid 
				--		  where t2 <=60 and t2 is not null
				--	) tt group by agent,dt
				select BB.agent,isnull(AA.ssc,0) ssc,BB.dt from 
				(
				 select count(sdrid) ssc,agent,dt
					from( SELECT A.sdrid,B.t2,agent,dt FROM	cte1 A
						  left join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 <=60 
					) tt group by agent,dt
				)AA right join 
				( select agent,dt from cte1 group by agent,dt ) BB
				on AA.agent=BB.agent
			),cte5 as(		--某时段内每个坐席的平均响应时间
				select agent,CONVERT(VARCHAR(6),sdrtime,112) dt,sum(art1)/count(agent)art 
				from V_AvgTime group by agent,CONVERT(VARCHAR(6),sdrtime,112)
			),
			 cte AS(
				select outter.dt,outter.agent,outter.tc,outter.sc,outter.re,outter.at,outter.aft,outter.art,outter.svclevel,outter.st,outter.ssc,outter.kc
				from(
				select A.dt			--日期
					,A.agent		--坐席
					,B.tc			--chat总量
					,A.sc			--接起量
					,ROUND(CAST(A.sc AS FLOAT)/B.tc, 2) re --回复率
					,A.st/B.tc   at --平均处理时间
					,A.aft			--首次平均响应时长
					,D.art			--平均响应时间
					,ROUND(CAST(C.ssc AS FLOAT)/A.sc, 2) svclevel --服务水平
					,A.st			--在线时长
					,C.ssc			--60内接起量
					,(B.tc-A.sc) kc --客户放弃数，未应答数
					from cte2 A,cte3 B,cte4 C,cte5 D
					WHERE A.agent=B.agent
					and	A.agent=C.agent
					and	A.agent=D.agent
					and A.dt=B.dt
					and A.dt=C.dt
					and A.dt=D.dt
					)outter
					where  @Preload = 0 
					AND ISNULL(outter.agent, '') = ISNULL(@Agent, ISNULL(outter.agent, ''))
			)
			SELECT  dt,agent,tc,sc,re,at,aft,art,svclevel,ssc,st,kc  FROM cte 
 UNION ALL
			SELECT 'Total' dt	
					,'' agent										--坐席
					,sum(tc)		tc								--chat总量
					,sum(sc)		sc								--接起量
					,ROUND(CAST(sum(sc) AS FLOAT)/sum(tc), 2) re	--回复率
					,sum(st)/sum(tc) at								--平均处理时间
					,sum(aft)/count(agent)	aft						--首次平均响应时长
					,sum(art)/count(agent)	art						--平均响应时间
					,ROUND(CAST(sum(ssc) AS FLOAT)/sum(sc), 2) svclevel --服务水平
					,sum(ssc)	ssc									--60内接起量
					,sum(st)	st									--在线时长
					,sum(kc)	kc									--客户放弃数，未应答数
					FROM cte
	END		
-----------------------年报表
		ELSE IF @GroupLevel = 'year' BEGIN
			;WITH cte1 AS(select sdrid,agent,CONVERT(VARCHAR(4),sdrtime,112) dt,sdrtime  from V_SDRWork 
				where CONVERT(VARCHAR(4),sdrtime,112) between CONVERT(int,left(@DateBegin,4)) and CONVERT(int,left(@DateEnd,4))
			), cte2 AS(		--坐席，日期，接待总数，在线时长,首次平均响应时长
					select dt,agent,count(sdrid) sc,sum(t1) st,avg(t2) aft
					from( SELECT A.sdrid,A.agent,B.t2,datediff(s,sdrtime,tst) t1,dt FROM cte1 A
						  inner join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 is not null
					) tt group by agent,dt	
			),cte3 as(		--会话总数
					 select count(sdrid)tc,dt,agent from cte1 group by agent,dt
			),cte4 as(		--某个时段内每个坐席60秒内接起的电话总量
					--select count(sdrid) ssc,agent,dt
					--from( SELECT A.sdrid,B.t2,agent,dt FROM	cte1 A
					--	  inner join
					--	V_FirstTime B on A.sdrid=B.sdrid 
					--	  where t2 <=60 and t2 is not null
					--) tt group by agent,dt
				select BB.agent,isnull(AA.ssc,0) ssc,BB.dt from 
				(
				 select count(sdrid) ssc,agent,dt
					from( SELECT A.sdrid,B.t2,agent,dt FROM	cte1 A
						  left join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 <=60 
					) tt group by agent,dt
				)AA right join 
				( select agent,dt from cte1 group by agent,dt ) BB
				on AA.agent=BB.agent
			),cte5 as(		--某时段内每个坐席的平均响应时间
				select agent,CONVERT(VARCHAR(4),sdrtime,112) dt,sum(art1)/count(agent)art 
				from V_AvgTime group by agent,CONVERT(VARCHAR(4),sdrtime,112)
			),
			 cte AS(
				select outter.dt,outter.agent,outter.tc,outter.sc,outter.re,outter.at,outter.aft,outter.art,outter.svclevel,outter.st,outter.ssc,outter.kc
				from(
				select A.dt			--日期
					,A.agent		--坐席
					,B.tc			--chat总量
					,A.sc			--接起量
					,ROUND(CAST(A.sc AS FLOAT)/B.tc, 2) re --回复率
					,A.st/B.tc   at --平均处理时间
					,A.aft			--首次平均响应时长
					,D.art			--平均响应时间
					,ROUND(CAST(C.ssc AS FLOAT)/A.sc, 2) svclevel --服务水平
					,A.st			--在线时长
					,C.ssc			--60内接起量
					,(B.tc-A.sc) kc --客户放弃数，未应答数
					from cte2 A,cte3 B,cte4 C,cte5 D
					WHERE A.agent=B.agent
					and	A.agent=C.agent
					and	A.agent=D.agent
					and A.dt=B.dt
					and A.dt=C.dt
					and A.dt=D.dt
					)outter
					where  @Preload = 0 
					AND ISNULL(outter.agent, '') = ISNULL(@Agent, ISNULL(outter.agent, ''))
			)
			SELECT  dt,agent,tc,sc,re,at,aft,art,svclevel,ssc,st,kc  FROM cte 
 UNION ALL
			SELECT 'Total' dt	
					,'' agent										--坐席
					,sum(tc)		tc								--chat总量
					,sum(sc)		sc								--接起量
					,ROUND(CAST(sum(sc) AS FLOAT)/sum(tc), 2) re	--回复率
					,sum(st)/sum(tc) at								--平均处理时间
					,sum(aft)/count(agent)	aft						--首次平均响应时长
					,sum(art)/count(agent)	art						--平均响应时间
					,ROUND(CAST(sum(ssc) AS FLOAT)/sum(sc), 2) svclevel --服务水平
					,sum(ssc)	ssc									--60内接起量
					,sum(st)	st									--在线时长
					,sum(kc)	kc									--客户放弃数，未应答数
					FROM cte
	END			
	----------------日报表
		ELSE IF @GroupLevel = 'day' BEGIN
			;WITH cte1 AS(select sdrid,agent,CONVERT(VARCHAR(8),sdrtime,112) dt,sdrtime  from V_SDRWork 
				 where CONVERT(VARCHAR(8),sdrtime,112)  between CONVERT(datetime,STR(@DateBegin),120) and CONVERT(datetime,STR(@DateEnd),120) 
			), cte2 AS(		--坐席，日期，接待总数，在线时长,首次平均响应时长
					select dt,agent,count(sdrid) sc,sum(t1) st,avg(t2) aft
					from( SELECT A.sdrid,A.agent,B.t2,datediff(s,sdrtime,tst) t1,dt FROM cte1 A
						  inner join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 is not null 
					) tt group by agent,dt	
			),cte3 as(		--会话总数
					 select count(sdrid)tc,dt,agent from cte1 group by agent,dt
			),cte4 as(		--某个时段内每个坐席60秒内接起的电话总量
					--select count(sdrid) ssc,agent,dt
					--from( SELECT A.sdrid,B.t2,agent,dt FROM	cte1 A
					--	  inner join
					--	  V_FirstTime B on A.sdrid=B.sdrid 
					--	  where t2 <=60 and t2 is not null
					--) tt group by agent,dt
				select BB.agent,isnull(AA.ssc,0) ssc,BB.dt from 
				(
				 select count(sdrid) ssc,agent,dt
					from( SELECT A.sdrid,B.t2,agent,dt FROM	cte1 A
						  left join
						  V_FirstTime B on A.sdrid=B.sdrid 
						  where t2 <=60 
					) tt group by agent,dt
				)AA right join 
				( select agent,dt from cte1 group by agent,dt ) BB
				on AA.agent=BB.agent
			),cte5 as(		--某时段内每个坐席的平均响应时间
				select agent,CONVERT(VARCHAR(8),sdrtime,112) dt,sum(art1)/count(agent)art 
				from V_AvgTime group by agent,CONVERT(VARCHAR(8),sdrtime,112)
			),
			 cte AS(
				select outter.dt,outter.agent,outter.tc,outter.sc,outter.re,outter.at,outter.aft,outter.art,outter.svclevel,outter.st,outter.ssc,outter.kc
				from(
				select A.dt			--日期
					,A.agent		--坐席
					,B.tc			--chat总量
					,A.sc			--接起量
					,ROUND(CAST(A.sc AS FLOAT)/B.tc, 2) re --回复率
					,A.st/B.tc   at --平均处理时间
					,A.aft			--首次平均响应时长
					,D.art			--平均响应时间
					,ROUND(CAST(C.ssc AS FLOAT)/A.sc, 2) svclevel --服务水平
					,A.st			--在线时长
					,C.ssc			--60内接起量
					,(B.tc-A.sc) kc --客户放弃数，未应答数
					from cte2 A,cte3 B,cte4 C,cte5 D
					WHERE A.agent=B.agent
					and	A.agent=C.agent
					and	A.agent=D.agent
					and A.dt=B.dt
					and A.dt=C.dt
					and A.dt=D.dt
					)outter
					where  @Preload = 0 
					AND ISNULL(outter.agent, '') = ISNULL(@Agent, ISNULL(outter.agent, ''))
			)
			SELECT  dt,agent,tc,sc,re,at,aft,art,svclevel,ssc,st,kc  FROM cte 
 UNION ALL
			SELECT 'Total' dt	
					,'' agent										--坐席
					,sum(tc)		tc								--chat总量
					,sum(sc)		sc								--接起量
					,ROUND(CAST(sum(sc) AS FLOAT)/sum(tc), 2) re	--回复率
					,sum(st)/sum(tc) at								--平均处理时间
					,sum(aft)/count(agent)	aft						--首次平均响应时长
					,sum(art)/count(agent)	art						--平均响应时间
					,ROUND(CAST(sum(ssc) AS FLOAT)/sum(sc), 2) svclevel --服务水平
					,sum(ssc)	ssc									--60内接起量
					,sum(st)	st									--在线时长
					,sum(kc)	kc									--客户放弃数，未应答数
					FROM cte
	END		
		
	SET @Error = 0	
	END TRY
	BEGIN CATCH
		SET @Error = -1
		GOTO ERROR_END
	END CATCH
	RETURN @@rowcount

ERROR_END:	
	PRINT '[dbo].[sp_chat_log_new]获取数据失败！'
SELECT  dt= NULL,agent= NULL,tc= NULL,sc= NULL,re= NULL,at= NULL,aft= NULL,art= NULL,svclevel= NULL,ssc= NULL,st= NULL
	SET @Error = -1;
	RETURN @Error
END






GO
/****** Object:  StoredProcedure [dbo].[sp_chat_msg_distribute]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2014.11.12>
-- Description:	chat HM 留言平均分配算法实现

-- exec [dbo].[sp_chat_msg_distribute] @Agents='dfkd,dfdkdf,dfdkf,dffjk'

-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_chat_msg_distribute]
	@Agents	NVARCHAR(2000)	= NULL
AS
BEGIN
	
	set @Agents = rtrim(ltrim(isnull(@Agents,'')));
	
	if (len(@Agents) > 0) begin
	
		declare @maxNum smallint
		
		create table #T_Chat_MsgD_Agent (col varchar(50) ,num smallint) 
		
		create table #T_Chat_MsgD_Msg (col bigint ,num smallint,disAgent smallint,agent varchar(50)) 
		
		insert into #T_Chat_MsgD_Agent select col,row_number() over(order by col) as num from dbo.f_split(@Agents,',') 
		
		insert into #T_Chat_MsgD_Msg (col,num) SELECT [id] as col ,row_number() over(order by id) as num FROM [vxi_chat].[dbo].[Message] where len(rtrim(ltrim(isnull(agent,'')))) = 0
		
		select @maxNum = max(num) from #T_Chat_MsgD_Agent
		
		select col,num,@maxNum from #T_Chat_MsgD_Agent
		
		update #T_Chat_MsgD_Msg set disAgent =(case when num%@maxNum =0 then @maxNum else num%@maxNum end)
		
		update #T_Chat_MsgD_Msg set agent =(select col from #T_Chat_MsgD_Agent where num=  disAgent)
		
		update  a
		set a.agent = b.agent
		from  [vxi_chat].[dbo].[Message] a , #T_Chat_MsgD_Msg b
		where a.id = b.col
		
		--select col,num,agent from #T_Chat_MsgD_Msg
		
		--SELECT [id] ,row_number() over(order by id) FROM [vxi_chat].[dbo].[Message] where len(rtrim(ltrim(isnull(agent,'')))) = 0

		--select agent,row_number() over(order by agent) as num from vxi_sys..agent  

		IF OBJECT_ID('tempdb..#T_Chat_MsgD_Msg') IS NOT NULL BEGIN
			DROP TABLE #T_Chat_MsgD_Msg
			PRINT 'delete temp table #T_Chat_MsgD_Msg'
		END
		
		IF OBJECT_ID('tempdb..#T_Chat_MsgD_Agent') IS NOT NULL BEGIN
			DROP TABLE #T_Chat_MsgD_Agent
			PRINT 'delete temp table #T_Chat_MsgD_Agent'
		END
	
	end
END



GO
/****** Object:  StoredProcedure [dbo].[sp_chat_service_time]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Haigang.Chen
-- Create date: 2015.06.01
-- Description:	获取项目服务时间
-- exec [dbo].[sp_chat_service_time]
-- =============================================
create PROCEDURE [dbo].[sp_chat_service_time]
    (
      @PrjId smallint = 1
    )
AS 
    BEGIN  
          	select  
		(case when ServiceType is null 
			then 
			(case when isWeekend=1 then  
				(case when currentTime>=HolidayStartTime and currentTime<=HolidayEndTime then 0 else 1 end)
				else
				(case when currentTime>=WorkdayStartTime and currentTime<=WorkdayEndTime then 0 else 1 end) end)
		  when servicetype = 3 then 1 
		  when servicetype = 2 then 
			(case when StartTime is not null and EndTime is not null
				then 
					(case when currentTime>=StartTime and currentTime<=EndTime then 0 else 1 end)
				else 
					(case when currentTime>=HolidayStartTime and currentTime<=HolidayEndTime then 0 else 1 end)
				end
			)
			
		  when servicetype = 1 then 
			(case when StartTime is not null and EndTime is not null
				then 
					(case when currentTime>=StartTime and currentTime<=EndTime then 0 else 1 end)
				else 
					(case when currentTime>=WorkdayStartTime and currentTime<=WorkdayEndTime then 0 else 1 end)
				end
			) 
		 else 0
		 end) notservicetime,
		t3.*
		 from (
		 select top 1
		   		convert(varchar(10),getdate(),120) as CurrentDate,
				ClosedPath,
				ClientPath,
				WorkdayStartTime,
				WorkdayEndTime,
				HolidayStartTime,
				HolidayEndTime,
				t2.StartTime,
				t2.EndTime,
				t2.ServiceType,
				(case when (
					datename(weekday, getdate())='Saturday' or
					datename(weekday, getdate())='Sunday' or
					datename( weekday, getdate())='星期六' or
					datename( weekday, getdate())='星期日' or
					datename( weekday, getdate())='星期天' ) 
					then 1 else 0 end ) as isWeekend,
				CONVERT(varchar(5), GETDATE(), 8) as currentTime
				
				 from vxi_chat.dbo.projects  t1
					left join  (select * from  vxi_chat.dbo.servicetime where servicedate = convert(varchar(10),getdate(),120) ) t2 
					on t1.prjid = t2.prjid
				where t1.prjid = @PrjId   ) t3

    END



GO
/****** Object:  StoredProcedure [dbo].[sp_get_chat_survey]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Haigang.Chen
-- Create date: 2012.07.05
-- Description:	满意度调查统计报表
/*
  exec [sp_get_chat_survey] @DateBegin = 20121010 ,@DateEnd = 20131010,@TimeBegin = '000303',@TimeEnd = '090336' ,@Preload=0 ,@Agent=1001
*/
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_chat_survey]
    (
      @DateBegin BIGINT = NULL ,
      @DateEnd BIGINT = NULL ,
      @TimeBegin VARCHAR(10) = '000000' ,
      @TimeEnd VARCHAR(10) = '235959' ,
      @Agent VARCHAR(16) = '' ,
      @urlName VARCHAR(50) = '' ,
      @Preload BIT = 0
    )
AS 
    BEGIN  
        DECLARE 
            @v_DateBegin VARCHAR(20) ,
            @v_DateEnd VARCHAR(20) ,
            @v_BeginTime VARCHAR(10) ,
            @v_EndTime VARCHAR(10) 
            
        IF LEN(@TimeBegin) < 6
            OR ISNULL(@TimeBegin, '0') = '0' 
            SET @v_BeginTime = '000000'
        ELSE 
            SET @v_BeginTime = @TimeBegin
        IF LEN(@TimeEnd) < 6
            OR ISNULL(@TimeEnd, '0') = '0' 
            SET @v_EndTime = '235959'
        ELSE 
            SET @v_EndTime = @TimeEnd
       
        SELECT  @v_DateBegin = Beg_Date ,
                @v_DateEnd = End_Date
        FROM    rep_ccms.dbo.For_Date(@DateBegin, @DateEnd, @v_BeginTime, @v_EndTime)  --获得起始与结束时间
        
		if ( len(@Agent) > 0) begin
			select 
			agent,--坐席
			urlName,--网页名称
			count(agent) answerTotal,--坐席接待量
			count(case when v.score>0 then 1 end) surveyTotal,--评分量
			dbo.avg_str(count(case when v.score>0 then 1 end),count(agent),1) surveyRate,--评分率
			count(case when v.score=5 then 1 end) score5,--非常满意量
			count(case when v.score=4 then 1 end) score4,
			count(case when v.score=3 then 1 end) score3,
			count(case when v.score=2 then 1 end) score2,
			count(case when v.score=1 then 1 end) score1,--
			dbo.avg_str(sum(isnull(v.score,0)),count(case when v.score>0 then 1 end),0) avgScore,--平均分
			dbo.avg_str(count(case when v.score=4 or v.score=5 then 1 end),count(case when v.score>0 then 1 end),1) satisfication --满意度（4&5分个数/评分量）
			
			from  v_sdr_new s
			left join dbo.Survey v on s.sdrid = v.sdrid 
			where agentMsgCount>0 and convert(varchar(20),sdrtime,120) between @v_DateBegin and @v_DateEnd 
			and 0=(@Preload) 
			group by agent,urlName having agent = @Agent and (case when isnull(@urlName,'')='' then '' else urlName end)=isnull(@urlName,'')
		end 
		else begin 
			select 
			agent,--坐席
			urlName,--网页名称
			count(agent) answerTotal,--坐席接待量
			count(case when v.score>0 then 1 end) surveyTotal,--评分量
			dbo.avg_str(count(case when v.score>0 then 1 end),count(agent),1) surveyRate,--评分率
			count(case when v.score=5 then 1 end) score5,--非常满意量
			count(case when v.score=4 then 1 end) score4,
			count(case when v.score=3 then 1 end) score3,
			count(case when v.score=2 then 1 end) score2,
			count(case when v.score=1 then 1 end) score1,--
			dbo.avg_str(sum(isnull(v.score,0)),count(case when v.score>0 then 1 end),0) avgScore,--平均分
			dbo.avg_str(count(case when v.score=4 or v.score=5 then 1 end),count(case when v.score>0 then 1 end),1) satisfication --满意度（4&5分个数/评分量）
			
			from  v_sdr_new s
			left join dbo.Survey v on s.sdrid = v.sdrid 
			where agentMsgCount>0 and convert(varchar(20),sdrtime,120) between @v_DateBegin and @v_DateEnd 
			and 0=(@Preload) 
			group by agent,urlName having ''='' and (case when isnull(@urlName,'')='' then '' else urlName end)=isnull(@urlName,'')
		end
    END



GO
/****** Object:  StoredProcedure [dbo].[sp_response_time]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.06.14>
-- Description:	计算首次响应时间，平均响应时间
/*
Example:
exec sp_response_time 
*/
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_response_time]

AS 
BEGIN
	declare @Sdrid bigint
	declare @temp_count int
	set @temp_count =0
	DECLARE tracetime CURSOR FOR
	    select sdrid from sdr where sdrid not in (
		select sdrid from SDRInfo where onCalc = 1 
		)
		and onend is not null
	OPEN tracetime
	    FETCH NEXT FROM tracetime INTO @Sdrid
			WHILE (@@FETCH_STATUS=0)
			BEGIN
				exec dbo.sp_calc_avg_response_time @Sdrid
				set @temp_count = @temp_count+1
			FETCH NEXT FROM tracetime INTO @Sdrid
			END
		CLOSE tracetime
	DEALLOCATE tracetime    
	return @temp_count
END


GO
/****** Object:  StoredProcedure [dbo].[sp_sum_login_time]    Script Date: 2016/9/5 13:35:12 ******/
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
	declare @right datetime
	declare @duration int

	set @duration = 0
	
	create table #temp_login_time ( l datetime,r datetime,row_num int)
	insert into #temp_login_time 
	SELECT 
      [StartTime] as l
      ,[EndTime] as r ,row_number() over(order by startTime) as row_num
	FROM [vxi_chat].[dbo].[Login] 
	where [StartTime] >= @DateBegin and [StartTime] < @DateEnd and agent=@Agent 
	
	select @left = l from #temp_login_time  where row_num = 1	
	if (@left is null) begin
		update #temp_login_time	 set l=@DateBegin where row_num = 1	
	end 
	select @right = r from #temp_login_time  where row_num = (select max(row_num) from #temp_login_time) 
	if (@right is null) begin
		update #temp_login_time	 set r=@DateEnd   where row_num = (select max(row_num) from #temp_login_time) 
	end
	
	select 
	@duration = sum(abs(datediff(ms,l,r)))/1000
	 from #temp_login_time
	
	drop table #temp_login_time
	
	IF OBJECT_ID('tempdb..#temp_login_time') IS NOT NULL BEGIN
		DROP TABLE #temp_login_time
		PRINT 'delete temp table #temp_login_time'
	END
	RETURN @duration
END



GO
/****** Object:  StoredProcedure [dbo].[sp_url_total]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ==========================================================================================
-- Author:		<haigang.chen@vxichina.com>
-- Create date: <2013.08.05>
-- Description:	访问来源统计报表
--exec [dbo].[sp_url_total] @DateBegin=20110101 ,@DateEnd = 20130901 ,@Preload=0
-- ==========================================================================================
CREATE PROCEDURE [dbo].[sp_url_total]
	@DateBegin	NVARCHAR(10) =NULL,
	@DateEnd	NVARCHAR(10)  =NULL,
	@Preload	BIT = 0				-- 仅预览表标题
AS
BEGIN
	
	declare @sql varchar(max)

	set @sql = '
	 ;with cte1 as (
	  select convert(varchar(10),v.viaTime,120) sdrtime ,v.refUrl,
		(select name from dbo.urlDict where charindex(url,v.refUrl) >=1) as urlName,v.sdrid,s.msgCount,s.agentMsgCount
	   from  dbo.vialog v 
		left join dbo.V_SDR_NEW s on v.sdrid = s.sdrid
		where   convert(varchar(8),v.viaTime,112) between '''+ @DateBegin + ''' and ''' + @DateEnd
    +''' and 0=' + str(@Preload) +')   
	select sdrtime
	' 

	select @sql =  @sql + 
		   ',(select count(urlname) from cte1 t1 where t1.sdrtime=t2.sdrtime and t1.urlname=''' + name + ''')  as ['+ urlname + '(访问数)]
	,(select count(urlname) from cte1 t1 where t1.sdrtime=t2.sdrtime and t1.urlname=''' + name + ''' and sdrid is not null and agentMsgCount <> msgCount) as ['+ urlname + '(有效聊天数)]
	'
	from (select distinct name,urlname from dbo.urlDict  ) a   
	 
	set @sql = @sql + '
	from  cte1 t2
	group by sdrtime 
	' 
	print @sql
	 exec( @sql )
	return @@rowcount
END


GO
/****** Object:  UserDefinedFunction [dbo].[avg_str]    Script Date: 2016/9/5 13:35:12 ******/
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
/****** Object:  UserDefinedFunction [dbo].[f_split]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

 CREATE function [dbo].[f_split](@c varchar(2000),@split varchar(2)) 
returns @t table(col varchar(50)  ) 
as 
begin 

while(charindex(@split,@c)<>0) 
begin 
insert @t(col) values (substring(@c,1,charindex(@split,@c)-1)) 
set @c = stuff(@c,1,charindex(@split,@c),'') 
end 

insert @t(col) values (@c) 

return 
end 

GO
/****** Object:  UserDefinedFunction [dbo].[Func_Content]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE function [dbo].[Func_Content](@sdrid bigint)   
returns varchar(max)   
as   
begin      
declare   
@Content varchar(max) 
     
select @Content=isnull(@Content,'')+(case when len(Account) >10 then '客户'+right(Account,4) else Account end)+CONVERT(CHAR(19),stime, 120)+content from [vxi_chat].[dbo].[SDRTrace] where sdrid=@sdrid 
select @Content=REPLACE(@Content,'<br>','')
select @Content=REPLACE(@Content,'<br/>','')
return @Content   
end   


GO
/****** Object:  UserDefinedFunction [dbo].[func_day]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


Create FUNCTION [dbo].[func_day] (@date datetime)  
RETURNS int AS  
BEGIN 
	return (year(@date) * 10000 + month(@date) * 100 + day(@date))
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_url]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



 
CREATE FUNCTION [dbo].[func_url](@url varchar(200))
RETURNS varchar(50)
AS
BEGIN
 /*
 select vxi_chat.dbo.func_url('http://portal.shtvu.edu.cn/ghfgff')
 
 学历教学平台：http://portal.shtvu.edu.cn
教研活动：http://jyhd2.shtvu.edu.cn/Web/Annoucement/NewAnnoucement.aspx?TermCode=20131
毕业设计：
①http://bysj.shtvu.edu.cn/web/Announcement/TermPaperAnnouncement.aspx?TermCode=20131
②http://lwsb.shtvu.org.cn/graduate_shtvu2/main/frontpage.asp
网上课堂：http://wskt.shtvu.edu.cn/web/default.aspx
形考平台：http://exam.shtvu.edu.cn/1.0.20130620/Pages/XingKao/XingKaoList.aspx?CourseCode=JC0001
上海学习网：http://www.shlll.net
开放学院：http://kfxy.shtvu.org.cn/new
十二五学分银行：http://xfyh.21shte.net
上海教育资源库：http://www.sherc.net
开大招生：http://zhaosheng.shtvu.edu.cn/
远程接待中心网站：http://server.shtvu.edu.cn
*/
 declare @urlName varchar(50)
   
    select @urlName=urlName from vxi_chat.dbo.urlDict where charindex(url,@url) >=1
    
	return isnull(@urlName, '其他')
END




GO
/****** Object:  UserDefinedFunction [dbo].[int_date_week]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Object:  UserDefinedFunction [dbo].[sec_to_time]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create FUNCTION [dbo].[sec_to_time] ( @time int )
RETURNS varchar(20) AS
BEGIN 
	declare  @hour  int, @min int, @sec int, @retval varchar (20)
	
	select @sec = @time % 60, 	@time = @time / 60
	select @min = @time % 60, 	@time = @time / 60
	select @hour = @time % 60, 	@retval = ''

	if @hour < 10 	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@hour)) + ':'
	if @min < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@min)) + ':'
	if @sec < 10  	set @retval = @retval + '0'
	set @retval = @retval + ltrim(str(@sec)) 

	return @retval

END

GO
/****** Object:  UserDefinedFunction [dbo].[week_series_to_str]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

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
/****** Object:  Table [dbo].[AgentDevice]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AgentDevice](
	[device] [varchar](50) NOT NULL,
	[agent] [varchar](50) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Blacklist]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Blacklist](
	[blId] [smallint] IDENTITY(1,1) NOT NULL,
	[customerId] [varchar](50) NULL,
	[refuseType] [smallint] NULL,
	[IPAddress] [varchar](15) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Blacklist] PRIMARY KEY CLUSTERED 
(
	[blId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ContactResultDefine]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ContactResultDefine](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[AppID] [int] NULL,
	[Name] [nvarchar](50) NULL,
	[canModify] [bit] NULL,
	[status] [bit] NULL,
	[parentId] [int] NULL,
	[keyword] [varchar](50) NULL,
 CONSTRAINT [PK_CallType] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Customers]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Customers](
	[email] [nchar](50) NOT NULL,
	[cust_name] [nchar](30) NOT NULL,
	[createDate] [datetime] NULL,
	[IPAddress] [nchar](15) NULL,
	[cust_id] [varchar](40) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[HmSurvey]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[HmSurvey](
	[SDRId] [bigint] NOT NULL,
	[score1] [tinyint] NULL,
	[score2] [tinyint] NULL,
	[score3] [tinyint] NULL,
	[score4] [tinyint] NULL,
	[surveyed] [bit] NULL,
	[SurveyTime] [datetime] NULL,
 CONSTRAINT [PK_HmSurvery_SDR] PRIMARY KEY CLUSTERED 
(
	[SDRId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Login]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Login](
	[LogID] [bigint] NOT NULL,
	[Agent] [char](20) NOT NULL,
	[Skills] [varchar](50) NULL,
	[Finish] [bit] NULL,
	[Flag] [tinyint] NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
	[EndTime]  AS (dateadd(millisecond,[timelen],[StartTime])),
	[ReadyLen] [int] NULL,
	[cause] [tinyint] NULL,
 CONSTRAINT [PK_Login] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[login_log]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[login_log](
	[userid] [varchar](20) NOT NULL,
	[ip] [varchar](20) NOT NULL,
	[logintime] [datetime] NULL,
	[skill] [varchar](20) NULL,
	[bz] [nvarchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Message]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Message](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NOT NULL,
	[phone] [varchar](30) NULL,
	[email] [varchar](30) NOT NULL,
	[topic] [varchar](60) NULL,
	[message] [varchar](500) NOT NULL,
	[recTime] [datetime] NULL,
	[account] [varchar](100) NULL,
	[agent] [varchar](20) NULL,
	[handleTime] [datetime] NULL,
	[remark] [varchar](1000) NULL,
	[url] [varchar](1000) NULL,
	[ip] [varchar](20) NULL,
	[uploadId] [bigint] NULL,
 CONSTRAINT [PK_Message] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OptionItem]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[OptionItem](
	[ID] [int] NOT NULL,
	[KeyWord] [varchar](50) NULL,
	[ItemName] [nvarchar](50) NULL,
	[ItemCode] [varchar](20) NULL,
	[GroupID] [int] NULL,
	[ParentID] [int] NULL,
	[StartDate] [datetime] NULL,
	[EndDate] [datetime] NULL,
	[status] [bit] NULL,
	[builtin] [bit] NULL,
	[orderNo] [int] NULL,
 CONSTRAINT [PK_OptionItem] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Projects]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Projects](
	[PrjId] [int] NOT NULL,
	[Project] [varchar](50) NULL,
	[HomePath] [varchar](50) NULL,
	[ClosedPath] [varchar](50) NULL,
	[ClientPath] [varchar](50) NULL,
	[WorkdayStartTime] [varchar](10) NULL,
	[WorkdayEndTime] [varchar](10) NULL,
	[HolidayStartTime] [varchar](10) NULL,
	[HolidayEndTime] [varchar](10) NULL,
	[Enabled] [bit] NOT NULL,
	[secretKey] [varchar](20) NULL,
	[custUrl] [varchar](500) NULL,
	[orderUrl] [varchar](500) NULL,
	[kbmUrl] [varchar](500) NULL,
	[workorderUrl] [varchar](500) NULL,
 CONSTRAINT [PK_Projects] PRIMARY KEY CLUSTERED 
(
	[PrjId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Ready]    Script Date: 2016/9/5 13:35:12 ******/
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
	[cause] [tinyint] NULL,
 CONSTRAINT [PK_Ready] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC,
	[SubID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[rt_agent]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[rt_agent](
	[Agent] [char](20) NOT NULL,
	[Skills] [varchar](50) NULL,
	[LogFlag] [tinyint] NOT NULL,
	[FlagTime] [datetime] NOT NULL,
	[Cause] [tinyint] NOT NULL,
	[LogId] [bigint] NULL,
	[SubId] [smallint] NULL,
	[LogTime] [datetime] NOT NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_rt_agent] PRIMARY KEY CLUSTERED 
(
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RtmConfig]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RtmConfig](
	[agent] [varchar](30) NOT NULL,
	[times] [int] NULL,
	[talktime] [int] NULL,
	[vipprompt] [bit] NULL,
 CONSTRAINT [PK_RtmConfig] PRIMARY KEY CLUSTERED 
(
	[agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SDR]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SDR](
	[SDRId] [bigint] NOT NULL,
	[SessionId] [int] NOT NULL,
	[SDRType] [tinyint] NULL,
	[Agent] [varchar](20) NULL,
	[Skill] [varchar](20) NULL,
	[Direction] [tinyint] NULL,
	[SrcAccount] [varchar](100) NULL,
	[DestAccount] [varchar](100) NULL,
	[SrcHost] [varchar](30) NULL,
	[DestHost] [varchar](30) NULL,
	[SrcAddr] [varchar](30) NULL,
	[DestAddr] [varchar](30) NULL,
	[SrcLocalAddr] [varchar](30) NULL,
	[DestLocalAddr] [varchar](30) NULL,
	[StoreId] [int] NULL,
	[SDRTime] [datetime] NULL,
	[bQueue] [bit] NULL,
	[bSubmit] [bit] NULL,
	[bTrans] [bit] NULL,
	[bConf] [bit] NULL,
	[bMonitor] [bit] NULL,
	[bWhisper] [bit] NULL,
	[OnQueue] [int] NULL,
	[OnSubmit] [int] NULL,
	[OnTrans] [int] NULL,
	[OnConf] [int] NULL,
	[OnMonitor] [int] NULL,
	[OnWhisper] [int] NULL,
	[TransTo] [varchar](50) NULL,
	[ConfTo] [varchar](50) NULL,
	[OnEnd] [int] NULL,
	[PrjId] [int] NULL,
	[DestName] [varchar](50) NULL,
 CONSTRAINT [PK_SDR] PRIMARY KEY CLUSTERED 
(
	[SDRId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SDRBusy]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SDRBusy](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[DestAccount] [varchar](100) NOT NULL,
	[flagtime] [datetime] NOT NULL,
	[isFinished] [char](1) NOT NULL,
 CONSTRAINT [PK_SDRBusy] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SDRDetail]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SDRDetail](
	[SDRId] [bigint] NOT NULL,
	[SubId] [int] NOT NULL,
	[Action] [tinyint] NULL,
	[SrcAccount] [varchar](100) NULL,
	[DestAccount] [varchar](100) NULL,
	[DestAddr] [varchar](30) NULL,
	[StartTime] [datetime] NULL,
	[OnEnd] [datetime] NULL,
	[PrjId] [int] NULL,
 CONSTRAINT [PK_SDRDetail] PRIMARY KEY CLUSTERED 
(
	[SDRId] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SDRInfo]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SDRInfo](
	[SDRId] [bigint] NULL,
	[firstTime] [int] NULL,
	[avgTime] [int] NULL,
	[country] [varchar](30) NULL,
	[province] [varchar](30) NULL,
	[city] [varchar](30) NULL,
	[district] [varchar](200) NULL,
	[isp] [varchar](30) NULL,
	[ip] [varchar](15) NULL,
	[refUrl] [varchar](500) NULL,
	[onCalc] [char](1) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SDRTrace]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SDRTrace](
	[SDRId] [bigint] NOT NULL,
	[SubId] [bigint] IDENTITY(1,1) NOT NULL,
	[STime] [datetime] NULL,
	[Account] [varchar](50) NULL,
	[Content] [varchar](4000) NULL,
	[Note] [varchar](2000) NULL,
 CONSTRAINT [PK_SDRTrace] PRIMARY KEY CLUSTERED 
(
	[SDRId] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ServiceTime]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ServiceTime](
	[PrjId] [int] NOT NULL,
	[ServiceDate] [varchar](10) NOT NULL,
	[ServiceType] [smallint] NOT NULL,
	[StartTime] [varchar](10) NULL,
	[EndTime] [varchar](10) NULL,
 CONSTRAINT [PK_ServiceTime] PRIMARY KEY CLUSTERED 
(
	[PrjId] ASC,
	[ServiceDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Shortcuts]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Shortcuts](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[Title] [varchar](200) NULL,
	[SContent] [varchar](1000) NULL,
	[SGroup] [nchar](200) NULL,
	[ITime] [datetime] NULL,
	[Owner] [varchar](50) NULL,
 CONSTRAINT [PK_Shortcuts] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Store]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Store](
	[StoreId] [int] NOT NULL,
	[IPAddr] [varchar](20) NOT NULL,
	[ExtIP] [varchar](20) NULL,
	[Folder] [varchar](60) NOT NULL,
	[Port] [int] NULL,
	[User] [varchar](50) NULL,
	[Password] [varchar](50) NULL,
	[Encry] [bit] NOT NULL,
	[Backup] [bit] NOT NULL,
	[BackupDest] [varchar](100) NULL,
	[BackupTime] [int] NULL,
	[KeepDays] [smallint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Store] PRIMARY KEY CLUSTERED 
(
	[StoreId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Survey]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Survey](
	[SDRId] [bigint] NOT NULL,
	[score] [tinyint] NULL,
	[suggestion] [varchar](500) NULL,
	[SurveyTime] [datetime] NULL,
 CONSTRAINT [PK_Survery_SDR] PRIMARY KEY CLUSTERED 
(
	[SDRId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SurveyResult]    Script Date: 2016/9/5 13:35:12 ******/
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
	[Score] [int] NULL,
 CONSTRAINT [PK_SurveyResult] PRIMARY KEY CLUSTERED 
(
	[ResultID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UploadFiles]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UploadFiles](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[disname] [varchar](200) NULL,
	[filesize] [int] NULL,
	[realpath] [varchar](200) NULL,
	[sender] [varchar](100) NULL,
	[senderIP] [varchar](30) NULL,
	[receiver] [varchar](100) NULL,
	[SDRID] [bigint] NULL,
	[uploadTime] [datetime] NULL,
	[uploadType] [char](1) NULL,
	[seconds] [smallint] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[urlDict]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[urlDict](
	[id] [int] NOT NULL,
	[url] [varchar](100) NOT NULL,
	[urlName] [varchar](50) NOT NULL,
	[name] [varchar](50) NULL,
 CONSTRAINT [PK_urlDict] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[user_roles]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[user_roles](
	[username] [varchar](20) NOT NULL,
	[role_name] [varchar](20) NOT NULL,
UNIQUE NONCLUSTERED 
(
	[username] ASC,
	[role_name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Users]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Users](
	[Agent] [varchar](20) NOT NULL,
	[AgentName] [varchar](50) NOT NULL,
	[ProjectId] [int] NULL,
	[Passwd] [varchar](200) NULL,
	[Device] [varchar](10) NULL,
	[Salt] [varchar](10) NULL,
	[Enabled] [bit] NULL,
	[LastPassword] [varchar](300) NULL,
 CONSTRAINT [PK_Agent] PRIMARY KEY CLUSTERED 
(
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ViaLog]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ViaLog](
	[id] [bigint] IDENTITY(1,1) NOT NULL,
	[viaTime] [datetime] NOT NULL,
	[account] [varchar](50) NOT NULL,
	[country] [varchar](30) NULL,
	[province] [varchar](30) NULL,
	[city] [varchar](30) NULL,
	[district] [varchar](200) NULL,
	[isp] [varchar](30) NULL,
	[ip] [varchar](15) NULL,
	[refUrl] [varchar](500) NULL,
	[onEstablish] [char](1) NULL,
	[SDRId] [bigint] NULL,
	[estabTime] [datetime] NULL,
	[skill] [varchar](20) NULL,
	[browser] [varchar](20) NULL,
	[name] [varchar](30) NULL,
	[email] [varchar](40) NULL,
 CONSTRAINT [PK_ViaLog] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Viplist]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Viplist](
	[CustomerNo] [varchar](100) NOT NULL,
	[UserName] [varchar](100) NULL,
	[Level] [smallint] NULL,
	[bPermanent] [bit] NULL,
	[CreateDate] [int] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Viplist] PRIMARY KEY CLUSTERED 
(
	[CustomerNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WorkOderLog]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WorkOderLog](
	[SDRId] [bigint] NOT NULL,
	[workOrderId] [varchar](30) NULL,
	[operateTime] [datetime] NULL,
	[operateUser] [varchar](30) NULL,
 CONSTRAINT [PK_WorkOderLog] PRIMARY KEY CLUSTERED 
(
	[SDRId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[V_SDRWork]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

create view [dbo].[V_SDRWork] as --去除上班时间外的数据,和不成立的chat

				select * from sdr 
					  where sdrid in (select sdrid from sdrtrace)
						--	and	 (	sdrtime in (select sdrtime from sdr where 5>=DATEPART(weekday,   sdrtime - 1) 
						--				and DATEPART(weekday,   sdrtime - 1)>=1
						--				and  DATEPART(hh,sdrtime) >=9
						--				and  DATEPART(hh,sdrtime) <=21)
						--			or sdrtime in  (select sdrtime from sdr where 7>=DATEPART(weekday,   sdrtime - 1) 
						--				and DATEPART(weekday,   sdrtime - 1)>=6
						--				and  DATEPART(hh,sdrtime) >=10
						--				and  DATEPART(hh,sdrtime) <=19) 
						--			)

GO
/****** Object:  View [dbo].[V_AvgTime]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE VIEW [dbo].[V_AvgTime]
AS
SELECT     AA.Agent, AA.SDRTime, ISNULL(BB.art1,0) art1
			FROM     V_SDRWork AS AA LEFT JOIN
                          (SELECT     SDRId, SUM(t) / COUNT(SDRId) AS art1
                            FROM          (SELECT     SDRId, SubId, MIN(tim) AS t
                                                    FROM          (SELECT     a_1.SDRId, a_1.STime AS atime, b.STime AS btime, b.SubId, ABS(DATEDIFF(s, a_1.STime, b.STime)) AS tim
                                                                            FROM          (SELECT     SDRId, STime, SubId, Account
                                                                                                    FROM          dbo.SDRTrace
                                                                                                    WHERE      (Account IN
                                                                                                                               (SELECT     Agent
                                                                                                                                 FROM          vxi_sys.dbo.Agent))) AS a_1 INNER JOIN
                                                                                                       (SELECT     SDRId, STime, SubId, Account
                                                                                                         FROM          dbo.SDRTrace AS SDRTrace_1
                                                                                                         WHERE      (Account NOT IN
                                                                                                                                    (SELECT     Agent
                                                                                                                                      FROM          vxi_sys.dbo.Agent AS Agent_1))) AS b ON a_1.SDRId = b.SDRId AND a_1.SubId > b.SubId) 
                                                                           AS outter
                                                    GROUP BY SubId, SDRId) AS A
                            GROUP BY SDRId) AS BB ON AA.SDRId = BB.SDRId




GO
/****** Object:  View [dbo].[V_Agent]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE VIEW [dbo].[V_Agent]
AS
SELECT agent,agentName,passwd from vxi_sys.dbo.Agent where enabled=1 


GO
/****** Object:  View [dbo].[V_Cus_Account]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW   [dbo].[V_Cus_Account]
AS
--select  cust_name,cust_id as acc  from visionPCR.dbo.CS_CUSTOMERS t where 
  -- len(t.cust_name) >0 union all 
select cust_name,email as acc from vxi_chat.dbo.Customers

GO
/****** Object:  View [dbo].[V_SDR_NEW]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




  CREATE view [dbo].[V_SDR_NEW] as 
select m.SDRid, m.Agent,m.Skill, m.DestAccount,
isnull((select top 1 cust_name from vxi_chat..V_Cus_Account where acc=m.DestAccount),DestAccount) as cust_name ,m.SrcAddr, m.DestAddr, m.SDRTime, m.SrcHost, m.DestHost 
,(select count(1) from vxi_chat..sdrtrace t where t.sdrid=m.sdrid) msgCount,
(select count(1) from vxi_chat..sdrtrace t where t.sdrid=m.sdrid and
exists (select 1 from dbo.V_agent a where t.account = a.agent)
) agentMsgCount,
i.firstTime,
i.avgTime,onEnd,n.refurl,vxi_chat.dbo.func_url(n.refurl) urlName
from vxi_chat..SDR m 
left join vxi_chat..SDRinfo i on m.sdrid = i.sdrid
left join vxi_chat.dbo.vialog n on m.SDRid=n.sdrid



GO
/****** Object:  View [dbo].[V_SDRTrace]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


  create view [dbo].[V_SDRTrace] as 
select s.SDRid,s.STime,s.Subid,isnull((select top 1 cust_name from vxi_chat..V_Cus_Account where acc=s.account),account) as yh ,s.Content from    vxi_chat..SDRTrace  s  


GO
/****** Object:  View [dbo].[V_SDR_ALL]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE view [dbo].[V_SDR_ALL] as 


select distinct destaccount,sdrid,agent,sdrtime,onEnd,srcaccount,destaddr,destname,SessionId from vxi_chat.dbo.sdr a with (nolock) 
where 
(destaccount in (select agent from vxi_chat..users  with (nolock) ) and  (select count(*) from vxi_chat.dbo.SDRTrace st  with (nolock) where st.sdrid=a.sdrid)>0)
or destaccount not in (select agent from vxi_chat..users  with (nolock) )
  union all 
  select distinct b.destaccount,a.sdrid,a.destaccount agent,b.sdrtime,b.onEnd,a.destaccount  srcaccount,b.destaddr,b.destname,b.SessionId  from vxi_chat.dbo.sdrdetail a with (nolock)  left join vxi_chat.dbo.sdr b with (nolock)  on a.sdrid=b.sdrid where (a.action =1 or a.action=3)
  union all
  
select 
distinct srcaccount destaccount,sdrid,destaccount agent,sdrtime,onEnd,destaccount srcaccount,destaddr,destname ,SessionId

from vxi_chat.dbo.sdr a with (nolock) 
 where destaccount in (select agent from vxi_chat..users  with (nolock) ) and
 (select count(*) from vxi_chat.dbo.SDRTrace st  with (nolock) where st.sdrid=a.sdrid)>0
 



GO
/****** Object:  View [dbo].[V_WorkOrderList]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
  
  CREATE view  [dbo].[V_WorkOrderList] as
select s.sdrid,agent,destaccount,sdrtime,workOrderId,operateTime,operateUser,
(case when len(workOrderId) >0 then 1 else 0 end) status from vxi_chat..v_sdr_all s 
with (nolock) left join vxi_chat..WorkOderLog w with (nolock) on s.sdrid=w.sdrid
where   onend >0
GO
/****** Object:  View [dbo].[V_SDR]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE view [dbo].[V_SDR] as
select m.SDRid, m.Agent,m.Skill, m.DestAccount,isnull((select top 1 cust_name from vxi_chat..V_Cus_Account where acc=m.DestAccount),DestAccount) as cust_name ,m.SrcAddr, m.DestAddr, m.SDRTime, m.SrcHost, m.DestHost,n.refurl,vxi_chat.dbo.func_url(n.refurl) urlName ,dbo.Func_Content(m.SDRid) content 
,(select count(1) from vxi_chat..sdrtrace t where t.sdrid=m.sdrid) msgCount,
(select count(1) from vxi_chat..sdrtrace t where t.sdrid=m.sdrid and exists (select 1 from dbo.V_agent a where t.account = a.agent)) agentMsgCount
from vxi_chat..SDR m 
left join vxi_chat.dbo.vialog n on m.SDRid=n.sdrid

GO
/****** Object:  View [dbo].[V_Survey]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





CREATE   VIEW   [dbo].[V_Survey]
AS

SELECT A.[SDRid] , A.[Agent], A.[Skill] , A.[DestAccount], A.[cust_name],A.[urlName] ,A.[refurl],B.[score] ,B.[suggestion] ,B.[SurveyTime] ,B.Description,A.content
  FROM [vxi_chat].[dbo].[V_SDR] A left join  
  (
  SELECT m.[SDRId]
      ,m.[score]
      ,m.[suggestion]
      ,m.[SurveyTime]
      ,s.[Description]+'('+cast(s.[Score] AS varchar(10)) +')'  Description 
  FROM [vxi_chat].[dbo].[Survey] m,[vxi_chat].[dbo].[SurveyResult] s where m.score=s.score
  ) B
  on A.[SDRid]=B.[SDRid]





GO
/****** Object:  View [dbo].[V_Account]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW   [dbo].[V_Account]
AS
--select  cust_name,cust_id as acc  from visionPCR.dbo.CS_CUSTOMERS t where 
 --  len(t.cust_name) >0 union all 
select cust_name,email as acc from vxi_chat.dbo.Customers
union all 
select agentname as  cust_name, agent as acc  from vxi_sys.dbo.agent

GO
/****** Object:  View [dbo].[V_Customers]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW   [dbo].[V_Customers]
AS
--select  cust_name,cust_id,email,1 type  from visionPCR.dbo.CS_CUSTOMERS t where 
  -- len(t.cust_name) >0 union all 
select cust_name,'' cust_id,email,2 type from vxi_chat.dbo.Customers



GO
/****** Object:  View [dbo].[V_FirstTime]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   VIEW   [dbo].[V_FirstTime]
AS
--	sdrtrace::最大时间bt最小时间st
--	account为坐席::最小时间 ast
--	t1在线时长
--	t2首次响应时长
--	t2=null		t1=0    客户说了一句话，坐席无响应
--	t2=null		t1>0	只有客户说话，坐席无响应
--	t2=0		t1=0	坐席说了一句话
--	t2=0		t1>0	坐席先说话，首次响应时间是0
--	t2>0		t1>0	首次响应时间t2

select sdrid,datediff(s,st,bt) t1,datediff(s,st,ast) t2,bt tst from
		(
					select A.sdrid,A.st,A.bt,B.ast  from 
							(select sdrid,min(stime)st,max(stime)bt from sdrtrace group by sdrid)A 
							left join
							(select sdrid,min(stime)ast from sdrtrace where account in (select agent from vxi_sys..agent) group by sdrid)B
					on  A.sdrid=B.sdrid  
			) outter



GO
/****** Object:  View [dbo].[V_HourSegment]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE view [dbo].[V_HourSegment] as 
SELECT RIGHT(100 + number, 2) + ':00:00-' + RIGHT(100 + number , 2) +
               ':59:59' as segment,
               RIGHT(100 + number, 2) + ':00:00' sBegin,
               RIGHT(100 + number , 2) + ':59:59' sEnd
          FROM master.dbo.spt_values
         WHERE type = 'P'
           AND number < 24
           AND number >= 0


GO
/****** Object:  View [dbo].[V_Message]    Script Date: 2016/9/5 13:35:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO









CREATE   VIEW   [dbo].[V_Message]
AS

select m.id,m.name,m.phone,m.email,m.topic,m.message,m.rectime as msgtime,m.account,vxi_chat.dbo.func_url(m.url) urlname,m.url refurl,m.agent,m.handletime,(case when m.handletime is null then '待处理' else '已处理' end)as status,m.remark as remarks from message m left join 
vxi_sys..agent s on m.agent=s.agent




GO
/****** Object:  View [dbo].[V_TimeSegment]    Script Date: 2016/9/5 13:35:12 ******/
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
ALTER TABLE [dbo].[Blacklist] ADD  CONSTRAINT [DF_Blacklist_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Customers] ADD  CONSTRAINT [DF_Customers_createDate]  DEFAULT (getdate()) FOR [createDate]
GO
ALTER TABLE [dbo].[HmSurvey] ADD  CONSTRAINT [DF_HmSurvey_SurveyTime]  DEFAULT (getdate()) FOR [SurveyTime]
GO
ALTER TABLE [dbo].[Login] ADD  CONSTRAINT [DF_Login_cause]  DEFAULT ((0)) FOR [cause]
GO
ALTER TABLE [dbo].[login_log] ADD  DEFAULT (getdate()) FOR [logintime]
GO
ALTER TABLE [dbo].[Message] ADD  DEFAULT (getdate()) FOR [message]
GO
ALTER TABLE [dbo].[Message] ADD  CONSTRAINT [DF_Message_recTime]  DEFAULT (getdate()) FOR [recTime]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_ClientPath1]  DEFAULT ((1)) FOR [ClosedPath]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_Enabled1]  DEFAULT ((1)) FOR [ClientPath]
GO
ALTER TABLE [dbo].[Projects] ADD  CONSTRAINT [DF_Projects_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Ready] ADD  CONSTRAINT [DF_Ready_cause]  DEFAULT ((0)) FOR [cause]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_LogFlag]  DEFAULT ((0)) FOR [LogFlag]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_FlagTime]  DEFAULT (getdate()) FOR [FlagTime]
GO
ALTER TABLE [dbo].[rt_agent] ADD  CONSTRAINT [DF_rt_agent_Cause]  DEFAULT ((0)) FOR [Cause]
GO
ALTER TABLE [dbo].[RtmConfig] ADD  CONSTRAINT [DF_RtmConfig_vipprompt]  DEFAULT ((1)) FOR [vipprompt]
GO
ALTER TABLE [dbo].[SDRBusy] ADD  CONSTRAINT [DF_SDRBusy_flagtime]  DEFAULT (getdate()) FOR [flagtime]
GO
ALTER TABLE [dbo].[SDRBusy] ADD  CONSTRAINT [DF_SDRBusy_isFinished]  DEFAULT ((0)) FOR [isFinished]
GO
ALTER TABLE [dbo].[SDRDetail] ADD  CONSTRAINT [DF_SDRDetail_StartTime]  DEFAULT (getdate()) FOR [StartTime]
GO
ALTER TABLE [dbo].[Shortcuts] ADD  CONSTRAINT [DF_Shortcuts_ITime]  DEFAULT (getdate()) FOR [ITime]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Folder]  DEFAULT ('/') FOR [Folder]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_User]  DEFAULT ('') FOR [User]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Password]  DEFAULT ('') FOR [Password]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_Backup]  DEFAULT ((0)) FOR [Backup]
GO
ALTER TABLE [dbo].[Store] ADD  CONSTRAINT [DF_Storage_KeepDays]  DEFAULT ((365)) FOR [KeepDays]
GO
ALTER TABLE [dbo].[Survey] ADD  CONSTRAINT [DF_Survey_SurveyTime]  DEFAULT (getdate()) FOR [SurveyTime]
GO
ALTER TABLE [dbo].[UploadFiles] ADD  CONSTRAINT [DF_UploadFiles_uploadTime]  DEFAULT (getdate()) FOR [uploadTime]
GO
ALTER TABLE [dbo].[ViaLog] ADD  DEFAULT (getdate()) FOR [viaTime]
GO
ALTER TABLE [dbo].[Viplist] ADD  CONSTRAINT [DF_Viplist_bPermanent]  DEFAULT ((0)) FOR [bPermanent]
GO
ALTER TABLE [dbo].[Viplist] ADD  CONSTRAINT [DF_Viplist_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Ready]  WITH CHECK ADD  CONSTRAINT [FK_Ready_Login] FOREIGN KEY([LogID])
REFERENCES [dbo].[Login] ([LogID])
GO
ALTER TABLE [dbo].[Ready] CHECK CONSTRAINT [FK_Ready_Login]
GO
ALTER TABLE [dbo].[SDRTrace]  WITH CHECK ADD  CONSTRAINT [FK_SDRTrace_SDR] FOREIGN KEY([SDRId])
REFERENCES [dbo].[SDR] ([SDRId])
GO
ALTER TABLE [dbo].[SDRTrace] CHECK CONSTRAINT [FK_SDRTrace_SDR]
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
         Begin Table = "AA"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 125
               Right = 196
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "BB"
            Begin Extent = 
               Top = 6
               Left = 234
               Bottom = 95
               Right = 376
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_AvgTime'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'V_AvgTime'
GO
