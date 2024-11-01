USE [master]
GO
CREATE DATABASE [vxi_pds]
GO


USE [vxi_pds]
GO
/****** Object:  StoredProcedure [dbo].[usp_pds_get_calloutdata]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[usp_pds_get_calloutdata] 
	@outparam1 varchar(25)='' output,
	@outparam2 varchar(20)='' output,
	@outparam3 varchar(10)='' output,
	@outparam4 varchar(10)='' output
AS
	declare @calloutidlen int
	set @calloutidlen=0
	select top 1 @outparam1=calloutid,@outparam2=calloutphone,@outparam3=vdninfo from v_calloutinfo where state=0 order by timeinsert
	set @calloutidlen =len(@outparam1)
	if @calloutidlen > 5
		begin
		update currentcallinfo set state=1 where calloutid=@outparam1
		set @outparam4=1
		end
	else
		begin
		set @outparam4='0'
		set @outparam1='1111'
		set @outparam2='1111'
		set @outparam3='1111'
		end







GO
/****** Object:  StoredProcedure [dbo].[usp_pds_get_calloutid]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_pds_get_calloutid] 
    
AS
BEGIN
	DECLARE @NEW_ID VARCHAR(25)
    DECLARE @TIME_ID VARCHAR(15)
	SET @TIME_ID = CONVERT(VARCHAR(8),GETDATE(),112) + replace(CONVERT(VARCHAR(8),GETDATE(),108),':','')
	PRINT @TIME_ID

    --取出表中当前日期的已有的最大ID
    SET @NEW_ID = NULL
    SELECT TOP 1 @NEW_ID = calloutid FROM vxi_pds..calloutdata WHERE calloutid LIKE @TIME_ID+'%' ORDER BY calloutid DESC
    
    --如果未取出来
    IF @NEW_ID IS NULL
        --说明还没有当前日期的编号，则直接从1开始编号
        SET @NEW_ID = (@TIME_ID+'00000001')
    --如果取出来了
    ELSE
    BEGIN
        DECLARE @NUM VARCHAR(7)
        --取出最大的编号加上1
        SET @NUM = CONVERT(VARCHAR, (CONVERT(INT, RIGHT(@NEW_ID, 7)) + 1))
        --因为经过类型转换，丢失了高位的0，需要补上
        SET @NUM = REPLICATE('0', 7 - LEN(@NUM)) + @NUM
        --最后返回日期加编号
        SET @NEW_ID = @TIME_ID + @NUM
    END
    select @NEW_ID as newid
END


GO
/****** Object:  StoredProcedure [dbo].[usp_pds_handler_callout]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROCEDURE [dbo].[usp_pds_handler_callout] 
	@inparam1 int=0,
	@inparam2 int=0,
	@inparam3 varchar(10)='',
	@outparam1 int=0 output		
AS
	set @outparam1=0
	
	declare @count int
	declare @callnumber int	
	declare @number int
	declare @callout_id varchar(32)
	declare @callout_phone varchar(32)
	set @number=0
    delete from dbo.currentcallinfo where calloutid in (select calloutid  FROM dbo.callresult where datediff(ss,logtime,getdate()) >=300)
	select  @count=count(calloutid) from currentcallinfo where projectid = @inparam1
	if @count<@inparam2
		begin
			set @callnumber = @inparam2-@count
			while @callnumber > @number
				begin
					set @callout_id=''
					select top 1 @callout_id=calloutid,@callout_phone=calloutphone from calloutdata where projectid=@inparam1 or projectid =0 order by calloutid
					if @callout_id = ''
						break
					insert into callresult(calloutid,calloutphone,skillinfo) values(@callout_id,@callout_phone,@inparam3)
					insert into currentcallinfo(calloutid,projectid) values(@callout_id,@inparam1)
					delete calloutdata where calloutid = @callout_id
					set @number=@number+1
				end 
			set @outparam1=@number
		end
	else
		begin
			set @outparam1=0
		end
	print @outparam1





GO
/****** Object:  StoredProcedure [dbo].[usp_pds_update_callstate]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[usp_pds_update_callstate] 
	@inparam1 varchar(25)='',
	@inparam2 varchar(25)='',
	@outparam1 varchar(25)='' output	
AS
	update callresult set state=@inparam2 where calloutid=@inparam1
	delete currentcallinfo where calloutid=@inparam1
	set @outparam1='0'


GO
/****** Object:  Table [dbo].[calloutdata]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[calloutdata](
	[calloutid] [varchar](25) NOT NULL,
	[calloutphone] [varchar](20) NOT NULL,
	[projectid] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[callresult]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[callresult](
	[calloutid] [varchar](25) NOT NULL,
	[calloutphone] [varchar](20) NOT NULL,
	[skillinfo] [varchar](10) NOT NULL,
	[state] [int] NOT NULL,
	[logtime] [datetime] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[currentcallinfo]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[currentcallinfo](
	[calloutid] [varchar](25) NOT NULL,
	[state] [int] NOT NULL,
	[projectid] [int] NOT NULL,
	[timeinsert] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[project]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[project](
	[projectid] [int] NOT NULL,
	[projectname] [varchar](50) NOT NULL,
	[skillinfo] [varchar](10) NOT NULL,
	[startflag] [bit] NOT NULL,
	[callfactor] [float] NOT NULL,
	[startworktime] [varchar](10) NULL,
	[endworktime] [varchar](10) NULL,
	[enabled] [bit] NOT NULL,
	[vdninfo] [varchar](10) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[v_calloutinfo]    Script Date: 2016/9/6 13:50:20 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  View [dbo].[v_calloutinfo]    Script Date: 07/24/2014 11:49:23 ******/
CREATE VIEW [dbo].[v_calloutinfo]
AS
SELECT     a.calloutid, a.state, a.projectid, b.calloutphone, c.skillinfo, c.vdninfo, a.timeinsert
FROM         dbo.currentcallinfo AS a INNER JOIN
                      dbo.callresult AS b ON a.calloutid = b.calloutid INNER JOIN
                      dbo.project AS c ON a.projectid = c.projectid

GO
ALTER TABLE [dbo].[calloutdata] ADD  CONSTRAINT [DF_calloutdata_projectid]  DEFAULT ((0)) FOR [projectid]
GO
ALTER TABLE [dbo].[callresult] ADD  CONSTRAINT [DF_callresult_state]  DEFAULT ((0)) FOR [state]
GO
ALTER TABLE [dbo].[callresult] ADD  CONSTRAINT [DF_callresult_logtime]  DEFAULT (getdate()) FOR [logtime]
GO
ALTER TABLE [dbo].[currentcallinfo] ADD  CONSTRAINT [DF_currentcallinfo_state]  DEFAULT ((0)) FOR [state]
GO
ALTER TABLE [dbo].[currentcallinfo] ADD  CONSTRAINT [DF_currentcallinfo_timeinsert]  DEFAULT (getdate()) FOR [timeinsert]
GO
ALTER TABLE [dbo].[project] ADD  CONSTRAINT [DF_project_enabled]  DEFAULT ((1)) FOR [enabled]
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[41] 4[14] 2[27] 3) )"
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
         Begin Table = "a"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 106
               Right = 190
            End
            DisplayFlags = 280
            TopColumn = 1
         End
         Begin Table = "b"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 114
               Right = 184
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "c"
            Begin Extent = 
               Top = 6
               Left = 222
               Bottom = 99
               Right = 352
            End
            DisplayFlags = 280
            TopColumn = 7
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
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_calloutinfo'
GO
EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'v_calloutinfo'
GO
