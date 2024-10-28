#include "stdafx.h"
#include <iostream>
#include "sockclient.h"
#include <string> 
#include "func.h"

using namespace std;

#ifdef MQTT
#include "make_mqtt.h"
#endif

#ifdef BOTDA
#include "make_botda.h"
#endif

SockClient::SockClient(const char *remote_ip, int portn, const char *local_ip):m_remote_port(portn)
{
	sprintf(m_remote_ip,remote_ip);
	sprintf(m_local_ip, local_ip);
	m_connected = false;
	msg_queue = NULL;
	InitializeCriticalSection(&m_cs);
    m_wVersionRequested = MAKEWORD( 1, 1 );
  
    m_err = WSAStartup( m_wVersionRequested , &m_wsaData );
	if ( m_err != 0 ) 
    {
	   printf("Initianize socket failed!\n");
       return;
    }

    if ((LOBYTE( m_wsaData.wVersion) != 1) || (HIBYTE(m_wsaData.wVersion) != 1 ) )
    {
       WSACleanup( );
       return;
    }

	m_sockettcp = socket(AF_INET,SOCK_STREAM,0);
	if (m_sockettcp<0)
	{
	    printf("Can not create socket!\n");
		m_connected=false;
	}

	m_destinationSockAddr.sin_family = AF_INET;
    m_destinationSockAddr.sin_addr.s_addr = inet_addr(m_remote_ip);
    m_destinationSockAddr.sin_port = htons(m_remote_port);
	m_sendinghb = false;
	m_send_len=0;
	m_remain_len = 0;
	memset(m_send_buf,0,BUF_SIZE);

}


SockClient::~SockClient()
{

    closesocket(m_sockettcp);
    Sleep(35);

}

