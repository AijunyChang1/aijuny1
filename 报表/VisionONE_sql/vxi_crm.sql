USE [master]
GO
CREATE DATABASE [vxi_crm]
GO

USE [vxi_crm]
GO
/****** Object:  DatabaseRole [ba]    Script Date: 2016/9/5 13:30:58 ******/
CREATE ROLE [ba]
GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_call_20070802]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[sp_assab_sch_call_20070802]
		@sch_type 	tinyint,		--查询类型	
		@date_begin 	datetime,               --开始日期	
		@date_end 	datetime,               --结束日期	
		@time_begin	datetime,               --开始时间 	
		@time_end	datetime,               --结束时间	
		@skill		varchar(20) = null,     --技能组		
		@agent		varchar(20) = null,     --员工代码	
		@client		varchar(50) = null,     --客户名称	
		@phone		varchar(20) = null,     --电话号码	
		@interval	int	    =30         --时间间隔 单位 分钟
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Agent	
(
	ID		int,	
	Agent		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_call
(	StartTime	datetime     ,
	Date		varchar(20)  ,
	Time		varchar(20)  ,
	Calling		varchar(20)  ,
	Called		varchar(20)  ,
	Client		varchar(50)  ,
	Agent		varchar(20)  ,
		
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)


--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)

end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<=0

--==================================================================================================================
--开始 取得的当前agent
--==================================================================================================================

--没有用identity
if(charindex(',',@agent)>0)
begin
	select @counter = 1
	while(charindex(',',@agent)>0)
	begin	
		if exists(select 1 from vxi_sys..Agent 
					where Agent = substring(@agent,1,charindex(',',@agent)-1))
		begin
			insert #tmp_current_Agent
			select @counter,substring(@agent,1,charindex(',',@agent)-1)
			select @Agent = substring(@agent,charindex(',',@agent)+1,len(@agent)-charindex(',',@agent))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'参数不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Agent
	select @counter,@agent
end
else 
begin
	if exists(select 1 from vxi_sys..Agent 
				where Agent = @agent)
	begin
		insert #tmp_current_Agent
		select @counter,@agent
	end
	else if(@agent is null)
	begin
		--如果技能组不为空，则以技能组取得所有agent
		if(@skill is not null)
		begin
			--输入技能组不为空且正确则选择技能组所有agent
			if exists(select 1 from vxi_sys..SkillAgent
						where skill = @skill )
			begin
				select @counter = count(*) from vxi_sys..SkillAgent
							where skill = @skill
				while(@counter>=1)
				begin
					insert into  #tmp_current_Agent
						select @counter,max(a.Agent) from vxi_sys..SkillAgent a
						where skill = @skill 
							and  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
					select @counter = @counter -1
				end
			end
			--输入技能组号错误
			else 
			begin
				select @omsg = '请输入正确的skill'
				goto l_fatal
			end
		end
		else --如果技能组为空则选择全部agent
		begin
			select @counter = count(*) from vxi_sys..Agent						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Agent
					select @counter,max(a.Agent) from vxi_sys..Agent a
					where  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
				select @counter = @counter -1
			end
			
		end
	end
