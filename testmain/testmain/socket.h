#include <stdio.h>
#include <Winsock2.h>
#include "Resource.h"
#include "CTILink.h"




//void on_cti_msg_recv_func(const char *buf, int len);
struct SocketStru
{ 
	SOCKET conSock;
	bool conn;
	HANDLE hHandleReceEvnet;
  
};


class Socket
{
 
 public :
	 Socket(HWND hwnd,int portn,int typen);
	 ~Socket();

	 bool StartListen();
	 bool StartClientSock();
	 static DWORD WINAPI ListenThread(LPVOID Param);
	 static DWORD WINAPI CliListenThread(LPVOID Param);
	 static DWORD WINAPI ReceSendThread(LPVOID Param);
     static DWORD WINAPI CallThread(LPVOID Param);
	 static DWORD WINAPI CliReThread(LPVOID Param);

	 static DWORD WINAPI HandleReceThread(LPVOID Param);
	 bool SendTo(const char* ClientIP);
	 char CliIP[50];
	 

//	 int clport[50];
	 char *CliSendBuf;
	 char *CliRecBuf;
	 bool connected;
     HWND Wnd;
	 HANDLE hEvent;
//	 HANDLE hCliEvent[2000];
	 HANDLE hCliEventT;
	 
	 SocketStru SockArr[10];
	 int ConnNum;   
	 
	 SOCKET SockSrv;
	 SOCKET SockClient[2000];
  private:

	 WORD wVersionRequested;
     WSADATA wsaData;
     int err;
	 SOCKADDR_IN addrSrv;
	 SOCKADDR_IN ConSrv;
	 HANDLE HListenThread;



	 int Port;
	 int Type;
	 char ReceiIP[50];

	 




};

struct RecvSendInfo
{
	SOCKET conSock;
	Socket* pCliSock;
	SOCKADDR_IN  Addr_in;
	int point;

};

struct RecvInfo
{
    RecvSendInfo* SockInfo;
	int RecvLen;
	unsigned char*buffer;

};



struct SoftPhoneParam
{
	Socket* pCliSock;
    int point;
};







