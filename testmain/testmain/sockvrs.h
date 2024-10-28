#include <stdio.h>
#include <Winsock2.h>
#include "Resource.h"
#include "CTILink.h"

class SockVRSClient;

struct VrsParam
{
	SockVRSClient* pVrsSock;
    int point;
};

class SockVRSClient
{
 public :
	 SockVRSClient(char* vrsip,int portn);
	 ~SockVRSClient();

	 int port;
	 char ipadd[60];

	 int Connect();

	 SOCKET SockClient[2000];
	 char VrsIP[50];
	 char RecordIP[50];
	 int RecordPort[2000][2];
	 bool bAddr[2000];

	 SOCKADDR_IN ConSrv;
	 static DWORD WINAPI VrsListenThread(LPVOID Param);
	 char msgarry[200][1500];


} ;