end
if not exists(select 1 from #tmp_current_Agent)
begin
	select @omsg= '请输入agent！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前Agent
--==================================================================================================================
	
select @counter = count(*) 
		from #tmp_current_Agent --统计出agent数量放入计数器里
while (@counter >= 1)
begin
	select @agent = Agent 
		from #tmp_current_Agent 
	where id  = (select min(id) from #tmp_current_Agent )
	delete from #tmp_current_Agent where agent = @agent	

	if (@sch_type = '1')
	begin	
		insert into #tmp_call 
		(
			startTime 	 ,   
			date		 ,   
			time		 ,   
			Calling		 ,   
			Called		 ,   
			Client		 ,   
			Agent		 
		) 

		select  a.StartTime,
			substring(convert(varchar(32),a.StartTime,120),1,11),
			substring(convert(varchar(32),a.StartTime,120),12,5),
			a.calling,
			a.called,
			a.ClientId,
			@agent
		from #tmp_current_data a,#tmp_current_time b	
		where 	agent = @agent and a.Inbound = '1'
			and datediff(s,a.StartTime,b.end_time)>0
			and datediff(s,a.StartTime,b.start_time)<0
	end
	
	else if (@sch_type = '2')
	begin	
		insert into #tmp_call 
		(
			startTime 	 ,   
			date		 ,   
			time		 ,   
			Calling		 ,   
			Called		 ,   
			Client		 ,   
			Agent		 
		) 

		select  a.StartTime,
			substring(convert(varchar(32),a.StartTime,120),1,11),
			substring(convert(varchar(32),a.StartTime,120),12,5),
			a.calling,
			a.called,
			a.ClientId,
			@agent
		from #tmp_current_data a,#tmp_current_time b	
		where 	agent = @agent and a.Outbound = '1'
			and datediff(s,a.StartTime,b.end_time)>0
			and datediff(s,a.StartTime,b.start_time)<0
	end	

--对于放弃的呼叫开始时间是以偏移量来计算还是一Ucd中的StartTime来计算呢？下面例子是以偏移量来计算的
	else if(@sch_type = '3')
		begin
		insert into #tmp_call 
		(
			startTime 	 ,   
			date		 ,   
			time		 ,   
			Calling		 ,   
			Called		 ,   
			Client		 ,   
			Agent		 
		) 

		select  a.StartTime,
			substring(convert(varchar(32),a.StartTime,120),1,11),
			substring(convert(varchar(32),a.StartTime,120),12,5),
			a.calling,
			a.called,
			a.ClientId, 
			@agent
		from #tmp_current_data a,#tmp_current_time b	
		where 	agent = @agent and a.bEstb = '0'--放弃标记				
			and datediff(s,a.StartTime,b.end_time)>0
			and datediff(s,a.StartTime,b.start_time)<0
		end
	else 
	begin
		select @omsg = '输入的@sch_type参数不合法!'
		goto l_fatal

	end
	select @counter = @counter - 1
end
/*输出电话清单*/
select  startTime 	 ,   
	date		 ,   
	time		 ,   
	Calling		 ,   
	Called		 ,   
	Client		 ,   
	Agent		 
from   #tmp_call
	
return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_call_base]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_sch_call_base]
		@sch_type 	tinyint,		--查询类型 1-呼入, 2-呼出, 3-放弃
		@date_begin datetime,               --开始日期	
		@date_end 	datetime,               --结束日期	
		@time_begin	datetime,               --开始时间 	
		@time_end	datetime,               --结束时间	
		@skill		varchar(20) = null,     --技能组		
		@agent		varchar(20) = null,     --员工代码	
		@client		varchar(50) = null,     --客户名称	
		@phone		varchar(20) = null,     --电话号码	
		@interval	int	= 30				--时间间隔 单位 分钟 默认的当天的时间段	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare	@str_sql		nvarchar(4000),
			@range_begin	datetime,
			@range_end		datetime,
			@time_begin_int	int,
			@time_end_int	int,
			@result			int

	select	@range_begin = left(convert(varchar(50), @date_begin, 120), 10) + ' 00:00:00',
			@range_end = left(convert(varchar(50), @date_end, 120), 10) + ' 23:59:59.997',
			@time_begin_int = datepart(hour, @time_begin) * 64 + datepart(minute, @time_begin),
			@time_end_int = datepart(hour, @time_end) * 64 + datepart(minute, @time_end)

	--select	@range_begin '@range_begin', @range_end '@range_end', @time_begin_int '@time_begin_int',
	--		@time_end_int '@time_end_int'

	set @str_sql = '
	select  u.StartTime,
			left(convert(varchar(50), u.StartTime, 120), 10) Date,
			substring(convert(varchar(50), u.StartTime, 120), 12, 5) Time,
			c.Calling,   	--主叫号码
			c.Called,   	--被叫号码
			'''' Client 	--客户名称
'
		+ case when @sch_type != 3 then ', c.Agent 		--员工代码'	-- 放弃无此列
			   else ', NULL Agent'
		  end
		+
'
	from 
	(
		select * from ucd
		where (StartTime between @range_begin and @range_end)
			and ((datepart(hour, StartTime) * 64 + datepart(minute, StartTime)) 
				between @time_begin_int and @time_end_int)
	) u
	inner join ucdcall c on u.ucdid = c.ucdid
	where left(c.Calling, 1) != ''T'' and '
		+ case when @sch_type != 3 then
			   'c.Type = ' + cast(@sch_type as char(1)) -- 1-呼入 2-呼出
			   else
			   'c.bEstb = 0'	-- 3-放弃
		  end
		+ case when len(isnull(@skill, '')) > 0 then
			   ' and c.Skill = ''' + @skill + ''''
			   else ''
		  end
		+ case when len(isnull(@agent, '')) > 0 then
			   ' and c.Agent = ''' + @agent + ''''
			   else ''
		  end
		+ case when len(isnull(@phone, '')) > 0 then
			   ' and (case when c.Type != 2 then c.Calling else c.Called end = ''' + @phone + ''')'
			   else ''
		  end

	-- for debug
	--print @str_sql

	exec @result = sp_executesql @str_sql,
					N'@range_begin datetime,
					  @range_end datetime, 
					  @time_begin_int int,
					  @time_end_int	int',
					@range_begin = @range_begin,
					@range_end = @range_end,
					@time_begin_int = @time_begin_int,
					@time_end_int = @time_end_int
					
	if @@error != 0 or @result != 0 begin
		raiserror('sp_executesql error!', 1, 1)
	end

	return @result
END
GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_stat_agent]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_sch_stat_agent]                 
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@agent		varchar(2000) = null,   --作席代码
		@skill		varchar(20) = null,     --技能组	 
		@interval	int = 30            	--时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Agent	
(
	ID		int,	
	Agent		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Agent		varchar(20),
	RecDate		datetime,
	TimeStr		varchar(50),
	Login_t		int,
	SkillIn_t	int,
	SkillIn_n	int,
	AvgRing_t	int,
	AvgTalk_t	int,
	ExtInt_t	int,
	ExtOut_t	int,
	Ready_t		int,
	Hold_t		int,
	ExtIn_n		int,
	ExtOut		int,
	Time_ID		int
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,	
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)


/*筛选vxi_ucd..login ,vxi_ucd..ready的最小数据结果集*/
create table  #tmp_current_login
(		             
	[LogID]     	bigint		not null,
	[Agent]     	char(16)	not null,
	[Device]    	varchar(50)	not null,
	[Skills]    	varchar(50)	null,
	[StartTime] 	datetime	null,
	[EndTime]   	datetime	null,
	[SubID]     	smallint	not null,
	[Finish]    	bit		null,
	[Flag]      	tinyint		null,
	[OnStart]   	int		null,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	int		null  --事件持续时间长度

)


--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)
end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>=0 
	and datediff(day,@current_date_end,a.StartTime)<=0
	
--作席login ready数据统计	
insert into #tmp_current_login
(
	[LogID]     ,
	[Agent]     ,
	[Device]    ,
	[Skills]    ,
	[StartTime] ,
	[EndTime]   ,
	[SubID]     ,
	[Finish]    ,
	[Flag]      ,
	[OnStart]   ,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	  --事件持续时间长度
)
select 
	a.[LogID]     ,
	a.[Agent]     ,
	a.[Device]    ,
	a.[Skills]    ,
--	a.[Finish]    ,
--	a.[Flag]      ,
	a.[StartTime] ,
--	a.[TimeLen]   ,
	a.[EndTime]   ,
--	a.[ReadyLen]  ,
--	a.[AcwLen]    ,
--	a.[cause]     ,     
	
--	b.[LogID]     ,
	b.[SubID]     ,
	b.[Finish]    ,
	b.[Flag]      ,
	b.[StartTime] as OnStart ,--进入当前状态时间偏移量
	b.[TimeLen]   	  --事件持续时间长度
--	b.[cause] 
from vxi_ucd..Login a , vxi_ucd..Ready b
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<= 0
	and a.LogID = b.LogID
--==================================================================================================================
--开始 取得的当前agent
--==================================================================================================================

--没有用identity
if(charindex(',',@agent)>0)
begin
	select @counter = 1
	while(charindex(',',@agent)>0)
	begin	
		if exists(select 1 from vxi_sys..Agent 
					where Agent = substring(@agent,1,charindex(',',@agent)-1))
		begin
			insert #tmp_current_Agent
			select @counter,substring(@agent,1,charindex(',',@agent)-1)
			select @Agent = substring(@agent,charindex(',',@agent)+1,len(@agent)-charindex(',',@agent))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'参数不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Agent
	select @counter,@agent
end
else 
begin
	if exists(select 1 from vxi_sys..Agent 
				where Agent = @agent)
	begin
		insert #tmp_current_Agent
		select @counter,@agent
	end
	else if(@agent is null)
	begin
		--如果技能组不为空，则以技能组取得所有agent
		if(@skill is not null)
		begin
			--输入技能组不为空且正确则选择技能组所有agent
			if exists(select 1 from vxi_sys..SkillAgent
						where skill = @skill )
			begin
				select @counter = count(*) from vxi_sys..SkillAgent
							where skill = @skill
				while(@counter>=1)
				begin
					insert into  #tmp_current_Agent
						select @counter,max(a.Agent) from vxi_sys..SkillAgent a
						where skill = @skill 
							and  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
					select @counter = @counter -1
				end
			end
			--输入技能组号错误
			else 
			begin
				select @omsg = '请输入正确的skill'
				goto l_fatal
			end
		end
		else --如果技能组为空则选择全部agent
		begin
			select @counter = count(*) from vxi_sys..Agent						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Agent
					select @counter,max(a.Agent) from vxi_sys..Agent a
					where  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
				select @counter = @counter -1
			end
			
		end
	end
end
if not exists(select 1 from #tmp_current_Agent)
begin
	select @omsg= '请输入agent！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前Agent
--==================================================================================================================


--==================================================================================================================
--开始 将Agent的工作情况放入临时表中
--==================================================================================================================

--其中Agent & time_id作为PK,注意Agent必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Agent --统计出agent数量放入计数器里
while (@counter >= 1)
begin
	select @agent = Agent 
		from #tmp_current_Agent 
			where id  = (select min(id) from #tmp_current_Agent )
	delete from #tmp_current_Agent where agent = @agent	
	
	--
	insert into  #tmp_stats
	(	Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		,
		Time_ID		
	)
	select 
		@Agent,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(Agent.login_t,0) as Login_t,	
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgRing_t.AvgRing_t,0) as AvgRing_t,
		isnull(AvgTalk_t.AvgTalk_t,0) as AvgTalk_t,
		isnull(ExtIn.ExtIn_t,0) as ExtIn_t,
		isnull(ExtOut.ExtOut_t,0) as ExtOut_t,
		isnull(Agent.Ready_t,0) as Ready_t,
		isnull(Hold_t.Hold_t,0) as Hold_t,
		isnull(ExtIn.ExtIn_n,0) as ExtIn_n,
		isnull(ExtOut.ExtOut_n,0) as ExtOut_n,
		Agent.time_id
	
	from 	#tmp_current_time TM 
		--不要忽略一个问题 login 包含 ready
		--统计Agent的login时间、Ready时间 

	left join(
			select 	time_id			,

			    sum(
					datediff(
							second
							,
							case when datediff(s,b.start_time,a.startTime) >0 
								then a.startTime  	else b.start_time end 
							,
							case when  datediff(s,b.end_time,a.EndTime) >0 
								then b.end_time		else a.EndTime end
						)
			       )As login_t, --login(工作)时间，秒
				sum(
					case when a.flag = 0x02
	      				then datediff(
							second
							,
							case when  datediff(s,b.start_time,dateadd(ms,a.OnStart,a.startTime)) >0 
								then dateadd(ms,a.OnStart,a.startTime)	else b.start_time end 
							,
							case when  datediff(s,b.end_time,dateadd(ms,a.OnStart+a.TimeLen,a.startTime)) >0 
								then b.end_time  else dateadd(ms,a.OnStart+a.TimeLen,a.startTime) end
							) 
		      		else 0 end
					)As Ready_t --Ready时间，秒
					 	 
			from #tmp_current_login a, #tmp_current_time b                                                                        
			where   a.Agent = @Agent
				and datediff(s,a.StartTime,b.end_time)>0 
				and datediff(s,a.EndTime,b.start_time)<0				
			group by b.time_id
			
		)Agent on TM.time_id = Agent.time_id
	
	left join
		--统计Agent所在Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   a.agent = @agent 
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and isnull(a.skill,'')<>'' and a.type = 1 --技能组号不为空，为呼入号码
			  	group by b.time_ID
		 ) ACD   on Agent.time_ID = ACD.time_ID
	
	left join 
		--统计Agent平均震铃时长
		(
			select 	b.time_id ,
				sum(a.OnEstb - a.OnRing) /count(1)  as AvgRing_t--平均震铃时长
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bRing = '1' and a.type = 1
			group by b.time_ID
		
		) AvgRing_t on  ACD.time_id = AvgRing_t.time_id
	  	
	left join 
		--统计Agent的平均通话时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd- a.OnEstb) /count(1) as AvgTalk_t --平均通话时长
			from  #tmp_current_data a,#tmp_current_time b
			where   agent = @agent 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgTalk_t on AvgRing_t.time_id = AvgTalk_t.time_id
		  	
	left join
		--统计Agent的分机呼入时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtIn_t ,--分机呼入时长
				count(1) 	as ExtIn_n--分机呼入次数
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent and skill is null --注意此处条件即为分机呼入时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
			  	
		) ExtIn on AvgTalk_t.time_id = ExtIn.time_id
	left join 
		--统计Agent的分机保持时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnHold)	as Hold_t --分机保持时长
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.start_time)<0
			  	and bHold = '1' and a.type = 1
			group by b.time_ID
			  	
		  )Hold_t on  ExtIn.time_id = Hold_t.time_id
	left join
		--统计Agent的分机呼出时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtOut_t,--分机呼出时长
				count(1) 	as ExtOut_n--分机呼出次数
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent --and skill is null --注意此处即为分机呼出时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 2
			group by b.time_ID
			  	
		) ExtOut on  Hold_t.time_id = ExtOut.time_id
	

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将Agent的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 
		Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_stat_agent_daily]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_sch_stat_agent_daily]
		@sch_type 	tinyint,		--查询类型	
		@date_begin 	datetime,               --开始日期	
		@date_end 	datetime,               --结束日期	
		@time_begin	datetime,               --开始时间 	
		@time_end	datetime,               --结束时间	
		@skill		varchar(20) = null,     --技能组		
		@agent		varchar(20) = null,     --员工代码	
		@client		varchar(50) = null,     --客户名称	
		@phone		varchar(20) = null,     --电话号码	
		@interval	int	    =30         --时间间隔 单位 分钟
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Agent	
(
	ID		int,	
	Agent		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_call
(	startTime	datetime     ,
	date		varchar(20)  ,
	time		varchar(20)  ,
	Calling		varchar(20)  ,
	Called		varchar(20)  ,
	Client		varchar(50)  ,
	Agent		varchar(20)  ,
		
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)


--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)
	print @current_date_begin
	print @date_end
end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
--	a.[Calling],
--	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
--	a.[Inbound],
--	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(ms,@current_date_begin,a.StartTime)>0 
	and datediff(ms,@current_date_end,a.StartTime)<0

--==================================================================================================================
--开始 取得的当前agent
--==================================================================================================================


if(charindex(',',@agent)>0)
begin
	select @counter = 1
	while(charindex(',',@agent)>0)
	begin	
		if exists(select 1 from vxi_sys..Agent 
					where Agent = substring(@agent,1,charindex(',',@agent)-1))
		begin
			insert #tmp_current_Agent
			select @counter,substring(@agent,1,charindex(',',@agent)-1)
			select @Agent = substring(@agent,charindex(',',@agent)+1,len(@agent)-charindex(',',@agent))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'参数不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Agent
	select @counter,@agent
end
else 
begin
	if exists(select 1 from vxi_sys..Agent 
				where Agent = substring(@agent,1,charindex(',',@agent)-1))
	begin
		insert #tmp_current_Agent
		select @counter,@agent
	end
	else --不存在的agent
	begin
		select @omsg = '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'不合法'
		goto l_fatal
	end
end
if not exists(select 1 from #tmp_current_Agent)
begin
	select @omsg= '请输入agent！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前Agent
--==================================================================================================================	
select @counter = count(*) 
		from #tmp_current_Agent --统计出agent数量放入计数器里
while (@counter >= 1)
begin
	select @agent = Agent 
		from #tmp_current_Agent 
	where id  = (select min(id) from #tmp_current_Agent )
	delete from #tmp_current_Agent where agent = @agent	

	if (@sch_type = '1')
	begin	
		insert into #tmp_call 
		(
			startTime 	 ,   
			date		 ,   
			time		 ,   
			Calling		 ,   
			Called		 ,   
			Client		 ,   
			Agent		 
		) 

		select  a.StartTime,
			substring(convert(varchar(32),a.StartTime,120),1,11),
			substring(convert(varchar(32),a.StartTime,120),12,5),
			a.calling,
			a.called,
			'NotSure',
			a.agent
		from #tmp_current_data a
		where agent = @agent and a.Inbound = '1'
	end
	
	else if (@sch_type = '2')
	begin	
		insert into #tmp_call 
		(
			startTime 	 ,   
			date		 ,   
			time		 ,   
			Calling		 ,   
			Called		 ,   
			Client		 ,   
			Agent		 
		) 

		select  a.StartTime,
			substring(convert(varchar(32),a.StartTime,120),1,11),
			substring(convert(varchar(32),a.StartTime,120),12,5),
			a.calling,
			a.called,
			'NotSure',
			a.agent
		from #tmp_current_data a
		where agent = @agent and a.Outbound = '1'
	end	

--对于放弃的呼叫开始时间是以偏移量来计算还是一Ucd中的StartTime来计算呢？下面例子是以偏移量来计算的
	else if(@sch_type = '3')
		begin
		insert into #tmp_call 
		(
			startTime 	 ,   
			date		 ,   
			time		 ,   
			Calling		 ,   
			Called		 ,   
			Client		 ,   
			Agent		 
		) 

		select  a.StartTime,
			substring(convert(varchar(32),a.StartTime,120),1,11),
			substring(convert(varchar(32),a.StartTime,120),12,5),
			a.calling,
			a.called,
			'NotSure', --
			a.agent
		from #tmp_current_data a
		where agent = @agent and b.bEstb = '0'--放弃标记				
	
		end
	else 
	begin
		select @omsg = '输入的@sch_type参数不合法!'
		goto l_fatal

	end
	select @counter = @counter - 1
end
/*输出电话清单*/
select  startTime 	 ,   
	date		 ,   
	time		 ,   
	Calling		 ,   
	Called		 ,   
	Client		 ,   
	Agent		 
from   #tmp_call
	
return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_stat_skill]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_sch_stat_skill]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30            --时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Skill	
(
	ID		int,	
	Skill		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Skill		varchar(20),       
	RecDate		datetime,          
	TimeStr		varchar(100),	
	Skill_t		int,            
	Skill_n		int,            
	AvgWait_t	int,	                
	AvgAban_t	int,                    
	Aban_n		int,            
	ToAdmin_n	int    
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)
--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)

end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<=0

--==================================================================================================================
--开始 取得的当前skill
--==================================================================================================================


if(charindex(',',@skill)>0)
begin
	select @counter = 1
	while(charindex(',',@skill)>0)
	begin	
		if exists(select 1 from vxi_sys..skill 
					where skill = substring(@skill,1,charindex(',',@skill)-1))
		begin
			insert #tmp_current_Skill
			select @counter,substring(@skill,1,charindex(',',@skill)-1)
			select @skill = substring(@skill,charindex(',',@skill)+1,len(@skill)-charindex(',',@skill))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的skill'+substring(@skill,1,charindex(',',@skill)-1)+'不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Skill
	select @counter,@skill
end
else 
begin
	if exists(select 1 from vxi_sys..skill 
				where skill = @skill)
	begin
		insert #tmp_current_Skill
		select @counter,@skill
	end
	else --不存在的skill
	begin
		select @omsg = '输入的技能组'+@skill+'不合法'
		goto l_fatal
	end
end
if not exists(select 1 from #tmp_current_Skill)
begin
	select @omsg= '请输入skill！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前skill
--==================================================================================================================
	

--==================================================================================================================
--开始 将skill的工作情况放入临时表中
--==================================================================================================================

--其中skill & time_id作为PK,注意skill必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Skill --统计出skill数量放入计数器里
while (@counter >= 1)
begin
	select @skill = skill 
		from #tmp_current_Skill 
			where id  = (select min(id) from #tmp_current_Skill )
	delete from #tmp_current_Skill where skill = @skill
		
	insert into  #tmp_stats
	(	Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ToAdmin_n	
	)
	select 
		@skill,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgWait_t.AvgWait_t,0) as AvgWait_t,
		isnull(Aban.AvgAban_t,0) as AvgAban_t,
		isnull(Aban.Aban_n,0) as Aban_n,
		0
	from 	#tmp_current_time TM 	
	left join		
		--统计Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and a.type = 1 
			  	group by b.time_ID
		 ) ACD   on TM.time_ID = ACD.time_ID
		 
	left join 
		--统计Skill平均应答时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnEstb) /count(1) as AvgWait_t --平均应答时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgWait_t on ACD.time_id = AvgWait_t.time_id
		  	
	left join
		--统计平均放弃时长，放弃呼叫数量
		(
			select 	b.time_id 	as Time_id,
				count(1)	as Aban_n ,--放弃呼叫数量
				sum(a.OnEstb) /count(1) as AvgAban_t --平均放弃时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 1
			group by b.time_ID
		
		) Aban on AvgWait_t.time_id = Aban.time_id

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将skill的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 		Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ToAdmin_n	
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_stat_skill_daily]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_sch_stat_skill_daily]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30            --时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Skill	
(
	ID		int,	
	Skill		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Skill		varchar(20),       
	RecDate		datetime,          
	TimeStr		varchar(100),	
	Skill_t		int,            
	Skill_n		int,            
	AvgWait_t	int,	                
	AvgAban_t	int,                    
	Aban_n		int,            
	ToAdmin_n	int    
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)
--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)

end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<=0

--==================================================================================================================
--开始 取得的当前skill
--==================================================================================================================


if(charindex(',',@skill)>0)
begin
	select @counter = 1
	while(charindex(',',@skill)>0)
	begin	
		if exists(select 1 from vxi_sys..skill 
					where skill = substring(@skill,1,charindex(',',@skill)-1))
		begin
			insert #tmp_current_Skill
			select @counter,substring(@skill,1,charindex(',',@skill)-1)
			select @skill = substring(@skill,charindex(',',@skill)+1,len(@skill)-charindex(',',@skill))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的skill'+substring(@skill,1,charindex(',',@skill)-1)+'不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Skill
	select @counter,@skill
end
else 
begin
	if exists(select 1 from vxi_sys..skill 
				where skill = @skill)
	begin
		insert #tmp_current_Skill
		select @counter,@skill
	end
	else --不存在的skill
	begin
		select @omsg = '输入的技能组'+@skill+'不合法'
		goto l_fatal
	end
end
if not exists(select 1 from #tmp_current_Skill)
begin
	select @omsg= '请输入skill！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前skill
--==================================================================================================================
	

--==================================================================================================================
--开始 将skill的工作情况放入临时表中
--==================================================================================================================

--其中skill & time_id作为PK,注意skill必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Skill --统计出skill数量放入计数器里
while (@counter >= 1)
begin
	select @skill = skill 
		from #tmp_current_Skill 
			where id  = (select min(id) from #tmp_current_Skill )
	delete from #tmp_current_Skill where skill = @skill
		
	insert into  #tmp_stats
	(	Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ToAdmin_n	
	)
	select 
		@skill,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgWait_t.AvgWait_t,0) as AvgWait_t,
		isnull(Aban.AvgAban_t,0) as AvgAban_t,
		isnull(Aban.Aban_n,0) as Aban_n,
		0
	from 	#tmp_current_time TM 	
	left join		
		--统计Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and a.type = 1 
			  	group by b.time_ID
		 ) ACD   on TM.time_ID = ACD.time_ID
		 
	left join 
		--统计Skill平均应答时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnEstb) /count(1) as AvgWait_t --平均应答时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgWait_t on ACD.time_id = AvgWait_t.time_id
		  	
	left join
		--统计平均放弃时长，放弃呼叫数量
		(
			select 	b.time_id 	as Time_id,
				count(1)	as Aban_n ,--放弃呼叫数量
				sum(a.OnEstb) /count(1) as AvgAban_t --平均放弃时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 1
			group by b.time_ID
		
		) Aban on AvgWait_t.time_id = Aban.time_id

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将skill的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 		Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ToAdmin_n	
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_sch_stat_skill_hourly]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_sch_stat_skill_hourly]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30            --时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Skill	
(
	ID		int,	
	Skill		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Skill		varchar(20),       
	RecDate		datetime,          
	TimeStr		varchar(100),	
	Skill_t		int,            
	Skill_n		int,            
	AvgWait_t	int,	                
	AvgAban_t	int,                    
	Aban_n		int,      
	ExtOut_t	int,
	AvgExtOut_t	int,      
	ToAdmin_n	int    
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)
--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)

end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<=0

--==================================================================================================================
--开始 取得的当前skill
--==================================================================================================================


if(charindex(',',@skill)>0)
begin
	select @counter = 1
	while(charindex(',',@skill)>0)
	begin	
		if exists(select 1 from vxi_sys..skill 
					where skill = substring(@skill,1,charindex(',',@skill)-1))
		begin
			insert #tmp_current_Skill
			select @counter,substring(@skill,1,charindex(',',@skill)-1)
			select @skill = substring(@skill,charindex(',',@skill)+1,len(@skill)-charindex(',',@skill))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的skill'+substring(@skill,1,charindex(',',@skill)-1)+'不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Skill
	select @counter,@skill
end
else 
begin
	if exists(select 1 from vxi_sys..skill 
				where skill = @skill)
	begin
		insert #tmp_current_Skill
		select @counter,@skill
	end
	else --不存在的skill
	begin
		select @omsg = '输入的技能组'+@skill+'不合法'
		goto l_fatal
	end
end
if not exists(select 1 from #tmp_current_Skill)
begin
	select @omsg= '请输入skill！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前skill
--==================================================================================================================
	

--==================================================================================================================
--开始 将skill的工作情况放入临时表中
--==================================================================================================================

--其中skill & time_id作为PK,注意skill必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Skill --统计出skill数量放入计数器里
while (@counter >= 1)
begin
	select @skill = skill 
		from #tmp_current_Skill 
			where id  = (select min(id) from #tmp_current_Skill )
	delete from #tmp_current_Skill where skill = @skill
		
	insert into  #tmp_stats
	(	Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ExtOut_t	,
		AvgExtOut_t	,  
		ToAdmin_n	
	)
	select 
		@skill,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgWait_t.AvgWait_t,0) as AvgWait_t,
		isnull(Aban.AvgAban_t,0) as AvgAban_t,
		isnull(Aban.Aban_n,0) as Aban_n,
		isnull(ExtOut.ExtOut_t,0) as ExtOut_t, 
		isnull(ExtOut.AvgExtOut_t,0) as AvgExtOut_t,
		0
	from 	#tmp_current_time TM 	
	left join		
		--统计Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and a.type = 1 
			  	group by b.time_ID
		 ) ACD   on TM.time_ID = ACD.time_ID
		 
	left join 
		--统计Skill平均应答时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnEstb) /count(1) as AvgWait_t --平均应答时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgWait_t on ACD.time_id = AvgWait_t.time_id
		  	
	left join
		--统计平均放弃时长，放弃呼叫数量
		(
			select 	b.time_id 	as Time_id,
				count(1)	as Aban_n ,--放弃呼叫数量
				sum(a.OnEstb) /count(1) as AvgAban_t --平均放弃时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 1
			group by b.time_ID
		
		) Aban on AvgWait_t.time_id = Aban.time_id
	left join
		--分机呼出时长，分机呼出平均时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd) as ExtOut_t ,--分机呼出时长
				sum(a.OnCallEnd) /count(1) as AvgExtOut_t --分机平均呼出时长
			from  #tmp_current_data a,#tmp_current_time b,(select agent from vxi_sys..SkillAgent where skill = @skill) c
			where   a.agent = c.agent
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 2
			group by b.time_ID
		) ExtOut on Aban.time_id = ExtOut.time_id

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将skill的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 		Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ExtOut_t	,
		AvgExtOut_t	, 
		ToAdmin_n	
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_agent_a_b]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_assab_stat_agent_a_b] 
	-- Add the parameters for the stored procedure here
		@repdate 	datetime,               --报表日期
		@date_begin datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,				--结束时间
		@agent		varchar(2000) = null,   --座席代码
		@skill		varchar(20) = null,     --技能组	 
		@interval	int = 30,            	--时间间隔
		@group_level varchar(200)			-- hour/day
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @date_time_begin_value	bigint, 
			@date_time_end_value	bigint,
			@time_begin_value		int, 
			@time_end_value			int,
			@str_sql				nvarchar(4000), 
			@str_date_part			nvarchar(500),
			@str_agent_where		nvarchar(1200),
			@str_order_by			nvarchar(100),
			@result					int

	select	@date_time_begin_value = convert(varchar(20), @date_begin, 112),	-- yyyymmdd
			@date_time_end_value = convert(varchar(20), @date_end, 112),		-- yyyymmdd
			@time_begin_value = datepart(hour, @time_begin) * 100 + datepart(minute, @time_begin), -- hhnn
			@time_end_value = datepart(hour, @time_end) * 100 + datepart(minute, @time_end),		-- hhnn
			@date_time_begin_value = @date_time_begin_value * 10000 + @time_begin_value,	-- yyyymmddhhnn
			@date_time_end_value = @date_time_end_value * 10000 + @time_end_value	-- yyyymmddhhnn
	
	if lower(@group_level) = 'hour' begin
		-- 按小时
		select	@str_date_part = 'RecDT', 
				@str_order_by = '2, 1, 3',	-- 日期、座席、时间
				@str_sql = 'select	rtrim(isnull(ca.Agent, sa.Agent)) Agent, -- 座席
									dbo.func_get_date_str_part(isnull(ca.RecDT, sa.RecDT)) RecDate,	-- 记录日期
									dbo.func_get_time_str_part(isnull(ca.RecDT, sa.RecDT), @interval) TimeStr,	-- 时间范围'
	end
	else begin
		-- 按天
		select	@str_date_part = '(RecDT / 10000)', 
				@str_order_by = '1, 2',		-- 日期、座席
				@str_sql = 'select	dbo.func_get_date_str_part(isnull(ca.RecDT, sa.RecDT)) RecDate,	-- 记录日期
									rtrim(isnull(ca.Agent, sa.Agent)) Agent, -- 座席'
	end

	set @str_agent_where = case when len(rtrim(@agent)) > 0 
								then ' and agent in (' + @agent + ') '
								else ''
						   end

    --select	@date_time_begin_value 'date_time_begin_value', @date_time_end_value 'date_time_end_value',
	--		@time_begin_value 'time_begin_value', @time_end_value 'time_end_value'

	set @str_sql = @str_sql + /* Select ..., */ '
			sa.Login_t,			-- 工作时间
			ca.SkillIn_t,		-- ACD呼入时长
			ca.SkillIn_n,		-- ACD呼入数量
			ca.AvgRing_t,		-- 平均震铃时长
			ca.AvgTalk_t,		-- 平均通话时长
			ca.ExtIn_t,			-- 分机呼入时长
			ca.ExtOut_t,		-- 分机呼出时长
			case when (sa.Ready_t - isnull(ca.SkillIn_t, 0) - isnull(ca.Ans_t, 0) - isnull(ca.Aban_t, 0)) >= 0 then
				sa.Ready_t - isnull(ca.SkillIn_t, 0) - isnull(ca.Ans_t, 0) - isnull(ca.Aban_t, 0)
			end Ready_t,		-- 就绪状态时长
			ca.Hold_t,			-- 呼叫保持时长
			ca.ExtIn_n,			-- 分机呼入次数
			ca.ExtOut_n,		-- 分机呼出次数
			sa.NotReady_t,		-- 坐席置忙时间(AUX)
			sa.Acw_t			-- 坐席话后工作时间(ACW)
	from
	(
		select	top 100 percent 
'
				+ @str_date_part + ' RecDT,' +							-- 日期
'				Agent,													-- 员工代码
				dbo.ms_to_int_sec(sum(Skill_t)) SkillIn_t,				-- ACD呼入时长
				sum(Ans_n) SkillIn_n,									-- ACD呼入数量

				dbo.ms_to_int_sec(sum(Ans_t)) Ans_t,					-- 接通振铃时长
				dbo.ms_to_int_sec(sum(Aban_t)) Aban_t,					-- 未接振铃时长

				case when sum(Ans_n) != 0
					 then dbo.ms_to_int_sec(cast(sum(Ans_t) as float) / sum(Ans_n)) 
					 else 0 end AvgRing_t,								-- 平均振铃时长

				case when sum(Ans_n) != 0
					 then dbo.ms_to_int_sec(cast(sum(Skill_t) as float) / sum(Ans_n))
					 else 0 end AvgTalk_t,								-- 平均通话时长
				
				dbo.ms_to_int_sec(sum(ExtIn_t)) ExtIn_t,				-- 分机呼入时长
				dbo.ms_to_int_sec(sum(OutTalk_t)) ExtOut_t,				-- 分机呼出时长

				dbo.ms_to_int_sec(sum(
					case when Hold_t < 0 then cast(3 + rand() * 7 as int) else Hold_t end
				)) Hold_t,	-- 呼叫保持时长
				sum(ExtIn_n) ExtIn_n,									-- 分机呼入次数
				sum(OutTalk_n) ExtOut_n									-- 分机呼出次数
		from stat_call_agent
		where (RecDT between @date_time_begin_value and @date_time_end_value)
			and ((RecDT % 10000) between @time_begin_value and @time_end_value)
'		  + @str_agent_where + '
		group by ' + @str_date_part + ', Agent
		order by 1, 2
	) ca
	full join
	(
		select	top 100 percent 
'
				+ @str_date_part + ' RecDT,' +							-- 日期
'				Agent,													-- 员工代码
				dbo.ms_to_int_sec(sum(Login_t)) Login_t,				-- 登录时间
				dbo.ms_to_int_sec(sum(Ready_t)) Ready_t,				-- 就绪状态时长
				dbo.ms_to_int_sec(isnull(sum(NotReady00_t), 0)
								+ isnull(sum(NotReady01_t), 0)
								+ isnull(sum(NotReady02_t), 0)
								+ isnull(sum(NotReady03_t), 0)
								+ isnull(sum(NotReady04_t), 0)
								+ isnull(sum(NotReady05_t), 0)
								+ isnull(sum(NotReady06_t), 0)
								+ isnull(sum(NotReady07_t), 0)
								+ isnull(sum(NotReady08_t), 0)
								+ isnull(sum(NotReady09_t), 0)
								) NotReady_t,							-- 坐席置忙时间(AUX)
				dbo.ms_to_int_sec(sum(Acw_t)) Acw_t						-- 坐席话后工作时间(ACW)
		from stat_agent		
		where (RecDT between @date_time_begin_value and @date_time_end_value)
			and ((RecDT % 10000) between @time_begin_value and @time_end_value)
'		  + @str_agent_where + '
		group by ' + @str_date_part + ', Agent
		order by 1, 2
	) sa
	on ca.RecDT = sa.RecDT and ca.Agent = sa.Agent
	order by ' + @str_order_by
	
	-- for debug
	--print @str_sql
	--print len(@str_sql)

	exec @result = sp_executesql @str_sql,
					N'@interval int,
					  @date_time_begin_value bigint, 
					  @date_time_end_value bigint,
					  @time_begin_value	int, 
					  @time_end_value int',
					@interval = @interval,
					@date_time_begin_value = @date_time_begin_value,
					@date_time_end_value = @date_time_end_value,
					@time_begin_value = @time_begin_value,
					@time_end_value = @time_end_value
					
	if @@error != 0 or @result != 0 begin
		raiserror('sp_executesql error!', 1, 1)
	end

	return @result
END


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_agent_daily]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_assab_stat_agent_daily] 
	-- Add the parameters for the stored procedure here
		@repdate 	datetime,               -- 报表日期
		@date_begin 	datetime,           -- 开始日期
		@date_end	datetime,               -- 结束日期
		@agent		varchar(2000) = null,   -- 作席代码
		@skill		varchar(20) = null,     -- 技能组	 
		@interval	int = 30,          		-- 时间间隔
		@time_begin	datetime = '1981-09-10 00:00:00.000',	-- 开始时间
		@time_end	datetime = '1981-09-10 23:59:59.000'	-- 结束时间
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @result	int

	EXEC	@result = [dbo].[sp_assab_stat_agent_a_b]
			@repdate = @repdate,
			@date_begin = @date_begin,
			@date_end = @date_end,
			@time_begin = @time_begin,
			@time_end = @time_end,
			@agent = @agent,
			@skill = @skill,
			@interval = @interval,
			@group_level = 'day'
					
	return @result
END


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_agent_daily_20070802]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[sp_assab_stat_agent_daily_20070802]                 
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@agent		varchar(2000) = null,   --作席代码
		@skill		varchar(20) = null,     --技能组	 
		@interval	int = 30            	--时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Agent	
(
	ID		int,	
	Agent		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Agent		varchar(20),
	RecDate		datetime,
	TimeStr		varchar(50),
	Login_t		int,
	SkillIn_t	int,
	SkillIn_n	int,
	AvgRing_t	int,
	AvgTalk_t	int,
	ExtInt_t	int,
	ExtOut_t	int,
	Ready_t		int,
	Hold_t		int,
	ExtIn_n		int,
	ExtOut		int,
	Time_ID		int
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,	
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)


/*筛选vxi_ucd..login ,vxi_ucd..ready的最小数据结果集*/
create table  #tmp_current_login
(		             
	[LogID]     	bigint		not null,
	[Agent]     	char(16)	not null,
	[Device]    	varchar(50)	not null,
	[Skills]    	varchar(50)	null,
	[StartTime] 	datetime	null,
	[EndTime]   	datetime	null,
	[SubID]     	smallint	not null,
	[Finish]    	bit		null,
	[Flag]      	tinyint		null,
	[OnStart]   	int		null,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	int		null  --事件持续时间长度

)


--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)
end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>=0 
	and datediff(day,@current_date_end,a.StartTime)<=0
	
--作席login ready数据统计	
insert into #tmp_current_login
(
	[LogID]     ,
	[Agent]     ,
	[Device]    ,
	[Skills]    ,
	[StartTime] ,
	[EndTime]   ,
	[SubID]     ,
	[Finish]    ,
	[Flag]      ,
	[OnStart]   ,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	  --事件持续时间长度
)
select 
	a.[LogID]     ,
	a.[Agent]     ,
	a.[Device]    ,
	a.[Skills]    ,
--	a.[Finish]    ,
--	a.[Flag]      ,
	a.[StartTime] ,
--	a.[TimeLen]   ,
	a.[EndTime]   ,
--	a.[ReadyLen]  ,
--	a.[AcwLen]    ,
--	a.[cause]     ,     
	
--	b.[LogID]     ,
	b.[SubID]     ,
	b.[Finish]    ,
	b.[Flag]      ,
	b.[StartTime] as OnStart ,--进入当前状态时间偏移量
	b.[TimeLen]   	  --事件持续时间长度
--	b.[cause] 
from vxi_ucd..Login a , vxi_ucd..Ready b
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<= 0
	and a.LogID = b.LogID
--==================================================================================================================
--开始 取得的当前agent
--==================================================================================================================

--没有用identity
if(charindex(',',@agent)>0)
begin
	select @counter = 1
	while(charindex(',',@agent)>0)
	begin	
		if exists(select 1 from vxi_sys..Agent 
					where Agent = substring(@agent,1,charindex(',',@agent)-1))
		begin
			insert #tmp_current_Agent
			select @counter,substring(@agent,1,charindex(',',@agent)-1)
			select @Agent = substring(@agent,charindex(',',@agent)+1,len(@agent)-charindex(',',@agent))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'参数不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Agent
	select @counter,@agent
end
else 
begin
	if exists(select 1 from vxi_sys..Agent 
				where Agent = @agent)
	begin
		insert #tmp_current_Agent
		select @counter,@agent
	end
	else if(@agent is null)
	begin
		--如果技能组不为空，则以技能组取得所有agent
		if(@skill is not null)
		begin
			--输入技能组不为空且正确则选择技能组所有agent
			if exists(select 1 from vxi_sys..SkillAgent
						where skill = @skill )
			begin
				select @counter = count(*) from vxi_sys..SkillAgent
							where skill = @skill
				while(@counter>=1)
				begin
					insert into  #tmp_current_Agent
						select @counter,max(a.Agent) from vxi_sys..SkillAgent a
						where skill = @skill 
							and  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
					select @counter = @counter -1
				end
			end
			--输入技能组号错误
			else 
			begin
				select @omsg = '请输入正确的skill'
				goto l_fatal
			end
		end
		else --如果技能组为空则选择全部agent
		begin
			select @counter = count(*) from vxi_sys..Agent						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Agent
					select @counter,max(a.Agent) from vxi_sys..Agent a
					where  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
				select @counter = @counter -1
			end
			
		end
	end
end
if not exists(select 1 from #tmp_current_Agent)
begin
	select @omsg= '请输入agent！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前Agent
--==================================================================================================================


--==================================================================================================================
--开始 将Agent的工作情况放入临时表中
--==================================================================================================================

--其中Agent & time_id作为PK,注意Agent必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Agent --统计出agent数量放入计数器里
while (@counter >= 1)
begin
	select @agent = Agent 
		from #tmp_current_Agent 
			where id  = (select min(id) from #tmp_current_Agent )
	delete from #tmp_current_Agent where agent = @agent	
	
	--
	insert into  #tmp_stats
	(	Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		,
		Time_ID		
	)
	select 
		@Agent,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(Agent.login_t,0) as Login_t,	
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgRing_t.AvgRing_t,0) as AvgRing_t,
		isnull(AvgTalk_t.AvgTalk_t,0) as AvgTalk_t,
		isnull(ExtIn.ExtIn_t,0) as ExtIn_t,
		isnull(ExtOut.ExtOut_t,0) as ExtOut_t,
		isnull(Agent.Ready_t,0) as Ready_t,
		isnull(Hold_t.Hold_t,0) as Hold_t,
		isnull(ExtIn.ExtIn_n,0) as ExtIn_n,
		isnull(ExtOut.ExtOut_n,0) as ExtOut_n,
		Agent.time_id
	
	from 	#tmp_current_time TM 
		--不要忽略一个问题 login 包含 ready
		--统计Agent的login时间、Ready时间 

	left join(
			select 	time_id			,

			    sum(
					datediff(
							second
							,
							case when datediff(s,b.start_time,a.startTime) >0 
								then a.startTime  	else b.start_time end 
							,
							case when  datediff(s,b.end_time,a.EndTime) >0 
								then b.end_time		else a.EndTime end
						)
			       )As login_t, --login(工作)时间，秒
				sum(
					case when a.flag = 0x02
	      				then datediff(
							second
							,
							case when  datediff(s,b.start_time,dateadd(ms,a.OnStart,a.startTime)) >0 
								then dateadd(ms,a.OnStart,a.startTime)	else b.start_time end 
							,
							case when  datediff(s,b.end_time,dateadd(ms,a.OnStart+a.TimeLen,a.startTime)) >0 
								then b.end_time  else dateadd(ms,a.OnStart+a.TimeLen,a.startTime) end
							) 
		      		else 0 end
					)As Ready_t --Ready时间，秒
					 	 
			from #tmp_current_login a, #tmp_current_time b                                                                        
			where   a.Agent = @Agent
				and datediff(s,a.StartTime,b.end_time)>0 
				and datediff(s,a.EndTime,b.start_time)<0				
			group by b.time_id
			
		)Agent on TM.time_id = Agent.time_id
	
	left join
		--统计Agent所在Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   a.agent = @agent 
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and isnull(a.skill,'')<>'' and a.type = 1 --技能组号不为空，为呼入号码
			  	group by b.time_ID
		 ) ACD   on Agent.time_ID = ACD.time_ID
	
	left join 
		--统计Agent平均震铃时长
		(
			select 	b.time_id ,
				sum(a.OnEstb - a.OnRing) /count(1)  as AvgRing_t--平均震铃时长
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bRing = '1' and a.type = 1
			group by b.time_ID
		
		) AvgRing_t on  ACD.time_id = AvgRing_t.time_id
	  	
	left join 
		--统计Agent的平均通话时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd- a.OnEstb) /count(1) as AvgTalk_t --平均通话时长
			from  #tmp_current_data a,#tmp_current_time b
			where   agent = @agent 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgTalk_t on AvgRing_t.time_id = AvgTalk_t.time_id
		  	
	left join
		--统计Agent的分机呼入时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtIn_t ,--分机呼入时长
				count(1) 	as ExtIn_n--分机呼入次数
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent and skill is null --注意此处条件即为分机呼入时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
			  	
		) ExtIn on AvgTalk_t.time_id = ExtIn.time_id
	left join 
		--统计Agent的分机保持时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnHold)	as Hold_t --分机保持时长
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.start_time)<0
			  	and bHold = '1' and a.type = 1
			group by b.time_ID
			  	
		  )Hold_t on  ExtIn.time_id = Hold_t.time_id
	left join
		--统计Agent的分机呼出时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtOut_t,--分机呼出时长
				count(1) 	as ExtOut_n--分机呼出次数
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent --and skill is null --注意此处即为分机呼出时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 2
			group by b.time_ID
			  	
		) ExtOut on  Hold_t.time_id = ExtOut.time_id
	

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将Agent的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 
		Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_agent_hourly]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_assab_stat_agent_hourly] 
	-- Add the parameters for the stored procedure here
		@repdate 	datetime,               --报表日期
		@date_begin datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,				--结束时间
		@agent		varchar(2000) = null,   --座席代码
		@skill		varchar(20) = null,     --技能组	 
		@interval	int = 30            	--时间间隔
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @result	int

	EXEC	@result = [dbo].[sp_assab_stat_agent_a_b]
			@repdate = @repdate,
			@date_begin = @date_begin,
			@date_end = @date_end,
			@time_begin = @time_begin,
			@time_end = @time_end,
			@agent = @agent,
			@skill = @skill,
			@interval = @interval,
			@group_level = 'hour'
					
	return @result
END


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_agent_hourly_20070802]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[sp_assab_stat_agent_hourly_20070802]                 
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@agent		varchar(2000) = null,   --作席代码
		@skill		varchar(20) = null,     --技能组	 
		@interval	int = 30            	--时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Agent	
(
	ID		int,	
	Agent		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Agent		varchar(20),
	RecDate		datetime,
	TimeStr		varchar(50),
	Login_t		int,
	SkillIn_t	int,
	SkillIn_n	int,
	AvgRing_t	int,
	AvgTalk_t	int,
	ExtInt_t	int,
	ExtOut_t	int,
	Ready_t		int,
	Hold_t		int,
	ExtIn_n		int,
	ExtOut		int,
	Time_ID		int
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,	
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)


/*筛选vxi_ucd..login ,vxi_ucd..ready的最小数据结果集*/
create table  #tmp_current_login
(		             
	[LogID]     	bigint		not null,
	[Agent]     	char(16)	not null,
	[Device]    	varchar(50)	not null,
	[Skills]    	varchar(50)	null,
	[StartTime] 	datetime	null,
	[EndTime]   	datetime	null,
	[SubID]     	smallint	not null,
	[Finish]    	bit		null,
	[Flag]      	tinyint		null,
	[OnStart]   	int		null,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	int		null  --事件持续时间长度

)


--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)
end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>=0 
	and datediff(day,@current_date_end,a.StartTime)<=0
	
--作席login ready数据统计	
insert into #tmp_current_login
(
	[LogID]     ,
	[Agent]     ,
	[Device]    ,
	[Skills]    ,
	[StartTime] ,
	[EndTime]   ,
	[SubID]     ,
	[Finish]    ,
	[Flag]      ,
	[OnStart]   ,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	  --事件持续时间长度
)
select 
	a.[LogID]     ,
	a.[Agent]     ,
	a.[Device]    ,
	a.[Skills]    ,
--	a.[Finish]    ,
--	a.[Flag]      ,
	a.[StartTime] ,
--	a.[TimeLen]   ,
	a.[EndTime]   ,
--	a.[ReadyLen]  ,
--	a.[AcwLen]    ,
--	a.[cause]     ,     
	
--	b.[LogID]     ,
	b.[SubID]     ,
	b.[Finish]    ,
	b.[Flag]      ,
	b.[StartTime] as OnStart ,--进入当前状态时间偏移量
	b.[TimeLen]   	  --事件持续时间长度
--	b.[cause] 
from vxi_ucd..Login a , vxi_ucd..Ready b
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<= 0
	and a.LogID = b.LogID
--==================================================================================================================
--开始 取得的当前agent
--==================================================================================================================

--没有用identity
if(charindex(',',@agent)>0)
begin
	select @counter = 1
	while(charindex(',',@agent)>0)
	begin	
		if exists(select 1 from vxi_sys..Agent 
					where Agent = substring(@agent,1,charindex(',',@agent)-1))
		begin
			insert #tmp_current_Agent
			select @counter,substring(@agent,1,charindex(',',@agent)-1)
			select @Agent = substring(@agent,charindex(',',@agent)+1,len(@agent)-charindex(',',@agent))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'参数不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Agent
	select @counter,@agent
end
else 
begin
	if exists(select 1 from vxi_sys..Agent 
				where Agent = @agent)
	begin
		insert #tmp_current_Agent
		select @counter,@agent
	end
	else if(@agent is null)
	begin
		--如果技能组不为空，则以技能组取得所有agent
		if(@skill is not null)
		begin
			--输入技能组不为空且正确则选择技能组所有agent
			if exists(select 1 from vxi_sys..SkillAgent
						where skill = @skill )
			begin
				select @counter = count(*) from vxi_sys..SkillAgent
							where skill = @skill
				while(@counter>=1)
				begin
					insert into  #tmp_current_Agent
						select @counter,max(a.Agent) from vxi_sys..SkillAgent a
						where skill = @skill 
							and  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
					select @counter = @counter -1
				end
			end
			--输入技能组号错误
			else 
			begin
				select @omsg = '请输入正确的skill'
				goto l_fatal
			end
		end
		else --如果技能组为空则选择全部agent
		begin
			select @counter = count(*) from vxi_sys..Agent						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Agent
					select @counter,max(a.Agent) from vxi_sys..Agent a
					where  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
				select @counter = @counter -1
			end
			
		end
	end
end
if not exists(select 1 from #tmp_current_Agent)
begin
	select @omsg= '请输入agent！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前Agent
--==================================================================================================================


--==================================================================================================================
--开始 将Agent的工作情况放入临时表中
--==================================================================================================================

--其中Agent & time_id作为PK,注意Agent必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Agent --统计出agent数量放入计数器里
while (@counter >= 1)
begin
	select @agent = Agent 
		from #tmp_current_Agent 
			where id  = (select min(id) from #tmp_current_Agent )
	delete from #tmp_current_Agent where agent = @agent	
	
	--
	insert into  #tmp_stats
	(	Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		,
		Time_ID		
	)
	select 
		@Agent,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(Agent.login_t,0) as Login_t,	
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgRing_t.AvgRing_t,0) as AvgRing_t,
		isnull(AvgTalk_t.AvgTalk_t,0) as AvgTalk_t,
		isnull(ExtIn.ExtIn_t,0) as ExtIn_t,
		isnull(ExtOut.ExtOut_t,0) as ExtOut_t,
		isnull(Agent.Ready_t,0) as Ready_t,
		isnull(Hold_t.Hold_t,0) as Hold_t,
		isnull(ExtIn.ExtIn_n,0) as ExtIn_n,
		isnull(ExtOut.ExtOut_n,0) as ExtOut_n,
		Agent.time_id
	
	from 	#tmp_current_time TM 
		--不要忽略一个问题 login 包含 ready
		--统计Agent的login时间、Ready时间 

	left join(
			select 	time_id			,

			    sum(
					datediff(
							second
							,
							case when datediff(s,b.start_time,a.startTime) >0 
								then a.startTime  	else b.start_time end 
							,
							case when  datediff(s,b.end_time,a.EndTime) >0 
								then b.end_time		else a.EndTime end
						)
			       )As login_t, --login(工作)时间，秒
				sum(
					case when a.flag = 0x02
	      				then datediff(
							second
							,
							case when  datediff(s,b.start_time,dateadd(ms,a.OnStart,a.startTime)) >0 
								then dateadd(ms,a.OnStart,a.startTime)	else b.start_time end 
							,
							case when  datediff(s,b.end_time,dateadd(ms,a.OnStart+a.TimeLen,a.startTime)) >0 
								then b.end_time  else dateadd(ms,a.OnStart+a.TimeLen,a.startTime) end
							) 
		      		else 0 end
					)As Ready_t --Ready时间，秒
					 	 
			from #tmp_current_login a, #tmp_current_time b                                                                        
			where   a.Agent = @Agent
				and datediff(s,a.StartTime,b.end_time)>0 
				and datediff(s,a.EndTime,b.start_time)<0				
			group by b.time_id
			
		)Agent on TM.time_id = Agent.time_id
	
	left join
		--统计Agent所在Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   a.agent = @agent 
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and isnull(a.skill,'')<>'' and a.type = 1 --技能组号不为空，为呼入号码
			  	group by b.time_ID
		 ) ACD   on Agent.time_ID = ACD.time_ID
	
	left join 
		--统计Agent平均震铃时长
		(
			select 	b.time_id ,
				sum(a.OnEstb - a.OnRing) /count(1)  as AvgRing_t--平均震铃时长
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bRing = '1' and a.type = 1
			group by b.time_ID
		
		) AvgRing_t on  ACD.time_id = AvgRing_t.time_id
	  	
	left join 
		--统计Agent的平均通话时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd- a.OnEstb) /count(1) as AvgTalk_t --平均通话时长
			from  #tmp_current_data a,#tmp_current_time b
			where   agent = @agent 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgTalk_t on AvgRing_t.time_id = AvgTalk_t.time_id
		  	
	left join
		--统计Agent的分机呼入时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtIn_t ,--分机呼入时长
				count(1) 	as ExtIn_n--分机呼入次数
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent and skill is null --注意此处条件即为分机呼入时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
			  	
		) ExtIn on AvgTalk_t.time_id = ExtIn.time_id
	left join 
		--统计Agent的分机保持时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnHold)	as Hold_t --分机保持时长
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.start_time)<0
			  	and bHold = '1' and a.type = 1
			group by b.time_ID
			  	
		  )Hold_t on  ExtIn.time_id = Hold_t.time_id
	left join
		--统计Agent的分机呼出时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtOut_t,--分机呼出时长
				count(1) 	as ExtOut_n--分机呼出次数
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent --and skill is null --注意此处即为分机呼出时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 2
			group by b.time_ID
			  	
		) ExtOut on  Hold_t.time_id = ExtOut.time_id
	

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将Agent的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 
		Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_agent_monthly]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_stat_agent_monthly]                 
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@agent		varchar(2000) = null,   --作席代码
		@skill		varchar(20) = null,     --技能组	 
		@interval	int = 30            	--时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Agent	
(
	ID		int,	
	Agent		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Agent		varchar(20),
	RecDate		datetime,
	TimeStr		varchar(50),
	Login_t		int,
	SkillIn_t	int,
	SkillIn_n	int,
	AvgRing_t	int,
	AvgTalk_t	int,
	ExtInt_t	int,
	ExtOut_t	int,
	Ready_t		int,
	Hold_t		int,
	ExtIn_n		int,
	ExtOut		int,
	Time_ID		int
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,	
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)


/*筛选vxi_ucd..login ,vxi_ucd..ready的最小数据结果集*/
create table  #tmp_current_login
(		             
	[LogID]     	bigint		not null,
	[Agent]     	char(16)	not null,
	[Device]    	varchar(50)	not null,
	[Skills]    	varchar(50)	null,
	[StartTime] 	datetime	null,
	[EndTime]   	datetime	null,
	[SubID]     	smallint	not null,
	[Finish]    	bit		null,
	[Flag]      	tinyint		null,
	[OnStart]   	int		null,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	int		null  --事件持续时间长度

)


--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)
end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>=0 
	and datediff(day,@current_date_end,a.StartTime)<=0
	
--作席login ready数据统计	
insert into #tmp_current_login
(
	[LogID]     ,
	[Agent]     ,
	[Device]    ,
	[Skills]    ,
	[StartTime] ,
	[EndTime]   ,
	[SubID]     ,
	[Finish]    ,
	[Flag]      ,
	[OnStart]   ,--b.[StartTime] as  ,--进入当前状态时间偏移量
	[TimeLen]   	  --事件持续时间长度
)
select 
	a.[LogID]     ,
	a.[Agent]     ,
	a.[Device]    ,
	a.[Skills]    ,
--	a.[Finish]    ,
--	a.[Flag]      ,
	a.[StartTime] ,
--	a.[TimeLen]   ,
	a.[EndTime]   ,
--	a.[ReadyLen]  ,
--	a.[AcwLen]    ,
--	a.[cause]     ,     
	
--	b.[LogID]     ,
	b.[SubID]     ,
	b.[Finish]    ,
	b.[Flag]      ,
	b.[StartTime] as OnStart ,--进入当前状态时间偏移量
	b.[TimeLen]   	  --事件持续时间长度
--	b.[cause] 
from vxi_ucd..Login a , vxi_ucd..Ready b
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<= 0
	and a.LogID = b.LogID
--==================================================================================================================
--开始 取得的当前agent
--==================================================================================================================

--没有用identity
if(charindex(',',@agent)>0)
begin
	select @counter = 1
	while(charindex(',',@agent)>0)
	begin	
		if exists(select 1 from vxi_sys..Agent 
					where Agent = substring(@agent,1,charindex(',',@agent)-1))
		begin
			insert #tmp_current_Agent
			select @counter,substring(@agent,1,charindex(',',@agent)-1)
			select @Agent = substring(@agent,charindex(',',@agent)+1,len(@agent)-charindex(',',@agent))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的Agent'+substring(@agent,1,charindex(',',@agent)-1)+'参数不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Agent
	select @counter,@agent
end
else 
begin
	if exists(select 1 from vxi_sys..Agent 
				where Agent = @agent)
	begin
		insert #tmp_current_Agent
		select @counter,@agent
	end
	else if(@agent is null)
	begin
		--如果技能组不为空，则以技能组取得所有agent
		if(@skill is not null)
		begin
			--输入技能组不为空且正确则选择技能组所有agent
			if exists(select 1 from vxi_sys..SkillAgent
						where skill = @skill )
			begin
				select @counter = count(*) from vxi_sys..SkillAgent
							where skill = @skill
				while(@counter>=1)
				begin
					insert into  #tmp_current_Agent
						select @counter,max(a.Agent) from vxi_sys..SkillAgent a
						where skill = @skill 
							and  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
					select @counter = @counter -1
				end
			end
			--输入技能组号错误
			else 
			begin
				select @omsg = '请输入正确的skill'
				goto l_fatal
			end
		end
		else --如果技能组为空则选择全部agent
		begin
			select @counter = count(*) from vxi_sys..Agent						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Agent
					select @counter,max(a.Agent) from vxi_sys..Agent a
					where  not exists (select 1 from #tmp_current_Agent b where a.agent = b.agent )
				select @counter = @counter -1
			end
			
		end
	end
end
if not exists(select 1 from #tmp_current_Agent)
begin
	select @omsg= '请输入agent！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前Agent
--==================================================================================================================


--==================================================================================================================
--开始 将Agent的工作情况放入临时表中
--==================================================================================================================

--其中Agent & time_id作为PK,注意Agent必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Agent --统计出agent数量放入计数器里
while (@counter >= 1)
begin
	select @agent = Agent 
		from #tmp_current_Agent 
			where id  = (select min(id) from #tmp_current_Agent )
	delete from #tmp_current_Agent where agent = @agent	
	
	--
	insert into  #tmp_stats
	(	Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		,
		Time_ID		
	)
	select 
		@Agent,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(Agent.login_t,0) as Login_t,	
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgRing_t.AvgRing_t,0) as AvgRing_t,
		isnull(AvgTalk_t.AvgTalk_t,0) as AvgTalk_t,
		isnull(ExtIn.ExtIn_t,0) as ExtIn_t,
		isnull(ExtOut.ExtOut_t,0) as ExtOut_t,
		isnull(Agent.Ready_t,0) as Ready_t,
		isnull(Hold_t.Hold_t,0) as Hold_t,
		isnull(ExtIn.ExtIn_n,0) as ExtIn_n,
		isnull(ExtOut.ExtOut_n,0) as ExtOut_n,
		Agent.time_id
	
	from 	#tmp_current_time TM 
		--不要忽略一个问题 login 包含 ready
		--统计Agent的login时间、Ready时间 

	left join(
			select 	time_id			,

			    sum(
					datediff(
							second
							,
							case when datediff(s,b.start_time,a.startTime) >0 
								then a.startTime  	else b.start_time end 
							,
							case when  datediff(s,b.end_time,a.EndTime) >0 
								then b.end_time		else a.EndTime end
						)
			       )As login_t, --login(工作)时间，秒
				sum(
					case when a.flag = 0x02
	      				then datediff(
							second
							,
							case when  datediff(s,b.start_time,dateadd(ms,a.OnStart,a.startTime)) >0 
								then dateadd(ms,a.OnStart,a.startTime)	else b.start_time end 
							,
							case when  datediff(s,b.end_time,dateadd(ms,a.OnStart+a.TimeLen,a.startTime)) >0 
								then b.end_time  else dateadd(ms,a.OnStart+a.TimeLen,a.startTime) end
							) 
		      		else 0 end
					)As Ready_t --Ready时间，秒
					 	 
			from #tmp_current_login a, #tmp_current_time b                                                                        
			where   a.Agent = @Agent
				and datediff(s,a.StartTime,b.end_time)>0 
				and datediff(s,a.EndTime,b.start_time)<0				
			group by b.time_id
			
		)Agent on TM.time_id = Agent.time_id
	
	left join
		--统计Agent所在Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   a.agent = @agent 
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and isnull(a.skill,'')<>'' and a.type = 1 --技能组号不为空，为呼入号码
			  	group by b.time_ID
		 ) ACD   on Agent.time_ID = ACD.time_ID
	
	left join 
		--统计Agent平均震铃时长
		(
			select 	b.time_id ,
				sum(a.OnEstb - a.OnRing) /count(1)  as AvgRing_t--平均震铃时长
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bRing = '1' and a.type = 1
			group by b.time_ID
		
		) AvgRing_t on  ACD.time_id = AvgRing_t.time_id
	  	
	left join 
		--统计Agent的平均通话时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd- a.OnEstb) /count(1) as AvgTalk_t --平均通话时长
			from  #tmp_current_data a,#tmp_current_time b
			where   agent = @agent 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgTalk_t on AvgRing_t.time_id = AvgTalk_t.time_id
		  	
	left join
		--统计Agent的分机呼入时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtIn_t ,--分机呼入时长
				count(1) 	as ExtIn_n--分机呼入次数
			from #tmp_current_data a,#tmp_current_time b
			where   agent = @agent and skill is null --注意此处条件即为分机呼入时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
			  	
		) ExtIn on AvgTalk_t.time_id = ExtIn.time_id
	left join 
		--统计Agent的分机保持时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnHold)	as Hold_t --分机保持时长
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnHold,StartTime),b.start_time)<0
			  	and bHold = '1' and a.type = 1
			group by b.time_ID
			  	
		  )Hold_t on  ExtIn.time_id = Hold_t.time_id
	left join
		--统计Agent的分机呼出时长
		(
			select 	@agent 		as Agent,
				b.time_id 	as Time_id,
				sum(a.OnCallEnd)as ExtOut_t,--分机呼出时长
				count(1) 	as ExtOut_n--分机呼出次数
			from #tmp_current_data a,#tmp_current_time b
			where 	agent = @agent --and skill is null --注意此处即为分机呼出时长
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0 
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 2
			group by b.time_ID
			  	
		) ExtOut on  Hold_t.time_id = ExtOut.time_id
	

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将Agent的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 
		Agent		,
		RecDate		,
		TimeStr		,
		Login_t		,
		SkillIn_t	,
		SkillIn_n	,
		AvgRing_t	,
		AvgTalk_t	,
		ExtInt_t	,
		ExtOut_t	,
		Ready_t		,
		Hold_t		,
		ExtIn_n		,
		ExtOut		
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_skill_a_b]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_assab_stat_skill_a_b]
	-- Add the parameters for the stored procedure here
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,           --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,				--结束时间
		@skill		varchar(800) = null,    --技能组	 
		@interval	int = 30,				--时间间隔
		@group_level varchar(200)			-- hour/day
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @date_time_begin_value	bigint, 
			@date_time_end_value	bigint,
			@time_begin_value		int, 
			@time_end_value			int,
			@str_sql				nvarchar(4000), 
			@str_date_part			nvarchar(500),
			@str_ext_fields			nvarchar(1000),
			@str_ext_fields_define	nvarchar(2000),
			@str_skill_where		nvarchar(1200),
			@str_order_by			nvarchar(100),
			@result					int

	select	@date_time_begin_value = convert(varchar(20), @date_begin, 112),	-- yyyymmdd
			@date_time_end_value = convert(varchar(20), @date_end, 112),		-- yyyymmdd
			@time_begin_value = datepart(hour, @time_begin) * 100 + datepart(minute, @time_begin), -- hhnn
			@time_end_value = datepart(hour, @time_end) * 100 + datepart(minute, @time_end),		-- hhnn
			@date_time_begin_value = @date_time_begin_value * 10000 + @time_begin_value,	-- yyyymmddhhnn
			@date_time_end_value = @date_time_end_value * 10000 + @time_end_value	-- yyyymmddhhnn

	if lower(@group_level) = 'hour' begin
		-- 按小时

		select	@str_date_part = 'RecDT', 
				@str_order_by = '2, 1, 3',	-- 日期、技能组、时间
				@str_sql = 'select	rtrim(Skill) Skill, -- 技能组
									dbo.func_get_date_str_part(RecDT) RecDate,	-- 记录日期
									dbo.func_get_time_str_part(RecDT, @interval) TimeStr,	-- 时间范围',
				@str_ext_fields = ' ExtOut_n,	-- 分机呼出数量
									AvgExtOut_t,	-- 分机平均呼出时间',
				@str_ext_fields_define = ', sum(AgentOut_n) ExtOut_n, 
											case when sum(AgentOut_n) != 0
											then dbo.ms_to_int_sec(cast(sum(AgentOut_t) as float) / sum(AgentOut_n)) 
											else 0 end AvgExtOut_t'
	end
	else begin
		-- 按天
		select	@str_date_part = '(RecDT / 10000)', 
				@str_order_by = '2, 1',		-- 日期、技能组
				@str_sql = 'select	rtrim(Skill) Skill, -- 技能组
									dbo.func_get_date_str_part(RecDT) RecDate,	-- 记录日期',
				@str_ext_fields = '',
				@str_ext_fields_define = ''
	end

	set @str_skill_where = case when len(rtrim(@skill)) > 0 
								then ' and Skill in (' + @skill + ') '
								else ''
						   end

    --select	@date_time_begin_value 'date_time_begin_value', @date_time_end_value 'date_time_end_value',
	--		@time_begin_value 'time_begin_value', @time_end_value 'time_end_value'

	set @str_sql = @str_sql + /* Select ..., */ '
		AvgWait_t,	-- 平均应答时长
		AvgAban_t,	-- 平均放弃时长
		SkillIn_n,	-- 技能组呼入数
		AvgSkillIn_t,	-- 技能组呼入平均时长
		Aban_n,			-- 放弃呼叫数量
'	  + @str_ext_fields + '
		0 ToAdmin_n		-- 是否转到Admin组
	from
	(
		select	top 100 percent 
'
				+ @str_date_part + ' RecDT,' +							-- 日期
'				Skill,													-- 技能组
				case when sum(Ans_n) != 0
					 then dbo.ms_to_int_sec(cast(sum(Ans_t) as float) / sum(Ans_n)) 
					 else 0 end AvgWait_t,								-- 平均应答时长

				case when sum(Aban_n) != 0
					 then dbo.ms_to_int_sec(cast(sum(Aban_t) as float) / sum(Aban_n)) 
					 else 0 end AvgAban_t,								-- 平均放弃时长

				sum(SkillIn_n) SkillIn_n,								-- 技能组来电总数

				case when sum(Ans_n) != 0
					 then dbo.ms_to_int_sec(cast(sum(Talk_t) as float) / sum(Ans_n)) 
					 else 0 end AvgSkillIn_t,							-- 技能组呼入平均时长

				sum(Aban_n) Aban_n										-- 放弃呼叫数量
'
				+ @str_ext_fields_define + 
'		from stat_call_skill
		where (RecDT between @date_time_begin_value and @date_time_end_value)
			and ((RecDT % 10000) between @time_begin_value and @time_end_value)
'		  + @str_skill_where + '
		group by ' + @str_date_part + ', Skill
		order by 1, 2
	) ca
	order by ' + @str_order_by
	
	--print @str_sql

	exec @result = sp_executesql @str_sql,
					N'@interval int,
					  @date_time_begin_value bigint, 
					  @date_time_end_value bigint,
					  @time_begin_value	int, 
					  @time_end_value int',
					@interval = @interval,
					@date_time_begin_value = @date_time_begin_value,
					@date_time_end_value = @date_time_end_value,
					@time_begin_value = @time_begin_value,
					@time_end_value = @time_end_value
					
	if @@error != 0 or @result != 0 begin
		raiserror('sp_executesql error!', 1, 1)
	end

	return @result

END


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_skill_daily]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_stat_skill_daily]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30 ,           --时间间隔
		@time_begin	datetime = '1981-09-10 00:00:00',               --开始时间 默认值，不输入
		@time_end	datetime = '1981-09-10 23:59:59'	        --结束时间 默认值，不输入
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @result	int

	EXEC	@result = [dbo].[sp_assab_stat_skill_a_b]
			@repdate = @repdate,
			@date_begin = @date_begin,
			@date_end = @date_end,
			@time_begin = @time_begin,
			@time_end = @time_end,
			@skill = @skill,
			@interval = @interval,
			@group_level = N'day'

	return @result
END

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_skill_daily_20070802]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[sp_assab_stat_skill_daily_20070802]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30            --时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Skill	
(
	ID		int,	
	Skill		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Skill		varchar(20),       
	RecDate		datetime,          
	TimeStr		varchar(100),	
	Skill_t		int,            
	Skill_n		int,            
	AvgWait_t	int,	                
	AvgAban_t	int,                    
	Aban_n		int,            
	ToAdmin_n	int    
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)
--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)

end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<=0

--==================================================================================================================
--开始 取得的当前skill
--==================================================================================================================


if(charindex(',',@skill)>0)
begin
	select @counter = 1
	while(charindex(',',@skill)>0)
	begin	
		if exists(select 1 from vxi_sys..skill 
					where skill = substring(@skill,1,charindex(',',@skill)-1))
		begin
			insert #tmp_current_Skill
			select @counter,substring(@skill,1,charindex(',',@skill)-1)
			select @skill = substring(@skill,charindex(',',@skill)+1,len(@skill)-charindex(',',@skill))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的skill'+substring(@skill,1,charindex(',',@skill)-1)+'不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Skill
	select @counter,@skill
end
else 
begin
	if exists(select 1 from vxi_sys..skill 
				where skill = @skill)
	begin
		insert #tmp_current_Skill
		select @counter,@skill
	end
	else 
	begin	--如果技能组为空则选择全部skill
		if(@skill is null)
		begin
			select @counter = count(*) from vxi_sys..Skill						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Skill
					select @counter,max(a.Skill) from vxi_sys..Skill a
					where  not exists (select 1 from #tmp_current_Skill b where a.Skill = b.Skill )
				select @counter = @counter -1
			end
		end
		else --不存在的skill
		begin
			select @omsg = '输入的技能组'+@skill+'不合法'
			goto l_fatal
		end
		
	end

end
if not exists(select 1 from #tmp_current_Skill)
begin
	select @omsg= '请输入skill！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前skill
--==================================================================================================================

	

--==================================================================================================================
--开始 将skill的工作情况放入临时表中
--==================================================================================================================

--其中skill & time_id作为PK,注意skill必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Skill --统计出skill数量放入计数器里
while (@counter >= 1)
begin
	select @skill = skill 
		from #tmp_current_Skill 
			where id  = (select min(id) from #tmp_current_Skill )
	delete from #tmp_current_Skill where skill = @skill
		
	insert into  #tmp_stats
	(	Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ToAdmin_n	
	)
	select 
		@skill,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgWait_t.AvgWait_t,0) as AvgWait_t,
		isnull(Aban.AvgAban_t,0) as AvgAban_t,
		isnull(Aban.Aban_n,0) as Aban_n,
		0
	from 	#tmp_current_time TM 	
	left join		
		--统计Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and a.type = 1 
			  	group by b.time_ID
		 ) ACD   on TM.time_ID = ACD.time_ID
		 
	left join 
		--统计Skill平均应答时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnEstb) /count(1) as AvgWait_t --平均应答时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgWait_t on ACD.time_id = AvgWait_t.time_id
		  	
	left join
		--统计平均放弃时长，放弃呼叫数量
		(
			select 	b.time_id 	as Time_id,
				count(1)	as Aban_n ,--放弃呼叫数量
				sum(a.OnEstb) /count(1) as AvgAban_t --平均放弃时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 1
			group by b.time_ID
		
		) Aban on AvgWait_t.time_id = Aban.time_id

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将skill的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 		Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ToAdmin_n	
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_skill_hourly]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_stat_skill_hourly]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30            --时间间隔
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    declare @result	int

	EXEC	@result = [dbo].[sp_assab_stat_skill_a_b]
			@repdate = @repdate,
			@date_begin = @date_begin,
			@date_end = @date_end,
			@time_begin = @time_begin,
			@time_end = @time_end,
			@skill = @skill,
			@interval = @interval,
			@group_level = N'hour'

	return @result
END

GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_skill_hourly_20070802]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[sp_assab_stat_skill_hourly_20070802]                
		@repdate 	datetime,               --报表日期
		@date_begin 	datetime,               --开始日期
		@date_end	datetime,               --结束日期
		@time_begin	datetime,               --开始时间
		@time_end	datetime,	        --结束时间
		@skill		varchar(800) = null,     --技能组	 
		@interval	int = 30            --时间间隔
AS

declare @current_date_begin datetime, --内部变量,统计当前时间
	@current_date_end 	datetime,
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	int
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Skill	
(
	ID		int,	
	Skill		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Skill		varchar(20),       
	RecDate		datetime,          
	TimeStr		varchar(100),	
	Skill_t		int,            
	Skill_n		int,            
	AvgWait_t	int,	                
	AvgAban_t	int,                    
	Aban_n		int,      
	ExtOut_t	int,
	AvgExtOut_t	int,      
	ToAdmin_n	int    
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)
--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				
select  @current_date_begin =  convert(varchar(20),@date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
  	@counter = 1 	
while(datediff(day,@current_date_begin,@date_end)>=0)
begin
	select  @current_date_begin  = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_begin,108),
		@current_date_end = convert(varchar(20),@current_date_begin,110)+' ' +convert(varchar(20),@time_end,108)

	while(datediff(minute,@current_date_begin,@current_date_end)>0)
	begin
		insert into #tmp_current_time
				(
				 start_time,
				 end_time  ,
				 time_ID	   
				)
		select 		@current_date_begin,
				dateadd(minute,@interval,@current_date_begin),
				@counter
		select 	@current_date_begin = dateadd(minute,@interval,@current_date_begin),
			@counter =@counter + 1
	end
	select @current_date_begin = dateadd(day,1,@current_date_begin)

end
--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================


/*取得开始与结束时间点，用于筛选出最少数据放入临时表中*/
select   @current_date_begin = min(Start_time) ,
	 @current_date_end = max(end_time) 
from #tmp_current_time

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)>= 0 
	and datediff(day,@current_date_end,a.StartTime)<=0

--==================================================================================================================
--开始 取得的当前skill
--==================================================================================================================


if(charindex(',',@skill)>0)
begin
	select @counter = 1
	while(charindex(',',@skill)>0)
	begin	
		if exists(select 1 from vxi_sys..skill 
					where skill = substring(@skill,1,charindex(',',@skill)-1))
		begin
			insert #tmp_current_Skill
			select @counter,substring(@skill,1,charindex(',',@skill)-1)
			select @skill = substring(@skill,charindex(',',@skill)+1,len(@skill)-charindex(',',@skill))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的skill'+substring(@skill,1,charindex(',',@skill)-1)+'不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Skill
	select @counter,@skill
end
else 
begin
	if exists(select 1 from vxi_sys..skill 
				where skill = @skill)
	begin
		insert #tmp_current_Skill
		select @counter,@skill
	end
	else 
	begin	--如果技能组为空则选择全部skill
		if(@skill is null)
		begin
			select @counter = count(*) from vxi_sys..Skill						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Skill
					select @counter,max(a.Skill) from vxi_sys..Skill a
					where  not exists (select 1 from #tmp_current_Skill b where a.Skill = b.Skill )
				select @counter = @counter -1
			end
		end
		else --不存在的skill
		begin
			select @omsg = '输入的技能组'+@skill+'不合法'
			goto l_fatal
		end
		
	end

end
if not exists(select 1 from #tmp_current_Skill)
begin
	select @omsg= '请输入skill！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前skill
--==================================================================================================================
	

--==================================================================================================================
--开始 将skill的工作情况放入临时表中
--==================================================================================================================

--其中skill & time_id作为PK,注意skill必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Skill --统计出skill数量放入计数器里
while (@counter >= 1)
begin
	select @skill = skill 
		from #tmp_current_Skill 
			where id  = (select min(id) from #tmp_current_Skill )
	delete from #tmp_current_Skill where skill = @skill
		
	insert into  #tmp_stats
	(	Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ExtOut_t	,
		AvgExtOut_t	,  
		ToAdmin_n	
	)
	select 
		@skill,
		convert(varchar(20),TM.Start_Time,110)	as RecDate,
		convert(varchar(20),TM.Start_Time,120) + '——'+convert(varchar(20),TM.End_Time,120) as TimeStr,		
		isnull(ACD.SkillIn_t,0) as SkillIn_t,
		isnull(ACD.SkillIn_n,0) as SkillIn_n,
		isnull(AvgWait_t.AvgWait_t,0) as AvgWait_t,
		isnull(Aban.AvgAban_t,0) as AvgAban_t,
		isnull(Aban.Aban_n,0) as Aban_n,
		isnull(ExtOut.ExtOut_t,0) as ExtOut_t, 
		isnull(ExtOut.AvgExtOut_t,0) as AvgExtOut_t,
		0
	from 	#tmp_current_time TM 	
	left join		
		--统计Skill的呼入总时长、呼入总数量。
		(
			select  b.time_id,
				sum(a.TimeLen)  as SkillIn_t,--skill呼入总时长
				count(1) 	as SkillIn_n --skill呼入总数量
	
			from 	 #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,a.StartTime,b.start_time)<0 
				and datediff(s,a.StartTime,b.end_time)>0
			  	and a.type = 1 
			  	group by b.time_ID
		 ) ACD   on TM.time_ID = ACD.time_ID
		 
	left join 
		--统计Skill平均应答时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnEstb) /count(1) as AvgWait_t --平均应答时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '1' and a.type = 1
			group by b.time_ID
		
		) AvgWait_t on ACD.time_id = AvgWait_t.time_id
		  	
	left join
		--统计平均放弃时长，放弃呼叫数量
		(
			select 	b.time_id 	as Time_id,
				count(1)	as Aban_n ,--放弃呼叫数量
				sum(a.OnEstb) /count(1) as AvgAban_t --平均放弃时长
			from  #tmp_current_data a,#tmp_current_time b
			where   skill = @skill
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 1
			group by b.time_ID
		
		) Aban on AvgWait_t.time_id = Aban.time_id
	left join
		--分机呼出时长，分机呼出平均时长
		(
			select 	b.time_id 	as Time_id,
				sum(a.OnCallEnd) as ExtOut_t ,--分机呼出时长
				sum(a.OnCallEnd) /count(1) as AvgExtOut_t --分机平均呼出时长
			from  #tmp_current_data a,#tmp_current_time b,(select agent from vxi_sys..SkillAgent where skill = @skill) c
			where   a.agent = c.agent
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.end_time)>0
				and datediff(s,dateadd(ms,a.OnRing,StartTime),b.start_time)<0
			  	and bEstb = '0' and a.type = 2
			group by b.time_ID
		) ExtOut on Aban.time_id = ExtOut.time_id

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将skill的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 		Skill		,
		RecDate		,
		TimeStr		,
		Skill_t		,
		Skill_n		,
		AvgWait_t	,
		AvgAban_t	,
		Aban_n		,
		ExtOut_t	,
		AvgExtOut_t	, 
		ToAdmin_n	
		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	


GO
/****** Object:  StoredProcedure [dbo].[sp_assab_stat_skill_realtime]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_assab_stat_skill_realtime]                
		@skill varchar(2000) = null
--		,@skillCalls int output
--		,@AbanCalls int output
AS

declare @current_date_begin datetime, --内部变量,统计当前时间	
	@counter	int, --内部计数器
	@omsg		varchar(300) --出错代码信息

--==================================================================================================================
--开始 创建过程中所需临时表
--==================================================================================================================				

/*创建存放时间段临时表*/
create table #tmp_current_time 
(   
	 start_time 	datetime,
	 end_time 	datetime,
	 time_ID	varchar(10)
)
/*创建存放要输出促销员的的临时表*/
Create table #tmp_current_Skill	
(
	ID		int,	
	Skill		varchar(20)
)
				
/*创建存放输出结果集的临时表*/		       
create table #tmp_stats
(	Items		varchar(20), 
	ItemType	tinyint,   
	Total_day	int,    
	Total_30        int,
	Sum_03          int,
	Sum_05          int,
	Sum_10          int,
	Sum_15          int,
	Sum_20          int,
	Sum_30          int,
	Sum_60		int
)
/*创建存放vxi..Ucd ,vxi..UcdCall的最小数据结果集临时表*/
create table #tmp_current_data
(
	[UcdId] 	bigint  	not null,
	[ClientId]	int	 	null,	
	[Calling]	varchar(20)	null,
	[Called]	varchar(20)	null,
	[StartTime]	datetime 	not null, 	--呼叫开始时间
	[TimeLen]	int		null,	--呼叫全过程经历的时间长度
	[Inbound]	bit		null,
	[Outbound]	bit		null,
	[Extension]	varchar(20)	null,
	[SubId]		tinyint		not null,
	[CallId]	int		null,
	[Type]		tinyint		not null,	
	[Agent]		varchar(20)	null,
	[Skill]		varchar(20)	null,
	[bRing]		bit		null,
	[bEstb]		bit		null,
	[bHold]		bit		null,
	[bRetv]		bit		null,
	[bTrans]	bit		null,
	[bConf]		bit		null,
	[bOverflow]	bit		null,
	[bAcw]		bit		null,
	[OnCallBegin]	int		not null,
	[OnRoute]	int		null,	
	[OnSkill]	int		null,
	[OnRing]	int		null,
	[OnEstb]	int		null,
	[OnHold]	int		null,
	[OnRetv]	int		null,
	[OnTrans]	int		null,
	[OnConf]	int		null,
	[OnConfEnd]	int		null,
	[OnCallEnd]	int		null,
	[OnOverflow]	int		null,
	[OnAcwEnd]	int		null,
	[UCID]		varchar(25)	null,
	[UUI]		varchar(100)	null
)
--==================================================================================================================
--结束 创建过程中所需临时表
--==================================================================================================================				

--==================================================================================================================
--开始 取得当前时间区间放入时间临时表 
--==================================================================================================================				

	
insert into #tmp_current_time 
	select  dateadd(s,-3,@current_date_begin),@current_date_begin,'Sum_03'
	union all
	select  dateadd(s,-5,@current_date_begin),dateadd(s,-3,@current_date_begin),'Sum_05'
	union all
	select  dateadd(s,-10,@current_date_begin),dateadd(s,-5,@current_date_begin),'Sum_10'
	union all
	select  dateadd(s,-15,@current_date_begin),dateadd(s,-10,@current_date_begin),'Sum_15'
	union all
	select  dateadd(s,-20,@current_date_begin),dateadd(s,-15,@current_date_begin),'Sum_20'
	union all
	select  dateadd(s,-30,@current_date_begin),dateadd(s,-20,@current_date_begin),'Sum_30'
	union all
	select  dateadd(s,-60,@current_date_begin),dateadd(s,-30,@current_date_begin),'Sum_60'
	union all
	select  dateadd(minute,-30,@current_date_begin),@current_date_begin,'total_30'
	union all
	select  convert(varchar(32),@current_date_begin,110),@current_date_begin,'total_day'



--==================================================================================================================
--结束 取得当前时间区间放入时间临时表 
--==================================================================================================================

--Ucd&UcdCall临时数据
insert into #tmp_current_data 
(
	[UcdId] ,
	[ClientId],
	[Calling],
	[Called],
	[StartTime], 	--呼叫开始时间
	[TimeLen],	--呼叫全过程经历的时间长度
	[Inbound],
	[Outbound],
	[Extension],
	[SubId],
	[CallId],
	[Type],
	[Agent],
	[Skill],
	[bRing],
	[bEstb],
	[bHold],
	[bRetv],
	[bTrans],
	[bConf],
	[bOverflow],
	[bAcw],
	[OnCallBegin],
	[OnRoute],
	[OnSkill],
	[OnRing],
	[OnEstb],
	[OnHold],
	[OnRetv],
	[OnTrans],
	[OnConf],
	[OnConfEnd],
	[OnCallEnd],
	[OnOverflow],
	[OnAcwEnd],
	[UCID],
	[UUI]
)
select 	a.[UcdId] ,
	a.[ClientId],
	a.[Calling],
	a.[Called],
--	a.[Answer],
--	a.[Route],
--	a.[Skill],
--	a.[Trunk],
	a.[StartTime], 	--呼叫开始时间
	a.[TimeLen],	--呼叫全过程经历的时间长度
	a.[Inbound],
	a.[Outbound],
	a.[Extension],
--	a.[Agent],
--	a.[UcdDate],
--	a.[UcdHour],
--	a.[PrjId],
--	a.[UCID],
--	a.[UUI],
	
--	b.[UcdId],
	b.[SubId],
	b.[CallId],
--	b.[Calling],
--	b.[Called],
--	b.[Answer],
	b.[Type],
	b.[Agent],
--	b.[Route],
	b.[Skill],
--	b.[Trunk],
--	b.[CtrlDev],
	b.[bRing],
	b.[bEstb],
	b.[bHold],
	b.[bRetv],
	b.[bTrans],
	b.[bConf],
	b.[bOverflow],
	b.[bAcw],
	b.[OnCallBegin],
	b.[OnRoute],
	b.[OnSkill],
	b.[OnRing],
	b.[OnEstb],
	b.[OnHold],
	b.[OnRetv],
	b.[OnTrans],
	b.[OnConf],
	b.[OnConfEnd],
	b.[OnCallEnd],
	b.[OnOverflow],
	b.[OnAcwEnd],
	b.[UCID],
	b.[UUI]
from vxi_ucd..Ucd a inner join vxi_ucd..UcdCall b on a.UcdId = b.UcdId	
where 	datediff(day,@current_date_begin,a.StartTime)= 0 
	

--==================================================================================================================
--开始 取得的当前skill
--==================================================================================================================


if(charindex(',',@skill)>0)
begin
	select @counter = 1
	while(charindex(',',@skill)>0)
	begin	
		if exists(select 1 from vxi_sys..skill 
					where skill = substring(@skill,1,charindex(',',@skill)-1))
		begin
			insert #tmp_current_Skill
			select @counter,substring(@skill,1,charindex(',',@skill)-1)
			select @skill = substring(@skill,charindex(',',@skill)+1,len(@skill)-charindex(',',@skill))
			select @counter = @counter + 1			
		end
		else
		begin			
			select @omsg= '输入的skill'+substring(@skill,1,charindex(',',@skill)-1)+'不合法'
			goto l_fatal
		end
	end
	insert #tmp_current_Skill
	select @counter,@skill
end
else 
begin
	if exists(select 1 from vxi_sys..skill 
				where skill = @skill)
	begin
		insert #tmp_current_Skill
		select @counter,@skill
	end
	else 
	begin	--如果技能组为空则选择全部skill
		if(@skill is null)
		begin
			select @counter = count(*) from vxi_sys..Skill						
			while(@counter>=1)
			begin
				insert into  #tmp_current_Skill
					select @counter,max(a.Skill) from vxi_sys..Skill a
					where  not exists (select 1 from #tmp_current_Skill b where a.Skill = b.Skill )
				select @counter = @counter -1
			end
		end
		else --不存在的skill
		begin
			select @omsg = '输入的技能组'+@skill+'不合法'
			goto l_fatal
		end
		
	end

end
if not exists(select 1 from #tmp_current_Skill)
begin
	select @omsg= '请输入skill！'
	goto l_fatal
end
--==================================================================================================================
--结束 取得当前skill
--==================================================================================================================
	

--==================================================================================================================
--开始 将skill的工作情况放入临时表中
--==================================================================================================================

--其中skill & time_id作为PK,注意skill必须是作席代码而不是姓名

select @counter = count(*) 
		from #tmp_current_Skill --统计出skill数量放入计数器里
while (@counter >= 1)
begin
	select @skill = skill 
		from #tmp_current_Skill 
			where id  = (select min(id) from #tmp_current_Skill )
	delete from #tmp_current_Skill where skill = @skill
		
/*	
--sql 2005 语法写法
	insert into  #tmp_stats
	(	Items		, 
		ItemType	,   
		Total_day	,    
		Total_30      ,
		Sum_03        ,
		Sum_05        ,
		Sum_10        ,
		Sum_15        ,
		Sum_20        ,
		Sum_30        ,
		Sum_60		
	)
	select 
		Items		, 
		ItemType	,   
		Total_day	,    
		Total_30      ,
		Sum_03        ,
		Sum_05        ,
		Sum_10        ,
		Sum_15        ,
		Sum_20        ,
		Sum_30        ,
		Sum_60	
	from 
	(
		select @skill as Items,a.bEstb as ItemType,b.Time_id,count(1) as Sum_n 
					from #tmp_current_data a,#tmp_current_time b
		where skill = @skill and datediff(s,a.StartTime,b.start_time)<0 and datediff(s,a.StartTime,b.end_time)>0
		group by b.Time_id,a.bEstb
	) Sum_Data
	PIVOT
	(		
		count (sum_n) for time_id in
		( Total_day, Total_30, Sum_03, Sum_05, Sum_10, Sum_15, Sum_20, Sum_30, Sum_60 )
	) as pvt	
*/	
-- sql server 2000写法
	insert into  #tmp_stats
	(	Items		, 
		ItemType	,   
		Total_day	,    
		Total_30      ,
		Sum_03        ,
		Sum_05        ,
		Sum_10        ,
		Sum_15        ,
		Sum_20        ,
		Sum_30        ,
		Sum_60		
	)
	select 
		@skill		, 
		ItemType	,   
		sum(case Sum_data.time_id when 'Total_day'
		 	 then Sum_data.sum_n else 0 end ) as Total_day	, 
 	 	sum(case  Sum_data.time_id when 'Total_30'
 	 		 then Sum_data.sum_n else 0 end ) as Total_30	, 
		sum(case  Sum_data.time_id when 'Sum_03' 
		 	 then Sum_data.sum_n else 0 end ) as Sum_03	, 
 	 	sum(case  Sum_data.time_id when 'Sum_05'
 	 		 then Sum_data.sum_n else 0 end ) as Sum_05	, 
 	 	sum(case  Sum_data.time_id when 'Sum_10' 
		 	 then Sum_data.sum_n else 0 end ) as Sum_10	, 
 	 	sum(case  Sum_data.time_id when 'Sum_15'  
 	 		 then Sum_data.sum_n else 0 end ) as Sum_15 	, 
 	 	sum(case  Sum_data.time_id when 'Sum_20' 
 	 		 then Sum_data.sum_n else 0 end ) as Sum_20 	, 
 	 	sum(case  Sum_data.time_id when 'Sum_30' 
		 	 then Sum_data.sum_n else 0 end ) as Sum_30	, 
 	 	sum(case  Sum_data.time_id when 'Sum_60'  
 	 		 then Sum_data.sum_n else 0 end ) as Sum_60 	
	from 
	(
		select a.bEstb as ItemType,b.Time_id,1 as Sum_n 
					from #tmp_current_data a,#tmp_current_time b
		where skill = @skill and datediff(s,a.StartTime,b.start_time)<0 and datediff(s,a.StartTime,b.end_time)>0		
	) Sum_Data
	group by Sum_data.Time_id,Sum_data.ItemType

	select @counter = @counter - 1
end
--==================================================================================================================
--结束 将skill的工作情况放入临时表中
--==================================================================================================================
--输出结果集
select 		
	
	Items		, 
	ItemType	,
	Total_day	,
	Total_30        ,
	Sum_03          ,
	Sum_05          ,
	Sum_10          ,
	Sum_15          ,
	Sum_20          ,
	Sum_30          ,
	Sum_60		
from 	#tmp_stats

return 0
--错误处理，返回信息
l_fatal:
	select @omsg
	return -1
	

GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_agent_sn_init]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_chengdu_agent_sn_init]
AS
	truncate table chengdu_agentsn
	insert into chengdu_agentsn
		select max(agent) agent, dbo.func_chengdu_agent_sn(agent) SN
			from vxi_sys..agent
			group by dbo.func_chengdu_agent_sn(agent)
GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_get_stat_param]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-04-23>
-- Description:	<计算统计查询日期范围>
-- =============================================
CREATE PROCEDURE [dbo].[sp_chengdu_get_stat_param]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0 out,			-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报
	
	@PrjID int = 0,					-- 缺省0表示所有项目
	@Skills varchar(100) = null,		-- 缺省null表示所有技能组
	@Agents varchar(100) = null,		-- 缺省null表示所有坐席

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null out,		-- 需要统计的起始时间 
	@Time_End datetime = null out,			-- 需要统计的结束时间
	@DataGroup varchar(10) = 'day' out,		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30,						-- 统计间隔时长, 单位：分

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
					   @DataGroup = 'month'							-- 年报按照月份分组
				set @Error = @@error
			end
			else if (@Month between 1 and 12) begin
				if @Day = 0	begin
					-- mm = 01～12 & dd = 00：月报
					select @Time_Begin = cast((@Year * 100 + @Month) as char(6)) + '01', 
						   @Time_End = dateadd(month, 1, @Time_Begin),	-- 计算范围为1月
						   @DataGroup = 'day'							-- 月报按照天分组
				end
				else begin
					-- mm = 01～12 & dd > 0：日报
					select @Time_Begin = cast((@RepDate) as char(8)), 
						   @Time_End = dateadd(day, 1, @Time_Begin),	-- 计算范围为1天
						   @DataGroup = ''								-- 日报不按照时间字段分组
				end
				set @Error = @@error
			end
			else if @Month = 20 and (@Day between 1 and 4) begin
				-- mm = 20 & dd = 01～04：季报
				select @Time_Begin = cast(@Year as char(4)) + '0101',
					   @Time_Begin = dateadd(month, (@Day - 1) * 3, @Time_Begin),
					   @Time_End = dateadd(month, 3, @Time_Begin),	-- 计算范围为3月=1季度
					   @DataGroup = 'month'						-- 季报按照月分组
				set @Error = @@error
			end
			else if @Month = 30 and (@Day between 1 and 53) begin
				-- mm = 30 & dd = 01～53：周报
				select @Time_Begin = cast(@Year as char(4)) + '0101',
					   @Time_Begin = dateadd(day, (@Day - 1) * 7, @Time_Begin),
					   @Time_End = dateadd(day, 7, @Time_Begin),	-- 计算范围为1周
					   @DataGroup = 'day'							-- 周报按照天分组
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
	if @DataGroup = 'year' begin -- 按年分组
		select @DisplayPart = 'cast(RecDT as char(4))',
			   @GroupPart = 'RecDT / 100000000'
	end
	else if @DataGroup = 'month' begin	-- 按月分组
		select @DisplayPart = 'vxi_def.dbo.strdate_to_str(RecDT)',
			   @GroupPart = 'RecDT / 1000000'
	end
	else if @DataGroup = 'week' begin	-- 按星期分组
		declare @strBeginTime char(8)
		select @strBeginTime = convert(char(8), @Time_Begin, 112),
			   @DisplayPart = 'vxi_def.dbo.week_series_to_str(''' 
											+ @strBeginTime
											+ ''', RecDT)',
			   @GroupPart = 'vxi_def.dbo.week_series(''' 
									+ @strBeginTime
									+ ''', cast((RecDT / 10000) as char(8)))'
	end
	else if @DataGroup = 'day' begin	-- 按天分组
		select @DisplayPart = 'vxi_def.dbo.strdate_to_str(RecDT)',
			   @GroupPart = 'RecDT / 10000'
	end
	else begin	-- 不分组
		select @DisplayPart = 'vxi_def.dbo.strdate_to_str(RecDT)',
			   @GroupPart = 'RecDT'
	end

	select  @RoundBegin = vxi_ucd.dbo.time_to_bigint(@Time_Begin, @SplitTm),	--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm
			@RoundEnd = vxi_ucd.dbo.time_to_bigint(@Time_End, @SplitTm)			--化为@SplitTm整数分钟，整数型 yyyyMMddhhmm

	if @SpecBeginEnd = 0 begin	-- 不按照时间段取数
		-- 查询范围调整为半开半闭区间[@RoundBegin, @RoundEnd)
		set @RoundEnd = @RoundEnd - 1
	end

	-- 生成where部分
	set @WherePart = ' '
	if @PrjID != 0 begin
		set @WherePart = ' and (PrjID = ' + cast(replace(@PrjID, '''', '') as nvarchar(11)) + ') '
	end

	if len(isnull(@Skills, '')) > 0 begin
		set @WherePart = @WherePart + 'and (Skill in (' + replace(@Skills, '''', '') + ')) '
	end

	if len(isnull(@Agents, '')) > 0 begin
		set @WherePart = @WherePart + 'and (Agent in (' + replace(@Agents, '''', '') + ')) '
	end

	return 0
