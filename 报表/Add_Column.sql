use vxi_rec
GO


ALTER table dbo.Records ALTER COLUMN UCID varchar(50)

--ALTER table dbo.Records DROP COLUMN FileCount
--ALTER table dbo.Records DROP COLUMN DataEncry
--ALTER table dbo.Records DROP COLUMN Mark

ALTER table dbo.Records ADD FileCount smallint
ALTER table dbo.Records ADD DataEncry bit
ALTER table dbo.Records ADD Mark varchar(10)
ALTER table dbo.Records ADD AssRec bigint
ALTER table dbo.Records ADD Established bit
GO

use vxi_sys
CREATE TABLE [dbo].[CallType](
	[App_Input] [varchar](50) NOT NULL,
	[CallType] [varchar](20) NOT NULL,
	[CallTypeDesc] [varchar](50) NULL,
	[Enabled] [bit] NOT NULL,
 CONSTRAINT [PK_CallType] PRIMARY KEY CLUSTERED 
(
	[App_Input] ASC,
	[CallType] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

INSERT INTO [vxi_sys].[dbo].[CallType]
           ([App_Input]
           ,[CallType]
           ,[CallTypeDesc]
           ,[Enabled])
     VALUES
           ('UPS_400_DOME_0'
           ,'7011'
           ,'400 Dom Uni'
           ,1)
GO

INSERT INTO [vxi_sys].[dbo].[CallType]
           ([App_Input]
           ,[CallType]
           ,[CallTypeDesc]
           ,[Enabled])
     VALUES
           ('UPS_400_DOME_1'
           ,'7011'
           ,'400 Dom Uni'
           ,1)
GO
----------------------------------------------------------------------------------------
USE [vxi_sys]
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[SelStratDef](
	[Strategy] [int] NOT NULL,
	[Name] [varchar](60) COLLATE Chinese_PRC_CI_AS NOT NULL,
	[Description] [varchar](200) COLLATE Chinese_PRC_CI_AS NULL,
 CONSTRAINT [PK_SelStratDef] PRIMARY KEY CLUSTERED 
(
	[Strategy] ASC
)WITH (IGNORE_DUP_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF

INSERT INTO [vxi_sys].[dbo].[SelStratDef]
           ([Strategy]
           ,[Name]
           ,[Description])
     VALUES
           (1,'{en:Longest Wait Time;zh:最长等待时间}','最长等待时间选择策略');

INSERT INTO [vxi_sys].[dbo].[SelStratDef]
           ([Strategy]
           ,[Name]
           ,[Description])
     VALUES
           (2,'{en:Random ;zh:随机选择策略}','随机选择策略');