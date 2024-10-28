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

#ifdef DTS
#include "make_dtc.h"
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
	m_sendingst = false;
	m_send_len=0;
	m_remain_len = 0;
	m_ch = 0;
	memset(m_send_buf,0,BUF_SIZE);
#ifdef DTS
	m_ch_info.area_num=0;
	m_ch_info.ch_id=0;
	m_ch_info.point_len=0;
	m_ch_info.point_num=0;
	m_ch_info.temp_acc=0;
	m_ch_info.time_len=0;

	m_ch_stat.ch_id=0;
	m_ch_stat.comm_error=false;
	m_ch_stat.fiber_break=false;
	m_ch_stat.main_power_error=false;
	m_ch_stat.back_power_error=false;
	m_ch_stat.power_charge_error=false;
	m_ch_stat.break_pos=-1;
	m_ch_stat.break_date="";
    dts_send_id=0;

#endif

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
#ifdef DTS
	unsigned char MessageBuf[1500];
#else
	unsigned char MessageBuf[200000];
	
#endif
	unsigned char* MessageBufp;
	
	//char temp2[1500];
	int iLen;
	unsigned char* point;
	unsigned char MsgName[100];
	char w_log[BUF_SIZE];
	DWORD targetThreadID;
	HANDLE HCliReThread;
	static bool ifsend=false;
#ifdef DTS
    unsigned short temp[200];
#else
    unsigned char temp[BUF_SIZE];
#endif
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
			
# ifdef DTS
		     if(P->m_sendingst==false)
			 {
                 P->start_send_getstat();
			 }
