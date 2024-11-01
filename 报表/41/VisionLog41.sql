USE [master]
/****** Object:  Database [VisionLog41]    Script Date: 2016/12/13 10:09:13 ******/
CREATE DATABASE [VisionLog41]
GO

ALTER DATABASE [VisionLog41] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [VisionLog41] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [VisionLog41] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [VisionLog41] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [VisionLog41] SET ARITHABORT OFF 
GO
ALTER DATABASE [VisionLog41] SET AUTO_CLOSE OFF 
GO
ALTER DATABASE [VisionLog41] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [VisionLog41] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [VisionLog41] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [VisionLog41] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [VisionLog41] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [VisionLog41] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [VisionLog41] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [VisionLog41] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [VisionLog41] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [VisionLog41] SET  DISABLE_BROKER 
GO
ALTER DATABASE [VisionLog41] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [VisionLog41] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [VisionLog41] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [VisionLog41] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [VisionLog41] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [VisionLog41] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [VisionLog41] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [VisionLog41] SET  MULTI_USER 
GO
ALTER DATABASE [VisionLog41] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [VisionLog41] SET DB_CHAINING OFF 
GO

USE [VisionLog41]
GO
/****** Object:  User [cdc]    Script Date: 2016/12/13 10:09:14 ******/
CREATE USER [cdc] WITHOUT LOGIN WITH DEFAULT_SCHEMA=[cdc]
GO

/****** Object:  DatabaseRole [cdc_admin]    Script Date: 2016/12/13 10:09:14 ******/
CREATE ROLE [cdc_admin]
GO
/****** Object:  DatabaseRole [ba]    Script Date: 2016/12/13 10:09:14 ******/
CREATE ROLE [ba]
GO

/****** Object:  Schema [ba]    Script Date: 2016/12/13 10:09:14 ******/
CREATE SCHEMA [ba]
GO
/****** Object:  Schema [cdc]    Script Date: 2016/12/13 10:09:14 ******/
CREATE SCHEMA [cdc]
GO
/****** Object:  Schema [hist]    Script Date: 2016/12/13 10:09:14 ******/
CREATE SCHEMA [hist]
GO

/****** Object:  StoredProcedure [dbo].[pi_usp_agent_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ======================================================================================================
-- Author:		Robin Feng
-- Create date: 2010.08.02
-- Description: provide agentid delete interface for other system.
-- Example: exec pi_usp_agent_delete @AgentID='70001'
-- ======================================================================================================

CREATE PROCEDURE [dbo].[pi_usp_agent_delete]  
	@AgentID varchar(20)  			-- agent id (define in avaya pbx)	
AS  
	if isnull(@AgentID, '') != '' begin
		set @AgentID = rtrim(ltrim(@AgentID))
		delete GroupAgent where AgentId = @AgentID
		delete Agent where AgentId = @AgentID		
		delete agentgroup where groupid in (select a.groupid from agentgroup a where (select count(g.groupid) from groupagent g where g.groupid=a.groupid)=0)
	end
	-- select case @error when 0 then 0 else 1 end flag, 'result' result
	return @@error


GO
/****** Object:  StoredProcedure [dbo].[pi_usp_agent_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- ======================================================================================================
-- Author:		Robin Feng
-- Create date: 2010.07.16
-- Description: provide agentid insert interface for other system.
-- Example: exec pi_usp_agent_insert @AgentID='70001',@AgentName='robin',@Enabled=1, @GroupName='wueng',
--											@GroupDesc='wu english project'
-- ======================================================================================================

CREATE PROCEDURE [dbo].[pi_usp_agent_insert]  
	@AgentID varchar(20),  			-- agent id (define in avaya pbx)
	@AgentName varchar(50),			-- agent name (user self define)
	@Enabled bit = 1,				-- (1)enabled/(0)disabled
	@GroupName varchar(50),			-- user self define group name(is not skill or acd)
	@GroupDesc varchar(300) = ''	-- agent group description
AS  
	declare @groupid int, @maxid int
	if isnull(@AgentID, '') != '' begin
		set @AgentID = rtrim(ltrim(@AgentID))
		if (select count(*) from Agent where AgentID = @AgentID) = 0 begin  
			insert into Agent (AgentID, AgentName, Enabled)  
						values (@AgentID, @AgentName, @Enabled) 
			if isnull(@GroupName, '') != '' begin
				if (select count(*) from AgentGroup where GroupName = @GroupName) = 0 begin
					select @maxid = ISNULL(max(groupid), 0) + 1 from agentgroup
					insert into AgentGroup(GroupId, GroupName, Description, Enabled)
								values(@maxid, @GroupName, @GroupDesc, 1)
					set @groupid = @maxid
				end 
				else begin
					select @groupid = GroupId from AgentGroup where GroupName = @GroupName
				end
				insert into GroupAgent(GroupId, AgentId) values(@groupid, @AgentID)
			end		 
		end
	end
	-- select case @error when 0 then 0 else 1 end flag, 'result' result
	return @@error

GO
/****** Object:  StoredProcedure [dbo].[pi_usp_agent_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- ======================================================================================================
-- Author:		Robin Feng
-- Create date: 2010.07.16
-- Description: provide agentid insert interface for other system.
-- Example: exec pi_usp_agent_insert @AgentID='70001',@AgentName='robin',@Enabled=1, @GroupName='wueng',
--											@GroupDesc='wu english project'
-- ======================================================================================================

CREATE PROCEDURE [dbo].[pi_usp_agent_update]  
	@AgentID varchar(20),  			-- agent id (define in avaya pbx)	
	@GroupName varchar(50)			-- user self define group name(is not skill or acd)	
AS  
	declare @groupid int, @maxid int
	if isnull(@AgentID, '') != '' begin
		set @AgentID = rtrim(ltrim(@AgentID))		
		if (select count(*) from Agent where AgentID = @AgentID) > 0 begin			
			if isnull(@GroupName, '') != '' begin
				delete GroupAgent where AgentId = @AgentID				
				if (select count(*) from AgentGroup where GroupName = @GroupName) = 0 begin
					select @maxid = ISNULL(max(groupid), 0) + 1 from agentgroup
					insert into AgentGroup(GroupId, GroupName, Description, Enabled)
								values(@maxid, @GroupName, '', 1)
					set @groupid = @maxid
				end 
				else begin
					select @groupid = GroupId from AgentGroup where GroupName = @GroupName
				end
				insert into GroupAgent(GroupId, AgentId) values(@groupid, @AgentID)
			end		 
		end
	end
	-- select case @error when 0 then 0 else 1 end flag, 'result' result
	return @@error


GO
/****** Object:  StoredProcedure [dbo].[sp_get_projects]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create procedure [dbo].[sp_get_projects]

@currentDate varchar(10)=1

as
select projid id,projName projectName,description description from project
where enabled=1


GO
/****** Object:  StoredProcedure [dbo].[stat_daily]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[stat_daily]
  @date int = 0
AS

if @date = 0 begin
  declare @today datetime
  set @today = Getdate()
  set @date = DATEPART(yy, @today) * 10000 + DATEPART(mm, @today) * 100 + DATEPART(dd, @today)
end

select channel extension, 'in' in_out,  Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
    from records where finished > 0 and seconds > 5 and outbound = 0 and startdate = @date group by channel
union select  channel extension, 'out' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
    from records where finished > 0 and seconds > 5 and outbound = 1 and startdate = @date group by channel
union select  channel extension, 'total' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
    from records where finished > 0 and seconds > 5 and startdate = @date group by channel
order by 1, 2

select 'in' in_out,  Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
    from records where finished > 0 and seconds > 5 and outbound = 0 and startdate = @date
union select 'out' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
    from records where finished > 0 and seconds > 5 and outbound = 1 and startdate = @date
union select 'total' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
    from records where finished > 0 and seconds > 5 and startdate = @date


GO
/****** Object:  StoredProcedure [dbo].[stat_range]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[stat_range]
  @timefrom datetime = '19990101',
  @timeto datetime = '20790101'
AS

if @timefrom = '19990101'  and @timeto = '20790101' begin
  declare @date datetime
  if @date = 0 begin
    declare @today datetime
    set @today = Getdate()
    set @date = DATEPART(yy, @today) * 10000 + DATEPART(mm, @today) * 100 + DATEPART(dd, @today)
  end

  select channel extension, 'in' in_out,  Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 0 and startdate = @date group by channel
  union select  channel extension, 'out' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 1 and startdate = @date group by channel
  union select  channel extension, 'total' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and startdate = @date group by channel
  order by 1, 2

  select 'in' in_out,  Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 0 and startdate = @date
  union select 'out' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 1 and startdate = @date
  union select 'total' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and startdate = @date
end
else begin
  select channel extension, 'in' in_out,  Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 0 and starttime between @timefrom and @timeto group by channel
  union select  channel extension, 'out' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 1 and starttime between @timefrom and @timeto group by channel
  union select  channel extension, 'total' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and starttime between @timefrom and @timeto group by channel
  order by 1, 2

  select 'in' in_out,  Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 0 and isnull(starttime, '19990101') between @timefrom and @timeto
  union select 'out' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and outbound = 1 and isnull(starttime, '19990101') between @timefrom and @timeto
  union select 'total' in_out, Count(*) total_calls, Sum(Seconds) total_time_len, Avg(Seconds) time_average  
      from records where finished > 0 and seconds > 5 and isnull(starttime, '19990101') between @timefrom and @timeto
end


GO
/****** Object:  StoredProcedure [dbo].[usp_acd_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_acd_delete]  
	@Acd varchar(20)  
AS  
	if @Acd is null return  
	set @Acd = ltrim(rtrim(@Acd))  
	delete Acd  from Acd where Acd = @Acd  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_acd_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_acd_insert]  
	@Acd varchar(20),  
	@ManagerAddress varchar(20) = null,  
	@Description varchar(500) = null  
AS  
	if @Acd is null return  
	set @Acd  = ltrim(rtrim(@Acd))  
	if @ManagerAddress is not null set @ManagerAddress = ltrim(rtrim(@ManagerAddress))  
	if (select count(*) from Acd where Acd = @Acd) = 0 begin  
		insert into Acd (Acd, ManagerAddress, Description) values (@Acd, @ManagerAddress, @Description)  
		select 1 'result' 
	end  
	else begin  
		select 0 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_acd_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_acd_update]  
	@Acd varchar(20),  
	@ManagerAddress varchar(20) = null,  
	@Description varchar(500) = null  
AS  
	if @Acd is null return  
	set @Acd  = ltrim(rtrim(@Acd))  
	if @ManagerAddress is not null set @ManagerAddress = ltrim(rtrim(@ManagerAddress))  
		update Acd  
			set ManagerAddress = isnull(@ManagerAddress, ManagerAddress),   
			Description    = isnull(@Description, Description)  
			where Acd = @Acd


GO
/****** Object:  StoredProcedure [dbo].[usp_address_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_address_delete]  
	@Address varchar(20) 
AS  
 	set @Address = rtrim(ltrim(isnull(@Address, '')));  
	if @Address != '' begin  
		delete groupaddress
			where Address = @Address  
			
		delete Address  
			where Address = @Address  
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_address_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_address_insert]  
	@Address varchar(20),  
	@Station varchar(50) = '',
	@MuteFlag int = 0
AS  
	if @Address is null return  
	set @Address = rtrim(ltrim(@Address));  
	if (select count(*) from Address where Address = @Address) = 0  
		insert into Address (Address, Station, MuteFlag ,Enabled) values (@Address, @Station, @MuteFlag, 1)  
	else  
		exec usp_address_update @Address, @Station





GO
/****** Object:  StoredProcedure [dbo].[usp_address_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[usp_address_update]  
	@Address varchar(20),  
	@Station varchar(20) = null,
	@MuteFlag int
AS  
	if (isnull(@Address,'') <> '') begin  
		update Address  set 
			Station = isnull(@Station, Station),
			MuteFlag = @MuteFlag  
		where Address = ltrim(rtrim(@Address))  
	end







GO
/****** Object:  StoredProcedure [dbo].[usp_addressgroup_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_addressgroup_delete]  
	@GroupID int = 0  
AS  
	  delete GroupAddress from GroupAddress where GroupID = @GroupID  
	  delete AddressGroup from AddressGroup where GroupID = @GroupID  
	  return


GO
/****** Object:  StoredProcedure [dbo].[usp_addressgroup_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_addressgroup_insert]  
	@GroupID int = 0,  
	@GroupName varchar(50),  
	@Description varchar(500),  
	@Enabled bit = 1  
AS  
	declare @newID int  
	if @GroupID = 0  
		set @GroupID = (select max(GroupID) from addressGroup) + 1 	 
	if @GroupID=null   
		set @GroupID=1  
	if (select count(*) from addressGroup where GroupName = @GroupName) = 0 begin  
		insert into addressGroup (GroupID, GroupName,Description)  
		values (@GroupID, @GroupName, @Description)  
		select 1 'result' 
	end  
	else begin  
		select 0 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_addressgroup_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_addressgroup_update]  
	@GroupID int = 0,  
	@GroupName varchar(50) = null,  
	@Description varchar(500) = null,  
	@Enabled bit = null  
AS  
	update addressGroup  
		set GroupName = isnull(@GroupName, GroupName),   
		Description  = isnull(@Description,Description),  
		Enabled    = isnull(@Enabled, Enabled)  
		where GroupID = @GroupID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_agent_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_agent_delete]  
	@AgentID varchar(20)  
AS  
	set @AgentID = ltrim(rtrim(@AgentID))  
	delete GroupAgent
		where AgentID = @AgentID  
		
	delete Agent  
		where AgentID = @AgentID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_agent_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_agent_insert]  
	@AgentID varchar(20),  
	@Acd varchar(20),  
	@AgentName varchar(50),  
	@Enabled bit = 1  
AS  
	if @AgentID is null return
	set @AgentID = rtrim(ltrim(@AgentID));
	if (select count(*) from Agent where AgentID = @AgentID) = 0 begin  
		insert into Agent (AgentID, Acd, AgentName, Enabled)  
		values (@AgentID, @Acd, @AgentName, @Enabled)  
		select 1, 'result' 
	end  
	else begin  
		select 0, 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_agent_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_agent_update]  
	@AgentID varchar(20),  
	@Acd varchar(20) = null,  
	@AgentName varchar(50) = null,  
	@Enabled bit = null  
AS  
	update Agent  
		set Acd = isnull(@Acd, Acd),   
		AgentName  = isnull(@AgentName, AgentName),  
		Enabled    = isnull(@Enabled, Enabled)  
	where AgentID = @AgentID


GO
/****** Object:  StoredProcedure [dbo].[usp_agentgroup_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_agentgroup_delete]  
	@GroupID int = 0  
AS  
	delete GroupAgent where GroupID = @GroupID  
	delete AgentGroup where GroupID = @GroupID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_agentgroup_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_agentgroup_insert]  
	@GroupID int = 0,  
	@GroupName varchar(50),  
	@Description varchar(500),  
	@Enabled bit = 1  
AS  
	declare @newID int  
	--if @GroupID = 0  
		--set @GroupID = (select max(GroupID) from AgentGroup) + 1  
	--if @GroupID=null   
	--	set @GroupID=1  
	if (select count(*) from AgentGroup where GroupName = @GroupName) = 0 begin  
		insert into AgentGroup (GroupName,Description)  
		values (@GroupName, @Description)  
		select 1 'result' 
	end  
	else begin  
		select 0 'result' 
	end



GO
/****** Object:  StoredProcedure [dbo].[usp_agentgroup_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_agentgroup_update]  
	@GroupID int = 0,  
	@GroupName varchar(50) = null,  
	@Description varchar(500) = null,  
	@Enabled bit = null  
AS  
	update AgentGroup set 
		GroupName = isnull(@GroupName, GroupName),   
		Description  = isnull(@Description,Description),  
		Enabled    = isnull(@Enabled, Enabled)  
	where GroupID = @GroupID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_API_AgentGroupRecTaskOperate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_API_AgentGroupRecTaskOperate]  
   @IN_Operate varchar(50)='',  -- Operate name : add/delete         
   @IN_TaskName varchar(50)='',  -- Rec task name
   @IN_AgentGroup varchar(MAX)=''  -- Agentgroup name for operate

AS   
   DECLARE @M_TaskID INT
   DECLARE @M_Type INT
   DECLARE @M_Retrun INT
   DECLARE @M_Message char(200)
   DECLARE @M_GroupName varchar(50)
   DECLARE @M_GroupID INT
   DECLARE @M_LEN INT
   DECLARE @M_END INT
   DECLARE @M_START INT
   DECLARE @M_COUNT INT
   DECLARE @M_NOTFOUND VARCHAR(MAX)
BEGIN
    IF ((@IN_Operate='add') OR (@IN_Operate='delete'))
    BEGIN
        /***********************************************************************/
        /* Check rec task type                                                 */
        /***********************************************************************/
                   SELECT  TOP 1 @M_TaskID=ISNULL([TaskId],0),@M_Type=ISNULL([ObjType],0) 
                   FROM [Task] WHERE LTRIM(RTRIM([TaskName]))=LTRIM(RTRIM(@IN_TaskName))

             --  Only Support AgentGroup type res task 
                   IF ((@M_Type=2) AND (@M_TaskID>0))
                   BEGIN
                            SET @M_START=1
                            SET @M_LEN=LEN(@IN_AgentGroup)
                            SET @M_END=CHARINDEX('|',@IN_AgentGroup,1)

            /***********************************************************************/
            /* First found if all the agent group name is exist                    */
            /***********************************************************************/
                            SET @M_NOTFOUND=''
            SELECT @M_NOTFOUND AS NotFound INTO #TEMP_A

                            WHILE ((@M_END>@M_START) AND (@M_END<=@M_LEN))
                            BEGIN
                                     /***********************************************************************/
                                     /* Find Groupname one by one in @IN_AgentGroup, eg: ABC|XYZ|DTV_TASK|  */
                                     /***********************************************************************/                           
                                     SET @M_GroupName=SUBSTRING(@IN_AgentGroup,@M_START,(@M_END-@M_START))
                                     /***********************************************************************/
                                     /* Check Groupname if exist                                            */
                                     /***********************************************************************/
                                     SELECT @M_COUNT=COUNT(1) FROM [AgentGroup] WHERE [GroupName] = @M_GroupName

                                     IF (@M_COUNT=0)
                                     BEGIN
                    UPDATE #TEMP_A SET NotFound=NotFound + @M_GroupName+', '
                END
                      
                                     /***********************************************************************/
                                     /* Find Next Groupname                                                 */
                                     /***********************************************************************/                     
                                     SET @M_START=@M_END+1
                                     SET @M_END=CHARINDEX('|',@IN_AgentGroup,@M_START)
                            END

                            SELECT @M_NOTFOUND = NotFound FROM #TEMP_A

            IF (LEN(@M_NOTFOUND)>=1)
                            BEGIN
                /***********************************************************************/
                /* If found only one agent group name is not exist, return fail        */
                /***********************************************************************/                           
                                     SET @M_Retrun = 1
                                     SET @M_Message = 'Fail: AgentGroup= ' + @M_NOTFOUND + ' is not exist! '                                 
                            END
            ELSE
            BEGIN 
                /***********************************************************************/
                /* All agent group name is exist,  then contionue to add/delete        */
                /***********************************************************************/
                                     SET @M_START=1
                                     SET @M_LEN=LEN(@IN_AgentGroup)
                                     SET @M_END=CHARINDEX('|',@IN_AgentGroup,1)

                                     WHILE ((@M_END>@M_START) AND (@M_END<=@M_LEN))
                                     BEGIN
                                               /***********************************************************************/
                                               /* Find Groupname one by one in @IN_AgentGroup, eg: ABC|XYZ|DTV_TASK|  */
                                               /***********************************************************************/                                    
                                               SET @M_GroupName=SUBSTRING(@IN_AgentGroup,@M_START,(@M_END-@M_START))

                                         /***********************************************************************/
                                               /* Find GroupID by GroupName                                           */
                                               /***********************************************************************/ 
                                               SELECT Top 1 @M_GroupID=GroupID FROM [AgentGroup] WHERE [GroupName] = @M_GroupName 
                                               /***********************************************************************/
                                               /* Find if GroupID already exist in rec task                           */
                                               /***********************************************************************/ 
                                               SELECT @M_COUNT=COUNT(1) FROM [TaskItem] WHERE [TaskId]=@M_TaskID AND [AgentGroupId]=@M_GroupID

                                               IF (@IN_Operate='add')
                                               BEGIN
                                                        IF (@M_COUNT=0)
                                                        BEGIN
                                                                 INSERT INTO [TaskItem] ([TaskId],[Agentid],[AgentGroupId])
                                                                 VALUES(@M_TaskID,0,@M_GroupID)
                                                        END                    
                                               END
                                               IF(@IN_Operate='delete')
                                               BEGIN
                                                        IF (@M_COUNT>0)
                                                        BEGIN
                                                                 DELETE FROM [TaskItem]
                                                                 WHERE [TaskId]=@M_TaskID AND [AgentGroupId]=@M_GroupID
                                                        END
                                               END                             

                                               /***********************************************************************/
                                         /* Find Next Groupname                                                 */
                                         /***********************************************************************/       
                                               SET @M_START=@M_END+1
                                               SET @M_END=CHARINDEX('|',@IN_AgentGroup,@M_START)
                                     END
                                     SET @M_Retrun = 0
                            END
                   END 
                   ELSE
                   BEGIN
                            SET @M_Retrun = 1
                            SET @M_Message = 'Fail: Task= '+@IN_TaskName+' is not exist or is not AgentGroup type'  
                   END
         END 
         ELSE
         BEGIN
                   SET @M_Retrun = 1
                   SET @M_Message = 'Fail: Operacte command= '+ @IN_Operate +' is not correct, only support add/delete' 
         END

    SELECT  @M_Retrun r_return,@M_Message r_message INTO #Temp_R 
    SELECT TOP 1  r_return, r_message FROM #Temp_R 

END

GO
/****** Object:  StoredProcedure [dbo].[usp_API_AgentRecTaskOperate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_API_AgentRecTaskOperate]  
   @IN_Operate varchar(50)='',  -- Operate name : add/delete         
   @IN_TaskName varchar(50)='',  -- Rec task name
   @IN_Agent varchar(MAX)=''  -- Agent name for operate

AS   
   DECLARE @M_TaskID INT
   DECLARE @M_Type INT
   DECLARE @M_Retrun INT
   DECLARE @M_Message char(200)
   DECLARE @M_AgentID varchar(50)
   DECLARE @M_LEN INT
   DECLARE @M_END INT
   DECLARE @M_START INT
   DECLARE @M_COUNT INT
   DECLARE @M_NOTFOUND VARCHAR(MAX)
BEGIN
    IF ((@IN_Operate='add') OR (@IN_Operate='delete'))
    BEGIN
       /***********************************************************************/
        /* Check rec task type                                                 */
        /***********************************************************************/
                   SELECT  TOP 1 @M_TaskID=ISNULL([TaskId],0),@M_Type=ISNULL([ObjType],0) 
                   FROM [Task] WHERE LTRIM(RTRIM([TaskName]))=LTRIM(RTRIM(@IN_TaskName))

             --  Only Support Agent type res task 
                   IF ((@M_Type=1) AND (@M_TaskID>0))
                   BEGIN
                            SET @M_START=1
                            SET @M_LEN=LEN(@IN_Agent)
                            SET @M_END=CHARINDEX('|',@IN_Agent,1)

            /***********************************************************************/
            /* First found if all the agent id is exist                            */
            /***********************************************************************/
                            SET @M_NOTFOUND=''
            SELECT @M_NOTFOUND AS NotFound INTO #TEMP_A

                            WHILE ((@M_END>@M_START) AND (@M_END<=@M_LEN))
                            BEGIN
                                     /***********************************************************************/
                                     /* Find Agent ID one by one in @IN_Agent , eg: 1001|1002|1003|         */
                                     /***********************************************************************/                           
                                     SET @M_AgentID=SUBSTRING(@IN_Agent,@M_START,(@M_END-@M_START))
                                     /***********************************************************************/
                                     /* Check Agent ID if exist                                            */
                                     /***********************************************************************/
                                     SELECT @M_COUNT=COUNT(1) FROM [Agent] WHERE [AgentId] = @M_AgentID

                                     IF (@M_COUNT=0)
                                     BEGIN
                    UPDATE #TEMP_A SET NotFound=NotFound + @M_AgentID+', '
                END
                      
                                     /***********************************************************************/
                                     /* Find Next AgentID                                                 */
                                     /***********************************************************************/                     
                                     SET @M_START=@M_END+1
                                     SET @M_END=CHARINDEX('|',@IN_Agent,@M_START)
                            END

                            SELECT @M_NOTFOUND = NotFound FROM #TEMP_A

            IF (LEN(@M_NOTFOUND)>=1)
                            BEGIN
                /***********************************************************************/
                /* If found only one agent ID is not exist, return fail                */
                /***********************************************************************/                           
                                     SET @M_Retrun = 1
                                     SET @M_Message = 'Fail: Agent = ' + @M_NOTFOUND + ' is not exist! '                                  
                            END
            ELSE
            BEGIN 
                /***********************************************************************/
                /* All agent ID is exist,  then contionue to add/delete                */
                /***********************************************************************/
                                     SET @M_START=1
                                     SET @M_LEN=LEN(@IN_Agent)
                                     SET @M_END=CHARINDEX('|',@IN_Agent,1)

                                     WHILE ((@M_END>@M_START) AND (@M_END<=@M_LEN))
                                     BEGIN
                                               /***********************************************************************/
                                               /* Find Agent ID one by one in @IN_Agent , eg: 1001|1002|1003|         */
                                               /***********************************************************************/                                    
                                               SET @M_AgentID=SUBSTRING(@IN_Agent,@M_START,(@M_END-@M_START))

                                               /***********************************************************************/
                                               /* Find if  Agent ID already exist in rec task                           */
                                               /***********************************************************************/ 
                                               SELECT @M_COUNT=COUNT(1) FROM [TaskItem] WHERE [TaskId]=@M_TaskID AND [AgentId]=@M_AgentID

                                               IF (@IN_Operate='add')
                                               BEGIN
                                                        IF (@M_COUNT=0)
                                                        BEGIN
                                                                 INSERT INTO [TaskItem] ([TaskId],[Agentid],[AgentGroupId])
                                                                 VALUES(@M_TaskID,@M_AgentID,0)
                                                        END                    
                                               END
                                               IF(@IN_Operate='delete')
                                               BEGIN
                                                        IF (@M_COUNT>0)
                                                        BEGIN
                                                                 DELETE FROM [TaskItem]
                                                                 WHERE [TaskId]=@M_TaskID AND [Agentid]=@M_AgentID
                                                        END
                                               END                               
                                               /***********************************************************************/
                                         /* Find Next AgentID                                                   */
                                         /***********************************************************************/       
                                               SET @M_START=@M_END+1
                                               SET @M_END=CHARINDEX('|',@IN_Agent,@M_START)
                                     END
                                     SET @M_Retrun = 0
                            END
                   END 
                   ELSE
                   BEGIN
                            SET @M_Retrun = 1
                            SET @M_Message = 'Fail: Task= '+@IN_TaskName+' is not exist or is not Agent type'  
                   END
         END 
         ELSE
         BEGIN
                   SET @M_Retrun = 1
                   SET @M_Message = 'Fail: Operacte command= '+ @IN_Operate +' is not correct, only support add/delete' 
         END

    SELECT  @M_Retrun r_return,@M_Message r_message INTO #Temp_R 
    SELECT TOP 1  r_return, r_message FROM #Temp_R 

END

GO
/****** Object:  StoredProcedure [dbo].[usp_API_getAgentGroupRecTask]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_API_getAgentGroupRecTask]  
         @IN_TaskName varchar(50)=''  -- Rec task name

AS   
   DECLARE @M_Type INT
   DECLARE @M_TaskID INT
   DECLARE @M_COUNT INT
BEGIN
         SELECT  TOP 1 @M_TaskID=ISNULL([TaskId],0),@M_Type=ISNULL([ObjType],0) 
         FROM [Task] WHERE LTRIM(RTRIM([TaskName]))=LTRIM(RTRIM(@IN_TaskName))

--     Only Support AgentGroup type res task 
    IF (@M_Type=2) 
    BEGIN
        SELECT @M_COUNT=COUNT(1) FROM [GroupAgent] 
                   WHERE [GroupId] IN (SELECT [AgentGroupId] 
                                                                 FROM [TaskItem] 
                                                                 WHERE [TaskId]=@M_TaskID) 

                   SELECT 1 ID, Ltrim(Rtrim([GroupName])) [GroupName] INTO #TEMP_A
                   FROM [AgentGroup]
                   WHERE [GroupId] IN (SELECT [AgentGroupId] 
                                                                 FROM [TaskItem] 
                                                                 WHERE [TaskId]=@M_TaskID)

                   SELECT ID, [GroupName] = STUFF((SELECT '|' + [GroupName] FROM #TEMP_A t 
                               WHERE ID = #TEMP_A.ID FOR XML PATH('')) ,1 ,1 , '')
                   INTO #TEMP_B
                   FROM  #TEMP_A
                   GROUP BY ID 

                   SELECT TOP 1 @M_COUNT agentcount,[GroupName]+'|' agentgroup FROM #TEMP_B
    END 
    ELSE
    BEGIN
       SELECT 0 agentcount,'' agentgroup 
    END
     

END

GO
/****** Object:  StoredProcedure [dbo].[usp_API_getAgentRecTask]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_API_getAgentRecTask]  
         @IN_TaskName varchar(50)=''  -- Rec task name
AS   
   DECLARE @M_Type INT
   DECLARE @M_TaskID INT

BEGIN
         SELECT  TOP 1 @M_TaskID=ISNULL([TaskId],0),@M_Type=ISNULL([ObjType],0) 
         FROM [Task] WHERE LTRIM(RTRIM([TaskName]))=LTRIM(RTRIM(@IN_TaskName))

    -- Only Support Agent or AgentGroup type res task 
    IF (@M_Type=1)
    BEGIN
                   SELECT 1 ID, [AgentId] INTO #TEMP_A
                   FROM [Agent]
                   WHERE [AgentId] IN (SELECT [AgentId] 
                                                                 FROM [TaskItem] 
                                                                 WHERE [TaskId]=@M_TaskID)

                   SELECT ID, [AgentId] = STUFF((SELECT '|' + [AgentId] FROM #TEMP_A t 
                               WHERE ID = #TEMP_A.ID FOR XML PATH('')) ,1 ,1 , '')
                   INTO #TEMP_B
                   FROM  #TEMP_A
                   GROUP BY ID 

                   SELECT TOP 1 [AgentId]+'|' agent FROM #TEMP_B
    END 
         ELSE
    BEGIN
       SELECT '' agent 
    END 
END

GO
/****** Object:  StoredProcedure [dbo].[usp_API_GetRecTaskList]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_API_GetRecTaskList]  
AS   

BEGIN

         SELECT 1 ID,[TaskName] INTO #TEMP_A FROM  [Task] ORDER BY [TaskID]
        
    SELECT ID, [TaskName] = STUFF((SELECT '|' + [TaskName] FROM #TEMP_A t 
                      WHERE ID = #TEMP_A.ID FOR XML PATH('')) ,1 ,1 , '')
    INTO #TEMP_B
         FROM  #TEMP_A
         GROUP BY ID 

         SELECT TOP 1 [TaskName]+'|' Task FROM #TEMP_B


END

GO
/****** Object:  StoredProcedure [dbo].[usp_API_GetRecTaskType]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO



create PROCEDURE [dbo].[usp_API_GetRecTaskType]  
  @IN_TaskName varchar(50)=''  -- Rec task name
AS   
BEGIN
         SELECT  TOP 1  
                   CASE ISNULL([ObjType],0) 
                   WHEN 1 THEN  'Agent' 
                   WHEN 2 THEN  'AgentGroup' 
                   WHEN 3 THEN  'Ext' 
                   WHEN 4 THEN  'ExtGroup' 
                   WHEN 5 THEN  'VDN' 
                   WHEN 6 THEN  'UnKnowType' 
                   WHEN 7 THEN  'TrunkGroup' 
                   WHEN 8 THEN  'ACD' 
                   ELSE '' END  AS type 
         FROM [Task] WHERE LTRIM(RTRIM([TaskName]))=LTRIM(RTRIM(@IN_TaskName))
        



END



GO
/****** Object:  StoredProcedure [dbo].[usp_bill]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_bill]
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null
AS  
	declare @datenow varchar(8)
	set @datenow = str(datepart(year, getdate()),4) + right(str(100 + datepart(month, getdate()),3),2) + right(str(100+datepart(day, getdate()),3),2); 

	-- add for test
	execute('usp_bill_new ''' +  @GroupBy + ''', ''' + @DateTimeFrom  + ''', ''' + @DateTimeTo + ''', ''' + @ID + ''''); 
	
	--if left(@DateTimeFrom, 8) = left(@DateTimeTo, 8)  begin
	--	execute('usp_bill_new ''' +  @GroupBy + ''', ''' + @DateTimeFrom  + ''', ''' + @DateTimeTo + ''', ''' + @ID + ''''); 
	--end
	--else begin 
	--	if @datenow = left(@DateTimeFrom, 8) or @datenow = left(@DateTimeTo, 8)  begin
	--		execute('usp_bill_update ' + @datenow)  
	--	end
	--	set @DateTimeFrom =  left(@DateTimeFrom, 8)  
	--	set @DateTimeTo =  left(@DateTimeTo, 8)  
	--
	--	execute('usp_bill_pool ''' +  @GroupBy + ''', ''' + @DateTimeFrom + ''', ''' + @DateTimeTo + ''', ''' + @ID + '''');
	--end


GO
/****** Object:  StoredProcedure [dbo].[usp_bill_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_bill_insert]
	@BillId int,
	@RecordId int = 0,
	@Trunk int = 0,
	@Calling varchar(50) = '',
	@Called varchar(50) = '',
	@Acd int = 0,
	@Agent int = 0,
	@Extension int = 0,
	@Vdn int = 0,
	@StartTime datetime,
	@Seconds int,
	@Inbound bit = 0,
	@Outbound bit = 0,
	@Frl varchar(2) = ''
AS
	declare @StartDate varchar(8), @TrunkGroup smallint, @TrunkNumber smallint, @AgentGroup int
	declare @ProjID int, @ExtGroup int, @Charge money, @ChargeMe money
	declare @Flag bit, @sch varchar(500), @Channel int
	declare @ObjType varchar(10), @AssociateId int
	declare @CallType tinyint, @IsLong int 
	

	set @CallType = 0
	set @IsLong = 0

	--@Frl? 7, b then outbound

	if (@BillId=0) begin
		select @BillId = max(billid) from bill				
		set @BillId = isnull(@BillId, 0) + 1
	end

	set @StartDate = str(DATEPART(yy, @StartTime),4) + substring(str(100+DATEPART(mm, @StartTime),3),2,2) + substring(str(100+DATEPART(dd, @StartTime),3),2,2)  

	set @RecordId	= isnull(@RecordId, 0)
	set @Seconds	= isnull(@Seconds, 0)
	set @Trunk	= isnull(@Trunk, 0)
	set @Acd	= isnull(@Acd, 0)
	set @Agent 	= isnull(@Agent, 0)
	set @Extension = isnull(@Extension, 0)
	set @Vdn 	= isnull(@Vdn, 0)
	set @Calling	= ltrim(rtrim(isnull(@Calling, '')))
	set @Called	= ltrim(rtrim(isnull(@Called, '')))
	set @Inbound	= isnull(@Inbound, 0)
	set @Outbound	= isnull(@Outbound, 0)

	if (charindex('#', @Called)>0)
		set @Called = substring(@Called, 1, charindex('#', @Called)-1)
	
	-- Get Trunk
	if @Trunk != 0 begin
		set @TrunkGroup = @Trunk/1000
		set @TrunkNumber = @Trunk%1000
	end

	-- Get Flag: 
	set @Flag = 0
	if @Inbound =0 and @Outbound = 0 begin
		set @Flag = 1
                        if exists (select top 1 * from BillVDN where TrunkGroup=@TrunkGroup and @called like '%' + phone)
			set @Inbound = 1 
		--else
		--	set @Outbound = 1 
	end

	--Get Extension&Agent&Channel
	if @Calling != ''  begin
		select @ObjType = o.typename, @ProjID = o.projId, @AssociateId=o.associateId
		from (select top 1 t.typename, p.projId, p.associateId from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type 
			where (t.typename='ext' or t.typename='agent' or t.typename='channel') and @Calling like ltrim(rtrim([value])) and pr.enabled = 1) o

		if (@ObjType is not null) begin
			if @ObjType = 'ext' and @Extension = 0
				set @Extension = @Calling
			else if @ObjType = 'agent' and @Agent =0
				set @Agent = @Calling
			else if @ObjType = 'channel' 
				set @Channel = @Calling

			--if @ObjType != 'called' and @Flag=1
			if @Flag=1
				set @Outbound = 1
		end
	end
	if @Called != ''  begin
		set @ObjType = null
		select @ObjType = o.typename, @ProjID = o.projId, @AssociateId=o.associateId
		from ( select top 1 t.typename, p.projId, p.associateId from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type 
			where (t.typename='called' and @Called like '%' + ltrim(rtrim([value]))) 
				or ((t.typename='ext' or t.typename='agent' or t.typename='channel') and @Called like ltrim(rtrim([value]))) 
				and pr.enabled = 1) o
		
		if (@ObjType is not null) begin
			if @ObjType = 'ext' and @Extension = 0
				set @Extension = @Called
			else if @ObjType = 'agent' and @Agent =0
				set @Agent = @Called
			else if @ObjType = 'channel' 
				set @Channel = @Called
			else if @ObjType = 'called' 
				set @Inbound = 1

			--if  @ObjType != 'called' and @Flag=1
			if @Flag=1
				set @Inbound = 1 
		end
	end

	set @Agent = isnull(@Agent, 0)
	set @Extension = isnull(@Extension, 0)
	set @Channel = isnull(@Channel, 0)

	/*
	if @Agent = 0 begin
		if @Calling!='' and exists (select top 1 * from agent where convert(varchar, agentid) = @Calling)
			set @Agent = @Calling
		else if @Called!='' and exists (select top 1 * from agent where convert(varchar, agentid) = @Called)
			set @Agent = @Called
	end
	if @Extension = 0 begin
		if @Calling!='' and exists (select top 1 * from address where convert(varchar, address) = @Calling)
			set @Extension = @Calling
		else if @Called!='' and exists (select top 1 * from address where convert(varchar, address) = @Called)
			set @Extension = @Called


	end
	*/

	-- Get ProjID 
	--if @ProjID is null
	set @ProjID = dbo.GetProject(@TrunkGroup, @Acd, @Agent, @Extension, @Channel, @Called, @VDN, @StartTime)

	-- Get @AgentGroup
	if @StartTime is not null and @Agent != 0
		select top 1 @AgentGroup = GroupId
		from GroupAgent g
		where  ((g.TimeType=0)  
			or (g.TimeType=1 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between g.timefrom and g.timeto)  
			or (g.TimeType=2 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between g.timefrom and g.timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&g.weeks!=0) )) 
			and agentid = @Agent
	set @AgentGroup = isnull(@AgentGroup, 0)

	-- Get ExtGroup
	if @Extension != 0
		select top 1 @ExtGroup = GroupId from GroupAddress where address = @Extension
	set @ExtGroup = isnull(@ExtGroup, 0)	

	-- Get Charge 
	-- AT&T not bill
	if (@Inbound=0 and @Outbound =0) begin
		if (len(@Called) >5)
			set @Outbound = 1
	end

	-- if @Outbound = 1 and @ProjID!=9 begin
	if @Outbound = 1  begin

		if @TrunkGroup = 1 or @TrunkGroup = 3 or @TrunkGroup = 5 begin
			set @Charge = dbo.PhoneChargeUSA(@Seconds)
			set @ChargeMe =@Charge
			set @IsLong = 1

			------------  特殊处理 --------------
			--DNP
			if @ProjID = 42
				set @ProjID = 48

			--CISCO
			if @ProjID = 47 
				set @ProjID = 50
			-------------------------------------------
			
			if len(@called) < 10 begin
				set @IsLong = 0
				set @Charge = 0
				set @ChargeMe = 0
			end

		end
		else begin

			----WU D2B	080521---
			if @Called like '28%' and @ProjID=78
				set @ProjID=94

			set @IsLong = dbo.IsLongPhone(@called)
			set @Charge = dbo.PhoneCharge(@Called, @Seconds)
			set @ChargeMe = dbo.PhoneChargeMe(@Called, @Seconds)
		end
	end

	set @Charge = isnull(@Charge, 0)
	set @ChargeMe = isnull(@ChargeMe, 0)

	-- ?
	if @Channel !=0 and @Extension = 0
		set @Extension = @Channel

	--if (@ProjID = 9) return

	-- Begin Insert
	insert Bill
		(BillId,     TrunkGroup,    ProjID,    TrunkNumber,    RecordId,    Calling,     Called,    Acd,    Agent,    AgentGroup,    Extension,    ExtGroup,    VDN,	  StartTime,    Seconds,    Inbound,    Outbound,     StartDate,     Charge,     ChargeMe,    Flag,    IsLongCall,                              CallType,                                                         Frl)
	values
		(@BillId, @TrunkGroup, @ProjID, @TrunkNumber, @RecordId, @Calling, @Called, @Acd, @Agent, @AgentGroup, @Extension, @ExtGroup, @Vdn, @StartTime, @Seconds, @Inbound, @Outbound, @StartDate,  @Charge, @ChargeMe, @Flag, @IsLong, dbo.GetCallType(@ProjId, @Calling, @Called), @Frl)


GO
/****** Object:  StoredProcedure [dbo].[usp_bill_insert_test]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






CREATE PROCEDURE [dbo].[usp_bill_insert_test]
	@CdrId int,
	@RecordId int = 0,
	@Calling varchar(50) = '',
	@Called varchar(50) = '',
	@Route int = 0,
	@CallDate datetime,
	@CallTime datetime,
	@TimeLen int,
	@InGroup int = 0,
	@InMember int = 0,
	@OutGroup int = 0,
	@OutMember int = 0,
	@Extension int = 0,
	@Agent int = 0,
	@PrjId int =0,
	@Frl varchar(2) = ''
AS


	declare @StartDate varchar(8), @TrunkGroup smallint, @TrunkNumber smallint, @AgentGroup int
	declare @ProjID int, @ExtGroup int, @Charge money, @ChargeMe money
	declare @Flag bit, @sch varchar(500), @Channel int
	declare @ObjType varchar(10), @AssociateId int
	declare @CallType tinyint, @IsLong int 
	declare @Inbound int, @Outbound  int
	declare @StartTime datetime,@Acd int

	set @CallType = 0
	set @IsLong = 0
	set @StartTime = @CallTime

	--@Frl? 7, b then outbound

	if (@CdrId=0) begin
		select @CdrId = max(billid) from bill				
		set @CdrId = isnull(@CdrId, 0) + 1
	end

	set @StartDate = str(DATEPART(yy, @StartTime),4) + substring(str(100+DATEPART(mm, @StartTime),3),2,2) + substring(str(100+DATEPART(dd, @StartTime),3),2,2)  

	set @RecordId	= isnull(@RecordId, 0)
	set @TimeLen	= isnull(@TimeLen, 0)
	set @InGroup	= isnull(@InGroup, 0)
	set @OutGroup	= isnull(@OutGroup, 0)
	set @Acd	= isnull(@Acd, 0)
	set @Agent 	= isnull(@Agent, 0)
	set @Extension = isnull(@Extension, 0)
	set @Route 	= isnull(@Route, 0)
	set @Calling	= ltrim(rtrim(isnull(@Calling, '')))
	set @Called	= ltrim(rtrim(isnull(@Called, '')))
	set @Inbound	= isnull(@Inbound, 0)
	set @Outbound	= isnull(@Outbound, 0)

	if (charindex('#', @Called)>0)
		set @Called = substring(@Called, 1, charindex('#', @Called)-1)
	
	-- Get Trunk
	if @OutGroup!= 0 begin
		set @TrunkGroup = @OutGroup
		set @TrunkNumber = @OutMember
	end
	else begin
		set @TrunkGroup = @InGroup
		set @TrunkNumber = @InMember
	end

	-- Get Flag: 
	set @Flag = 0
	if @Inbound =0 and @Outbound = 0 begin
		set @Flag = 1
                        --if exists (select top 1 * from BillVDN where TrunkGroup=@TrunkGroup and @called like '%' + phone)
			--set @Inbound = 1 
		--else
		--	set @Outbound = 1 
	end

	--Get Extension&Agent&Channel
	if @Calling != ''  begin
		select @ObjType = o.typename, @ProjID = o.projId, @AssociateId=o.associateId
		from (select top 1 t.typename, p.projId, p.associateId from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type 
			where (t.typename='ext' or t.typename='agent' or t.typename='channel') and @Calling like ltrim(rtrim([value])) and pr.enabled = 1) o

		if (@ObjType is not null) begin
			if @ObjType = 'ext' and @Extension = 0
				set @Extension = @Calling
			else if @ObjType = 'agent' and @Agent =0
				set @Agent = @Calling
			else if @ObjType = 'channel' 
				set @Channel = @Calling

			--if @ObjType != 'called' and @Flag=1
			if @Flag=1
				set @Outbound = 1
		end
	end
	if @Called != ''  begin
		set @ObjType = null
		select @ObjType = o.typename, @ProjID = o.projId, @AssociateId=o.associateId
		from ( select top 1 t.typename, p.projId, p.associateId from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type 
			where (t.typename='called' and @Called like '%' + ltrim(rtrim([value]))) 
				or ((t.typename='ext' or t.typename='agent' or t.typename='channel') and @Called like ltrim(rtrim([value]))) 
				and pr.enabled = 1) o
		
		if (@ObjType is not null) begin
			if @ObjType = 'ext' and @Extension = 0
				set @Extension = @Called
			else if @ObjType = 'agent' and @Agent =0
				set @Agent = @Called
			else if @ObjType = 'channel' 
				set @Channel = @Called
			else if @ObjType = 'called' 
				set @Inbound = 1

			--if  @ObjType != 'called' and @Flag=1
			if @Flag=1
				set @Inbound = 1 
		end
	end

	set @Agent = isnull(@Agent, 0)
	set @Extension = isnull(@Extension, 0)
	set @Channel = isnull(@Channel, 0)

	/*
	if @Agent = 0 begin
		if @Calling!='' and exists (select top 1 * from agent where convert(varchar, agentid) = @Calling)
			set @Agent = @Calling
		else if @Called!='' and exists (select top 1 * from agent where convert(varchar, agentid) = @Called)
			set @Agent = @Called
	end
	if @Extension = 0 begin
		if @Calling!='' and exists (select top 1 * from address where convert(varchar, address) = @Calling)
			set @Extension = @Calling
		else if @Called!='' and exists (select top 1 * from address where convert(varchar, address) = @Called)
			set @Extension = @Called
	end
	*/

	-- Get ProjID 
	--if @ProjID is null
	set @ProjID = dbo.GetProject(@TrunkGroup, @Acd, @Agent, @Extension, @Channel, @Called, @Route, @StartTime)

	-- Get @AgentGroup
	if @StartTime is not null and @Agent != 0
		select top 1 @AgentGroup = GroupId
		from GroupAgent g
		where  ((g.TimeType=0)  
			or (g.TimeType=1 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between g.timefrom and g.timeto)  
			or (g.TimeType=2 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between g.timefrom and g.timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&g.weeks!=0) )) 
			and agentid = @Agent
	set @AgentGroup = isnull(@AgentGroup, 0)

	-- Get ExtGroup
	if @Extension != 0
		select top 1 @ExtGroup = GroupId from GroupAddress where address = @Extension
	set @ExtGroup = isnull(@ExtGroup, 0)	

	-- Get Charge 
	-- AT&T not bill
	if (@Inbound=0 and @Outbound =0) begin
		if (len(@Called) >5)
			set @Outbound = 1
	end


    ------modified at 2011/05/09:begin/---------
    if (@ProjID=120 and @Inbound=1 and @Outbound =0)
        begin
           if (len(@Called)>7 and len(@Calling)=5)
              begin 
                set @Inbound=0 
                set @Outbound=1
              end
        end

    -----end/---------




	-- if @Outbound = 1 and @ProjID!=9 begin
	if @Outbound = 1  begin

		if @TrunkGroup = 1 or @TrunkGroup = 3 or @TrunkGroup = 5 begin
			set @Charge = dbo.PhoneChargeUSA(@TimeLen)
			set @ChargeMe =@Charge
			set @IsLong = 1

			------------  特殊处理 --------------
			--DNP
			if @ProjID = 42
				set @ProjID = 48

			--CISCO
			if @ProjID = 47 
				set @ProjID = 50
			-------------------------------------------
			
			if len(@called) < 10 begin
				set @IsLong = 0
				set @Charge = 0
				set @ChargeMe = 0
			end

		end
		else if @ProjID = 108 begin
			set @IsLong = dbo.IsLongPhone(@called)
			set @Charge= dbo.PhoneChargeCD(@Called, @TimeLen)
			set @ChargeMe = dbo.PhoneChargeMeCD(@Called, @TimeLen)
			
		end
		else if (@ProjID=56  and (@TrunkGroup=71 or @TrunkGroup=72))begin
			set @IsLong = dbo.IsLongPhone(@called)
			set @Charge= dbo.PhoneChargeCD(@Called, @TimeLen)
			set @ChargeMe = dbo.PhoneChargeMeCD(@Called, @TimeLen)
		
		end 
		else if (@ProjID=120  and (@TrunkGroup=71 or @TrunkGroup=72))begin
			set @IsLong = dbo.IsLongPhone(@called)
			set @Charge= dbo.PhoneChargeCD(@Called, @TimeLen)
			set @ChargeMe = dbo.PhoneChargeMeCD(@Called, @TimeLen)
		
		end 
		else if (@ProjID=121  and (@TrunkGroup=71 or @TrunkGroup=72))begin
			set @IsLong = dbo.IsLongPhone(@called)
			set @Charge= dbo.PhoneChargeCD(@Called, @TimeLen)
			set @ChargeMe = dbo.PhoneChargeMeCD(@Called, @TimeLen)
		
		end

		else begin

			----WU D2B	080521---
			if @Called like '28%' and @ProjID=78
				set @ProjID=94

			set @IsLong = dbo.IsLongPhone(@called)
			set @Charge = dbo.PhoneCharge(@Called, @TimeLen)
			set @ChargeMe = dbo.PhoneChargeMe(@Called, @TimeLen)
		end
	end

	set @Charge = isnull(@Charge, 0)
	set @ChargeMe = isnull(@ChargeMe, 0)

	--BOC GuangZhou bill   --20090917
	if (@Calling='2128939098' and  @TrunkGroup=2)
	begin
		set  @ProjID=105
	end

	-- ?
	if @Channel !=0 and @Extension = 0
		set @Extension = @Channel

	--if (@ProjID = 9) return

	-- Begin Insert
	insert Bill
		(BillId,     TrunkGroup,    ProjID,    TrunkNumber,    InTrunkGroup, InTrunkNumber, RecordId,    Calling,     Called,    Acd,    Agent,    AgentGroup,    Extension,    ExtGroup,    VDN,	  StartTime,    Seconds,    Inbound,    Outbound,     StartDate,     Charge,     ChargeMe,    Flag,    IsLongCall,                              CallType,                                                         Frl)
	values
		(@CdrId, @TrunkGroup, @ProjID, @TrunkNumber, @InGroup, @InMember, @RecordId, @Calling, @Called, @Acd, @Agent, @AgentGroup, @Extension, @ExtGroup, @Route, @StartTime, @TimeLen, @Inbound, @Outbound, @StartDate,  @Charge, @ChargeMe, @Flag, @IsLong, dbo.GetCallType(@ProjId, @Calling, @Called), @Frl)





GO
/****** Object:  StoredProcedure [dbo].[usp_bill_new]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_bill_new]  
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (id varchar(20), name varchar(50), objs int, times int, seconds int, charge money, chargeme money)   

	if @GroupBy = 'group' begin  
		insert into #TempTab  
		select distinct g.groupid, g.groupname, count(distinct r.agent) agents, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
		from Bill r inner join AgentGroup g on g.GroupID = r.AgentGroup   
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and r.agent is not null and r.agent !='' 
			and r.agentgroup is not null and r.agentgroup !=0 
			and r.charge>0
		group by g.groupid, g.groupname  
		order by g.groupid  

		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select distinct '', 'Sum', count(distinct r.agent) agents, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
			from Bill r  
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and seconds > 0  
				and agent is not null and agent !='' 
				and agentgroup is not null and agentgroup !=0 
				and charge>0
		end  
	end  

	if @GroupBy = 'agent' begin  
		insert into #TempTab  
		select a.agentid, a.agentname, 1 agents, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
		from Bill r left join Agent a on r.agent = a.agentid  
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and seconds > 0  
			and agent is not null and agent !='' 
			and agentgroup = isnull(@ID, agentgroup)
			and charge>0
		group by a.agentid, a.agentname  
		order by a.agentid  

		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct r.agent) agents, count(distinct r.BillId) times,  sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
			from Bill r inner join agent a on r.agent = a.agentid  
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and seconds > 0  
				and agent is not null and agent !='' 
				and agentgroup = isnull(@ID, agentgroup)
				and charge>0
		end  
	end  

	if @GroupBy = 'extgroup' begin  
		insert into #TempTab  
		select distinct g.groupid, g.groupname, count(distinct r.extension) exts, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
		from Bill r inner join AddressGroup g on g.GroupID = r.ExtGroup   
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and r.extension is not null and r.extension !='' 
			and r.extgroup is not null and r.extgroup !=0 
			and charge>0
		group by g.groupId, g.groupname  
		order by g.groupid  

		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			insert into #TempTab  
			select distinct '', 'Sum', count(distinct r.agent) agents, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
			from Bill r  
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and seconds > 0  
				and extension is not null and extension !='' 
				and extgroup is not null and extgroup !=0 
				and charge>0
		end  
	end  

	if @GroupBy = 'ext' begin  
		insert into #TempTab  
		select extension ext1, extension ext2, 1 exts, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
		from Bill r
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and seconds > 0  
			and extension is not null and extension !='' 
			and extgroup = isnull(@ID, extgroup)
			and charge>0
		group by extension
		order by extension

		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct extension) exts, count(distinct r.BillId) times,  sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
			from Bill r
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and seconds > 0  
				and extension is not null and extension !='' 
				and extgroup = isnull(@ID, extgroup)
				and charge>0
		end  
	end

	if @GroupBy = 'project' begin  
		insert into #TempTab  
		select r.projid, p.projname, 1, count(distinct r.BillId) times, sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
		from Bill r left join Project p on p.projId = r.projId left join project pr on pr.projId = r.projId
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and r.projId !=0
			and pr.enabled = 1
			and r.projId = isnull(@ID, r.projId)
			and r.charge>0
		group by r.projid, p.projname
		order by p.projname

		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct r.projid) projs, count(distinct r.BillId) times,  sum(r.seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
			from Bill r left join project pr on pr.projId = r.projId
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
				and r.projId !=0
				and pr.enabled = 1
				and r.projId = isnull(@ID, r.projId)
				and r.charge>0
		end  
	end

	select * from #TempTab  
	drop table #TempTab  
	return @RowCount



GO
/****** Object:  StoredProcedure [dbo].[usp_bill_pool]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_bill_pool]  
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null
AS  
	declare @RowCount int  
	declare @Agents int  
	declare @Exts int  

	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (id varchar(20), name varchar(50), objs int, times int, seconds int,  charge money, chargeme money)

	if @GroupBy = 'group' begin  
		insert into #TempTab  
		select g.groupid, g.groupname,  sum(distinct a.agents) agents, sum(times) times, sum(r.seconds) total,  sum(charge) as charge, sum(chargeme) as chargeme
		from Bill_StatGroup r inner join AgentGroup g on g.GroupID = r.subid inner join (select subid, count(distinct agent) as agents from Bill_StatGroupAgents where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and g.groupid = isnull(@ID, g.groupid)  
		group by g.groupid, g.groupname  
		order by g.groupid  

		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			select @Agents=count(distinct agent) from Bill_StatGroupAgents where statdate between @DateTimeFrom and @DateTimeTo  
			insert into #TempTab  
			select '', 'Sum', @Agents agents, sum(r.times) times, sum(r.seconds) total,  sum(charge) as charge, sum(chargeme) as chargeme 
			from Bill_StatGroup r  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and subid = isnull(@ID, subid)  

		end  
	end  

	if @GroupBy = 'agent' begin  
		if (@ID is null) begin
	   		insert into #TempTab  
			select a.agentid, a.agentname, 1 agents, sum(r.times) times, sum(r.seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
			from Bill_StatAgent r inner join Agent a on r.subid = a.agentid  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			group by a.agentid, a.agentname  
			order by a.agentid  
	
			set @RowCount = @@RowCount  
			if @RowCount > 0 begin  
				insert into #TempTab  
					select '', 'Sum', @RowCount agents, sum(times) times, sum(r.seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
				from Bill_StatAgent r inner join agent a on r.subid = a.agentid  
				where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			end  
		end
		else begin
	   		insert into #TempTab  
			select a.agentid, a.agentname, 1 agents, sum(r.times) times, sum(r.seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
			from Bill_StatAgent r inner join Agent a on r.subid = a.agentid  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and a.agentid in  (select distinct agent from Bill_Statgroupagents where subid = @ID and statdate between @DateTimeFrom and @DateTimeTo) 
			group by a.agentid, a.agentname  
			order by a.agentid  
	
			set @RowCount = @@RowCount  
			if @RowCount > 0 begin  
				insert into #TempTab  
					select '', 'Sum', @RowCount agents, sum(times) times, sum(r.seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
				from Bill_StatAgent r inner join agent a on r.subid = a.agentid  
				where (r.statdate between @DateTimeFrom and @DateTimeTo)  
					and a.agentid in  (select distinct agent from Bill_Statgroupagents where subid =@ID and statdate between @DateTimeFrom and @DateTimeTo) 
			end  
		end

	end

	if @GroupBy = 'extgroup' begin  
		insert into #TempTab  
		select g.groupid, g.groupname,  sum(distinct a.exts) exts, sum(times) times, sum(r.seconds) total,  sum(charge) as charge, sum(chargeme) as chargeme
		from Bill_StatExtGroup r inner join AddressGroup g on g.GroupID = r.subid inner join (select subid, count(distinct ext) as exts from Bill_StatExtGroupExts where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and g.groupid = isnull(@ID, g.groupid)  
		group by g.groupid, g.groupname  
		order by g.groupid  

		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			select @Exts=count(distinct subId) from Bill_StatExtGroupExts 
			where statdate between @DateTimeFrom and @DateTimeTo  
				and subid = isnull(@ID, subid)  

			insert into #TempTab  
			select '', 'Sum', @Exts objs, sum(times) times, sum(seconds) total,  sum(charge) as charge, sum(chargeme) as chargeme 
			from Bill_StatExtGroup
			where (statdate between @DateTimeFrom and @DateTimeTo)  
				and subid = isnull(@ID, subid)  

		end  
	end  

	if @GroupBy = 'ext' begin  
   		insert into #TempTab  
		select subid s1, subid s2, 1 exts, sum(times) times, sum(seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
		from Bill_StatExt
		where (statdate between @DateTimeFrom and @DateTimeTo)  
			and subid = isnull(@ID, subid)  
		group by subid
		order by subid


		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			insert into #TempTab  
				select '', 'Sum', @RowCount exts, sum(times) times, sum(seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
			from Bill_StatExt
			where (statdate between @DateTimeFrom and @DateTimeTo)  
				and subid = isnull(@ID, subid)  
		end  
	end

	if @GroupBy = 'project' begin  
   		insert into #TempTab  
		select subid, p.projname, 1 exts, sum(times) times, sum(seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
		from Bill_StatProj b left join Project p on p.projId = b.subId
		where (statdate between @DateTimeFrom and @DateTimeTo)  
			and subid = isnull(@ID, subid)  
		group by subid, p.projname
		order by p.projname


		set @RowCount = @@RowCount  
		if @RowCount > 0 begin  
			insert into #TempTab  
				select '', 'Sum', @RowCount exts, sum(times) times, sum(seconds) total,   sum(charge) as charge, sum(chargeme) as chargeme
			from Bill_StatProj
			where (statdate between @DateTimeFrom and @DateTimeTo)  
				and subid = isnull(@ID, subid)  
		end  
	end

	select * from #TempTab  
	drop table #TempTab  
	return @RowCount



GO
/****** Object:  StoredProcedure [dbo].[usp_bill_proj]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_bill_proj]
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID int,
	@CallType varchar(10) = '' 
AS  

	set @CallType = '0'

	declare @RowCount int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (device varchar(100) collate database_default, local_calls int, local_seconds int, local_charge money, local_chargeme money, long_calls int, long_seconds int, long_charge money, long_chargeme money)

	if (@ID !=1 or @CallType !=1)  begin
		-- not HP or is HP but not transfer
		if (@ID !=1)
			set @CallType = 0

		insert into #TempTab
		select calling, 
			sum(1-islongcall), sum(case islongcall when 1 then 0 else seconds end), sum(case islongcall when 1 then 0 else charge end), sum(case islongcall when 1 then 0 else chargeme end), 
			sum(islongcall), sum(case islongcall when 0 then 0 else seconds end), sum(case islongcall when 0 then 0 else charge end), sum(case islongcall when 0 then 0 else chargeme end)
		from Bill b
		where (StartTime between @DateTimeFrom and @DateTimeTo)  
			and projId = (case @ID when 0 then projid else @ID end)
			and charge>0
			and CallType = (case @CallType when 0 then CallType else @CallType end)
			and outbound = 1
		group by calling
	
		insert into #TempTab
		select 'sum', sum(local_calls),  sum(local_seconds), sum(local_charge), sum(local_chargeme),   sum(long_calls),  sum(long_seconds), sum(long_charge), sum(long_chargeme)  
		from #TempTab  
	end
	else begin
		-- is HP and Transfer
		insert into #TempTab
		select called, 
			sum(1-islongcall), sum(case islongcall when 1 then 0 else seconds end), sum(case islongcall when 1 then 0 else charge end), sum(case islongcall when 1 then 0 else chargeme end), 
			sum(islongcall), sum(case islongcall when 0 then 0 else seconds end), sum(case islongcall when 0 then 0 else charge end), sum(case islongcall when 0 then 0 else chargeme end)
		from Bill b
		where (StartTime between @DateTimeFrom and @DateTimeTo)  
			and projId = (case @ID when 0 then projid else @ID end)
			and charge>0
			and CallType = (case @CallType when 0 then CallType else @CallType end)
			and outbound = 1
		group by called
	
		insert into #TempTab
		select 'sum', sum(local_calls),  sum(local_seconds), sum(local_charge), sum(local_chargeme),   sum(long_calls),  sum(long_seconds), sum(long_charge), sum(long_chargeme)  
		from #TempTab  
	end

	select t.*,  local_charge + long_charge as chargeall,   local_chargeme + long_chargeme as chargemeall, o.[desc] from #TempTab t  left join other_device o on t.device = o.device
	where local_calls is not null
	order by t.device

	drop table #TempTab  
	return @RowCount


GO
/****** Object:  StoredProcedure [dbo].[usp_bill_proj_n]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[usp_bill_proj_n]
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID int  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (device varchar(10), local_calls int, local_seconds int, local_charge money, local_chargeme money, long_calls int, long_seconds int, long_charge money, long_chargeme money)

	insert into #TempTab
	select agent, 
		sum(1-islongcall), sum(case islongcall when 1 then 0 else seconds end), sum(case islongcall when 1 then 0 else charge end), sum(case islongcall when 1 then 0 else chargeme end), 
		sum(islongcall), sum(case islongcall when 0 then 0 else seconds end), sum(case islongcall when 0 then 0 else charge end), sum(case islongcall when 0 then 0 else chargeme end)
	from Bill
	where (StartTime between @DateTimeFrom and @DateTimeTo)  
		and projId = (case @ID when 0 then projid else @ID end)
		and charge>0
		and agent !=''
	group by agent
	order by agent

	insert into #TempTab
	select extension, 
		sum(1-islongcall), sum(case islongcall when 1 then 0 else seconds end), sum(case islongcall when 1 then 0 else charge end), sum(case islongcall when 1 then 0 else chargeme end), 
		sum(islongcall), sum(case islongcall when 0 then 0 else seconds end), sum(case islongcall when 0 then 0 else charge end), sum(case islongcall when 0 then 0 else chargeme end)
	from Bill
	where (StartTime between @DateTimeFrom and @DateTimeTo)  
		and projId = (case @ID when 0 then projid else @ID end)
		and charge>0
		and extension !=''
	group by extension
	order by extension

	insert into #TempTab
	select 'sum', sum(local_calls),  sum(local_seconds), sum(local_charge), sum(local_chargeme),   sum(long_calls),  sum(long_seconds), sum(long_charge), sum(long_chargeme)  
	from #TempTab  
	
	select *,  local_charge + long_charge as chargeall,   local_chargeme + long_chargeme as chargemeall  from #TempTab  
	where local_calls is not null

	drop table #TempTab  
	return @RowCount



GO
/****** Object:  StoredProcedure [dbo].[usp_bill_recount]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_bill_recount] 
	@DatetimeStart datetime,
	@DatetimeEnd datetime
AS

	 -- Set Inbound or Outbound
	update bill 
	set Inbound = 0, outbound = 0
	where flag = 1
		and starttime between @DatetimeStart and @DatetimeEnd

	
	--update bill set Inbound = 1, flag = 1 
	--where ((Inbound = 0 and outbound = 0)  or (flag = 1))
	--	and called != ''
	--	and starttime between @DatetimeStart and @DatetimeEnd
	--	and TrunkGroup in (select trunkgroup from BillVDN where called like '%' + phone)
	
		
	update bill set Inbound = 1, flag = 1 
	where ((Inbound = 0 and outbound = 0)  or (flag = 1))
		and called != ''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where called like '%' + ltrim(rtrim([value])) and (typename = 'called') and pr.enabled=1)
		and starttime between @DatetimeStart and @DatetimeEnd

	update bill set outbound  = 1,  flag = 1 
	where outbound = 0 and Inbound = 0
		and starttime between @DatetimeStart and @DatetimeEnd

	-- Set Extension
	update bill 
	set extension = calling 
	where extension = '' and calling !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where calling like ltrim(rtrim([value])) and (typename = 'ext') and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = calling)
		and starttime between @DatetimeStart and @DatetimeEnd
		
	update bill 
	set extension = called 
	where extension = '' and called !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where called like ltrim(rtrim([value])) and (typename = 'ext') and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = called)
		and starttime between @DatetimeStart and @DatetimeEnd

	update bill 
	set extension = calling 
	where extension = '' and calling !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where calling like ltrim(rtrim([value])) and (typename = 'channel') and pr.enabled=1) or exists (select top 1 * from vpbchannel where convert(varchar, channel) = calling)
		and starttime between @DatetimeStart and @DatetimeEnd

	update bill 
	set extension = called 
	where extension = '' and called !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where called like ltrim(rtrim([value])) and (typename = 'channel') and pr.enabled=1) or exists (select top 1 * from vpbchannel where convert(varchar, channel) = called)
		and starttime between @DatetimeStart and @DatetimeEnd

	-- Set Agent
	update bill 
	set agent = calling 
	where agent = '' and calling !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where calling like ltrim(rtrim([value])) and (typename = 'agent') and pr.enabled=1) or exists (select top 1 * from agent where convert(varchar, agentid) = calling)
		and starttime between @DatetimeStart and @DatetimeEnd
		
	update bill 
	set agent = called 
	where agent = '' and called !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where called like ltrim(rtrim([value])) and (typename = 'agent') and pr.enabled=1) or exists (select top 1 * from agent where convert(varchar, agentid) = called)
		and starttime between @DatetimeStart and @DatetimeEnd

	-- Set Vdn
	update bill 
	set vdn = called 
	where vdn = '' and called !=''
		and exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where called like ltrim(rtrim([value])) and (typename = 'vdn') and pr.enabled=1)
		and starttime between @DatetimeStart and @DatetimeEnd

	-- Set Project
	update bill 
	set projId = dbo.GetProject(TrunkGroup, Acd, Agent, Extension, Extension, Called, Vdn, Starttime)

	-- Set AgentGroup
	update bill
	set AgentGroup = (select top 1 GroupId from GroupAgent g
				where  ((g.TimeType=0)  
					or (g.TimeType=1 and substring(str(100+DATEPART(hh,  Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi,  Starttime),3),2,2) between g.timefrom and g.timeto)  
					or (g.TimeType=2 and (substring(str(100+DATEPART(hh, Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi,  Starttime),3),2,2) between g.timefrom and g.timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday,  Starttime)*3 - 2, 2)&g.weeks!=0) )) 
					and agentid = agent)

 	-- Set ExtGroup
	update bill
	set extgroup = (select top 1 groupid from GroupAddress where address = extension)
	where starttime between @DatetimeStart and @DatetimeEnd

	-- Set Charge
	update bill
	set charge = dbo.PhoneCharge(called, seconds),
		chargeMe = dbo.PhoneChargeMe(called, seconds)
	where outbound = 1
		and starttime between @DatetimeStart and @DatetimeEnd

	update bill
	set charge = 0, chargeMe = 0
	where inbound = 1
		and starttime between @DatetimeStart and @DatetimeEnd

	update bill
	set 
		projid = (case projid when null then -1 else projid end),
		acd = (case acd when null then '' else acd end),
		agent = (case agent when null then '' else agent end),
		agentgroup = (case agentgroup when null then 0 else agentgroup end),
		extension = (case extension when null then '' else extension end),
		extgroup = (case extgroup when null then 0 else extgroup end)
	where starttime between @DatetimeStart and @DatetimeEnd


GO
/****** Object:  StoredProcedure [dbo].[usp_bill_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_bill_update]  
	@DateFrom int = 0,  
	@DateTo int = 0  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @DateFrom < 20000101 return 0  
	if @DateTo = 0 set @DateTo = @DateFrom  

	--AgentGroup 
	print('AgentGroup...') 
	delete from Bill_StatGroupAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from Bill_StatGroup where StatDate >= @DateFrom and StatDate <= @DateTo  

	insert into Bill_StatGroup  
	select cast(StartDate as int) StatDate, agentgroup, count(distinct agent) agents, count(distinct BillId) times, sum(seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
	from bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and agent is not null and agent !='' 
		and agentgroup is not null and agentgroup !=0 
		and charge>0
	group by StartDate, agentgroup 

	insert into Bill_StatGroupAgents  
		select cast(StartDate as int) StatDate, AgentGroup, Agent  
	from Bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and agent is not null and agent !='' 
		and agentgroup is not null and agentgroup !=0 
		and charge>0
	group by StartDate,  AgentGroup, Agent  

	--Agent
	print('Agent...') 
	delete from Bill_StatAgent where StatDate >= @DateFrom and StatDate <= @DateTo  

	insert into Bill_StatAgent  
	select cast(StartDate as int) StatDate, agent as agentid , 1 agents, count(distinct BillId) times, sum(seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
	from Bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and agent is not null and agent !='' 
		and charge>0
	group by  StartDate, agent 

	--ExtGroup 
	print('Ext. Group...') 
	delete from Bill_StatExtGroupExts where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from Bill_StatExtGroup where StatDate >= @DateFrom and StatDate <= @DateTo  

	insert into Bill_StatExtGroup  
	select cast(StartDate as int) StatDate, extgroup, count(distinct extension) exts, count(distinct BillId) times, sum(seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
	from bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and Extension is not null and Extension !='' 
		and ExtGroup is not null and ExtGroup !=0 
		and charge>0
	group by StartDate, extgroup 

	insert into Bill_StatExtGroupExts  
		select cast(StartDate as int) StatDate, ExtGroup, Extension  
	from Bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and Extension is not null and Extension !='' 
		and extgroup is not null and extgroup !=0 
		and charge>0
	group by StartDate, ExtGroup, Extension

	--Ext
	print('Ext....') 
	delete from Bill_StatExt where StatDate >= @DateFrom and StatDate <= @DateTo  

	insert into Bill_StatExt
	select cast(StartDate as int) StatDate, extension as subid , 1 exts, count(distinct BillId) times, sum(seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
	from Bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and extension is not null and extension !='' 
		and charge>0
	group by  StartDate, extension

	--Project
	print('Project....') 
	delete from Bill_StatProj where StatDate >= @DateFrom and StatDate <= @DateTo  

	insert into Bill_StatProj
	select cast(StartDate as int) StatDate, projId as subid , 1 exts, count(distinct BillId) times, sum(seconds) total, sum(charge) as charge, sum(chargeme) as chargeme
	from Bill
	where StartDate >= str(@DateFrom, 8) and StartDate <= str(@DateTo, 8)  
		and seconds > 0  
		and projId is not null and projId !=0 
		and charge>0
	group by  StartDate, projId


GO
/****** Object:  StoredProcedure [dbo].[usp_change_pwd]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_change_pwd]
	@LogID int = 0,  
	@LogPass varchar(50) = null,  
	@validays int = null
AS  
	declare @date int, @today int
	if @LogPass is null begin
		set @today = null
	end 
	else begin
		set @today = DATEPART(yy, getdate()) * 10000 + DATEPART(mm, getdate()) * 100 + DATEPART(dd, getdate())
	end

	update Supervisor set  
		LogID = isnull(@LogID, LogID),  
		LogPass = isnull(@LogPass, LogPass),  
		LastDate = case when @today is null then LastDate else str(@today) end,
		validays = isnull(@validays, validays)
		where LogID = @LogID
		select 1 'result' 


GO
/****** Object:  StoredProcedure [dbo].[usp_clear_test_records]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE 	[dbo].[usp_clear_test_records]
	@Validate varchar(8)
AS
	if @Validate = dbo.ConvertDateToDate(getdate()) begin
		delete agentgrouprec
		delete AddressGroupRec
		delete taskrec
		delete formrec
		delete monitor
		delete label
		delete connection
		delete records
		delete StatAgent
		delete StatDaily
		delete StatDailyAgents
		delete StatExt
		delete StatExtGroup
		delete StatExtGroupExts
		delete StatGroup
		delete StatGroupAgents
		delete StatHour
		delete StatHourAgents
		delete StatTask
		delete StatTaskAgents
		delete StatTrunkGroup

		delete History_AddressGroupRec
		delete History_AgentGroupRec
		delete History_Connection
		delete History_Records
		delete History_Task
		delete History_TaskItem
		delete History_TaskRec

		delete bill
		delete Bill_StatAgent
		delete Bill_StatExt
		delete Bill_StatExtGroup
		delete Bill_StatExtGroupExts
		delete Bill_StatGroup
		delete Bill_StatGroupAgents
		delete Bill_StatProj
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_connection_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_connection_insert] 
	@RecordId	int, 
	@Device	varchar(20), 
	@Phone 	varchar(50) = '', 
	@Agent 	varchar(20) = '', 
	@Enter		int = 0, 
	@Leave 	int = 0,
	@DevType 	tinyint = 0
AS 
	insert connection (RecordId, Device, Phone, Agent,  Enter, Leave) 
		values	 (@RecordId, @Device, @Phone, @Agent,  @Enter, @Leave) 

	if (@Device!='' and @Agent != '')
		set @DevType = 2

	if @DevType = 2 begin
		-- extention
		if @Device !='' begin 
			--if not exists (select top 1 * from AddressGroupRec where Address = @Device and RecordId = @RecordId) 
			insert AddressGroupRec select GroupId, @RecordId as RecordId, Address as Device from GroupAddress where convert(varchar, Address)=@Device 
		end 
		if @Agent !=''  begin 
			declare @Starttime datetime
			declare @Master varchar(20) 	
			set @Starttime = dateadd(second, -@Leave, getdate())

			select @Master = master from records where RecordId = @RecordId
			set @Master = isnull(@Master, '')

			if (@Master != @Agent) begin
				insert AgentGroupRec (RecordId, AgentId, GroupId)
					select distinct @RecordId as RecordId,  AgentId, GroupId  
					from GroupAgent
					where AgentId = @Agent 
						and GroupId is not null 
						and ((TimeType=0)  
							or (TimeType=1 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
							or (TimeType=2 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&weeks!=0) )) 
			end
		end
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_connection_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_connection_update] 
	@RecordId	int, 
	@Device	varchar(20), 
	@Phone 	varchar(50) = null, 
	@Agent 	varchar(20) = null, 
	@Enter		int = null, 
	@Leave 	int = null 
AS 
	update connection set 
		Phone = isnull(@Phone, Phone), 
		Agent  = isnull(@Agent, Agent), 
		Enter   = isnull(@Enter, Enter), 
		Leave = isnull(@Leave, Leave) 
	where RecordId = @RecordId and Device = @Device 
	  
	--if @Agent !=0  begin 
	--	if not exists (select top 1 * from AgentGroupRec where AgentId = @Agent and RecordId = @RecordId) 
	--		insert AgentGroupRec select GroupId, @RecordId as RecordId, AgentId from GroupAgent where AgentId=@Agent 
	--end 
	--if @Device !='' begin 
	--	if not exists (select top 1 * from AddressGroupRec where Address = @Device and RecordId = @RecordId) 
	--		insert AddressGroupRec select GroupId, @RecordId as RecordId, Address as Device from GroupAddress where Address=@Device 
	--end


GO
/****** Object:  StoredProcedure [dbo].[usp_cti_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_cti_delete]  
	@CtiName char(32)  
AS  
	delete CTI 
		where CtiName = ltrim(rtrim(@CtiName))


GO
/****** Object:  StoredProcedure [dbo].[usp_cti_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_cti_insert] 
	@CtiName char(32) = null, 
	@LinkStr varchar(50) = null, 
	@Station varchar(50) = null, 
	@Port int =0, 
	@Username varchar(20) = null, 
	@Password varchar(20) = null, 
	@Type int = 0, 
	@Enabled bit = 1 
AS 
	set @CtiName = ltrim(rtrim(@CtiName)) 
	 if (select count(*) from CTI where CtiName = @CtiName) = 0 begin  
		insert into CTI (CtiName, LinkStr, Station, Port, Username, Password, Type, Enabled) values (@CtiName,@LinkStr, @Station, @Port, @Username, @Password, @Type, @Enabled) 
		select 1  'result' 
	end  
		else begin  
		select 0 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_cti_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_cti_update]  
	@CtiName char(32) = null, 
	@LinkStr varchar(50) = null, 
	@Station varchar(50) = null, 
	@Port int = null, 
	@Username varchar(20) = null, 
	@Password varchar(20) = null, 
	@Type int = null, 
	@Enabled bit = 1 
AS  
	update CTI 
		set LinkStr = isnull(@LinkStr, LinkStr), 
		Station  = isnull(@Station, Station), 
		Port = isnull(@Port, Port ), 
		Username = isnull(@Username, Username), 
		Password = isnull(@Password, Password), 
		Type = isnull(@Type, Type), 
		Enabled= isnull(@Enabled, Enabled) 
		where CtiName = @CtiName


GO
/****** Object:  StoredProcedure [dbo].[usp_ctilink_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_ctilink_delete]  
	@LinkName char(32)  
AS  
	delete CTILink 
		where LinkName = ltrim(rtrim(@LinkName))   
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_ctilink_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_ctilink_insert] 
	@LinkName char(32) = null, 
	@CtiName char(32) = null, 
	@Utility int = 0, 
	@Description varchar(500) = null, 
	@Enabled bit = 1 
AS 
	set @LinkName = ltrim(rtrim(@LinkName)) 
	if exists (select * from CtiLink where LinkName=@LinkName)  
		select 0 'result' 
	else begin 
		insert into CtiLink (LinkName, CtiName, Utility,  Description, Enabled) values (@LinkName, @CtiName, @Utility,  @Description, @Enabled) 
		select 1 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_ctilink_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_ctilink_update]  
	@LinkName char(32) = null, 
	@CtiName char(32) = null, 
	@Utility int = 0, 
	@Description varchar(500) = null, 
	@Enabled bit = 1 
AS  
	set @LinkName=ltrim(rtrim(@LinkName )) 
	update CtiLink set 
		CtiName = isnull(@CtiName, CtiName), 
		Utility = isnull(@Utility, Utility), 
		Description =  isnull(@Description, Description), 
		Enabled = isnull(@Enabled, Enabled) 
	where LinkName= @LinkName


GO
/****** Object:  StoredProcedure [dbo].[usp_delete_filters]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_delete_filters]
AS
	delete filter


GO
/****** Object:  StoredProcedure [dbo].[usp_ENC_RecordInfo_Add]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ENC_RecordInfo_Add]  
    @in_RecordId        int               ,
    @in_Calling         varchar(50) = ''  ,
    @in_Called          varchar(50) = ''  ,
    @in_Answer          varchar(50) = ''  ,
    @in_Master          varchar(20) = ''  ,
    @in_Channel         varchar(10) = ''  ,
    @in_RecURL			smallint = 0      ,
    @in_ScrURL			smallint = 0	  ,
    @in_VideoURL        smallint = 0      ,
    @in_StartTime       datetime = null   ,
    @in_Seconds         int = 0           ,
    @in_State           int = 0           ,
    @in_Finished        tinyint = 0       ,
    @in_StartDate       int = 0           ,
    @in_StartHour       tinyint = 0       ,
    @in_Backuped        tinyint =    0    ,
    @in_Checked         bit = 0           ,
    @in_Direction       bit = 0           ,
    @in_ProjId          int = 0           ,
    @in_Inbound         bit = 0           ,
    @in_Outbound        bit = 0           ,
    @in_Flag            bit = 0           ,
    @in_Extension       varchar(20) = ''  ,
    @in_VoiceType       tinyint = 0       ,
    @in_Acd             varchar(20) = ''  ,
    @in_UCID            varchar(25) = ''  ,
    @in_UUI             varchar(100) = '' ,
    @in_NeedEncry		bit = 0			  ,
    @in_DataEncrypted   bit = 1           , 
    @in_EncryKey        int = 0
AS  

BEGIN
--Please note: Before enable the following Script need first 
--             create source DB link XXXXX


-- BEGIN : Add Encryed Record information to Target DB
INSERT INTO [Records]
           ([RecordId]
           ,[Calling]
           ,[Called]
           ,[Answer]
           ,[Master]
           ,[Channel]
           ,[RecURL]
           ,[ScrURL]
           ,[VideoURL]
           ,[StartTime]
           ,[Seconds]
           ,[State]
           ,[Finished]
           ,[StartDate]
           ,[StartHour]
           ,[Backuped]
           ,[Checked]
           ,[Direction]
           ,[ProjId]
           ,[Inbound]
           ,[Outbound]
           ,[Flag]
           ,[Extension]
           ,[VoiceType]
           ,[Acd]
           ,[UCID]
           ,[UUI]
           ,[NeedEncry]
           ,[DataEncrypted]
           ,[EncryKey])
     VALUES
           (@in_RecordId        
           ,@in_Calling         
           ,@in_Called          
           ,@in_Answer          
           ,@in_Master          
           ,@in_Channel         
           ,@in_RecURL  
           ,@in_ScrURL      
           ,@in_VideoURL        
           ,@in_StartTime       
           ,@in_Seconds         
           ,@in_State           
           ,@in_Finished        
           ,@in_StartDate       
           ,@in_StartHour       
           ,@in_Backuped        
           ,@in_Checked         
           ,@in_Direction       
           ,@in_ProjId          
           ,@in_Inbound         
           ,@in_Outbound        
           ,@in_Flag            
           ,@in_Extension       
           ,@in_VoiceType       
           ,@in_Acd             
           ,@in_UCID            
           ,@in_UUI   
           ,@in_NeedEncry          
	       ,@in_DataEncrypted
           ,@in_EncryKey) 
-- END  : Add Encryed Record information to Target DB

--BEGIN: Get Rec Infomation from Source DB ADD to Target DB
--
--         INSERT INTO [AddressGroupRec]
--                               ([recordid],[address],[groupid])
--                   SELECT [recordid],[address],[groupid]
--                    FROM [Visionlog].[dbo].[AddressGroupRec]
--         WHERE [recordid]=@In_RecordID
--
--         INSERT INTO [AgentGroupRec]
--                                     ([recordid],[agentid],[groupid])
--                    SELECT [recordid],[agentid],[groupid]
--                     FROM [Visionlog].[dbo].[AgentGroupRec]
--         WHERE [recordid]=@In_RecordID
--
--         INSERT INTO [TaskRec]
--                               ([taskid],[recordid])
--                   SELECT [taskid],[recordid]
--                     FROM [Visionlog].[dbo].[TaskRec]
--                   WHERE [recordid]=@In_RecordID      
--END  : Get Rec Infomation from Source DB ADD to Target DB

END



GO
/****** Object:  StoredProcedure [dbo].[usp_ENC_RecordInfo_Get]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ENC_RecordInfo_Get]  
	@startdate INT = 0,  
	@recordid INT = 0  
AS  
	DECLARE @m_BufferCount int
	DECLARE @m_LastGetDT datetime
BEGIN

	SELECT TOP 1 @m_LastGetDT = [StartTime] FROM [ENC_LastRecordDT] 

	IF (ISNULL(@m_LastGetDT,0)!=0)
	BEGIN
		SELECT TOP 100
			   [RecordId]
			  ,[Calling]
			  ,[Called]
			  ,[Answer]
			  ,[Master]
			  ,[Channel]
			  ,[RecURL]
			  ,[ScrURL]
			  ,[VideoURL]
			  ,[StartTime]
			  ,[Seconds]
			  ,[State]
			  ,[Finished]
			  ,[StartDate]
			  ,[StartHour]
			  ,[Backuped]
			  ,[Checked]
			  ,[Direction]
			  ,[ProjId]
			  ,[Inbound]
			  ,[Outbound]
			  ,[Flag]
			  ,[Extension]
			  ,[VoiceType]
			  ,[Acd]
			  ,[UCID]
			  ,[UUI]
			  ,[NeedEncry]
			  ,[DataEncrypted]
			  ,0 AS [EncryKey]
		into #TEMP_A
		--FROM [VXILVDRS7].[Visionlog].[dbo].[Records]
		--实际生产环境需要加上需要加密的源数据库Link
		--In Product System , need add the source db-link which need to be ENC
		FROM [dbo].[Records]
		WHERE [StartTime] >= @m_LastGetDT AND [Finished]>=1

		SELECT  @m_LastGetDT=MAX([StartTime]) FROM #TEMP_A 
	    
		IF(ISNULL( @m_LastGetDT,0)!=0)
		BEGIN  
			UPDATE [ENC_LastRecordDT] SET [StartTime]= @m_LastGetDT
		END

		SELECT * FROM #TEMP_A ORDER BY [StartTime]
	END


END













GO
/****** Object:  StoredProcedure [dbo].[usp_ENC_StorageInfo_Get]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ENC_StorageInfo_Get]  

AS  

BEGIN
--Please note: Before enable the following Script need first 
--             create source DB link XXXXX
         SELECT A.[FtpId]
                     ,A.[Station]
                     ,A.[Folder]
                     ,A.[Drive]
                     ,A.[RealFolder]
                     ,A.[Priority]
                     ,A.[Username]
                     ,A.[Password]
                     ,A.[Enabled]
                     ,A.[StorageType]
					 ,B.[IP]
           --FROM [VXILVDRS7].[Visionlog].[dbo].[Storage] A,[VXILVDRS7].[Visionlog].[dbo].[Station] B
		   --实际生产环境需要加上需要加密的源数据库Link
		   --In Product System , need add the source db-link which need to be ENC
		   FROM [dbo].[Storage] A, [dbo].[Station] B
           WHERE A.[Station] = B.[Station]


END



GO
/****** Object:  StoredProcedure [dbo].[usp_get_acd]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_acd] 
	@Acd varchar(20) = null 
AS  
	if @Acd is not null  set @Acd  = ltrim(rtrim(@Acd))  
	select * from Acd  
		where Acd = isnull(@Acd, Acd)  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_get_address]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_address]  
	@Address varchar(20) = null 
AS  
	if @Address is not null set @Address = rtrim(ltrim(@Address)) 
	select a.*, n.Station 
		from Address a left join Station n on a.Station = n.Station 
		where Address = isnull(@Address, Address)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_addressgroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_addressgroup]  
	@GroupID int = 0  
AS  
	if @GroupID=0 begin  
		select * from AddressGroup  
	end  
	else begin  
		select * from AddressGroup  
			where GroupID = @GroupID  
	end  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_agent]    Script Date: 2016/12/13 10:09:14 ******/
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
	select a.* from Agent a left join Acd b on a.Acd=b.Acd  
		where AgentID = isnull(@AgentID, AgentID)  
		and Enabled = isnull(@Enabled, Enabled)  
	order by a.agentid 
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_agentbygroupid]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create PROCEDURE [dbo].[usp_get_agentbygroupid]  
         @GroupId int = 0
AS  
         begin  
                   select * from groupagent  
                   where GroupId = @GroupId 
         end  
         select @@rowcount counts

GO
/****** Object:  StoredProcedure [dbo].[usp_get_agentgroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_agentgroup]  
	@GroupID int = 0  
AS  
	if @GroupID=0 begin  
		select distinct a.groupid, a.groupname  from agentgroup a 
		order by  groupname 
	end  
	else begin  
		select * from agentgroup  
		where GroupID = @GroupID  
		 order by  groupname 
	end  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_agentgroupbyname]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





create PROCEDURE [dbo].[usp_get_agentgroupbyname]  
         @GroupName varchar(100)  
AS  
         begin  
                   select * from agentgroup  
                   where charindex(',' + GroupName + ',', ',' + @GroupName + ',') > 0
                   order by  groupname 
         end  
         select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_agents_all]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_agents_all]  
	@LogID int = 0  
AS  
	declare @groups_all varchar(2000)  
	set @groups_all = (select groups from supervisor where logid=@logID)  
	set @groups_all = isnull(@groups_all, '')  
	set @groups_all = ltrim(rtrim(@groups_all))  
	if (@groups_all !='')  
             		set @groups_all = 'select distinct agentid from groupagent where groupid in (' + @groups_all+ ')'  
	else  
		set @groups_all = ' '  
	execute(@groups_all)


GO
/****** Object:  StoredProcedure [dbo].[usp_get_alltaskagents]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_alltaskagents]  
	@taskID int = 0,  
	@taskName varchar(20)=null  
AS  
	if @taskID !=0  
		select DISTINCT b.agentid   
			from taskitem a, groupagent b   
			where a.taskid=@taskID and b.groupid=a.agentgroupid  
	else   
		select DISTINCT b.agentid   
			from task t, taskitem a, groupagent b   
			where t.taskName= @taskName and  a.taskID = t.taskID  and b.groupid=a.agentgroupid  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_get_alltaskagents_alone]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_alltaskagents_alone]
	@taskID int = 0
AS  
	--  Get all agents is one task and not in other tasks
	if exists (select top 1 * from taskitem where taskid = @taskID and agentid is not null and agentid !='')
		select agentid 
			from taskitem 
			where taskid = @taskID
				and agentid not in(select distinct agentid from taskitem where taskid!=@taskID and agentid is not null and agentid!='')
				and agentid not in(select DISTINCT b.agentid  from taskitem a, groupagent b  where a.taskid!=@taskID and b.groupid=a.agentgroupid and AgentGroupID !=0)
	else
		select DISTINCT b.agentid   
			from taskitem a, groupagent b   
			where a.taskid=@taskID and b.groupid=a.agentgroupid
				and b.agentid not in(select distinct agentid from taskitem where taskid!=@taskID and agentid is not null and agentid!='')
				and b.agentid not in(select DISTINCT b.agentid  from taskitem a, groupagent b  where a.taskid!=@taskID and b.groupid=a.agentgroupid and AgentGroupID !=0)


GO
/****** Object:  StoredProcedure [dbo].[usp_get_alltaskextensions]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_alltaskextensions]  
	@taskID int = 0,  
	@taskName varchar(20)=null  
AS  
	if @taskID !=0  
		select DISTINCT b.address   
			from taskitem a, groupaddress b   
			where a.taskid=@taskID and b.groupid=a.addressgroupid  
	else   
		select DISTINCT b.address  
			from task t, taskitem a, groupaddress b   
			where t.taskName= @taskName and  a.taskID = t.taskID  and b.groupid=a.addressgroupid  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_get_backuprecords]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_backuprecords]  
	@date varchar(8) = ''  
AS  
	select * from records where startdate = @date  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_billproj]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_billproj]
	@ProjId int = 0
AS
	select * from BillProj where projId = (case @ProjId when 0 then projId else @ProjId end)


GO
/****** Object:  StoredProcedure [dbo].[usp_get_cti]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_cti] 
	@ctiName char(32) = null 
AS  
	if @ctiName is not null  set @ctiName  = ltrim(rtrim(@ctiName))  
		select * from CTI 
			where ctiName = isnull(@ctiName, ctiName)  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_get_ctilink]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_ctilink] 
	@LinkName char(32) = null 
AS  
	if @LinkName is null   set @LinkName = '' 
	set @LinkName  = ltrim(rtrim(@LinkName))  
	select * from CTILink 
		where LinkName = case @LinkName when '' then LinkName else @LinkName end 
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_get_filter]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_filter] 
AS
	select * from filter order by phone


GO
/****** Object:  StoredProcedure [dbo].[usp_get_ftpserver]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_ftpserver]   
AS  
	declare @ftpid int
	set @ftpid = (select top 1 audiourl as id  from records where audioUrl is not null and audioUrl != '' order by recordid desc) 
	select b.ip as 'ftpip', folder, username, password from storage a left join station b on a.station=b.station where ftpid = @ftpid


GO
/****** Object:  StoredProcedure [dbo].[usp_get_groupaddress]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_groupaddress]  
	@GroupID int = 0,  
	@Address varchar(20) = null  
AS  
	if @GroupID=0 begin  
		select b.* from GroupAddress a, addressgroup b  
			where a.Address = @Address and b.GroupID= a.GroupID  
	end  
	else begin  
		select b.* from GroupAddress a, Address b  
			where a.GroupID = @GroupID and b.Address= a.Address  
	end  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_groupagent]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_groupagent] 
	@GroupID int = 0,  
	@AgentID varchar(20) = ''  
AS  
	if (@GroupID=0 and @AgentID='') begin 
		select distinct groupid, agentid  from groupagent order by groupid, agentid 
	end 
	else if @GroupID=0 begin  
		select a.groupid, b.groupname, a.* from GroupAgent a, AgentGroup b  
		where a.AgentID = @AgentID and b.GroupID= a.GroupID  
		order by b.groupname 
	end  
	else begin  
		select * from GroupAgent a, Agent b  
		where a.GroupID = @GroupID and b.AgentID= a.AgentID  
		order by b.agentid 
	end  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_grouptrunk]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_grouptrunk] 
	@GroupID int
AS
	select tg.groupid, t.trunkid, tg.station  from TrunkGroup tg, Trunk t 
	where t.trunkGroup = @GroupID
		and tg.GroupID = @GroupID 	
		order by trunkid


GO
/****** Object:  StoredProcedure [dbo].[usp_get_label]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_label]  
	@RecordID int = 0  
AS  
	select l.*, s.loguser  
		from label l left join supervisor s on s.logid=l.userid  
		where l.recordid= (case @recordID when 0 then l.recordid else @RecordID end) order by l.label


GO
/****** Object:  StoredProcedure [dbo].[usp_get_labelinfo]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_labelinfo] 
	@RecordID int = 0 
AS 
	if (not exists (select top 1 * from monitor where recordid=@RecordID)) 
		select 0 as flag 
	else begin 
		if (exists (select top 1 * from formrec where recordid=@RecordID)) 
			select * from formrec where recordid=@RecordID 
		else 
			select 1 as flag 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_get_maxmsgid]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_maxmsgid]  
AS  
	return 0


GO
/****** Object:  StoredProcedure [dbo].[usp_get_menu]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_menu] 
AS 
	select * from menu


GO
/****** Object:  StoredProcedure [dbo].[usp_get_monitor]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_monitor]  
	@logid int = 0, 
	@userid int = 0,  
	@datefrom datetime = null,  
	@dateto datetime = null,  
	@orderby varchar(20) = null  
AS  
	declare @members varchar(800)  
	set @members = '' 
	if (@logid !=1) begin 
		set @members = (select members from supervisor where logid=@logid)  
		set @members = ltrim(rtrim(isnull(@members, '')))  
		if (@members = '0')  
			set @logid = 1  
	end 
	set @orderby = isnull(@orderby, '') 
	if (@orderby = 'qd') begin 
		select userid as id, count(distinct recordid) calls, sum(datediff(second, timestart, timeend)) as diff  from monitor  
			where (userid = case @userid when 0 then userid else @userid end)  
				and timestart between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' 
				and (charindex(','+ltrim(rtrim(str(userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(userid))) else @members end)+',')>0 or userid=@logid) 
			group by userid order by userid 
		select userid as id,  sum(case (flag&1) when 0 then 0 else 1 end) flag1, sum(case (flag&2) when 0 then 0 else 1 end) flag2, sum(case (flag&4) when 0 then 0 else 1 end) flag3 from FormRec 
			where (userid = case @userid when 0 then userid else @userid end)   
				and (updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59') 
				and (charindex(','+ltrim(rtrim(str(userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(userid))) else @members end)+',')>0 or userid=@logid) 
			group by userid 
		select userid as id, count(distinct labelid) as labels from label 
			where userid=(case @Userid when 0 then userid else @Userid end)  
				and updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59'  
				and (charindex(','+ltrim(rtrim(str(userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(userid))) else @members end)+',')>0 or userid=@logid) 
			group by userid 
		select logid as id, loguser as name from supervisor 
	end 
	else if (@orderby = 'group') begin 
		select g.groupid as id, count(distinct g.recordid) calls, sum(datediff(second, m.timestart, m.timeend)) as diff from monitor m left join AgentGroupRec g on g.recordid=m.recordid 
			where  (userid = case @userid when 0 then userid else @userid end)   
				and m.timestart between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59'  
				and (charindex(','+ltrim(rtrim(str(m.userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(m.userid))) else @members end)+',')>0 or m.userid=@logid) 
			group by g.groupid order by g.groupid 
		select g.groupid as id,  sum(case (f.flag&1) when 0 then 0 else 1 end) flag1, sum(case (f.flag&2) when 0 then 0 else 1 end) flag2, sum(case (f.flag&4) when 0 then 0 else 1 end) flag3 from FormRec f right join AgentGroupRec g on g.recordid=f.recordid   
			where  (userid = case @userid when 0 then userid else @userid end)   
				and (f.updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59') 
				and (charindex(','+ltrim(rtrim(str(f.userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(f.userid))) else @members end)+',')>0 or f.userid=@logid) 
			group by g.groupid 
		select g.groupid as id, count(distinct labelid) as labels from AgentGroupRec g, label l   
			where l.userid = (case @userid when 0 then l.userid else @userid end)   
				and l.recordid=g.recordid  
				and (l.updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' ) 
				and (charindex(','+ltrim(rtrim(str(l.userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(l.userid))) else @members end)+',')>0 or l.userid=@logid) 
			group by g.groupid 
		select groupid as id, groupname as name from AgentGroup 
	end 
	else if (@orderby = 'task') begin 
		select t.taskid as id, count(distinct t.recordid) calls, sum(datediff(second, m.timestart, m.timeend)) as diff from monitor m left join TaskRec t on t.recordid=m.recordid  
			where  (userid = case @userid when 0 then userid else @userid end)  
				and m.timestart between  @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' 
				and (charindex(','+ltrim(rtrim(str(m.userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(m.userid))) else @members end)+',')>0 or m.userid=@logid) 
			group by t.taskid 
		select t.taskid as id,  sum(case (f.flag&1) when 0 then 0 else 1 end) flag1, sum(case (f.flag&2) when 0 then 0 else 1 end) flag2, sum(case (f.flag&4) when 0 then 0 else 1 end) flag3 from FormRec f right join TaskRec t on t.recordid=f.recordid  
			where (userid = case @userid when 0 then userid else @userid end)   
				and (f.updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59') 
				and (charindex(','+ltrim(rtrim(str(f.userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(f.userid))) else @members end)+',')>0 or f.userid=@logid) 
			group by t.taskid 
		select  t.taskid as id, count(distinct labelid) as labels from taskrec t,  label l   
			where l.userid = (case @userid when 0 then l.userid else @userid end)   
				and l.recordid=t.recordid  
				and (l.updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' ) 
				and (charindex(','+ltrim(rtrim(str(l.userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(l.userid))) else @members end)+',')>0 or l.userid=@logid) 
			group by t.taskid 
		select taskid as id, taskname as name from task 
	end 
	select 9999 as id, count(distinct recordid) calls, sum(datediff(second, timestart, timeend)) as diff  from monitor  
		where  timestart between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' 
			and (userid = case @userid when 0 then userid else @userid end)  
			and (charindex(','+ltrim(rtrim(str(userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(userid))) else @members end)+',')>0 or userid=@logid) 
	select 9999 as id, sum(case (flag&1) when 0 then 0 else 1 end) flag1, sum(case (flag&2) when 0 then 0 else 1 end) flag2, sum(case (flag&4) when 0 then 0 else 1 end) flag3 from FormRec 
		where  (updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59') 
			and (userid = case @userid when 0 then userid else @userid end)  
			and (charindex(','+ltrim(rtrim(str(userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(userid))) else @members end)+',')>0 or userid=@logid) 
	select 9999 as id, count(distinct labelid) as labels from label   
		where updatedate between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' 
			and (userid = case @userid when 0 then userid else @userid end)  
			and (charindex(','+ltrim(rtrim(str(userid)))+',', ','+(case @logid when 1 then ltrim(rtrim(str(userid))) else @members end)+',')>0 or userid=@logid)



GO
/****** Object:  StoredProcedure [dbo].[usp_get_project]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_project]
	@ProjId int = 0
AS
	select * from Project 
	where projId = (case @ProjId when 0 then projId else @ProjId end)
		and Enabled = 1


GO
/****** Object:  StoredProcedure [dbo].[usp_get_projectitem]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_projectitem]
	@ID int
AS
	select *  from projectitem 
	where projId = @ID
	order by type,value


GO
/****** Object:  StoredProcedure [dbo].[usp_get_projitemtype]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_projitemtype] 
AS
	select * 
	from projitemtype
	order by type


GO
/****** Object:  StoredProcedure [dbo].[usp_get_record_info]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[usp_get_record_info]
	-- Add the parameters for the stored procedure here
	@RecordId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select re.startDate,re.channel,vt.typename, st.folder,st.username,st.password,sta.ip from Records re left join VoiceType vt on re.voicetype = vt.typeid 
	left join storage st on st.ftpid = re.videourl left join station sta on sta.station = st.station where re.recordid=@RecordId
END




GO
/****** Object:  StoredProcedure [dbo].[usp_get_record_maxid]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_record_maxid]  
AS  
	declare @maxid int  
	set @maxid = isnull((select max(RecordId) from records), 0)  
	select @maxid maxid  
	return @maxid


GO
/****** Object:  StoredProcedure [dbo].[usp_get_records]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Example: exec usp_get_records 0 ,''
CREATE PROCEDURE [dbo].[usp_get_records]  
	@RecordID bigint = 0,
	@UCID varchar(20) = '' 
AS  
	if @RecordID != 0 begin		
		select distinct r.recordid, r.calling, r.called, r.master, r.channel, 
			r.starttime, r.seconds, r.startdate, r.acd, r.uui,
			ltrim(rtrim(isnull(p1.ip, ''))) au_ip, ltrim(rtrim(isnull(s1.folder, ''))) au_folder,
			ltrim(rtrim(isnull(p2.ip, ''))) vu_ip, ltrim(rtrim(isnull(s2.folder, ''))) vu_folder,
			ltrim(rtrim(isnull(p3.ip, ''))) su_ip, ltrim(rtrim(isnull(s3.folder, ''))) su_folder,
			ltrim(rtrim(isnull(p1.extip, ''))) au_extip, ltrim(rtrim(isnull(p2.extip, ''))) vu_extip,
			ltrim(rtrim(isnull(p3.extip, ''))) su_extip,
			 a.agentname, v.typename, v.ext, v.wavbit, v.code, r.ucid,r.projid,r.filecount,
			 r.RecFlag,r.ScrFlag,r.VideoFlag,r.needEncry,r.dataEncrypted,r.encryKey		 
		from records r 
			left join connection c on c.recordid = r.recordid 
			left join agentgrouprec g on g.recordid=r.recordid			
			left join agent a on a.agentid=r.master 
			left join storage s1 on s1.ftpid = r.recurl --录音
			left join storage s2 on s2.ftpid = r.videourl --视频
			left join storage s3 on s3.ftpid = r.scrurl --截屏
			left join station p1 on s1.station = p1.station  
			left join station p2 on s2.station = p2.station
			left join station p3 on s3.station = p3.station
			left join voicetype v on r.voicetype = v.typeid
		where  r.recordid = @RecordID
	end else begin
		select distinct r.recordid, r.calling, r.called, r.master, r.channel, 
			r.starttime, r.seconds, r.startdate, r.acd, r.uui,
			ltrim(rtrim(isnull(p1.ip, ''))) au_ip, ltrim(rtrim(isnull(s1.folder, ''))) au_folder,
			ltrim(rtrim(isnull(p2.ip, ''))) vu_ip, ltrim(rtrim(isnull(s2.folder, ''))) vu_folder,
			ltrim(rtrim(isnull(p3.ip, ''))) su_ip, ltrim(rtrim(isnull(s3.folder, ''))) su_folder,
			ltrim(rtrim(isnull(p1.extip, ''))) au_extip, ltrim(rtrim(isnull(p2.extip, ''))) vu_extip, 
			ltrim(rtrim(isnull(p3.extip, ''))) su_extip,
			 a.agentname, v.typename, v.ext, v.wavbit, v.code, r.ucid,r.filecount,
			 r.RecFlag,r.ScrFlag,r.VideoFlag,r.needEncry,r.dataEncrypted,r.encryKey	 
		from records r 
			left join connection c on c.recordid = r.recordid 
			left join agentgrouprec g on g.recordid=r.recordid			
			left join agent a on a.agentid=r.master 
			left join storage s1 on s1.ftpid = r.recurl --录音
			left join storage s2 on s2.ftpid = r.videourl --视频
			left join storage s3 on s3.ftpid = r.scrurl --截屏
			left join station p1 on s1.station = p1.station  
			left join station p2 on s2.station = p2.station
			left join station p3 on s3.station = p3.station
			left join voicetype v on r.voicetype = v.typeid
		where  r.ucid = @UCID	
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_Get_ScreenFailStation]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


create PROCEDURE [dbo].[usp_Get_ScreenFailStation]  
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
/****** Object:  StoredProcedure [dbo].[usp_get_station]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_station] 
	@IP varchar(15) = null,  
	@Station varchar(20) = null 
AS  
	if @IP is not null  set @IP  = ltrim(rtrim(@IP))  
	if @Station is not null set @Station = ltrim(rtrim(@Station))  
		select * from Station 
			where IP  = isnull(@IP, IP)  
			and Station = isnull(@Station, Station)  order by Station
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_storage]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_get_storage] 
	@FtpId tinyint = 0 
AS  
SELECT [FtpId]
      ,[Station]
      ,[Folder] 
      ,[Drive]
      ,[Priority]
      ,[Username]
      ,[Password]
      ,[Enabled]
      ,[AutoBackup]
      ,[DestFolder]
      ,[BackupDays]
      ,[BackupTime]
      ,[AudioKeepDays]
      ,[FileType]
      ,[StorageType]
	  ,[VideoKeepDays]	
	  ,[RealFolder]
	  ,[DataEncry]
  FROM  storage 
		where FtpId = case @FtpId when 0 then FtpId else @FtpId end 
	return




GO
/****** Object:  StoredProcedure [dbo].[usp_get_supervisor]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_get_supervisor]  
	@LogID int = 0,  
	@LogName varchar(20) = null,  
	@LogPass varchar(20) = null  
AS  
	if @LogID=0 begin  
		select * from supervisor  
	end  
	else begin  
		select * from supervisor 	 
			where LogID = @LogID  
	end  
	select @@rowcount counts

GO
/****** Object:  StoredProcedure [dbo].[usp_get_supvisortasks]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_get_supvisortasks]
	@logId int = 0
AS   
	declare @tasks varchar(500)
	select @tasks = tasks from supervisor where logId = @logId
	set @tasks = ltrim(rtrim(isnull(@tasks, '')))
	if @tasks != '' 
		select taskname 
		from task 
		where charindex(','+ltrim(rtrim(convert(varchar, taskid)))+',', ','+@tasks+',')>0
	else 
		select * from task where taskid<0

GO
/****** Object:  StoredProcedure [dbo].[usp_get_system]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_get_system]   
AS  
	select * from [system]

GO
/****** Object:  StoredProcedure [dbo].[usp_get_task]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_get_task]  
	@TaskID int = 0,  
	@TaskName varchar(20) = null,  
	@enabled bit = 1  
AS  
	declare @sch varchar(200)  
	if @enabled = 1  
		set @sch = ' and enabled = 1'  
	else  
		set @sch = ''  
	
	if isnull(@TaskName, '') = '' begin  
		if @TaskID!=0  
			set @sch = ' where TaskID = ' + str(@TaskID)  
		else   
			set @sch = ' where TaskID = TaskID ' + @sch  
		set @sch = 'select *, DATEDIFF(hh, date_start + '' '' + time_start ,  date_end + '' '' +  time_end)  hours  from task ' + @sch  
	end 	  
	else begin  
		set @sch = 'select *,  DATEDIFF(hh, date_start + '' '' + time_start ,  date_end + '' '' +  time_end)  hours  from task  where TaskName = ''' + @TaskName + ''''  
	end  
	set @sch = @sch + ' order by taskName'   
	execute(@sch)  
	select @@rowcount counts




GO
/****** Object:  StoredProcedure [dbo].[usp_get_taskitem]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_taskitem]  
	@TaskID int = 0,  
	@TaskName varchar(20) = null  
AS  
	if @TaskName is null  
		select  b.* from Task a, TaskItem b   
			where a.TaskID = @TaskID and b.TaskID= a.TaskID  
	else  
		select  b.* from Task a, TaskItem b   
			where a.TaskName = @TaskName and b.TaskID= a.TaskID



GO
/****** Object:  StoredProcedure [dbo].[usp_get_tasks]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_tasks]  
	@Type  varchar(10),
	@ObjID int = 0
AS   
	set @Type = ltrim(rtrim(@Type))
	if (@Type = 'agentgroup')
		select t.taskid, taskname from taskitem i left join task t  on t.taskid=i.taskid where i.AgentGroupId=@ObjID
	else if (@Type = 'addressgroup')
		select t.taskid, taskname from taskitem i left join task t  on t.taskid=i.taskid where i.AddressGroupId=@ObjID 
	else if (@Type = 'trunkgroup')
		select t.taskid, taskname from taskitem i left join task t  on t.taskid=i.taskid where i.TrunkGroupId=@ObjID


GO
/****** Object:  StoredProcedure [dbo].[usp_get_trunk]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_trunk]  
	@TrunkID int = 0
AS  
	if @TrunkID=0 
		select * from trunk order by trunkid
	else
		select * from trunk
		where trunkid = @TrunkID  order by trunkid


GO
/****** Object:  StoredProcedure [dbo].[usp_get_trunkgroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_get_trunkgroup]  
	@GroupID int = 0  
AS  
	if @GroupID=0 begin  
		select * from TrunkGroup  
	end  
	else begin  
		select * from TrunkGroup  
			where GroupID = @GroupID  
	end  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_vdn]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_vdn]  
	@vdn varchar(20) = null 
AS  
	if @vdn is not null     set @vdn     = ltrim(rtrim(@vdn))  
	select * from vdn  
		where vdn = isnull(@vdn, vdn)  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_get_voicetype]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_voicetype]  
	@TypeName	varchar(10),
	@TypeId	tinyint = 0
	
AS
	set @TypeName = ltrim(rtrim(isnull(@TypeName, '')))
	if (@TypeName != '')
		select top 1 * from VoiceType
		where typename = @TypeName
	else if (@TypeId != 0)
		select top 1 * from VoiceType
		where TypeId = @TypeId
	else
		select * from VoiceType where enabled = 1


GO
/****** Object:  StoredProcedure [dbo].[usp_get_vpbchannel]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_vpbchannel]  
	@Channel varchar(20) = null,  
	@Station varchar(20) = null  
AS  
	if @Channel is not null set @Channel = rtrim(ltrim(@Channel));  
	if @Station   is not null set @Station   = rtrim(ltrim(@Station))  
		select * from VPBChannel  
		where Channel = isnull(@Channel, Channel)  
		and Station   = isnull(@Station, Station)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_get_worklogs]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_get_worklogs]  
	@userid int = 0,  
	@datefrom datetime = null,  
	@dateto datetime = null,  
	@orderby varchar(20) = null  
AS  
	select * from worklogs where userid=@userid and [datetime] >= @datefrom and [datetime]<@dateto --/order by @@orderby  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_groupaddress_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_groupaddress_delete]  
	@GroupID int = 0,  
	@Address varchar(20) = null  
AS  
	if  @GroupID=0  
		delete groupaddress from groupaddress where Address = @Address  
	else  
		delete groupaddress from groupaddress where GroupID = @GroupID  
	 return


GO
/****** Object:  StoredProcedure [dbo].[usp_groupaddress_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_groupaddress_insert]  
	@GroupID int = 0,  
	@Address varchar(20) = null  
AS  
	insert into  GroupAddress (GroupID, Address)  values (@GroupID, @Address)


GO
/****** Object:  StoredProcedure [dbo].[usp_groupagent_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_groupagent_delete]  
	@GroupID int = 0,  
	@AgentID varchar(20) = null  
AS  
	if  @GroupID=0  
		delete groupagent  where AgentID = @AgentID  
	else  
		delete groupagent where GroupID = @GroupID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_groupagent_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_groupagent_insert]  
	@GroupID int = 0,  
	@AgentID varchar(20),  
	@TimeType tinyint = 0, 
	@TimeFrom varchar(5) = '', 
	@TimeTo varchar(5) = '', 
	@Weeks smallint = 0 
AS  
	insert into GroupAgent (GroupID,  AgentID, TimeType, TimeFrom, TimeTo, Weeks)  values (@GroupID, @AgentID, @TimeType, @TimeFrom, @TimeTo, @Weeks)


GO
/****** Object:  StoredProcedure [dbo].[usp_grouptrunk_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_grouptrunk_delete]
	@GroupID int
AS
	delete trunk where trunkGroup=@GroupID


GO
/****** Object:  StoredProcedure [dbo].[usp_init]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_init] 
	@LineMode int = 0
AS 
	delete supervisor 
	execute usp_supervisor_insert @loguser='admin',@logpass='E08C9E12032C21383141',@privilege=3887, @agents='', @groups='', @tasks='', @members='',  @type=0 

	delete  [system] 
	insert [system] ([key], type, value) Values ('Version', 'char', '3.1.01.001') 
	insert [system] ([key], type, value) Values ('UpdateDate', 'date', getdate()) 
	insert [system] ([key], type, value) Values ('RecordsUpdatePeriod', 'int', '3')

	delete projitemtype
	insert projitemtype (Type, TypeName) Values (1, 'trunk')
	insert projitemtype (Type, TypeName) Values (2, 'ext')
	insert projitemtype (Type, TypeName) Values (3, 'agent')
	insert projitemtype (Type, TypeName) Values (4, 'acd')
	insert projitemtype (Type, TypeName) Values (5, 'channel')
	insert projitemtype (Type, TypeName) Values (6, 'called')
	insert projitemtype (Type, TypeName) Values (7, 'vdn')

	delete project
	insert project (projId, projName, Description, Enabled) Values (-1, 'Unknown', 'Couldn''t be sure which project this record belongs to.',1)

	delete voicetype
	insert voicetype values (0, 'mp3' , 'mp3', 8, 0, 'MicroSoft Wave, Compress MS8BitWAV to mp3', 1)
	insert voicetype values (1, 'wav' , 'wav', 8, 0, 'MicroSoft Wave, MS8BitWAV', 1)
	insert voicetype values (2, 'g729a' , 'g729a', 16, 4, 'G.729A 8000 bps', 1)
	insert into voicetype values (3, 'vxi', 'vxi', 16, 4, 'VXI 8000 bps', 1)

GO
/****** Object:  StoredProcedure [dbo].[usp_init_menu]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_init_menu]
	@MenuType int = 0
AS 
	declare @TYPE_PASSIVE int, @TYPE_EXTENSION int,  @TYPE_CTI_ENABLED int,@TYPE_PROJECT_ENABLED int
	declare @TYPE_AGENT_ENABLED int, @TYPE_BILL_ENABLED int,  @TYPE_MONITOR_ENABLED int
	set @TYPE_PASSIVE 	  		= 1
	set @TYPE_EXTENSION 		= 2
	set @TYPE_CTI_ENABLED 		= 4
	set @TYPE_AGENT_ENABLED		= 8
	set @TYPE_BILL_ENABLED		= 16
	set @TYPE_MONITOR_ENABLED	= 32
	set @TYPE_PROJECT_ENABLED	= 64

	-- See Also usp_schedule_records_daily_update

	-- passive
	set @MenuType = isnull(@MenuType, '')
	delete menu 
	insert into menu values ('010000','task',0,' ',' ',0,0,0,'','','C') 
	insert into menu values ('010100','new',0,' ','S',0,0,0,'task.jsp','new',' ') 
	insert into menu values ('010200','open',0,' ','P',400,90,1,'','',' ') 
	insert into menu values ('010300','save',0,'010100,010200','P',400,90,1,'saveTask()','',' ') 
	insert into menu values ('010400','saveas',0,'010100,010200','P',400,90,1,'save.jsp','',' ') 
	insert into menu values ('010500','-',0,' ',' ',0,0,0,'','',' ') 
	insert into menu values ('010600','tasklist',0,' ','S',0,0,0,'','',' ') 
	insert into menu values ('010700','-',0,'',' ',0,0,0,'','',' ') 
	insert into menu values ('010800','close',0,'',' ',0,0,0,'closeSystem()','','A') 

	insert into menu values ('020000','report',0,' ',' ',0,0,0,'','','C') 
	insert into menu values ('020100','realtime',0,' ','S',0,0,0,'','','C') 
	if (@MenuType &  @TYPE_MONITOR_ENABLED) !=0
		insert into menu values ('020200','agentstate',0,' ','S',0,0,0,'','','C') 
	insert into menu values ('020300','-',0,'',' ',0,0,0,'','',' ') 
	insert into menu values ('020400','history',0,' ','S',0,0,0,'','','C') 
	insert into menu values ('020500','statistics',0,' ','S',0,0,0,'statistic.jsp','','C') 
	insert into menu values ('020600','monitor',0,' ',' ',0,0,0,'works.jsp','','C') 
	if ((@MenuType &  @TYPE_BILL_ENABLED) !=0) begin
		insert into menu values ('020700','-',0,'',' ',0,0,0,'','',' ') 
		insert into menu values ('020800','billsch',0,' ',' ',0,0,0,'','','C') 
		insert into menu values ('020900','bill',0,' ',' ',0,0,0,'','','C') 
		insert into menu values ('021000','records',0,' ','S',0,0,0,'','','C') 
	end
	if ((@MenuType &  @TYPE_PROJECT_ENABLED)  !=0 ) begin
		insert into menu values ('021100','-',0,'',' ',0,0,0,'','',' ') 
		insert into menu values ('021200','match',0,' ','S',0,0,0,'','','C') 
	end

	insert into menu values ('030000','setup',0,' ','S',0,0,0,'','','C') 
	insert into menu values ('030100','password',0,'','P',360,220,0,'','','A') 
	insert into menu values ('030200','-',0,'',' ',0,0,0,'','',' ') 
	insert into menu values ('030300','supervisor',0,' ','S',0,0,0,'supervisor_list.jsp','',' ') 
	insert into menu values ('030400','-',0,'',' ',0,0,0,'','',' ') 
	if ((@MenuType &  @TYPE_CTI_ENABLED) !=0) begin
		insert into menu values ('030500','vdn',0,' ','S',0,0,0,'vdn_list.jsp','',' ') 
		insert into menu values ('030600','acd',0,' ','S',0,0,0,'acd_list.jsp','',' ') 
	end
	if ((@MenuType &  @TYPE_CTI_ENABLED) !=0 or  (@MenuType &  @TYPE_AGENT_ENABLED) !=0) begin
		insert into menu values ('030700','agent',0,' ','S',0,0,0,'agent_list.jsp','',' ') 
		insert into menu values ('030800','group',0,' ','S',0,0,0,'group_list.jsp','',' ') 
	end
	insert into menu values ('030900','station',0,' ','S',0,0,0,'station_list.jsp','',' ') 
	insert into menu values ('031000','storage',0,' ','S',0,0,0,'storage_list.jsp','',' ') 
	if ((@MenuType &  @TYPE_PASSIVE) =0 ) begin
		insert into menu values ('031100','channel',0,' ','S',0,0,0,'channel_list.jsp','',' ') 
	end
	insert into menu values ('031200','extension',0,' ','S',0,0,0,'extension_list.jsp','',' ') 
	insert into menu values ('031300','extgroup',0,' ','S',0,0,0,'extgroup_list.jsp','',' ') 
	if ((@MenuType &  @TYPE_PASSIVE)  !=0 ) begin
		insert into menu values ('031400','trunkgroup',0,' ','S',0,0,0,'trunkgroup_list.jsp','',' ') 
		insert into menu values ('031500','trunk',0,' ','S',0,0,0,'trunk_list.jsp','',' ') 
	end
	insert into menu values ('031600','-',0,'',' ',0,0,0,'','',' ') 
	insert into menu values ('031700','filter',0,' ','P',400,310,1,'','',' ') 
	insert into menu values ('031800','freespace',0,' ','P',570,320,1,'','',' ') 
	if ((@MenuType &  @TYPE_PROJECT_ENABLED)  !=0 ) begin
		insert into menu values ('031900','-',0,'',' ',0,0,0,'','',' ') 
		insert into menu values ('032000','project',0,' ','S',0,0,0,'project_list.jsp','',' ') 
	end

	insert into menu values ('040000','system',0,' ',' ',0,0,0,'','','C') 
	--insert into menu values ('040100','logs',0,' ','S',0,0,0,'logs_view.jsp','',' ') 
	--insert into menu values ('040200','-',0,' ',' ',0,0,0,'','',' ') 

	insert into menu values ('040300','backup',0,'','P',420, 350,1,'maintain_files.jsp','','')
	-- insert into menu values ('040300','backup',0,'',' ',0,0,0,'','',' ') 
	--insert into menu values ('040301','record',0,' ','P',440,335,1,'backup_record.jsp','',' ') 
	--insert into menu values ('040302','database',0,' ','P',420,260,1,'backup_database.jsp','',' ') 
	--insert into menu values ('040303','logs',0,' ','P',440,280,1,'backup_logs.jsp','',' ') 
	--insert into menu values ('040304','complete',0,' ','P',420,330,1,'backup_complete.jsp','',' ') 

	insert into menu values ('050000','help',0,' ',' ',0,0,0,'','','A') 
	insert into menu values ('050100','help',0,'  ','O',800,600,0,'','','A') 
	insert into menu values ('050200','-',0,'',' ',0,0,0,'','','A') 
	insert into menu values ('050300','about',0,' ','P',300,430,1,'','','A')



GO
/****** Object:  StoredProcedure [dbo].[usp_Login]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_Login]  
	@LogUser varchar(20),
	@LogPass varchar(50)
AS  
	declare @password varchar(50), @LastDate datetime, @today datetime, @overdue datetime, @ErrTimes int, @Locked bit, @validays int, @logid int

	set @today = getdate()
	select @logid = logid, @password = logpass, @ErrTimes = isnull(ErrTimes, 0), @LastDate = isnull(LastDate, @today), @Locked = isnull(Locked, 0), @validays = isnull(Validays, 30) 
		from supervisor where LogUser = @LogUser 
	set @overdue = dateadd(dd, @validays + 1, @LastDate)

	if @logid > 1 begin
		if @LogPass != @password begin
			if @Locked = 0 and  @overdue > @today begin
				update supervisor set ErrTimes = @ErrTimes + 1,  Locked = case when @ErrTimes  < 2 then 0 else 1 end where LogUser = @LogUser
			end
		end
		else if @Locked = 0 begin
			update supervisor set ErrTimes = 0, Locked = 0 where LogUser = @LogUser
		end
	end

	select * from supervisor where LogUser = @LogUser

GO
/****** Object:  StoredProcedure [dbo].[usp_mix_get_record]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_mix_get_record]
	@RecordId int = 0
AS
BEGIN
	SELECT * FROM Records WHERE RecordId = @RecordId
END
GO
/****** Object:  StoredProcedure [dbo].[usp_monitor_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_monitor_insert]  
	@userid int = 0,  
	@recordid int = 0,  
	@agentid varchar(20) = null,  
	@timestart datetime = null,  
	@timeend datetime = null  
AS  
	insert monitor  (userid, agentid, recordid, timestart, timeend) values (@userid, @agentid, @recordid, @timestart, @timeend)  
	select max(monitorid) as monitorid from monitor


GO
/****** Object:  StoredProcedure [dbo].[usp_monitor_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_monitor_update]  
	@monitorid int = 0,  
	@timeend datetime = null  
AS  
	update monitor set timeend=@timeend where monitorid=@monitorid


GO
/****** Object:  StoredProcedure [dbo].[usp_package_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_package_insert]  
	@RecordId	int, 
	@date datetime,
	@filesize bigint,
	@username varchar(50),
	@success bit
AS  
Begin
	INSERT INTO [PackageRec]
           ([recordid]
           ,[date]
           ,[filesize]
           ,[username]
           ,[success])
     VALUES
           (@recordid
           ,@date
           ,@filesize
           ,@username
           ,@success)
	Select * from [PackageRec] where recordid=@recordid
End	

GO
/****** Object:  StoredProcedure [dbo].[usp_project_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_project_delete]
	@ProjId int
AS
	if exists (select top 1 * from records where projid = @ProjId) 
		update Project
		set enabled = 0
		where ProjId = @ProjId
	else begin
		delete projectitem where ProjId = @ProjId
		delete Project where ProjId = @ProjId
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_project_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_project_insert]
	@ProjName varchar(50),
	@Description varchar(1000) = null,
	@Items tinyint,
	@Head01 varchar(50),
	@Head02 varchar(50),
	@Head03 varchar(50),
	@Head04 varchar(50),
	@Head05 varchar(50),
	@Head06 varchar(50),
	@Head07 varchar(50),
	@Head08 varchar(50),
	@Head09 varchar(50),
	@Head10 varchar(50)
AS
	declare @ProjId int
	select @ProjId = (isnull(max(projId), 0)) + 1 from Project
	if @ProjId < 1 set @ProjId = 1

	if not exists (select top 1 * from project where ProjName = @ProjName or ProjId = @ProjId) begin 
		insert into Project (ProjId, ProjName,Items
           ,Head01
           ,Head02
           ,Head03
           ,Head04
           ,Head05
           ,Head06
           ,Head07
           ,Head08
           ,Head09
           ,Head10, Description, Enabled) values (
			@ProjId, @ProjName,
			@Items,
			@Head01,
			@Head02,
			@Head03,
			@Head04,
			@Head05,
			@Head06,
			@Head07,
			@Head08,
			@Head09,
			@Head10,
			@Description, 1)  
		select @ProjId 'result' 
	end 
	else  
		select 0 'result' 
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_project_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_project_update]	
	@ProjName varchar(50),
	@Description varchar(1000) = null,
	@Items tinyint,
	@Head01 varchar(50),
	@Head02 varchar(50),
	@Head03 varchar(50),
	@Head04 varchar(50),
	@Head05 varchar(50),
	@Head06 varchar(50),
	@Head07 varchar(50),
	@Head08 varchar(50),
	@Head09 varchar(50),
	@Head10 varchar(50),
	@ProjId int
AS
	if not exists (select top 1 * from project where ProjName = @ProjName and ProjId != @ProjId) begin 
		update Project
		set ProjName = @ProjName,
			Items=@Items,
			Head01=@Head01,
			Head02=@Head02,
			Head03=@Head03,
			Head04=@Head04,
			Head05=@Head05,
			Head06=@Head06,
			Head07=@Head07,
			Head08=@Head08,
			Head09=@Head09,
			Head10=@Head10,
			Description = @Description
		where ProjId = @ProjId

		select 1 'result' 
	end 
	else  
		select 0 'result' 
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_projectitem_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_projectitem_delete]  
	@ProjID int
AS  
	  delete ProjectItem where ProjID = @ProjID
	  return


GO
/****** Object:  StoredProcedure [dbo].[usp_projectitem_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_projectitem_insert]  
	@ProjId 	int,
	@Type 		smallint,
	@Value  	varchar(50), 
	@AssociateId 	int = 0
AS  
	insert into ProjectItem (ProjID, Type, Value, AssociateId)  
		values (@ProjID, @Type, ltrim(rtrim(@Value)), @AssociateId)
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_QA_Login]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_QA_Login]  
	@LogUser varchar(20)
	--@LogPass varchar(20)
AS  
	declare @password varchar(50), @LastDate datetime, @today datetime, @overdue datetime, @ErrTimes int, @Locked bit, @validays int, @logid int

	set @today = getdate()
	--select @logid = logid, @password = logpass, @ErrTimes = isnull(ErrTimes, 0), @LastDate = isnull(LastDate, @today), @Locked = isnull(Locked, 0), @validays = isnull(Validays, 30) 
		--from supervisor where LogUser = @LogUser 
	if not exists(select * from supervisor where LogUser = @LogUser) begin
		select (select (max(logid) + 1) logid from supervisor) [LogID]
			  ,@LogUser [LogUser]
			  ,'' [LogPass]
			  ,'274' [Privilege]
			  ,'0' [Type]
			  ,'' [Agents]
			  ,'' [Groups]
			  ,'' [Tasks]
			  ,'' [Members]
			  ,'' [IsQD]
			  ,@today [LastDate]
			  ,'30' [Validays]
			  ,'0' [ErrTimes]
			  ,'0' [Locked]
	end
	else begin 
		select * from supervisor where LogUser = @LogUser
	end

GO
/****** Object:  StoredProcedure [dbo].[usp_RecAdditional_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Sean Xiao (zhimin.xiao@vxichina.com)
-- Create date: 2016-02-19 11:00:00
-- Description:	Provide RecAdditional Table value insert by Yearly
-- =============================================
CREATE PROCEDURE [dbo].[usp_RecAdditional_insert]
	-- Add the parameters for the stored procedure here 
    @inRecordId   INT         = 0,
    @inCallId     INT         = 0, 
    @inCtrlDevice VARCHAR(50) = '',
    @inDevice     VARCHAR(50) = '',
    @inEventType  INT         = 0,
    @inStartTime  INT         = 0,
    @inTimeLen    INT         = 0	
AS
    DECLARE @mYearly VARCHAR(4) ,@TableName VARCHAR(50),@mSQL VARCHAR(1000)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SET @mYearly = SUBSTRING(CONVERT(VARCHAR(100), GETDATE(), 112),1,4)
	SET @TableName = 'RecAdditional_'+ @mYearly

	IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].['+@TableName+']') AND TYPE in (N'U'))
    BEGIN
        -- IF the table RecAdditional_YYYY not exist, then build new table SQL script by yearly
		SET @mSQL= 'CREATE TABLE [dbo].[RecAdditional_'+@mYearly+'](
						[Id] [int] IDENTITY(1,1) NOT NULL,
						[RecordId] [int] NOT NULL,
						[CallId] [int] NULL,
						[CtrlDevice] [varchar](50) NULL,
						[Device] [varchar](50) NULL,
						[EventType] [int] NOT NULL,
						[StartTime] [int] NOT NULL,
						[TimeLen] [int] NOT NULL,
					 CONSTRAINT [PK_RecAdditional_'+@mYearly+'] PRIMARY KEY CLUSTERED 
					(
						[Id] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
					) ON [PRIMARY]

					CREATE NONCLUSTERED INDEX [PK_RecAdditional_'+@mYearly+'_RecordId] ON [dbo].[RecAdditional_2016]
					(
						[RecordId] ASC
					)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]'
		PRINT @mSQL
		EXEC(@mSQL)
    END

	-- Build value insert SQL script by yearly and parameters
	SET @mSQL=	'INSERT INTO [dbo].['+@TableName+']
				   ([RecordId]
				   ,[CallId]
				   ,[CtrlDevice]
				   ,[Device]
				   ,[EventType]
				   ,[StartTime]
				   ,[TimeLen])
				 VALUES
				   ('  + CONVERT(VARCHAR(10),@inRecordId)  +'  
				   ,'  + CONVERT(VARCHAR(10),@inCallId)    +'    
				   ,'''+                     @inCtrlDevice +'''
				   ,'''+                     @inDevice     +'''    
				   ,'  + CONVERT(VARCHAR(10),@inEventType) +' 
				   ,'  + CONVERT(VARCHAR(10),@inStartTime) +' 
				   ,'  + CONVERT(VARCHAR(10),@inTimeLen)   +')'   
    
	PRINT @mSQL
	EXEC(@mSQL)
    
  
END


GO
/****** Object:  StoredProcedure [dbo].[usp_recexts_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- =============================================
-- Author:		wenyong xia
-- Create date: 2007 12/07
-- Description:	recexts insert or update
-- =============================================
CREATE PROCEDURE [dbo].[usp_recexts_insert]  
	-- Add the parameters for the stored procedure here
	@RecordId int = null,
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
	@Enabled bit = 1,
	@ucid varchar(30) = null
AS
BEGIN
	if @RecordId is not null and @RecordId != 0 and exists(select 1 from RecExts where RecordId = @RecordId  ) begin
		update RecExts set 
			Handler = isnull(@Handler,Handler),
			ucid   = isnull(@ucid, ucid),
			Item01 = isnull(@Item01,Item01),
			Item02 = isnull(@Item02,Item02),
			Item03 = isnull(@Item03,Item03),
			Item04 = isnull(@Item04,Item04),
			Item05 = isnull(@Item05,Item05),
			Item06 = isnull(@Item06,Item06),
			Item07 = isnull(@Item07,Item07),
			Item08 = isnull(@Item08,Item08),
			Item09 = isnull(@Item09,Item09),
			Item10 = isnull(@Item10,Item10),
			Note = isnull(@Note,Note),
			Enabled = isnull(@Enabled,Enabled)
		where RecordId = @RecordId and ucid=@ucid
	end
	else if @ucid is not null and exists(select 1 from RecExts where ucid = @ucid) begin
		update RecExts set 
			Handler = isnull(@Handler,Handler),
			ucid   = isnull(@ucid, ucid),
			Item01 = isnull(@Item01,Item01),
			Item02 = isnull(@Item02,Item02),
			Item03 = isnull(@Item03,Item03),
			Item04 = isnull(@Item04,Item04),
			Item05 = isnull(@Item05,Item05),
			Item06 = isnull(@Item06,Item06),
			Item07 = isnull(@Item07,Item07),
			Item08 = isnull(@Item08,Item08),
			Item09 = isnull(@Item09,Item09),
			Item10 = isnull(@Item10,Item10),
			Note = isnull(@Note,Note),
			Enabled = isnull(@Enabled,Enabled)
		where RecordId = @RecordId and ucid=@ucid		
	end
	else begin

		if @RecordId is not null begin
			insert into RecExts(RecordId,ucid, Handler, Item01, Item02, Item03, Item04, 
				Item05, Item06,	Item07, Item08, Item09, Item10, Note, ItemTime, Enabled )
			 values(@RecordId, @ucid, @Handler, @Item01, @Item02, @Item03, @Item04, 
				@Item05, @Item06, @Item07, @Item08, @Item09, @Item10, @Note, getdate(), isnull(@Enabled,1))
		end
	end

END






GO
/****** Object:  StoredProcedure [dbo].[usp_records_append]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_records_append] 
	@DateFrom int = 0,  
	@DateTo int = 0
AS
	declare @today datetime, @yesterday datetime
	select @today = dateadd(dd, -1, getdate()), @yesterday = dateadd(dd, -2, getdate())

	if @DateFrom = 0 begin
		select @DateFrom = year(@yesterday) * 10000 + month(@yesterday) * 100 + day(@yesterday)
	end
	if @DateTo = 0 begin
		select @DateTo = year(@today) * 10000 + month(@today) * 100 + day(@today)
	end

	update records
		set extension = c.device
		from records r left join connection c on r.recordid = c.recordid and r.master = c.agent 
		where r.extension = '' and r.master != '' and len(c.device) < 6
			and r.startdate between @DateFrom and @DateTo

	update connection
		set agent = r.master
		from records r, connection c
		where r.recordid = c.recordid 
			and r.extension = c.device
			and r.master != ''
			and c.agent != r.master
			and r.startdate between @DateFrom and @DateTo

	insert into connection
		select top 1000 r.recordid, r.extension, '' phone, r.master agent, 1 enter, r.seconds leave
			from records r left join connection c on r.recordid = c.recordid and r.extension = c.device
			where r.master != '' and c.agent is null and r.extension != ''
				and r.startdate between @DateFrom and @DateTo


GO
/****** Object:  StoredProcedure [dbo].[usp_records_connection_save]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_records_connection_save]
	@RecordID int
AS
	declare @Calling varchar(50), @Called varchar(50), @Answer varchar(50), @Seconds int
	select @Calling = isnull(calling, ''), @Called = isnull(called, ''),  @Answer = isnull(answer, ''), @Seconds = seconds from records where recordid = @RecordID
	if @@RowCount = 1 begin
		if @Calling != '' and substring(@Calling, 1, 1) !='T'
			insert into connection (recordid, device, phone, agent, enter, leave) values (@RecordID, @Calling, @Calling, '', 0, @Seconds)
		if @Called != '' and substring(@Called, 1, 1) !='T' and @Called != @Calling
			insert into connection (recordid, device, phone, agent, enter, leave) values (@RecordID, @Called, @Called, '', 0, @Seconds)
		else if @Answer != '' and substring(@Answer, 1, 1) !='T' and @Answer != @Calling
			insert into connection (recordid, device, phone, agent, enter, leave) values (@RecordID, @Answer, @Answer, '', 0, @Seconds)
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_records_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_records_delete]  
	@RecordID varchar(20)  
AS  
	set @RecordID = ltrim(rtrim(@RecordID))  
	delete Records  
		 from Records  
 		where RecordID = @RecordID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_records_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create PROCEDURE [dbo].[usp_records_insert]  
	@RecordId		int, 
	@Calling		varchar(50) = '', 
	@Called			varchar(50) = '', 
	
	@CallID	int = -1,
	@Trunk int = -1,
	@SessionID int = -1,
	@RecordStartTime nvarchar(23) ='',
	@RecordSeconds int = -1,
	@FileCount	smallint = -1,
	@VideoFlag	tinyint = -1,
	@StartDate	int = -1,
	@StartHour	tinyint = -1,
	@Extension	varchar(20) = '',
	@AttendAgent	varchar(256) ='',
	@AttendDevice	varchar(256) = '',
	
	@Answer			varchar(50) = '', 
	@Master			varchar(20) = '', 
	@Channel		varchar(10) = '',
	@RecURL			smallint = 0,
	@ScrURL			smallint = 0,  
	@VideoURL		smallint = 0, 
	@TrsStation     varchar(50) = '',
	@StartTime		nvarchar(23) ='', 
	@Seconds		int = 0, 
	@Direction		int = 0,
	@Inbound		int = 0,
	@Outbound		int = 0,
	@Acd			varchar(20) = '',
	@Vdn			varchar(20) = '',	
	@VoiceType 		varchar(10) = '',
	@ucid			varchar(20) = '',
	@uui			varchar(100) = ''
AS
begin
	if object_id('tempdb.dbo.#Temp1') is not null 
	 begin
	  drop table #Temp1;
	 end
	create table #Temp1(ProjId int,DataEncry bit);
	if object_id('tempdb.dbo.#Temp2') is not null 
	 begin
	  drop table #Temp2;
	 end
	create table #Temp2(SiteID int);
	
	with c as
	(
		select a.ProjId from dbo.ProjectItem a
		inner join dbo.ProjItemType b on a.[type] = b.[type] and b.[type]=3
		where a.Value = @Master /*@Master*/
		group by a.ProjId
	)
	insert into #Temp1(ProjId,DataEncry)
	select top 1 d.ProjId,d.DataEncry from c inner join dbo.Project d on c.ProjId = d.ProjId;

	if not exists(select top 1 ProjId from #Temp1)
	begin
		with c as
		(
			select a.ProjId from dbo.ProjectItem a
			inner join dbo.ProjItemType b on a.[type] = b.[type] and b.[type]=4
			where a.Value = @Acd /*@Acd*/
			group by a.ProjId
		)
		insert into #Temp1(ProjId,DataEncry)
		select top 1 d.ProjId,d.DataEncry from c inner join dbo.Project d on c.ProjId = d.ProjId
	end;
	
	insert into #Temp2(SiteID)
	select top 1 SiteID from dbo.SiteRelated where SiteType=2 and RelatedID = @Master;

	if not exists(select SiteID from #Temp2)
	begin
		insert into #Temp2(SiteID)
		select top 1 a.SiteID from dbo.SiteRelated a where a.SiteType=1
			and exists(select GroupID from dbo.GroupAgent where AgentID = @Master and GroupID = a.RelatedID)
	end;

	declare @DataEncrypted int,@ProjId int,@SiteID int;
	select @ProjId = ProjId,@DataEncrypted = DataEncry from #Temp1;
	select @SiteID = SiteID from #Temp2;
	BEGIN TRY
        BEGIN TRANSACTION;
		update dbo.Records
		set
		Calling = case when @Calling !='' then @Calling else Calling end
		,Called = case when @Called !='' then @Called else Called end
		,Answer = case when @Answer !='' then @Answer else Answer end
		,[Master] = case when @Master !='' then @Master else [Master] end
		,Acd = case when @Acd !='' then @Acd else Acd end
		,Channel = case when @Channel !='' then @Channel else Channel end
		,VDN = case when @VDN !='' then @VDN else VDN end
		,CallID = case when @CallID !=-1 then @CallID else CallID end
		,Trunk = case when @Trunk !=-1 then @Trunk else Trunk end
		,SessionID = case when @SessionID !=-1 then @SessionID else SessionID end
		,RecURL = case when @RecURL !=0 then @RecURL else RecURL end
		,ScrURL = case when @ScrURL !=0 then @ScrURL else ScrURL end
		,VideoURL = case when @VideoURL !=0 then @VideoURL else VideoURL end
		,TrsStation = case when @TrsStation !='' then @TrsStation else TrsStation end
		,RecordStartTime = case when @RecordStartTime !='' then @RecordStartTime else RecordStartTime end
		,StartTime = case when @StartTime !='' then @StartTime else StartTime end
		,RecordSeconds = case when @RecordSeconds !=-1 then @RecordSeconds else RecordSeconds end
		,Seconds = case when @Seconds !=0 then @Seconds else Seconds end
		,FileCount = case when @FileCount !=-1 then @FileCount else FileCount end
		,VideoFlag = case when @VideoFlag !=-1 then @VideoFlag else VideoFlag end
		,StartDate = case when @StartDate !=-1 then @StartDate else StartDate end
		,StartHour = case when @StartHour !=-1 then @StartHour else StartHour end
		,Direction = case when @Direction !=0 then @Direction else Direction end
		,Inbound = case when @Inbound !=0 then @Inbound else Inbound end
		,Outbound = case when @Outbound !=0 then @Outbound else Outbound end
		,Extension = case when @Extension !='' then @Extension else Extension end
		,VoiceType = case when @VoiceType !='' then @VoiceType else VoiceType end
		,UCID = case when @UCID !='' then @UCID else UCID end
		,UUI = case when @UUI !='' then @UUI else UUI end
		,AttendAgent = case when @AttendAgent !='' then @AttendAgent else AttendAgent end
		,AttendDevice = case when @AttendDevice !='' then @AttendDevice else AttendDevice end
		,DataEncrypted = @DataEncrypted
		,SiteID = @SiteID
		,ProjId = @ProjId
		where RecordId = @RecordId;
		
		if not exists(select top 1 RecordId from dbo.Records where RecordId = @RecordId)
		begin
			insert into dbo.Records(RecordId,Calling,Called,CallID,Trunk,SessionID,RecordStartTime,RecordSeconds,FileCount,VideoFlag,StartDate,StartHour,Extension,AttendAgent,AttendDevice,Answer,Master,Channel,RecURL,ScrURL, VideoURL,TrsStation,StartTime,Seconds,Direction,Inbound,Outbound,Acd,Vdn,VoiceType,ucid,uui)
			values(@RecordId,@Calling,@Called,@CallID,@Trunk,@SessionID,@RecordStartTime,@RecordSeconds,@FileCount,@VideoFlag,@StartDate,@StartHour,@Extension,@AttendAgent,@AttendDevice,@Answer, @Master, @Channel,@RecURL,@ScrURL,  @VideoURL, @TrsStation,@StartTime, @Seconds, @Direction,@Inbound,@Outbound,@Acd,@Vdn,@VoiceType,@ucid,@uui);
		end;
       COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
        BEGIN
            ROLLBACK TRANSACTION;
        END
    END CATCH;	
	drop table #Temp1;
	drop table #Temp2;
end


GO
/****** Object:  StoredProcedure [dbo].[usp_records_insert_bak20161111]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_records_insert_bak20161111]  
	@RecordId		int, 
	@Calling		varchar(50) = '', 
	@Called			varchar(50) = '', 
	@Answer			varchar(50) = '', 
	@Master			varchar(20) = '', 
	@Channel		varchar(10) = '',
	@RecURL			smallint = 0,
	@ScrURL			smallint = 0,  
	@VideoURL		smallint = 0, 
	@TrsStation     varchar(50) = '',
	@StartTime		datetime = null, 
	@Seconds		int = 0, 
	@State			int = 0, 
	@Finished		tinyint = 0, 
	@Tasks			varchar(50) = '', 
	@Direction		int = 0,
	@Inbound		int = 0,
	@Outbound		int = 0,
	@Acd			varchar(20) = '',
	@Vdn			varchar(20) = '',	
	@VoiceType 		varchar(10) = 'mp3',
	@ucid			varchar(20) = '',
	@uui			varchar(100) = '',
	@NeedEncry		bit = 0,
    @DataEncrypted	int = 0,
	@EncryKey		varchar(256) = ''
AS  
	declare @StartDate varchar(8), @StartHour tinyint, @ProjId int
	declare @Flag bit, @Rchannel varchar(10), @TrunkGroup smallint, @Extension varchar(20)
	declare @Groups varchar(50), @GroupID varchar(10)  
	declare @VoiceTypeId int,  @OldMaster varchar(20)
	--declare @Direction int
	--set @Direction = 0

	if isnull(@RecordId, 0) = 0  
		set @RecordId = isnull((select max(RecordId) from Records), 0) + 1  

	set @Channel		= ltrim(rtrim(isnull(@Channel, '')))
	set @Calling		= ltrim(rtrim(isnull(@Calling, '')))
	set @Called			= ltrim(rtrim(isnull(@Called, '')))
	set @Inbound		= isnull(@Inbound, 0)
	set @Outbound		= isnull(@Outbound, 0)
    set @DataEncrypted	= isnull(@DataEncrypted, 0)
	set @Acd			= rtrim(ltrim(isnull(@Acd, '')))
	set @Vdn			= rtrim(ltrim(isnull(@Vdn, '')))
	set @Master			= rtrim(ltrim(isnull(@Master, '')))
	set @uui			= rtrim(ltrim(isnull(@uui, '')))
	set @ucid			= rtrim(ltrim(isnull(@ucid, '')))

	-- Get Data & Hour
	set @StartDate = str(DATEPART(yy, @StartTime),4) + substring(str(100+DATEPART(mm, @StartTime),3),2,2) + substring(str(100+DATEPART(dd, @StartTime),3),2,2)  
	set @StartHour = datepart(hh, @StartTime)

	select top 1 @OldMaster = Master from Records where RecordID = @RecordID

	if (1 = 1) or @Finished > 0  begin 
		-- 总是执行此段代码，防止@Finished为0时，取不到分机

		-- Set Project and Inbound / Outbound
		if (1 = 1) or  /*exists (select top 1 * from projectitem) and*/ @Finished>0 begin
			-- 总是执行此段代码，防止@Finished为0时，取不到分机

			-- Get Trunk
			set @TrunkGroup = 0
			if @Channel != '' and @Channel != '0' begin
				if exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Channel like ltrim(rtrim([value])) and typename = 'channel' and pr.enabled=1) or exists (select top 1 * from vpbchannel where convert(varchar, channel) = @Channel) begin
					set @Rchannel = @Channel
					set @Outbound = 1
				end
		
				if @Rchannel is null
					set @TrunkGroup = @Channel/1000
			end
		
			-- Get Flag: 
			set @Flag = 0
			if @Inbound =0 and @Outbound = 0 begin
				set @Flag = 1
		             		--if exists (select top 1 * from BillVDN where TrunkGroup=@TrunkGroup and @called like '%' + phone)
					--set @Inbound = 1
			end
	
			-- Get Device
			--if (@Master is not null and @Master !=0)
			--	select @Extension = device from [connection] where recordid = @RecordId and agent = @Master
		
			set @Extension = rtrim(ltrim(isnull(@Extension, '')))
	
			if @Calling != ''  begin
				if exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Calling like ltrim(rtrim([value])) and typename = 'ext' and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = @Calling) begin
					set @Extension = @Calling
					set @Outbound = 1
				end		
			end
			if @Called != ''  begin
				if exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Called like ltrim(rtrim([value])) and typename = 'ext' and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = @Called) begin
					set @Extension = @Called
					set @Inbound = 1
				end
			end
			if (@Extension = '') begin
				if @Answer != ''  
					if exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Answer like ltrim(rtrim([value])) and typename = 'ext' and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = @Answer)
						set @Extension = @Answer
			end
			set @Extension = rtrim(ltrim(isnull(@Extension, '')))
			set @Rchannel = rtrim(ltrim(isnull(@Rchannel, '')))
	

			-- Get ProjID
			set @ProjID = dbo.GetProject(@TrunkGroup, @Acd, @Master, @Extension, @Rchannel, @Called, @Vdn, @StartTime)
	
			if (@Extension = '' and @Rchannel != '')
				set  @Extension = @Rchannel
		end
		else begin
			set @Extension  = ''
			set @Rchannel  = ''
			set @Flag = 0
		end
	end

	set @ProjID = isnull(@ProjID, -1)
	if (@ProjID = 0) set @ProjID = -1
	set @Extension = rtrim(ltrim(isnull(@Extension, '')))
	set @Flag = isnull(@Flag, 0)
	--if @Inbound = 0 and @Outbound = 0
	--	set @Outbound = 1
	
	-- Get Voice Type	
	set @VoiceType =  ltrim(rtrim(isnull(@VoiceType, '')))
	if (@VoiceType = '') set @VoiceType = 'mp3'

	select top 1 @VoiceTypeId = typeId from VoiceType where typename = @VoiceType
	set @VoiceTypeId = isnull(@VoiceTypeId, 0)

	if @OldMaster is null begin
		---- Insert Records -----
		insert into Records (RecordId,Calling,Called,Answer,Master,Acd, Channel,RecURL,ScrURL,VideoURL,TrsStation,StartTime,Seconds,State,Finished,StartDate,StartHour,Backuped,Checked,Direction, VoiceType, Extension, Inbound, Outbound,Flag, ProjId, ucid, uui, NeedEncry,DataEncrypted,EncryKey,TaskID) 
	      		values (@RecordId,@Calling,@Called,@Answer, @Master,@Acd, @Channel,@RecURL,@ScrURL,@VideoURL,@TrsStation,@StartTime,@Seconds,@State,@Finished,@StartDate,@StartHour,0,0,@Direction, @VoiceTypeId, @Extension, @Inbound, @Outbound, @Flag, @ProjId, @ucid, @uui, @NeedEncry, @DataEncrypted,@EncryKey,@Tasks)

		-- Update Task Rec
		if (@Tasks is not null and @Tasks!='') begin
			declare @ExecStr varchar(500)  
			set @ExecStr = 'insert into TaskRec (TaskID, RecordID) select TaskID, ' + ltrim(str(@RecordId)) + ' RecordID from Task where TaskID in (' + @Tasks + ')'  
			exec (@ExecStr)  
		end

		-- Set AgentGroupRec
		--if not exists (select top 1 * from AgentGroupRec where RecordId = @RecordId and AgentId = @Master) begin
			insert AgentGroupRec (RecordId, AgentId, GroupId)
				select distinct @RecordId as RecordId,  AgentId, GroupId
				from GroupAgent
				where AgentId = @Master 
					and GroupId is not null 
					and ((TimeType=0)  
						or (TimeType=1 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
						or (TimeType=2 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&weeks!=0) )) 
		--end

	end
	else begin
		---- Update Records ----
		update Records set 
			Calling			= @Calling,
			Called			= @Called,
			Answer			= @Answer,
			Master			= @Master,
			Channel			= @Channel,
			RecURL			= @RecURL,
			ScrURL			= @ScrURL,
			VideoURL 		= @VideoURL,
			TrsStation      = @TrsStation,
			StartTime		= @StartTime, 
			Seconds    		= @Seconds,
			State      		= @State,
			Finished   		= @Finished,
			StartDate  		= @StartDate,  
			StartHour		= @StartHour, 
			ProjId			= @ProjID,
			Inbound 		= @Inbound,
			Outbound		= @Outbound,
			Flag			= @Flag,
			Extension		= @Extension,
			VoiceType		= @VoiceTypeId,
			Acd				= @Acd,
			UCID			= @ucid,
			UUI				= @uui,
			NeedEncry		= @NeedEncry,
            DataEncrypted	= @DataEncrypted,
			EncryKey		= @EncryKey,
			TaskID			= @Tasks
		where RecordID = @RecordID
	end
	
	--if (@OldMaster is null or @OldMaster = 0) and @Master !=0  begin 
	--	-- Set AgentGroupRec
	--	--if not exists (select top 1 * from AgentGroupRec where RecordId = @RecordId and AgentId = @Master) begin
	--		insert AgentGroupRec (RecordId, AgentId, GroupId)
	--			select distinct @RecordId as RecordId,  AgentId, GroupId
	--			from GroupAgent
	--			where AgentId = @Master 
	--				and GroupId is not null 
	--				and ((TimeType=0)  
	--					or (TimeType=1 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
	--					or (TimeType=2 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&weeks!=0) )) 
	--	--end
	--end
	
	return
GO
/****** Object:  StoredProcedure [dbo].[usp_records_recount]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_records_recount] 
	@DatetimeStart datetime,
	@DatetimeEnd datetime
AS

	 -- Set Inbound or Outbound
	update records 
	set Inbound = 0, outbound = 0, extension = ''
	where flag = 1 or Inbound is null or outbound is null
		and starttime between @DatetimeStart and @DatetimeEnd

	update records set flag = 1 
	where Inbound = 0 and outbound = 0
		and starttime between @DatetimeStart and @DatetimeEnd

	
	--update records set Inbound = 1, flag = 1 
	--where ((Inbound = 0 and outbound = 0)  or (flag = 1))
	--	and called != ''
	--	and exists (select trunkgroup from BillVDN where called like '%' + phone)
	--	and starttime between @DatetimeStart and @DatetimeEnd
	
		
	-- Set ProjID
	update records 
	set extension = calling, outbound = 1 
	where calling !=''
		and exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId  inner join projItemType t on t.type=p.type  where calling like ltrim(rtrim([value])) and (typename = 'ext') and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = calling)
		and starttime between @DatetimeStart and @DatetimeEnd
		
	update records 
	set extension = called,  Inbound = 1
	where called !=''
		and exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId  inner join projItemType t on t.type=p.type  where called like ltrim(rtrim([value])) and (typename = 'ext') and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = called)
		and starttime between @DatetimeStart and @DatetimeEnd

	update records
	set extension = calling, outbound = 1 
	where calling !=''
		and exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId  inner join projItemType t on t.type=p.type  where calling like ltrim(rtrim([value])) and (typename = 'channel') and pr.enabled=1) or exists (select top 1 * from vpbchannel where convert(varchar, channel) = calling)
		and starttime between @DatetimeStart and @DatetimeEnd

	update records 
	set projID = dbo.GetProject(Channel/1000, 0, Master, Extension, Channel, Called, 0, StartTime)
	where starttime between @DatetimeStart and @DatetimeEnd

	-- 
	update records set outbound  = 1
	where outbound = 0 and Inbound = 0
		and starttime between @DatetimeStart and @DatetimeEnd


GO
/****** Object:  StoredProcedure [dbo].[usp_records_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_records_update] 
	@RecordId	int, 
	@Calling	varchar(50) = null, 
	@Called		varchar(50) = null, 
	@Answer		varchar(50) = null, 
	@Master		varchar(20) = null, 
	@Channel	varchar(10) = 0, 
	@RecURL		smallint = 0,
	@ScrURL		smallint = 0,
	@VideoURL	smallint = 0, 
	@StartTime	datetime = null, 
	@Seconds	int = 0, 
	@State		int = 0, 
	@Finished	tinyint = 0, 
	@Direction	bit = 0,
	@Inbound	bit = 0,
	@Outbound	bit = 0,
	@Acd		varchar(20) = null,
	@Vdn		varchar(20) = null,
	@VoiceType	varchar(10) = null,
	@ucid		varchar(20) = null,
	@uui		varchar(100) = null,	
	@NeedEncry	bit	= 0
AS  
	declare @StartDate varchar(8), @StartHour tinyint, @ProjId int
	declare @Flag bit, @Rchannel varchar(20), @TrunkGroup smallint, @Extension varchar(20)
	declare @VoiceTypeId int

	set @Channel	= ltrim(rtrim(isnull(@Channel, '')))
	set @Calling	= ltrim(rtrim(isnull(@Calling, '')))
	set @Called	= ltrim(rtrim(isnull(@Called, '')))
	set @Inbound	= isnull(@Inbound, 0)
	set @Outbound	= isnull(@Outbound, 0)
	set @Acd	= rtrim(ltrim(isnull(@Acd, '')))
	set @Vdn	= rtrim(ltrim(isnull(@Vdn, '')))
	set @Master	= rtrim(ltrim(isnull(@Master, '')))
	set @uui	= rtrim(ltrim(isnull(@uui, '')))
	set @ucid	= rtrim(ltrim(isnull(@ucid, '')))

	-- Get Data & Hour
	set @StartDate = str(DATEPART(yy, @StartTime),4) + substring(str(100+DATEPART(mm, @StartTime),3),2,2) + substring(str(100+DATEPART(dd, @StartTime),3),2,2)  
	set @StartHour = datepart(hh, @StartTime)  

	-- Voice Type
	set @VoiceType =  ltrim(rtrim(isnull(@VoiceType, '')))
	if (@VoiceType = '') set @VoiceType = 'mp3'
		
	select top 1 @VoiceTypeId = typeId from VoiceType where typename = @VoiceType
	set @VoiceTypeId = isnull(@VoiceTypeId, 0)

	-- Set Project
	if exists (select top 1 * from projectitem) and @Finished>0 begin
		-- Get Trunk
		set @TrunkGroup = 0
		if @Channel != '' and @Channel != '0' begin
			if exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Channel like ltrim(rtrim([value])) and typename = 'channel' and pr.enabled=1) or exists (select top 1 * from vpbchannel where convert(varchar, channel) = @Channel) begin
				set @Rchannel = @Channel
				set @Outbound = 1
			end
	
			if @Rchannel is null
				set @TrunkGroup = @Channel/1000
		end
	
		-- Get Flag: 
		set @Flag = 0
		if @Inbound =0 and @Outbound = 0 begin
			set @Flag = 1
	                        --if exists (select top 1 * from BillVDN where TrunkGroup=@TrunkGroup and @called like '%' + phone)
				--set @Inbound = 1
		end

		-- Get Device
		--if (@Master is not null and @Master !=0)
		--	select @Extension = device from [connection] where recordid = @RecordId and agent = @Master
	
		set @Extension = rtrim(ltrim(isnull(@Extension, '')))

		if @Calling != ''  begin
			if exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Calling like ltrim(rtrim([value])) and typename = 'ext' and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = @Calling) begin
				set @Extension = @Calling
				set @Outbound = 1
			end		
		end
		if @Called != ''  begin
			if exists (select top 1 * from projectitem p inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Called like ltrim(rtrim([value])) and typename = 'ext' and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = @Called) begin
				set @Extension = @Called
				set @Inbound = 1
			end
		end
		if (@Extension = '') begin
			if @Answer != ''  
				if exists (select top 1 * from projectitem p  inner join project pr on pr.projId = p.projId inner join projItemType t on t.type=p.type  where @Answer like ltrim(rtrim([value])) and typename = 'ext' and pr.enabled=1) or exists (select top 1 * from address where convert(varchar, address) = @Answer)
					set @Extension = @Answer
		end
		set @Extension = rtrim(ltrim(isnull(@Extension, '')))
		set @Rchannel = rtrim(ltrim(isnull(@Rchannel, '')))

		-- Get ProjID
		set @ProjID = dbo.GetProject(@TrunkGroup, @Acd, @Master, @Extension, @Rchannel, @Called, @Vdn, @StartTime)

		if (@Extension = '' and @Rchannel != '')
			set  @Extension = @Rchannel
	end
	else begin
		set @Extension  = ''
		set @Rchannel  = ''
		set @Flag = 0
	end

	set @ProjID = isnull(@ProjID, -1)

	if @Inbound =0 and @Outbound = 0
		set @Outbound = 1

	--if (@TrunkGroup != 0)
	--	set @Channel = @TrunkGroup

	-- Update
	update Records set 
		Calling		= isnull(@Calling, Calling),  
		Called		= isnull(@Called, Called),  
		Answer		= isnull(@Answer, Answer),   
		Master		= isnull(@Master, Master),  
		Channel		= isnull(@Channel, Channel),  
		RecURL		= isnull(@RecURL, RecURL),  
		ScrURL      = isnull(@ScrURL, ScrURL), 
		VideoURL 	= isnull(@VideoURL, VideoURL),   
		StartTime	= isnull(@StartTime, StartTime),   
		Seconds    	= isnull(@Seconds, Seconds),   
		State      	= isnull(@State, State),  
		Finished   	= isnull(@Finished, Finished),  
		StartDate  	= @StartDate,  
		StartHour	= @StartHour, 
		Direction 	= isnull(@Direction, Direction),
		ProjId		= @ProjID,
		Inbound 	= @Inbound,
		Outbound	= @Outbound,
		Flag		= @Flag,
		Extension	= isnull(@Extension, Extension),
		VoiceType	= isnull(@VoiceTypeId, VoiceType),
        Acd         = isnull(@Acd, Acd),
		UCID		= isnull(@ucid, UCID),       
		UUI			= isnull(@uui, UUI),
		NeedEncry	= isnull(@NeedEncry, NeedEncry)
	where RecordID = @RecordID

GO
/****** Object:  StoredProcedure [dbo].[usp_relate_database]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_relate_database] AS  
	exec sp_addlinkedserver 'model'  
	exec sp_addlinkedsrvlogin @rmtsrvname = 'model', @useself = 'false', @rmtuser = 'sa', @rmtpassword = 'VisionLog'  
	reconfigure


GO
/****** Object:  StoredProcedure [dbo].[usp_reset_tasks]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_reset_tasks]  
	@Type  varchar(10),
	@ObjID int = 0
AS   
	set @Type = ltrim(rtrim(@Type))
	if (@Type = 'agent')
		delete taskitem where agentid=@ObjID
	else if (@Type = 'address')
		delete taskitem where address=@ObjID
	else if (@Type = 'vdn')
		delete taskitem where vdn=@ObjID
	else if (@Type = 'trunk')
		delete taskitem where trunk=@ObjID
	else if (@Type = 'agentgroup')
		delete taskitem where agentgroupid=@ObjID
	else if (@Type = 'addressgroup')
		delete taskitem where addressgroupid=@ObjID
	else if (@Type = 'trunkgroup')
		delete taskitem where trunkgroupid=@ObjID


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_acd]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_acd]  
	@acd varchar(100) = '',  
	@orderBy varchar(20) = '',  
	@order varchar(20) = '' 
AS  
	declare @sch varchar(2000)  
	if (@acd=null or @acd= '')   
		set @acd = ' acd = acd '  
	else   
		set @acd = ' acd like ''' + ltrim(rtrim(@acd)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'acd'  
	set @sch = 'select * from acd where '  + @acd + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_address]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_address]  
	@address varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = null  
AS  
	declare @sch varchar(2000)  
	if (@address=null or @address= '')   
		set @address = ' address = address '  
	else   
		set @address = ' address like ''' + ltrim(rtrim(@address)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'address'  
	set @sch = 'select * from address where '  + @address + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_addressgroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_addressgroup]  
	@groupName varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = null  
AS  
	declare @sch varchar(2000)  
	if (@groupName=null or @groupName= '')   
		set @groupName = ' groupName = groupName '  
	else   
		set @groupName = ' groupName like ''' + ltrim(rtrim(@groupName)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'groupName'  
	set @sch = 'select * from addressgroup where '  + @groupName + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_agent]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_agent]  
	@agentID varchar(20) = '',  
	@orderBy varchar(20) = null,  
	@order varchar(20) = null  
AS  
	declare @sch varchar(2000)  
	set @agentID = ltrim(rtrim(isnull(@agentID, ''))) 
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'agentId'  
	if @order is null 
		set @order = '' 
	if @agentID is null or @agentID= 0 
		set @sch = 'select * from agent order by ' + @orderBy + '  ' + @order  
	else   
		set @sch = 'select * from agent where agentid like ''' + @agentID + '%''  order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_agentgroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_agentgroup]  
	@groupName varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = null  
AS  
	declare @sch varchar(2000)  
	if (@groupName=null or @groupName= '')   
		set @groupName = ' groupName = groupName '  
	else   
		set @groupName = ' groupName like ''' + ltrim(rtrim(@groupName)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'groupName'  
	set @sch = 'select * from agentgroup where '  + @groupName + ' order by ' + @orderBy + '  ' + @order  
	print @sch  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_bill]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_sch_bill]
	@ProjID	int = 0, 
	@GroupID	int = 0, 
	@AgentID	varchar(20)  = '', 
	@Ext		varchar(20)  = '', 
	@ExtGroup	int = 0, 
	@PhoneNo	varchar(50)  = null, 
	@DateBegin 	varchar(20)  = '20000101', 
	@DateEnd	varchar(20)  = '20790101', 
	@TimeBegin	varchar(20)  = '00:00:00', 
	@TimeEnd	varchar(20)  = '23:59:59.999', 
	@CalltimeFrom	float = 0, 
	@CalltimeTo	float = 0, 
	@TrunkId	int = 0,
	@ShowAll	bit  = 0,
	@InOut		tinyint  = 0,
	@Orderby	varchar(20) = 'BillId'
AS 
	declare  @base varchar(2000), @sum varchar(2500), @sch varchar(2500)
	set @ProjID	= ltrim(rtrim(isnull(@ProjID, 0))) 
	set @AgentID	= ltrim(rtrim(isnull(@AgentID, ''))) 
	set @GroupID	= ltrim(rtrim(isnull(@GroupID, 0))) 
	set @Ext	= ltrim(rtrim(isnull(@Ext, ''))) 
	set @ExtGroup	= ltrim(rtrim(isnull(@ExtGroup, 0))) 
	set @PhoneNo	= ltrim(rtrim(isnull(@PhoneNo, ''))) 
	set @trunkId	= ltrim(rtrim(isnull(@trunkId, 0))) 

	set @base = ' where  (StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')' 

	if @ProjID !=0 
		set @base = @base + ' and r.projid = ' + convert(varchar, @ProjID) 
	if @GroupID !=0 
		set @base = @base + ' and r.agentgroup = ' + convert(varchar, @GroupID) 
	if @AgentID !=0 
		set @base = @base + ' and r.agent  = ' + convert(varchar, @AgentID) 
	if @Ext !=0 
		set @base = @base + ' and r.extension  = ' + convert(varchar, @Ext)
	if @ExtGroup !=0 
		set @base = @base + ' and r.extgroup = ' + convert(varchar, @ExtGroup) 
	if @PhoneNo !='' 
		set @base = @base + ' and (r.calling like ''%' + @PhoneNo + '%'' or r.called like ''%' + @PhoneNo + '%'')' 
	if (@CalltimeTo !=0)  
		set @base = @base + ' and r.seconds between ' + str(@CalltimeFrom*60) + ' and ' + str(@CalltimeTo*60) 
	if (@trunkId !=0) 
		set @base = @base + ' and r.trunkgroup = ' + convert(varchar, @trunkId)

	if (@ShowAll =0)
		set @base = @base  + ' and r.charge>0 and  r.seconds>0 '

	set @sch = 'select distinct r.*, a.agentname, p.projname from bill r left join agent a on a.agentid=r.agent left join project p on p.projid = r.projid  ' + @base + ' order by  r.' + @Orderby + ' desc' 
	execute(@sch) 

	declare @rowcount int
	set @rowcount = @@rowcount
	if (@rowcount>0) 
		set @sum = 'select ' + convert(varchar, @rowcount) + ' counts, sum(r.seconds) as seconds, sum(r.charge) as charge, sum(r.chargeme) as chargeme from bill r ' + @base
	else
		set @sum = 'select ' + convert(varchar, @rowcount) + ' counts'

	execute(@sum)


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_bill_proj]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_sch_bill_proj]
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ProjID int ,
	@CallType int = 0
AS  
	if (@ProjID != 1 or @CallType !=1) begin
		-- not HP or is HP but not transfer		
		if (@ProjID !=1)
			set @CallType = 0

		select * from bill b
		where Starttime between @DateTimeFrom and @DateTimeTo
			and projid = @ProjID
			and charge != 0
			and CallType = (case @CallType when 0 then CallType else @CallType end)
			and outbound = 1 
		order by calling, starttime
	end
	else begin
		-- is HP and Transfer
		select BillId, Called as Calling, Calling as Called,  Agent, Extension, StartTime, Seconds, StartDate, Charge, ChargeMe from bill b
		where Starttime between @DateTimeFrom and @DateTimeTo
			and projid = @ProjID
			and charge != 0
			and CallType = (case @CallType when 0 then CallType else @CallType end)
			and outbound = 1 
		order by called,  calling, starttime
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_cti]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_cti]  
	@CtiName char(32) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = ''  
AS  
	declare @sch varchar(2000)  
	if (@CtiName=null or @CtiName= '')   
		set @CtiName = ' CtiName = CtiName '  
	else   
		set @CtiName = ' CtiName like ''' + ltrim(rtrim(@CtiName)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'CtiName'  
	set @sch = 'select * from CTI where '  + @CtiName + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_ctilink]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_ctilink] 
	@LinkName char(32) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = ''  
AS  
	declare @sch varchar(2000)  
	if (@LinkName=null or @LinkName= '')   
		set @LinkName = ' LinkName = LinkName '  
	else   
		set @LinkName = ' LinkName like ''' + ltrim(rtrim(@LinkName)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'LinkName'  
	set @sch = 'select * from CTIlink where '  + @LinkName + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_monitor]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_monitor]  
  @logid int = 0,  
  @userid int = 0,  
  @datefrom datetime = null,  
  @dateto datetime = null,  
  @orderby varchar(20) = null  
AS  
  declare @members varchar(800)  
  if (@logid !=1) begin 
	set @members = (select members from supervisor where logid=@logid)  
	set @members = ltrim(rtrim(isnull(@members, '')))  
	if (@members = '0')  
		set @logid = 1  
  end 
  select  s.loguser, m.*, datediff(second, m.timestart, m.timeend) as diff, f.flag from monitor m left join supervisor s on s.logid = m.userid  left join formrec f on f.recordid=m.recordid  
	where m.userid = (case @userid when 0 then m.userid else @userid end)   
	and timestart between @datefrom + ' 00:00:00' and @dateto + ' 23:59:59' 
  	and (charindex(','+m.userid+',', ','+(case @logid when 1 then m.userid else @members end)+',')>0 or m.userid=@logid) order by m.userid, m.timestart  
  select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_project]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_sch_project]  
	@ProjName varchar(50) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = '' 
AS  
	declare @sch varchar(2000)  
	if (@ProjName=null or @ProjName= '')   
		set @ProjName = ' ProjName = ProjName '  
	else   
		set @ProjName = ' ProjName like ''' + ltrim(rtrim(@ProjName)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'ProjName'
	set @sch = 'select * from project where '  + @ProjName + ' and enabled=1 order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts



GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example: 
exec VisionLog41..usp_sch_records '0','','','','','','2016-09-01','2016-09-09','00:00','23:59'
,null,'','',0,1439,'','recordId','0','','','','','','','','','','','','','','','','','',''
,'0','30','0','30','0','30','1','','','',1,20,''
*/	 

CREATE PROCEDURE [dbo].[usp_sch_records] 
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
/****** Object:  StoredProcedure [dbo].[usp_sch_records_0907]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example: 
DECLARE @ans int
exec VisionLog40..usp_sch_records_2 '0','','','','','','','2016-08-15','2016-08-19','00:00','23:59','','','',0,1439,
'','recordId','','','','','','','','','','','','',
'',
--'1005,1006,1007',
'',
--'1002,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024,1025,1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1002,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024,1025,1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039,1002,1005,1006,1007,1008,1009,1010,1011,1012,1013,1014,1015,1016,1017,1018,1019,1020,1021,1022,1023,1024,1025,1026,1027,1028,1029,1030,1031,1032,1033,1034,1035,1036,1037,1038,1039',
'','','','','','0','30','0','30','0','30','0','','','',1,10
print @ans;
*/	 
CREATE PROCEDURE [dbo].[usp_sch_records_0907] 
	@LogID				int = 0, 
	@TaskID				int = 0, 
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
	@TrunkGroup_p 		varchar(2000) = '',
	@ProjId				varchar(200) = '',
	@ProjId_p			varchar(200) = '',
	@Acd				varchar(2000) = '',
	@Acd_p				varchar(2000) = '',
	@Direction			varchar(20) = 'all',
	@CustmoerPhone		varchar(50) = '',
	@Calling			varchar(50) = '',
	@Called				varchar(2000) = '',
	@Called_p			varchar(2000) = '',
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
	@EndPage			int =50
	--@TotalPage			int	out
AS
BEGIN
	set @AgentID	= ltrim(rtrim(isnull(@AgentID, '')))
	set @AgentID_p	= ltrim(rtrim(isnull(@AgentID_p, '')))  
	set @Address	= ltrim(rtrim(isnull(@Address, '')))
	set @Address_p	= ltrim(rtrim(isnull(@Address_p, ''))) 
	set @CustmoerPhone	= ltrim(rtrim(isnull(@CustmoerPhone, ''))) 
	set @Calling	= ltrim(rtrim(isnull(@Calling, ''))) 
	set @Label	= ltrim(rtrim(isnull(@Label, ''))) 
	set @TrunkGroup = ltrim(rtrim(isnull(@TrunkGroup, '')))
	set @TrunkGroup_p = ltrim(rtrim(isnull(@TrunkGroup_p, '')))
	set @ProjId =  ltrim(rtrim(isnull(@ProjId, '')))
	set @ProjId_p =  ltrim(rtrim(isnull(@ProjId_p, '')))
	set @Acd	= ltrim(rtrim(isnull(@Acd, '')))
	set @Acd_p	= ltrim(rtrim(isnull(@Acd_p, '')))
	set @Called	= ltrim(rtrim(isnull(@Called, '')))
	set @Called_p	= ltrim(rtrim(isnull(@Called_p, ''))) 
	set @AgentGroupId = ltrim(rtrim(isnull(@AgentGroupId, '')))
	set @AgentGroupId_p = ltrim(rtrim(isnull(@AgentGroupId_p, '')))
	set @AddressGroup = ltrim(rtrim(isnull(@AddressGroup, '')))
	set @AddressGroup_p = ltrim(rtrim(isnull(@AddressGroup_p, '')))
	set @uui	= ltrim(rtrim(isnull(@uui, ''))) 
	set @bAdmin = isnull(@bAdmin, 0)

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
	
	set @sch = 	'select distinct top 100 percent r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel,
						r.RecURL,r.ScrURL,r.VideoURL,r.StartTime,r.Seconds,r.State,
			   			isnull(ra.muteTime, 0) muteTime,isnull(ra.holdTime, 0) holdTime,isnull(ra.conferenceTime, 0) conferenceTime,
			   			r.RecFlag,r.ScrFlag,r.VideoFlag,r.StartDate,r.StartHour,r.Backuped,r.Checked Checked1,r.Direction,r.ProjId,
			   			r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI,
			   			a.agentname,p.projname,isnull(r.DataEncrypted,0) dataencrypted,r.trunk,
			   			null item01, null item02,
			   			null item03, null item04,
			   			null item05, null item06,
			   			null item07, null item08,
			   			null item09, null item10,
			   			null note, null itemtime,
			   			null handler 
					from records r  
			   			left join (select recordid, 
										sum(case when eventtype = 0 then 1 else 0 end) holdTime,
										sum(case when eventtype = 1 then 1 else 0 end) conferenceTime,
										sum(case when eventtype = 2 then 1 else 0 end) muteTime
									 from RecAdditional
									 group by recordid
							) ra on r.recordid = ra.recordid
			   			--left join connection c on c.recordid = r.recordid 
			   			left join agentgrouprec g on g.recordid=r.recordid
			   			left join taskrec t on t.recordid=r.recordid 
			   			left join agent a on a.agentid=r.master
			   			left join project p on r.projid=p.projid
			   			left join Storage vs on r.VideoUrl = vs.FtpID'
			   			
	/*	
	if @RecordID = ''
		set @sch = @sch + ' and	(StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')'
	*/
	
	/*权限控制录音记录取舍Begin*/
	set @bAdmin=1
	if @bAdmin = 1 goto _NEXT
	if len(@AgentID_p) = 0 and len(@Address_p) = 0 and len(@acd_p) = 0 and len(@Called_p) = 0
		 and len(@TrunkGroup_p) = 0 and len(@projId_p) = 0 and len(@AgentGroupId_p) = 0 and len(@AddressGroup_p) = 0
		goto _NEXT
	
	--set @sch_p = @sch + 'and (1=0'

	if len(@AgentID_p) > 0 begin
		
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AgentID_p',ParamKey from dbo.ufnSplitStringToTable(@AgentID_p,',');

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
	if len(@acd_p) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'acd_p',ParamKey from dbo.ufnSplitStringToTable(@acd_p,',');

		insert into #t_record(recordid) 
			select recordid 
			from records r 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			AND r.acd IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'acd_p');

	end
	if len(@Called_p) > 0 begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'Called_p',ParamKey from dbo.ufnSplitStringToTable(@Called_p,',');

		insert into #t_record(recordid) 
			select recordid 
			from records r 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			AND r.answer IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'Called_p');

	end
	if len(@TrunkGroup_p) > 0 begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'TrunkGroup_p',ParamKey from dbo.ufnSplitStringToTable(@TrunkGroup_p,',');
		insert into #t_record(recordid) 
			select recordid 
			from records r 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			AND r.channel/1000 IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'TrunkGroup_p'); 

	end
	if len(@projId_p) > 0 begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'projId_p',ParamKey from dbo.ufnSplitStringToTable(@projId_p,',');
		insert into #t_record(recordid) 
			select recordid 
			from records r 
			where (StartTime between @tTimeBegin and @tTimeEnd) 
			and not exists (select t.recordid from #t_record t where t.recordid = r.recordid)
			AND r.projId IN (SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'projId_p'); 
	end
	if len(@AgentGroupId_p) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AgentGroupId_p',ParamKey from dbo.ufnSplitStringToTable(@AgentGroupId_p,',');

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
		select N'AddressGroup_p',ParamKey from dbo.ufnSplitStringToTable(@AddressGroup_p,',');

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

	if len(@AgentGroupId) > 0 begin
		TRUNCATE TABLE #PARAMETER;
		INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AgentGroupId',ParamKey from dbo.ufnSplitStringToTable(@AgentGroupId,',');

		insert into #t_agent([Master])
			select agentid
			from GroupAgent g
			where groupid IN(SELECT ParaValue FROM #PARAMETER WHERE ParaName = N'AgentGroupId'); 
		--select * from #t_agent
		select @sch = @sch + ' inner join #t_agent ta on r.[Master] = ta.[master] '

	end

	set @sch = @sch + ' where 1 = 1'
	if @RecordID = ''
		set @sch = @sch + ' and	(StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')'
	

	if @GroupID !=0 
		set @sch = @sch + ' and g.groupid = ' + convert(varchar, @GroupID) 
	if @TaskID !=0 
		set @sch = @sch + ' and t.taskid  = ' +  convert(varchar, @TaskID) 
	
	if @uui != ''
		set @sch = @sch + ' and r.uui  like ''%' +  @uui + '%'''
		 
	if len(@AgentID) > 0 begin
	TRUNCATE TABLE #PARAMETER;
	INSERT INTO #PARAMETER(ParaName,ParaValue)
		select N'AgentID',ParamKey from dbo.ufnSplitStringToTable(@AgentID,',');
		set @sch = @sch + ' and r.[master] in (SELECT ParaValue FROM #PARAMETER WHERE ParaName =N''AgentID'') '

	end
	
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

	-- 若电话号码中不存在%_[]，则在号码前加上%进行匹配
	if len(@CustmoerPhone) > 0 begin
		set @CustmoerPhone = case when @CustmoerPhone like '%[/%/_/[/]]%' ESCAPE '/' then @CustmoerPhone
						   else '%' + @CustmoerPhone + '%'
					  end
		--set @sch = @sch + ' and (r.answer like ''' + @CustmoerPhone + ''' or c.device like ''' + @CustmoerPhone + ''' or c.phone like ''' + @CustmoerPhone + ''' or r.calling like ''' +  @CustmoerPhone + '''  or r.called like ''' +  @CustmoerPhone + ''')' 
		set @sch = @sch + ' and (r.answer like ''' + @CustmoerPhone + ''' or r.extension like ''' + @CustmoerPhone + ''' or r.calling like ''' +  @CustmoerPhone + '''  or r.called like ''' +  @CustmoerPhone + ''')' 
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
		select N'AddressGroup',ParamKey from dbo.ufnSplitStringToTable(@AddressGroup,',');

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
		set @sch = @sch + ' and isnull(ra.muteTime, 0) between ' + str(@MutetimeFrom) + ' and ' + str(@MutetimeTo) 
	if (@HoldtimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.holdTime, 0) between ' + str(@HoldtimeFrom) + ' and ' + str(@HoldtimeTo) 
	if (@ConferencetimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.conferenceTime, 0) between ' + str(@ConferencetimeFrom) + ' and ' + str(@ConferencetimeTo) 
	if (@RecordID !=0)  begin
		--set @sch = @sch + ' and r.RecordID like ''' + cast(@RecordID as varchar(20)) + '%'''	 
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
		
	if len(@projId) > 0 begin
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
		set @sch = @sch + ' and outbound = 1'
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
	
	if (@LogID >1) begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  begin 
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
		else if (@type=2) begin 
			declare @tasks_all varchar(1000) 
			set @tasks_all = (select tasks from supervisor where logid=@logID) 
			set @tasks_all = ltrim(rtrim(isnull(@tasks_all, ''))) 
			if (@tasks_all !='') 
				set @tasks_all = 't.taskid in (' + @tasks_all+ ')' 
			else 
			 	set @tasks_all = 't.taskid= 0 ' 
			set @tasks_all = 'and (' + @tasks_all + ') ' 
			set @sch = @sch + @tasks_all 
		end 
	end 

		set @sch = 'select *,row_number()over(order by t.'+@Orderby+' desc)as oder into ##t from (' 
			 + @sch  + ' and r.seconds>0 '
			 + case when @bPrivilege > 0 then '
						and exists(select 1 from #t_record tr 
										where tr.recordid = r.recordid)' else '' end
			 + ') t '
			 --+ ' order by t.' + @Orderby + ' desc '
			 

	--print @sch

	execute(@sch) ;

	declare @TotalPage int
	set @TotalPage=(select max(oder) from ##t);
	select * from ##t where oder between @StartPage and @EndPage;

	select @TotalPage total

	drop table ##t;
		DROP TABLE #t_record;
		DROP TABLE #t_agent;
		drop table #MIDTABLE;
		drop table #PARAMETER;
	
END
GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records_bak20160812]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example: 
exec usp_sch_records @recordid=201604261641150101
	 @DateBegin=20160115
	 ,@DateEnd=20160915
	 ,@AgentID_p='178126,178154'
	 ,@Address_p='62237,62238'
	 ,@recordType='1,2,3'
usp_sch_records
	 @DateBegin=20160315
	 ,@DateEnd=20160415
	 --,@AgentID_p='72056,178154'
	 --,@Address_p='62237,62238'
	 --,@AgentGroupId_p='3,7,10,11'
	 ,@AddressGroup_p='1,2,3'
	 
usp_sch_records 0,'' ,'' ,'' , '', '31612','' , '2016-05-11', '2016-05-11', '00:00', '23:59', null, '', 0, 1439,'' , 'recordId', 0,'' ,'' , '','' , '','' , '', '','' , '', '', '', '','' ,'' , '', 0, 30, 0, 30, 0, 30, 1

*/	 
CREATE PROCEDURE [dbo].[usp_sch_records_bak20160812] 
	@LogID				int = 0, 
	@TaskID				int = 0, 
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
	@TrunkGroup_p 		varchar(2000) = '',
	@ProjId				varchar(200) = '',
	@ProjId_p			varchar(200) = '',
	@Acd				varchar(2000) = '',
	@Acd_p				varchar(2000) = '',
	@Direction			varchar(20) = 'all',
	@CustmoerPhone		varchar(50) = '',
	@Calling			varchar(50) = '',
	@Called				varchar(2000) = '',
	@Called_p			varchar(2000) = '',
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
	@confsCount			int = null			-- 会议
AS
BEGIN
	set @AgentID	= ltrim(rtrim(isnull(@AgentID, '')))
	set @AgentID_p	= ltrim(rtrim(isnull(@AgentID_p, '')))  
	set @Address	= ltrim(rtrim(isnull(@Address, '')))
	set @Address_p	= ltrim(rtrim(isnull(@Address_p, ''))) 
	set @CustmoerPhone	= ltrim(rtrim(isnull(@CustmoerPhone, ''))) 
	set @Calling	= ltrim(rtrim(isnull(@Calling, ''))) 
	set @Label	= ltrim(rtrim(isnull(@Label, ''))) 
	set @TrunkGroup = ltrim(rtrim(isnull(@TrunkGroup, '')))
	set @TrunkGroup_p = ltrim(rtrim(isnull(@TrunkGroup_p, '')))
	set @ProjId =  ltrim(rtrim(isnull(@ProjId, '')))
	set @ProjId_p =  ltrim(rtrim(isnull(@ProjId_p, '')))
	set @Acd	= ltrim(rtrim(isnull(@Acd, '')))
	set @Acd_p	= ltrim(rtrim(isnull(@Acd_p, '')))
	set @Called	= ltrim(rtrim(isnull(@Called, '')))
	set @Called_p	= ltrim(rtrim(isnull(@Called_p, ''))) 
	set @AgentGroupId = ltrim(rtrim(isnull(@AgentGroupId, '')))
	set @AgentGroupId_p = ltrim(rtrim(isnull(@AgentGroupId_p, '')))
	set @AddressGroup = ltrim(rtrim(isnull(@AddressGroup, '')))
	set @AddressGroup_p = ltrim(rtrim(isnull(@AddressGroup_p, '')))
	set @uui	= ltrim(rtrim(isnull(@uui, ''))) 
	set @bAdmin = isnull(@bAdmin, 0)

	IF OBJECT_ID('tempdb..#t_record') IS NOT NULL BEGIN
		DROP TABLE #t_record
		PRINT 'drop temp table #t_record'
	END
		
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
	
	create table #t_record(recordid bigint)
	create index #ix_t_record on #t_record(recordid)

	set @sch = 	'select distinct top 100 percent r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel,
						r.RecURL,r.ScrURL,r.VideoURL,r.StartTime,r.Seconds,r.State,
			   			isnull(ra.muteTime, 0) muteTime,isnull(ra.holdTime, 0) holdTime,isnull(ra.conferenceTime, 0) conferenceTime,
			   			r.RecFlag,r.ScrFlag,r.VideoFlag,r.StartDate,r.StartHour,r.Backuped,r.Checked Checked1,r.Direction,r.ProjId,
			   			r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI,
			   			a.agentname,p.projname,isnull(r.DataEncrypted,0) dataencrypted,r.trunk,
			   			null item01, null item02,
			   			null item03, null item04,
			   			null item05, null item06,
			   			null item07, null item08,
			   			null item09, null item10,
			   			null note, null itemtime,
			   			null handler 
					from records r  
			   			left join (select recordid, 
										sum(case when eventtype = 0 then 1 else 0 end) holdTime,
										sum(case when eventtype = 1 then 1 else 0 end) conferenceTime,
										sum(case when eventtype = 2 then 1 else 0 end) muteTime
									 from RecAdditional
									 group by recordid
							) ra on r.recordid = ra.recordid
			   			--left join connection c on c.recordid = r.recordid 
			   			left join agentgrouprec g on g.recordid=r.recordid
			   			left join taskrec t on t.recordid=r.recordid 
			   			left join agent a on a.agentid=r.master
			   			left join project p on r.projid=p.projid
			   			left join Storage vs on r.VideoUrl = vs.FtpID
			   		where 1=1'
			   		
	if @RecordID = ''
		set @sch = @sch + ' and	(StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')'
	
	/*权限控制录音记录取舍Begin*/
	if @bAdmin = 1 goto _NEXT
	if len(@AgentID_p) = 0 and len(@Address_p) = 0 and len(@acd_p) = 0 and len(@Called_p) = 0
		 and len(@TrunkGroup_p) = 0 and len(@projId_p) = 0 and len(@AgentGroupId_p) = 0 and len(@AddressGroup_p) = 0
		goto _NEXT
	
	set @sch_p = @sch + '
						and (1=0'
	
	if len(@AgentID_p) > 0 begin
		set @AgentID_p = ',' + @AgentID_p + ','
		--set @sch_p = @sch_p + ' (charindex('','' + rtrim(c.agent) + '','' ,''' + @AgentID_p + ''') > 0  or charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID_p + ''') > 0)'
		set @sch_p = @sch_p + ' or charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID_p + ''') > 0'
	end
	if len(@Address_p) > 0 begin
		set @Address_p = ',' + @Address_p + ','
		--select @sch_p = @sch_p + ' or charindex('','' + rtrim(c.device) + '','' ,''' + @Address_p + ''') > 0 '
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.extension) + '','' ,''' + @Address_p + ''') > 0 '
	end
	if len(@acd_p) > 0 begin
		set @acd_p = ',' + @acd_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.acd) + '','' ,''' + @acd_p + ''') > 0 '
	end
	if len(@Called_p) > 0 begin
		set @Called_p = ',' + @Called_p + ','
		select @sch_p = @sch_p + ' or (charindex('','' + rtrim(r.answer) + '','' ,''' + @Called_p + ''') > 0 or charindex('','' + rtrim(r.called) + '','' ,''' + @Called_p + ''') > 0)'
	end
	if len(@TrunkGroup_p) > 0 begin
		set @TrunkGroup_p = ',' + @TrunkGroup_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + convert(varchar,(r.channel/1000)) + '','' ,''' + @TrunkGroup_p + ''') > 0 '
	end
	if len(@projId_p) > 0 begin
		set @projId_p = ',' + @projId_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + convert(varchar, r.projId) + '','' ,''' + @projId_p + ''') > 0 '
	end
	if len(@AgentGroupId_p) > 0 begin
		set @GroupAgent = ',--,'
		select @GroupAgent = @GroupAgent + rtrim(agentid) + ','
			from GroupAgent
			where charindex(',' + convert(varchar, groupid) + ',',',' + @AgentGroupId_p + ',') > 0
			
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.master) + '','' ,''' + @GroupAgent + ''') > 0 '
	end
	if len(@AddressGroup_p) > 0 begin
		set @GroupAddress = ',--,'
		select @GroupAddress = @GroupAddress + rtrim(Address) + ','
			from GroupAddress
			where charindex(',' + convert(varchar, groupid) + ',',',' + @AddressGroup_p + ',') > 0
			
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.extension) + '','' ,''' + @GroupAddress + ''') > 0 '
	end
	
	
	set @sch_p = @sch_p + ')'
	
	set @sch_p = 'insert into #t_record(recordid) select recordid from (' + @sch_p + ') t'
	
	print @sch_p --
	exec(@sch_p)
	
	set @bPrivilege = 1
	
	/*权限控制录音记录取舍End*/
	
	_NEXT:

	if @GroupID !=0 
		set @sch = @sch + ' and g.groupid = ' + convert(varchar, @GroupID) 
	if @TaskID !=0 
		set @sch = @sch + ' and t.taskid  = ' +  convert(varchar, @TaskID) 
	
	if @uui != ''
		set @sch = @sch + ' and r.uui  like ''%' +  @uui + '%'''
		 
	if len(@AgentID) > 0 begin
		set @AgentID = ',' + @AgentID + ','
		--set @sch = @sch + ' and (charindex('','' + rtrim(c.agent) + '','' ,''' + @AgentID + ''') > 0  or charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID + ''') > 0)'
		set @sch = @sch + ' and charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID + ''') > 0'
	end
	
	if len(@Address) > 0 begin
		set @Address = ',' + @Address + ','
		--select @sch = @sch + ' and charindex('','' + rtrim(c.device) + '','' ,''' + @Address + ''') > 0 '
		select @sch = @sch + ' and charindex('','' + rtrim(r.extension) + '','' ,''' + @Address + ''') > 0 '
	end
	
	if len(@acd) > 0 begin
		set @acd = ',' + @acd + ','
		select @sch = @sch + ' and charindex('','' + rtrim(r.acd) + '','' ,''' + @acd + ''') > 0 '
	end

	-- 若电话号码中不存在%_[]，则在号码前加上%进行匹配
	if len(@CustmoerPhone) > 0 begin
		set @CustmoerPhone = case when @CustmoerPhone like '%[/%/_/[/]]%' ESCAPE '/' then @CustmoerPhone
						   else '%' + @CustmoerPhone + '%'
					  end
		--set @sch = @sch + ' and (r.answer like ''' + @CustmoerPhone + ''' or c.device like ''' + @CustmoerPhone + ''' or c.phone like ''' + @CustmoerPhone + ''' or r.calling like ''' +  @CustmoerPhone + '''  or r.called like ''' +  @CustmoerPhone + ''')' 
		set @sch = @sch + ' and (r.answer like ''' + @CustmoerPhone + ''' or r.extension like ''' + @CustmoerPhone + ''' or r.calling like ''' +  @CustmoerPhone + '''  or r.called like ''' +  @CustmoerPhone + ''')' 
	end
	
	if len(@Calling) > 0 begin
		set @Calling = case when @Calling like '%[/%/_/[/]]%' ESCAPE '/' then @Calling
						   else '%' + @Calling + '%'
					  end
		set @sch = @sch + ' and r.calling like ''' +  @Calling + ''''
	end
	
	if len(@Called) > 0 begin
		set @Called = ',' + @Called + ','
		select @sch = @sch + ' and (charindex('','' + rtrim(r.answer) + '','' ,''' + @Called + ''') > 0 or charindex('','' + rtrim(r.called) + '','' ,''' + @Called + ''') > 0)'
	end
	
	if len(@AgentGroupId) > 0 begin
		set @GroupAgent = ',--,'
		select @GroupAgent = @GroupAgent + rtrim(agentid) + ','
			from GroupAgent
			where charindex(',' + convert(varchar, groupid) + ',',',' + @AgentGroupId + ',') > 0
			
		select @sch = @sch + ' and charindex('','' + rtrim(r.master) + '','' ,''' + @GroupAgent + ''') > 0 '
	end
	
	if len(@AddressGroup) > 0 begin
		set @GroupAddress = ',--,'
		select @GroupAddress = @GroupAddress + rtrim(Address) + ','
			from GroupAddress
			where charindex(',' + convert(varchar, groupid) + ',',',' + @AddressGroup + ',') > 0
			
		select @sch = @sch + ' and charindex('','' + rtrim(r.extension) + '','' ,''' + @GroupAddress + ''') > 0 '
	end

	if (@Label !='')  
		set @sch = @sch + ' and r.RecordID in (select distinct RecordID from Label where Label like''%' + rtrim(ltrim(@Label)) + '%'')' 
	else if (@Labeled = 1)  
		set @sch = @sch + ' and r.checked = 1 ' 
	if (@CalltimeTo !=0)  
		set @sch = @sch + ' and r.seconds between ' + str(@CalltimeFrom*60) + ' and ' + str(@CalltimeTo*60) 
	if (@MutetimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.muteTime, 0) between ' + str(@MutetimeFrom) + ' and ' + str(@MutetimeTo) 
	if (@HoldtimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.holdTime, 0) between ' + str(@HoldtimeFrom) + ' and ' + str(@HoldtimeTo) 
	if (@ConferencetimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.conferenceTime, 0) between ' + str(@ConferencetimeFrom) + ' and ' + str(@ConferencetimeTo) 
	if (@RecordID !=0)  begin
		--set @sch = @sch + ' and r.RecordID like ''' + cast(@RecordID as varchar(20)) + '%'''	 
		set @sch = @sch + ' and r.RecordID=' + cast(@RecordID as varchar(20))		
	end
	else begin
		if (@UCID != '') begin
			set @sch = @sch + ' and r.ucid like ''' + ltrim(@UCID) + '%'''
		end
	end

	if len(@TrunkGroup) > 0 begin
		set @TrunkGroup = ',' + @TrunkGroup + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar,(r.channel/1000)) + '','' ,''' + @TrunkGroup + ''') > 0 '
	end
		
	if len(@projId) > 0 begin
		set @projId = ',' + @projId + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.projId) + '','' ,''' + @projId + ''') > 0 '
	end

	set @direction = isnull(@direction, '')
	if (@direction = 'in' or @direction = 'inbound') begin
		set @sch = @sch + ' and inbound = 1 and outbound = 0'
	end
	if (@direction = 'out' or @direction = 'outbound') begin
		set @sch = @sch + ' and outbound = 1'
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
	
	if (@LogID >1) begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  begin 
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
		else if (@type=2) begin 
			declare @tasks_all varchar(1000) 
			set @tasks_all = (select tasks from supervisor where logid=@logID) 
			set @tasks_all = ltrim(rtrim(isnull(@tasks_all, ''))) 
			if (@tasks_all !='') 
				set @tasks_all = 't.taskid in (' + @tasks_all+ ')' 
			else 
			 	set @tasks_all = 't.taskid= 0 ' 
			set @tasks_all = 'and (' + @tasks_all + ') ' 
			set @sch = @sch + @tasks_all 
		end 
	end 

	set @sch = 'select * from (' 
			 + @sch  + ' and r.seconds>0 '
			 + case when @bPrivilege > 0 then '
						and exists(select 1 from #t_record tr 
										where tr.recordid = r.recordid)' else '' end
			 + ') t '
			 + ' 
					order by t.' + @Orderby + ' desc '

	print @sch

	execute(@sch) 
	
	IF OBJECT_ID('tempdb..#t_record') IS NOT NULL BEGIN
		DROP TABLE #t_record
		PRINT 'drop temp table #t_record'
	END
	
END
GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records_byId]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_records_byId]  
	@LogID int = 0,  
	@RecordID int = 0  
AS
declare @sch varchar(5000) 
	declare @cur_date_value varchar(50)
	set @cur_date_value = floor(cast(getdate() as float))

	--modified by wenyong xia 2007 12/11
	--set @sch = 	'select distinct r.*, a.agentname, pp.projname from records r ' + 
	--		'	left join connection c on c.recordid = r.recordid ' + 
	--		'	left join agentgrouprec g on g.recordid=r.recordid ' + 
	--		'	left join taskrec t on t.recordid=r.recordid ' + 
	--		'	left join agent a on a.agentid=r.master ' + 
	--		'	left join project pp on pp.projid=r.projid ' + 
	--		'where  r.recordid = ' + convert(varchar, @RecordID) 
	set @sch = 	'select distinct r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel,' +
				'r.AudioURL,r.VideoURL,r.StartTime,r.Seconds,r.State,' +
				'case ' +
					'when (isnull(vs.VideoKeepDays, 0) <= 0) or ' +
						 '(floor(cast(r.StartTime as float)) + vs.VideoKeepDays >= ' + @cur_date_value + ') then r.Finished ' +
					'else (r.Finished & 253) ' +
				'end Finished,' +
				'r.StartDate,r.StartHour,r.Backuped,r.Checked,r.Direction,r.ProjId,' +
				'r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI,' +
				'a.agentname, pp.projname, isnull(r.dataencry,0) dataencry, ' +
				'null item01,null item02,null item03,null item04,null item05,null item06,null item07,' +
				'null item08,null item09,null item10,null note,null itemtime,null handler,' +
				'r.SilenceOffset1,r.SilenceLen1 ' +
				'from records r ' + 
				'left join connection c on c.recordid = r.recordid ' + 
				'left join agentgrouprec g on g.recordid=r.recordid ' + 
				'left join taskrec t on t.recordid=r.recordid ' + 
				'left join agent a on a.agentid=r.master ' + 
				'left join project pp on pp.projid=r.projid ' + 
				--'left join recexts rt on (rt.recordid = r.recordid  or rt.ucid=r.ucid) and rt.enabled = 1 ' 
				+ 
				'left join Storage vs on r.VideoUrl = vs.FtpID ' +
				'where	r.recordid = ' + convert(varchar, @RecordID)  + ' '
	--
	if (@LogID >1) begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  begin 
			declare @sch_agent varchar(1000) 
			declare @agents_all varchar(1000) 
			declare @groups_all varchar(1000) 
			set @agents_all = (select agents from supervisor where logid=@logID) 
			set @agents_all = ltrim(rtrim(isnull(@agents_all, ''))) 
			if (@agents_all !='') 
				set @agents_all =  'c.agent in (' + ltrim(rtrim(@agents_all)) + ')' 
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
				set @sch_agent = ' and (c.agent= ''1'')' 
			set @sch = @sch + @sch_agent 
		end 
		else if (@type=2) begin 
			declare @tasks_all varchar(1000) 
			set @tasks_all = (select tasks from supervisor where logid=@logID) 
			set @tasks_all = ltrim(rtrim(isnull(@tasks_all, ''))) 
			if (@tasks_all !='') 
				set @tasks_all = 't.taskid in (' + @tasks_all+ ')' 
			else 
			 	set @tasks_all = 't.taskid= 0 ' 
			set @tasks_all = 'and (' + @tasks_all + ') ' 
			set @sch = @sch + @tasks_all 
		end 
	end 
print @sch
	execute(@sch) 
	select @@rowcount counts



GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records_byId_recexts]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_sch_records_byId_recexts]  
	@LogID int = 0,  
	@RecordID int = 0  
AS  
	declare @sch varchar(5000) 
	declare @cur_date_value varchar(50)
	set @cur_date_value = floor(cast(getdate() as float))

	--modified by wenyong xia 2007 12/11
	--set @sch = 	'select distinct r.*, a.agentname, pp.projname from records r ' + 
	--		'	left join connection c on c.recordid = r.recordid ' + 
	--		'	left join agentgrouprec g on g.recordid=r.recordid ' + 
	--		'	left join taskrec t on t.recordid=r.recordid ' + 
	--		'	left join agent a on a.agentid=r.master ' + 
	--		'	left join project pp on pp.projid=r.projid ' + 
	--		'where  r.recordid = ' + convert(varchar, @RecordID) 
	set @sch = 	'select distinct r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel,' +
				'r.AudioURL,r.VideoURL,r.StartTime,r.Seconds,r.State,' +
				'case ' +
					'when (isnull(vs.VideoKeepDays, 0) <= 0) or ' +
						 '(floor(cast(r.StartTime as float)) + vs.VideoKeepDays >= ' + @cur_date_value + ') then r.Finished ' +
					'else (r.Finished & 253) ' +
				'end Finished,' +
				'r.StartDate,r.StartHour,r.Backuped,r.Checked,r.Direction,r.ProjId,' +
				'r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI,' +
				'a.agentname, pp.projname,' +
				'rt.item01,rt.item02,rt.item03,rt.item04,rt.item05,rt.item06,rt.item07,' +
				'rt.item08,rt.item09,rt.item10,rt.note,rt.itemtime,rt.handler,' +
				'r.SilenceOffset1,r.SilenceLen1 ' +
				'from records r ' + 
				'left join connection c on c.recordid = r.recordid ' + 
				'left join agentgrouprec g on g.recordid=r.recordid ' + 
				'left join taskrec t on t.recordid=r.recordid ' + 
				'left join agent a on a.agentid=r.master ' + 
				'left join project pp on pp.projid=r.projid ' + 
				'left join recexts rt on (rt.recordid = r.recordid  or rt.ucid=r.ucid) and rt.enabled = 1 ' + 
				'left join Storage vs on r.VideoUrl = vs.FtpID ' +
				'where	r.recordid = ' + convert(varchar, @RecordID)  + ' '
	--
	if (@LogID >1) begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  begin 
			declare @sch_agent varchar(1000) 
			declare @agents_all varchar(1000) 
			declare @groups_all varchar(1000) 
			set @agents_all = (select agents from supervisor where logid=@logID) 
			set @agents_all = ltrim(rtrim(isnull(@agents_all, ''))) 
			if (@agents_all !='') 
				set @agents_all =  'c.agent in (' + ltrim(rtrim(@agents_all)) + ')' 
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
				set @sch_agent = ' and (c.agent= ''1'')' 
			set @sch = @sch + @sch_agent 
		end 
		else if (@type=2) begin 
			declare @tasks_all varchar(1000) 
			set @tasks_all = (select tasks from supervisor where logid=@logID) 
			set @tasks_all = ltrim(rtrim(isnull(@tasks_all, ''))) 
			if (@tasks_all !='') 
				set @tasks_all = 't.taskid in (' + @tasks_all+ ')' 
			else 
			 	set @tasks_all = 't.taskid= 0 ' 
			set @tasks_all = 'and (' + @tasks_all + ') ' 
			set @sch = @sch + @tasks_all 
		end 
	end 
print @sch
	execute(@sch) 
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records_recexts]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_sch_records_recexts] 
	@LogID	int = 0, 
	@TaskID	int = 0, 
	@GroupID	int = 0, 
	@AgentID	varchar(20)  = '', 
	@Address	varchar(20)  = '', 
	@PhoneNo	varchar(50)  = '', 
	@DateBegin 	varchar(20)  = '20000101', 
	@DateEnd	varchar(20)  = '20790101', 
	@TimeBegin	varchar(20)  = '00:00:00', 
	@TimeEnd	varchar(20)  = '23:59:59.999', 
	@Label		varchar(20) = '', 
	@AddGroupID	int = 0, 
	@CalltimeFrom	float = 0, 
	@CalltimeTo	float = 0, 
	@RecordID	int = 0, 
	@Orderby	varchar(20) = 'RecordId', 
	@Labeled	bit = 0, 
	@TrunkGroup 	varchar(10) = '',
	@ProjId		int = 0,
	@Acd		varchar(20) = '',
	@Direction	varchar(20) = 'all',

	@PhoneType	int = 0,
	@uui		varchar(100) = '',
	@ItemNo tinyint = 0,
	@Value varchar(50) = '',
	@UCID  varchar(20) = '',
	@finished tinyint = 0
AS 
	-- phone type
	-- 0: all, 1:calling, 2:called
	--declare @sch varchar(2000)
	-- modfied by wenyong xia 2007 12/11
	declare @sch varchar(5000), @Item1 varchar(20), @Item2 varchar(20)
	declare @cur_date_value varchar(50)
	set @cur_date_value = floor(cast(getdate() as float))

	-- 
	set @Acd	= ltrim(rtrim(isnull(@Acd, ''))) 
	set @AgentID	= ltrim(rtrim(isnull(@AgentID, ''))) 
	set @Address	= ltrim(rtrim(isnull(@Address, ''))) 
	set @PhoneNo	= ltrim(rtrim(isnull(@PhoneNo, ''))) 
	set @Label	= ltrim(rtrim(isnull(@Label, ''))) 
	set @TrunkGroup = ltrim(rtrim(isnull(@TrunkGroup, ''))) 
	set @uui	= ltrim(rtrim(isnull(@uui, ''))) 
--modified by wenyong xie 2007/12/11
/*
	set @sch = 	'select distinct r.*, a.agentname,p.projname from records r ' + 
			'	left join connection c on c.recordid = r.recordid ' + 
			'	left join agentgrouprec g on g.recordid=r.recordid ' + 
			'	left join taskrec t on t.recordid=r.recordid ' + 
			'	left join agent a on a.agentid=r.master ' + 
			'	left join project p on r.projid=p.projid ' + 
			'where  (StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')' 
*/	
	set @sch = 	'select distinct top 100 percent r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel,' +
				'r.AudioURL,r.VideoURL,r.StartTime,r.Seconds,r.State,' +
				'case ' +
					'when (isnull(vs.VideoKeepDays, 0) <= 0) or ' +
						 '(floor(cast(r.StartTime as float)) + vs.VideoKeepDays >= ' + @cur_date_value + ') then r.Finished ' +
					'else (r.Finished & 253) ' +
				'end Finished,' +
				'r.StartDate,r.StartHour,r.Backuped,r.Checked,r.Direction,r.ProjId,' +
				'r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI,' +
				'a.agentname,p.projname,'+
				'isnull(rt1.item01, rt2.item01) item01, isnull(rt1.item02, rt2.item02) item02,' +
				'isnull(rt1.item03, rt2.item03) item03, isnull(rt1.item04, rt2.item04) item04,' +
				'isnull(rt1.item05, rt2.item05) item05, isnull(rt1.item06, rt2.item06) item06,' +
				'isnull(rt1.item07, rt2.item07) item07, isnull(rt1.item08, rt2.item08) item08,' +
				'isnull(rt1.item09, rt2.item09) item09, isnull(rt1.item10, rt2.item10) item10,' +
				'isnull(rt1.note, rt2.note) note, isnull(rt1.itemtime, rt2.itemtime) itemtime,' +
				'isnull(rt1.handler, rt2.handler) handler from records r ' + 
				'left join connection c on c.recordid = r.recordid ' + 
				'left join agentgrouprec g on g.recordid=r.recordid ' + 
				'left join taskrec t on t.recordid=r.recordid ' + 
				'left join agent a on a.agentid=r.master ' + 
				'left join project p on r.projid=p.projid ' + 
				'left join recexts rt1 on rt1.recordid = r.recordid and rt1.enabled = 1 ' + 
				'left join recexts rt2 on rt2.recordid != r.recordid and rt2.ucid=r.ucid and rt2.enabled = 1 ' +
				'left join Storage vs on r.VideoUrl = vs.FtpID ' +
				'where  (StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')'
	--if @finished >0 
	--	set @sch = @sch + ' and r.finished = ' + convert(varchar, @finished) 
	if @GroupID !=0 
		set @sch = @sch + ' and g.groupid = ' + convert(varchar, @GroupID) 
	if @TaskID !=0 
		set @sch = @sch + ' and t.taskid  = ' +  convert(varchar, @TaskID) 
	if @Acd != ''
		set @sch = @sch + ' and r.acd  = ''' +  @acd + ''''
	if @uui != ''
		set @sch = @sch + ' and r.uui  like ''%' +  @uui + '%''' 
	if @AgentID !='' 
		set @sch = @sch + ' and (c.agent  = ''' + @AgentID + ''' or r.master = ''' + @AgentID + ''')'
	if @Address !='' 
		set @sch = @sch + ' and c.device  = ''' + @Address + '''' 
	if @PhoneNo !=''  begin
		if (charindex(':', @PhoneNo)=2) begin
			set @PhoneType = convert(int, substring(@PhoneNo, 1,1))
			set @PhoneNo = substring(@PhoneNo, 3, len(@PhoneNo)-2)
		end

		-- 若电话号码中不存在%_[]，则在号码前加上%进行匹配
		declare @SchPhoneNo varchar(50)		
		set @SchPhoneNo = case when @PhoneNo like '%[/%/_/[/]]%' ESCAPE '/' then @PhoneNo
							   else '%' + @PhoneNo
						  end

		if @PhoneType=0
			set @sch = @sch + ' and (r.answer like ''' + @SchPhoneNo + ''' or c.device like ''' + @SchPhoneNo + ''' or c.phone like ''' + @SchPhoneNo + ''' or r.calling like ''' +  @SchPhoneNo + '''  or r.called like ''' +  @SchPhoneNo + ''')' 
		else if @PhoneType=1
			set @sch = @sch + ' and r.calling like ''' +  @SchPhoneNo + ''''
		else if @PhoneType=2
			set @sch = @sch + ' and (r.answer like ''' + @SchPhoneNo + ''' or r.called like ''' +  @SchPhoneNo + ''')'
		else if @PhoneType=3
			set @sch = @sch + ' and r.uui like ''' +  @SchPhoneNo + ''''
	end	
	if (@Label !='')  
		set @sch = @sch + ' and r.RecordID in (select distinct RecordID from Label where Label like''%' + rtrim(ltrim(@Label)) + '%'')' 
	else if (@Labeled = 1)  
		set @sch = @sch + ' and r.checked = 1 ' 
	if (@CalltimeTo !=0)  
		set @sch = @sch + ' and r.seconds between ' + str(@CalltimeFrom*60) + ' and ' + str(@CalltimeTo*60) 
	if (@RecordID !=0)  begin
		set @sch = @sch + ' and ltrim(str(r.RecordID)) like ''' + ltrim(str(@RecordID)) + '%'''	 	
	end
	else begin
		if (@UCID != '') begin
			set @sch = @sch + ' and r.ucid like ''' + ltrim(@UCID) + '%'''
		end
	end
	
	if (@TrunkGroup !='') 
		set @sch = @sch + ' and r.channel/1000 =' + @TrunkGroup 
	if (@projId !=0) 
		set @sch = @sch + ' and r.projId  ='  + ltrim(str(@projId))

	set @direction = isnull(@direction, '')
	if (@direction = 'in' or @direction = 'inbound') begin
		set @sch = @sch + ' and inbound = 1 and outbound = 0'
	end
	if (@direction = 'out' or @direction = 'outbound') begin
		set @sch = @sch + ' and outbound = 1'
	end

	if (@LogID >1) begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  begin 
			declare @sch_agent varchar(1000) 
			declare @agents_all varchar(1000) 
			declare @groups_all varchar(1000) 
			set @agents_all = (select agents from supervisor where logid=@logID) 
			set @agents_all = ltrim(rtrim(isnull(@agents_all, ''))) 
			if (@agents_all !='') 
				set @agents_all =  'c.agent in (' + ltrim(rtrim(@agents_all)) + ')' 
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
				set @sch_agent = ' and (c.agent= ''1'')' 
			set @sch = @sch + @sch_agent 
		end 
		else if (@type=2) begin 
			declare @tasks_all varchar(1000) 
			set @tasks_all = (select tasks from supervisor where logid=@logID) 
			set @tasks_all = ltrim(rtrim(isnull(@tasks_all, ''))) 
			if (@tasks_all !='') 
				set @tasks_all = 't.taskid in (' + @tasks_all+ ')' 
			else 
			 	set @tasks_all = 't.taskid= 0 ' 
			set @tasks_all = 'and (' + @tasks_all + ') ' 
			set @sch = @sch + @tasks_all 
		end 
	end 
	--print @sch 
	--add by wenyong xia 2007 12/11
	if not (isnull(@ItemNo, 0) = 0 or @ItemNo > 10 or @Value = '')  begin
		if @ItemNo = 10  begin
			select @Item1 = ' rt1.Item' + cast(@ItemNo as varchar(10)),
					@Item2 = ' rt2.Item' + cast(@ItemNo as varchar(10))
		end
		else begin
			select @Item1 = ' rt1.Item0' + cast(@ItemNo as varchar(10)),
					@Item2 = ' rt2.Item0' + cast(@ItemNo as varchar(10)) 
		end
		set @Value = @Value + '%'
		set @sch = @sch + ' and (' + @Item1 + ' like '''+ @Value +''' or ' + @Item2 + ' like '''+ @Value +''')'
	end
	----
	set @sch = 'select * from (' 
			 + @sch  + ' and r.finished > 0 and r.seconds>0 '
--			 + 'order by  r.' + @Orderby + ' desc' 	
			 + ') t '
			 + case when @finished > 0 then 'where finished = ' + cast(@finished as varchar(10)) else '' end
			 + ' order by t.' + @Orderby + ' desc '

	--print @sch

	execute(@sch) 
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_records_yibin]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*Example: 
exec usp_sch_records @recordid=201604261641150101
	 @DateBegin=20160115
	 ,@DateEnd=20160915
	 ,@AgentID_p='178126,178154'
	 ,@Address_p='62237,62238'
	 ,@recordType='1,2,3'
usp_sch_records
	 @DateBegin=20160315
	 ,@DateEnd=20160415
	 --,@AgentID_p='72056,178154'
	 --,@Address_p='62237,62238'
	 --,@AgentGroupId_p='3,7,10,11'
	 ,@AddressGroup_p='1,2,3'
	 
usp_sch_records 0,'' ,'' ,'' , '', '31612','' , '2016-05-11', '2016-05-11', '00:00', '23:59', null, '', 0, 1439,'' , 'recordId', 0,'' ,'' , '','' , '','' , '', '','' , '', '', '', '','' ,'' , '', 0, 30, 0, 30, 0, 30, 1

*/	 
CREATE PROCEDURE [dbo].[usp_sch_records_yibin] 
	@LogID				int = 0, 
	@TaskID				int = 0, 
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
	@TrunkGroup_p 		varchar(2000) = '',
	@ProjId				varchar(200) = '',
	@ProjId_p			varchar(200) = '',
	@Acd				varchar(2000) = '',
	@Acd_p				varchar(2000) = '',
	@Direction			varchar(20) = 'all',
	@CustmoerPhone		varchar(50) = '',
	@Calling			varchar(50) = '',
	@Called				varchar(2000) = '',
	@Called_p			varchar(2000) = '',
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
	@confsCount			int = null			-- 会议
AS
BEGIN
	set @AgentID	= ltrim(rtrim(isnull(@AgentID, '')))
	set @AgentID_p	= ltrim(rtrim(isnull(@AgentID_p, '')))  
	set @Address	= ltrim(rtrim(isnull(@Address, '')))
	set @Address_p	= ltrim(rtrim(isnull(@Address_p, ''))) 
	set @CustmoerPhone	= ltrim(rtrim(isnull(@CustmoerPhone, ''))) 
	set @Calling	= ltrim(rtrim(isnull(@Calling, ''))) 
	set @Label	= ltrim(rtrim(isnull(@Label, ''))) 
	set @TrunkGroup = ltrim(rtrim(isnull(@TrunkGroup, '')))
	set @TrunkGroup_p = ltrim(rtrim(isnull(@TrunkGroup_p, '')))
	set @ProjId =  ltrim(rtrim(isnull(@ProjId, '')))
	set @ProjId_p =  ltrim(rtrim(isnull(@ProjId_p, '')))
	set @Acd	= ltrim(rtrim(isnull(@Acd, '')))
	set @Acd_p	= ltrim(rtrim(isnull(@Acd_p, '')))
	set @Called	= ltrim(rtrim(isnull(@Called, '')))
	set @Called_p	= ltrim(rtrim(isnull(@Called_p, ''))) 
	set @AgentGroupId = ltrim(rtrim(isnull(@AgentGroupId, '')))
	set @AgentGroupId_p = ltrim(rtrim(isnull(@AgentGroupId_p, '')))
	set @AddressGroup = ltrim(rtrim(isnull(@AddressGroup, '')))
	set @AddressGroup_p = ltrim(rtrim(isnull(@AddressGroup_p, '')))
	set @uui	= ltrim(rtrim(isnull(@uui, ''))) 
	set @bAdmin = isnull(@bAdmin, 0)

	IF OBJECT_ID('tempdb..#t_record') IS NOT NULL BEGIN
		DROP TABLE #t_record
		PRINT 'drop temp table #t_record'
	END
	IF OBJECT_ID('tempdb..#t1') IS NOT NULL BEGIN
		drop table #t1
	END
	 create table #t1(AgentGroupId_p int);
	IF OBJECT_ID('tempdb..#t2') IS NOT NULL BEGIN
		drop table #t2
	END
	 create table #t2(GroupAgent int);
	IF OBJECT_ID('tempdb..#t3') IS NOT NULL BEGIN
		drop table #t3
	END
	create table #t3(AddressGroup_p int);	
	IF OBJECT_ID('tempdb..#t4') IS NOT NULL BEGIN
		drop table #t4
	END
 create table #t4(GroupAddress varchar(20));
 
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
	
	create table #t_record(recordid bigint)
	create index #ix_t_record on #t_record(recordid)

	set @sch = 	'select distinct top 100 percent r.RecordId,r.Calling,r.Called,r.Answer,r.Master,r.Channel,
						r.RecURL,r.ScrURL,r.VideoURL,r.StartTime,r.Seconds,r.State,
			   			isnull(ra.muteTime, 0) muteTime,isnull(ra.holdTime, 0) holdTime,isnull(ra.conferenceTime, 0) conferenceTime,
			   			r.RecFlag,r.ScrFlag,r.VideoFlag,r.StartDate,r.StartHour,r.Backuped,r.Checked Checked1,r.Direction,r.ProjId,
			   			r.Inbound,r.Outbound,r.Flag,r.Extension,r.VoiceType,r.Acd,r.UCID,r.UUI,
			   			a.agentname,p.projname,isnull(r.DataEncrypted,0) dataencrypted,r.trunk,
			   			null item01, null item02,
			   			null item03, null item04,
			   			null item05, null item06,
			   			null item07, null item08,
			   			null item09, null item10,
			   			null note, null itemtime,
			   			null handler 
					from records r with(nolock) 
			   			left join (select recordid, 
										sum(case when eventtype = 0 then 1 else 0 end) holdTime,
										sum(case when eventtype = 1 then 1 else 0 end) conferenceTime,
										sum(case when eventtype = 2 then 1 else 0 end) muteTime
									 from RecAdditional
									 group by recordid
							) ra on r.recordid = ra.recordid
			   			--left join connection c on c.recordid = r.recordid 
			   			left join agentgrouprec g on g.recordid=r.recordid
			   			left join taskrec t on t.recordid=r.recordid 
			   			left join agent a on a.agentid=r.master
			   			left join project p on r.projid=p.projid
			   			left join Storage vs on r.VideoUrl = vs.FtpID
			   		where 1=1'
			   		
	if @RecordID = ''
		set @sch = @sch + ' and	(StartTime between ''' + @DateBegin + ' ' + @TimeBegin + ''' and ''' + @DateEnd+ ' '  + @TimeEnd + ''')'
	
	/*权限控制录音记录取舍Begin*/
	if @bAdmin = 1 goto _NEXT
	if len(@AgentID_p) = 0 and len(@Address_p) = 0 and len(@acd_p) = 0 and len(@Called_p) = 0
		 and len(@TrunkGroup_p) = 0 and len(@projId_p) = 0 and len(@AgentGroupId_p) = 0 and len(@AddressGroup_p) = 0
		goto _NEXT
	
	set @sch_p = @sch + '
						and (1=0'
	
	if len(@AgentID_p) > 0 begin
		set @AgentID_p = ',' + @AgentID_p + ','
		--set @sch_p = @sch_p + ' (charindex('','' + rtrim(c.agent) + '','' ,''' + @AgentID_p + ''') > 0  or charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID_p + ''') > 0)'
		set @sch_p = @sch_p + ' or charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID_p + ''') > 0'
	end
	if len(@Address_p) > 0 begin
		set @Address_p = ',' + @Address_p + ','
		--select @sch_p = @sch_p + ' or charindex('','' + rtrim(c.device) + '','' ,''' + @Address_p + ''') > 0 '
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.extension) + '','' ,''' + @Address_p + ''') > 0 '
	end
	if len(@acd_p) > 0 begin
		set @acd_p = ',' + @acd_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.acd) + '','' ,''' + @acd_p + ''') > 0 '
	end
	if len(@Called_p) > 0 begin
		set @Called_p = ',' + @Called_p + ','
		select @sch_p = @sch_p + ' or (charindex('','' + rtrim(r.answer) + '','' ,''' + @Called_p + ''') > 0 or charindex('','' + rtrim(r.called) + '','' ,''' + @Called_p + ''') > 0)'
	end
	if len(@TrunkGroup_p) > 0 begin
		set @TrunkGroup_p = ',' + @TrunkGroup_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + convert(varchar,(r.channel/1000)) + '','' ,''' + @TrunkGroup_p + ''') > 0 '
	end
	if len(@projId_p) > 0 begin
		set @projId_p = ',' + @projId_p + ','
		select @sch_p = @sch_p + ' or charindex('','' + convert(varchar, r.projId) + '','' ,''' + @projId_p + ''') > 0 '
	end
	if len(@AgentGroupId_p) > 0 begin
		--set @GroupAgent = ',--,'
		--select @GroupAgent = @GroupAgent + rtrim(agentid) + ','
		--	from GroupAgent
		--	where charindex(',' + convert(varchar, groupid) + ',',',' + @AgentGroupId_p + ',') > 0
		insert into #t1(AgentGroupId_p)	
		select ParamKey from dbo.ufnSplitStringToTable(@AgentGroupId_p,',');
		
		insert into #t2(GroupAgent)
		select agentid from GroupAgent where groupid in(select AgentGroupId_p from #t1);
		
		--select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.master) + '','' ,''' + @GroupAgent + ''') > 0 '
		select @sch_p = @sch_p + ' or r.master in (select GroupAgent from #t2) '
	end
	if len(@AddressGroup_p) > 0 begin
		--set @GroupAddress = ',--,'
		--select @GroupAddress = @GroupAddress + rtrim(Address) + ','
		--	from GroupAddress
		--	where charindex(',' + convert(varchar, groupid) + ',',',' + @AddressGroup_p + ',') > 0
	
	insert into #t3(AddressGroup_p)	
		select ParamKey from dbo.ufnSplitStringToTable(@AddressGroup_p,',');
	insert into #t4(GroupAddress)
		select [Address] from GroupAddress where groupid in(select AddressGroup_p from #t3);
					
		--select @sch_p = @sch_p + ' or charindex('','' + rtrim(r.extension) + '','' ,''' + @GroupAddress + ''') > 0 '
		select @sch_p = @sch_p + ' or r.extension in (select GroupAddress from #t4) '
	
	end
	
	
	set @sch_p = @sch_p + ')'
	
	set @sch_p = 'insert into #t_record(recordid) select recordid from (' + @sch_p + ') t'
	
	print @sch_p --
	exec(@sch_p)
	
	set @bPrivilege = 1
	
	/*权限控制录音记录取舍End*/
	
	_NEXT:

	if @GroupID !=0 
		set @sch = @sch + ' and g.groupid = ' + convert(varchar, @GroupID) 
	if @TaskID !=0 
		set @sch = @sch + ' and t.taskid  = ' +  convert(varchar, @TaskID) 
	
	if @uui != ''
		set @sch = @sch + ' and r.uui  like ''%' +  @uui + '%'''
		 
	if len(@AgentID) > 0 begin
		set @AgentID = ',' + @AgentID + ','
		--set @sch = @sch + ' and (charindex('','' + rtrim(c.agent) + '','' ,''' + @AgentID + ''') > 0  or charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID + ''') > 0)'
		set @sch = @sch + ' and charindex('','' + rtrim(r.master) + '','' ,''' + @AgentID + ''') > 0'
	end
	
	if len(@Address) > 0 begin
		set @Address = ',' + @Address + ','
		--select @sch = @sch + ' and charindex('','' + rtrim(c.device) + '','' ,''' + @Address + ''') > 0 '
		select @sch = @sch + ' and charindex('','' + rtrim(r.extension) + '','' ,''' + @Address + ''') > 0 '
	end
	
	if len(@acd) > 0 begin
		set @acd = ',' + @acd + ','
		select @sch = @sch + ' and charindex('','' + rtrim(r.acd) + '','' ,''' + @acd + ''') > 0 '
	end

	-- 若电话号码中不存在%_[]，则在号码前加上%进行匹配
	if len(@CustmoerPhone) > 0 begin
		set @CustmoerPhone = case when @CustmoerPhone like '%[/%/_/[/]]%' ESCAPE '/' then @CustmoerPhone
						   else '%' + @CustmoerPhone + '%'
					  end
		--set @sch = @sch + ' and (r.answer like ''' + @CustmoerPhone + ''' or c.device like ''' + @CustmoerPhone + ''' or c.phone like ''' + @CustmoerPhone + ''' or r.calling like ''' +  @CustmoerPhone + '''  or r.called like ''' +  @CustmoerPhone + ''')' 
		set @sch = @sch + ' and (r.answer like ''' + @CustmoerPhone + ''' or r.extension like ''' + @CustmoerPhone + ''' or r.calling like ''' +  @CustmoerPhone + '''  or r.called like ''' +  @CustmoerPhone + ''')' 
	end
	
	if len(@Calling) > 0 begin
		set @Calling = case when @Calling like '%[/%/_/[/]]%' ESCAPE '/' then @Calling
						   else '%' + @Calling + '%'
					  end
		set @sch = @sch + ' and r.calling like ''' +  @Calling + ''''
	end
	
	if len(@Called) > 0 begin
		set @Called = ',' + @Called + ','
		select @sch = @sch + ' and (charindex('','' + rtrim(r.answer) + '','' ,''' + @Called + ''') > 0 or charindex('','' + rtrim(r.called) + '','' ,''' + @Called + ''') > 0)'
	end
	
	if len(@AgentGroupId) > 0 begin
		set @GroupAgent = ',--,'
		select @GroupAgent = @GroupAgent + rtrim(agentid) + ','
			from GroupAgent
			where charindex(',' + convert(varchar, groupid) + ',',',' + @AgentGroupId + ',') > 0
		
		select ParamKey from dbo.ufnSplitStringToTable(@AgentGroupId,',');
			
		select @sch = @sch + ' and charindex('','' + rtrim(r.master) + '','' ,''' + @GroupAgent + ''') > 0 '
	end
	
	if len(@AddressGroup) > 0 begin
		set @GroupAddress = ',--,'
		select @GroupAddress = @GroupAddress + rtrim(Address) + ','
			from GroupAddress
			where charindex(',' + convert(varchar, groupid) + ',',',' + @AddressGroup + ',') > 0
			
		select @sch = @sch + ' and charindex('','' + rtrim(r.extension) + '','' ,''' + @GroupAddress + ''') > 0 '
	end

	if (@Label !='')  
		set @sch = @sch + ' and r.RecordID in (select distinct RecordID from Label where Label like''%' + rtrim(ltrim(@Label)) + '%'')' 
	else if (@Labeled = 1)  
		set @sch = @sch + ' and r.checked = 1 ' 
	if (@CalltimeTo !=0)  
		set @sch = @sch + ' and r.seconds between ' + str(@CalltimeFrom*60) + ' and ' + str(@CalltimeTo*60) 
	if (@MutetimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.muteTime, 0) between ' + str(@MutetimeFrom) + ' and ' + str(@MutetimeTo) 
	if (@HoldtimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.holdTime, 0) between ' + str(@HoldtimeFrom) + ' and ' + str(@HoldtimeTo) 
	if (@ConferencetimeTo !=0)  
		set @sch = @sch + ' and isnull(ra.conferenceTime, 0) between ' + str(@ConferencetimeFrom) + ' and ' + str(@ConferencetimeTo) 
	if (@RecordID !=0)  begin
		--set @sch = @sch + ' and r.RecordID like ''' + cast(@RecordID as varchar(20)) + '%'''	 
		set @sch = @sch + ' and r.RecordID=' + cast(@RecordID as varchar(20))		
	end
	else begin
		if (@UCID != '') begin
			set @sch = @sch + ' and r.ucid like ''' + ltrim(@UCID) + '%'''
		end
	end

	if len(@TrunkGroup) > 0 begin
		set @TrunkGroup = ',' + @TrunkGroup + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar,(r.channel/1000)) + '','' ,''' + @TrunkGroup + ''') > 0 '
	end
		
	if len(@projId) > 0 begin
		set @projId = ',' + @projId + ','
		select @sch = @sch + ' and charindex('','' + convert(varchar, r.projId) + '','' ,''' + @projId + ''') > 0 '
	end

	set @direction = isnull(@direction, '')
	if (@direction = 'in' or @direction = 'inbound') begin
		set @sch = @sch + ' and inbound = 1 and outbound = 0'
	end
	if (@direction = 'out' or @direction = 'outbound') begin
		set @sch = @sch + ' and outbound = 1'
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
	
	if (@LogID >1) begin 
		declare @type smallint  
		set @type = (select type  from supervisor where logid=@logID) 
		set @type = isnull(@type, 0) 
		if (@type = 1)  begin 
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
		else if (@type=2) begin 
			declare @tasks_all varchar(1000) 
			set @tasks_all = (select tasks from supervisor where logid=@logID) 
			set @tasks_all = ltrim(rtrim(isnull(@tasks_all, ''))) 
			if (@tasks_all !='') 
				set @tasks_all = 't.taskid in (' + @tasks_all+ ')' 
			else 
			 	set @tasks_all = 't.taskid= 0 ' 
			set @tasks_all = 'and (' + @tasks_all + ') ' 
			set @sch = @sch + @tasks_all 
		end 
	end 

	set @sch = 'select * from (' 
			 + @sch  + ' and r.seconds>0 '
			 + case when @bPrivilege > 0 then '
						and exists(select 1 from #t_record tr 
										where tr.recordid = r.recordid)' else '' end
			 + ') t '
			 + ' 
					order by t.' + @Orderby + ' desc '

	print @sch

	execute(@sch) 
	
	IF OBJECT_ID('tempdb..#t_record') IS NOT NULL BEGIN
		DROP TABLE #t_record
		PRINT 'drop temp table #t_record'
	END
	
END
GO
/****** Object:  StoredProcedure [dbo].[usp_sch_station]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_sch_station]  
	@Station varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = '' 
AS  
	declare @sch varchar(2000)  
	if (@Station=null or @Station= '')   
		set @Station = ' Station = Station '  
	else   
		set @Station = ' Station like ''' + ltrim(rtrim(@Station)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'ip'  
	set @sch = 'select * from station where '  + @Station + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_storage]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_sch_storage] 
	@Station  varchar(200) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = '',
	@storagetype tinyint = 3 
AS  
	declare @sch varchar(2000)  
	

	if (@Station=null or @Station= '') begin   
		set @Station = ' Station = Station '
	end  
	else begin   
		set @Station = ' Station like ''' + ltrim(rtrim(@Station)) + '%'''  
	end
	if (@orderBy=null or @orderBy= '')  begin
		set @orderBy = 'ftpid'  
	end
	if (@storagetype != 3) begin
		set @Station = @Station + ' and (storagetype=' + cast(@storagetype as varchar(20)) + ' or storagetype=3)'  
	end
	set @sch = 'select * from storage where '  + @Station + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_supervisor]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_supervisor]  
	@logUser varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = ''  
AS  
	declare @sch varchar(2000)  
	if (@logUser=null or @logUser= '')   
		set @logUser = ' logUser = logUser '  
	else   
		set @logUser = ' logUser like ''' + ltrim(rtrim(@logUser)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'logUser'  
	set @sch = 'select * from supervisor where '  + @logUser + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_trunk]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_trunk]
	@TrunkID int = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = ''  
AS  
	declare @sch varchar(2000)  
	if (@TrunkID=0)   
		set @sch = ' trunkid = trunkid'  
	else   
		set @sch = ' trunkid like ''' + ltrim(rtrim(@TrunkID)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'trunkid'  
	set @sch = 'select  t.trunkid, t.trunknum, g.station, g.groupname from trunk t left join trunkgroup g on  g.groupid=t.trunkgroup where  '  + @sch + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_trunkgroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_sch_trunkgroup]  
	@groupName varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = null  
AS  
	declare @sch varchar(2000)  
	if (@groupName is null or @groupName= '')   
		set @groupName = ' groupName = groupName '  
	else   
		set @groupName = ' groupName like ''' + ltrim(rtrim(@groupName)) + '%'''  

	if (@orderBy is null or @orderBy= '')  
		set @orderBy = 'groupid'  

	set @sch = 'select t.*, v.typename, f.station ftphost, f.folder ftpfolder from trunkgroup t left join voicetype v on v.typeid = t.voicetype left join storage f on t.ftpid = f.ftpid  where '  + @groupName + ' order by ' + @orderBy + '  ' + isnull(@order, '')  

	print @sch  

	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_vdn]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_vdn]  
	@vdn varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = ''  
AS  
	declare @sch varchar(2000)  
	if (@vdn=null or @vdn= '')   
		set @vdn = ' vdn = vdn '  
	else   
		set @vdn = ' vdn like ''' + ltrim(rtrim(@vdn)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'vdn'  
	set @sch = 'select * from vdn where '  + @vdn + ' order by ' + @orderBy + '  ' + @order  
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_sch_vpbchannel]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_sch_vpbchannel]  
	@channel varchar(100) = null,  
	@orderBy varchar(20) = null,  
	@order varchar(20) = ''  
AS  
	declare @sch varchar(2000)  
	if (@channel=null or @channel= '')   
		set @channel = ' channel = channel '  
	else   
		set @channel = ' channel like ''' + ltrim(rtrim(@channel)) + '%'''  
	if (@orderBy=null or @orderBy= '')  
		set @orderBy = 'channel'  
	set @sch = 'select * from vpbchannel where '  + @channel + ' order by ' + @orderBy + '  ' +  isnull(@order, '') 
	execute(@sch)  
	select @@rowcount counts


GO
/****** Object:  StoredProcedure [dbo].[usp_schedule_records_daily_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_schedule_records_daily_update] 
	@StartDate varchar(8) = null 
AS 
	declare @TYPE_PASSIVE int, @TYPE_EXTENSION int,  @TYPE_CTI_ENABLED int, @TYPE_AGENT_ENABLED int
	set @TYPE_PASSIVE 	  	= 1
	set @TYPE_EXTENSION 	= 2
	set @TYPE_CTI_ENABLED 	= 4
	set @TYPE_AGENT_ENABLED	= 8

	--0 defalut
	--1 passive enable
	--2 cti enable	
	--3 agent enabled
	--See Also usp_init_menu

	declare @MaxRecords int, @MinRecords int, @sch varchar(1000), @Period int 
	declare @LineMode int

	if @StartDate is null or @StartDate ='' begin 
		declare @Yesterday datetime 
		set @Yesterday = dateadd(day, -1, getdate()) 
		set @StartDate = str(DATEPART(yy, @Yesterday),4) + substring(str(100+DATEPART(mm, @Yesterday),3),2,2) + substring(str(100+DATEPART(dd, @Yesterday),3),2,2) 
	end 

	select @Period = value from [system] where [key]='RecordsUpdatePeriod' 
	if (@Period is null or @Period = 0)  
		set @Period = 3 
	select @LineMode = value from [system] where [key]='LineMode'

	delete connection where recordid in (select recordid from records where startdate<20000000)
	delete records where startdate<20000000

	if (@LineMode is not null) and (@LineMode & @TYPE_EXTENSION !=0) and (@LineMode & @TYPE_AGENT_ENABLED =0)
		execute('usp_stat_update_ext ' + @StartDate)
	else
		execute('usp_stat_update ' + @StartDate)

	execute('usp_bill_update ' + @StartDate)

	/*put records into history table*/ 
	select @MaxRecords = max(recordId)  from records where DATEDIFF(month, starttime, @StartDate) > @Period and Startdate>'20010000'
	select @MinRecords  = min(recordId)  from records where DATEDIFF(month, starttime, @StartDate) > @Period and Startdate>'20010000'

	if (@MaxRecords is not null and @MaxRecords > 0) begin 
		print 'Max Records: ' + str(@MaxRecords) + 'Min Records:' + str(@MinRecords) +  '   Period: ' + str(@Period) 
		BEGIN TRANSACTION 
			delete History_Connection where recordid>=@MinRecords
			delete History_Records where recordid>=@MinRecords
			delete History_AgentGroupRec where recordid>=@MinRecords
			delete History_AddressGroupRec where recordid>=@MinRecords
			delete History_TaskRec where recordid>=@MinRecords
			insert into History_Records select * from Records where recordId <= @MaxRecords 
			insert into History_Connection select * from Connection where recordId <= @MaxRecords 
			insert into History_AgentGroupRec select * from AgentGroupRec where recordId <= @MaxRecords 
			insert into History_AddressGroupRec select * from AddressGroupRec where recordId <= @MaxRecords 
			insert into History_TaskRec select * from TaskRec where recordId <= @MaxRecords 
			delete Connection where recordId <= @MaxRecords 
			delete Records where recordId <= @MaxRecords 
			delete AgentGroupRec where recordId <= @MaxRecords 
			delete  AddressGroupRec where recordId <= @MaxRecords 
			delete TaskRec where recordId <= @MaxRecords 
		COMMIT TRANSACTION 
	end 
	else 
		print 'None data need to be put into history table!'


GO
/****** Object:  StoredProcedure [dbo].[usp_schedule_records_interim_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_schedule_records_interim_update] 
	@StartDate varchar(8) = null, 
	@EndDate varchar(8) = null 
AS 
	if (@StartDate = null) 
		set @StartDate = str(DATEPART(yy, getdate()),4) + substring(str(100+DATEPART(mm, getdate()),3),2,2) + substring(str(100+DATEPART(dd, getdate()),3),2,2) 
	if (@EndDate = null) 
		set @EndDate = @StartDate 
	insert AgentGroupRec 
		select distinct g.GroupId, c.RecordId, g.AgentId  
		from records r left join connection c on c.RecordId = r.RecordId left join GroupAgent g on g.AgentId = c.Agent 
		where c.Agent !=0  
			and r.RecordId not in (select RecordId from AgentGroupRec) 
			and g.GroupId is not null 
			and r.StartDate between @StartDate and @EndDate 
			and ((g.TimeType=0)  
				or (g.TimeType=1 and substring(str(100+DATEPART(hh, Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, Starttime),3),2,2) between g.timefrom and g.timeto)  
				or (g.TimeType=2 and (substring(str(100+DATEPART(hh, Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, Starttime),3),2,2) between g.timefrom and g.timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, Starttime)*3 - 2, 2)&g.weeks!=0) )) 
			and r.finished > 0 
	insert AddressGroupRec 
		select distinct g.GroupId, c.RecordId, g.Address 
		from records r left join connection c on c.RecordId = r.RecordId left join GroupAddress g on g.Address = c.Device 
		where c.Agent !=0  
			and r.RecordId not in (select RecordId from AddressGroupRec) 
			and g.GroupId is not null 
			and r.StartDate between @StartDate and @EndDate 
			and r.finished > 0


GO
/****** Object:  StoredProcedure [dbo].[usp_set_filter]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_set_filter] 
	@Phone varchar(20)
AS
	insert filter (phone) values (@Phone)


GO
/****** Object:  StoredProcedure [dbo].[usp_set_finishedrecord]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_set_finishedrecord]  
	@RecordId int = 0  
AS  
	update records set finished=1 where recordid=@RecordId


GO
/****** Object:  StoredProcedure [dbo].[usp_set_label]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_set_label]  
	@RecordID int = 0,  
	@Label varchar(50),  
	@Description varchar(500),  
	@Labelid int = 0,  
	@Userid int = 0, 
	@Flag tinyint = 0 
AS  
	declare @newID int  
	if @Labelid!=0 and Exists (select top 1 * from label where recordid=@RecordID and labelid=@Labelid)  
		update  label  set label=@Label, description=@Description, userid=@Userid, updatedate = getdate(), flag=@Flag where recordid=@RecordID and  labelid=@Labelid   
	else   
		insert label (recordid, label, description, userid, updatedate, flag) values (@Recordid, @Label, @Description, @Userid, getdate(), @Flag) 
	update records set checked = 1 where recordid = @RecordID 
	if (Exists (select top 1 * from FormRec where recordid=@RecordID)) 
		update FormRec set flag = @Flag, userid = @Userid,  updatedate = getdate() where recordid=@RecordID 
	else  
		insert FormRec (recordid, userid, updatedate) values (@RecordID, @Userid, getdate())


GO
/****** Object:  StoredProcedure [dbo].[usp_set_project]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_set_project]
	@Obj varchar(10),
	@ObjId int,
	@ProjId int
AS
	if @Obj = 'bill'
		update bill 
		set projId = @ProjId
		where billId = @ObjId
	else
		update records
		set projId = @ProjId
		where recordId = @ObjId


GO
/****** Object:  StoredProcedure [dbo].[usp_stat_install]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_stat_install]
AS
	declare @StartDate varchar(8), @EndDate varchar(8) 
	set @StartDate = (select top 1 Startdate from records)
	set @EndDate = (select top 1 Startdate from records order by recordid desc)
	execute usp_stat_update @StartDate, @EndDate


GO
/****** Object:  StoredProcedure [dbo].[usp_stat_ScreenPerDaily_ByStation]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_stat_ScreenPerDaily_ByStation]
	-- Add the parameters for the stored procedure here
	@in_BeginDT varchar(8),
	@in_EndDT varchar(8)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [StartDate],[TrsStation]
		  ,count([RecFlag]) VoiceCount
		  ,sum([ScrFlag]) ScreenCount
		  ,CASE WHEN count([RecFlag])=0 THEN '0.00%' ELSE str(sum([ScrFlag])*100.0/count([RecFlag]),5,2) +'%' END Screen_Percentage 
		  ,sum([VideoFlag]) VideoCount
	  FROM [dbo].[Records]
	  WHERE [StartDate]>=@in_BeginDT and [StartDate]<=@in_EndDT
	  GROUP BY [StartDate],[TrsStation]
	  ORDER BY [StartDate]
END

GO
/****** Object:  StoredProcedure [dbo].[usp_stat_ScreenPerDaily_Total]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_stat_ScreenPerDaily_Total]
	-- Add the parameters for the stored procedure here
	@in_BeginDT varchar(8),
	@in_EndDT varchar(8)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [StartDate]
		  ,count([RecFlag]) VoiceCount
		  ,sum([ScrFlag]) ScreenCount
		  ,CASE WHEN count([RecFlag])=0 THEN '0.00%' ELSE str(sum([ScrFlag])*100.0/count([RecFlag]),5,2) +'%' END Screen_Percentage 
		  ,sum([VideoFlag]) VideoCount
	  FROM [dbo].[Records]
	  WHERE [StartDate]>=@in_BeginDT and [StartDate]<=@in_EndDT
	  GROUP BY [StartDate]
	  ORDER BY [StartDate]
END


GO
/****** Object:  StoredProcedure [dbo].[usp_stat_ScreenPerHourly_ByStation]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_stat_ScreenPerHourly_ByStation]
	-- Add the parameters for the stored procedure here
	@in_BeginDT varchar(8)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [StartDate],[StartHour],[TrsStation]
		  ,count([RecFlag]) VoiceCount
		  ,sum([ScrFlag]) ScreenCount	  
		  ,CASE WHEN count([RecFlag])=0 THEN '0.00%' ELSE str(sum([ScrFlag])*100.0/count([RecFlag]),5,2) +'%' END Screen_Percentage 
		  ,sum([VideoFlag]) VideoCount
	  FROM [dbo].[Records]
	  WHERE [StartDate]=@in_BeginDT 
	  GROUP BY [StartDate],[StartHour],[TrsStation]
	  ORDER BY [StartDate],[TrsStation],[StartHour]
END


GO
/****** Object:  StoredProcedure [dbo].[usp_stat_ScreenPerHourly_Total]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[usp_stat_ScreenPerHourly_Total]
	-- Add the parameters for the stored procedure here
	@in_BeginDT varchar(8)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [StartDate],[StartHour]
		  ,count([RecFlag]) VoiceCount
		  ,sum([ScrFlag]) ScreenCount
		  ,CASE WHEN count([RecFlag])=0 THEN '0.00%' ELSE str(sum([ScrFlag])*100.0/count([RecFlag]),5,2) +'%' END Screen_Percentage 
		  ,sum([VideoFlag]) VideoCount
	  FROM [dbo].[Records]
	  WHERE [StartDate]=@in_BeginDT
	  GROUP BY [StartDate],[StartHour]
	  ORDER BY [StartDate],[StartHour]
END


GO
/****** Object:  StoredProcedure [dbo].[usp_stat_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_stat_update]  
	@DateFrom int = 0,  
	@DateTo int = 0  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @DateFrom < 20000101 return 0  
	if @DateTo = 0 set @DateTo = @DateFrom  

	exec usp_records_append @DateFrom = @DateFrom, @DateTo = @DateTo

	/*Task*/ 
	print('task...') 
	delete from StatTaskAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatTask where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatTask  
	select cast(r.StartDate as int) StatDate, tr.taskid,  count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57, 
 		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r  
		inner join TaskRec tr on r.recordid = tr.recordid  
		inner join connection c on c.RecordId = r.RecordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8) 
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
	group by r.StartDate, tr.taskid 
	set @RowCount = @@RowCount  
	if @RowCount > 0 begin 
		insert into StatTaskAgents  
			select r.StartDate, tr.TaskId, c.agent  
			from records r  
				inner join TaskRec tr on r.recordid = tr.recordid  
				inner join connection c on c.recordId = r.recordId 
			where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
				and r.seconds > 0 and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
			group by r.StartDate, tr.TaskID, c.agent  
	end  

	/*Group*/ 
	print('group...') 
	delete from StatGroupAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatGroup where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatGroup  
	select cast(r.StartDate as int) StatDate, gr.groupid, count(distinct gr.agentid) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total, 
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r  
		inner join connection c on r.recordid = c.recordid  
		inner join AgentGroupRec gr on r.recordid = gr.recordid and c.agent = gr.agentid 
	where  r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
	group by r.StartDate, gr.groupid 

	insert into StatGroupAgents  
		select cast(r.StartDate as int) StatDate, gr.groupid, c.Agent  
	from records r  
		inner join connection c on r.recordid = c.recordid  
		inner join AgentGroupRec gr on r.recordid = gr.recordid and c.agent = gr.agentid 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
	group by r.StartDate, gr.groupid, c.Agent  

	/*Agent*/ 
	print('agent...') 
	delete from StatAgent where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatAgent  
	select cast(r.StartDate as int) StatDate, c.agent as agentid , 1 agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total, 
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on r.recordid = c.recordid 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
	group by  r.StartDate, c.agent 

	/*Daily*/ 
	print('daily...') 
	delete from StatDailyAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatDaily where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatDaily  
	select cast(r.StartDate as int) StatDate, max(r.Recordid), min(r.Recordid), count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on  r.recordId = c.RecordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
	group by r.StartDate  
	insert into StatDailyAgents  
	select r.StartDate, c.Agent 
	from records r  
		inner join connection c on c.recordID = r.recordID 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by r.StartDate, c.Agent 

	/*Hour*/ 
	print('hour...') 
	delete from StatHourAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatHour where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatHour  
	select cast(r.StartDate as int) StatDate, r.StartHour,   
		count(distinct c.agent) agents, count(distinct r.recordId) times, sum(c.leave-c.enter) total,  
		sum(case seconds / 30 when  0 then 1 else 0 end) M0,   
		sum(case seconds / 30 when  1 then 1 else 0 end) M1,  
		sum(case seconds / 30 when  2 then 1 else 0 end) M2,  
		sum(case seconds / 30 when  3 then 1 else 0 end) M3,  
		sum(case seconds / 30 when  4 then 1 else 0 end) M4,  
		sum(case seconds / 30 when  5 then 1 else 0 end) M5,  
		sum(case seconds / 30 when  6 then 1 else 0 end) M6,  
		sum(case seconds / 30 when  7 then 1 else 0 end) M7,  
		sum(case seconds / 30 when  8 then 1 else 0 end) M8,  
		sum(case seconds / 30 when  9 then 1 else 0 end) M9,  
		sum(case seconds / 30 when 10 then 1 else 0 end) M10,  
		sum(case seconds / 30 when 11 then 1 else 0 end) M11,  
		sum(case seconds / 30 when 12 then 1 else 0 end) M12,  
		sum(case seconds / 30 when 13 then 1 else 0 end) M13,  
		sum(case seconds / 30 when 14 then 1 else 0 end) M14,  
		sum(case seconds / 30 when 15 then 1 else 0 end) M15,  
		sum(case seconds / 30 when 16 then 1 else 0 end) M16,  
		sum(case seconds / 30 when 17 then 1 else 0 end) M17,  
		sum(case seconds / 30 when 18 then 1 else 0 end) M18,  
		sum(case seconds / 30 when 19 then 1 else 0 end) M19,  
		sum(case seconds / 30 when 20 then 1 else 0 end) M20,  
		sum(case seconds / 30 when 21 then 1 else 0 end) M21,  
		sum(case seconds / 30 when 22 then 1 else 0 end) M22,  
		sum(case seconds / 30 when 23 then 1 else 0 end) M23,  
		sum(case seconds / 30 when 24 then 1 else 0 end) M24,  
		sum(case seconds / 30 when 25 then 1 else 0 end) M25,  
		sum(case seconds / 30 when 26 then 1 else 0 end) M26,  
		sum(case seconds / 30 when 27 then 1 else 0 end) M27,  
		sum(case seconds / 30 when 28 then 1 else 0 end) M28,  
		sum(case seconds / 30 when 29 then 1 else 0 end) M29,  
		sum(case seconds / 30 when 30 then 1 else 0 end) M30,  
		sum(case seconds / 30 when 31 then 1 else 0 end) M31,  
		sum(case seconds / 30 when 32 then 1 else 0 end) M32,  
		sum(case seconds / 30 when 33 then 1 else 0 end) M33,  
		sum(case seconds / 30 when 34 then 1 else 0 end) M34,  
		sum(case seconds / 30 when 35 then 1 else 0 end) M35,  
		sum(case seconds / 30 when 36 then 1 else 0 end) M36,  
		sum(case seconds / 30 when 37 then 1 else 0 end) M37,  
		sum(case seconds / 30 when 38 then 1 else 0 end) M38,  
		sum(case seconds / 30 when 39 then 1 else 0 end) M39,  
		sum(case seconds / 30 when 40 then 1 else 0 end) M40,  
		sum(case seconds / 30 when 41 then 1 else 0 end) M41,  
		sum(case seconds / 30 when 42 then 1 else 0 end) M42,  
		sum(case seconds / 30 when 43 then 1 else 0 end) M43,  
		sum(case seconds / 30 when 44 then 1 else 0 end) M44,  
		sum(case seconds / 30 when 45 then 1 else 0 end) M45,  
		sum(case seconds / 30 when 46 then 1 else 0 end) M46,  
		sum(case seconds / 30 when 47 then 1 else 0 end) M47,  
		sum(case seconds / 30 when 48 then 1 else 0 end) M48,  
		sum(case seconds / 30 when 49 then 1 else 0 end) M49,  
		sum(case seconds / 30 when 50 then 1 else 0 end) M50,  
		sum(case seconds / 30 when 51 then 1 else 0 end) M51,  
		sum(case seconds / 30 when 52 then 1 else 0 end) M52,  
		sum(case seconds / 30 when 53 then 1 else 0 end) M53,  
		sum(case seconds / 30 when 54 then 1 else 0 end) M54,  
		sum(case seconds / 30 when 55 then 1 else 0 end) M55,  
		sum(case seconds / 30 when 56 then 1 else 0 end) M56,  
		sum(case seconds / 30 when 57 then 1 else 0 end) M57,  
		sum(case seconds / 30 when 58 then 1 else 0 end) M58,  
		sum(case seconds / 30 when 59 then 1 else 0 end) M59,  
		sum(case seconds / 30 when 60 then 1 else 0 end) M60,  
		sum(case seconds / 30 when 61 then 1 else 0 end) M61,  
		sum(case seconds / 30 when 62 then 1 else 0 end) M62,  
		sum(case seconds / 30 when 63 then 1 else 0 end) M63,  
		sum(case seconds / 30 when 64 then 1 else 0 end) M64,  
		sum(case seconds / 30 when 65 then 1 else 0 end) M65,  
		sum(case seconds / 30 when 66 then 1 else 0 end) M66,  
		sum(case seconds / 30 when 67 then 1 else 0 end) M67,  
		sum(case seconds / 30 when 68 then 1 else 0 end) M68,  
		sum(case seconds / 30 when 69 then 1 else 0 end) M69,  
		sum(case seconds / 2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on c.recordId = r.recordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent != 0 /* and r.finished > 0 */
	group by  r.StartDate, r.StartHour  
	insert into StatHourAgents  
	select cast(r.StartDate as int) StatDate, r.StartHour, c.Agent  
	from records r inner join connection c on c.recordId = r.recordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by r.StartDate, r.StartHour, c.Agent



GO
/****** Object:  StoredProcedure [dbo].[usp_stat_update_ext]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_stat_update_ext]  
	@DateFrom int = 0,  
	@DateTo int = 0  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @DateFrom < 20000101 return 0  
	if @DateTo = 0 set @DateTo = @DateFrom  

	/*Task*/ 
	print('task...') 
	delete from StatTaskAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatTask where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatTask  
	select cast(r.StartDate as int) StatDate, tr.taskid,  count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r  
		inner join TaskRec tr on r.recordid = tr.recordid  
		inner join connection c on c.RecordId = r.RecordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8) 
		and c.leave-c.enter > 0  
		and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
	group by r.StartDate, tr.taskid 

	set @RowCount = @@RowCount  
	if @RowCount > 0 begin 
		insert into StatTaskAgents  
			select r.StartDate, tr.TaskId, c.device  
			from records r  
				inner join TaskRec tr on r.recordid = tr.recordid  
				inner join connection c on c.recordId = r.recordId 
			where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
				and r.seconds > 0 and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
			group by r.StartDate, tr.TaskID, c.device  
	end  

	/*ext*/ 
	print('ext...') 
	delete from StatExt where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatExt  
	select cast(r.StartDate as int) StatDate, c.device as subid , 1 exts, count(distinct r.RecordId) times, sum(c.leave-c.enter) total, 
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on r.recordid = c.recordid 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
	group by  r.StartDate, c.device 

	/*Daily*/ 
	print('daily...') 
	delete from StatDailyAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatDaily where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatDaily  
	select cast(r.StartDate as int) StatDate, max(r.Recordid), min(r.Recordid), count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on  r.recordId = c.RecordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
	group by r.StartDate  

	insert into StatDailyAgents  
	select r.StartDate, c.device 
	from records r  
		inner join connection c on c.recordID = r.recordID 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
	group by r.StartDate, c.device 

	/*Hour*/ 
	print('hour...') 
	delete from StatHourAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatHour where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatHour  

	select cast(r.StartDate as int) StatDate, r.StartHour,   
		count(distinct c.device) agents, count(distinct r.recordId) times, sum(c.leave-c.enter) total,  
		sum(case seconds / 30 when  0 then 1 else 0 end) M0,   
		sum(case seconds / 30 when  1 then 1 else 0 end) M1,  
		sum(case seconds / 30 when  2 then 1 else 0 end) M2,  
		sum(case seconds / 30 when  3 then 1 else 0 end) M3,  
		sum(case seconds / 30 when  4 then 1 else 0 end) M4,  
		sum(case seconds / 30 when  5 then 1 else 0 end) M5,  
		sum(case seconds / 30 when  6 then 1 else 0 end) M6,  
		sum(case seconds / 30 when  7 then 1 else 0 end) M7,  
		sum(case seconds / 30 when  8 then 1 else 0 end) M8,  
		sum(case seconds / 30 when  9 then 1 else 0 end) M9,  
		sum(case seconds / 30 when 10 then 1 else 0 end) M10,  
		sum(case seconds / 30 when 11 then 1 else 0 end) M11,  
		sum(case seconds / 30 when 12 then 1 else 0 end) M12,  
		sum(case seconds / 30 when 13 then 1 else 0 end) M13,  
		sum(case seconds / 30 when 14 then 1 else 0 end) M14,  
		sum(case seconds / 30 when 15 then 1 else 0 end) M15,  
		sum(case seconds / 30 when 16 then 1 else 0 end) M16,  
		sum(case seconds / 30 when 17 then 1 else 0 end) M17,  
		sum(case seconds / 30 when 18 then 1 else 0 end) M18,  
		sum(case seconds / 30 when 19 then 1 else 0 end) M19,  
		sum(case seconds / 30 when 20 then 1 else 0 end) M20,  
		sum(case seconds / 30 when 21 then 1 else 0 end) M21,  
		sum(case seconds / 30 when 22 then 1 else 0 end) M22,  
		sum(case seconds / 30 when 23 then 1 else 0 end) M23,  
		sum(case seconds / 30 when 24 then 1 else 0 end) M24,  
		sum(case seconds / 30 when 25 then 1 else 0 end) M25,  
		sum(case seconds / 30 when 26 then 1 else 0 end) M26,  
		sum(case seconds / 30 when 27 then 1 else 0 end) M27,  
		sum(case seconds / 30 when 28 then 1 else 0 end) M28,  
		sum(case seconds / 30 when 29 then 1 else 0 end) M29,  
		sum(case seconds / 30 when 30 then 1 else 0 end) M30,  
		sum(case seconds / 30 when 31 then 1 else 0 end) M31,  
		sum(case seconds / 30 when 32 then 1 else 0 end) M32,  
		sum(case seconds / 30 when 33 then 1 else 0 end) M33,  
		sum(case seconds / 30 when 34 then 1 else 0 end) M34,  
		sum(case seconds / 30 when 35 then 1 else 0 end) M35,  
		sum(case seconds / 30 when 36 then 1 else 0 end) M36,  
		sum(case seconds / 30 when 37 then 1 else 0 end) M37,  
		sum(case seconds / 30 when 38 then 1 else 0 end) M38,  
		sum(case seconds / 30 when 39 then 1 else 0 end) M39,  
		sum(case seconds / 30 when 40 then 1 else 0 end) M40,  
		sum(case seconds / 30 when 41 then 1 else 0 end) M41,  
		sum(case seconds / 30 when 42 then 1 else 0 end) M42,  
		sum(case seconds / 30 when 43 then 1 else 0 end) M43,  
		sum(case seconds / 30 when 44 then 1 else 0 end) M44,  
		sum(case seconds / 30 when 45 then 1 else 0 end) M45,  
		sum(case seconds / 30 when 46 then 1 else 0 end) M46,  
		sum(case seconds / 30 when 47 then 1 else 0 end) M47,  
		sum(case seconds / 30 when 48 then 1 else 0 end) M48,  
		sum(case seconds / 30 when 49 then 1 else 0 end) M49,  
		sum(case seconds / 30 when 50 then 1 else 0 end) M50,  
		sum(case seconds / 30 when 51 then 1 else 0 end) M51,  
		sum(case seconds / 30 when 52 then 1 else 0 end) M52,  
		sum(case seconds / 30 when 53 then 1 else 0 end) M53,  
		sum(case seconds / 30 when 54 then 1 else 0 end) M54,  
		sum(case seconds / 30 when 55 then 1 else 0 end) M55,  
		sum(case seconds / 30 when 56 then 1 else 0 end) M56,  
		sum(case seconds / 30 when 57 then 1 else 0 end) M57,  
		sum(case seconds / 30 when 58 then 1 else 0 end) M58,  
		sum(case seconds / 30 when 59 then 1 else 0 end) M59,  
		sum(case seconds / 30 when 60 then 1 else 0 end) M60,  
		sum(case seconds / 30 when 61 then 1 else 0 end) M61,  
		sum(case seconds / 30 when 62 then 1 else 0 end) M62,  
		sum(case seconds / 30 when 63 then 1 else 0 end) M63,  
		sum(case seconds / 30 when 64 then 1 else 0 end) M64,  
		sum(case seconds / 30 when 65 then 1 else 0 end) M65,  
		sum(case seconds / 30 when 66 then 1 else 0 end) M66,  
		sum(case seconds / 30 when 67 then 1 else 0 end) M67,  
		sum(case seconds / 30 when 68 then 1 else 0 end) M68,  
		sum(case seconds / 30 when 69 then 1 else 0 end) M69,  
		sum(case seconds / 2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on c.recordId = r.recordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
	group by  r.StartDate, r.StartHour  

	insert into StatHourAgents  
	select cast(r.StartDate as int) StatDate, r.StartHour, c.device  
	from records r inner join connection c on c.recordId = r.recordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
	group by r.StartDate, r.StartHour, c.device


GO
/****** Object:  StoredProcedure [dbo].[usp_stat_update_none]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_stat_update_none]  
	@DateFrom int = 0,  
	@DateTo int = 0  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @DateFrom < 20000101 return 0  
	if @DateTo = 0 set @DateTo = @DateFrom  

	/*Task*/ 
	print('task...') 
	delete from StatTaskAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatTask where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatTask  
	select cast(r.StartDate as int) StatDate, tr.taskid,  count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  

		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r  
		inner join TaskRec tr on r.recordid = tr.recordid  
		inner join connection c on c.RecordId = r.RecordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8) 
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by r.StartDate, tr.taskid 
	set @RowCount = @@RowCount  
	if @RowCount > 0 begin 
		insert into StatTaskAgents  
			select r.StartDate, tr.TaskId, c.agent  
			from records r  
				inner join TaskRec tr on r.recordid = tr.recordid  
				inner join connection c on c.recordId = r.recordId 
			where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
				and r.seconds > 0 and c.agent is not null and c.agent !='' 
			group by r.StartDate, tr.TaskID, c.agent  
	end  

	/*Agent*/ 
	print('ext...') 
	delete from StatAgent where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatAgent  
	select cast(r.StartDate as int) StatDate, c.agent as agentid , 1 agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total, 
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  

		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on r.recordid = c.recordid 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by  r.StartDate, c.agent 

	/*Daily*/ 
	print('daily...') 
	delete from StatDailyAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatDaily where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatDaily  
	select cast(r.StartDate as int) StatDate, max(r.Recordid), min(r.Recordid), count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
		sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
		sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
		sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
		sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
		sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
		sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
		sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
		sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
		sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
		sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
		sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
		sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
		sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
		sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
		sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
		sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
		sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
		sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
		sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
		sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
		sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
		sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
		sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
		sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
		sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
		sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
		sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
		sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
		sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
		sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
		sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
		sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
		sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
		sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
		sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
		sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
		sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
		sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
		sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
		sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
		sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
		sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
		sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
		sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
		sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
		sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
		sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
		sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
		sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
		sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
		sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
		sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
		sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
		sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
		sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
		sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
		sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
		sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
		sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
		sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
		sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
		sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
		sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
		sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
		sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
		sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
		sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
		sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
		sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
		sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
		sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on  r.recordId = c.RecordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by r.StartDate  
	insert into StatDailyAgents  
	select r.StartDate, c.Agent 
	from records r  
		inner join connection c on c.recordID = r.recordID 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by r.StartDate, c.Agent 

	/*Hour*/ 
	print('hour...') 
	delete from StatHourAgents where StatDate >= @DateFrom and StatDate <= @DateTo  
	delete from StatHour where StatDate >= @DateFrom and StatDate <= @DateTo  
	insert into StatHour  
	select cast(r.StartDate as int) StatDate, r.StartHour,   
		count(distinct c.agent) agents, count(distinct r.recordId) times, sum(c.leave-c.enter) total,  
		sum(case seconds / 30 when  0 then 1 else 0 end) M0,   
		sum(case seconds / 30 when  1 then 1 else 0 end) M1,  
		sum(case seconds / 30 when  2 then 1 else 0 end) M2,  
		sum(case seconds / 30 when  3 then 1 else 0 end) M3,  
		sum(case seconds / 30 when  4 then 1 else 0 end) M4,  
		sum(case seconds / 30 when  5 then 1 else 0 end) M5,  
		sum(case seconds / 30 when  6 then 1 else 0 end) M6,  
		sum(case seconds / 30 when  7 then 1 else 0 end) M7,  
		sum(case seconds / 30 when  8 then 1 else 0 end) M8,  
		sum(case seconds / 30 when  9 then 1 else 0 end) M9,  
		sum(case seconds / 30 when 10 then 1 else 0 end) M10,  
		sum(case seconds / 30 when 11 then 1 else 0 end) M11,  
		sum(case seconds / 30 when 12 then 1 else 0 end) M12,  
		sum(case seconds / 30 when 13 then 1 else 0 end) M13,  
		sum(case seconds / 30 when 14 then 1 else 0 end) M14,  
		sum(case seconds / 30 when 15 then 1 else 0 end) M15,  
		sum(case seconds / 30 when 16 then 1 else 0 end) M16,  
		sum(case seconds / 30 when 17 then 1 else 0 end) M17,  
		sum(case seconds / 30 when 18 then 1 else 0 end) M18,  
		sum(case seconds / 30 when 19 then 1 else 0 end) M19,  
		sum(case seconds / 30 when 20 then 1 else 0 end) M20,  
		sum(case seconds / 30 when 21 then 1 else 0 end) M21,  
		sum(case seconds / 30 when 22 then 1 else 0 end) M22,  
		sum(case seconds / 30 when 23 then 1 else 0 end) M23,  
		sum(case seconds / 30 when 24 then 1 else 0 end) M24,  
		sum(case seconds / 30 when 25 then 1 else 0 end) M25,  
		sum(case seconds / 30 when 26 then 1 else 0 end) M26,  
		sum(case seconds / 30 when 27 then 1 else 0 end) M27,  
		sum(case seconds / 30 when 28 then 1 else 0 end) M28,  
		sum(case seconds / 30 when 29 then 1 else 0 end) M29,  
		sum(case seconds / 30 when 30 then 1 else 0 end) M30,  
		sum(case seconds / 30 when 31 then 1 else 0 end) M31,  
		sum(case seconds / 30 when 32 then 1 else 0 end) M32,  
		sum(case seconds / 30 when 33 then 1 else 0 end) M33,  
		sum(case seconds / 30 when 34 then 1 else 0 end) M34,  
		sum(case seconds / 30 when 35 then 1 else 0 end) M35,  
		sum(case seconds / 30 when 36 then 1 else 0 end) M36,  
		sum(case seconds / 30 when 37 then 1 else 0 end) M37,  
		sum(case seconds / 30 when 38 then 1 else 0 end) M38,  
		sum(case seconds / 30 when 39 then 1 else 0 end) M39,  
		sum(case seconds / 30 when 40 then 1 else 0 end) M40,  
		sum(case seconds / 30 when 41 then 1 else 0 end) M41,  
		sum(case seconds / 30 when 42 then 1 else 0 end) M42,  
		sum(case seconds / 30 when 43 then 1 else 0 end) M43,  
		sum(case seconds / 30 when 44 then 1 else 0 end) M44,  
		sum(case seconds / 30 when 45 then 1 else 0 end) M45,  
		sum(case seconds / 30 when 46 then 1 else 0 end) M46,  
		sum(case seconds / 30 when 47 then 1 else 0 end) M47,  
		sum(case seconds / 30 when 48 then 1 else 0 end) M48,  
		sum(case seconds / 30 when 49 then 1 else 0 end) M49,  
		sum(case seconds / 30 when 50 then 1 else 0 end) M50,  
		sum(case seconds / 30 when 51 then 1 else 0 end) M51,  
		sum(case seconds / 30 when 52 then 1 else 0 end) M52,  
		sum(case seconds / 30 when 53 then 1 else 0 end) M53,  
		sum(case seconds / 30 when 54 then 1 else 0 end) M54,  
		sum(case seconds / 30 when 55 then 1 else 0 end) M55,  
		sum(case seconds / 30 when 56 then 1 else 0 end) M56,  
		sum(case seconds / 30 when 57 then 1 else 0 end) M57,  
		sum(case seconds / 30 when 58 then 1 else 0 end) M58,  
		sum(case seconds / 30 when 59 then 1 else 0 end) M59,  
		sum(case seconds / 30 when 60 then 1 else 0 end) M60,  
		sum(case seconds / 30 when 61 then 1 else 0 end) M61,  
		sum(case seconds / 30 when 62 then 1 else 0 end) M62,  
		sum(case seconds / 30 when 63 then 1 else 0 end) M63,  
		sum(case seconds / 30 when 64 then 1 else 0 end) M64,  
		sum(case seconds / 30 when 65 then 1 else 0 end) M65,  
		sum(case seconds / 30 when 66 then 1 else 0 end) M66,  
		sum(case seconds / 30 when 67 then 1 else 0 end) M67,  
		sum(case seconds / 30 when 68 then 1 else 0 end) M68,  
		sum(case seconds / 30 when 69 then 1 else 0 end) M69,  
		sum(case seconds / 2100 when 0 then 0 else 1 end) M70  
	from records r inner join connection c on c.recordId = r.recordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by  r.StartDate, r.StartHour  
	insert into StatHourAgents  
	select cast(r.StartDate as int) StatDate, r.StartHour, c.Agent  
	from records r inner join connection c on c.recordId = r.recordId 
	where r.StartDate >= str(@DateFrom, 8) and r.StartDate <= str(@DateTo, 8)  
		and c.leave-c.enter > 0  
		and c.agent is not null and c.agent !=0 
	group by r.StartDate, r.StartHour, c.Agent


GO
/****** Object:  StoredProcedure [dbo].[usp_station_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_station_delete]  
  @IP varchar(15) = null,  
  @Station varchar(50) = null  
AS  
	if @IP is null and @Station is null return  
	if @IP is not null  set @IP  = ltrim(rtrim(@IP))  
	if @Station is not null set @Station = ltrim(rtrim(@Station))  
	delete Station  
	where IP = @IP  
		or Station = @Station


GO
/****** Object:  StoredProcedure [dbo].[usp_Station_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_Station_insert]  
	@IP varchar(15),  
	@Station varchar(20),  
	@ExtIP   varchar(500),
	@Enabled bit = 1  
AS  
	if @IP is null return  
	set @IP = ltrim(rtrim(@IP))  
	set @Station = ltrim(rtrim(isnull(@Station, '')))
	set @ExtIP = ltrim(rtrim(isnull(@ExtIP, '')))

	if (select count(*) from Station where IP = @IP or Station = @Station) = 0 begin 
		insert into Station (IP, Station, ExtIP, Enabled) values (@IP, @Station, @ExtIP, @Enabled)  
		select 1 'result' 
	end 
	else  
		select 0 'result' 
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_station_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_station_update]  
	@IP varchar(15) = null,  
	@Station varchar(20) = null,  
	@ExtIP varchar(500) = null,  
	@Enabled bit = null  
AS  
	if @IP is null and @Station is null return  
	if @IP is not null  set @IP  = ltrim(rtrim(@IP))  
	if @Station is not null set @Station = ltrim(rtrim(@Station))  
	if @ExtIP is not null set @ExtIP = ltrim(rtrim(@ExtIP))  

	update Station  
	set  
		IP    = isnull(@IP, IP),  
		Station   = isnull(@Station, Station),  
		ExtIP	 =  isnull(@ExtIP, ExtIP),  
		Enabled  = isnull(@Enabled, Enabled)   
	where  
		IP  = @IP  
		or Station  = @Station  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_statistic]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_statistic]  
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null,  
	@HourFrom int = 0,  
	@HourTo int = 24
AS  
	declare @LineMode int
	declare @TYPE_PASSIVE int, @TYPE_EXTENSION int,  @TYPE_CTI_ENABLED int, @TYPE_AGENT_ENABLED int
	set @TYPE_PASSIVE 	  	= 1
	set @TYPE_EXTENSION 	= 2
	set @TYPE_CTI_ENABLED 	= 4
	set @TYPE_AGENT_ENABLED	= 8
	--0 defalut
	--1 passive enable
	--2 cti enable	
	--3 agent enabled
	--See Also usp_init_menu	

	select @LineMode = value from [system] where [key] = 'LineMode'

	declare @datenow varchar(8);  
	set @datenow = str(datepart(year, getdate()),4) + right(str(100 + datepart(month, getdate()),3),2) + right(str(100+datepart(day, getdate()),3),2); 
	if left(@DateTimeFrom, 8) = left(@DateTimeTo, 8)  begin
		if (@LineMode is not null) and (@LineMode & @TYPE_EXTENSION !=0) and (@LineMode & @TYPE_AGENT_ENABLED =0)
			execute('usp_statistic_new_ext ''' +  @GroupBy + ''', ''' + @DateTimeFrom  + ''', ''' + @DateTimeTo + ''', ''' + @ID + ''', ' + @HourFrom + ',' + @HourTo); 
		else
			execute('usp_statistic_new ''' +  @GroupBy + ''', ''' + @DateTimeFrom  + ''', ''' + @DateTimeTo + ''', ''' + @ID + ''', ' + @HourFrom + ',' + @HourTo); 
	end
	else begin 
		if @datenow = left(@DateTimeFrom, 8) or @datenow = left(@DateTimeTo, 8)  begin
			if (@LineMode is not null) and (@LineMode & @TYPE_EXTENSION !=0) and (@LineMode & @TYPE_AGENT_ENABLED =0)
				execute('usp_stat_update_ext ' + @datenow)  
			else
				execute('usp_stat_update ' + @datenow)  
		end
		set @DateTimeFrom =  left(@DateTimeFrom, 8)  
		set @DateTimeTo =  left(@DateTimeTo, 8)  
	
		if (@LineMode is not null) and (@LineMode & @TYPE_EXTENSION !=0) and (@LineMode & @TYPE_AGENT_ENABLED =0)
			execute('usp_statistic_pool_ext ''' +  @GroupBy + ''', ''' + @DateTimeFrom + ''', ''' + @DateTimeTo + ''', ''' + @ID + ''', ' + @HourFrom + ',' + @HourTo);	  
		else
			execute('usp_statistic_pool ''' +  @GroupBy + ''', ''' + @DateTimeFrom + ''', ''' + @DateTimeTo + ''', ''' + @ID + ''', ' + @HourFrom + ',' + @HourTo);	  
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_statistic_new]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_statistic_new]  
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null,  
	@HourFrom int = 0,  
	@HourTo int = 24  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (id varchar(20), name varchar(50), agents int, times int, seconds int,   
		m0 int, m1 int, m2 int, m3 int, m4 int, m5 int, m6 int, m7 int, m8 int, m9 int, m10 int,   
		m11 int, m12 int, m13 int, m14 int, m15 int, m16 int, m17 int, m18 int, m19 int, m20 int,  
		m21 int, m22 int, m23 int, m24 int, m25 int, m26 int, m27 int, m28 int, m29 int, m30 int,   
		m31 int, m32 int, m33 int, m34 int, m35 int, m36 int, m37 int, m38 int, m39 int, m40 int,  
		m41 int, m42 int, m43 int, m44 int, m45 int, m46 int, m47 int, m48 int, m49 int, m50 int,  
		m51 int, m52 int, m53 int, m54 int, m55 int, m56 int, m57 int, m58 int, m59 int, m60 int,  
		m61 int, m62 int, m63 int, m64 int, m65 int, m66 int, m67 int, m68 int, m69 int, m70 int)   
	if @GroupBy = 'task' begin  
		insert into #TempTab 
		select t.taskid, t.taskname, count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r  
			inner join TaskRec tr on r.recordid = tr.recordid  
			inner join connection c on c.RecordId = r.RecordId 
			inner join Task t on tr.TaskID = t.TaskID   
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.agent is not null and c.agent !=0 
			and t.taskid = isnull(@ID, t.taskid)  
		group by t.taskid, t.taskname  
		order by t.taskid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin 
			insert into #TempTab  
			select '', 'Sum', count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r inner join (select distinct recordid from TaskRec where taskid in (select taskid from task)) t on r.recordid = t.recordid  
				inner join connection c on c.RecordId = r.RecordId 
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.agent is not null and c.agent !=0 
		end  
	end  
	if @GroupBy = 'group' begin  
		insert into #TempTab  
		select distinct g.groupid, g.groupname, count(distinct gr.agentid) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total, 
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r  
			inner join connection c on r.recordid = c.recordid  
			inner join AgentGroupRec gr on r.recordid = gr.recordid and c.agent = gr.agentid 
			inner join AgentGroup g on gr.GroupID = g.GroupID   
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.agent is not null and c.agent !=0 
			and g.groupid = isnull(@ID, g.groupid)  
		group by g.groupid, g.groupname  
		order by g.groupid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select distinct '', 'Sum', count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total, 
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r  
				inner join connection c on r.recordid = c.recordid  
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.agent is not null and c.agent !=0 
				and r.RecordId in (select recordid from AgentGroupRec) 
		end  
	end  
	if @GroupBy = 'agent' begin  
		insert into #TempTab  
		select a.agentid, a.agentname, 1 agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r inner join connection c on r.recordid = c.recordid left join Agent a on c.agent = a.agentid  
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.agent = isnull(@ID, c.agent)  
			and c.agent is not null and c.agent !=0 
		group by a.agentid, a.agentname  
		order by a.agentid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  


				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r inner join connection c on c.RecordId = r.RecordId  
				inner join agent a on c.agent = a.agentid  
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.agent is not null and c.agent !=0 
		end  
	end  
	if @GroupBy = 'date' begin  
		declare @dateID datetime  
		insert into #TempTab  
		select r.StartDate id, r.StartDate name, count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r inner join connection c on  r.recordId = c.RecordId 
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and r.StartDate = isnull(@ID, r.StartDate)  
			and c.leave-c.enter > 0  
			and c.agent is not null and c.agent !=0 
		group by r.StartDate  
		order by r.StartDate  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r left join connection c on c.RecordId = r.RecordId 
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.agent is not null and c.agent !=0 
		end  
	end  
	if @GroupBy = 'hour' begin  
		if @HourFrom is null set @HourFrom = 0  
		if @HourTo   is null set @HourTo   = 24  
		if @HourFrom < 0     set @HourFrom = 0  
		if @HourFrom > 24    set @HourFrom = 24  
		if @HourTo   < 0     set @HourTo   = 0  
		if @HourTo   > 24    set @HourTo   = 24  
		if @HourFrom = @HourTo select @ID = @HourFrom, @HourTo = @HourTo + 1  
		if @HourTo   = 25 select @HourFrom = 0, @HourTo = 1, @ID = 0  
		insert into #TempTab  
		select str(r.StartHour,2) id, str(r.StartHour, 2) + ':00 - ' + str(r.StartHour + 1, 2) + ':00' name,  
			count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
 		from records r inner join connection c on c.recordId = r.recordId 
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.agent is not null and c.agent !=0 
			and r.StartHour = isnull(@ID, r.StartHour)  
			and ((@HourFrom < @HourTo and (r.StartHour >= @HourFrom and r.StartHour < @HourTo)) or  
			(@HourFrom > @HourTo and (r.StartHour >= @HourFrom or  r.StartHour < @HourTo)))  
		group by r.StartHour  
		order by r.StartHour  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct c.agent) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
 			from records r inner join connection c on c.recordId = r.recordId 
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.agent is not null and c.agent !=0 
				and ((@HourFrom < @HourTo and (r.StartHour >= @HourFrom and r.StartHour < @HourTo)) or  
					 (@HourFrom > @HourTo and (r.StartHour >= @HourFrom or  r.StartHour < @HourTo)))  
		end  
	end  
	select * from #TempTab  
	drop table #TempTab  
	return @RowCount


GO
/****** Object:  StoredProcedure [dbo].[usp_statistic_new_ext]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_statistic_new_ext]  
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null,  
	@HourFrom int = 0,  
	@HourTo int = 24  
AS  
	declare @RowCount int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (id varchar(20), name varchar(50), agents int, times int, seconds int,   
		m0 int, m1 int, m2 int, m3 int, m4 int, m5 int, m6 int, m7 int, m8 int, m9 int, m10 int,   
		m11 int, m12 int, m13 int, m14 int, m15 int, m16 int, m17 int, m18 int, m19 int, m20 int,  
		m21 int, m22 int, m23 int, m24 int, m25 int, m26 int, m27 int, m28 int, m29 int, m30 int,   
		m31 int, m32 int, m33 int, m34 int, m35 int, m36 int, m37 int, m38 int, m39 int, m40 int,  
		m41 int, m42 int, m43 int, m44 int, m45 int, m46 int, m47 int, m48 int, m49 int, m50 int,  
		m51 int, m52 int, m53 int, m54 int, m55 int, m56 int, m57 int, m58 int, m59 int, m60 int,  
		m61 int, m62 int, m63 int, m64 int, m65 int, m66 int, m67 int, m68 int, m69 int, m70 int)  
		
	if @GroupBy = 'task' begin  
		insert into #TempTab 
		select t.taskid, t.taskname, count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r  
			inner join TaskRec tr on r.recordid = tr.recordid  
			inner join connection c on c.RecordId = r.RecordId 
			inner join Task t on tr.TaskID = t.TaskID   
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
			and t.taskid = isnull(@ID, t.taskid)  
		group by t.taskid, t.taskname  
		order by t.taskid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin 
			insert into #TempTab  
			select '', 'Sum', count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r inner join (select distinct recordid from TaskRec where taskid in (select taskid from task)) t on r.recordid = t.recordid  
				inner join connection c on c.RecordId = r.RecordId 
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
		end  
	end  

	if @GroupBy = 'ext' begin  
		insert into #TempTab  
		select c.device, c.device, 1 agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r inner join connection c on r.recordid = c.recordid 
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.device = isnull(@ID, c.device)  
			and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
		group by c.device
		order by c.device
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r inner join connection c on c.RecordId = r.RecordId  
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
		end  
	end  

	if @GroupBy = 'date' begin  
		declare @dateID datetime  
		insert into #TempTab  
		select r.StartDate id, r.StartDate name, count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
		from records r inner join connection c on  r.recordId = c.RecordId 
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and r.StartDate = isnull(@ID, r.StartDate)  
			and c.leave-c.enter > 0  
			and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
		group by r.StartDate  
		order by r.StartDate  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  

				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
			from records r left join connection c on c.RecordId = r.RecordId 
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
		end  
	end  

	if @GroupBy = 'hour' begin  
		if @HourFrom is null set @HourFrom = 0  
		if @HourTo   is null set @HourTo   = 24  
		if @HourFrom < 0     set @HourFrom = 0  
		if @HourFrom > 24    set @HourFrom = 24  
		if @HourTo   < 0     set @HourTo   = 0  
		if @HourTo   > 24    set @HourTo   = 24  
		if @HourFrom = @HourTo select @ID = @HourFrom, @HourTo = @HourTo + 1  
		if @HourTo   = 25 select @HourFrom = 0, @HourTo = 1, @ID = 0  
		insert into #TempTab  
		select str(r.StartHour,2) id, str(r.StartHour, 2) + ':00 - ' + str(r.StartHour + 1, 2) + ':00' name,  
			count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
			sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
			sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
			sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
			sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
			sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
			sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
			sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
			sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
			sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
			sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
			sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
			sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
			sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
			sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
			sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
			sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
			sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
			sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
			sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
			sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
			sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
			sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
			sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
			sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
			sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
			sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
			sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
			sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
			sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
			sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
			sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
			sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
			sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
			sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
			sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
			sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
			sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
			sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
			sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
			sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
			sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
			sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
			sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
			sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
			sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
			sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
			sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
			sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
			sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
			sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
			sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
			sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
			sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
			sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
			sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
			sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
			sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
			sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
			sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
			sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
			sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
			sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
			sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
			sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
			sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
			sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
			sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
			sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
			sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
			sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
			sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
 		from records r inner join connection c on c.recordId = r.recordId 
		where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
			and c.leave-c.enter > 0  
			and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
			and r.StartHour = isnull(@ID, r.StartHour)  
			and ((@HourFrom < @HourTo and (r.StartHour >= @HourFrom and r.StartHour < @HourTo)) or  
			(@HourFrom > @HourTo and (r.StartHour >= @HourFrom or  r.StartHour < @HourTo)))  
		group by r.StartHour  
		order by r.StartHour  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
			select '', 'Sum', count(distinct c.device) agents, count(distinct r.RecordId) times, sum(c.leave-c.enter) total,  
				sum(case r.seconds/30 when  0 then 1 else 0 end) M0,   
				sum(case r.seconds/30 when  1 then 1 else 0 end) M1,  
				sum(case r.seconds/30 when  2 then 1 else 0 end) M2,  
				sum(case r.seconds/30 when  3 then 1 else 0 end) M3,  
				sum(case r.seconds/30 when  4 then 1 else 0 end) M4,  
				sum(case r.seconds/30 when  5 then 1 else 0 end) M5,  
				sum(case r.seconds/30 when  6 then 1 else 0 end) M6,  
				sum(case r.seconds/30 when  7 then 1 else 0 end) M7,  
				sum(case r.seconds/30 when  8 then 1 else 0 end) M8,  
				sum(case r.seconds/30 when  9 then 1 else 0 end) M9,  
				sum(case r.seconds/30 when 10 then 1 else 0 end) M10,  
				sum(case r.seconds/30 when 11 then 1 else 0 end) M11,  
				sum(case r.seconds/30 when 12 then 1 else 0 end) M12,  
				sum(case r.seconds/30 when 13 then 1 else 0 end) M13,  
				sum(case r.seconds/30 when 14 then 1 else 0 end) M14,  
				sum(case r.seconds/30 when 15 then 1 else 0 end) M15,  
				sum(case r.seconds/30 when 16 then 1 else 0 end) M16,  
				sum(case r.seconds/30 when 17 then 1 else 0 end) M17,  
				sum(case r.seconds/30 when 18 then 1 else 0 end) M18,  
				sum(case r.seconds/30 when 19 then 1 else 0 end) M19,  
				sum(case r.seconds/30 when 20 then 1 else 0 end) M20,  
				sum(case r.seconds/30 when 21 then 1 else 0 end) M21,  
				sum(case r.seconds/30 when 22 then 1 else 0 end) M22,  
				sum(case r.seconds/30 when 23 then 1 else 0 end) M23,  
				sum(case r.seconds/30 when 24 then 1 else 0 end) M24,  
				sum(case r.seconds/30 when 25 then 1 else 0 end) M25,  
				sum(case r.seconds/30 when 26 then 1 else 0 end) M26,  
				sum(case r.seconds/30 when 27 then 1 else 0 end) M27,  
				sum(case r.seconds/30 when 28 then 1 else 0 end) M28,  
				sum(case r.seconds/30 when 29 then 1 else 0 end) M29,  
				sum(case r.seconds/30 when 30 then 1 else 0 end) M30,  
				sum(case r.seconds/30 when 31 then 1 else 0 end) M31,  
				sum(case r.seconds/30 when 32 then 1 else 0 end) M32,  
				sum(case r.seconds/30 when 33 then 1 else 0 end) M33,  
				sum(case r.seconds/30 when 34 then 1 else 0 end) M34,  
				sum(case r.seconds/30 when 35 then 1 else 0 end) M35,  
				sum(case r.seconds/30 when 36 then 1 else 0 end) M36,  
				sum(case r.seconds/30 when 37 then 1 else 0 end) M37,  
				sum(case r.seconds/30 when 38 then 1 else 0 end) M38,  
				sum(case r.seconds/30 when 39 then 1 else 0 end) M39,  
				sum(case r.seconds/30 when 40 then 1 else 0 end) M40,  
				sum(case r.seconds/30 when 41 then 1 else 0 end) M41,  
				sum(case r.seconds/30 when 42 then 1 else 0 end) M42,  
				sum(case r.seconds/30 when 43 then 1 else 0 end) M43,  
				sum(case r.seconds/30 when 44 then 1 else 0 end) M44,  
				sum(case r.seconds/30 when 45 then 1 else 0 end) M45,  
				sum(case r.seconds/30 when 46 then 1 else 0 end) M46,  
				sum(case r.seconds/30 when 47 then 1 else 0 end) M47,  
				sum(case r.seconds/30 when 48 then 1 else 0 end) M48,  
				sum(case r.seconds/30 when 49 then 1 else 0 end) M49,  
				sum(case r.seconds/30 when 50 then 1 else 0 end) M50,  
				sum(case r.seconds/30 when 51 then 1 else 0 end) M51,  
				sum(case r.seconds/30 when 52 then 1 else 0 end) M52,  
				sum(case r.seconds/30 when 53 then 1 else 0 end) M53,  
				sum(case r.seconds/30 when 54 then 1 else 0 end) M54,  
				sum(case r.seconds/30 when 55 then 1 else 0 end) M55,  
				sum(case r.seconds/30 when 56 then 1 else 0 end) M56,  
				sum(case r.seconds/30 when 57 then 1 else 0 end) M57,  
				sum(case r.seconds/30 when 58 then 1 else 0 end) M58,  
				sum(case r.seconds/30 when 59 then 1 else 0 end) M59,  
				sum(case r.seconds/30 when 60 then 1 else 0 end) M60,  
				sum(case r.seconds/30 when 61 then 1 else 0 end) M61,  
				sum(case r.seconds/30 when 62 then 1 else 0 end) M62,  
				sum(case r.seconds/30 when 63 then 1 else 0 end) M63,  
				sum(case r.seconds/30 when 64 then 1 else 0 end) M64,  
				sum(case r.seconds/30 when 65 then 1 else 0 end) M65,  
				sum(case r.seconds/30 when 66 then 1 else 0 end) M66,  
				sum(case r.seconds/30 when 67 then 1 else 0 end) M67,  
				sum(case r.seconds/30 when 68 then 1 else 0 end) M68,  
				sum(case r.seconds/30 when 69 then 1 else 0 end) M69,  
				sum(case r.seconds/2100 when 0 then 0 else 1 end) M70  
 			from records r inner join connection c on c.recordId = r.recordId 
			where (r.StartTime between @DateTimeFrom and @DateTimeTo)  
				and c.leave-c.enter > 0  
				and c.device is not null and c.device not like 'T%' and c.device in (select convert(varchar, address) from address)
				and ((@HourFrom < @HourTo and (r.StartHour >= @HourFrom and r.StartHour < @HourTo)) or  
					 (@HourFrom > @HourTo and (r.StartHour >= @HourFrom or  r.StartHour < @HourTo)))  
		end  
	end  
	select * from #TempTab  
	drop table #TempTab  
	return @RowCount


GO
/****** Object:  StoredProcedure [dbo].[usp_statistic_pool]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_statistic_pool]  
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null,  
	@HourFrom int = 0,  
	@HourTo int = 24  
AS  
	declare @RowCount int  
	declare @Agents int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (id varchar(20), name varchar(50), agents int, times int, seconds int,   
		m0 int, m1 int, m2 int, m3 int, m4 int, m5 int, m6 int, m7 int, m8 int, m9 int, m10 int,   
		m11 int, m12 int, m13 int, m14 int, m15 int, m16 int, m17 int, m18 int, m19 int, m20 int,  
		m21 int, m22 int, m23 int, m24 int, m25 int, m26 int, m27 int, m28 int, m29 int, m30 int,   
		m31 int, m32 int, m33 int, m34 int, m35 int, m36 int, m37 int, m38 int, m39 int, m40 int,  
		m41 int, m42 int, m43 int, m44 int, m45 int, m46 int, m47 int, m48 int, m49 int, m50 int,  
		m51 int, m52 int, m53 int, m54 int, m55 int, m56 int, m57 int, m58 int, m59 int, m60 int,  
		m61 int, m62 int, m63 int, m64 int, m65 int, m66 int, m67 int, m68 int, m69 int, m70 int)   

	if @GroupBy = 'task' begin  
	insert into #TempTab  
		select t.taskid, t.taskname,  sum(distinct a.agents) agents, sum(times) times, sum(r.seconds) total,  
		sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
		sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
		sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
		sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
		sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
		sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
		sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
	from StatTask r inner join Task t on t.TaskID = r.subid inner join (select subid, count(distinct agent) as agents from StatTaskAgents where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
	where (r.statdate between @DateTimeFrom and @DateTimeTo)  
		and r.seconds > 0  
		and t.taskid = isnull(@ID, t.taskid)  
	group by t.taskid, t.taskname  
	order by t.taskid  
	set @RowCount = @@RowCount  
	if @RowCount > 0 and @ID is null begin  
		select @Agents=count(distinct agent) from StatTaskAgents where statdate between @DateTimeFrom and @DateTimeTo  
		insert into #TempTab  
		select '', 'Sum', @Agents agents, sum(r.times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatTask r  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'group' begin  
		insert into #TempTab  
		select g.groupid, g.groupname,  sum(distinct a.agents) agents, sum(times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatGroup r inner join AgentGroup g on g.GroupID = r.subid inner join (select subid, count(distinct agent) as agents from StatGroupAgents where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and g.groupid = isnull(@ID, g.groupid)  
		group by g.groupid, g.groupname  
		order by g.groupid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			select @Agents=count(distinct agent) from StatGroupAgents where statdate between @DateTimeFrom and @DateTimeTo  
			insert into #TempTab  
			select '', 'Sum', @Agents agents, sum(r.times) times, sum(r.seconds) total,  
				sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
				sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
				sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
				sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
				sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
				sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
				sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatGroup r  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'agent' begin  
   		insert into #TempTab  
		select a.agentid, a.agentname, 1 agents, sum(r.times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatAgent r inner join Agent a on r.subid = a.agentid  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and a.agentid = isnull(@ID, a.agentid)  
		group by a.agentid, a.agentname  
		order by a.agentid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
				select '', 'Sum', @RowCount agents, sum(times) times, sum(r.seconds) total,  
					sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
					sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
					sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
					sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
					sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
					sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
					sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatAgent r inner join agent a on r.subid = a.agentid  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'date' begin  
		declare @dateID datetime  
		insert into #TempTab  
		select r.StatDate id, r.StatDate name, sum(distinct a.agents) agents, sum(r.times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatDaily r  inner join (select statdate, count(distinct agent) as agents from StatDailyAgents where statdate between @DateTimeFrom and @DateTimeTo group by statdate) a on r.statdate=a.statdate  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and r.StatDate = isnull(@ID, r.StatDate)  
		group by r.StatDate  
		order by r.StatDate  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			select @Agents=count(distinct agent) from StatDailyAgents where statdate between @DateTimeFrom and @DateTimeTo  
			insert into #TempTab  
			select '', 'Sum', @Agents agents, sum(r.times) times, sum(r.seconds) total,  
				sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
				sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
				sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
				sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
				sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
				sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
				sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatDaily r  
			where (r.StatDate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'hour' begin 
		if @HourFrom is null set @HourFrom = 0  
		if @HourTo   is null set @HourTo   = 24  
		if @HourFrom < 0     set @HourFrom = 0  
		if @HourFrom > 24    set @HourFrom = 24  
		if @HourTo   < 0     set @HourTo   = 0  
		if @HourTo   > 24    set @HourTo   = 24  
		if @HourFrom = @HourTo select @ID = @HourFrom, @HourTo = @HourTo + 1  
		if @HourTo   = 25 select @HourFrom = 0, @HourTo = 1, @ID = 0  
		insert into #TempTab  
		select str(r.subid,2) id, str(r.subid, 2) + ':00 - ' + str(r.subid + 1, 2) + ':00' name,  
			sum(distinct a.agents) agents, sum(times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatHour r  inner join (select subid, count(distinct agent) as agents from StatHourAgents where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
		where (r.StatDate between @DateTimeFrom and @DateTimeTo)  
		          and r.seconds > 0  
		          and r.subid = isnull(@ID, r.subid)  
		          and ((@HourFrom < @HourTo and (r.subid >= @HourFrom and r.subid < @HourTo)) or  
		               (@HourFrom > @HourTo and (r.subid >= @HourFrom or  r.subid < @HourTo)))  
		group by r.subid  
		order by r.subid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			select @Agents=count(distinct agent) from StatHourAgents where statdate between @DateTimeFrom and @DateTimeTo and ((@HourFrom < @HourTo and (subid >= @HourFrom and subid < @HourTo)) or  
			         (@HourFrom > @HourTo and (subid >= @HourFrom or  subid < @HourTo)))  
			insert into #TempTab  
			select '', 'Sum', @Agents agents, sum(times) times, sum(r.seconds) total,  
				sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
				sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
				sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
				sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
				sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
				sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
				sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatHour r  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
				and ((@HourFrom < @HourTo and (r.subid >= @HourFrom and r.subid < @HourTo)) or  
				 (@HourFrom > @HourTo and (r.subid >= @HourFrom or  r.subid < @HourTo)))  
		end  
	end  
	select * from #TempTab  
	drop table #TempTab  
	return @RowCount


GO
/****** Object:  StoredProcedure [dbo].[usp_statistic_pool_ext]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_statistic_pool_ext]
	@GroupBy varchar(20) = 'agent',  
	@DateTimeFrom varchar(20)  = '20000101 0:00',  
	@DateTimeTo varchar(20)  = '21000101 0:00',  
	@ID varchar(20) = null,  
	@HourFrom int = 0,  
	@HourTo int = 24  
AS  
	declare @RowCount int  
	declare @Agents int  
	set @RowCount = 0  
	if @ID is not null and ltrim(@ID) = '' set @ID = null  
	create table #TempTab (id varchar(20), name varchar(50), agents int, times int, seconds int,   
		m0 int, m1 int, m2 int, m3 int, m4 int, m5 int, m6 int, m7 int, m8 int, m9 int, m10 int,   
		m11 int, m12 int, m13 int, m14 int, m15 int, m16 int, m17 int, m18 int, m19 int, m20 int,  
		m21 int, m22 int, m23 int, m24 int, m25 int, m26 int, m27 int, m28 int, m29 int, m30 int,   
		m31 int, m32 int, m33 int, m34 int, m35 int, m36 int, m37 int, m38 int, m39 int, m40 int,  
		m41 int, m42 int, m43 int, m44 int, m45 int, m46 int, m47 int, m48 int, m49 int, m50 int,  
		m51 int, m52 int, m53 int, m54 int, m55 int, m56 int, m57 int, m58 int, m59 int, m60 int,  
		m61 int, m62 int, m63 int, m64 int, m65 int, m66 int, m67 int, m68 int, m69 int, m70 int)   
	if @GroupBy = 'task' begin  
	insert into #TempTab  
		select t.taskid, t.taskname,  sum(distinct a.agents) agents, sum(times) times, sum(r.seconds) total,  
		sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
		sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
		sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
		sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
		sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
		sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
		sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
	from StatTask r inner join Task t on t.TaskID = r.subid inner join (select subid, count(distinct agent) as agents from StatTaskAgents where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
	where (r.statdate between @DateTimeFrom and @DateTimeTo)  
		and r.seconds > 0  
		and t.taskid = isnull(@ID, t.taskid)  
	group by t.taskid, t.taskname  
	order by t.taskid  
	set @RowCount = @@RowCount  
	if @RowCount > 0 and @ID is null begin  
		select @Agents=count(distinct agent) from StatTaskAgents where statdate between @DateTimeFrom and @DateTimeTo  
		insert into #TempTab  
		select '', 'Sum', @Agents agents, sum(r.times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatTask r  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'ext' begin  
   		insert into #TempTab  
		select r.subid as agentid, r.subid as name, 1 agents, sum(r.times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatExt r
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and r.subid = isnull(@ID, r.subid)  
		group by r.subid
		order by r.subid
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			insert into #TempTab  
				select '', 'Sum', @RowCount agents, sum(times) times, sum(r.seconds) total,  
					sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
					sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
					sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
					sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
					sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
					sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
					sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatExt r
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'date' begin  
		declare @dateID datetime  
		insert into #TempTab  
		select r.StatDate id, r.StatDate name, sum(distinct a.agents) agents, sum(r.times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatDaily r  inner join (select statdate, count(distinct agent) as agents from StatDailyAgents where statdate between @DateTimeFrom and @DateTimeTo group by statdate) a on r.statdate=a.statdate  
		where (r.statdate between @DateTimeFrom and @DateTimeTo)  
			and r.seconds > 0  
			and r.StatDate = isnull(@ID, r.StatDate)  
		group by r.StatDate  
		order by r.StatDate  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			select @Agents=count(distinct agent) from StatDailyAgents where statdate between @DateTimeFrom and @DateTimeTo  
			insert into #TempTab  
			select '', 'Sum', @Agents agents, sum(r.times) times, sum(r.seconds) total,  
				sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
				sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
				sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
				sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
				sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
				sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
				sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatDaily r  
			where (r.StatDate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
		end  
	end  

	if @GroupBy = 'hour' begin 
		if @HourFrom is null set @HourFrom = 0  
		if @HourTo   is null set @HourTo   = 24  
		if @HourFrom < 0     set @HourFrom = 0  
		if @HourFrom > 24    set @HourFrom = 24  
		if @HourTo   < 0     set @HourTo   = 0  
		if @HourTo   > 24    set @HourTo   = 24  
		if @HourFrom = @HourTo select @ID = @HourFrom, @HourTo = @HourTo + 1  
		if @HourTo   = 25 select @HourFrom = 0, @HourTo = 1, @ID = 0  
		insert into #TempTab  
		select str(r.subid,2) id, str(r.subid, 2) + ':00 - ' + str(r.subid + 1, 2) + ':00' name,  
			sum(distinct a.agents) agents, sum(times) times, sum(r.seconds) total,  
			sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
			sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
			sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
			sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
			sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
			sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
			sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
		from StatHour r  inner join (select subid, count(distinct agent) as agents from StatHourAgents where statdate between @DateTimeFrom and @DateTimeTo group by subid) a on r.subid=a.subid  
		where (r.StatDate between @DateTimeFrom and @DateTimeTo)  
		          and r.seconds > 0  
		          and r.subid = isnull(@ID, r.subid)  
		          and ((@HourFrom < @HourTo and (r.subid >= @HourFrom and r.subid < @HourTo)) or  
		               (@HourFrom > @HourTo and (r.subid >= @HourFrom or  r.subid < @HourTo)))  
		group by r.subid  
		order by r.subid  
		set @RowCount = @@RowCount  
		if @RowCount > 0 and @ID is null begin  
			select @Agents=count(distinct agent) from StatHourAgents where statdate between @DateTimeFrom and @DateTimeTo and ((@HourFrom < @HourTo and (subid >= @HourFrom and subid < @HourTo)) or  
			         (@HourFrom > @HourTo and (subid >= @HourFrom or  subid < @HourTo)))  
			insert into #TempTab  
			select '', 'Sum', @Agents agents, sum(times) times, sum(r.seconds) total,  
				sum(M0) M0, sum(M1) M1, sum(M2) M2,  sum(M3) M3,  sum(M4) M4,  sum(M5) M5,  sum(M6) M6,  sum(M7) M7,  sum(M8) M8,  sum(M9) M9,  sum(M10) M10,   
				sum(M11) M11,  sum(M12) M12, sum(M13) M13,  sum(M14) M14,  sum(M15) M15,  sum(M16) M16,  sum(M17) M17, sum(M18) M18,  sum(M19) M19, sum(M20) M20,   
				sum(M21) M21,  sum(M22) M22, sum(M23) M23,  sum(M24) M24,  sum(M25) M25,  sum(M26) M26,  sum(M27) M27, sum(M28) M28,  sum(M29) M29, sum(M30) M30,   
				sum(M31) M31,  sum(M32) M32, sum(M33) M33,  sum(M34) M34,  sum(M35) M35,  sum(M36) M36,  sum(M37) M37, sum(M33) M38,  sum(M39) M39, sum(M40) M40,   
				sum(M41) M41,  sum(M42) M42, sum(M43) M43,  sum(M44) M44,  sum(M45) M45,  sum(M46) M46,  sum(M47) M47, sum(M48) M48,  sum(M49) M49, sum(M50) M50,   
				sum(M51) M51,  sum(M52) M52, sum(M53) M53,  sum(M54) M54,  sum(M55) M55,  sum(M56) M56,  sum(M57) M57, sum(M58) M58,  sum(M59) M59, sum(M60) M60,   
				sum(M61) M61,  sum(M62) M62, sum(M63) M63,  sum(M64) M64,  sum(M65) M65,  sum(M66) M66,  sum(M67) M67, sum(M68) M68,  sum(M69) M69, sum(M70) M70  
			from StatHour r  
			where (r.statdate between @DateTimeFrom and @DateTimeTo)  
				and r.seconds > 0  
				and ((@HourFrom < @HourTo and (r.subid >= @HourFrom and r.subid < @HourTo)) or  
				 (@HourFrom > @HourTo and (r.subid >= @HourFrom or  r.subid < @HourTo)))  
		end  
	end  
	select * from #TempTab  
	drop table #TempTab  
	return @RowCount


GO
/****** Object:  StoredProcedure [dbo].[usp_storage_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_storage_delete]  
	@FtpId char(32)  
AS  
	if exists (select top 1 * from records where audiourl=@FtpId or videourl=@FtpId) begin 
		update storage set enabled = 0 
		where FtpId = @FtpId 
		select 0 'result' 
	end 
	else begin 
		delete storage 
		where FtpId = @FtpId 
		select 1 'result' 
	end 
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_storage_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_storage_insert] 
	@FtpId			tinyint = 0, 
	@Station		char(32) = null, 
	@Folder			varchar(50) = null, 
	@Port			int = 0,
	@Drive			char(1) = null, 
	@Priority		tinyint = null, 
	@UserName		varchar(20) = null, 
	@Password		varchar(50) = null, 
	@Enabled		bit = 1,
    @StorageType	tinyint = null,
	@realFolder		varchar(100) = null
AS 
	if exists (select * from storage where ftpId=@FtpId or (station=@station and folder=@Folder)) 
		select 0 'result' 
	else begin 
		insert into Storage(FtpId, 
							Station, 
							Folder, 
							Port,
							Drive, 
							Priority, 
							Username, 
							Password, 
							Enabled, 
							StorageType, 
							RealFolder) 
			values (@FtpId, 
					@Station,
					@Folder, 
					@Port,
					@Drive, 
					@Priority, 
					@Username, 
					@Password, 
					@Enabled, 
					@StorageType,
					@realFolder) 
		select 1 'result' 
	end





GO
/****** Object:  StoredProcedure [dbo].[usp_storage_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_storage_update]  
	@FtpId tinyint = 0, 
	@Station char(32) = null, 
	@Folder varchar(50) = null, 
	@Port	int = null,
	@Drive char(1) = null, 
	@Priority tinyint = null, 
	@UserName varchar(20) = null, 
	@Password varchar(50) = null, 
	@Enabled bit = 1,
	@StorageType tinyint = null,
	@realFolder varchar(100) = null
AS  
	if @FtpId is null return  
	update storage set 
		Station = isnull(@Station, Station), 
		Folder = isnull(@Folder, Folder), 
		Port = isnull(@Port, Port),
		Drive = isnull(@Drive, Drive), 
		Priority =  isnull(@Priority, Priority), 
		UserName = isnull(@UserName, UserName), 
		Password = isnull(@Password, Password), 
		Enabled = isnull(@Enabled, Enabled) ,
		StorageType = isnull(@StorageType, StorageType),
		RealFolder = isnull(@RealFolder, RealFolder)
	where FtpId = @FtpId
GO
/****** Object:  StoredProcedure [dbo].[usp_supervisor_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_supervisor_delete]  
	@LogID int = 0  
AS  
	delete Supervisor from Supervisor where LogID = @LogID  
	return

GO
/****** Object:  StoredProcedure [dbo].[usp_supervisor_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_supervisor_insert]  
	@LogUser varchar(20),  
	@LogPass varchar(50),  
	@Privilege int = 0,  
	@Type varchar(1),  
	@Agents varchar(2000),  
	@Groups varchar(2000),  
	@Tasks  varchar(2000),  
	@Members  varchar(800) ,
	@validays int = 30
AS  
	declare @LogID int , @today int
	set @LogID = (select max(LogID) from Supervisor) + 1  
	if @LogID = null  
		set @LogID = 1  

	set @today = DATEPART(yy, getdate()) * 10000 + DATEPART(mm, getdate()) * 100 + DATEPART(dd, getdate())
	set @validays = isnull(@validays,30)
	if @validays < 30
		set @validays = 30
	else if @validays > 90
		set @validays = 90

	if isnull(@LogPass, '') = ''
		set @LogPass = 'E08C9E12032C21383141'

	if (select count(*) from Supervisor where LogUser = @LogUser) = 0 begin  
		insert into Supervisor (LogID, LogUser, LogPass, Privilege, Type, Agents, Groups ,Tasks, Members, LastDate, Validays, ErrTimes, Locked)  
		values (@LogID, @LogUser, @LogPass, @Privilege, @Type, @Agents, @Groups, @Tasks, @Members, str(@today), @validays, 0, 0)  
		select 1 'result' 
	end  
	else begin  
		select 0 'result' 
	end  
	return

GO
/****** Object:  StoredProcedure [dbo].[usp_supervisor_reset]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_supervisor_reset]
	@LogID int
AS  
	update supervisor set ErrTimes = 0,  Locked = 0, logpass = 'E08C9E12032C21383141' where LogID = @LogID

GO
/****** Object:  StoredProcedure [dbo].[usp_supervisor_unlock]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[usp_supervisor_unlock]  
	@LogID int
AS  
	update supervisor set ErrTimes = 0,  Locked = 0 where LogID = @LogID

GO
/****** Object:  StoredProcedure [dbo].[usp_supervisor_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_supervisor_update]
	@LogID int = 0,  
	@LogUser varchar(20) = null,  
	@LogPass varchar(50) = null,  
	@Privilege int = null, 
	@Type varchar(1) = null,  
	@Agents varchar(2000) = null,  
	@Groups varchar(2000) = null,  
	@Tasks varchar(2000) = null,  
	@Members varchar(800) = null,
	@validays int = null
AS  
	declare @date int, @today int
	if @LogPass is null begin
		set @today = null
	end 
	else begin
		set @today = DATEPART(yy, getdate()) * 10000 + DATEPART(mm, getdate()) * 100 + DATEPART(dd, getdate())
	end

	if (select count(*) from Supervisor where LogUser = @LogUser and LogID != @LogID ) = 0 begin  
	update Supervisor set  
		LogID = isnull(@LogID, LogID),  
		LogUser = isnull(@LogUser, LogUser),  
		LogPass = isnull(@LogPass, LogPass),  
		Privilege = isnull(@Privilege, Privilege),  
		Type =  isnull(@Type, Type),  
		Agents =  isnull(@Agents, Agents),  
		Groups =  isnull(@Groups, Groups),  
		Tasks =  isnull(@Tasks, Tasks),  
		Members = isnull(@Members, Members) ,
		LastDate = case when @today is null then LastDate else str(@today) end,
		validays = isnull(@validays, validays)
		where LogID = @LogID
		select 1 'result' 
	end  
	else begin  
		select 0 'result' 
	end  
  return

GO
/****** Object:  StoredProcedure [dbo].[usp_system_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_system_update] 
	@LineMode int = 0
AS
	if exists (select * from [system] where [key] = 'LineMode')
		update [system] set value =@LineMode  where [key] = 'LineMode'
	else
		insert [system] ([key], value, type) values ('LineMode', @LineMode, 'int')

GO
/****** Object:  StoredProcedure [dbo].[usp_task_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_task_delete]  
	@TaskID int = 0,  
	@taskName varchar(20) = null  
AS  
	if @TaskID = 0  
		set @TaskID = (select  taskID from task where TaskName = @TaskName)  

	insert into History_Task ([TaskID]
           ,[TaskName]
           ,[Description]
           ,[ObjType]
           ,[TimeRangeType]
           ,[Quality]
           ,[State]
           ,[WeekState]
           ,[MonthState]
           ,[date_start]
           ,[date_end]
           ,[time_start]
           ,[time_end]
           ,[RecFlag]
           ,[Priority]
           ,[Enabled]
           ,[Items]
           ,[RecPercent]
           ,[ScrPercent]) 
	select [TaskID]
           ,[TaskName]
           ,[Description]
           ,[ObjType]
           ,[TimeRangeType]
           ,[Quality]
           ,[State]
           ,[WeekState]
           ,[MonthState]
           ,[date_start]
           ,[date_end]
           ,[time_start]
           ,[time_end]
           ,[RecFlag]
           ,[Priority]
           ,[Enabled]
           ,[Items]
           ,[RecPercent]
           ,[ScrPercent]
	from task where TaskID = @TaskID  

	insert into History_TaskItem select * from taskitem where TaskID = @TaskID
	delete TaskItem where TaskID = @TaskID  
	delete Task where TaskID = @TaskID  
	delete StatTask where subid=@TaskID
	delete StatTaskAgents where subid=@TaskID
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_task_getstate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_task_getstate]  
	@TaskID int = 0  
AS  
	select enabled from task where taskid=@TaskID


GO
/****** Object:  StoredProcedure [dbo].[usp_task_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_task_insert]  
	@TaskID			int = 0,  
	@TaskName		varchar(50),  
	@Description	varchar(1000) = null,  
	@ObjType		tinyint = 0,  
	@TimeRangeType	tinyint = 0,  
	@Quality		int = 0,  
	@WeekState		int = 0,  
	@MonthState		int = 0,  
	@date_start		varchar(8) = '',  
	@date_end		varchar(8) = '',  
	@time_start		varchar(8) = '',  
	@time_end		varchar(8) = '',  
	@recflag		tinyint = 0, 
	@priority		smallint = 0, 
    @recPercent		tinyint = 0,
	@RecFtpID		smallint,
	@ScrFtpID		smallint,
	@Enabled		bit = 0,
	@scrPercent		tinyint = 0,
	@VideoPercent	tinyint = 0,
	@VideoZoomScale	smallint = 0,
	@VideoFtpID		smallint = 0,
	@DataEncry		bit = 0,
	@AutoBackup		bit = 0,
	@DestFolder		varchar(256) = '',
	@BackupDays		smallint = 0,
	@Backuptime		smallint = 0,
	@RecKeepDays	smallint = 0,
	@ScrKeepDays	smallint = 0,
	@VideoKeepDays	smallint = 0

AS  

	set @DataEncry = isnull(@DataEncry, 0)
	set @AutoBackup = isnull(@AutoBackup, 0)
	
	--if @TaskID = 0  
		--set @TaskID = (select max(TaskID) from Task) + 1  
		--set @TaskID = isnull(@TaskID, 1)  
		if (select count(*) from Task where TaskName = @TaskName) = 0 begin  
			insert into Task(TaskName,
								Description, 
								ObjType, 
								TimeRangeType,  
								Quality, 
								WeekState, 
								MonthState,  
								date_start, 
								date_end, 
								time_start, 
								time_end, 
								recflag,  
								priority,
								recpercent,
								scrPercent,
								enabled, 
								RecFtpID,
								ScrFtpID,
								VideoPercent,
								VideoZoomScale,
								VideoFtpID,
								DataEncry,
								AutoBackup,
								DestFolder,
								BackupDays,
								BackupTime,
								RecKeepDays,
								ScrKeepDays,
								VideoKeepDays)  
				values (@TaskName, 
						@Description, 
						@ObjType, 
						@TimeRangeType, 
						@Quality, 
						@WeekState, 
						@MonthState, 
						@date_start, 
						@date_end, 
						@time_start, 
						@time_end, 
						@recflag, 
						@priority,
						@recPercent,
						@scrPercent,
						@enabled, 
						@RecFtpID, 
						@ScrFtpID,
						@VideoPercent,
						@VideoZoomScale,
						@VideoFtpID,
						@DataEncry,
						@AutoBackup,
						@DestFolder,
						@BackupDays,
						@Backuptime,
						@RecKeepDays,
						@ScrKeepDays,
						@VideoKeepDays)  
				
			select max(taskid) as 'TaskID'  from task
		end
	--end  
	else begin  
		select 0 as 'TaskID'  
	end



GO
/****** Object:  StoredProcedure [dbo].[usp_task_setstate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_task_setstate]  
	@TaskID int = 0,  
	@enabled bit = 0  
AS  
	update Task   
		set enabled = @enabled  
		where TaskID = @TaskID  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_task_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_task_update]  
	@TaskID int = 0,  
	@TaskName varchar(50) = null,  
	@Description varchar(1000) = null,  
	@ObjType tinyint = null,  
	@TimeRangeType tinyint = null,  
	@Quality tinyint = null,  
	@WeekState int = 0,  
	@MonthState int = 0,  
	@date_start varchar(8) = null,  
	@date_end  varchar(8) =null,  
	@time_start varchar(8) = null,  
	@time_end varchar(8) = null,  
	@recflag tinyint =  null, 
	@priority smallint =  null,
    @recPercent tinyint = null, 	
	@RecFtpID smallint,
	@ScrFtpID smallint,
	@scrPercent tinyint,
	@Enabled bit = null,
	@VideoPercent	tinyint = 0,
	@VideoZoomScale	smallint = 0,
	@VideoFtpID		smallint = 0,
	@DataEncry		bit = 0,
	@AutoBackup		bit = 0,
	@DestFolder		varchar(256) = '',
	@BackupDays		smallint = 0,
	@Backuptime		smallint = 0,
	@RecKeepDays	smallint = 0,
	@ScrKeepDays	smallint = 0,
	@VideoKeepDays	smallint = 0

AS  
	update Task   
	set 	TaskName = isnull(@TaskName, TaskName),   
		Description  = isnull(@Description,Description),  
		ObjType  = @ObjType,   
		TimeRangeType = @TimeRangeType,   
		Quality   = @Quality,   
		WeekState = @WeekState,  
		MonthState = @MonthState,  
		date_start = isnull(@date_start, date_start),  
		date_end   =isnull(@date_end, date_end),  
		time_start  =isnull(@time_start, time_start),  
		time_end   =isnull(@time_end, time_end),  
		recflag = isnull(@recflag, recflag), 		 
		priority = isnull(@priority, priority), 
		recpercent = isnull(@recPercent, recpercent),	
		scrPercent = isnull(@scrPercent, scrPercent),	 
		Enabled    = isnull(@Enabled, Enabled),
		RecFtpID = isnull(@RecFtpID, RecFtpID),
		ScrFtpID = isnull(@ScrFtpID, ScrFtpID),
		VideoPercent = isnull(@VideoPercent, VideoPercent),
		VideoZoomScale = isnull(@VideoZoomScale, VideoZoomScale),
		VideoFtpID = isnull(@VideoFtpID, VideoFtpID),
		DataEncry = isnull(@DataEncry, DataEncry),
		AutoBackup = isnull(@AutoBackup, AutoBackup),
		DestFolder = isnull(@DestFolder, DestFolder),
		BackupDays = isnull(@BackupDays, BackupDays),
		Backuptime = isnull(@Backuptime, Backuptime),
		RecKeepDays = isnull(@RecKeepDays, RecKeepDays),
		ScrKeepDays = isnull(@ScrKeepDays, ScrKeepDays),
		VideoKeepDays = isnull(@VideoKeepDays, VideoKeepDays)
	where TaskID = @TaskID  
	return




GO
/****** Object:  StoredProcedure [dbo].[usp_taskitem_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[usp_taskitem_delete]  
	@TaskID int = 0  
AS  
	  delete TaskItem from TaskItem where TaskID = @TaskID  
	  return


GO
/****** Object:  StoredProcedure [dbo].[usp_taskitem_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_taskitem_insert]  
	@TaskID int = 0,  
	@AgentID varchar(20),  
	@AgentGroupID int,  
	@Address varchar(20),  
	@AddressGroupID int , 
	@Vdn varchar(50) = null, 
	@Trunk varchar(50) = null,
	@TrunkGroupID int = null,
	@Acd varchar(20) = null
AS  
	insert into TaskItem (TaskID, AgentID, AgentGroupID, Address, AddressGroupID, vdn, trunk, TrunkGroupID, Acd)  
		values (@TaskID, @AgentID, @AgentGroupID, @Address, @AddressGroupID, @Vdn, @Trunk, @TrunkGroupID, @Acd)  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_trunk_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_trunk_delete]
	@TrunkId int
 AS
	delete trunk where trunkid=@TrunkID


GO
/****** Object:  StoredProcedure [dbo].[usp_trunk_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_trunk_insert]  
	@TrunkNum int,  
	@TrunkGroup int
AS  
	declare @TrunkId int
	set @TrunkId = @TrunkGroup * 1000 + @TrunkNum
	-- See also: usp_billiing insert 

	if (select count(*) from trunk where trunkid = @TrunkId) = 0 begin  
		insert into trunk (trunkid, trunknum, trunkgroup) values (@TrunkId, @TrunkNum, @TrunkGroup) 
		select 1 'result' 
	end  
	else begin
		update trunk set trunkgroup = @TrunkGroup where TrunkId = @TrunkId
		select 1 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_trunk_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_trunk_update]
	@TrunkID int,  
	@TrunkGroup int
AS  
	update trunk set TrunkGroup = @TrunkGroup where trunkid=@TrunkID
	select 1 'result'


GO
/****** Object:  StoredProcedure [dbo].[usp_trunkgroup_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_trunkgroup_delete]  
	@GroupID int = 0  
AS  
	  delete TrunkGroup where GroupID = @GroupID  
	  delete Trunk where TrunkGroup = @GroupID  
	  return


GO
/****** Object:  StoredProcedure [dbo].[usp_trunkgroup_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_trunkgroup_insert]  
	@GroupID int = 0,  
	@GroupName varchar(50),  
	@Description varchar(500),  
	@AutoBill bit = 0,
	@VoiceType tinyint = 0,
	@Station varchar(20) = '',
	@FtpId smallint = 0,
	@Enabled bit = 1  
AS  
	declare @newID int , @TypeName varchar(10)

	if @GroupID = 0  
		set @GroupID = (select max(GroupID) from trunkGroup) + 1 	 

	if @GroupID is null   
		set @GroupID=1  

	select @TypeName = typename 
	from voicetype
	where typeid = @VoiceType

	if (select count(*) from trunkGroup where GroupID = @GroupID) = 0 begin  
		insert into trunkGroup (GroupID, GroupName, Description, Station, AutoBill, VoiceType, FtpId)  
		values (@GroupID, @GroupName, @Description, @Station, @AutoBill, @VoiceType, @FtpId)  
		select 1 as 'result', @TypeName as typename
	end  
	else begin  
		select 0 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_trunkgroup_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_trunkgroup_update]  
	@GroupID int = 0,  
	@GroupName varchar(50) = null,  
	@Description varchar(500) = null,
	@AutoBill bit = null,
	@VoiceType tinyint = null,
	@Station varchar(20) = null,
	@FtpId smallint = null,
	@Enabled bit = null
AS  
	declare  @TypeName varchar(10)

	select @TypeName = typename 
	from voicetype
	where typeid = @VoiceType

	update trunkGroup  
	set 
		GroupName = isnull(@GroupName, GroupName),   
		AutoBill = isnull(@AutoBill, AutoBill),
		Station = isnull(@Station, Station),
		VoiceType =  isnull(@VoiceType, VoiceType),
		Description  = isnull(@Description,Description),
		FtpId = isnull(@FtpId, FtpId),
		Enabled = isnull(@Enabled, Enabled)
	where 
		GroupID = @GroupID  

	select @TypeName as TypeName
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_update_rt_trs]    Script Date: 2016/12/13 10:09:14 ******/
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
/****** Object:  StoredProcedure [dbo].[usp_vdn_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_vdn_delete]  
	@vdn varchar(20)  
AS  
	if @vdn is null return  
		set @vdn = ltrim(rtrim(@vdn))  
	delete vdn  
	from vdn  
	where vdn = @vdn  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_vdn_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_vdn_insert]  
	@vdn varchar(20),  
	@switchin varchar(20), 
	@description varchar(500) = null  
AS  
	if @vdn is null return  
	set @vdn  = ltrim(rtrim(@vdn))  
	if (select count(*) from vdn where vdn = @vdn) = 0 begin  
		insert into vdn (vdn, switchin, Description) values (@vdn, @switchin, @Description)  
		select 1 'result' 
	end  
	else begin  
		select 0 'result' 
	end


GO
/****** Object:  StoredProcedure [dbo].[usp_vdn_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_vdn_update]  
	@vdn varchar(20),  
	@switchin varchar(20), 
	@Description varchar(500) = null  
AS  
	if @vdn is null return  
		set @vdn  = ltrim(rtrim(@vdn))  
	update vdn  
	set switchin = isnull(@switchin, switchin), Description    = isnull(@Description, Description)  
	where vdn = @vdn


GO
/****** Object:  StoredProcedure [dbo].[usp_vpbchannel_delete]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_vpbchannel_delete]  
	@Channel varchar(20) = null,  
	@Station varchar(50) = null  
AS  
	if @Channel is null and @Station is null return  
	set @Channel = rtrim(ltrim(@Channel))  
	set @Station   = ltrim(rtrim(@Station))  
	delete VPBChannel  
	from VPBChannel  
	where Channel = isnull(@Channel, Channel)  
		and Station   = isnull(@Station, Station)  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_vpbchannel_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_vpbchannel_insert]  
	@Channel varchar(20),  
	@Station varchar(50),  
	@Priority int = 0  
AS  
	if @Channel is null or @Station is null return  
	set @Channel = rtrim(ltrim(@Channel))  
	if @Channel != '' begin  
		if (select count(*) from VPBChannel where Channel = @Channel) = 0  
			insert into VPBChannel (Station, Channel, Priority) values (@Station, @Channel, @Priority)  
		else  
			exec usp_vpbchannel_update @Channel, @Station, @Priority  
		end  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_vpbchannel_update]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_vpbchannel_update]  
	@Channel varchar(10),  
	@Station varchar(50) = null,  
	@Priority int = null  
AS  
	if @Channel is null return  
	set @Channel = rtrim(ltrim(@Channel));  
	update VPBChannel  
	set 	Station    = isnull(@Station, Station),   
		Priority = isnull(@Priority, Priority)  
	where Channel = @Channel  
	return


GO
/****** Object:  StoredProcedure [dbo].[usp_worklogs_insert]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_worklogs_insert]  
	@userid int = 0,  
	@datetime datetime = null,  
	@module varchar(10)	= null,  
	@object varchar(20) = null,  
	@behave varchar(10) = null,  
	@detail varchar(1000) = null  
AS  
	insert worklogs (userid, [datetime], module, object, behave, detail) values (@userid, @datetime, @module, @object, @behave, @detail)


GO
/****** Object:  StoredProcedure [dbo].[uspGetLsn]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[uspGetLsn]
(@MinLsn binary(10) out,@MaxSln binary(10) out)
as
begin
	DECLARE @begin_time datetime, @end_time datetime,@begin_lsn binary(10), @end_lsn binary(10);
	set @begin_time = '2016-09-20 23:59:59';
	set @end_time =getdate();
	set @begin_lsn = (select sys.fn_cdc_map_time_to_lsn('smallest greater than', @begin_time)); 
	set @end_lsn = (select sys.fn_cdc_map_time_to_lsn('largest less than or equal', @end_time));
	 
	SELECT @MinLsn = min(__$start_lsn)
		,@MaxSln = max(__$start_lsn)
	FROM cdc.fn_cdc_get_net_changes_Records_CT(@begin_lsn, @end_lsn, N'all');
end
GO
/****** Object:  UserDefinedFunction [dbo].[ConvertDatetime]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[ConvertDatetime] 
	(@pDate datetime) 
RETURNS varchar(20) 
AS 
BEGIN 
	declare @rDate varchar(20)  
	set @rDate = str(DATEPART(yy, @pDate),4) + '-' + substring(str(100+DATEPART(mm, @pDate),3),2,2) + '-' + substring(str(100+DATEPART(dd, @pDate),3),2,2) + ' ' +  
	substring(str(100+DATEPART(hh, @pDate),3),2,2) + ':' + substring(str(100+DATEPART(mi, @pDate),3),2,2) + ':' + substring(str(100+DATEPART(ss, @pDate),3),2,2) 	 
	RETURN @rDate 
END 







GO
/****** Object:  UserDefinedFunction [dbo].[ConvertDatetimeToDate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[ConvertDatetimeToDate] 
	(@pDate datetime) 
RETURNS varchar(20) 
AS 
BEGIN 
	declare @rDate varchar(20)  
	set @rDate = str(DATEPART(yy, @pDate),4) + '-' + substring(str(100+DATEPART(mm, @pDate),3),2,2) + '-' + substring(str(100+DATEPART(dd, @pDate),3),2,2)
	RETURN @rDate 
END 


GO
/****** Object:  UserDefinedFunction [dbo].[ConvertSecondsToTime]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[ConvertSecondsToTime] 
	(@Seconds int) 
RETURNS varchar(10) 
AS 
BEGIN 
	--return substring(str(10000 + @seconds/60/60, 5), 2, 5) +  ':' + substring(str(100+@seconds/60 - (@seconds/60/60)*60, 3), 2,3) + ':' + substring(str(100+(@seconds-(@seconds/60)*60), 3), 2, 3)
	return ltrim(rtrim(str(@seconds/60/60))) +  ':' + substring(str(100+@seconds/60 - (@seconds/60/60)*60, 3), 2,3) + ':' + substring(str(100+(@seconds-(@seconds/60)*60), 3), 2, 3)
END


GO
/****** Object:  UserDefinedFunction [dbo].[GetCallType]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetCallType]
	(@ProjID int = 0,
	@Calling varchar(50),
	@Called varchar(50)
	)
RETURNS tinyint
AS
BEGIN
	declare @CallType tinyint
	declare @MaxTypeId tinyint

	if (@ProjID <= 0) 
		return 0

	select @MaxTypeId = max(CallType) from ProjCallType where ProjId = @ProjId
	if (@MaxTypeId is null) 
		return 0

	
	declare @Id tinyint
	set @Id = 1
	while (@CallType is null) 
	begin
		select  @CallType = @Id
		where 
			exists (select top 1 * 
			from projitemspecial p 
			where p.CallType = @Id 
				and ((p.calling != '' and @Calling != '' and @Calling like p.calling) or (@Called != '' and p.called != '' and @Called like p.called))
				and p.projid = @ProjID
			)
		set @Id = @Id + 1 
	end

	return isnull(@CallType, 0)
END


GO
/****** Object:  UserDefinedFunction [dbo].[GetFtpId]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[GetFtpId] 
	(@ftppath varchar(30)) 
RETURNS int  
AS 
BEGIN 
	declare @ftpip varchar(15) 
	declare @webshare varchar(15) 
	declare @station varchar(50) 
	declare @p int, @ftpid int 
	set @ftppath = isnull(@ftppath, '') 
	if @ftppath = '' return 0 
	set @p = charindex('/', @ftppath) 
	if (@p>0) begin 
		set @ftpip = substring(@ftppath, 1, @p-1) 
		set @webshare = substring(@ftppath, @p+1, len(@ftppath)) 
	end 
	else  
		set @ftpip = @ftppath 
	set @station = (select top 1 station as station from station where ip=@ftpip) 
	select @ftpid = ftpId  from storage where folder= @webshare and ltrim(rtrim(station))=ltrim(rtrim(@station)) 
	set @ftpid = isnull(@ftpid, 0) 
	RETURN @ftpid 
END 


GO
/****** Object:  UserDefinedFunction [dbo].[GetProject]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[GetProject]
	(@Trunk int,
	@Acd varchar(20),
	@Agent varchar(20),
	@Ext varchar(20),
	@Channel int,
	@Called varchar(50),
	@Vdn varchar(20),
	@StartTime datetime)
RETURNS int
AS
BEGIN
	-- Time Type
	-- 0: always 
	-- 1: Date From/To, Time From/To
	-- 2: Daily
	-- 3: Weekly
	declare @ProjID int

	-- associateId != 0 & trunk, acd, agent
	select @ProjID = o.projId 
	from (select top 1 p.projId  from projectitem p left join associate a on a.associateId = p.associateId left join projitemtype pt on pt.type=p.type
		 where p.associateId != 0
			and (
				(@Trunk!=0 and @Trunk like ltrim(rtrim(p.value))  and pt.typename ='trunk')
				or (@Acd!='' and @Acd like ltrim(rtrim(p.value))  and pt.typename ='acd') 
				or (@Agent like ltrim(rtrim(p.value))  and pt.typename ='agent')
				or (@Ext!='' and @Ext like ltrim(rtrim(p.value)) and pt.typename ='ext')
				or (@Channel!=0 and @Channel like ltrim(rtrim(p.value)) and pt.typename ='channel')
				or (@Called!='' and @Called like '%' + ltrim(rtrim(p.value)) and pt.typename ='called') 
				or (@Vdn!='' and @Vdn like ltrim(rtrim(p.value)) and pt.typename ='vdn') 
			)
			and (
				 (TimeType=1 and str(DATEPART(yy, @Starttime), 4) + substring(str(100+DATEPART(mm, @Starttime),3),2,2) + substring(str(100+DATEPART(dd, @Starttime),3),2,2)  between datefrom and dateto 
					and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
				or (TimeType=2 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
				or (TimeType=3 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&weekday!=0) )
			) 
	) o
	

	-- associateId = 0 & trunk, acd, agent
	if @ProjID is null begin
		select top 1 @ProjID = projId 
		from projectitem p left join projitemtype pt on pt.type=p.type
		where associateId = 0
			and (
				(@Trunk!=0 and @Trunk like ltrim(rtrim(p.value))  and pt.typename ='trunk')
				or (@Acd!='' and @Acd like ltrim(rtrim(p.value))  and pt.typename ='acd') 
				or (@Agent like ltrim(rtrim(p.value))  and pt.typename ='agent')
				or (@Ext!='' and @Ext like ltrim(rtrim(p.value)) and pt.typename ='ext')
			)
	end

	-- associateId = 0 & ext, channel, called, vdn
	if @ProjID is null begin
		select top 1 @ProjID = projId 
		from projectitem p left join projitemtype pt on pt.type=p.type
		where associateId = 0
			and (
				 (@Channel!=0 and @Channel like ltrim(rtrim(p.value)) and pt.typename ='channel')
				or (@Called!='' and @Called like '%' + ltrim(rtrim(p.value)) and pt.typename ='called') 
				or (@Vdn!='' and @Vdn like ltrim(rtrim(p.value)) and pt.typename ='vdn') 
			)
	end

	set @ProjID = isnull(@ProjID, -1)

	RETURN @ProjID
END


GO
/****** Object:  UserDefinedFunction [dbo].[IsAssociate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[IsAssociate]
	(@AssociateIdId int, @StartTime datetime)
RETURNS bit
AS
BEGIN
	-- 0: always 
	-- 1: Date From/To, Time From/To
	-- 2: Daily
	-- 3: Weekly


	if (@AssociateIdId = 0)
		return 1	

	if exists (select top 1 * from Associate
		 where AssociateId = @AssociateIdId 
			and IsDeny = 1
			and (
				(TimeType=0)  
				or (TimeType=1 and str(DATEPART(yy, @Starttime), 4) + substring(str(100+DATEPART(mm, @Starttime),3),2,2) + substring(str(100+DATEPART(dd, @Starttime),3),2,2)  between datefrom and dateto 
					and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
				or (TimeType=2 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
				or (TimeType=3 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&weekday!=0) )
			) 
		 )

		return 0
	else
		if exists (select top 1 * from Associate
			 where AssociateId = @AssociateIdId 
				and IsDeny = 0
				and (
					(TimeType=0)  
					or (TimeType=1 and str(DATEPART(yy, @Starttime), 4) + substring(str(100+DATEPART(mm, @Starttime),3),2,2) + substring(str(100+DATEPART(dd, @Starttime),3),2,2)  between datefrom and dateto 
						and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
					or (TimeType=2 and substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto)  
					or (TimeType=3 and (substring(str(100+DATEPART(hh, @Starttime),3),2,2) + ':' + substring(str(100+DATEPART(mi, @Starttime),3),2,2) between timefrom and timeto) and (substring('01,02,04,08,10,20,40', datepart(weekday, @Starttime)*3 - 2, 2)&weekday!=0) )
				) 
			 )
			 return 1

	RETURN 0
END


GO
/****** Object:  UserDefinedFunction [dbo].[IsLongPhone]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[IsLongPhone]
	(@Phone varchar(50) = null)
RETURNS int
AS
BEGIN
	if isnull(@Phone, '') = ''
		return 0
	else begin
		set @Phone = ltrim(rtrim(@Phone))
		if substring(@Phone,1,3) ='021' begin
			return 0
		end
		else if substring(@Phone, 1, 5)='96803' begin
			return 1
		end
		else if substring(@Phone, 1, 3)='193' begin
			return 1
		end
		else if  substring(@Phone,1,2) ='00' begin
			-- internet call
			return 1
		end
		else if substring(@Phone,1,1) = '0' begin
			/*网通*/
			return 1
		end
	end
	return 0
END


GO
/****** Object:  UserDefinedFunction [dbo].[MaxLsn]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create FUNCTION [dbo].[MaxLsn]()
RETURNS bigint
AS
BEGIN
	DECLARE @begin_time datetime, @end_time datetime,@begin_lsn binary(10), @end_lsn binary(10),@MaxSln bigint;
	set @begin_time = '2016-09-20 23:59:59';
	set @end_time =getdate();
	set @begin_lsn = (select sys.fn_cdc_map_time_to_lsn('smallest greater than', @begin_time)); 
	set @end_lsn = (select sys.fn_cdc_map_time_to_lsn('largest less than or equal', @end_time));
	 
	set @MaxSln = (SELECT cast(max(__$start_lsn)as bigint)
	FROM [VisionLog40].cdc.fn_cdc_get_net_changes_Vary_Records(@begin_lsn, @end_lsn, N'all'));
	RETURN @MaxSln;
END
GO
/****** Object:  UserDefinedFunction [dbo].[PhoneCharge]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[PhoneCharge]
	(@Phone varchar(50) = null, @Seconds int = 0)
RETURNS money
AS
BEGIN
  /**********Fee Count***********************/
	declare  @Charge money
	set @Charge = 0
	if isnull(@Seconds, -1)=-1 or @Seconds = 0 or isnull(@Phone, '') = ''
		set @Charge = 0
	else begin
		set @Phone = ltrim(rtrim(@Phone))
		if substring(@Phone, 1, 5)='96803' begin
			/*ip 96803*/
			/*local*/
			if @Seconds <= 180
				set @Charge =  0.22									-- 0.22/3m
			else
				set @Charge = 0.22 + ((@Seconds-180)/60 + ((@Seconds-180)%60+59)/60) * 0.11		-- 0.11/1m
			/*+ip*/
			set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 0.3
		end
		else if substring(@Phone, 1, 3)='193' begin
			/*ip 193*/
			set @Charge =  (@Seconds/6 + (@Seconds%6+5)/6) * 0.06					-- 0.06/6s
		end
		else if  substring(@Phone,1,2) ='00' begin
			-- internet call
			if substring(@Phone,1,3) = '008'
				set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 1.5
			else
				set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 1.5
		end
		else if substring(@Phone,1,1) = '0'  and substring(@Phone, 1, 3)!='021' begin
			/*网通*/
			/*local*/
			if @Seconds <= 180
				set @Charge =  0.22									-- 0.22/3m
			else
				set @Charge = 0.22 + ((@Seconds-180)/60 + ((@Seconds-180)%60+59)/60) * 0.11		-- 0.11/1m
			/*+ip*/
			set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 0.3
		end
		else if  substring(@Phone,1,1)!='1' and (len(@Phone)<5  or substring(@Phone,1,3) = '800')
			set @Charge = 0
		else begin
			-- local
			--121
			--168
			-- Other
			if @Seconds <= 180
				set @Charge = 0.22									-- 0.22/3m
			else
				set @Charge = 0.22 + ((@Seconds-180)/60 + ((@Seconds-180)%60+59)/60) * 0.11		-- 0.11/1m
		end
	end
  /********************************************/

   RETURN @Charge
END


GO
/****** Object:  UserDefinedFunction [dbo].[PhoneChargeMe]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE FUNCTION [dbo].[PhoneChargeMe]
	(@Phone varchar(50) = null, @Seconds int = 0)
RETURNS money
AS
BEGIN
  /**********Fee Count***********************/
	declare  @Charge money
	set @Charge = 0
	if isnull(@Seconds, -1)=-1 or @Seconds = 0 or isnull(@Phone, '') = ''
		set @Charge = 0
	else begin
		set @Phone = ltrim(rtrim(@Phone))
		if substring(@Phone, 1, 5)='96803' begin
			/*ip 96803*/
			/*local*/
			if @Seconds <= 180
				set @Charge =  0.22									-- 0.22/3m
			else
				set @Charge = 0.22 + ((@Seconds-180)/60 + ((@Seconds-180)%60+59)/60) * 0.11		-- 0.11/1m
			/*+ip*/
			set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 0.3
		end
		else if substring(@Phone, 1, 3)='193' begin
			/*ip 193*/
			set @Charge =  (@Seconds/6 + (@Seconds%6+5)/6) * 0.06					-- 0.06/6s
		end
		else if  substring(@Phone,1,2) ='00' begin
			-- internet call
			if substring(@Phone,1,3) = '008'
				set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 1.5
			else
				set @Charge = @Charge + (@Seconds/60 + (@Seconds%60+59)/60) * 1.5
		end
		else if substring(@Phone,1,1) = '0'  and substring(@Phone, 1, 3) != '021' begin
			/*网通*/
			/*+ip*/
			set @Charge =  (@Seconds/60 + (@Seconds%60+59)/60) * 0.3					-- 0.3/1m
		end
		else if  substring(@Phone,1,1)!='1' and (len(@Phone)<5  or substring(@Phone,1,3) = '800')
			set @Charge = 0
		else begin
			/*local*/
			if @Seconds <= 180
				set @Charge = 0.22									-- 0.22/3m
			else
				set @Charge = 0.22 + ((@Seconds-180)/60 + ((@Seconds-180)%60+59)/60) * 0.11		-- 0.11/1m
		end
	end
  /********************************************/

   RETURN @Charge
END


GO
/****** Object:  Table [dbo].[ACD]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ACD](
	[Acd] [varchar](20) NOT NULL,
	[ManagerAddress] [varchar](20) NULL,
	[Description] [varchar](500) NULL,
 CONSTRAINT [PK_ACDAddress] PRIMARY KEY CLUSTERED 
(
	[Acd] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

GO

CREATE TABLE [dbo].[Address_NoNeedStatic](
       [Address] [nchar](10) NULL,
       [Station] [nvarchar](50) NULL
) ON [PRIMARY]

CREATE TABLE [dbo].[Station_NoNeedStatic](
       [StationName] [nvarchar](50) NULL
) ON [PRIMARY]

/****** Object:  Table [dbo].[Address]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Address](
	[Address] [varchar](20) NOT NULL,
	[Station] [varchar](20) NULL,
	[Type] [int] NULL,
	[MuteFlag] [int] NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Address] PRIMARY KEY CLUSTERED 
(
	[Address] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AddressGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AddressGroup](
	[GroupId] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [varchar](50) NOT NULL,
	[Description] [varchar](500) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_AddressGroup] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AddressGroupRec]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AddressGroupRec](
	[recordid] [bigint] NOT NULL,
	[address] [varchar](20) NOT NULL,
	[groupid] [int] NOT NULL,
 CONSTRAINT [PK_AddressGroupRec] PRIMARY KEY CLUSTERED 
(
	[groupid] ASC,
	[recordid] ASC,
	[address] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Agent]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Agent](
	[AgentId] [varchar](20) NOT NULL,
	[Acd] [varchar](20) NULL,
	[AgentName] [varchar](50) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Agent] PRIMARY KEY CLUSTERED 
(
	[AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AgentGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AgentGroup](
	[GroupId] [int] IDENTITY(1,1) NOT NULL,
	[GroupName] [varchar](50) NOT NULL,
	[Description] [varchar](500) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Group] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AgentGroupRec]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[AgentGroupRec](
	[recordid] [bigint] NOT NULL,
	[agentid] [varchar](20) NOT NULL,
	[groupid] [int] NOT NULL,
 CONSTRAINT [PK_AgentGroupRec] PRIMARY KEY CLUSTERED 
(
	[groupid] ASC,
	[recordid] ASC,
	[agentid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Associate]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Associate](
	[AssociateId] [int] NOT NULL,
	[TimeType] [tinyint] NOT NULL,
	[DateFrom] [varchar](8) NULL,
	[DateTo] [varchar](8) NULL,
	[TimeFrom] [varchar](5) NULL,
	[TimeTo] [varchar](5) NULL,
	[Weekday] [smallint] NULL,
	[IsDeny] [bit] NULL,
 CONSTRAINT [PK_Associate] PRIMARY KEY CLUSTERED 
(
	[AssociateId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Bill]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Bill](
	[BillId] [int] NOT NULL,
	[RecordId] [bigint] NULL,
	[ProjId] [int] NULL,
	[InTrunkGroup] [smallint] NULL,
	[InTrunkNumber] [smallint] NULL,
	[TrunkGroup] [smallint] NULL,
	[TrunkNumber] [smallint] NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[Acd] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[AgentGroup] [smallint] NULL,
	[Extension] [varchar](20) NULL,
	[ExtGroup] [smallint] NULL,
	[Vdn] [varchar](20) NULL,
	[StartTime] [datetime] NOT NULL,
	[Seconds] [int] NOT NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[Flag] [bit] NULL,
	[StartDate] [varchar](8) NULL,
	[Charge] [money] NULL,
	[ChargeMe] [money] NULL,
	[IsLongCall] [tinyint] NULL,
	[CallType] [tinyint] NULL,
	[Frl] [varchar](2) NULL,
 CONSTRAINT [PK_Bill] PRIMARY KEY CLUSTERED 
(
	[BillId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[bill_20160425]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[bill_20160425](
	[BillId] [nvarchar](255) NULL,
	[RecordId] [nvarchar](255) NULL,
	[ProjId] [nvarchar](255) NULL,
	[TrunkGroup] [nvarchar](255) NULL,
	[TrunkNumber] [nvarchar](255) NULL,
	[Calling] [nvarchar](255) NULL,
	[Called] [nvarchar](255) NULL,
	[Acd] [nvarchar](255) NULL,
	[Agent] [nvarchar](255) NULL,
	[AgentGroup] [nvarchar](255) NULL,
	[Extension] [nvarchar](255) NULL,
	[ExtGroup] [nvarchar](255) NULL,
	[Vdn] [nvarchar](255) NULL,
	[StartTime] [nvarchar](255) NULL,
	[Seconds] [nvarchar](255) NULL,
	[Inbound] [nvarchar](255) NULL,
	[Outbound] [nvarchar](255) NULL,
	[Flag] [nvarchar](255) NULL,
	[StartDate] [nvarchar](255) NULL,
	[Charge] [nvarchar](255) NULL,
	[ChargeMe] [nvarchar](255) NULL,
	[IsLongCall] [nvarchar](255) NULL,
	[CallType] [nvarchar](255) NULL,
	[Frl] [nvarchar](255) NULL,
	[InTrunkGroup] [nvarchar](255) NULL,
	[InTrunkNumber] [nvarchar](255) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bill_StatAgent]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bill_StatAgent](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[Charge] [money] NULL,
	[ChargeMe] [money] NULL,
 CONSTRAINT [PK_Bill_StatAgent] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bill_StatExt]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bill_StatExt](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Exts] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[Charge] [money] NULL,
	[ChargeMe] [money] NULL,
 CONSTRAINT [PK_Bill_StatExt] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bill_StatExtGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bill_StatExtGroup](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Exts] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[Charge] [money] NULL,
	[ChargeMe] [money] NULL,
 CONSTRAINT [PK_Bill_StatExtGroup] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bill_StatExtGroupExts]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Bill_StatExtGroupExts](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Ext] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Bill_StatExtGroupExts] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Bill_StatGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bill_StatGroup](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[Charge] [money] NULL,
	[ChargeMe] [money] NULL,
 CONSTRAINT [PK_Bill_StatGroup] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bill_StatGroupAgents]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Bill_StatGroupAgents](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agent] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Bill_StatGroupAgents] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Bill_StatProj]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Bill_StatProj](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Exts] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[Charge] [money] NULL,
	[ChargeMe] [money] NULL,
 CONSTRAINT [PK_Bill_StatProj] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Bookmark]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Bookmark](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RecordId] [bigint] NOT NULL,
	[BookmarkName] [varchar](50) NULL,
	[BookmarkTime] [varchar](8) NULL,
 CONSTRAINT [PK_Bookmark] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Call]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Call](
	[CallSeq] [bigint] IDENTITY(1,1) NOT NULL,
	[RecordID] [bigint] NULL,
	[Calling] [varchar](32) NULL,
	[Called] [varchar](32) NULL,
	[CallID] [int] NULL,
	[Answer] [varchar](32) NULL,
	[Channel] [varchar](24) NULL,
	[Trunk] [int] NULL,
	[Acd] [varchar](32) NULL,
	[Agent] [varchar](32) NULL,
	[Extension] [varchar](32) NULL,
	[Vdn] [varchar](32) NULL,
	[StartTime] [datetime] NULL,
	[Seconds] [int] NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[DtmfTime] [datetime] NULL,
	[Dtmf] [varchar](50) NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [nchar](128) NULL,
 CONSTRAINT [PK_Call] PRIMARY KEY CLUSTERED 
(
	[CallSeq] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Connection]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Connection](
	[RecordId] [bigint] NOT NULL,
	[Device] [varchar](20) NOT NULL,
	[Phone] [varchar](50) NULL,
	[Agent] [varchar](20) NULL,
	[Enter] [int] NULL,
	[Leave] [int] NULL,
 CONSTRAINT [PK_Connection] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[Device] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CTI]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CTI](
	[CtiName] [char](32) NOT NULL,
	[LinkStr] [varchar](50) NOT NULL,
	[Station] [varchar](20) NOT NULL,
	[Port] [int] NOT NULL,
	[Username] [varchar](20) NOT NULL,
	[Password] [varchar](20) NOT NULL,
	[Type] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_CTI] PRIMARY KEY CLUSTERED 
(
	[CtiName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[CTILink]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CTILink](
	[LinkName] [char](32) NOT NULL,
	[CtiName] [char](32) NOT NULL,
	[Utility] [int] NOT NULL,
	[Description] [varchar](500) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_TLink] PRIMARY KEY CLUSTERED 
(
	[LinkName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ENC_LastRecordDT]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ENC_LastRecordDT](
	[StartTime] [datetime] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[EncryKeys]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EncryKeys](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NULL,
	[BeginDate] [datetime] NOT NULL,
	[EndDate] [datetime] NOT NULL,
	[PasswordBits] [int] NULL,
	[Password] [varchar](50) NULL,
	[KeyInfo] [varchar](256) NOT NULL,
 CONSTRAINT [PK_EncryKeys] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ETL_LOG]    Script Date: 2016/12/13 10:09:14 ******/
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
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FileDelTask]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FileDelTask](
	[TaskId] [int] IDENTITY(1,1) NOT NULL,
	[TaskName] [varchar](50) NOT NULL,
	[RecTaskId] [int] NOT NULL,
	[TimeBegin] [int] NOT NULL,
	[TimeEnd] [int] NOT NULL,
	[Period] [int] NOT NULL,
	[FileTypes] [varchar](50) NOT NULL,
	[KeepDays] [int] NOT NULL,
	[FindDepth] [int] NOT NULL,
	[LastExecDate] [int] NOT NULL,
	[NextExecDate] [int] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK__FileDelTask__1A69E950] PRIMARY KEY CLUSTERED 
(
	[TaskId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Filter]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Filter](
	[Phone] [varchar](20) NOT NULL,
 CONSTRAINT [PK_Filter] PRIMARY KEY CLUSTERED 
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FormRec]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FormRec](
	[RecordId] [bigint] NOT NULL,
	[Userid] [int] NULL,
	[Updatedate] [datetime] NULL,
	[Flag] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_FormRec] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[GroupAddress]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GroupAddress](
	[GroupID] [int] NOT NULL,
	[Address] [varchar](20) NOT NULL,
 CONSTRAINT [PK_GroupAddress] PRIMARY KEY CLUSTERED 
(
	[GroupID] ASC,
	[Address] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[GroupAgent]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[GroupAgent](
	[GroupId] [int] NOT NULL,
	[AgentId] [varchar](20) NOT NULL,
	[TimeType] [tinyint] NULL,
	[TimeFrom] [varchar](5) NULL,
	[TimeTo] [varchar](5) NULL,
	[Weeks] [smallint] NULL,
 CONSTRAINT [PK_GroupAgent] PRIMARY KEY CLUSTERED 
(
	[GroupId] ASC,
	[AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Label]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Label](
	[RecordId] [bigint] NOT NULL,
	[LabelId] [int] IDENTITY(1,1) NOT NULL,
	[Label] [varchar](50) NOT NULL,
	[Description] [varchar](500) NULL,
	[Userid] [int] NULL,
	[Updatedate] [datetime] NULL,
	[Flag] [tinyint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Label] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[LabelId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[MENU]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[MENU](
	[MENU_ID] [char](6) NOT NULL,
	[MENU_NAME] [varchar](20) NOT NULL,
	[HAS_IMAGE] [bit] NOT NULL,
	[DEPEND] [varchar](50) NULL,
	[OPEN_MODE] [char](1) NULL,
	[POP_WIDTH] [int] NULL,
	[POP_HEIGHT] [int] NULL,
	[SHOW_MODAL] [bit] NULL,
	[APPLICATION] [varchar](50) NULL,
	[METHOD] [varchar](10) NULL,
	[PRIVI_FLAG] [char](1) NULL,
 CONSTRAINT [PK_MENU] PRIMARY KEY CLUSTERED 
(
	[MENU_ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Monitor]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Monitor](
	[monitorid] [int] IDENTITY(1,1) NOT NULL,
	[userid] [varchar](20) NULL,
	[agentid] [varchar](20) NULL,
	[recordid] [int] NULL,
	[timestart] [datetime] NULL,
	[timeend] [datetime] NULL,
 CONSTRAINT [PK_Monitor] PRIMARY KEY CLUSTERED 
(
	[monitorid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[OTHER_DEVICE]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[OTHER_DEVICE](
	[DEVICE] [varchar](100) NULL,
	[DESC] [varchar](100) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PackageRec]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PackageRec](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[recordid] [bigint] NOT NULL,
	[date] [datetime] NULL,
	[filesize] [varchar](50) NULL,
	[username] [varchar](50) NULL,
	[success] [bit] NULL,
 CONSTRAINT [PK_PackageRec] PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProjCallType]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProjCallType](
	[ProjId] [int] NOT NULL,
	[CallType] [tinyint] NOT NULL,
	[Desc] [varchar](5000) NULL,
 CONSTRAINT [PK_ProjItemCallType] PRIMARY KEY CLUSTERED 
(
	[ProjId] ASC,
	[CallType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Project]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Project](
	[ProjId] [int] IDENTITY(1,1) NOT NULL,
	[ProjName] [varchar](50) NOT NULL,
	[Description] [varchar](1000) NULL,
	[TimeRangeType] [tinyint] NULL,
	[WeekState] [int] NULL,
	[MonthState] [int] NULL,
	[date_start] [varchar](8) NULL,
	[date_end] [varchar](8) NULL,
	[time_start] [varchar](8) NULL,
	[time_end] [varchar](8) NULL,
	[RecPercent] [tinyint] NULL,
	[ScrPercent] [tinyint] NULL,
	[VideoPercent] [tinyint] NULL,
	[DataEncry] [bit] NOT NULL,
	[AutoBackup] [bit] NOT NULL,
	[DestFolder] [varchar](256) NULL,
	[BackupDays] [smallint] NULL,
	[BackupTime] [smallint] NULL,
	[RecKeepDays] [smallint] NULL,
	[ScrKeepDays] [smallint] NULL,
	[VideoKeepDays] [smallint] NULL,
	[Enabled] [bit] NULL,
	[TransStopRecord] [bit] NULL,
 CONSTRAINT [PK_BillProj] PRIMARY KEY CLUSTERED 
(
	[ProjId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProjectItem]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProjectItem](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[ProjId] [int] NOT NULL,
	[Type] [smallint] NOT NULL,
	[Value] [varchar](50) NOT NULL,
	[AssociateId] [int] NULL,
 CONSTRAINT [PK_ProjectItem] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProjItemSpecial]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProjItemSpecial](
	[ProjId] [int] NOT NULL,
	[CallType] [tinyint] NOT NULL,
	[Calling] [varchar](50) NULL,
	[Called] [varchar](50) NULL,
	[OrderBy] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ProjItemType]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ProjItemType](
	[Type] [smallint] NOT NULL,
	[TypeName] [varchar](50) NOT NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_ProjItemType] PRIMARY KEY CLUSTERED 
(
	[Type] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecAdditional]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecAdditional](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RecordId] [bigint] NOT NULL,
	[CallId] [int] NULL,
	[CtrlDevice] [varchar](50) NULL,
	[Device] [varchar](50) NULL,
	[EventType] [int] NOT NULL,
	[StartTime] [int] NOT NULL,
	[TimeLen] [int] NOT NULL,
 CONSTRAINT [PK_RecAdditional] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecAdditional_2016]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecAdditional_2016](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RecordId] [bigint] NOT NULL,
	[CallId] [int] NULL,
	[CtrlDevice] [varchar](50) NULL,
	[Device] [varchar](50) NULL,
	[EventType] [int] NOT NULL,
	[StartTime] [int] NOT NULL,
	[TimeLen] [int] NOT NULL,
 CONSTRAINT [PK_RecAdditional_2016] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecExts]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[RecExts](
	[RecordId] [bigint] NOT NULL,
	[UCID] [varchar](25) NOT NULL,
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
/****** Object:  Table [dbo].[RecordMutes]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecordMutes](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[RecordId] [bigint] NULL,
	[StartTime] [int] NULL,
	[Timelen] [int] NULL,
	[isExpected] [bit] NULL,
 CONSTRAINT [PK_RecordMutes] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Records]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Records](
	[RecordId] [bigint] NOT NULL,
	[Calling] [varchar](50) NOT NULL,
	[Called] [varchar](50) NOT NULL,
	[Answer] [varchar](50) NOT NULL,
	[Master] [varchar](20) NOT NULL,
	[Acd] [varchar](20) NULL,
	[Channel] [varchar](10) NULL,
	[VDN] [varchar](10) NULL,
	[CallID] [int] NULL,
	[Trunk] [int] NULL,
	[SessionID] [int] NULL,
	[RecURL] [smallint] NULL,
	[ScrURL] [smallint] NULL,
	[VideoURL] [smallint] NULL,
	[TrsStation] [varchar](50) NULL,
	[RecordStartTime] [datetime] NULL,
	[StartTime] [datetime] NOT NULL,
	[RecordSeconds] [int] NOT NULL,
	[Seconds] [int] NOT NULL,
	[State] [int] NOT NULL,
	[FileCount] [smallint] NULL,
	[RecFlag] [tinyint] NULL,
	[ScrFlag] [tinyint] NULL,
	[VideoFlag] [tinyint] NULL,
	[StartDate] [int] NULL,
	[StartHour] [tinyint] NULL,
	[Backuped] [tinyint] NULL,
	[Checked] [bit] NULL,
	[Direction] [bit] NULL,
	[ProjId] [int] NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[TransInCount] [int] NULL,
	[TransOutCount] [int] NULL,
	[ConfsCount] [int] NULL,
	[Flag] [bit] NULL,
	[Extension] [varchar](20) NULL,
	[VoiceType] [tinyint] NULL,
	[UCID] [varchar](50) NULL,
	[UUI] [varchar](256) NULL,
	[AttendAgent] [varchar](256) NULL,
	[AttendDevice] [varchar](256) NULL,
	[NeedEncry] [bit] NULL,
	[DataEncrypted] [int] NULL,
	[EncryKey] [varchar](256) NULL,
	[TaskID] [varchar](50) NULL,
	[UniqueID] [int] IDENTITY(1,1) NOT NULL,
	[CMSCALLID] [bigint] NULL,
	[Visible] [bit] NULL,
	[SiteID] [int] NULL,
        [TmStamp] [timestamp] NULL,
 CONSTRAINT [PK_Records] PRIMARY KEY NONCLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
)

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[RecordsEvtCaculate]    Script Date: 2016/12/13 10:09:14 ******/
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
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[RtTrs]    Script Date: 2016/12/13 10:09:14 ******/
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
/****** Object:  Table [dbo].[ScreenCfg]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ScreenCfg](
	[ScreenCfgID] [int] IDENTITY(1,1) NOT NULL,
	[ScreenCfgName] [varchar](50) NOT NULL,
	[Description] [varchar](1000) NULL,
	[StartDate] [varchar](8) NULL,
	[EndDate] [varchar](8) NULL,
	[ScrFtpID] [smallint] NULL,
	[VideoEnabled] [tinyint] NULL,
	[VideoFtpID] [smallint] NULL,
	[VideoZoomScale] [smallint] NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_ScreenCfg] PRIMARY KEY CLUSTERED 
(
	[ScreenCfgID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Site]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Site](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SiteName] [varchar](100) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Site] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SiteRelated]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SiteRelated](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[SiteID] [int] NULL,
	[SiteType] [int] NULL,
	[RelatedID] [varchar](20) NULL,
 CONSTRAINT [PK_SiteRelated] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) 

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatAgent]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatAgent](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL,
 CONSTRAINT [PK_StatAgent] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatDaily]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatDaily](
	[StatDate] [int] NOT NULL,
	[MaxId] [int] NULL,
	[MinTo] [int] NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL,
 CONSTRAINT [PK_StatDaily] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatDailyAgents]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatDailyAgents](
	[StatDate] [int] NOT NULL,
	[Agent] [varchar](20) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatExt]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatExt](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Exts] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL,
 CONSTRAINT [PK_StatExt] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatExtGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatExtGroup](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Exts] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL,
 CONSTRAINT [PK_StatExtGroup] PRIMARY KEY CLUSTERED 
(
	[StatDate] ASC,
	[SubId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatExtGroupExts]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatExtGroupExts](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Ext] [varchar](20) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatGroup](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatGroupAgents]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatGroupAgents](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agent] [varchar](20) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatHour]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatHour](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatHourAgents]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatHourAgents](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agent] [varchar](20) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Station]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Station](
	[Station] [varchar](50) NOT NULL,
	[IP] [char](15) NULL,
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
/****** Object:  Table [dbo].[StatTask]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatTask](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agents] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[StatTaskAgents]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[StatTaskAgents](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[Agent] [varchar](20) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[StatTrunkGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StatTrunkGroup](
	[StatDate] [int] NOT NULL,
	[SubId] [int] NOT NULL,
	[TrunkGroups] [int] NULL,
	[Times] [int] NULL,
	[Seconds] [int] NULL,
	[m0] [int] NULL,
	[m1] [int] NULL,
	[m2] [int] NULL,
	[m3] [int] NULL,
	[m4] [int] NULL,
	[m5] [int] NULL,
	[m6] [int] NULL,
	[m7] [int] NULL,
	[m8] [int] NULL,
	[m9] [int] NULL,
	[m10] [int] NULL,
	[m11] [int] NULL,
	[m12] [int] NULL,
	[m13] [int] NULL,
	[m14] [int] NULL,
	[m15] [int] NULL,
	[m16] [int] NULL,
	[m17] [int] NULL,
	[m18] [int] NULL,
	[m19] [int] NULL,
	[m20] [int] NULL,
	[m21] [int] NULL,
	[m22] [int] NULL,
	[m23] [int] NULL,
	[m24] [int] NULL,
	[m25] [int] NULL,
	[m26] [int] NULL,
	[m27] [int] NULL,
	[m28] [int] NULL,
	[m29] [int] NULL,
	[m30] [int] NULL,
	[m31] [int] NULL,
	[m32] [int] NULL,
	[m33] [int] NULL,
	[m34] [int] NULL,
	[m35] [int] NULL,
	[m36] [int] NULL,
	[m37] [int] NULL,
	[m38] [int] NULL,
	[m39] [int] NULL,
	[m40] [int] NULL,
	[m41] [int] NULL,
	[m42] [int] NULL,
	[m43] [int] NULL,
	[m44] [int] NULL,
	[m45] [int] NULL,
	[m46] [int] NULL,
	[m47] [int] NULL,
	[m48] [int] NULL,
	[m49] [int] NULL,
	[m50] [int] NULL,
	[m51] [int] NULL,
	[m52] [int] NULL,
	[m53] [int] NULL,
	[m54] [int] NULL,
	[m55] [int] NULL,
	[m56] [int] NULL,
	[m57] [int] NULL,
	[m58] [int] NULL,
	[m59] [int] NULL,
	[m60] [int] NULL,
	[m61] [int] NULL,
	[m62] [int] NULL,
	[m63] [int] NULL,
	[m64] [int] NULL,
	[m65] [int] NULL,
	[m66] [int] NULL,
	[m67] [int] NULL,
	[m68] [int] NULL,
	[m69] [int] NULL,
	[m70] [int] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Storage]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Storage](
	[FtpId] [int] IDENTITY(1,1) NOT NULL,
	[Station] [varchar](50) NOT NULL,
	[Folder] [varchar](50) NOT NULL,
	[Port] [int] NOT NULL,
	[Drive] [char](1) NOT NULL,
	[RealFolder] [varchar](256) NOT NULL,
	[Priority] [tinyint] NOT NULL,
	[Username] [varchar](50) NOT NULL,
	[Password] [varchar](50) NOT NULL,
	[StorageType] [tinyint] NOT NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_Storage] PRIMARY KEY CLUSTERED 
(
	[FtpId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Supervisor]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Supervisor](
	[LogID] [int] NOT NULL,
	[LogUser] [varchar](20) NOT NULL,
	[LogPass] [varchar](50) NOT NULL,
	[Privilege] [varchar](1000) NOT NULL,
	[Type] [varchar](1) NULL,
	[Agents] [varchar](2000) NULL,
	[Groups] [varchar](2000) NULL,
	[Tasks] [varchar](2000) NULL,
	[Members] [varchar](800) NULL,
	[IsQD] [bit] NULL,
	[LastDate] [datetime] NULL,
	[Validays] [int] NOT NULL,
	[ErrTimes] [int] NOT NULL,
	[Locked] [bit] NOT NULL,
 CONSTRAINT [PK_Supervisor] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[System]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[System](
	[Key] [char](20) NOT NULL,
	[Type] [varchar](8) NOT NULL,
	[Value] [varchar](100) NOT NULL,
 CONSTRAINT [PK_System] PRIMARY KEY CLUSTERED 
(
	[Key] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TaskItem]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TaskItem](
	[TaskId] [int] NOT NULL,
	[AgentId] [varchar](20) NULL,
	[AgentGroupId] [int] NULL,
	[Address] [varchar](20) NULL,
	[AddressGroupId] [int] NULL,
	[Vdn] [varchar](20) NULL,
	[Trunk] [varchar](20) NULL,
	[TrunkGroupId] [int] NULL,
	[Acd] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Trunk]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Trunk](
	[TrunkID] [int] NOT NULL,
	[TrunkNum] [int] NOT NULL,
	[TrunkGroup] [int] NOT NULL,
	[Station] [varchar](50) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_Trunk] PRIMARY KEY CLUSTERED 
(
	[TrunkID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TrunkGroup]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TrunkGroup](
	[GroupID] [int] NOT NULL,
	[GroupName] [varchar](50) NOT NULL,
	[Description] [varchar](500) NULL,
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
/****** Object:  Table [dbo].[VDN]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VDN](
	[vdn] [varchar](20) NOT NULL,
	[switchin] [varchar](20) NULL,
	[description] [varchar](500) NULL,
	[enabled] [bit] NULL,
 CONSTRAINT [PK_VDN] PRIMARY KEY CLUSTERED 
(
	[vdn] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VoiceType]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VoiceType](
	[TypeId] [tinyint] NOT NULL,
	[TypeName] [varchar](10) NULL,
	[Ext] [varchar](10) NOT NULL,
	[Wavbit] [tinyint] NOT NULL,
	[Code] [tinyint] NOT NULL,
	[Description] [varchar](100) NULL,
	[Enabled] [bit] NULL,
 CONSTRAINT [PK_VoiceType] PRIMARY KEY CLUSTERED 
(
	[TypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[VPBChannel]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[VPBChannel](
	[Channel] [varchar](20) NOT NULL,
	[Station] [varchar](20) NOT NULL,
	[Priority] [tinyint] NULL,
 CONSTRAINT [PK_VPBChannel] PRIMARY KEY CLUSTERED 
(
	[Channel] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[AddressGroupRec]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[AddressGroupRec](
	[recordid] [bigint] NOT NULL,
	[address] [varchar](20) NOT NULL,
	[groupid] [int] NOT NULL,
 CONSTRAINT [PK_AddressGroupRec] PRIMARY KEY CLUSTERED 
(
	[groupid] ASC,
	[recordid] ASC,
	[address] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[Connection]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[Connection](
	[RecordId] [bigint] NOT NULL,
	[Device] [varchar](20) NOT NULL,
	[Phone] [varchar](20) NULL,
	[Agent] [varchar](20) NULL,
	[Enter] [int] NULL,
	[Leave] [int] NULL,
 CONSTRAINT [PK_Connection] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC,
	[Device] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[Records]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[Records](
	[RecordId] [bigint] NOT NULL,
	[Calling] [varchar](50) NOT NULL,
	[Called] [varchar](50) NOT NULL,
	[Answer] [varchar](50) NOT NULL,
	[Master] [varchar](20) NOT NULL,
	[Channel] [varchar](10) NOT NULL,
	[AudioURL] [smallint] NULL,
	[VideoURL] [smallint] NULL,
	[StartTime] [datetime] NOT NULL,
	[Seconds] [int] NOT NULL,
	[State] [int] NOT NULL,
	[Finished] [tinyint] NULL,
	[StartDate] [int] NULL,
	[StartHour] [tinyint] NULL,
	[Backuped] [tinyint] NULL,
	[Checked] [bit] NULL,
	[Direction] [bit] NULL,
	[ProjId] [int] NULL,
	[Inbound] [bit] NULL,
	[Outbound] [bit] NULL,
	[Flag] [bit] NULL,
	[Extension] [varchar](20) NULL,
	[VoiceType] [tinyint] NULL,
	[Acd] [varchar](20) NULL,
	[UCID] [varchar](20) NULL,
	[UUI] [varchar](256) NULL,
	[SilenceOffset1] [int] NULL,
	[SilenceLen1] [int] NULL,
 CONSTRAINT [PK_Records] PRIMARY KEY CLUSTERED 
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[Task]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[Task](
	[TaskID] [int] NOT NULL,
	[TaskName] [varchar](50) NOT NULL,
	[Description] [varchar](1000) NULL,
	[ObjType] [tinyint] NULL,
	[TimeRangeType] [tinyint] NULL,
	[Quality] [tinyint] NULL,
	[State] [tinyint] NULL,
	[WeekState] [int] NULL,
	[MonthState] [int] NULL,
	[date_start] [varchar](8) NULL,
	[date_end] [varchar](8) NULL,
	[time_start] [varchar](8) NULL,
	[time_end] [varchar](8) NULL,
	[RecFlag] [tinyint] NULL,
	[Priority] [smallint] NULL,
	[Enabled] [bit] NULL,
	[Items] [text] NULL,
	[RecPercent] [tinyint] NULL,
	[ScrPercent] [tinyint] NULL,
 CONSTRAINT [PK_Task] PRIMARY KEY CLUSTERED 
(
	[TaskID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[TaskItem]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [hist].[TaskItem](
	[TaskId] [int] NOT NULL,
	[AgentId] [varchar](20) NULL,
	[AgentGroupId] [int] NULL,
	[Address] [varchar](20) NULL,
	[AddressGroupId] [int] NULL,
	[Vdn] [varchar](50) NULL,
	[Trunk] [varchar](50) NULL,
	[TrunkGroupId] [int] NULL,
	[Acd] [varchar](20) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [hist].[TaskRec]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [hist].[TaskRec](
	[taskid] [int] NOT NULL,
	[recordid] [bigint] NOT NULL,
 CONSTRAINT [PK_TaskRec] PRIMARY KEY CLUSTERED 
(
	[taskid] ASC,
	[recordid] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  UserDefinedFunction [cdc].[fn_cdc_get_all_changes_Records_CT]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/****** Object:  UserDefinedFunction [dbo].[ufnSplitStringToTable]    Script Date: 2016/12/13 10:09:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


	CREATE FUNCTION [dbo].[ufnSplitStringToTable]
		(
		  @str VARCHAR(MAX) ,
		  @split VARCHAR(10)
		)
		RETURNS TABLE
			AS 
			RETURN
				( SELECT B.ParamKey
				  FROM ( SELECT [value] = CONVERT(XML , '<v>' + REPLACE(@str , @split , '</v><v>')+ '</v>')
						) A
				  OUTER APPLY ( SELECT  ParamKey = N.v.value('.' , 'varchar(100)')
								FROM    A.[value].nodes('/v') N ( v )
							  ) B
				)


GO
/****** Object:  Index [IX_Records_StartTime]    Script Date: 2016/12/13 10:09:14 ******/
CREATE CLUSTERED INDEX [IX_Records_StartTime] ON [dbo].[Records]
(
	[StartTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Bill]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Bill] ON [dbo].[Bill]
(
	[Calling] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Bill_1]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Bill_1] ON [dbo].[Bill]
(
	[Called] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Bill_2]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Bill_2] ON [dbo].[Bill]
(
	[StartDate] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Connection]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Connection] ON [dbo].[Connection]
(
	[Agent] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Connection_1]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Connection_1] ON [dbo].[Connection]
(
	[Phone] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_GroupAgent]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_GroupAgent] ON [dbo].[GroupAgent]
(
	[GroupId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_GroupAgent_1]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_GroupAgent_1] ON [dbo].[GroupAgent]
(
	[AgentId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [PK_RecAdditional_2016_RecordId]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [PK_RecAdditional_2016_RecordId] ON [dbo].[RecAdditional_2016]
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_RecExts_Ucid]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_RecExts_Ucid] ON [dbo].[RecExts]
(
	[UCID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Records_Mast]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Records_Mast] ON [dbo].[Records]
(
	[Master] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
GO
/****** Object:  Index [IX_Records_RecordStartTime]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Records_RecordStartTime] ON [dbo].[Records]
(
	[RecordStartTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Records_StartTime_Called]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Records_StartTime_Called] ON [dbo].[Records]
(
	[Called] ASC,
	[StartTime] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Records_StartTime_Calling]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Records_StartTime_Calling] ON [dbo].[Records]
(
	[StartTime] ASC,
	[Calling] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING ON

GO
/****** Object:  Index [IX_Records_Ucid]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_Records_Ucid] ON [dbo].[Records]
(
	[UCID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_RcdEvtCa_RecordId]    Script Date: 2016/12/13 10:09:14 ******/
CREATE UNIQUE NONCLUSTERED INDEX [IX_RcdEvtCa_RecordId] ON [dbo].[RecordsEvtCaculate]
(
	[RecordId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
/****** Object:  Index [IX_TaskItem]    Script Date: 2016/12/13 10:09:14 ******/
CREATE NONCLUSTERED INDEX [IX_TaskItem] ON [dbo].[TaskItem]
(
	[TaskId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_NetPC]  DEFAULT ((0)) FOR [Station]
GO
ALTER TABLE [dbo].[Address] ADD  CONSTRAINT [DF_Address_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[AddressGroup] ADD  CONSTRAINT [DF_AddressGroup_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Agent] ADD  CONSTRAINT [DF_Agent_AgentId]  DEFAULT ((1)) FOR [AgentId]
GO
ALTER TABLE [dbo].[AgentGroup] ADD  CONSTRAINT [DF_Groups_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Bill] ADD  CONSTRAINT [DF_Bill_Vdn]  DEFAULT ((0)) FOR [Vdn]
GO
ALTER TABLE [dbo].[Bill] ADD  CONSTRAINT [DF_Bill_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[Bill] ADD  CONSTRAINT [DF_Bill_IsLongCall]  DEFAULT ((0)) FOR [IsLongCall]
GO
ALTER TABLE [dbo].[CTI] ADD  CONSTRAINT [DF_CTI_LinkName]  DEFAULT ((1)) FOR [CtiName]
GO
ALTER TABLE [dbo].[CTI] ADD  CONSTRAINT [DF_CTI_Port]  DEFAULT ((0)) FOR [Port]
GO
ALTER TABLE [dbo].[CTI] ADD  CONSTRAINT [DF_CTI_Username]  DEFAULT ('administrator') FOR [Username]
GO
ALTER TABLE [dbo].[CTI] ADD  CONSTRAINT [DF_CTI_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[FormRec] ADD  CONSTRAINT [DF_FormRec_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[FormRec] ADD  CONSTRAINT [DF_FormRec_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[GroupAddress] ADD  CONSTRAINT [DF_GroupAddress_GroupID]  DEFAULT ((0)) FOR [GroupID]
GO
ALTER TABLE [dbo].[GroupAgent] ADD  CONSTRAINT [DF_GroupAgent_GroupId]  DEFAULT ((0)) FOR [GroupId]
GO
ALTER TABLE [dbo].[GroupAgent] ADD  CONSTRAINT [DF_GroupAgent_AgentId]  DEFAULT ((0)) FOR [AgentId]
GO
ALTER TABLE [dbo].[GroupAgent] ADD  CONSTRAINT [DF_GroupAgent_TimeType]  DEFAULT ((0)) FOR [TimeType]
GO
ALTER TABLE [dbo].[GroupAgent] ADD  CONSTRAINT [DF_GroupAgent_Week]  DEFAULT ((0)) FOR [Weeks]
GO
ALTER TABLE [dbo].[Label] ADD  CONSTRAINT [DF_Label_Flag]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[Label] ADD  CONSTRAINT [DF_Label_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_HAVE_IMAGE]  DEFAULT ((0)) FOR [HAS_IMAGE]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_DEPEND]  DEFAULT ('') FOR [DEPEND]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_OPEN_MODE]  DEFAULT ('') FOR [OPEN_MODE]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_POP_WIDTH]  DEFAULT ((0)) FOR [POP_WIDTH]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_POP_HEIGHT]  DEFAULT ((0)) FOR [POP_HEIGHT]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_SHOW_MODAL]  DEFAULT ((0)) FOR [SHOW_MODAL]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_APPLICATION]  DEFAULT ('') FOR [APPLICATION]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_METHOD]  DEFAULT ('') FOR [METHOD]
GO
ALTER TABLE [dbo].[MENU] ADD  CONSTRAINT [DF_MENU_CAN_PRIVI]  DEFAULT ((0)) FOR [PRIVI_FLAG]
GO
ALTER TABLE [dbo].[OTHER_DEVICE] ADD  CONSTRAINT [DF_OTHER_DEVICE_DEVICE]  DEFAULT ('') FOR [DEVICE]
GO
ALTER TABLE [dbo].[OTHER_DEVICE] ADD  CONSTRAINT [DF_OTHER_DEVICE_DESC]  DEFAULT ('') FOR [DESC]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_TimeRangeType]  DEFAULT ((0)) FOR [TimeRangeType]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_WeekState]  DEFAULT ((0)) FOR [WeekState]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_MonthState]  DEFAULT ((0)) FOR [MonthState]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_DataEncry]  DEFAULT ((0)) FOR [DataEncry]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_AutoBackup]  DEFAULT ((0)) FOR [AutoBackup]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_RecKeepDays]  DEFAULT ((365)) FOR [RecKeepDays]
GO
ALTER TABLE [dbo].[Project] ADD  CONSTRAINT [DF_Project_VideoKeepDays]  DEFAULT ((365)) FOR [VideoKeepDays]
GO
ALTER TABLE [dbo].[ProjectItem] ADD  CONSTRAINT [DF_ProjectItem_AssociateId]  DEFAULT ((0)) FOR [AssociateId]
GO
ALTER TABLE [dbo].[RecExts] ADD  CONSTRAINT [DF_RecExts_RecordId]  DEFAULT ((0)) FOR [RecordId]
GO
ALTER TABLE [dbo].[RecExts] ADD  CONSTRAINT [DF_RecExts_UCID]  DEFAULT ((0)) FOR [UCID]
GO
ALTER TABLE [dbo].[RecExts] ADD  CONSTRAINT [DF_RecExts_ItemTime]  DEFAULT (getdate()) FOR [ItemTime]
GO
ALTER TABLE [dbo].[RecExts] ADD  CONSTRAINT [DF_RecExts_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF__tmp_ms_xx__TrsSt__3BCADD1B]  DEFAULT (NULL) FOR [TrsStation]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_RecordSeconds]  DEFAULT ((0)) FOR [RecordSeconds]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Seconds]  DEFAULT ((0)) FOR [Seconds]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_State]  DEFAULT ((0)) FOR [State]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_finished]  DEFAULT ((0)) FOR [VideoFlag]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_StartDate]  DEFAULT ((0)) FOR [StartDate]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_StartHour]  DEFAULT ((0)) FOR [StartHour]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Backuped]  DEFAULT ((0)) FOR [Backuped]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Checked]  DEFAULT ((0)) FOR [Checked]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Direction]  DEFAULT ((1)) FOR [Direction]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_ProjId_1]  DEFAULT ((0)) FOR [ProjId]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Inbound_1]  DEFAULT ((0)) FOR [Inbound]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Outbound_1]  DEFAULT ((0)) FOR [Outbound]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_TransInCount]  DEFAULT ((0)) FOR [TransInCount]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_TransOutCount]  DEFAULT ((0)) FOR [TransOutCount]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_ConfsCount]  DEFAULT ((0)) FOR [ConfsCount]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Flag_1]  DEFAULT ((0)) FOR [Flag]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Extension_1]  DEFAULT ((0)) FOR [Extension]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_VoiceType]  DEFAULT ((0)) FOR [VoiceType]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_DataEncry]  DEFAULT ((0)) FOR [DataEncrypted]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_CMSCALLID]  DEFAULT ((0)) FOR [CMSCALLID]
GO
ALTER TABLE [dbo].[Records] ADD  CONSTRAINT [DF_Records_Visible]  DEFAULT ((1)) FOR [Visible]
GO
ALTER TABLE [dbo].[RtTrs] ADD  CONSTRAINT [DF_RtTrs_TrsEnable]  DEFAULT ((0)) FOR [TrsEnable]
GO
ALTER TABLE [dbo].[RtTrs] ADD  CONSTRAINT [DF_RtTrs_TrsLogin]  DEFAULT ((0)) FOR [TrsLogin]
GO
ALTER TABLE [dbo].[ScreenCfg] ADD  CONSTRAINT [DF_Task_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Station] ADD  CONSTRAINT [DF_NetPC_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Folder]  DEFAULT ('/') FOR [Folder]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Port]  DEFAULT ((80)) FOR [Port]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Drive]  DEFAULT ('C') FOR [Drive]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_RealFolder]  DEFAULT ('') FOR [RealFolder]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Priority]  DEFAULT ((0)) FOR [Priority]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Username]  DEFAULT ('') FOR [Username]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Password]  DEFAULT ('') FOR [Password]
GO
ALTER TABLE [dbo].[Storage] ADD  CONSTRAINT [DF_Storage_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Supervisor] ADD  CONSTRAINT [DF_Supervisor_type]  DEFAULT ((0)) FOR [Type]
GO
ALTER TABLE [dbo].[Supervisor] ADD  CONSTRAINT [DF_Supervisor_IsQD]  DEFAULT ((0)) FOR [IsQD]
GO
ALTER TABLE [dbo].[Supervisor] ADD  CONSTRAINT [DF_supervisor_Validays]  DEFAULT ((30)) FOR [Validays]
GO
ALTER TABLE [dbo].[Supervisor] ADD  CONSTRAINT [DF_supervisor_ErrTimes]  DEFAULT ((0)) FOR [ErrTimes]
GO
ALTER TABLE [dbo].[Supervisor] ADD  CONSTRAINT [DF_supervisor_Locked]  DEFAULT ((0)) FOR [Locked]
GO
ALTER TABLE [dbo].[System] ADD  CONSTRAINT [DF_System_datenow]  DEFAULT ((0)) FOR [Type]
GO
ALTER TABLE [dbo].[System] ADD  CONSTRAINT [DF_System_msgid]  DEFAULT ((0)) FOR [Value]
GO
ALTER TABLE [dbo].[TaskItem] ADD  CONSTRAINT [DF_task_AgentId]  DEFAULT ((1)) FOR [AgentId]
GO
ALTER TABLE [dbo].[TaskItem] ADD  CONSTRAINT [DF_TaskItem_ExtGroupID_1]  DEFAULT ((0)) FOR [AddressGroupId]
GO
ALTER TABLE [dbo].[TaskItem] ADD  CONSTRAINT [DF_TaskItem_TrunkGroupId]  DEFAULT ((0)) FOR [TrunkGroupId]
GO
ALTER TABLE [dbo].[Trunk] ADD  CONSTRAINT [DF_Trunk_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[TrunkGroup] ADD  CONSTRAINT [DF_TrunkGroup_Billed]  DEFAULT ((0)) FOR [AutoBill]
GO
ALTER TABLE [dbo].[TrunkGroup] ADD  CONSTRAINT [DF_TrunkGroup_FtpId]  DEFAULT ((0)) FOR [FtpId]
GO
ALTER TABLE [dbo].[TrunkGroup] ADD  CONSTRAINT [DF_TrunkGroup_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[VDN] ADD  CONSTRAINT [DF_VDN_enabled]  DEFAULT ((1)) FOR [enabled]
GO
ALTER TABLE [dbo].[VoiceType] ADD  CONSTRAINT [DF_VoiceType_Enabled]  DEFAULT ((1)) FOR [Enabled]
GO
ALTER TABLE [dbo].[Agent]  WITH CHECK ADD  CONSTRAINT [FK_Agent_ACDAddress] FOREIGN KEY([Acd])
REFERENCES [dbo].[ACD] ([Acd])
GO
ALTER TABLE [dbo].[Agent] CHECK CONSTRAINT [FK_Agent_ACDAddress]
GO
ALTER TABLE [dbo].[Connection]  WITH CHECK ADD  CONSTRAINT [FK_Connection_Records] FOREIGN KEY([RecordId])
REFERENCES [dbo].[Records] ([RecordId])
GO
ALTER TABLE [dbo].[Connection] CHECK CONSTRAINT [FK_Connection_Records]
GO
ALTER TABLE [dbo].[ProjectItem]  WITH NOCHECK ADD  CONSTRAINT [FK_BillProjItem_BillProj] FOREIGN KEY([ProjId])
REFERENCES [dbo].[Project] ([ProjId])
GO
ALTER TABLE [dbo].[ProjectItem] CHECK CONSTRAINT [FK_BillProjItem_BillProj]
GO
ALTER TABLE [dbo].[ProjectItem]  WITH CHECK ADD  CONSTRAINT [FK_ProjectItem_ProjItemType] FOREIGN KEY([Type])
REFERENCES [dbo].[ProjItemType] ([Type])
GO
ALTER TABLE [dbo].[ProjectItem] CHECK CONSTRAINT [FK_ProjectItem_ProjItemType]
GO
ALTER TABLE [dbo].[Trunk]  WITH CHECK ADD  CONSTRAINT [FK_Trunk_TrunkGroup] FOREIGN KEY([TrunkGroup])
REFERENCES [dbo].[TrunkGroup] ([GroupID])
GO
ALTER TABLE [dbo].[Trunk] CHECK CONSTRAINT [FK_Trunk_TrunkGroup]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0:hold, 1:conference,2:Mute' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'RecAdditional', @level2type=N'COLUMN',@level2name=N'EventType'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'SiteType=1,RelatedID为AgentGroup.GroupId;SiteType=2,RelatedID为Agent.AgentId' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'SiteRelated', @level2type=N'COLUMN',@level2name=N'SiteType'
GO
USE [master]
GO
ALTER DATABASE [VisionLog41] SET  READ_WRITE 
GO

USE visionlog41

go

SET IDENTITY_INSERT [dbo].[Storage] ON
INSERT [dbo].[Storage] ([FtpId], [Station], [Folder], [Port], [Drive], [RealFolder], [Priority], [Username], [Password], [StorageType], [Enabled]) VALUES (0, N'CD-PC-ESBUB123', N'audio', 21, N'D', N'E:\record\', 0, N'', N'', 1, 1)
SET IDENTITY_INSERT [dbo].[Storage] OFF

SET IDENTITY_INSERT [dbo].[SiteRelated] ON
INSERT [dbo].[SiteRelated] ([ID], [SiteID], [SiteType], [RelatedID]) VALUES (403, 5, 2, N'72056')
INSERT [dbo].[SiteRelated] ([ID], [SiteID], [SiteType], [RelatedID]) VALUES (404, 5, 2, N'72058')
INSERT [dbo].[SiteRelated] ([ID], [SiteID], [SiteType], [RelatedID]) VALUES (405, 5, 2, N'72062')
INSERT [dbo].[SiteRelated] ([ID], [SiteID], [SiteType], [RelatedID]) VALUES (616, 5, 2, N'72070')
INSERT [dbo].[SiteRelated] ([ID], [SiteID], [SiteType], [RelatedID]) VALUES (619, 4, 1, N'12')
SET IDENTITY_INSERT [dbo].[SiteRelated] OFF

GO
SET IDENTITY_INSERT [dbo].[Site] ON
INSERT [dbo].[Site] ([ID], [SiteName], [Enabled]) VALUES (4, N'beijing', 1)
INSERT [dbo].[Site] ([ID], [SiteName], [Enabled]) VALUES (5, N'shanghai', 1)
SET IDENTITY_INSERT [dbo].[Site] OFF

INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (1, N'{zh:中继组,en:trunk}')
INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (2, N'{zh:分机,en:ext}')
INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (3, N'{zh:座席,en:agent}')
INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (4, N'{zh:技能组,en:acd}')
INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (5, N'{zh:语音通道,en:channel}')
INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (6, N'{zh:被叫号码,en:called}')
INSERT [dbo].[ProjItemType] ([Type], [TypeName]) VALUES (7, N'{zh:路由点,en:vdn}')

INSERT [dbo].[GroupAddress] ([GroupID], [Address]) VALUES (1, N'30926               ')

INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010000', N'task', 0, N' ', N' ', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010100', N'new', 0, N' ', N'S', 0, 0, 0, N'task.jsp', N'new', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010200', N'open', 0, N' ', N'P', 400, 90, 1, N'', N'', N' ')

INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010300', N'save', 0, N'010100,010200', N'P', 400, 90, 1, N'saveTask()', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010400', N'saveas', 0, N'010100,010200', N'P', 400, 90, 1, N'save.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010500', N'-', 0, N' ', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010600', N'tasklist', 0, N' ', N'S', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010700', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'010800', N'close', 0, N'', N' ', 0, 0, 0, N'closeSystem()', N'', N'A')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020000', N'report', 0, N' ', N' ', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020100', N'realtime', 0, N' ', N'S', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020200', N'agentstate', 0, N' ', N'S', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020300', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020400', N'history', 0, N' ', N'S', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020500', N'statistics', 0, N' ', N'S', 0, 0, 0, N'statistic.jsp', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020600', N'monitor', 0, N' ', N' ', 0, 0, 0, N'works.jsp', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020700', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020800', N'billsch', 0, N' ', N' ', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'020900', N'bill', 0, N' ', N' ', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'021000', N'records', 0, N' ', N'S', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'021100', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'021200', N'match', 0, N' ', N'S', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030000', N'setup', 0, N' ', N'S', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030100', N'password', 0, N'', N'P', 360, 220, 0, N'', N'', N'A')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030200', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030300', N'supervisor', 0, N' ', N'S', 0, 0, 0, N'supervisor_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030400', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030500', N'vdn', 0, N' ', N'S', 0, 0, 0, N'vdn_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030600', N'acd', 0, N' ', N'S', 0, 0, 0, N'acd_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030700', N'agent', 0, N' ', N'S', 0, 0, 0, N'agent_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030800', N'group', 0, N' ', N'S', 0, 0, 0, N'group_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'030900', N'station', 0, N' ', N'S', 0, 0, 0, N'station_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031000', N'storage', 0, N' ', N'S', 0, 0, 0, N'storage_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031200', N'extension', 0, N' ', N'S', 0, 0, 0, N'extension_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031300', N'extgroup', 0, N' ', N'S', 0, 0, 0, N'extgroup_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031400', N'trunkgroup', 0, N' ', N'S', 0, 0, 0, N'trunkgroup_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031500', N'trunk', 0, N' ', N'S', 0, 0, 0, N'trunk_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031600', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031700', N'filter', 0, N' ', N'P', 400, 310, 1, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031800', N'freespace', 0, N' ', N'P', 570, 320, 1, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'031900', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'032000', N'project', 0, N' ', N'S', 0, 0, 0, N'project_list.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'040000', N'system', 0, N' ', N' ', 0, 0, 0, N'', N'', N'C')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'040300', N'backup', 0, N'', N'P', 420, 350, 1, N'maintain_files.jsp', N'', N' ')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'050000', N'help', 0, N' ', N' ', 0, 0, 0, N'', N'', N'A')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'050100', N'help', 0, N'  ', N'O', 800, 600, 0, N'', N'', N'A')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'050200', N'-', 0, N'', N' ', 0, 0, 0, N'', N'', N'A')
INSERT [dbo].[MENU] ([MENU_ID], [MENU_NAME], [HAS_IMAGE], [DEPEND], [OPEN_MODE], [POP_WIDTH], [POP_HEIGHT], [SHOW_MODAL], [APPLICATION], [METHOD], [PRIVI_FLAG]) VALUES (N'050300', N'about', 0, N' ', N'P', 300, 430, 1, N'', N'', N'A')

SET IDENTITY_INSERT [dbo].[EncryKeys] ON
SET IDENTITY_INSERT [dbo].[EncryKeys] OFF

SET IDENTITY_INSERT [dbo].[Call] ON
INSERT [dbo].[Call] ([CallSeq], [RecordID], [Calling], [Called], [CallID], [Answer], [Channel], [Trunk], [Acd], [Agent], [Extension], [Vdn], [StartTime], [Seconds], [Inbound], [Outbound], [DtmfTime], [Dtmf], [UCID], [UUI]) VALUES (2636868, 0, N'15683281218', N'51356099', 10667, N'30929', N'', 18019, N'4467', N'73994', N'30929', N'4469', CAST(0x0000A66A00A2094B AS DateTime), 91, 1, 0, CAST(0x0000A66A00A2094B AS DateTime), N'', N'00001106671471859401', N'                                                                                                                                ')
SET IDENTITY_INSERT [dbo].[Call] OFF

SET IDENTITY_INSERT [dbo].[AgentGroup] ON
INSERT [dbo].[AgentGroup] ([GroupId], [GroupName], [Description], [Enabled]) VALUES (11, N'Agent group', N'', 1)
INSERT [dbo].[AgentGroup] ([GroupId], [GroupName], [Description], [Enabled]) VALUES (12, N'Agent Group 2', N'', 1)
SET IDENTITY_INSERT [dbo].[AgentGroup] OFF

INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (0, N'mp3', N'mp3', 8, 0, N'MicroSoft Wave, Compress MS8BitWAV to mp3', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (1, N'wav', N'wav', 8, 0, N'MicroSoft Wave, MS8BitWAV', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (2, N'g729a', N'g729a', 16, 4, N'G.729A 8000 bps', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (3, N'vxi', N'vxi', 16, 4, N'VXI 8000 bps', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (4, N'pcm', N'pcm', 8, 4, N'Stereo Linear PCM(no wav header), 8k8bit', 1)
--INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (5, N'g711', N'g711', 8, 4, N'G711, 8k8bit', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (7, N'g711u', N'g711u', 8, 4, N'G711u, 8k8bit', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (9, N'g711us', N'g711us', 8, 4, N'G711us, g711 stereo, 8k16bit', 1)
INSERT [dbo].[VoiceType] ([TypeId], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled]) VALUES (10, N'g711a', N'g711a', 8, 4, N'G711a, 8k8bit', 1)

