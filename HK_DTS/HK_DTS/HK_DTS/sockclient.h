

#ifndef SOCK_CLIENT_H_
#define SOCK_CLIENT_H_

#include <stdio.h>
#include <Winsock2.h>
#include <fstream>
#include <string>
#include "encode.h"
#include "func.h"

//#define BUF_SIZE 1500
using namespace std; 

struct QueueElem
{
    string msg_topic;
	string msg_jason;
	QueueElem * pre;
	QueueElem * next;
};

struct DtsQueueElem
{
	unsigned short ref_id;
    unsigned short ch_id;
	unsigned short func_code;
	unsigned short reg_num;
	unsigned short reg[200];

	DtsQueueElem * pre;
	DtsQueueElem * next;
};

struct DtsChInfo
{
	unsigned short ch_id;
    unsigned short point_len;
	unsigned short point_num;
	unsigned short area_num;
	unsigned short time_len;
	unsigned short temp_acc;
};

struct DtsChStat
{
	unsigned short ch_id;
    bool fiber_break;
	bool comm_error;
	bool main_power_error;
	bool back_power_error;
	bool power_charge_error;
	int break_pos;
	string break_date;
};

struct DtsAreaSet
{
	unsigned short ch_id;
    unsigned short start_point;
	unsigned short end_point;
	unsigned short tmp_highlimit;
	unsigned short tmp_raiselimit;
	unsigned short tmp_difflimit;

};

struct DtsAreaRealData
{
	unsigned short ch_id;
    unsigned short tmp_warning;
	unsigned short high_temp;
	unsigned short ava_temp;
	unsigned short low_temp;
	unsigned short high_pos;
	unsigned short low_pos;
};

struct DtsAlarmInfo
{
    unsigned short ch_id;
	unsigned short area_num;
	unsigned short start_pos;
	unsigned short end_pos;
	string alarm_time;

};


class SockClient
{
 public :
	 SockClient(const char* remote_ip, int portn, const char* local_ip);
	 ~SockClient();

	 static DWORD WINAPI CliListenThread(LPVOID Param);
	 static DWORD WINAPI CliReThread(LPVOID Param);
	// HWND m_hwnd;                       
	 int m_remote_port;
	 char m_remote_ip[60];
	 char m_local_ip[60];
	 SOCKET m_sockettcp;
	 bool m_sendinghb;
	 bool m_sendingst;
	 bool m_connected;
	 CRITICAL_SECTION m_cs;
	 unsigned short m_ch;


#ifdef DTS
	 unsigned short dts_send_id;
	 DtsChInfo m_ch_info;
	 DtsChStat m_ch_stat;
	 DtsAreaSet m_area_set[800];
	 DtsAreaRealData m_area_real_data[800];
	 DtsAlarmInfo m_high_alarm[200];
	 DtsAlarmInfo m_raise_alarm[200];
	 DtsAlarmInfo m_diff_alarm[200];
	 unsigned short m_data[45535];
#endif

	 byte m_send_buf[BUF_SIZE];
	 int m_send_len;
	 byte m_remain_msg[BUF_SIZE];
	 unsigned int m_remain_len;

	 int ConnectTo();
	 int CloseSocket();
	 // void CreatRtpHead(char *buf,int csrc,int sequence_num,int time_stamp);
	 void Send();
	 void clean_send_buf();
	 void start_send_heartbeat();
#ifdef DTS
	 void start_send_getstat();
#endif

private:
	WORD m_wVersionRequested;
    WSADATA m_wsaData;
	int m_err;
	sockaddr_in m_destinationSockAddr;

#ifdef DTS
	DtsQueueElem * msg_queue;
	DtsQueueElem * last_ptr;

#else
	QueueElem * msg_queue;
	QueueElem * last_ptr;

#endif


//	VXI_Time m_time;

public:
	static DWORD WINAPI SendThread(LPVOID Param);
	static DWORD WINAPI SendData(LPVOID Param);
	static DWORD WINAPI SendHeartBeat(LPVOID Param);

#ifdef DTS
	static DWORD WINAPI GetStat(LPVOID Param);
#endif

	static DWORD WINAPI HandleQueue(LPVOID Param);

public:
	db_factory db;
	int ConnectDB(const char* dbdsn, const char* dbusername, const char *dbpassword);

};

#endif