use vxi_sys
go

Delete from vxi_sys..Aux; 
INSERT INTO vxi_sys..Aux([ProjectId], [Cause], [Description], [LogFlag])  VALUES(1, 1, 'С��', 1);
INSERT INTO vxi_sys..Aux([ProjectId], [Cause], [Description], [LogFlag])  VALUES(1, 2, '{zh:��ʱС��, en:Unsched Break}', 1);
INSERT INTO vxi_sys..Aux([ProjectId], [Cause], [Description], [LogFlag])  VALUES(1, 3, '{zh:���, en:Lunch}', 0);
INSERT INTO vxi_sys..Aux([ProjectId], [Cause], [Description], [LogFlag])  VALUES(1, 4, '{zh:��ѵ, en:Recurrent Training}', 1);
INSERT INTO vxi_sys..Aux([ProjectId], [Cause], [Description], [LogFlag])  VALUES(1, 5, '{zh:�Ŷӹ���, en:Team Mtg}', 1);
INSERT INTO vxi_sys..Aux([ProjectId], [Cause], [Description], [LogFlag])  VALUES(1, 6, '{zh:ָ��, en:Super Directed}', 1);

Delete from vxi_sys..CallType; 
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_400_DOME_0', '7011', '400 Dom Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_400_DOME_1', '7011', '400 Dom Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_400_DOME_2', '7011', '400 Dom Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_400_INTL_0', '7004', '400 Intl Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_400_INTL_1', '7006', '400 Intl PU', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_400_INTL_2', '7004', '400 Intl Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_4008208388_0', '7013', 'UPS No Response', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_4008208388_9', '9006', 'English', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_800_INTL_0', '7013', 'UPS No Response', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_800_INTL_1', '7006', '800 Intl PU', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_800_INTL_2', '7004', '800 Intl Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_800_INTL_D', '7006', '800 Intl PU', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_8008208388_0', '7013', 'UPS No Response', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7004_0', '7004', '800 Intl Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7004_1', '7004', '800 Intl Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7004_2', '7004', '800 Intl Uni', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7006_0', '7006', '800 Intl PU', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7006_1', '7006', '800 Intl PU', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7006_2', '7006', '800 Intl PU', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7013_0', '7013', 'UPS No Response', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7013_1', '7013', 'UPS No Response', 1);
INSERT INTO vxi_sys..CallType([App_Input], [CallType], [CallTypeDesc], [Enabled])  VALUES('UPS_Busy_7013_2', '7013', 'UPS No Response', 1);