# endif

		     if(P->m_sendinghb==false)
			 {
			     P->start_send_heartbeat();	
			 }
			 P->m_connected = true;
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
#ifdef DTS
		unsigned char * msg_ptr = &temp_msg[0];
		unsigned short  start_reg=0;
		unsigned short reg_num=0;
		unsigned short ref_id;
		unsigned short ch_id;
		unsigned short func_code;
		do
		{
			
		   has_error = parse_dts_msg(&msg_ptr, iLen, ref_id, ch_id, func_code, reg_num, temp); 
		   if (has_error==1)
		   {
		       	memcpy(P->m_remain_msg, msg_ptr, iLen);
				P->m_remain_len = iLen;
				continue;
		   }
		   
		   if (!has_error)
		   {
			  
               if (reg_num>0)
			   {
			       	sprintf(w_log, "Parsed a message, ref_id: %d, ch_id: %d, func_code: %d, reg_num: %d", ref_id, ch_id, func_code, reg_num);
					write_log(w_log);
					DtsQueueElem* new_elem = new DtsQueueElem;
					if (new_elem!=NULL)
					{
				       new_elem->ch_id = ch_id;
				       new_elem->func_code = func_code;
					   new_elem->ref_id = ref_id;
					   new_elem->reg_num = reg_num;
					  // memcpy((byte*)new_elem->reg, (byte*)temp, 400);					   
					   for(int i =0; i<reg_num/2; i++)
					   {
					       new_elem->reg[i]=temp[i];						   
					   }					   
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
			 
		   }
		   
          

        } while (iLen>0);
#endif

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
		    has_error = parse_botda_msg(&msg_ptr, iLen, (unsigned char*)MsgName, (unsigned short*)temp); 
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
			if(topic=="PUSH_TEMP_DATA")
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

#ifdef DTS

DWORD WINAPI SockClient::HandleQueue(LPVOID Param)
{
	SockClient*P =(SockClient*)Param;
	if (P == NULL) return -1;
	DtsQueueElem* this_ptr = NULL;

	string sql ="";
	char itocode[50];
	char tmp[100];
	bool changed;
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
		changed = false;
		if (this_ptr!=NULL)
		{
			switch (this_ptr->func_code)
			{
			case 3:
                 if (this_ptr->ref_id==51)
				 {

					 if ((P->m_ch_info.ch_id!=this_ptr->ch_id)
						 ||(P->m_ch_info.time_len!=this_ptr->reg[0])
						 ||(P->m_ch_info.temp_acc!=this_ptr->reg[2]))
					 {
					     P->m_ch_info.ch_id=this_ptr->ch_id;
					     P->m_ch_info.time_len=this_ptr->reg[0];
					     P->m_ch_info.temp_acc=this_ptr->reg[2];
						 changed = true;
					 }
					 if (changed)
					 {
						 if((P->m_ch_info.area_num!=0)
							 &&(P->m_ch_info.point_len!=0)
							 &&(P->m_ch_info.point_num!=0)
							 &&(P->m_ch_info.time_len!=65535)
							 &&(P->m_ch_info.point_num!=65535))
						 {
							 	            
							 time_t t = time(0); 
	                         memset(&tmp[0], 0, sizeof(tmp));
				             strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						     sql= "insert into hk_dts_ch_def(channel_id,point_len,point_num,time_len,temp_acc,area_num,create_time) values (";
							 sprintf(itocode,"%d",P->m_ch_info.ch_id);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.point_len);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.point_num);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.time_len);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.temp_acc);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.area_num);
							 sql = sql + itocode+",";
							 sql = sql + "'" + tmp +"')";

							 P->db.execute(sql.c_str());
			                 write_log(sql.c_str());
			                 OutputDebugString(sql.c_str());
						 }
					 }

					 if (P->m_ch_info.time_len==65535)
					 {
					     write_log("Fiber disconnected!!! from 3, 51");
					 
					 }
					 break;
				 
				 }  // end if 51
				 if ((this_ptr->ref_id>999)&&(this_ptr->ref_id<9000))
				 {
					 unsigned short area_num = this_ptr->ref_id/10-100;

					 if ((P->m_area_set[area_num].start_point!=this_ptr->reg[0])
						 ||(P->m_area_set[area_num].end_point!=this_ptr->reg[1])
						 ||(P->m_area_set[area_num].tmp_highlimit!=this_ptr->reg[2])
						 ||(P->m_area_set[area_num].tmp_raiselimit!=this_ptr->reg[3])
						 ||(P->m_area_set[area_num].tmp_difflimit!=this_ptr->reg[4])
						 ||(P->m_area_set[area_num].ch_id!=this_ptr->ch_id))
					 {
						 P->m_area_set[area_num].ch_id = this_ptr->ch_id;
					     P->m_area_set[area_num].start_point=this_ptr->reg[0];
						 P->m_area_set[area_num].end_point=this_ptr->reg[1];
						 P->m_area_set[area_num].tmp_highlimit=this_ptr->reg[2];
						 P->m_area_set[area_num].tmp_raiselimit=this_ptr->reg[3];
						 P->m_area_set[area_num].tmp_difflimit=this_ptr->reg[4];
						 changed = true;					 					 					 
					 }

					 if (changed)
					 {
						 time_t t = time(0); 
	                     memset(&tmp[0], 0, sizeof(tmp));
				         strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						 sql= "insert into hk_dts_area_def(channel_id,area_no, begin_pos,end_pos,high_limit,raise_limit,diff_limit,create_time) values (";
						 sprintf(itocode,"%d", P->m_area_set[area_num].ch_id);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", area_num+1);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_set[area_num].start_point);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_set[area_num].end_point);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_set[area_num].tmp_highlimit);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_set[area_num].tmp_raiselimit);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_set[area_num].tmp_difflimit);
						 sql = sql + itocode+",";
						 sql = sql + "'" + tmp +"')";
						 P->db.execute(sql.c_str());
			             write_log(sql.c_str());
			             OutputDebugString(sql.c_str());

					 }
				 
				 }



				break;
			case 4:

				switch (this_ptr->ref_id)
				{
				case 10:                                    //通道基本信息

					///////////////////////////////////////////////////////////////////////////
					 if ((P->m_ch_info.ch_id!=this_ptr->ch_id)
						 ||(P->m_ch_info.area_num!=this_ptr->reg[1]))
					 {
					     P->m_ch_info.ch_id=this_ptr->ch_id;
						 P->m_ch_info.area_num=this_ptr->reg[1];
						 changed = true;
					 }
					 if (changed)
					 {
						 if((P->m_ch_info.time_len!=0)
							 &&(P->m_ch_info.temp_acc!=0)
							 &&(P->m_ch_info.point_len!=0)
							 &&(P->m_ch_info.point_num!=0)
							 &&(P->m_ch_info.time_len!=65535)
							 &&(P->m_ch_info.point_num!=65535))
						 {
							 	            
							 time_t t = time(0); 
	                         memset(&tmp[0], 0, sizeof(tmp));
				             strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						     sql= "insert into hk_dts_ch_def(channel_id,point_len,point_num,time_len,temp_acc,area_num,create_time) values (";
							 sprintf(itocode,"%d",P->m_ch_info.ch_id);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.point_len);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.point_num);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.time_len);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.temp_acc);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.area_num);
							 sql = sql + itocode+",";
							 sql = sql + "'" + tmp +"')";

							 P->db.execute(sql.c_str());
			                 write_log(sql.c_str());
			                 OutputDebugString(sql.c_str());
						 }
					 }

					///////////////////////////////////////////////////////////////////////////
					 changed = false;
					 bool b_break;
					 if(this_ptr->reg[2]==0)
					 {
					     b_break = false;
					 }
					 else
					 {
					     b_break = true;					 
					 }
					 if ((P->m_ch_stat.ch_id!=this_ptr->ch_id)||(P->m_ch_stat.fiber_break!=b_break))
					 { 
					     P->m_ch_stat.ch_id = this_ptr->ch_id;
						 P->m_ch_stat.fiber_break = b_break;
						 changed = true;					 
					 }
 					 if (changed)
					 {
						  time_t t = time(0); 
	                      memset(&tmp[0], 0, sizeof(tmp));
				          strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						  sql= "insert into hk_dts_ch_stat(channel_id,fiber_break,comm_error,main_power,back_power,power_charge,create_time) values (";
							 sprintf(itocode,"%d",P->m_ch_stat.ch_id);
							 sql = sql + itocode+",";
							 if(P->m_ch_stat.fiber_break)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.comm_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.main_power_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.back_power_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.power_charge_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
                             sql = sql + "'" + tmp +"')";

							 P->db.execute(sql.c_str());
			                 write_log(sql.c_str());
			                 OutputDebugString(sql.c_str());
					 }


					    break;
				case 50:                                         //通道采集信息

					///////////////////////////////////////////////////////////////////////////
					 if ((P->m_ch_info.ch_id!=this_ptr->ch_id)
						 ||(P->m_ch_info.point_num!=this_ptr->reg[1])
						 ||(P->m_ch_info.point_len!=this_ptr->reg[0]))
					 {
						 P->m_ch_info.ch_id=this_ptr->ch_id;
					     P->m_ch_info.point_len=this_ptr->reg[0];
						 P->m_ch_info.point_num=this_ptr->reg[1];
						 changed = true;
					 }
					 if (changed)
					 {
						 if((P->m_ch_info.time_len!=0)
							 &&(P->m_ch_info.temp_acc!=0)
							 &&(P->m_ch_info.area_num!=0)
							 &&(P->m_ch_info.time_len!=65535)
							 &&(P->m_ch_info.point_num!=65535))
						 {
							 	            
							 time_t t = time(0); 
	                         memset(&tmp[0], 0, sizeof(tmp));
				             strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						     sql= "insert into hk_dts_ch_def(channel_id,point_len,point_num,time_len,temp_acc,area_num,create_time) values (";
							 sprintf(itocode,"%d",P->m_ch_info.ch_id);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.point_len);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.point_num);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.time_len);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.temp_acc);
							 sql = sql + itocode+",";
							 sprintf(itocode,"%d",P->m_ch_info.area_num);
							 sql = sql + itocode+",";
							 sql = sql + "'" + tmp +"')";

							 P->db.execute(sql.c_str());
			                 write_log(sql.c_str());
			                 OutputDebugString(sql.c_str());
						 }
					 }

					 if (P->m_ch_info.point_num==65535)
					 {
					     write_log("No fiber connected!!! from 4, 50");
					 }

					///////////////////////////////////////////////////////////////////////////

					    break;

				case 100:                                   //通道断纤信息
					{

					if (!P->m_ch_stat.fiber_break) break;
					char temp_date[50];
					string s_temp_date;
					unsigned short month=this_ptr->reg[1]&0x00FF;
					unsigned short year=(this_ptr->reg[1]>>8)&0x00FF;
					unsigned short hour=this_ptr->reg[2]&0x00FF;
					unsigned short day=(this_ptr->reg[2]>>8)&0x00FF;
					unsigned short sec=this_ptr->reg[3]&0x00FF;
					unsigned short min=(this_ptr->reg[3]>>8)&0x00FF;
					sprintf(temp_date, "20%d-%02d-%02d %02d:%02d:%02d", year,month, day, hour, min, sec);
					
					if ((P->m_ch_stat.ch_id!=this_ptr->ch_id)||(P->m_ch_stat.break_pos!=this_ptr->reg[0])||(P->m_ch_stat.break_date!=temp_date))
					{ 
					     P->m_ch_stat.ch_id = this_ptr->ch_id;
						 P->m_ch_stat.break_pos=this_ptr->reg[0];
						 P->m_ch_stat.break_date=temp_date;
						 changed = true;					 
					}
					
 				    if (changed)
					{
						time_t t = time(0); 
	                    memset(&tmp[0], 0, sizeof(tmp));
				        strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						sql= "insert into hk_dts_ch_stat(channel_id,fiber_break,comm_error,main_power,back_power,power_charge,create_time, break_pos, fiber_break_time) values (";
						sprintf(itocode,"%d",P->m_ch_stat.ch_id);
						sql = sql + itocode+",";
						if(P->m_ch_stat.fiber_break)
						{
							sql = sql +"1,";
						}
						else
						{
							sql = sql +"0,";
						}
					    if (P->m_ch_stat.comm_error)
						{
							sql = sql +"1,";
						}
						else
						{
							sql = sql +"0,";
						}
						if (P->m_ch_stat.main_power_error)
						{
						    sql = sql +"1,";
						}
						else
						{
						    sql = sql +"0,";
						}
						if (P->m_ch_stat.back_power_error)
						{
							sql = sql +"1,";
						}
						else
						{
							sql = sql +"0,";
						}
						if (P->m_ch_stat.power_charge_error)
						{
							sql = sql +"1,";
						}
						else
						{
							sql = sql +"0,";
						}
                        sql = sql + "'" + tmp +"',";
						sprintf(itocode,"%d", P->m_ch_stat.break_pos);
						sql = sql + itocode + ",";
						sql = sql + "'"+P->m_ch_stat.break_date+ "')";

						P->db.execute(sql.c_str());
			            write_log(sql.c_str());
			            OutputDebugString(sql.c_str());
					 }



					    
					    break;
					}



				case 200:                                   //设备故障信息


					 bool comm_error;
					 bool main_error;
					 bool back_error;
					 bool charge_error;
					 if(this_ptr->reg[0]==0)
					 {
					     comm_error = false;
					 }
					 else
					 {
					     comm_error = true;					 
					 }
					 if(this_ptr->reg[1]==0)
					 {
					     main_error = false;
					 }
					 else
					 {
					     main_error = true;					 
					 }
					 if(this_ptr->reg[2]==0)
					 {
					     back_error = false;
					 }
					 else
					 {
					     back_error = true;					 
					 }
					 if(this_ptr->reg[3]==0)
					 {
					     charge_error = false;
					 }
					 else
					 {
					     charge_error = true;					 
					 }


					 if ((P->m_ch_stat.ch_id!=this_ptr->ch_id)
						 ||(P->m_ch_stat.comm_error!=comm_error)
						 ||(P->m_ch_stat.main_power_error!=main_error)
						 ||(P->m_ch_stat.back_power_error!=back_error)
						 ||(P->m_ch_stat.power_charge_error!=charge_error))
					 { 
					     P->m_ch_stat.ch_id = this_ptr->ch_id;
						 P->m_ch_stat.comm_error = comm_error;
						 P->m_ch_stat.main_power_error = main_error;
                         P->m_ch_stat.back_power_error = back_error;
						 P->m_ch_stat.power_charge_error = charge_error;
						 changed = true;					 
					 }
 					 if (changed)
					 {
						  time_t t = time(0); 
	                      memset(&tmp[0], 0, sizeof(tmp));
				          strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						  sql= "insert into hk_dts_ch_stat(channel_id,fiber_break,comm_error,main_power,back_power,power_charge,create_time) values (";
							 sprintf(itocode,"%d",P->m_ch_info.ch_id);
							 sql = sql + itocode+",";
							 if(P->m_ch_stat.fiber_break)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.comm_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.main_power_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.back_power_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
							 if (P->m_ch_stat.power_charge_error)
							 {
							     sql = sql +"1,";
							 }
							 else
							 {
							     sql = sql +"0,";
							 }
                             sql = sql + "'" + tmp +"')";

							 P->db.execute(sql.c_str());
			                 write_log(sql.c_str());
			                 OutputDebugString(sql.c_str());
					 }
					 else
					 {
					 
					 
					 }
					    
					 break;

				default:  break;

				}
