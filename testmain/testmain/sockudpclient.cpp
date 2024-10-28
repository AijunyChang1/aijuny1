
#include "stdafx.h"

#include "sockudpclient.h"

SockUdpClient::SockUdpClient(HWND hwnd,char*ipaddr, int portn): m_hwnd(hwnd),port(portn)
{
	sprintf(ipadd,ipaddr);


}

SockUdpClient::~SockUdpClient()
{

}

int SockUdpClient::ConnectTo()
{


}