Delete from vxi_sys..ChType; 
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(1, 'IVR');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(2, 'VRS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(4, 'PDS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(16, 'IVR');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(17, 'IVR-Trunk');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(18, 'IVR-Conf');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(19, 'IVR-Ext');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(20, 'IVR-IP');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(21, 'IVR-SIP');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(32, 'VRS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(33, 'VRS-Trunk');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(34, 'VRS-Conf');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(35, 'VRS-Ext');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(36, 'VRS-IP');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(64, 'PDS');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(65, 'PDS-Trunk');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(66, 'PDS-Conf');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(67, 'PDS-Ext');
INSERT INTO vxi_sys..ChType([ChType], [TypeName])  VALUES(68, 'PDS-IP');

 
Delete from vxi_sys..DevType; 
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(18, '{en:Agent Group,zh:��ϯ��}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(2, '{en:Agent,zh:��ϯ}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(7, '{en:Audio,zh:��Ƶ}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(25, '{en:Chat Skill,zh:��ҳ���켼��}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(8, '{en:CTI Port, zh:ý���豸}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(35, '{en:Custom Skill,zh:�Զ��弼��}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(19, '{en:DevSkill,zh:�豸����}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(17, '{en:Extension Group,zh:�ֻ���}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(1, '{en:Extension,zh:�ֻ�}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(6, '{en:External,zh:����}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(23, '{en:Mail Skill,zh:�ʼ�����}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(22, '{en:QQ Skill,zh:QQ����}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(4, '{en:Route,zh:·��}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(3, '{en:Skill,zh:��ͨ����}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(24, '{en:SMS Skill,zh:���ż���}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(21, '{en:Trunk Group,zh:�м���}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(5, '{en:Trunk,zh:�м�}');
INSERT INTO vxi_sys..DevType([DevType], [TypeName])  VALUES(0, 'Unknown');

Delete from vxi_sys..GroupType; 
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(1, '{en:Agent Group,zh:��ϯ��}');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(2, '{en:Extension Group,zh:�ֻ���}');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(3, '{en:Channel Group,zh:ͨ����}');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(4, '{en:Trunk Group,zh:�м���}');
INSERT INTO vxi_sys..GroupType([GroupType], [TypeName])  VALUES(5, '{en:Station Group,zh:�������}');

Delete from vxi_sys..Posts; 
INSERT INTO vxi_sys..Posts([Post], [PostName], [Description], [bAnswer], [Enabled])  VALUES(0, '{en:Part Time;zh:��ְ����Ա}', '', 1, 0);
INSERT INTO vxi_sys..Posts([Post], [PostName], [Description], [bAnswer], [Enabled])  VALUES(1, '{en:Full Time;zh:ȫְ����Ա}', '', 1, 1);
INSERT INTO vxi_sys..Posts([Post], [PostName], [Description], [bAnswer], [Enabled])  VALUES(2, '{en:Team Leader;zh:�鳤}', '', null, 1);
INSERT INTO vxi_sys..Posts([Post], [PostName], [Description], [bAnswer], [Enabled])  VALUES(3, '{en:Coordination;zh:ҵ����Ա}', '', null, 0);
INSERT INTO vxi_sys..Posts([Post], [PostName], [Description], [bAnswer], [Enabled])  VALUES(4, '{en:Trainer;zh:��ѵʦ}', '', null, 0);
INSERT INTO vxi_sys..Posts([Post], [PostName], [Description], [bAnswer], [Enabled])  VALUES(5, '{en:Manager/Supervisor;zh:��Ŀ����/����}', '', null, 1);

Delete from vxi_sys..PrjItemType; 
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(1, '{en:Agent,zh:��ϯ}');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(2, '{en:Extension,zh:�ֻ�}');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(3, '{en:Skill,zh:����}');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(4, '{en:Route,zh:·��}');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(5, '{en:Trunk Group,zh:�м���}');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(6, '{en:Calling No.,zh:�������}');
INSERT INTO vxi_sys..PrjItemType([Type], [TypeName])  VALUES(7, '{en:Called No.,zh:��������}');
  
Delete from vxi_sys..SelStratDef; 
INSERT INTO vxi_sys..SelStratDef([Strategy], [Name], [Description])  VALUES(1, '{en:Longest Wait Time;zh:��ȴ�ʱ��}', '��ȴ�ʱ��ѡ�����');
INSERT INTO vxi_sys..SelStratDef([Strategy], [Name], [Description])  VALUES(2, '{en:Random ;zh:���ѡ�����}', '���ѡ�����');
  
Delete from vxi_sys..VoiceType; 
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(1, 'VCE', 'vce', 16, 0, 'VCE File, .vce', 0);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(2, 'VOX', 'vox', 16, 0, 'VOX File, .vox', 0);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(3, 'MP3', 'mp3', 8, 0, 'MP3 File, mp3', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(4, 'WAV', 'wav', 8, 0, 'WAV File, .wav', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(5, 'G729A', 'g729a', 16, 4, 'G729A File, .g729a', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(6, 'VXI', 'vxi', 16, 4, 'VXI Compress File, .vxi', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(7, 'G711U', 'g711', 8, 0, 'G711U  File, .g711', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(8, 'G729', 'g729', 8, 0, 'G729  File, .g729', 1);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(10, 'ALAW', 'alaw', 8, 0, 'ALAW  File, .alaw', 0);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(20, 'g723', 'g723', 16, 0, 'G723 File, .g723', 0);
INSERT INTO vxi_sys..VoiceType([VoiceType], [TypeName], [Ext], [Wavbit], [Code], [Description], [Enabled])  VALUES(30, 'g726', 'g726', 16, 0, 'G726 File, .g726', 0);


use vxi_ivr
go 

Delete from vxi_ivr..FaxCategory; 
INSERT INTO vxi_ivr..FaxCategory([CategoryID], [CategoryName])  VALUES(6, 'abc');

  
Delete from vxi_ivr..FaxLevel; 
INSERT INTO vxi_ivr..FaxLevel([LevelID], [TryTimes], [LevelDesc])  VALUES(1, 2, 'normal');
INSERT INTO vxi_ivr..FaxLevel([LevelID], [TryTimes], [LevelDesc])  VALUES(2, 3, 'important');
INSERT INTO vxi_ivr..FaxLevel([LevelID], [TryTimes], [LevelDesc])  VALUES(3, 5, 'very important');
 
Delete from vxi_ivr..FaxReason; 
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(0, 'Normal', '����');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(1, 'Invalid Time Range', '�Ƿ�ʱ�䷶Χ(����Ԥ������ʱ��)');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(2, 'Overrun Max Trytimes', '��������ʹ���');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(3, 'No Local FAX File', '����FAX�ļ�δ�ҵ�');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(4, 'Conver Fail', 'ת��TIFʧ�ܣ���ʱ');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(5, 'Printer Fail', '��ӡ������ʧ��');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(6, 'No Local TIF File', '���ؽ���TIF�ļ�δ�ҵ�');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(7, 'Conver Dest Format Fail', 'ת��ΪĿ���ļ���ʽʧ��');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(101, 'CFR_NO_DIAL_TONE', 'û�в�����');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(102, 'CFR_INVALID_DNIS', '�Ƿ�����');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(103, 'CFR_RMT_BUSY', 'Զ��æ');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(104, 'CFR_TIMEOUT', '��ʱ');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(105, 'CFR_NO_ANSWER', '��Ӧ��');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(106, 'CFR_TRUNK_BUSY', '�м�æ');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(107, 'CFR_ERROR', '����');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(108, 'CFR_RMT_RELEASED', 'Զ���ͷ�');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(109, 'CFR_RELEASED', '�����ͷ�');
INSERT INTO vxi_ivr..FaxReason([Reason], [ReasonKey], [ReasonDesc])  VALUES(110, 'CFR_NO_AVALABLE', '������');
  
Delete from vxi_ivr..FaxStatus; 
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(1, 'Send_Fax', '�����ʹ���');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(2, 'Send_Sending', '���ʹ�����');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(3, 'Send_Fail', '���ʹ���ʧ��');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(4, 'Send_Success', '���ʹ���ɹ�');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(5, 'Send_Final_Success', '���ʹ������ճɹ�');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(6, 'Send_Final_Fail', '���ʹ�������ʧ��');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(11, 'Recv_New', '���յ�����');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(12, 'Recv_Notify', '�Ѿ�֪ͨ����');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(13, 'Recv_Final_Success', '���մ������ճɹ�');
INSERT INTO vxi_ivr..FaxStatus([Status], [StatusKey], [StatusDesc])  VALUES(14, 'Recv_Final_Fail', '���մ�������ʧ��');

  
Delete from vxi_ivr..IvrFlow; 
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(1, 'testflow', 'testflow');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(2, 'testflow1', 'testflow1');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(3, 'testflow2', 'testflow2');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(4, 'testflow3', 'testflow3');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(5, 'flow_ivr', 'flow_ivr');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(6, 'flow_ivr_out', 'flow_ivr_out');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(7, 'flowsendmsg', 'flowsendmsg');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(8, 'CD12333Project_V1.1', 'CD12333Project_V1.1');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(9, 'CD12333Project_V1.2', 'CD12333Project_V1.2');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(10, 'IVRExperience', 'IVRExperience');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(11, 'IVRe', 'IVRe');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(12, 'IVR_Demo', 'IVR_Demo');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(13, 'userflow', 'userflow');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(14, 'test', 'test');
INSERT INTO vxi_ivr..IvrFlow([FlowId], [FlowName], [FlowFile])  VALUES(15, 'siptest', 'siptest');


Delete from vxi_ivr..IvrNodeResult; 
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(0, 'NORMAL', '�ڵ���������');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(2, 'TERM_DTMF', '�û���������ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(3, 'TERM_MAX_DIGITS', '��󰴼�����ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(4, 'TERM_END_DIGIT', '��ֹ����ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(5, 'TERM_STOPPED', '����ֹͣ��ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(6, 'TERM_RMT_RELEASED', 'Զ�˹һ���ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(7, 'TERM_TIMEOUT', '��ʱ��ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(8, 'TERM_MAX_TIME', '�������ʱ����ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(9, 'TERM_MAX_SILENCE', '���������ʱ����ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(10, 'TERM_ERROR', '����������ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(11, 'TERM_RELEASED', '�����ͷŵ�����ֹ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(101, 'CFR_NO_DIAL_TONE', 'û�в�����');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(102, 'CFR_INVALID_DNIS', '�Ƿ�����');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(103, 'CFR_RMT_BUSY', 'Զ��æ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(104, 'CFR_TIMEOUT', '��ʱ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(105, 'CFR_NO_ANSWER', '��Ӧ��');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(106, 'CFR_TRUNK_BUSY', '�м�æ');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(107, 'CFR_ERROR', '����');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(108, 'CFR_RMT_RELEASED', 'Զ���ͷ�');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(109, 'CFR_RELEASED', '�����ͷ�');
INSERT INTO vxi_ivr..IvrNodeResult([Result], [Descript], [Remark])  VALUES(110, 'CFR_NO_AVALABLE', '������');

Delete from vxi_ivr..IvrNodeType; 
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '0', 'WaitingCall');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '1', 'AnswerCallPC');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '2', 'PlayFile');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '3', 'GetDigits');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '4', 'PlayDigits');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '5', 'PlayFile');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '6', 'SipBridge');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '7', 'PlayFile');
INSERT INTO vxi_ivr..IvrNodeType([FlowId], [NodeName], [NodeType])  VALUES(15, '8', 'PlayFile');
  
Delete from vxi_ivr..SurveyResult; 
INSERT INTO vxi_ivr..SurveyResult([ResultID], [OrderId], [Description])  VALUES(1, 1, '����');
INSERT INTO vxi_ivr..SurveyResult([ResultID], [OrderId], [Description])  VALUES(2, 2, 'һ��');
INSERT INTO vxi_ivr..SurveyResult([ResultID], [OrderId], [Description])  VALUES(3, 3, '������');
  
Delete from vxi_ivr..VoiceStatus; 
INSERT INTO vxi_ivr..VoiceStatus([StatusID], [Description])  VALUES(1, '������');
INSERT INTO vxi_ivr..VoiceStatus([StatusID], [Description])  VALUES(2, '��������');
INSERT INTO vxi_ivr..VoiceStatus([StatusID], [Description])  VALUES(3, '��ɾ��');

use vxi_rec
go 
  
Delete from vxi_rec..StoreType; 
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(1, 'VRS');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(2, 'TRS');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(3, 'VRS & TRS');
INSERT INTO vxi_rec..StoreType([StoreType], [TypeName])  VALUES(8, 'Backup');

Delete from vxi_rec..TaskType; 
INSERT INTO vxi_rec..TaskType([TaskType], [TypeName])  VALUES(1, '��������');
INSERT INTO vxi_rec..TaskType([TaskType], [TypeName])  VALUES(2, 'ÿ������');
INSERT INTO vxi_rec..TaskType([TaskType], [TypeName])  VALUES(3, 'ÿ������');
INSERT INTO vxi_rec..TaskType([TaskType], [TypeName])  VALUES(4, 'ÿ������');

Delete from vxi_rec..VideoType; 
INSERT INTO vxi_rec..VideoType([VideoType], [Description])  VALUES(0, 'Screen capture picture');
INSERT INTO vxi_rec..VideoType([VideoType], [Description])  VALUES(1, 'Screen capture avi');


use vxi_ucd
go  
Delete from vxi_ucd..stat_param; 

use vxi_chat
go
delete from vxi_chat..SurveyResult;
INSERT INTO vxi_chat..SurveyResult([ResultID], [OrderId], [Description], [Score])  VALUES(1, 1, '�ǳ�����', 5);
INSERT INTO vxi_chat..SurveyResult([ResultID], [OrderId], [Description], [Score])  VALUES(2, 2, '����', 4);
INSERT INTO vxi_chat..SurveyResult([ResultID], [OrderId], [Description], [Score])  VALUES(3, 3, 'һ��', 3);
INSERT INTO vxi_chat..SurveyResult([ResultID], [OrderId], [Description], [Score])  VALUES(4, 4, '������', 2);
INSERT INTO vxi_chat..SurveyResult([ResultID], [OrderId], [Description], [Score])  VALUES(5, 5, '�ǳ�������', 1);





