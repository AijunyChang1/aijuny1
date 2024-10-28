--exec sp_droplinkedsrvlogin ITSV, NULL;
--exec sp_dropserver  ITSV; 
exec sp_addlinkedserver   'ITSV', '', 'SQLOLEDB ','192.168.3.82'; 
exec sp_addlinkedsrvlogin  'ITSV', 'false ',NULL, 'sa', 'vxi';
select * from ITSV.vxi_ivr.dbo.survey where StartTime>'2013-7-1' and StartTime<'2013-7-31';


set IDENTITY_INSERT vxi_ivr.dbo.Survey ON
insert into vxi_ivr.dbo.Survey(surveyid,Dtmf,Calling,Called,CallID,StartTime,callstarttime) (select a.surveyid+10000000000,a.Dtmf,a.Calling,a.Called,a.CallID,a.StartTime,a.callstarttime from ITSV.vxi_ivr.dbo.survey a where a.StartTime>'2013-7-1' and a.StartTime<'2013-7-31');
set IDENTITY_INSERT vxi_ivr.dbo.Survey OFF

set IDENTITY_INSERT vxi_ivr.dbo.Survey ON
insert into vxi_ivr.dbo.Survey(surveyid,Dtmf,Calling,Called,CallID,StartTime,callstarttime) (select a.surveyid+10000000000,a.Dtmf,a.Calling,a.Called,a.CallID,a.StartTime,a.callstarttime from ITSV.vxi_ivr.dbo.survey a where a.StartTime>'2013-8-1' and a.StartTime<'2013-8-31 9');
set IDENTITY_INSERT vxi_ivr.dbo.Survey OFF

set IDENTITY_INSERT vxi_ivr.dbo.Survey ON
insert into vxi_ivr.dbo.Survey(surveyid,Dtmf,Calling,Called,CallID,StartTime,callstarttime) (select a.surveyid+10000000000,a.Dtmf,a.Calling,a.Called,a.CallID,a.StartTime,a.callstarttime from ITSV.vxi_ivr.dbo.survey a where a.StartTime like '2013-8-31 9%');
set IDENTITY_INSERT vxi_ivr.dbo.Survey OFF

select surveyid+10000000000,Dtmf,Calling,Called,CallID,StartTime,callstarttime from ITSV.vxi_ivr.dbo.survey where StartTime>'2013-7-1' and StartTime<'2013-7-31'
select Dtmf,Calling,Called,CallID,StartTime,callstarttime from vxi_ivr.dbo.survey where StartTime>'2013-7-1' and StartTime<'2013-7-31'
insert into vxi_ivr.dbo.Survey(Dtmf,Calling,Called,CallID,StartTime,callstarttime) (select a.Dtmf,a.Calling,a.Called,a.CallID,a.StartTime,a.callstarttime from ITSV.vxi_ivr.dbo.survey a where a.StartTime>'2013-7-1' and a.StartTime<'2013-7-31'); 

select * from vxi_ivr.dbo.survey where StartTime>'2013-9-1' order by StartTime desc;

set IDENTITY_INSERT vxi_ivr.dbo.Survey ON
insert into vxi_ivr.dbo.Survey(surveyid,Dtmf,Calling,Called,CallID,StartTime,callstarttime) (select a.surveyid+10000000000,a.Dtmf,a.Calling,a.Called,a.CallID,a.StartTime,a.callstarttime from ITSV.vxi_ivr.dbo.survey a where a.StartTime like '2013-8-31 9%');
set IDENTITY_INSERT vxi_ivr.dbo.Survey OFF

select top 100 * from vxi_ivr.dbo.survey  order by StartTime desc;

select top 1000 * from vxi_rec..records order by RecordId desc