///////////////////////////////////////////////////////
				if ((this_ptr->ref_id>999)&&(this_ptr->ref_id<9000))    //分区实时温度信息
				{
					 unsigned short area_num = this_ptr->ref_id/10-100;
					 P->m_area_real_data[area_num].ch_id = this_ptr->ch_id;
					 P->m_area_real_data[area_num].tmp_warning = this_ptr->reg[0];
					 P->m_area_real_data[area_num].high_temp = this_ptr->reg[1];
					 P->m_area_real_data[area_num].ava_temp = this_ptr->reg[2];
					 P->m_area_real_data[area_num].low_temp = this_ptr->reg[3];
					 P->m_area_real_data[area_num].high_pos = this_ptr->reg[4];
					 P->m_area_real_data[area_num].low_pos = this_ptr->reg[5];

					 time_t t = time(0); 
	                 memset(&tmp[0], 0, sizeof(tmp));
				     strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						 sql= "insert into hk_dts_area_real_data(channel_id,area_no,tmp_warning,high_temp,ava_temp,low_temp,high_pos,low_pos,create_time) values (";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].ch_id);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", area_num+1);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].tmp_warning);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].high_temp);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].ava_temp);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].low_temp);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].high_pos);
						 sql = sql + itocode+",";
						 sprintf(itocode,"%d", P->m_area_real_data[area_num].low_pos);
						 sql = sql + itocode+",";
						 sql = sql + "'" + tmp +"')";
						 P->db.execute(sql.c_str());
			             write_log(sql.c_str());
			             OutputDebugString(sql.c_str());	

				     break;
				}

				if((this_ptr->ref_id>9999)&&(this_ptr->ref_id<16000))
				{
					if (this_ptr->reg[2]==65535) break;
					unsigned short array_index;
					unsigned short alarm_type=0;
					changed=false;

					char temp_date[50];
					string s_temp_date;
					unsigned short month=this_ptr->reg[2]&0x00FF;
					unsigned short year=(this_ptr->reg[2]>>8)&0x00FF;
					unsigned short hour=this_ptr->reg[3]&0x00FF;
					unsigned short day=(this_ptr->reg[3]>>8)&0x00FF;
					unsigned short sec=this_ptr->reg[4]&0x00FF;
					unsigned short min=(this_ptr->reg[4]>>8)&0x00FF;
					sprintf(temp_date, "20%d-%02d-%02d %02d:%02d:%02d", year,month, day, hour, min, sec);
				    if((this_ptr->ref_id>9999)&&(this_ptr->ref_id<12000))
					{
					     array_index=(this_ptr->ref_id/10)%1000;
						 alarm_type=1;
						 if ((P->m_high_alarm[array_index].ch_id!=this_ptr->ch_id)
						   ||(P->m_high_alarm[array_index].area_num!=this_ptr->reg[5])
						   ||(P->m_high_alarm[array_index].start_pos!=this_ptr->reg[0])
						   ||(P->m_high_alarm[array_index].end_pos!=this_ptr->reg[1])
						   ||(P->m_high_alarm[array_index].alarm_time!=temp_date)
						   )
					     {
					           P->m_high_alarm[array_index].ch_id=this_ptr->ch_id;
						       P->m_high_alarm[array_index].area_num=this_ptr->reg[5];
							   P->m_high_alarm[array_index].start_pos=this_ptr->reg[0];
							   P->m_high_alarm[array_index].end_pos=this_ptr->reg[1];
							   P->m_high_alarm[array_index].alarm_time=temp_date;
						       changed = true;
					     }

					}

					if((this_ptr->ref_id>11999)&&(this_ptr->ref_id<14000))
					{
					     array_index=(this_ptr->ref_id/10)%1000-200;
						 alarm_type=2;

						 if ((P->m_raise_alarm[array_index].ch_id!=this_ptr->ch_id)
						   ||(P->m_raise_alarm[array_index].area_num!=this_ptr->reg[5])
						   ||(P->m_raise_alarm[array_index].start_pos!=this_ptr->reg[0])
						   ||(P->m_raise_alarm[array_index].end_pos!=this_ptr->reg[1])
						   ||(P->m_raise_alarm[array_index].alarm_time!=temp_date)
						   )
					     {
					           P->m_raise_alarm[array_index].ch_id=this_ptr->ch_id;
						       P->m_raise_alarm[array_index].area_num=this_ptr->reg[5];
							   P->m_raise_alarm[array_index].start_pos=this_ptr->reg[0];
							   P->m_raise_alarm[array_index].end_pos=this_ptr->reg[1];
							   P->m_raise_alarm[array_index].alarm_time=temp_date;
						       changed = true;
					     }
					}

					if((this_ptr->ref_id>13999)&&(this_ptr->ref_id<16000))
					{
					    array_index=(this_ptr->ref_id/10)%1000-400;
						alarm_type=4;

						 if ((P->m_diff_alarm[array_index].ch_id!=this_ptr->ch_id)
						   ||(P->m_diff_alarm[array_index].area_num!=this_ptr->reg[5])
						   ||(P->m_diff_alarm[array_index].start_pos!=this_ptr->reg[0])
						   ||(P->m_diff_alarm[array_index].end_pos!=this_ptr->reg[1])
						   ||(P->m_diff_alarm[array_index].alarm_time!=temp_date)
						   )
					     {
					           P->m_diff_alarm[array_index].ch_id=this_ptr->ch_id;
						       P->m_diff_alarm[array_index].area_num=this_ptr->reg[5];
							   P->m_diff_alarm[array_index].start_pos=this_ptr->reg[0];
							   P->m_diff_alarm[array_index].end_pos=this_ptr->reg[1];
							   P->m_diff_alarm[array_index].alarm_time=temp_date;
						       changed = true;
					     }
					}

					if(changed)
					{
						  time_t t = time(0); 
	                      memset(&tmp[0], 0, sizeof(tmp));
				          strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						  sql= "insert into  hk_dts_real_alarm_info(channel_id,area_no,alarm_type,begin_pos,end_pos,alarm_time,create_time) values (";
						  sprintf(itocode,"%d",this_ptr->ch_id);
						  sql = sql + itocode+",";
						  sprintf(itocode,"%d",this_ptr->reg[5]);
						  sql = sql + itocode+",";
						  sprintf(itocode,"%d",alarm_type);
						  sql = sql + itocode+",";
						  sprintf(itocode,"%d",this_ptr->reg[0]);
						  sql = sql + itocode+",";
						  sprintf(itocode,"%d",this_ptr->reg[1]);
						  sql = sql + itocode+",";
						  sql = sql + "'" + temp_date +"',";
						  sql = sql + "'" + tmp +"')";
						  P->db.execute(sql.c_str());
			              write_log(sql.c_str());
			              OutputDebugString(sql.c_str());	
					
					}
					break;
				
				}
