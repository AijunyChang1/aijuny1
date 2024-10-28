USE [VisionLog41]
GO
insert into [dbo].[ETL_LOG]([MinLsn],[FromTB],[ToTB],[MaxLsn],[MinTmStamp],[MaxTmStamp])
Select 0,'Records','RecordsEvtCaculate',0,cast(max(tmstamp) as bigint) ,0 from dbo.records

select * from [dbo].[ETL_LOG]