END


GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_ivr_svc_type]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_chengdu_ivr_svc_type]
	@date_from datetime = null,
	@date_to datetime = null
AS
	if @date_from is null begin
		-- set @date_from = floor(cast(getdate() as float))
		set @date_from = cast(getdate() - 0.5 as int)
		set @date_to = cast(getdate() - 0.5 as int) + 1
	end
	if @date_to is null begin
		set @date_to = cast(getdate() - 0.5 as int) + 1
	end

	if (select count(*) from chengdu_agentsn) = 0 begin
		exec sp_chengdu_agent_sn_init
	end

	-- if exists(select nodename from ivrnodetype where nodename = 'svctype') 

	select r.ucdid, r.flowid, n.nodetype, t.selection, 
			case t.selection 
				when '0' then '11' 	-- 人式服务
				when '2' then '16' 	-- 举报投诉
				when '3' then '12' 	-- 听取录音
				when '4' then '13' 	-- 索取传真
				else '00' 
			end SF
		into #TempIvrType
		from vxi_ivr..ivrrecords r, vxi_ivr..ivrtrack t, vxi_ivr..ivrnodetype n, (
			select t.ivrid, min(t.subid) subid 
				from vxi_ivr..ivrrecords r, vxi_ivr..ivrtrack t, vxi_ivr..ivrnodetype n
				where r.ivrid = t.ivrid
					and t.nodename = n.nodename
					and n.nodetype = 'getdigits'
					and t.selection in ('0', '1','2', '3', '4')
					and r.starttime between @date_from and @date_to
					and r.ucdid > 0
				group by t.ivrid
			) m
		where r.ivrid = t.ivrid 
			and r.flowid = n.flowid and t.nodename = n.nodename
			and n.nodetype = 'getdigits'
			and t.ivrid = m.ivrid and t.subid = m.subid
			and r.starttime between @date_from and @date_to
		order by t.ivrid desc, t.subid

	-- Add for Test
	-- /*
	select @date_from, @date_to
	select * from #TempIvrType
	select u.* from chengdu_UcdCallLog u inner join #TempIVrType t on u.ucdid = t.ucdid
		where u.StartTime between @date_from and @date_to
	-- */
	-- End of Test

	update chengdu_UcdCallLog
		set SF = t.SF
		from chengdu_UcdCallLog u inner join #TempIVrType t on u.ucdid = t.ucdid
		where u.StartTime between @date_from and @date_to
			and u.SF is null

	drop table #TempIvrType
GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_stat_agent_report]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-08-08>
-- Description:	<查询统计中间结果表，取得完整的坐席状态统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_chengdu_stat_agent_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Agents varchar(100) = null,	-- 缺省null表示所有坐席
	--@Skills varchar(100) = null,	-- 缺省null表示所有技能组

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@DataGroup varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @ReturnValue int

	EXEC	@ReturnValue = [dbo].[sp_chengdu_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@DataGroup = @DataGroup OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Agents = @Agents,
			@Skills = '',	--@Skills,
			@SplitTm = @SplitTm

	if @@error != 0 or @ReturnValue != 0 begin
		raiserror('exec sp_chengdu_get_stat_param error!', 1, 1)
		return @ReturnValue
	end

	-- 由于按年做sum可能会溢出，故先调vxi_def.dbo.ms_to_int_sec(xx)，再sum
	-- 时间单位为s
	select	@DisplayPart = replace(@DisplayPart, 'RecDT', 'isnull(sca.RecDT,sa.RecDT)'),

-- 200711023 下面这个查询为Bobo要求改回原来的查询样式
			@ExecSQL =
'select isnull(cast(ag.GroupId as varchar(20)), '''')GroupID,isnull(isnull(sca.Agent,sa.Agent), ''合计'')Agent,
isnull(cast(sa.Login_t as int),0)Login_t,isnull(cast(sca.CallInOut_t as int),0)CallInOut_t,isnull(sca.CallInOut_t/sa.Login_t,0)CallInOut_tdl,isnull(sca.CallInOut_n,0)CallInOut_n,
isnull(sca.CallInOut_n/(sa.Login_t/3600.0),0)CallInOut_ndl,isnull(cast(case when sca.CallInOut_n!=0 then sca.CallInOut_t/sca.CallInOut_n end as int),0)CallInOut_tdn,
isnull(cast(sca.CallIn_t as int),0)CallIn_t,isnull(sca.CallIn_t/sa.Login_t,0)CallIn_tdl,isnull(sca.CallIn_n,0)CallIn_n,isnull(sca.CallIn_n/(sa.Login_t/3600.0),0)CallIn_ndl,
isnull(cast(case when sca.CallIn_n!=0 then sca.CallIn_t/sca.CallIn_n end as int),0)CallIn_tdn,
isnull(cast(sca.CallOut_t as int),0)CallOut_t,isnull(sca.CallOut_t/sa.Login_t,0)CallOut_tdl,isnull(sca.CallOut_n,0)CallOut_n,isnull(sca.CallOut_n/(sa.Login_t/3600.0),0)CallOut_ndl,
isnull(cast(case when sca.CallOut_n!=0 then sca.CallOut_t/sca.CallOut_n end as int),0)CallOut_tdn,
isnull(cast(sca.CallInner_t as int),0)CallInner_t,isnull(sca.CallInner_n,0)CallInner_n,isnull(sca.Trans_n,0)Trans_n,
isnull(cast( case when (isnull(sa.Login_t,0)-isnull(sca.CallInOut_t,0)-isnull(sa.NotReady_t,0)) > 0 then isnull(sa.Login_t,0)-isnull(sca.CallInOut_t,0)-isnull(sa.NotReady_t,0) end as int),0)Idle_t,
isnull(case when (isnull(sa.Login_t,0)-isnull(sca.CallInOut_t,0)-isnull(sa.NotReady_t,0)) > 0 then (isnull(sa.Login_t,0)-isnull(sca.CallInOut_t,0)-isnull(sa.NotReady_t,0))/sa.Login_t end,0)Idle_tdl,
isnull(cast(sa.NotReady_t as int),0)NotReady_t,isnull(sa.NotReady_t/sa.Login_t,0)NotReady_tdl,
isnull(cast(case when sca.Ans_n!=0 then sca.Ans_t/sca.Ans_n end as int),0)Ans_tdn,
isnull(sca.Ans_t/sa.Login_t,0)Ans_tdl,isnull(sca.CallInOut_t/sa.Login_t,0)Efficiency
from 
(
	select Agent,cast(sum(vxi_def.dbo.ms_to_int_sec(isnull(Skill_t,0)+isnull(ExtIn_t,0))) as float)CallIn_t,cast(isnull(sum(vxi_def.dbo.ms_to_int_sec(OutTalk_t)),0) as float)CallOut_t,cast(sum(vxi_def.dbo.ms_to_int_sec(isnull(Skill_t,0)+isnull(ExtIn_t,0)+isnull(OutTalk_t,0))) as float)CallInOut_t,sum(isnull(Ans_n,0)+isnull(ExtIn_n,0))CallIn_n,isnull(sum(OutTalk_n),0)CallOut_n,sum(isnull(Ans_n,0)+isnull(ExtIn_n,0)+isnull(OutTalk_n,0))CallInOut_n,sum(AnsMore_n)AnsMore_n,sum(AbanMore)AbanMore,sum(vxi_def.dbo.ms_to_int_sec(ExtInner_t))CallInner_t,sum(ExtInner_n)CallInner_n,sum(Trans_n)Trans_n,cast(isnull(sum(vxi_def.dbo.ms_to_int_sec(Ans_t)),0) as float)Ans_t,sum(Ans_n)Ans_n
	from vxi_ucd..stat_call_agent
	where (RecDT between @RoundBegin and @RoundEnd) ' + @WherePart + '
	group by Agent with cube 
) sca
full join
(
	select Agent,cast(case when sum(vxi_def.dbo.ms_to_int_sec(Login_t))!=0 then sum(vxi_def.dbo.ms_to_int_sec(Login_t)) end as float)Login_t,sum(vxi_def.dbo.ms_to_int_sec(isnull(NotReady00_t,0)+isnull(NotReady01_t,0)+isnull(NotReady02_t,0)+isnull(NotReady03_t,0)+isnull(NotReady04_t,0)+isnull(NotReady05_t,0)+isnull(NotReady06_t,0)+isnull(NotReady07_t,0)+isnull(NotReady08_t,0)+isnull(NotReady09_t,0)))NotReady_t
	from vxi_ucd..stat_agent
	where (RecDT between @RoundBegin and @RoundEnd) ' + @WherePart + '
	group by Agent with cube
) sa on isnull(sca.Agent,'''')=isnull(sa.Agent,'''')
left join (select top 100 percent Agent,min(GroupId) GroupId from vxi_sys..AgentGroup group by Agent order by 1) ag on sca.Agent=ag.Agent collate Chinese_PRC_CI_AS or sa.Agent=ag.Agent collate Chinese_PRC_CI_AS
order by 1, 2'
/*
-- 按照晓霞的要求进行修改的程序报表，新增了一些字段
			@ExecSQL =
'select case when isnull(sca.RecDT,sa.RecDT) is not null then ' + @DisplayPart + ' else ''合计'' end RecDT,ag.GroupId,isnull(sca.Agent,sa.Agent) Agent,sa.LoginTime,sa.LogoutTime,sa.Login_t / 3600.0 Login_ht,(sca.CallInOut_t/3600.0) CallInOut_ht,sca.CallInOut_t/sa.Login_t CallInOut_tdl,sca.CallInOut_n,sca.CallInOut_n/(sa.Login_t/3600.0) CallInOut_ndl,case when sca.CallInOut_n!=0 then sca.CallInOut_t/sca.CallInOut_n end CallInOut_tdn,(sca.CallIn_t/3600.0) CallIn_ht,sca.CallIn_t/sa.Login_t CallIn_tdl,sca.CallIn_n,sca.CallIn_n/(sa.Login_t/3600.0) CallIn_ndl,case when sca.CallIn_n!=0 then sca.CallIn_t/sca.CallIn_n end CallIn_tdn,(sca.CallOut_t/3600.0) CallOut_ht,sca.CallOut_t/sa.Login_t CallOut_tdl,sca.CallOut_n,sca.CallOut_n/(sa.Login_t/3600.0) CallOut_ndl,case when sca.CallOut_n!=0 then sca.CallOut_t/sca.CallOut_n end CallOut_tdn,sca.AnsMore_n,sca.AbanMore,(sca.CallInner_t/3600.0) CallInner_ht,sca.CallInner_n,sca.Trans_n,((isnull(sa.Login_t,0)-isnull(sca.CallInOut_t,0)-isnull(sa.NotReady_t,0))/3600.0) Idle_t,((isnull(sa.Login_t,0)-isnull(sca.CallInOut_t,0)-isnull(sa.NotReady_t,0))/sa.Login_t) Idle_tdl,(sa.NotReady_t/3600.0) NotReady_ht,sa.NotReady_t/sa.Login_t NotReady_tdl,case when sca.Ans_n!=0 then sca.Ans_t/sca.Ans_n end Ans_tdn,sca.Ans_t/sa.Login_t Ans_tdl,sca.CallInOut_t/sa.Login_t Efficiency
from 
(
	select ' + @GroupPart + ' RecDT,Agent,cast(sum(vxi_def.dbo.ms_to_int_sec(isnull(Skill_t,0) + isnull(ExtIn_t,0))) as float) CallIn_t,cast(isnull(sum(vxi_def.dbo.ms_to_int_sec(OutTalk_t)),0) as float) CallOut_t,cast(sum(vxi_def.dbo.ms_to_int_sec(isnull(Skill_t,0) + isnull(ExtIn_t,0) + isnull(OutTalk_t,0))) as float) CallInOut_t,sum(isnull(Ans_n,0)+isnull(ExtIn_n,0)) CallIn_n,isnull(sum(OutTalk_n),0) CallOut_n,sum(isnull(Ans_n,0)+isnull(ExtIn_n,0)+isnull(OutTalk_n,0)) CallInOut_n,sum(AnsMore_n) AnsMore_n,sum(AbanMore) AbanMore,sum(vxi_def.dbo.ms_to_int_sec(ExtInner_t)) CallInner_t,sum(ExtInner_n) CallInner_n,sum(Trans_n) Trans_n,cast(isnull(sum(vxi_def.dbo.ms_to_int_sec(Ans_t)),0) as float) Ans_t,sum(Ans_n) Ans_n
	from vxi_ucd..stat_call_agent
	where (RecDT between @RoundBegin and @RoundEnd) ' + @WherePart + '
	group by ' + @GroupPart + ',Agent with cube having (' + @GroupPart + ' is not null and Agent is not null) or (' 
														  + @GroupPart + ' is null and Agent is null)
) sca
full join
(
	select ' + @GroupPart + ' RecDT,Agent,min(LoginTime) LoginTime,max(LogoutTime) LogoutTime,cast(case when sum(vxi_def.dbo.ms_to_int_sec(Login_t))!=0 then sum(vxi_def.dbo.ms_to_int_sec(Login_t)) end as float) Login_t,sum(vxi_def.dbo.ms_to_int_sec(isnull(NotReady00_t,0)+isnull(NotReady01_t,0)+isnull(NotReady02_t,0)+isnull(NotReady03_t,0)+isnull(NotReady04_t,0)+isnull(NotReady05_t,0)+isnull(NotReady06_t,0)+isnull(NotReady07_t,0)+isnull(NotReady08_t,0)+isnull(NotReady09_t,0))) NotReady_t
	from vxi_ucd..stat_agent
	where (RecDT between @RoundBegin and @RoundEnd) ' + @WherePart + '
	group by ' + @GroupPart + ',Agent with cube having (' + @GroupPart + ' is not null and Agent is not null) or ('
														  + @GroupPart + ' is null and Agent is null)
) sa on isnull(sca.RecDT,'''')=isnull(sa.RecDT,'''') and isnull(sca.Agent,'''')=isnull(sa.Agent,'''')
left join (select top 100 percent Agent,min(GroupId) GroupId from vxi_sys..AgentGroup group by Agent order by 1) ag on sca.Agent=ag.Agent collate Chinese_PRC_CI_AS or sa.Agent=ag.Agent collate Chinese_PRC_CI_AS
order by 1,2,3'
*/
	-- for debug
	print @ExecSQL
	print 'len(@ExecSQL)=' + cast(len(@ExecSQL) as varchar(50))
	--select @RoundBegin '@RoundBegin', @RoundEnd '@RoundEnd'

	exec @ReturnValue = sp_executesql @ExecSQL,
						N'@RoundBegin bigint, @RoundEnd bigint',
						@RoundBegin = @RoundBegin,
						@RoundEnd = @RoundEnd

	if @@error != 0 or @ReturnValue != 0 begin
		raiserror('exec sp_executesql error!', 1, 1)
		--return @ReturnValue
	end

	return @ReturnValue

END

GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_stat_call_report]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<yanwei.mao@vxichina.com>
-- Create date: <2007-08-08>
-- Description:	<查询统计中间结果表，取得完整的呼叫统计报表>
-- =============================================
CREATE PROCEDURE [dbo].[sp_chengdu_stat_call_report]
	-- Add the parameters for the stored procedure here
	@RepDate int = 0,				-- 缺省0表示当日的日报表，
									-- mm = 00 & dd = 00：年报
									-- mm = 01～12 & dd = 00：月报
									-- mm = 01～12 & dd > 0：日报
									-- mm = 20 & dd = 01～04：季报
									-- mm = 30 & dd = 01～53：周报

	@PrjID int = 0,					-- 缺省0表示所有项目
	@Agents varchar(100) = null,	-- 缺省null表示所有坐席
	@SkillList varchar(100) = null,	-- 缺省null表示所有技能组

	-- 以下用于时间段统计，时间段@Time_Begin/@Time_End优先于@RepDate统计
	@Time_Begin datetime = null,		-- 需要统计的起始时间 
	@Time_End datetime = null,			-- 需要统计的结束时间
	@DataGroup varchar(10) = '',		-- 分组级别 'year' / 'month' / 'week'/ 'day' /''
	@SplitTm int = 30					-- 统计间隔时长, 单位：分
AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @DisplayPart nvarchar(512), @GroupPart nvarchar(512), @WherePart nvarchar(512)
	declare @ExecSQL nvarchar(4000)
	declare @RoundBegin bigint, @RoundEnd bigint	-- 圆整过的日期时间值
	declare @ReturnValue int

	EXEC	@ReturnValue = [dbo].[sp_chengdu_get_stat_param]
			@RepDate = @RepDate OUTPUT,
			@Time_Begin = @Time_Begin OUTPUT,
			@Time_End = @Time_End OUTPUT,
			@DataGroup = @DataGroup OUTPUT,
			@RoundBegin = @RoundBegin OUTPUT,
			@RoundEnd = @RoundEnd OUTPUT,
			@DisplayPart = @DisplayPart OUTPUT,
			@GroupPart = @GroupPart OUTPUT,
			@WherePart = @WherePart OUTPUT,
			@PrjID = @PrjID,
			@Agents = '',	--@Agents,
			@Skills = '',	--@SkillList,
			@SplitTm = @SplitTm

	if @@error != 0 or @ReturnValue != 0 begin
		raiserror('exec sp_chengdu_get_stat_param error!', 1, 1)
		return @ReturnValue
	end

	-- 由于按年做sum可能会溢出，故先调vxi_def.dbo.ms_to_int_sec(xx)，再sum
	-- 时间单位为s
	select	@DisplayPart = replace(@DisplayPart, 'RecDT', 'isnull(isnull(isnull(tk.RecDT,cs.RecDT),sca.RecDT),sa.RecDT)'),
			@ExecSQL =
'select case when isnull(isnull(isnull(tk.RecDT,cs.RecDT),sca.RecDT),sa.RecDT)!=0 then '
			+ @DisplayPart + ' else ''合计'' end RecDT,isnull(tk.TrunkIn_n,0)TrunkIn_n,isnull(tk.TrunkOut_n,0)TrunkOut_n,isnull(cs.SkillIn_n,0)SkillIn_n,isnull(cs.Ans_n,0)Ans_n,
		isnull(cs.Ans_n/cs.SkillIn_n,0)Ans_nds,isnull(cs.AnsLess_n,0)AnsLess_n,isnull(cs.AnsLess_n/cs.SkillIn_n,0)AnsLess_nds,isnull(cs.AnsMore_n,0)AnsMore_n,
		isnull(cast(cs.Ans_tdn as int),0)Ans_tdn,isnull(cs.Aban_n,0)Aban_n,isnull(cs.Aban_n/cs.SkillIn_n,0)Aban_nds,isnull(cs.AbanMore_n,0)AbanMore_n,isnull(cs.AbanSkill_n,0)AbanSkill_n,
		isnull(cs.AbanSkill_n/cs.Aban_n,0)AbanSkill_nda,isnull(cs.AbanAgent_n,0)AbanAgent_n,isnull(cs.AbanAgent_n/cs.Aban_n,0)AbanAgent_nda,
		isnull(cast(sca.Aban_tdn as int),0)Aban_tdn,isnull(cs.MaxAns_t,0)MaxAns_t,isnull(cast(sca.CallIn_t as int),0)CallIn_t,isnull(cast(sa.Login_t as int),0)Login_t
from 
(
	select isnull(DT, 0) RecDT, * from (
		select ' + @GroupPart + ' DT,sum(TrunkIn_n)TrunkIn_n,sum(TrunkOut_n)TrunkOut_n
		from vxi_ucd..stat_call_trunk where (RecDT between @RoundBegin and @RoundEnd)
		group by ' + @GroupPart + ' with cube
	) t
) tk
full join
(
	select isnull(DT, 0) RecDT, * from (
		select ' + @GroupPart + ' DT,case when sum(SkillIn_n) != 0 then cast(sum(SkillIn_n) as float) end SkillIn_n,
			sum(Ans_n) Ans_n,sum(AnsLess_n) AnsLess_n,sum(AnsMore_n) AnsMore_n,
			case when sum(Ans_n)!=0 then cast(sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) as float)/sum(Ans_n) end Ans_tdn,
			case when sum(Aban_n)!=0 then cast(sum(Aban_n) as float) end Aban_n,
			sum(AbanMore) AbanMore_n,sum(AbanSkill) AbanSkill_n,sum(AbanAgent) AbanAgent_n,
			vxi_def.dbo.ms_to_int_sec(max(MaxAns_t)) MaxAns_t
		from vxi_ucd..stat_call_skill where (RecDT between @RoundBegin and @RoundEnd)'
		+ @WherePart + case when len(@SkillList) > 0 then ' and (Skill in (' + @SkillList + '))' else '' end +
		'	group by ' + @GroupPart + ' with cube
	) t
) cs on tk.RecDT=cs.RecDT
full join
(
	select isnull(DT, 0) RecDT, * from (
		select ' + @GroupPart + ' DT,
			case when sum(Aban_n)!=0 then cast(sum(Aban_t) as float)/sum(Aban_n)/1000 end Aban_tdn,
			sum(vxi_def.dbo.ms_to_int_sec(isnull(Skill_t,0)+isnull(ExtIn_t,0)))CallIn_t
		from vxi_ucd..stat_call_agent
		where (RecDT between @RoundBegin and @RoundEnd)' 
		+ @WherePart + case when len(@Agents) > 0 then ' and (Agent in (' + @Agents + '))' else '' end +
		'	group by ' + @GroupPart + ' with cube
	) t
) sca on tk.RecDT=sca.RecDT or cs.RecDT=sca.RecDT
full join
(
	select isnull(DT, 0) RecDT, * from (
		select ' + @GroupPart + ' DT,sum(vxi_def.dbo.ms_to_int_sec(Login_t))Login_t
		from vxi_ucd..stat_agent
		where (RecDT between @RoundBegin and @RoundEnd)'
		+ @WherePart + case when len(@Agents) > 0 then ' and (Agent in (' + @Agents + '))' else '' end +
		'	group by ' + @GroupPart + ' with cube
	) t
) sa on tk.RecDT=sa.RecDT or cs.RecDT=sa.RecDT or sca.RecDT=sa.RecDT
order by 1'

	-- for debug
	print @ExecSQL
	print 'len(@ExecSQL)=' + cast(len(@ExecSQL) as varchar(50))
	--select @RoundBegin '@RoundBegin', @RoundEnd '@RoundEnd'

	exec @ReturnValue = sp_executesql @ExecSQL,
						N'@RoundBegin bigint, @RoundEnd bigint',
						@RoundBegin = @RoundBegin,
						@RoundEnd = @RoundEnd

	if @@error != 0 or @ReturnValue != 0 begin
		raiserror('exec sp_executesql error!', 1, 1)
		--return @ReturnValue
	end

	return @ReturnValue

END

GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_stat_call_work]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<wenyong xia>
-- Create date: <2007 12/01>
-- Description:	<统计工作时间电话分布>
-- =============================================
CREATE PROCEDURE [dbo].[sp_chengdu_stat_call_work] 
	@time_begin datetime = null,	-- 统计起始时间
	@time_end datetime = null		-- 统计截至时间

AS
BEGIN
	if @time_begin is null begin
		select @time_begin = cast(str(year(getdate()))+str(month(getdate()))+str(day(getdate()))+' 00:00:00' as datetime)
		--select @time_begin = cast(year(getdate())*10000+month(getdate())*100+day(getdate()) as datetime)
	end
	if @time_end is null begin
		set @time_end = getdate()
	end	
	select '1' ItemNo,'电话总数:' Describe,isnull(count(ivrid),0) Amount
		from vxi_ivr..ivrrecords 
		where starttime between @time_begin and @time_end 
	union
	select '2','+工作时间电话总数:',isnull(count(ivrid),0)
		from vxi_ivr..ivrrecords 
		where starttime between @time_begin and @time_end 
				and ivrid in ( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7')
	union
	select '3','----人工服务:',isnull(count(ivrid),0) 
		from vxi_ivr..ivrrecords 
		where starttime between @time_begin and @time_end 
			and ivrid in ( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '0')
	union
	--add by wenyong xia 2007 12/12
	select '4','----社保卡挂失:',isnull(count(ivrid),0) 
		from vxi_ivr..ivrrecords 
		where starttime between @time_begin and @time_end 
			and ivrid in ( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '1')
	union
	--
	select '5','----举报投诉:',isnull(count(ivrid),0) 
		from vxi_ivr..ivrrecords
		where starttime between @time_begin and @time_end 
		and ivrid in ( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '2')
	union
	select '6','----政策及热点问题:',count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '3') a
					inner join vxi_ivr..ivrrecords b on a.ivrid = b.ivrid 
			where b.starttime  between @time_begin and @time_end ) c
	/*
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;热点问题:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '3') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '188' and selection = '1') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;政策咨询:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '3') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '188' and selection = '2') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	*/
	union
	select '7','----索取传真:',count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
					inner join vxi_ivr..ivrrecords b on a.ivrid = b.ivrid 
			where b.starttime  between @time_begin and @time_end ) c
	/*
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;就业:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '1') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;劳动关系:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '2') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;养老保险:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '3') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;医疗保险:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '4') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;工伤生育保险:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '5') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;失业保险:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '6') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
		where d.starttime  between @time_begin and @time_end 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;综合保险:', count(c.b_subid) from 
		(select b.ivrid b_ivrid,b.subid b_subid from 
			(select ivrid,subid from vxi_ivr..ivrtrack where nodename = '7' and selection = '4') a
				inner join
			(select ivrid,subid from vxi_ivr..ivrtrack  where nodename = '245' and selection = '7') b 
				on a.ivrid = b.ivrid
				where b.subid > a.subid ) c
			inner join vxi_ivr..ivrrecords d 
			on c.b_ivrid = d.ivrid 
	where d.starttime  between @time_begin and @time_end 
	*/
	union
	select '8','+非工作时间电话总数:',isnull(count(ivrid),0)
		from vxi_ivr..ivrrecords 
		where starttime between @time_begin and @time_end 
				and ivrid not in ( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7')
	union
	--add by wenyong xia 2007 12/12
	select '9','----社保卡挂失:',count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '693' and selection = '1' 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	--
	union
	select '10','----政策及热点问题:',count(c.a_subid) from 
			(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '188' and selection in ('1','2') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	/*
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;热点问题:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '188' and selection = '1' 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;政策咨询:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid ivrid,subid subid from vxi_ivr..ivrtrack  
			where nodename = '188' and selection = '2' 
				and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end ) c
	*/
	union
	select '11','----索取传真:',count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('1','2','3','4','5','6','7') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	/*
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;就业:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('1') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;劳动关系:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('2') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;养老保险:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('3') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c  
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;医疗保险:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('4') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;工伤生育保险:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('5') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;失业保险:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('6') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c 
	union
	select @seq,'&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;综合保险:', count(c.a_subid) from 
		(select a.ivrid a_ivrid,a.subid a_subid from
			(select ivrid,subid from vxi_ivr..ivrtrack  
				where nodename = '245' and selection in ('7') 
					and ivrid not in( select distinct(ivrid) from vxi_ivr..ivrtrack where nodename = '7' and selection = '3')) a
				inner join vxi_ivr..ivrrecords b 
			on a.ivrid = b.ivrid
			where b.starttime  between @time_begin and @time_end )c
	*/  

END






GO
/****** Object:  StoredProcedure [dbo].[sp_chengdu_ucd_call_log]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[sp_chengdu_ucd_call_log] 
	@time_begin datetime = null,	-- 开始时间
	@time_end datetime = null	-- 结束时间
AS
	declare @cid varchar(4)
	set @cid = 'TEST'

	declare @result int
	if @time_begin is null
		set @time_begin = convert(varchar(10), getdate(), 120) + ' 00:00:00'

	if @time_end is null
		set @time_end = convert(varchar(10), getdate(), 120) + ' 23:59:59'

	set @result = 0

	--过滤出ucd, ucdcall数据
	select * into #ucd from (
		select * from vxi_ucd..ucd where (StartTime between @time_begin and @time_end) and (Inbound = 1 or Outbound = 1)
	) u

	CREATE INDEX [IX_Ucd_temp] ON [#ucd]([UcdId]) --ON [PRIMARY]

	select * into #ucdcall from vxi_ucd..ucdcall uc 
		where uc.ucdid between (select min(ucdid) from #ucd) and (select max(ucdid) from #ucd)

	CREATE INDEX [IX_UcdCall_temp] ON [#ucdcall]([UcdId], [subid]) --ON [PRIMARY]


	begin tran
	delete from chengdu_UcdCallLog where StartTime between @time_begin and @time_end	--删除现有数据
	--插入新数据
	insert into chengdu_UcdCallLog(ucdid, StartTime, UcdHour, CID, [DATE], ASSN, BT, PN, WBT, WET, SN, TPMBT, TPMET, RT, ASN, ET)
	select u.ucdid, u.StartTime, u.UcdHour, @cid CID, u.UcdDate [DATE], cast((u.ucdid % 1000000) as int) ASSN,
			case uc1.bEstb when 1 then DATEADD(ms, uc1.OnEstb, u.starttime) else null end BT,
			case u.inbound when 1 then u.calling else u.called end PN, u.starttime WBT,
			case uc1.bEstb when 1 then DATEADD(ms, uc1.OnEstb, u.starttime) else DATEADD(ms, uc1.OnCallEnd, u.starttime) end WET, 
			isnull(sn_u.SN, dbo.func_chengdu_agent_sn(u.agent)) SN, DATEADD(ms, ucc.OnConf, u.starttime) TPMBT, 
			DATEADD(ms, ucc.OnConfEnd, u.starttime) TPMET, DATEADD(ms, uctr.OnTrans, u.starttime) RT, 
			isnull(sn_uctr.SN, dbo.func_chengdu_agent_sn(uctr.Agent)) ASN, DATEADD(ms, u.TimeLen, u.starttime) ET
		--into #tmp_log
		from #ucd u 
			left join ( 
				select uct1.ucdid, uct1.bEstb, uct1.OnEstb, uct1.OnCallEnd 
					from #ucdcall uct1 
					where uct1.subid = (
										select min(uct2.subid) from #ucdcall uct2 where uct2.ucdid = uct1.ucdid
										)
			) uc1 on u.ucdid = uc1.ucdid
			left join ( 
				select ucdc1.ucdid, min(ucdc1.OnConf) OnConf, isnull(max(ucdc1.OnConfEnd), 
					max(ucdc1.OnCallEnd)) OnConfEnd 
					from #ucdcall ucdc1
					where ucdc1.bConf = 1 group by ucdc1.ucdid 
			) ucc on u.ucdid = ucc.ucdid
			left join ( 
				select uct1.ucdid, uct1.OnTrans, uct1.agent 
					from #ucdcall uct1 
					where (uct1.bTrans = 1) 
						and ( uct1.subid = (select min(uct2.subid) from #ucdcall uct2 
											where uct2.bTrans = 1 
											and uct2.ucdid = uct1.ucdid												
											and (not exists(select * from #ucd n_u 
															where n_u.ucdid = uct2.ucdid and n_u.agent = uct2.agent)) 
										   ) )
				) uctr on u.ucdid = uctr.ucdid
			left join chengdu_AgentSN sn_u on u.agent = sn_u.agent collate Chinese_PRC_CI_AS
			left join chengdu_AgentSN sn_uctr on uctr.Agent = sn_uctr.agent collate Chinese_PRC_CI_AS


	if @@Error = 0 begin
		-- drop table #tmp_log
		commit tran
	end
	else begin
		rollback tran
		set @result = 1
	end

	drop table #ucd
	drop table #ucdcall

	return @result
	/*-------------------------------以下不用------------------------------------*/

	--按日期写入ASSN
	declare @curDateInGrp int, @curMaxNoInGrp int
	declare @ucdDate int, @assn int--, @ucdid bigint--, @maxassn int
	declare curLog CURSOR /*FAST_FORWARD*/ FOR 
		select /*UcdId,*/ [Date], ASSN from chengdu_UcdCallLog
			where StartTime between @time_begin and @time_end order by StartTime
			FOR UPDATE OF ASSN

	OPEN curLog
		fetch next from curLog into /*@ucdid,*/ @ucdDate, @assn --, @maxassn

	if @@FETCH_STATUS = 0 begin
		set @curDateInGrp = @ucdDate
		set @curMaxNoInGrp = (
			select isnull(max(ASSN), 0) from chengdu_UcdCallLog 
				where /*(not (StartTime between @time_begin and @time_end)) and*/ ([Date] = @ucdDate))
		-- set @curMaxNoInGrp = @maxassn
	end
	while @@FETCH_STATUS = 0 begin
		if @curDateInGrp = @ucdDate begin	--同一组
			set @curMaxNoInGrp = @curMaxNoInGrp + 1
		end
		else begin	--新日期，取该日期下最大数
		-- set @curMaxNoInGrp = @maxassn + 1
			set @curMaxNoInGrp = (select isnull(max(ASSN), 0) from chengdu_UcdCallLog 
				where /*(not (StartTime between @time_begin and @time_end)) and*/ ([Date] = @ucdDate)) + 1
			set @curDateInGrp = @ucdDate
		end
	
		-- 修改ASSN
		update chengdu_UcdCallLog set ASSN = @curMaxNoInGrp where current of curLog

		/*
		if @@Error <> 0 begin
		print 'error: update' + cast(@ucdDate as varchar(11))
		rollback tran
		return 1
		end
		*/
	
		--继续下一条
		fetch next from curLog into /*@ucdid,*/ @ucdDate, @assn --, @maxassn
	end
	CLOSE curLog
	DEALLOCATE curLog

	-- 保存到chengdu_UcdCallLog
	-- insert into chengdu_UcdCallLog(ucdid, StartTime, UcdHour, [DATE], ASSN, BT, PN, WBT, WET, SN, TPMBT, TPMET, RT, ASN, ET)
	--	select ucdid, StartTime, UcdHour, [DATE], ASSN, BT, PN, WBT, WET, SN, TPMBT, TPMET, RT, ASN, ET from #tmp_log

	/*
	if @@Error = 0 begin
		-- drop table #tmp_log
		commit tran
	end
	else begin
		rollback tran
		set @result = 1
	end
	*/

	return @result



GO
/****** Object:  StoredProcedure [dbo].[sp_csc_half_hour_report]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_csc_half_hour_report]
	-- Add the parameters for the stored procedure here
	@BeginTime datetime,			-- 需要统计的起始时间 
	@EndTime datetime,				-- 需要统计的结束时间
	@SplitTm int = 30				-- 统计间隔时长, 单位：分钟
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	if ( (@BeginTime is null) or (@EndTime is null) ) begin
		raiserror('@BeginTime和@EndTime不能为null', 1, 1)
		return 1
	end

	declare	@StatBegin bigint,				-- 起始日期时间值数字表示yyyyMMddhhmm
			@StatEnd bigint					-- 结束日期时间值数字表示yyyyMMddhhmm

	select  @StatBegin = vxi_ucd.dbo.time_to_bigint(@BeginTime, @SplitTm),
			@StatEnd = vxi_ucd.dbo.time_to_bigint(@EndTime, @SplitTm)

	select isnull(isnull(sa.RecDT, sca.RecDT), scs.RecDT) RecDT, sca.Skill_n,
		sca.Ans_n, case when sca.Skill_n != 0 then cast(sca.Ans_n as float) / sca.Skill_n end Ans_p, 
		sca.AnsLess_n, case when sca.Skill_n != 0 then cast(sca.AnsLess_n as float) / sca.Skill_n end AnsLess_p, 
		scs.Aban_n, case when sca.Skill_n != 0 then cast(scs.Aban_n as float) / sca.Skill_n end Aban_p, 
		sca.AbanAgent, scs.AbanSkill, sca.Talk_t_n, scs.Aban_t_n, sca.Ans_t_n, sca.Ans_t_max, 
		sca.Loss_n, sa.Login_t, sca.Talk_t, sca.Ring_t, 
		case when sa.Login_t != 0 then (sca.Talk_t + sca.Ring_t) / sa.Login_t end Efficiency
	from
	(
		select RecDT, (sum(vxi_def.dbo.ms_to_int_sec(Login_t)) / 3600.0) Login_t
		from vxi_ucd..stat_agent
		where RecDT between @StatBegin and @StatEnd Group by RecDT
	) sa
	full join
	(
		select RecDT, sum(Skill_n) Skill_n, sum(Ans_n) Ans_n, sum(AnsLess_n) AnsLess_n,
			max(vxi_def.dbo.ms_to_int_sec(Ans_t)) Ans_t_max,
			(sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) / 3600.0) Ring_t,
			case when sum(Ans_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) / sum(Ans_n) end Ans_t_n,
			sum(Aban_n) AbanAgent, sum(Loss_n) Loss_n,
			(sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) / 3600.0) Talk_t,
			case when sum(Talk_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) / sum(Talk_n) end Talk_t_n
		from vxi_ucd..stat_call_agent
		where RecDT between @StatBegin and @StatEnd Group by RecDT
	) sca
	on sa.RecDT = sca.RecDT
	full join
	(
		select RecDT, 
			sum(Aban_n) Aban_n, sum(AbanSkill) AbanSkill, 
			case when sum(Aban_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(Aban_t)) / sum(Aban_n) end Aban_t_n
		from vxi_ucd..stat_call_skill
		where RecDT between @StatBegin and @StatEnd group by RecDT
	) scs
	on sa.RecDT = scs.RecDT
	Order by isnull(isnull(sa.RecDT, sca.RecDT), scs.RecDT)

	return 0

END










GO
/****** Object:  StoredProcedure [dbo].[sp_get_projects]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE procedure [dbo].[sp_get_projects]
	@currentDate varchar(10)
as
	select prjid id, project projectName, summary description 
		from vxi_sys..projects
		where startDay <= cast(@currentDate as int)
		and stopDay >= cast(@currentDate as int)
		and enabled = 1






GO
/****** Object:  StoredProcedure [dbo].[sp_report_15]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_report_15]
	-- Add the parameters for the stored procedure here
	@BeginTime datetime,			-- 需要统计的起始时间 
	@EndTime datetime,				-- 需要统计的结束时间
	@SplitTm int = 30				-- 统计间隔时长, 单位：分钟
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	if ( (@BeginTime is null) or (@EndTime is null) ) begin
		raiserror('@BeginTime和@EndTime不能为null', 1, 1)
		return 1
	end

	declare	@StatBegin bigint,				-- 起始日期时间值数字表示yyyyMMddhhmm
			@StatEnd bigint					-- 结束日期时间值数字表示yyyyMMddhhmm

	select  @StatBegin = vxi_ucd.dbo.time_to_bigint(@BeginTime, @SplitTm),
			@StatEnd = vxi_ucd.dbo.time_to_bigint(@EndTime, @SplitTm)

	select isnull(sa.Agent, sca.Agent) Agent, sa.Login_t, 
		sca.Talk_t, case when sa.Login_t != 0 then (sca.Talk_t / sa.Login_t) end Talk_p, 
		sca.Talk_n, case when sa.Login_t != 0 then (sca.Talk_n / sa.Login_t) end Talk_n_l,
		sca.Talk_t_n, 
		sca.InTalk_t, case when sa.Login_t != 0 then (sca.InTalk_t / sa.Login_t) end InTalk_p, 
		sca.InTalk_n, case when sa.Login_t != 0 then (sca.InTalk_n / sa.Login_t) end InTalk_n_l,
		sca.InTalk_t_n, 
		sca.OutTalk_t, case when sa.Login_t != 0 then (sca.OutTalk_t / sa.Login_t) end OutTalk_p, 
		sca.OutTalk_n, case when sa.Login_t != 0 then (sca.OutTalk_n / sa.Login_t) end OutTalk_n_l,
		sca.OutTalk_t_n, 
		sca.Inner_t, sca.Inner_n, sca.Trans_n,
		sa.Idle_t, case when sa.Login_t != 0 then (sa.Idle_t / sa.Login_t) end Idle_p,
		sa.NotReady00_t, case when sa.Login_t != 0 then (sa.NotReady00_t / sa.Login_t) end NotReady00_p,
		sa.NotReady01_t, case when sa.Login_t != 0 then (sa.NotReady01_t / sa.Login_t) end NotReady01_p,
		sa.NotReady02_t, case when sa.Login_t != 0 then (sa.NotReady02_t / sa.Login_t) end NotReady02_p,
		sa.NotReady03_t, case when sa.Login_t != 0 then (sa.NotReady03_t / sa.Login_t) end NotReady03_p,
		sa.NotReady04_t, case when sa.Login_t != 0 then (sa.NotReady04_t / sa.Login_t) end NotReady04_p,
		sa.NotReady05_t, case when sa.Login_t != 0 then (sa.NotReady05_t / sa.Login_t) end NotReady05_p,
		sa.NotReady06_t, case when sa.Login_t != 0 then (sa.NotReady06_t / sa.Login_t) end NotReady06_p,
		sa.NotReady07_t, case when sa.Login_t != 0 then (sa.NotReady07_t / sa.Login_t) end NotReady07_p,
		sa.NotReady08_t, case when sa.Login_t != 0 then (sa.NotReady08_t / sa.Login_t) end NotReady08_p,
		sa.NotReady09_t, case when sa.Login_t != 0 then (sa.NotReady09_t / sa.Login_t) end NotReady09_p,
		sca.Ring_t, case when sa.Login_t != 0 then (sca.Ring_t / sa.Login_t) end Ring_p,
		case when sa.Login_t != 0 then (sca.Talk_t + sca.Ring_t) / sa.Login_t end Efficiency
	from
	(
		select Agent, (sum(vxi_def.dbo.ms_to_int_sec(Login_t)) / 3600.0) Login_t,
			(sum(vxi_def.dbo.ms_to_int_sec(Idle_t)) / 3600.0) Idle_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady00_t)) / 3600.0) NotReady00_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady01_t)) / 3600.0) NotReady01_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady02_t)) / 3600.0) NotReady02_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady03_t)) / 3600.0) NotReady03_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady04_t)) / 3600.0) NotReady04_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady05_t)) / 3600.0) NotReady05_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady06_t)) / 3600.0) NotReady06_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady07_t)) / 3600.0) NotReady07_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady08_t)) / 3600.0) NotReady08_t,
			(sum(vxi_def.dbo.ms_to_int_sec(NotReady09_t)) / 3600.0) NotReady09_t
		from vxi_ucd..stat_agent
		where RecDT between @StatBegin and @StatEnd Group by Agent
	) sa
	full join
	(
		select Agent, (sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) / 3600.0) Talk_t, sum(Talk_n) Talk_n,
			case when sum(Talk_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) / sum(Talk_n) end Talk_t_n,
			(sum(vxi_def.dbo.ms_to_int_sec(InTalk_t)) / 3600.0) InTalk_t, sum(InTalk_n) InTalk_n,
			case when sum(InTalk_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(InTalk_t)) / sum(InTalk_n) end InTalk_t_n,
			(sum(vxi_def.dbo.ms_to_int_sec(OutTalk_t)) / 3600.0) OutTalk_t, sum(OutTalk_n) OutTalk_n,
			case when sum(OutTalk_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(OutTalk_t)) / sum(OutTalk_n) end OutTalk_t_n,
			(sum(vxi_def.dbo.ms_to_int_sec(Inner_t)) / 3600.0) Inner_t, sum(Inner_n) Inner_n,
			sum(Trans_n) Trans_n, (sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) / 3600.0) [Ring_t]
		from vxi_ucd..stat_call_agent
		where RecDT between @StatBegin and @StatEnd Group by Agent
	) sca
	on sa.Agent = sca.Agent
	order by isnull(sa.Agent, sca.Agent)

	return 0

END









GO
/****** Object:  StoredProcedure [dbo].[sp_report_17]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_report_17]
	-- Add the parameters for the stored procedure here
	@BeginTime datetime,			-- 需要统计的起始时间 
	@EndTime datetime,				-- 需要统计的结束时间
	@SplitTm int = 30				-- 统计间隔时长, 单位：分钟
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	if ( (@BeginTime is null) or (@EndTime is null) ) begin
		raiserror('@BeginTime和@EndTime不能为null', 1, 1)
		return 1
	end

	declare	@StatBegin bigint,				-- 起始日期时间值数字表示yyyyMMddhhmm
			@StatEnd bigint					-- 结束日期时间值数字表示yyyyMMddhhmm

	select  @StatBegin = vxi_ucd.dbo.time_to_bigint(@BeginTime, @SplitTm),
			@StatEnd = vxi_ucd.dbo.time_to_bigint(@EndTime, @SplitTm)

	select
		isnull(isnull(isnull(isnull(sa.RecDT, sca.RecDT), scs.RecDT), ed.RecDT), ab.RecDT) RecDT, 
		isnull(scs.SkillIn_n, 0) BeiJingActualSkillIn_n,	-- 北京实际日来电数 D
		isnull(scs.SkillIn_n, 0) 
			- isnull(ed.ShangHaiToBeiJing, 0) 
			+ isnull(ed.BeiJingToShangHai, 0) CurDayCallIn_n,	-- 日来电总数 A
		isnull(ed.BeiJingToShangHai, 0) BeiJingToShangHai,		-- 北京溢到上海数 B
		isnull(ed.ShangHaiToBeiJing, 0) ShangHaiToBeiJing,		-- 上海溢到北京数 C
		
		scs.Ans_n, (scs.Ans_n / scs.SkillIn_n) Ans_p, 
		scs.AnsLess_n, (scs.AnsLess_n / scs.SkillIn_n) AnsLess_p, 
		scs.AnsMore_n, scs.Ans_t_n,	scs.Aban_n, 
		(scs.Aban_n / scs.SkillIn_n) Aban_p, 
		(scs.AbanMore / scs.Aban_n) AbanMore_p, 
		scs.AbanSkill, 
		(scs.AbanSkill / scs.Aban_n) AbanSkill_p,
		scs.AbanAgent, 
		(scs.AbanAgent / scs.Aban_n) AbanAgent_p,
		sca.AgentAban_t, scs.Ans_t_max, 

		ab.an0_3,
		(ab.an0_3 / scs.Aban_n) an0_3_p,
		ab.an3_6,
		(ab.an3_6 / scs.Aban_n) an3_6_p,
		ab.an6_9,
		(ab.an6_9 / scs.Aban_n) an6_9_p,
		ab.an9_12,
		(ab.an9_12 / scs.Aban_n) an9_12_p,
		ab.an12_15,
		(ab.an12_15 / scs.Aban_n) an12_15_p,
		ab.an15_18,
		(ab.an15_18 / scs.Aban_n) an15_18_p,
		ab.an18_21,
		(ab.an18_21 / scs.Aban_n) an18_21_p,
		ab.an21_24,
		(ab.an21_24 / scs.Aban_n) an21_24_p,
		ab.an24_27,
		(ab.an24_27 / scs.Aban_n) an24_27_p,
		ab.an27_30,
		(ab.an27_30 / scs.Aban_n) an27_30_p,
		ab.an30_33,
		(ab.an30_33 / scs.Aban_n) an30_33_p,
		ab.an33_36,
		(ab.an33_36 / scs.Aban_n) an33_36_p,
		ab.an36_39,
		(ab.an36_39 / scs.Aban_n) an36_39_p,
		ab.an39_42,
		(ab.an39_42 / scs.Aban_n) an39_42_p,
		ab.an42_45,
		(ab.an42_45 / scs.Aban_n) an42_45_p,
		ab.an45_48,
		(ab.an45_48 / scs.Aban_n) an45_48_p,
		ab.an48_51,
		(ab.an48_51 / scs.Aban_n) an48_51_p,
		ab.an51_54,
		(ab.an51_54 / scs.Aban_n) an51_54_p,
		ab.an54_57,
		(ab.an54_57 / scs.Aban_n) an54_57_p,
		ab.an57_60,
		(ab.an57_60 / scs.Aban_n) an57_60_p,
		ab.an_gt_60,
		(ab.an_gt_60 / scs.Aban_n) an_gt_60_p,

		sca.AgentTalk_t, (sca.AgentTalk_t / sa.Login_t) AgentTalk_tdl, sca.AgentTalk_t_n, 
		sa.Acw_t, (sa.Acw_t / sa.Login_t) Acw_tdl,
		sa.NotReady_t, (sa.NotReady_t / sa.Login_t) NotReady_tdl,
		sa.Login_t,
		(isnull(sca.AgentTalk_t, 0) + isnull(sca.Ring_t, 0)) / sa.Login_t Efficiency
	from
	(
		select RecDT, 
			case when (sum(vxi_def.dbo.ms_to_int_sec(Login_t)) / 3600.0) != 0 then 
				(sum(vxi_def.dbo.ms_to_int_sec(Login_t)) / 3600.0)
			end Login_t,
			(sum(vxi_def.dbo.ms_to_int_sec(isnull(NotReady00_t, 0) + isnull(NotReady01_t, 0) + isnull(NotReady02_t, 0) 
										 + isnull(NotReady03_t, 0) + isnull(NotReady04_t, 0) + isnull(NotReady05_t, 0) 
										 + isnull(NotReady06_t, 0) + isnull(NotReady07_t, 0) + isnull(NotReady08_t, 0) 
										 + isnull(NotReady09_t, 0))) / 3600.0) NotReady_t,
			(sum(vxi_def.dbo.ms_to_int_sec(Acw_t)) / 3600.0) Acw_t
		from vxi_ucd..stat_agent
		where RecDT between @StatBegin and @StatEnd Group by RecDT
	) sa
	full join
	(
		select RecDT, 
			(sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) / 3600.0) AgentTalk_t,
			(sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) / 3600.0) Ring_t,
			case when sum(Talk_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(Talk_t)) / sum(Talk_n) end AgentTalk_t_n,
			sum(vxi_def.dbo.ms_to_int_sec(Aban_t)) AgentAban_t
		from vxi_ucd..stat_call_agent
		where RecDT between @StatBegin and @StatEnd Group by RecDT
	) sca
	on sa.RecDT = sca.RecDT
	full join
	(
		select RecDT, cast(case when sum(SkillIn_n) != 0 then sum(SkillIn_n) end as float) SkillIn_n,
			sum(Ans_n) Ans_n, sum(AnsLess_n) AnsLess_n,
			sum(AnsMore_n) AnsMore_n, 
			cast(case when sum(Aban_n) != 0 then sum(Aban_n) end as float) Aban_n, 
			sum(AbanAgent) AbanAgent, sum(AbanSkill) AbanSkill, 
			sum(AbanMore) AbanMore,
			case when sum(Ans_n) != 0 then sum(vxi_def.dbo.ms_to_int_sec(Ans_t)) / sum(Ans_n) end Ans_t_n,
			max(vxi_def.dbo.ms_to_int_sec(MaxAns_t)) Ans_t_max
		from vxi_ucd..stat_call_skill
		where RecDT between @StatBegin and @StatEnd group by RecDT
	) scs
	on sa.RecDT = scs.RecDT or sca.RecDT = scs.RecDT
	full join
	(
		select 
			RecDT, 
			sum(BeiJingToShangHai) BeiJingToShangHai, 
			sum(ShangHaiToBeiJing) ShangHaiToBeiJing 
		from 
		(
			select 
				vxi_ucd.dbo.time_to_bigint(u.StartTime, @SplitTm) RecDT, 
				case when len(c.Answer) = 4 and (c.Answer between '4000' and '4100') then 1 else 0 end BeiJingToShangHai,
				case when Route = '81005' then 1 else 0 end ShangHaiToBeiJing
			from (
				select UcdId, StartTime from vxi_ucd..Ucd where Starttime between @BeginTime and @EndTime
			) u 
			inner join vxi_ucd..UcdCall c on u.UcdId = c.Ucdid
			where (len(c.Trunk) > 0) and ((cast(c.Trunk as int) / 1000) between 2 and 3)
				and ( (len(c.Answer) = 4 and (c.Answer between '4000' and '4100')) or (Route = '81005')	)
		) ExtraData group by RecDT
	) ed 
	on sa.RecDT = ed.RecDT or sca.RecDT = ed.RecDT or scs.RecDT = ed.RecDT
	full join
	(
		select top 100 percent RecDT,
			sum(case when OnCallEnd - OnSkill between 0 and 3000 then 1 end) an0_3,
			sum(case when OnCallEnd - OnSkill between 3001 and 6000 then 1 end) an3_6,
			sum(case when OnCallEnd - OnSkill between 6001 and 9000 then 1 end) an6_9,
			sum(case when OnCallEnd - OnSkill between 9001 and 12000 then 1 end) an9_12,
			sum(case when OnCallEnd - OnSkill between 12001 and 15000 then 1 end) an12_15,
			sum(case when OnCallEnd - OnSkill between 15001 and 18000 then 1 end) an15_18,
			sum(case when OnCallEnd - OnSkill between 18001 and 21000 then 1 end) an18_21,
			sum(case when OnCallEnd - OnSkill between 21001 and 24000 then 1 end) an21_24,
			sum(case when OnCallEnd - OnSkill between 24001 and 27000 then 1 end) an24_27,
			sum(case when OnCallEnd - OnSkill between 27001 and 30000 then 1 end) an27_30,
			sum(case when OnCallEnd - OnSkill between 30001 and 33000 then 1 end) an30_33,
			sum(case when OnCallEnd - OnSkill between 33001 and 36000 then 1 end) an33_36,
			sum(case when OnCallEnd - OnSkill between 36001 and 39000 then 1 end) an36_39,
			sum(case when OnCallEnd - OnSkill between 39001 and 42000 then 1 end) an39_42,
			sum(case when OnCallEnd - OnSkill between 42001 and 45000 then 1 end) an42_45,
			sum(case when OnCallEnd - OnSkill between 45001 and 48000 then 1 end) an45_48,
			sum(case when OnCallEnd - OnSkill between 48001 and 51000 then 1 end) an48_51,
			sum(case when OnCallEnd - OnSkill between 51001 and 54000 then 1 end) an51_54,
			sum(case when OnCallEnd - OnSkill between 54001 and 57000 then 1 end) an54_57,
			sum(case when OnCallEnd - OnSkill between 57001 and 60000 then 1 end) an57_60,
			sum(case when OnCallEnd - OnSkill > 60000 then 1 end) an_gt_60
		from (
			select UcdID, vxi_ucd.dbo.time_to_bigint(StartTime, @SplitTm) RecDT
				from vxi_ucd..Ucd where (Starttime between @BeginTime and @EndTime)
		) u join vxi_ucd..UcdCall c on u.UcdID = c.UcdID where bEstb = 0 and len(Skill) > 0
		group by RecDT order by 1
	) ab
	on sa.RecDT = ab.RecDT or sca.RecDT = ab.RecDT or scs.RecDT = ab.RecDT or ed.RecDT = ab.RecDT
	Order by 1	-- RecDT

	return 0

END











GO
/****** Object:  StoredProcedure [dbo].[sp_report_9]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_report_9]
	-- Add the parameters for the stored procedure here
	@BeginTime datetime,			-- 需要统计的起始时间 
	@EndTime datetime,				-- 需要统计的结束时间
	@SplitTm int = 30				-- 统计间隔时长, 单位：分钟
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	if ( (@BeginTime is null) or (@EndTime is null) ) begin
		raiserror('@BeginTime和@EndTime不能为null', 1, 1)
		return 1
	end

	declare	@StatBegin bigint,				-- 起始日期时间值数字表示yyyyMMddhhmm
			@StatEnd bigint					-- 结束日期时间值数字表示yyyyMMddhhmm

	select  @StatBegin = vxi_ucd.dbo.time_to_bigint(@BeginTime, @SplitTm),
			@StatEnd = vxi_ucd.dbo.time_to_bigint(@EndTime, @SplitTm)

	select Agent, (sum(vxi_def.dbo.ms_to_int_sec(Login_t)) / 3600.0) Login_t from vxi_ucd..stat_agent
	where RecDT between @StatBegin and @StatEnd Group by Agent
	order by Agent

	return 0

END










GO
/****** Object:  StoredProcedure [dbo].[sp_sch_records]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		fei yu
-- Create date: 03/24/2008
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_sch_records]
	@recordid bigint = 0,
	@num_begin int = 0,
	@num_end   int = 0,
	@taskid int = 0,
	@groupid int = 0,
	@prjid int = 0,
	@calltype varchar(20) = '',
	@UcdId bigint = 0,
	@Calling varchar(20) = '',
	@Called varchar(20) = '',
	@Answer varchar(20) = '',
	@StartTime_begin datetime = null,
	@StartTime_end datetime = null,
	@agent varchar(20) = '',
	@skill  varchar(20) = '',
	@Extension  varchar(20) = '',
	@ItemNo tinyint = 0,
	@Value varchar(50) = '',
	@label varchar(2000) = '',
	@custom varchar(20) = ''
AS
BEGIN
	declare @sch varchar(2000), @Item varchar(20),@order_str varchar(200)
	set @Calling	= ltrim(rtrim(isnull(@Calling, ''))) 
	set @Extension	= ltrim(rtrim(isnull(@Extension, ''))) 
	set @Called	= ltrim(rtrim(isnull(@Called, ''))) 
	set @Answer	= ltrim(rtrim(isnull(@Answer, ''))) 
	set @agent	= ltrim(rtrim(isnull(@agent, ''))) 
	set @skill = ltrim(rtrim(isnull(@skill, '')))
	set @label	= ltrim(rtrim(isnull(@label, ''))) 
	set @custom	= ltrim(rtrim(isnull(@custom, ''))) 
	set @Value = ltrim(rtrim(isnull(@Value, '')))
	set @order_str = ' order by m.recordid desc'

set @sch = 'select distinct m.recordid, isnull(c.Calling, m.Calling) Calling, isnull(c.Called, m.Called) Called, isnull(c.Answer, m.Answer) Answer, m.StartTime, m.seconds, m.Extension, m.Skill, m.Agent as master, a.AgentName, m.UcdId,e.item01, e.item02, e.item03,  c.type calltype '
  + ' from vxi_rec..records m left join vxi_ucd..ucdcall c on m.ucdid = c.ucdid and m.callid = c.callid'
  + ' left join vxi_rec..taskrec r on r.recordid = m.recordid '
  + ' left join vxi_sys..Agent a on a.agent = m.agent ' 
  + ' left join vxi_rec..grouprec g on g.recordid = m.recordid'
  + ' left join vxi_rec..RecExts e on e.recordid = m.recordid  and e.Enabled = 1'
  + ' where m.finsihed >= 1 and seconds > 1 ' 
	
	if (@label !='')  
		set @sch = @sch + ' and m.recordid in (select distinct recordid from vxi_label where label like''%' + rtrim(ltrim(@label)) + '%'')' 
	if (isnull(@calltype, '') != '') begin
		set @sch = @sch + ' and c.type = ' + convert(varchar, @calltype)	
	end
    else if (@custom !='')  begin
		set @sch = @sch + ' and ((c.type = 1 and isnull(c.Calling, m.Calling) like ''' + @custom + '%'') or (c.type = 2 and isnull(c.Called, m.Called) like ''' + @custom + '%''))' 
	end

	if @recordid != 0
		set @sch = @sch + ' and m.recordid = ' + convert(varchar, @recordid) 
	if @num_begin  != 0
		set @sch = @sch + ' and m.seconds > ' + convert(varchar, @num_begin )		
	if @num_end != 0
		set @sch = @sch + ' and m.seconds < ' + convert(varchar, @num_end)
	if @taskid!= 0
		set @sch = @sch + ' and r.taskid = ' + convert(varchar, @taskid)
	if @groupid != 0
		set @sch = @sch + ' and g.groupid = ' + convert(varchar, @groupid)
	if @prjid != 0
		set @sch = @sch + ' and m.prjid = ' + convert(varchar, @prjid)

	if @UcdId != 0
		set @sch = @sch + ' and m.UcdId = ' + convert(varchar, @UcdId)
	if @Calling != ''
		set @sch = @sch + ' and isnull(c.Calling, m.Calling) like ''' + @Calling + '%'''
	if @Called != ''
		set @sch = @sch + ' and isnull(c.Called, m.Called) like ''' + @Called + '%'''
	if @Answer != ''
		set @sch = @sch + ' and Answer = ''' + @Answer + ''''
	if @StartTime_begin is not null
		set @sch = @sch + ' and m.StartTime > ''' + convert(varchar(20), @StartTime_begin, 120) + ''''
	if @StartTime_end is not null
		set @sch = @sch + ' and m.StartTime < ''' + convert(varchar(20), @StartTime_end,120) + ''''

	if @agent != ''
		set @sch = @sch + ' and m.agent = ''' + @agent + ''''

	if @skill != ''
		set @sch = @sch + ' and m.skill = ''' + @skill + ''''

	if @Extension != ''
		set @sch = @sch + ' and m.Extension = ''' + @Extension + ''''

	if not (@ItemNo is null or @ItemNo = 0 or @ItemNo > 10 or @Value ='')  begin
		if @ItemNo = 10  begin
			select @Item = ' e.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item = ' e.Item0' + cast(@ItemNo as varchar(10))	 
		end
		set @Value =  @Value + '%'
		set @sch = @sch + ' and ' + @item + ' like '''+ @Value +''''
	end
	set @sch = @sch + @order_str
execute(@sch) 
END


GO
/****** Object:  StoredProcedure [dbo].[sp_tianping_syn_ucd]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[sp_tianping_syn_ucd]
	@time_begin datetime = null,
	@time_end datetime = null
AS
	if @time_begin is null	set @time_begin = str(year(getdate()) * 10000 + month(getdate()) * 100 + day(getdate()))
	if @time_end   is null 	set @time_end = getdate()

	select u.ucdid, u.calling caller, u.called, u.extension ext, u.agent, 
			dateadd(ms, isnull(min(i.establish), 0), u.starttime) start_time, 
			(isnull(max(i.leave), 0) - isnull(min(i.establish), 0)) timelen
		into #TempTP
		from vxi_ucd..ucd u inner join vxi_ucd..ucditem i on u.ucdid = i.ucdid
		where u.starttime between @time_begin and @time_end 
			and isnull(i.agent, '') != ''
			and u.timelen > 0
			and u.ucdid not in (select ucdid from tianping_ucd t where t.starttime between @time_begin and @time_end)
		group by u.ucdid, u.calling, u.called, u.extension, u.agent, u.starttime
	
	insert into tianping_ucd
		select * from #TempTP

	insert into tianping_buf
		select * from #TempTP

	drop table #TempTP

	-- 数据库 vxi_crm 与 tp 在不同的服务器时，打开该语句，否则关闭
	-- insert into [192.168.0.37].[tp].[dbo].tp_ucd 
	--	select * from tianping_buf

	-- 数据库 vxi_crm 与 tp 在相同的服务器时，打开该语句，否则关闭
	-- insert into tp..tp_ucd 
	-- 	select * from tianping_buf
	
	if @@error = 0 begin
		truncate table tianping_buf
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_sch_records]
	-- Add the parameters for the stored procedure here
	@recordid bigint = 0,
	@seconds_from int = 0,
	@seconds_to   int = 0,
	@taskid int = 0,
	@groupid int = 0,
	@prjid int = 0,
	@calltype varchar(20) = '',
	@UcdId bigint = 0,
	@Calling varchar(20) = '',
	@Called varchar(20) = '',
	@Answer varchar(20) = '',
	@StartTime_begin datetime = null,
	@StartTime_end datetime = null,
	@agent varchar(20) = '',
	@skill  varchar(20) = '',
	@Extension  varchar(20) = '',
	@ItemNo tinyint = 0,
	@Value varchar(50) = ''
AS
BEGIN
	EXEC vxi_crm..sp_sch_records
			@recordid,
			@seconds_from,
			@seconds_to,
			@taskid,
			@groupid,
			@prjid,
			@calltype,
			@UcdId,
			@Calling,
			@Called,
			@Answer,
			@StartTime_begin,
			@StartTime_end,
			@agent,
			@skill,
			@Extension,
			@ItemNo,
			@Value
END




GO
/****** Object:  UserDefinedFunction [dbo].[func_chengdu_agent_sn]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  FUNCTION [dbo].[func_chengdu_agent_sn] ( @agent varchar(50) )
RETURNS varchar(4) AS
BEGIN 
	select @agent = rtrim(isnull(@agent, ''))
	return case @agent when '' then space(4) else 'C' + right(@agent, 3) end
END

GO
/****** Object:  UserDefinedFunction [dbo].[func_get_date_str_part]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[func_get_date_str_part]
(
	-- Add the parameters for the function here
	@yyyymmddhhmm bigint
)
RETURNS varchar(20)
AS
BEGIN
	-- Declare the return variable here
	-- 200705231300 to '2007-05-23'
	
	declare @strFormat varchar(20)
	set @strFormat = left(cast(@yyyymmddhhmm as varchar(20)), 8)
	 
	return left(@strFormat, 4) + '-' 
		 + substring(@strFormat, 5, 2) + '-'
		 + right(@strFormat, 2)
END


GO
/****** Object:  UserDefinedFunction [dbo].[func_get_time_str_part]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
create FUNCTION [dbo].[func_get_time_str_part]
(
	-- Add the parameters for the function here
	@yyyymmddhhmm	bigint,
	@interval		int
)
RETURNS varchar(20)
AS
BEGIN
	-- Declare the return variable here
	-- 200705231300 to '13:00-13:30'
	
	declare @hh_begin int, @mm_begin int, @hh_end int, @mm_end int

	select @yyyymmddhhmm = @yyyymmddhhmm % 10000,
		   @hh_begin = @yyyymmddhhmm / 100,
		   @mm_begin = @yyyymmddhhmm % 100,
		   @mm_end = @mm_begin + @interval 
	
	if @mm_end >= 60 begin
		select @mm_end = @mm_end - 60, @hh_end = @hh_begin + 1
		if @hh_end >= 24 set @hh_end = 0
	end
	else begin
		select @hh_end = @hh_begin
	end
	
	return right('0' + cast(@hh_begin as varchar(2)), 2)
		 + ':'
		 + right('0' + cast(@mm_begin as varchar(2)), 2)
		 + '-'
		 + right('0' + cast(@hh_end as varchar(2)), 2)
		 + ':'
		 + right('0' + cast(@mm_end as varchar(2)), 2)
END


GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_int_sec]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



--print dbo.ms_to_int_sec(1500)

create         FUNCTION [dbo].[ms_to_int_sec](@ms int)
RETURNS int AS  
BEGIN 
	return (@ms + 500) / 1000
END
GO
/****** Object:  UserDefinedFunction [dbo].[ms_to_time]    Script Date: 2016/9/5 13:30:58 ******/
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
/****** Object:  Table [dbo].[chengdu_AgentSN]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[chengdu_AgentSN](
	[Agent] [char](20) NOT NULL,
	[SN] [char](4) NOT NULL,
 CONSTRAINT [PK_chengdu_AgentSN] PRIMARY KEY CLUSTERED 
(
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [IX_chengdu_AgentSN] UNIQUE NONCLUSTERED 
(
	[SN] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[chengdu_UcdCallLog]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[chengdu_UcdCallLog](
	[UcdId] [bigint] NOT NULL,
	[StartTime] [datetime] NULL,
	[UcdHour] [tinyint] NULL,
	[CID] [varchar](4) NULL,
	[DATE] [int] NOT NULL,
	[ASSN] [int] NOT NULL,
	[BT] [datetime] NULL,
	[PN] [char](23) NULL,
	[SF] [varchar](2) NULL,
	[WBT] [datetime] NULL,
	[WET] [datetime] NULL,
	[SN] [varchar](4) NULL,
	[MBT] [datetime] NULL,
	[MR] [varchar](4) NULL,
	[MET] [datetime] NULL,
	[IBT] [datetime] NULL,
	[IR] [varchar](4) NULL,
	[IET] [datetime] NULL,
	[TPMBT] [datetime] NULL,
	[TPMET] [datetime] NULL,
	[RT] [datetime] NULL,
	[ASN] [varchar](4) NULL,
	[ET] [datetime] NULL,
 CONSTRAINT [PK_chengdu_UcdCallLog] PRIMARY KEY NONCLUSTERED 
(
	[UcdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CMS_Skill_RTData]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CMS_Skill_RTData](
	[UpdateTime] [datetime] NOT NULL,
	[SkillNo] [varchar](16) NULL,
	[SkillName] [varchar](50) NOT NULL,
	[CallsInQueue] [int] NULL,
	[AgentsLoggedIn] [int] NULL,
	[AgentsReadyForCalls] [int] NULL,
	[AgentsOnCall] [int] NULL,
	[AgentsNotReadyForCalls] [int] NULL,
	[CurrentLongestQueueTime] [int] NULL,
	[LongestQueueTime] [int] NULL,
 CONSTRAINT [PK_CMS_Skill_RTData_1] PRIMARY KEY CLUSTERED 
(
	[SkillName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[sample]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[sample](
	[orderid] [int] NOT NULL,
	[title] [varchar](50) NULL,
	[client] [varchar](20) NULL,
	[address] [varchar](50) NULL,
	[phone] [varchar](50) NULL,
	[orderdate] [datetime] NULL,
	[tempdate] [int] NULL,
	[temptime] [int] NULL,
	[price] [float] NULL,
	[summary] [text] NULL,
	[signal] [varchar](20) NULL,
	[Signdate] [int] NULL,
	[acked] [bit] NULL,
	[enabled] [bit] NULL,
 CONSTRAINT [PK_sample] PRIMARY KEY CLUSTERED 
(
	[orderid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tianping_buf]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tianping_buf](
	[UcdId] [bigint] NOT NULL,
	[Caller] [varchar](20) NULL,
	[Called] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[Ext] [varchar](20) NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
 CONSTRAINT [PK_tianping_buf] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[tianping_ucd]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[tianping_ucd](
	[UcdId] [bigint] NOT NULL,
	[Caller] [varchar](20) NULL,
	[Called] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[Ext] [varchar](20) NULL,
	[StartTime] [datetime] NULL,
	[TimeLen] [int] NULL,
 CONSTRAINT [PK_tianping_ucd] PRIMARY KEY CLUSTERED 
(
	[UcdId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VipUsers]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VipUsers](
	[PhoneNo] [varchar](100) NOT NULL,
	[UserName] [varchar](30) NULL,
	[Level] [smallint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_VipUsers] PRIMARY KEY CLUSTERED 
(
	[PhoneNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[chengdu_UcdCallLog_view]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE VIEW [dbo].[chengdu_UcdCallLog_view]
AS
SELECT UcdId, StartTime, UcdHour, CID, [DATE] AS DateInt, 
      vxi_def.dbo.datetime_to_datestr(StartTime) AS [DATE], ASSN, 
      vxi_def.dbo.datetime_to_timestr(BT) AS BT, PN, SF, 
      vxi_def.dbo.datetime_to_timestr(WBT) AS WBT, 
      vxi_def.dbo.datetime_to_timestr(WET) AS WET, SN, 
      vxi_def.dbo.datetime_to_timestr(MBT) AS MBT, MR, 
      vxi_def.dbo.datetime_to_timestr(MET) AS MET, vxi_def.dbo.datetime_to_timestr(IBT) 
      AS IBT, IR, vxi_def.dbo.datetime_to_timestr(IET) AS IET, 
      vxi_def.dbo.datetime_to_timestr(TPMBT) AS TPMBT, 
      vxi_def.dbo.datetime_to_timestr(TPMET) AS TPMET, 
      vxi_def.dbo.datetime_to_timestr(RT) AS RT, ASN, vxi_def.dbo.datetime_to_timestr(ET) 
      AS ET
FROM dbo.chengdu_UcdCallLog



GO
/****** Object:  View [dbo].[stat_agent]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[stat_agent]
AS
SELECT     *
FROM  vxi_ucd.dbo.stat_agent

GO
/****** Object:  View [dbo].[stat_call_agent]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[stat_call_agent]
AS
SELECT     *
FROM	vxi_ucd.dbo.stat_call_agent

GO
/****** Object:  View [dbo].[stat_call_skill]    Script Date: 2016/9/5 13:30:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[stat_call_skill]
AS
SELECT     *
FROM	vxi_ucd.dbo.stat_call_skill

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
         Configuration = "(H (1[50] 2[25] 3) )"
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
         Configuration = "(H (2[66] 3) )"
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
      ActivePaneConfig = 5
   End
   Begin DiagramPane = 
      PaneHidden = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "stat_agent_1"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 190
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
      Begin ColumnWidths = 56
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
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
      PaneHidden = 
      ' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_agent'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane2', @value=N'Begin ColumnWidths = 11
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_agent'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=2 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_agent'
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
         Begin Table = "stat_call_agent (vxi_ucd.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 193
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_call_agent'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_call_agent'
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
         Begin Table = "stat_call_skill (vxi_ucd.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 193
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_call_skill'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'stat_call_skill'
GO