//////////////////////////////////////////////////////////////////////
				if((this_ptr->ref_id>19999)&&(this_ptr->ref_id<65535))
				{
					unsigned short array_index;
					array_index = this_ptr->ref_id-20000;
					for (int k=0; k<50; k++)
					{
						P->m_data[array_index+k] = 	this_ptr->reg[k];			
					
					}

					if(this_ptr->ref_id==22400)
					{
						 time_t t = time(0); 
	                     memset(&tmp[0], 0, sizeof(tmp));
				         strftime(tmp, sizeof(tmp), "%Y-%m-%d %X",localtime(&t));
						 string data_str="";
						 for (int k=0;k<(P->m_ch_info.point_num-50);k++)
						 {
							 sprintf(itocode,"%d",P->m_data[k]);
							 data_str=data_str+itocode+":";
						 
						 }

						 sql= "insert into  hk_dts_real_data_info(channel_id,point_len,data,create_time) values (";
						 sprintf(itocode,"%d",this_ptr->ch_id);
						 sql = sql + itocode+",";	
						 sprintf(itocode,"%d",P->m_ch_info.point_len);
						 sql = sql + itocode+",";
						 sql = sql + "'"+ data_str+"',";
						 sql = sql + "'" + tmp +"')";
						 P->db.execute(sql.c_str());
			             write_log(sql.c_str());
			             OutputDebugString(sql.c_str());	
					
					}

				
					break;			
				}


