// stdafx.cpp : ֻ������׼�����ļ���Դ�ļ�
// testmain.pch ����ΪԤ����ͷ
// stdafx.obj ������Ԥ����������Ϣ

#include "stdafx.h"


int  iThreadNum=1;
char  inNum[30];
char  outNum[30];
int callid=1234567;
int firstcallid;
HANDLE hCallidEvent;
bool sfstarted;
bool recnew;
int line=0;
int Slogin=2;
SockVRSClient * SockVrs=NULL;
char VrsIP[50];
char SerIP[50];
int porttag[2000];
FILE* logfp=NULL;
int missnum=0;




