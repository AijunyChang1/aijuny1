#include <stdio.h>
#include <Winsock2.h>
#include "Resource.h"
#include "CTILink.h"

class SockUdpClient
{
 public :
	 SockUdpClient(HWND hwnd, char* ipaddr, int portn);
	 ~SockUdpClient();

	 HWND m_hwnd;

	 int port;
	 char ipadd[60];

	int ConnectTo();




}
;