//////////////////////////////////////////////////////////
				

				break;
			case 6: 

				break;
			default:

				break;

			
			}


		}

		if (this_ptr!=NULL)
		{
			this_ptr->next = NULL;
			this_ptr->pre = NULL;
			delete this_ptr;
		    this_ptr = NULL;	
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

#ifdef DTS
	int func_code;
	int channel_id;
	func_code=3;
	channel_id=P->m_ch;
	int send_hold_len=0;
	int send_input_len=0;
	byte send_buf_hold[100];
	byte send_buf_input[100];
//	make_request_msg(&send_buf_hold[0],send_hold_len,t_id,func_code,channel_id);
#else
	make_ping_request_msg(&send_buf[0],send_len);
#endif

	while (1)
	{
		if (P->m_connected)
		{
#ifdef DTS
			P->dts_send_id++;
			make_request_msg(&send_buf_hold[0],send_hold_len,P->dts_send_id,func_code,P->m_ch,0,100);

			//send(P->m_sockettcp ,(const char*)send_buf_hold,send_hold_len,0);
#else
		    send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
#endif
		}


#ifdef BOTDA
	    Sleep(5000);
#endif

#ifdef MQTT 
		Sleep(15000);
#endif

#ifdef DTS 
		Sleep(5000);
#endif
	}
	write_log("Leave heart beat thread!!!!!!!!!!!!!!");
	P->m_sendinghb=false;
	return 0;
}

