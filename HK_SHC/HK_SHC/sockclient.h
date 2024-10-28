

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
	 bool m_connected;
	 CRITICAL_SECTION m_cs;

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

private:
	WORD m_wVersionRequested;
    WSADATA m_wsaData;
	int m_err;
	sockaddr_in m_destinationSockAddr;
	QueueElem * msg_queue;
	QueueElem * last_ptr;
//	VXI_Time m_time;

public:
	static DWORD WINAPI SendThread(LPVOID Param);
	static DWORD WINAPI SendData(LPVOID Param);
	static DWORD WINAPI SendHeartBeat(LPVOID Param);
	static DWORD WINAPI HandleQueue(LPVOID Param);

public:
	db_factory db;
	int ConnectDB(const char* dbdsn, const char* dbusername, const char *dbpassword);

};

#endif