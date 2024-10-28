#include <stdio.h>
#include <Winsock2.h>
#include "Resource.h"
#include "CTILink.h"



//void on_cti_msg_recv_func(const char *buf, int len);

class Socket
{
 
 public :
	 Socket(HWND hwnd,int portn,int typen);
	 ~Socket();

	 bool StartListen();
	 static DWORD WINAPI ListenThread(LPVOID Param);
	 static DWORD WINAPI ReceSendThread(LPVOID Param);
	 static DWORD WINAPI HandleReceThread(LPVOID Param);
	 bool SendTo(const char* ClientIP);
	 char *CliSendBuf;
	 char *CliRecBuf;
     HWND Wnd;
  private:

	 WORD wVersionRequested;
     WSADATA wsaData;
     int err;
	 SOCKADDR_IN addrSrv;
	 HANDLE HListenThread;


     SOCKET SockSrv;
	 SOCKET SockClient;
	 int Port;
	 int Type;
	 char ReceiIP[50];

	 




};

struct RecvSendInfo
{
	SOCKET conSock;
	Socket* pCliSock;
	SOCKADDR_IN  Addr_in;

};

struct RecvInfo
{
    RecvSendInfo* SockInfo;
	int RecvLen;
	unsigned char*buffer;

};