#ifdef DTS
 DWORD WINAPI SockClient::GetStat(LPVOID Param)
{
	write_log("Send Get State thread started.");
	SockClient*P =(SockClient*)Param;
    byte send_buf[100];
	int send_len=0;
	P->m_sendingst=true;

	int func_code;
	int channel_id;
	int regist_start_id;
	int regist_num;

	while (1)
	{
		if (P->m_connected)
		{
			P->dts_send_id++;
			
			channel_id =P->m_ch;

			func_code = 3;
			regist_start_id = 51; //获取通道的测量时间
			regist_num= 3;
			//make_request_msg(&send_buf[0],send_len,P->dts_send_id,func_code,channel_id,regist_start_id,regist_num);
			make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
			Sleep(20);

		    func_code = 4;
			regist_start_id = 50; //两个温度点之间的实际距离(单位为米)，实际值*100
			regist_num= 5;
			make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
			Sleep(20);

			func_code = 4;
			regist_start_id = 10; //两个温度点之间的实际距离(单位为米)，实际值*100
			regist_num= 6;
			make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
			Sleep(20);

			func_code = 4;
			regist_start_id = 100; //断纤位置
			regist_num= 4;
			make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
			Sleep(20);

			func_code = 4;
			regist_start_id = 200; //设备故障信息
			regist_num= 4;
			make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
			Sleep(20);

			if((P->m_ch_info.area_num>0)&& (P->m_ch_info.point_num!=65535))
			{
			      for(int i=0;i<P->m_ch_info.area_num; i++)
				  {
					  func_code=3;
				      regist_start_id = 1000+10*i; 
					  regist_num= 5;
					  make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			          send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
					  Sleep(10);

					  func_code=4; 
					  regist_num= 6;
					  make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			          send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
					  Sleep(10);

				  }


				  for(int j=1000;j<1200; j++)           //定温报警
				  {
					  func_code=4; 
					  regist_start_id=10*j;
					  regist_num= 6;
				      make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			          send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
					  Sleep(10);
				  }

				  for(int j=1200;j<1400; j++)           //升温温报警
				  {
					  func_code=4; 
					  regist_start_id=10*j;
					  regist_num= 6;
				      make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			          send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
					  Sleep(10);
				  }

				  for(int j=1400;j<1600; j++)           //差温报警
				  {
					  func_code=4; 
					  regist_start_id=10*j;
					  regist_num= 6;
				      make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			          send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
					  Sleep(10);
				  }

			}

			if ((P->m_ch_info.point_num>0)&& (P->m_ch_info.point_num!=65535))            // P->m_ch_info.point_num==65535
			{
				  
				for (int k=0; (k*50+50)<P->m_ch_info.point_num; k++)
				{
					  func_code=4; 
					  regist_start_id=20000+50*k;
					  regist_num= 50;
				      make_request_msg(&send_buf[0],send_len,regist_start_id,func_code,channel_id,regist_start_id,regist_num);
			          send(P->m_sockettcp ,(const char*)send_buf,send_len,0);
					  Sleep(10);					   
				}
				  
			}


		}

		Sleep(10000);

	}

    P->m_sendingst=false; 
	return 0;
}
#endif

 void SockClient::start_send_heartbeat()
 {
     HANDLE HBeatThread;
	 DWORD targetThreadID;

     HBeatThread = CreateThread(NULL,0,SendHeartBeat,this,0,&targetThreadID);
	 Sleep(2000);
     CloseHandle(HBeatThread);

 }

#ifdef DTS

 void SockClient::start_send_getstat()
 {
 
	 HANDLE HBeatThread;
	 DWORD targetThreadID;

     HBeatThread = CreateThread(NULL,0,GetStat,this,0,&targetThreadID);
	 Sleep(2000);
     CloseHandle(HBeatThread);
 
 }
#endif

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