int SockClient::ConnectTo()
{
	char w_log[200];
	if (m_sockettcp<0)
	{
	    m_sockettcp = socket(AF_INET,SOCK_STREAM,0);
	}
	if (m_sockettcp<0)
    {
	    write_log("Can not create socket!!!!!!!!\n");
		m_connected = false;
		return -1;
	}

	if (connect(m_sockettcp,(SOCKADDR*)&m_destinationSockAddr,sizeof(SOCKADDR))<0)		  
    {
		write_log("Socket connect to server failed!!!!!!!!!!\n");
	    OutputDebugString(TEXT("SockClient Connect fail...!!!!!!!!!!!!!!!!!!!!!!!!!\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
		m_connected = false;
		return -1;
	}
    m_connected = true;
	DWORD targetThreadID;
	HANDLE HCliThread;                          		
    HCliThread=CreateThread(NULL,0,CliListenThread,this,0,&targetThreadID);
	CloseHandle(HCliThread);

	DWORD targetThreadID1;
	HANDLE HQueueThread;                          		
    HQueueThread=CreateThread(NULL,0,HandleQueue,this,0,&targetThreadID1);
	CloseHandle(HQueueThread);

	return 0;
} 

int SockClient::CloseSocket()
{
    closesocket(m_sockettcp);
    return 0;
}


void SockClient::clean_send_buf()
{
	memset(m_send_buf,0,BUF_SIZE);
	m_send_len = 0;
}
void SockClient::Send()
{
    DWORD targetThreadID;
	HANDLE  HCallThread;
	HCallThread = CreateThread(NULL,0,SendThread,this,0,&targetThreadID);

    Sleep(500);
	CloseHandle(HCallThread);

}

DWORD WINAPI SockClient::SendThread(LPVOID Param)
{
    SockClient *udp_client = NULL;
	udp_client = (SockClient*)Param;
 	if (udp_client == NULL) return -1;

	udp_client->SendData(udp_client);
}


DWORD WINAPI SockClient::SendData(LPVOID Param)
{
	
	if (Param==NULL) return -1;
    SockClient *udp_client = NULL;
	udp_client = (SockClient*)Param;
	if (udp_client->m_send_buf==0) return -1;
	if (udp_client->m_send_buf==0) return -1;
	send(udp_client->m_sockettcp ,(const char*)udp_client->m_send_buf,udp_client->m_send_len,0);
	/*
	if((lparam==NULL)||(lparam->sock==NULL)||(lparam->sock_add==NULL)||(lparam->buf==NULL))
	{
	    return -1;
	}
	sendto(*(lparam->sock),(char*)lparam->buf->buffer,172,0, (sockaddr*)(lparam->sock_add),sizeof(sockaddr_in));
	*/
	return -1;
	
}

DWORD WINAPI SockClient::CliListenThread(LPVOID Param)
{
	SockClient*P =(SockClient*)Param;
	unsigned char MessageBuf[200000];
	unsigned char* MessageBufp;
	unsigned char temp[BUF_SIZE];
	//char temp2[1500];
	int iLen;
	unsigned char* point;
	unsigned char MsgName[100];
	char w_log[BUF_SIZE];
	DWORD targetThreadID;
	HANDLE HCliReThread;
	static bool ifsend=false;

	while(1)
	{
		//OutputDebugString(TEXT("CliListenThread loop1...\n==========\n"));
        //sprintf(w_log, "Receiving msg...");
		//write_log(w_log);
		iLen=recv(P->m_sockettcp,(char*)MessageBuf,BUF_SIZE-1,0);
		if ((iLen<0)||(iLen==0))
		{                              
			 closesocket(P->m_sockettcp);
               		
			 sprintf(w_log, "SocketDisconnected!!!\n");
			 write_log(w_log);
			 OutputDebugStringA(w_log);
			 P->m_sockettcp=socket(AF_INET,SOCK_STREAM,0);
			                             
			 Sleep(500);
			//  MessageBoxA(NULL,"Can not connect1!","Alert",1);
			 if (connect(P->m_sockettcp,(SOCKADDR*)&(P->m_destinationSockAddr),sizeof(SOCKADDR))<0)
	         {
                  closesocket(P->m_sockettcp);
				  P->m_sockettcp=socket(AF_INET,SOCK_STREAM,0);

				  //////////////////////////////////////////////////////////
				
				  if (connect(P->m_sockettcp,(SOCKADDR*)&(P->m_destinationSockAddr),sizeof(SOCKADDR))<0)
				  {
					  closesocket(P->m_sockettcp);
					  P->m_sockettcp=socket(AF_INET,SOCK_STREAM,0);
					  connect(P->m_sockettcp,(SOCKADDR*)&(P->m_destinationSockAddr),sizeof(SOCKADDR));
					  P->m_connected=false;
					  write_log("Socket reconnected failed, wait a moment and try again......\n");
					  OutputDebugString(TEXT("CliListenThread Exit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!...\n!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
					  Sleep(5000);
					  continue;
					  //return 0;
				  }		            			
             
	         }
#ifdef MQTT
			 int msg_len=0;
	         P->clean_send_buf();
			 make_connect_request_msg(&(P->m_send_buf[0]),msg_len, &(P->m_local_ip[0]));
			 P->m_send_len = msg_len;
	         P->Send();
			 write_log("Send mqtt connect reguest...Done");

             P->clean_send_buf();
			 make_unsuscribe_request_msg(&(P->m_send_buf[0]),msg_len, "DFVS/Channel/Alarm");
			 P->m_send_len = msg_len;
			 P->Send();
			 write_log("Send mqtt unsuscribe reguest: DFVS/Channel/Alarm ...Done");

			 P->clean_send_buf();
			 make_unsuscribe_request_msg(&(P->m_send_buf[0]),msg_len, "DFVS/Channel/Fiber");
			 P->m_send_len = msg_len;
			 P->Send();
			 write_log("Send mqtt unsuscribe reguest: DFVS/Channel/Fiber ...Done");

			 Sleep(50);
	         P->clean_send_buf();
	         make_suscribe_request_msg(&(P->m_send_buf[0]),msg_len, "DFVS/Channel/Alarm");			 
	         P->m_send_len = msg_len;
	         P->Send();
			 write_log("Send mqtt suscribe reguest: DFVS/Channel/Alarm ...Done");

			 P->clean_send_buf();
	         make_suscribe_request_msg(&(P->m_send_buf[0]),msg_len, "DFVS/Channel/Fiber");			 
	         P->m_send_len = msg_len;
	         P->Send();
			 write_log("Send mqtt suscribe reguest: DFVS/Channel/Fiber ...Done");
#endif

		     if(P->m_sendinghb==false)
			 {
			     P->start_send_heartbeat();	
			 }
			 continue;

		}

		P->m_connected = true;
		if (iLen>600)
		{
		    OutputDebugString(TEXT("Multiple msg package!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!...\n!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
			write_log("Received a multiple msg package!");
		}
		unsigned char temp_msg[BUF_SIZE];
		unsigned char * tmp_ptr = &temp_msg[0];
		if (P->m_remain_len>0)
		{
			memcpy(tmp_ptr, P->m_remain_msg, P->m_remain_len);
			tmp_ptr= tmp_ptr + P->m_remain_len;
			memset(P->m_remain_msg, 0, sizeof(P->m_remain_msg));
			//P->m_remain_len = 0;
		}
		memcpy(tmp_ptr, MessageBuf, iLen);
		iLen = iLen + P->m_remain_len;
		P->m_remain_len = 0;
		memset(temp, 0, BUF_SIZE);
		memset(MsgName,0,sizeof(MsgName));
		int has_error;
		int topic_len;
		int jason_len;
		char w_log[BUF_SIZE];
#ifdef MQTT
		unsigned char * msg_ptr = &temp_msg[0];
		do
		{
			memset(MsgName, 0, sizeof(MsgName));
			memset(temp, 0, sizeof(temp));
		    has_error = parse_mqtt_msg(&msg_ptr, iLen, (unsigned char*)MsgName, (unsigned char*)temp); 
			if (has_error==1)
			{
				memcpy(P->m_remain_msg, msg_ptr, iLen);
				P->m_remain_len = iLen;
				continue;
			}
		    if (!has_error)
		    {
		        topic_len = strlen((char*)MsgName);
			    jason_len = strlen((char*)temp);
			    if ((topic_len>0) && (jason_len>0))
			    {
					sprintf(w_log, "Parsed a message, topic: %s", MsgName);
					write_log(w_log);
					sprintf(w_log, "Parsed a message, Jason: %s", temp);
					write_log(w_log);
			        QueueElem* new_elem = new QueueElem;
				    new_elem->msg_topic = (char*)MsgName;
				    new_elem->msg_jason = (char*)temp;
				    new_elem->next = NULL;

				    EnterCriticalSection(&P->m_cs);

				   if (P->msg_queue==NULL)
				   {
				       new_elem->pre=NULL;
					   P->msg_queue = new_elem;
					   P->last_ptr = new_elem;
				   }
				   else
				   {
				       new_elem->pre = P->last_ptr;
					   P->last_ptr->next = new_elem;
					   P->last_ptr = new_elem;
				   }
				   LeaveCriticalSection(&P->m_cs);

			   }
		    }
		} while ((iLen>0)&&(strlen((char *)MsgName)>0));
#endif

#ifdef BOTDA
		unsigned char * msg_ptr = &temp_msg[0];
		do
		{
		    memset(MsgName, 0, sizeof(MsgName));
		    memset(temp, 0, sizeof(temp));
		    has_error = parse_botda_msg(&msg_ptr, iLen, (unsigned char*)MsgName, (unsigned char*)temp); 
		    if (has_error==1)
		    {
			    memcpy(P->m_remain_msg, msg_ptr, iLen);
			    P->m_remain_len = iLen;
				char temp_log[50];
				sprintf(temp_log, "Write temp msg, len: %d", iLen);
				write_log(temp_log);
			    continue;
		    }

		    if (!has_error)
		    {
		        topic_len = strlen((char*)MsgName);
			    jason_len = strlen((char*)temp);
			    if ((topic_len>0) && (jason_len>0))
			    {
					sprintf(w_log, "Parsed a message, topic: %s", MsgName);
					write_log(w_log);
					sprintf(w_log, "Parsed a message, Jason: %s", temp);
					write_log(w_log);
			        QueueElem* new_elem = new QueueElem;
				    new_elem->msg_topic = (char*)MsgName;
				    new_elem->msg_jason = (char*)temp;
				    new_elem->next = NULL;

				    EnterCriticalSection(&P->m_cs);

				   if (P->msg_queue==NULL)
				   {
				       new_elem->pre=NULL;
					   P->msg_queue = new_elem;
					  // P->last_ptr = new_elem;
				   }
				   else
				   {
				       new_elem->pre = P->last_ptr;
					   P->last_ptr->next = new_elem;
					  // P->last_ptr = new_elem;
				   }
				   P->last_ptr = new_elem;
				   LeaveCriticalSection(&P->m_cs);

			   }
		    }
		} while ((iLen>0)&&(strlen((char *)MsgName)>0));
#endif
	
	}    
	return 0;
}

#ifdef MQTT

DWORD WINAPI SockClient::HandleQueue(LPVOID Param)
{

	SockClient*P =(SockClient*)Param;
	if (P == NULL) return -1;
	QueueElem* this_ptr = NULL;
	while (1)
	{
		EnterCriticalSection(&P->m_cs);
		if (P->msg_queue!=NULL)
		{
		    this_ptr = P->msg_queue;
			P->msg_queue=P->msg_queue->next;
			if(P->last_ptr==this_ptr) 
			{
				P->last_ptr=NULL;
			}		
		}
		LeaveCriticalSection(&P->m_cs);
		
		if(this_ptr!=NULL)
		{
			string item;
			string item_fir;
			string item_sec;
			string item_sec_tem;
			string topic;
			topic = this_ptr->msg_topic;

			//////////////////////////////////////////////////////////
			string type_id="";
			string type_name="";
			string level="";
			string possibility="";
			string center_pos="";
			string event_width="";
			string first_push_time="";
			string max_intensity="";
			string sensor_id="";
			string channel_id="";
			string push_time="";
			string last_push_time="";

           //////////////////////////////////////////////////////////////
			string fiber_status="";
			string fiber_bk_pos="";
			string fiber_rl_len="";

			string my_sql;
			if(topic=="DFVS/Channel/Alarm")
			{
			    my_sql = "insert into hk_vib_event_detail(topic, sample_id, sample_name, level, possibility, center_pos,event_width, first_push_time, "\
				            "max_intensity, sensor_id, channel_id, push_time, last_push_time)";
			    fetch_head(this_ptr->msg_jason, "{");
			    while (this_ptr->msg_jason!="")
			    {
			        item = fetch_head(this_ptr->msg_jason, ",");
				    item_fir = fetch_head(item, ":");
				    item_fir = fetch_mid(item_fir,"\"", "\"");
				    item_sec = item;
				    item_sec_tem = fetch_mid(item_sec,"\"", "\"");
				    if (item_sec_tem!="")
				    {
				        item_sec = item_sec_tem;
				    }

				    if(item_fir=="TypeID")
				    {
				        type_id = item_sec;
				    }

				    if(item_fir=="TypeName")
				    {
				        type_name = item_sec;
				    }

				    if(item_fir=="Level")
				    {
				        level = item_sec;
				    }

				    if(item_fir=="Possibility")
				    {
				        possibility = item_sec;
				    }

				    if(item_fir=="CenterPosition")
				    {
				        center_pos = item_sec;
				    }

				    if(item_fir=="EventWidth")
				    {
				        event_width = item_sec;
				    }

				    if(item_fir=="FirstPushTime")
				    {
				        first_push_time = item_sec;
				    }

				    if(item_fir=="MaxIntensity")
				    {
				        max_intensity = item_sec;
				    }

				    if(item_fir=="SensorID")
				    {
				        sensor_id = item_sec;
				    }

				    if(item_fir=="ChannelID")
				    {
				        channel_id = item_sec;
				    }

				    if(item_fir=="PushTime")
				    {
				        push_time = item_sec;
				    }

				    if(item_fir=="LastPushTime")
				    {
				        last_push_time = item_sec;
				    }
				
			    }
			    //P->msg_queue
		        delete this_ptr;
		        this_ptr = NULL;

			    my_sql = my_sql + " values(";
			    my_sql = my_sql + "'"+topic + "',";
			    my_sql = my_sql + type_id + ",";
			    my_sql = my_sql + "'"+ type_name + "',";
			    my_sql = my_sql + level + ",";
			    my_sql = my_sql + "'"+ possibility + "',";
			    my_sql = my_sql + "'"+ center_pos + "',";
			    my_sql = my_sql + "'"+ event_width + "',";
			    my_sql = my_sql + "'"+ first_push_time + "',";
			    my_sql = my_sql + "'"+ max_intensity + "',";
			    my_sql = my_sql + "'"+ sensor_id + "',";
			    my_sql = my_sql + channel_id + ",";
			    my_sql = my_sql + "'"+ push_time + "',";
			    my_sql = my_sql + "'"+ last_push_time + "')";
			    P->db.execute(my_sql.c_str());
			    write_log(my_sql);
			    OutputDebugString(my_sql.c_str());
			}
			else if (topic=="DFVS/Channel/Fiber")
			{
			    fetch_head(this_ptr->msg_jason, "{");
			    while (this_ptr->msg_jason!="")
			    {
			        item = fetch_head(this_ptr->msg_jason, ",");
				    item_fir = fetch_head(item, ":");
				    item_fir = fetch_mid(item_fir,"\"", "\"");
				    item_sec = item;
				    item_sec_tem = fetch_mid(item_sec,"\"", "\"");
				    if (item_sec_tem!="")
				    {
				        item_sec = item_sec_tem;
				    }
				    if(item_fir=="FiberStatus")
				    {
				        fiber_status = item_sec;
				    }

				    if(item_fir=="FiberBreakLength")
				    {
				        fiber_bk_pos = item_sec;
				    }

					if(item_fir=="FiberRealLength")
				    {
				        fiber_rl_len = item_sec;
				    }

				    if(item_fir=="SensorID")
				    {
				        sensor_id = item_sec;
				    }

				    if(item_fir=="ChannelID")
				    {
				        channel_id = item_sec;
				    }

				    if(item_fir=="PushTime")
				    {
				        push_time = item_sec;
				    }

				}

                my_sql = "insert into hk_fiber_event_detail(topic,sensor_id, channel_id, push_time, fiber_stat, fiber_bk_len, fiber_real_len) values (";
				my_sql = my_sql + "'"+topic + "',";
				my_sql = my_sql + "'"+ sensor_id + "',";
				my_sql = my_sql + channel_id + ",";
				my_sql = my_sql + "'"+ push_time + "',";
				my_sql = my_sql + "'"+ fiber_status + "',";
				my_sql = my_sql + "'"+ fiber_bk_pos + "',";
				my_sql = my_sql + "'"+ fiber_rl_len + "')";

			    P->db.execute(my_sql.c_str());
			    write_log(my_sql);
			    OutputDebugString(my_sql.c_str());
				delete this_ptr;
		        this_ptr = NULL;
            }

		}
		else
		{
	        Sleep(50);
		}	
	}
	return 0;
}
#endif

#ifdef BOTDA

DWORD WINAPI SockClient::HandleQueue(LPVOID Param)
{
	SockClient*P =(SockClient*)Param;
	if (P == NULL) return -1;
	QueueElem* this_ptr = NULL;
	char tmp[100];
	string my_sql;
	while (1)
	{
		my_sql = "";
		EnterCriticalSection(&P->m_cs);
		if (P->msg_queue!=NULL)
		{
		    this_ptr = P->msg_queue;
			P->msg_queue=P->msg_queue->next;
			if(P->msg_queue!=NULL)
			{
			    P->msg_queue->pre = NULL;
			}
			if(P->last_ptr==this_ptr) 
			{
				P->last_ptr=NULL;
			}		
		}
		LeaveCriticalSection(&P->m_cs);
        if(this_ptr!=NULL)
	    {
			string topic;
			topic = this_ptr->msg_topic;
			string device_name;
			
			if(topic=="PUSH_SERVER_TYPE")
			{
				device_name = fetch_mid(this_ptr->msg_jason,"MachineID\":\"","\"");
				string device_mode = fetch_mid(this_ptr->msg_jason,"ServerType\":\"","\"");
				string max_ch_count = fetch_mid(this_ptr->msg_jason,"ChMaxCount\":",",");
				string run_status = fetch_mid(this_ptr->msg_jason,"RunType\":",",");
				if (device_name == "")
				{
					this_ptr->next = NULL;
					this_ptr->pre = NULL;
			        delete this_ptr;
		            this_ptr = NULL;
					continue;
				}
				
	            time_t t = time(0); 
	            memset(&tmp[0], 0, sizeof(tmp));
				strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
				my_sql = "insert into hk_botda_device_info(event_time,device_name, event_type, device_mode, max_ch_count, run_status) values ("; 
				my_sql = my_sql + "'" +  tmp + "',";
				my_sql = my_sql + "'" +  device_name + "',";
				my_sql = my_sql + "'" +  topic + "',";
				my_sql = my_sql + "'" +  device_mode + "', ";
				my_sql = my_sql + max_ch_count + ",";
				my_sql = my_sql + run_status + ")";

			}
			if(topic=="PUSH_WARNING_INFO")
			{
				device_name = fetch_mid(this_ptr->msg_jason,"MachineID\":\"","\"");
				string soft_alarm = fetch_mid(this_ptr->msg_jason,"SoftAlarm\":","}");
				string all_sec = fetch_mid(this_ptr->msg_jason,"AlarmSecs\":[","],");
				string a_sec="";


				while (all_sec !="")
				{
					a_sec = fetch_head(all_sec, "}");
					string channel_id = fetch_mid(a_sec, "ChannelID\":", ",");
					string alarm_guid = fetch_mid(a_sec, "Guid\":\"", "\","); 
					string alarm_time = fetch_mid(a_sec, "HappenTime\":\"", "\",");
					string update_time = fetch_mid(a_sec, "UpdateTime\":\"", "\",");
					string device_mode = fetch_mid(a_sec, "DataType\":", ",");
					string alarm_format = fetch_mid(a_sec, "EventTypeInt\":", ",");
					string alarm_level = fetch_mid(a_sec, "EventLevelInt\":", ",");
					string begin_pos = fetch_mid(a_sec, "BeginPos\":", ","); 
					string cent_pos = fetch_mid(a_sec, "MaxPos\":", ","); 
					string end_pos = fetch_mid(a_sec, "EndPos\":", ","); 
					string limen_value = fetch_mid(a_sec, "LimenVal\":", ","); 
					string max_value = fetch_mid(a_sec, "MaxVal\":", ","); 
					my_sql = "insert into hk_botda_alarm_info(device_name,channel_id, alarm_time, update_time, event_type, alarm_guid, device_mode, alarm_level, alarm_format, begin_pos, end_pos, cent_pos, max_value, limen_value, soft_alarm) values( ";
					my_sql = my_sql + "'" + device_name + "',";
					my_sql = my_sql + channel_id + ",";
					my_sql = my_sql + "'" + alarm_time + "',";
					my_sql = my_sql + "'" + update_time + "',";
					my_sql = my_sql + "'" + topic + "',";
					my_sql = my_sql + "'" + alarm_guid + "',";
					my_sql = my_sql + device_mode + ",";
					my_sql = my_sql + alarm_level + ",";
					my_sql = my_sql + alarm_format + ",";
					my_sql = my_sql + "'" + begin_pos + "',";
					my_sql = my_sql + "'" + end_pos + "',";
					my_sql = my_sql + "'" + cent_pos + "',";
					my_sql = my_sql + "'" + max_value + "',";
					my_sql = my_sql + "'" + limen_value + "',";
					my_sql = my_sql + soft_alarm + ")";
					P->db.execute(my_sql.c_str());
			        write_log(my_sql.c_str());
			        OutputDebugString(my_sql.c_str());
					my_sql = "";

				}


				P->clean_send_buf();
				make_reset_request_msg(P->m_send_buf,P->m_send_len, device_name.c_str());
				P->Send();

			}
			//if(topic=="PUSH_BOTDA_DATA")
			if ((topic=="PUSH_TEMP_DATA")||(topic=="PUSH_STRAIN_DATA")||(topic=="PUSH_CAL_PARAM"))
			{
				device_name = fetch_mid(this_ptr->msg_jason,"MacID\":\"","\"");
				string channel_id = fetch_mid(this_ptr->msg_jason, "ChnID\":", ",");
				string data_size = fetch_mid(this_ptr->msg_jason, "Size\":", ",");
				string data = fetch_mid(this_ptr->msg_jason,"HEXY\":\"","\"");
				string begin_pos = fetch_mid(this_ptr->msg_jason, "XOffsetUser\":", ",");
				string dot_len = fetch_mid(this_ptr->msg_jason, "XStepUser\":", ",");
				string rece_time = fetch_mid(this_ptr->msg_jason,"DataTime\":\"","\"");
				string is_alarm = fetch_mid(this_ptr->msg_jason, "IsAlarm\":", ",");
				my_sql = "insert into hk_botda_data(event_type, device_name, channel_id, data_size, data, begin_pos, dot_len, rece_time, is_alarm) values (";
				my_sql = my_sql + "'" + topic + "',";
				my_sql = my_sql + "'" + device_name + "',";
				my_sql = my_sql + channel_id + ",";
				my_sql = my_sql + data_size + ",";
				my_sql = my_sql + "'" + data + "',";
				my_sql = my_sql + "'" + begin_pos + "',";
				my_sql = my_sql + "'" + dot_len + "',";
				my_sql = my_sql + "'" + rece_time + "',";
				my_sql = my_sql + is_alarm + ")";
			}

			if (my_sql != "")
			{
			    P->db.execute(my_sql.c_str());
			    write_log(my_sql.c_str());
			    OutputDebugString(my_sql.c_str());
			}
			if( this_ptr!=NULL )
			{
				this_ptr->next = NULL;
				this_ptr->pre = NULL;
			    delete this_ptr;
		        this_ptr = NULL;
			}
		}
		Sleep(10);

	}
	return 0;
}
#endif


DWORD WINAPI SockClient::CliReThread(LPVOID Param)
{

	SockClient*P =(SockClient*)Param;
	
	int iCallNum;
	int oCallNum;
	char* temp1=new char[800];

	return 0;

}

DWORD WINAPI SockClient::SendHeartBeat(LPVOID Param)
{
	write_log("Send heart beat thread started.");
	SockClient*P =(SockClient*)Param;
	byte send_buf[100];
	int send_len=0;
	P->m_sendinghb=true;
	make_ping_request_msg(&send_buf[0],send_len);
	while (1)
	{
		if (P->m_connected)
		{
		    send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
		}
#ifdef BOTDA
	    Sleep(5000);
#endif

#ifdef MQTT 
		Sleep(15000);
#endif

	}
	write_log("Leave heart beat thread!!!!!!!!!!!!!!");
	P->m_sendinghb=false;
	return 0;
}

 void SockClient::start_send_heartbeat()
 {
     HANDLE HBeatThread;
	 DWORD targetThreadID;

     HBeatThread = CreateThread(NULL,0,SendHeartBeat,this,0,&targetThreadID);
	 Sleep(2000);
     CloseHandle(HBeatThread);

 }

 int SockClient::ConnectDB(const char* dbdsn, const char* dbusername, const char *dbpassword)
 {
	 if((dbdsn==NULL)||(dbusername==NULL)) return -1;
	 int dsn_len = strlen(dbdsn);
	 int username_len=strlen(dbusername);
	 if ((dsn_len==0)||(username_len==0)) return -1;

	 bool con_status;
	 string con_string;
	 /*
	 con_string="Provider=OraOLEDB.Oracle.1;Data Source=";
	    con_string=con_string+dbdsn;
	    con_string=con_string+";User ID=";
	    con_string=con_string+dbusername;
	    con_string=con_string+";Password=";
	    con_string=con_string+dbpassword;
	    con_string=con_string+";";
		con_string=con_string+"Persist Security Info=True";	
	*/
	con_string = "DSN=";
	con_string = con_string + dbdsn;
	
#ifdef MQTT
	con_string = con_string + ";Server=localhost;Database=hk_vib";
#endif
	
#ifdef BOTDA
	con_string = con_string + ";Server=localhost;Database=hk_botda";
#endif
	
	sprintf(db.connect_str,"%s", con_string.c_str());
	//con_status=db.open(con_string.c_str(),"","",adModeUnknown);
	con_status=db.open(con_string.c_str(),dbusername,dbpassword,adModeUnknown);
		
	if (!con_status)
	{
	    string temp="Can not connect to Database. Please check the setting!";	
		write_log(temp.c_str());
		return -1;
	}

     return 0;	
 }