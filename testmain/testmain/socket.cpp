#include "stdafx.h"
//#include "socket.h"
#include "decode.h"

#ifndef _IN

#define _IN
//#include "testmainDlg.h"
#endif




Socket::Socket(HWND hwnd,int portn,int typen):Port(portn),Type(typen),Wnd(hwnd),ConnNum(0),connected(false)
{
  hEvent=CreateEvent(NULL,FALSE,TRUE,NULL);

  /*
  for(int i=0;i<iThreadNum;i++)
  {
    hCliEvent[i]=CreateEvent(NULL,TRUE,TRUE,NULL);
  }
  */

   hCliEventT=CreateEvent(NULL,TRUE,FALSE,NULL);
   


  CliSendBuf=new char[1000];
  CliRecBuf=new char[1000];
  for (int i=0;i<10;i++)
  {
	  SockArr[i].conn=false; 
	  SockArr[i].hHandleReceEvnet=CreateEvent(NULL,TRUE,FALSE,NULL);
  }
/*
  if ((CliSendBuf==NULL)||(CliRecBuf==NULL))
  {
     ::MessageBox(NULL,TEXT("No enough memory!"),TEXT("Socket Error"),0);
  }
  */
  wVersionRequested = MAKEWORD( 1, 1 );
  
  err = WSAStartup( wVersionRequested, &wsaData );
   if ( err != 0 ) 
   {
	   ::MessageBox(NULL,TEXT("Initialize Socket error!"),TEXT("Socket Error"),0);
       return;
   }

   if ((LOBYTE( wsaData.wVersion) != 1) || (HIBYTE(wsaData.wVersion) != 1 ) )
   {
       WSACleanup( );
       return;
   }

   char name[150];
   PHOSTENT  hostinfo;  
   if(gethostname(name,sizeof(name))  ==  0)  
   {  
     if((hostinfo=gethostbyname(name))!=  NULL)  
    {  
     sprintf(SerIP,"%s", inet_ntoa(*(struct  in_addr *)*hostinfo->h_addr_list));  
    } 
   }



   SockSrv=socket(AF_INET,SOCK_STREAM,0);
 //  SockSrv=socket(AF_INET,SOCK_DGRAM,0);

   for(int i=0;i<iThreadNum; i++)
   {
       SockClient[i]=socket(AF_INET,Type,0);
	   if (SockClient[i]==INVALID_SOCKET)
	   {
	    ::MessageBox(NULL,TEXT("Create Socket error!"),TEXT("Socket Error"),0);
	   }

   }

   if (SockSrv==INVALID_SOCKET)
   {
   
   	   ::MessageBox(NULL,TEXT("Create Socket error!"),TEXT("Socket Error"),0);
       return;
   
   }


   addrSrv.sin_addr.S_un.S_addr=htonl(INADDR_ANY);
   addrSrv.sin_family=AF_INET;
   addrSrv.sin_port=htons(Port);




   err=bind(SockSrv,(SOCKADDR*)&addrSrv,sizeof(SOCKADDR));
   if (err==SOCKET_ERROR)
   {
      ::MessageBox(NULL,TEXT("Bind Socket error!"),TEXT("Socket Error"),0);
   }



}

Socket::~Socket()
{
   CloseHandle(HListenThread);
   WSACleanup();
   for (int i=0;i<iThreadNum;i++)
   {
     closesocket(SockClient[i]);
   }
   closesocket(SockSrv);
   CloseHandle(hCliEventT);

   	if (CliSendBuf)
	{
		delete[] CliSendBuf;
		CliSendBuf=NULL;
	} 
	if (CliRecBuf)
	{
	    delete[] CliRecBuf;
		CliRecBuf=NULL;
	}

}

bool Socket::StartClientSock()
{

	  char aa[500];
	  ConSrv.sin_addr.S_un.S_addr=inet_addr(CliIP);
      ConSrv.sin_family=AF_INET;
      ConSrv.sin_port=htons(32501); 
	  SoftPhoneParam thisParam;
	  int iCallNum,oCallNum;
	  char * temp=new char[500];
	  int len;
	 
	  for (int i=0;i<iThreadNum;i++)
	  {
		  /*
		 ConSrv.sin_addr.S_un.S_addr=inet_addr(CliIP);
         ConSrv.sin_family=AF_INET;
         ConSrv.sin_port=htons(32501);
		 */
		  if (connect(SockClient[i],(SOCKADDR*)&ConSrv,sizeof(SOCKADDR))<0)
		  {
			  closesocket(SockClient[i]);
			  SockClient[i]=socket(AF_INET,Type,0);
              if (connect(SockClient[i],(SOCKADDR*)&ConSrv,sizeof(SOCKADDR))<0)
			  {
			   OutputDebugString(TEXT("SockClient Connect fail...!!!!!!!!!!!!!!!!!!!!!!!!!\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
			  }
		  }
  ///////////////////////////////////////////////////////////////////////////      
		  /*
		  sprintf(aa,"%d", SockClient[i]);
		  MessageBoxA(NULL,aa,"Port",1);
		  */
		


		  DWORD targetThreadID;
		  HANDLE HCliThread;
		

		  thisParam.pCliSock=this;
		  thisParam.point=i;
          HCliThread=CreateThread(NULL,0,CliListenThread,&thisParam,0,&targetThreadID);
		  sprintf(aa, "Thread: %d created@@@@@@@@@@@@@@@@@@@@\n",i);
		  OutputDebugStringA(aa);
          

		  iCallNum=atoi(inNum)+i;
		  oCallNum=atoi(outNum)+i;


		  sprintf(temp,"%s","<socket-data>\ndomain=0\ntype=512\nevent=677\nsrc=Softphone</socket-data>\n");
		  len=strlen(temp);
		  send(SockClient[i],(char*)temp,len+1,0);
		  Sleep(200);


		  
		  sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=673\ndev=%d</socket-data>\n",oCallNum);
		  len=strlen(temp);
		  send(SockClient[i],(char*)temp,len+1,0);
		  
		  CloseHandle(HCliThread);
		  

	  }


      delete[] temp;
	  return true;

}


DWORD WINAPI Socket::CliListenThread(LPVOID Param)
{
	SoftPhoneParam*P=(SoftPhoneParam*)Param;
	SoftPhoneParam L=*P;
	int ipoint=P->point;
	P=&L;
	P->point=ipoint;
	char MessageBuf[1500];
	char* MessageBufp;
	char* temp=new char[1500];
	//char temp2[1500];
	int iLen;
	char* point;
	char aa[1500];
	temp[0]='\0';
	int iCallNum;
	int oCallNum;
	DWORD targetThreadID;
	HANDLE HCliReThread;
	char a[200];
	static bool ifsend=false;

	while(1)
	{
		OutputDebugString(TEXT("CliListenThread loop1...\n==========\n"));
        
		if(sfstarted==false)
		{
		  return 0;
		}

		iLen=recv(P->pCliSock->SockClient[P->point],MessageBuf,1000,0);
		if ((iLen<0)||(iLen==0))
		{    
//			   WaitForSingleObject(P->pCliSock->hCliEvent[P->point],INFINITE);
//               ResetEvent(P->pCliSock->hCliEvent[P->point]);  
			   closesocket(P->pCliSock->SockClient[P->point]);
               		
			   sprintf(a, "len: %d",P->point);
			   OutputDebugStringA(a);

			   Sleep(1000);
			//  MessageBoxA(NULL,"Can not connect1!","Alert",1);
			  if (connect(P->pCliSock->SockClient[P->point],(SOCKADDR*)&(P->pCliSock->ConSrv),sizeof(SOCKADDR))<0)
	          {

                  closesocket(P->pCliSock->SockClient[P->point]);
				  P->pCliSock->SockClient[P->point]=socket(AF_INET,P->pCliSock->Type,0);

				  //////////////////////////////////////////////////////////
				
				  if (connect(P->pCliSock->SockClient[P->point],(SOCKADDR*)&(P->pCliSock->ConSrv),sizeof(SOCKADDR))<0)
				  {
				   // MessageBoxA(NULL,"Can not connect2!","Alert",1);
					closesocket(P->pCliSock->SockClient[P->point]);
					delete[] temp;
					sfstarted=false;
//					SetEvent(P->pCliSock->hCliEvent[P->point]);

					OutputDebugString(TEXT("CliListenThread Exit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!...\n!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
					
					
					return 0;
				  }
				  	

			
	             
                 HCliReThread=CreateThread(NULL,0,CliReThread,P,0,&targetThreadID); 
				 Sleep(2000);

				 CloseHandle(HCliReThread);
			
			

/*
		          sprintf(temp2,"<socket-data>\ndomain=40960\ntype=512\nevent=673\ndev=%d</socket-data>\n",iCallNum);
		          send(P->pCliSock->SockClient[P->point],(char*)temp2,500,0);
				  */

 
	             
	          }
			  
		//	  SetEvent(P->pCliSock->hCliEvent[P->point]);
			  continue;

		}

		//MessageBoxA(NULL,temp1,"alert",1);
		
		MessageBuf[iLen]='\0';
		strcat(temp,MessageBuf);
		sprintf(MessageBuf,"%s",temp);
		temp[0]='\0';


	//	sprintf(aa,"%d",iLen);
	//	MessageBoxA(NULL,aa,"Alert",1);
	//	sprintf(temp1,"%s ip:%s:32501", MessageBuf,P->pCliSock->CliIP);
	//	sprintf(temp1,"%s ", P->pCliSock->CliIP);
	//	MessageBoxA(NULL,temp1,"Alert",1);
		MessageBufp=&MessageBuf[0];


		while (((point=strstr(MessageBufp,"</socket-data>"))-MessageBufp)>0)
		{
		//	char a[2000];
		//	sprintf(a, "len: %d",((point=strstr(MessageBuf,"</socket-data>"))-MessageBuf));
		//	OutputDebugStringA(a);

			strncpy(aa,MessageBufp,point-MessageBufp+14);
			aa[point-MessageBufp+14]='\0';
			MessageBufp=point+14;
			if(!ifsend)
			{
			 ifsend=true;
//			 SendMessage(P->pCliSock->Wnd,WM_SOCKR,(WPARAM)aa,0);
//			 PostMessage(P->pCliSock->Wnd,WM_SOCKR,(WPARAM)aa,0);
			 Sleep(500);
			}
			else
			{
			 ifsend=false;
			}
		
		}
       OutputDebugString(TEXT("CliListenThread loop2...\n==========\n"));
	 //  Sleep(500);

	
/*
		while (*MessageBuf=='\n')
		{
           	MessageBuf=MessageBuf+1;	
		}
		if(*MessageBuf) 
		{
	//		MessageBoxA(NULL,MessageBuf,"Alert",1);
			char aa[1000];
	//		sprintf(aa,"%s, len:%d",MessageBuf,strlen(MessageBuf));
	//		MessageBoxA(NULL,aa, "alert",1);
		    sprintf(temp,"%s",MessageBuf);
		}

 */





	}
    

	return 0;
}


DWORD WINAPI Socket::CliReThread(LPVOID Param)
{

	SoftPhoneParam*P=(SoftPhoneParam*)Param;
	SoftPhoneParam L=*P;
	P=&L;

	int iCallNum;
	int oCallNum;
	char* temp1=new char[800];

	OutputDebugString(TEXT("32501 Reconnected...\n==========\n"));
	iCallNum=atoi(inNum)+P->point;
	oCallNum=atoi(outNum)+P->point;
	
	sprintf(temp1,"%s","<socket-data>\ndomain=0\ntype=512\nevent=677\nsrc=Softphone</socket-data>\n");
	send(P->pCliSock->SockClient[P->point],(char*)temp1,500,0);
	Sleep(20*P->point);


	sprintf(temp1,"<socket-data>\ndomain=40960\ntype=512\nevent=673\ndev=%d</socket-data>\n",oCallNum);
	send(P->pCliSock->SockClient[P->point],(char*)temp1,500,0);
	

	Sleep(20*P->point);

	delete[] temp1;
	temp1=NULL;
	OutputDebugString(TEXT("Exit CliReThread...\n==========\n"));

	return 0;

}



bool Socket::StartListen()
{
   DWORD targetThreadID;
   HListenThread=CreateThread(NULL,0,ListenThread,this,0,&targetThreadID);

   CloseHandle(HListenThread);
   if(HListenThread==NULL)
   {
    ::MessageBox(NULL,TEXT("Create Socket thread error!"),TEXT("Socket Error"),0);
	return false;
   }

 return true;


}

DWORD WINAPI Socket::ListenThread(LPVOID Param)
{
   Socket*P=(Socket*)Param;

 
   SOCKADDR_IN addrIn;
   int len=sizeof(SOCKADDR);

    RecvSendInfo info;
	int i;

   while(1)
   {  
	   listen(P->SockSrv,5);
	   SOCKET sockConn=accept(P->SockSrv,(SOCKADDR*)&addrIn,&len);





	   for (i=0;i<10;i++)
	   {
		   if (!((P->SockArr[i]).conn))
		   {
			   (P->SockArr[i]).conn=true;
			   (P->SockArr[i]).conSock=sockConn;
			   break;
			   
		   }
	   }
	   if (i==10)
	   {
	     MessageBoxA(NULL,"Server busy! Please wait...", "Busy Message", 1);
		 closesocket(sockConn);
		 continue;

	   }
	   sprintf(P->CliIP,"%s", inet_ntoa(addrIn.sin_addr));
///////////////////////////////////////////////////////////////////////////////////////////////////////////
	//   MessageBoxA(NULL,P->CliIP, "Alert",0);
	    P->connected=true;
	//   SetEvent(P->hCliEvent);
       

	   HANDLE HReciSendThread;
	   HANDLE HCallThread;
	   DWORD targetThreadID;
	//   RecvSendInfo info;
	   info.conSock=sockConn;
	   info.pCliSock=P;
	   info.Addr_in=addrIn;
	   info.point=i;
	   HReciSendThread=CreateThread(NULL,0,ReceSendThread,&info,0,&targetThreadID);
	   ///////////////////////////////////////////////////////////////////////////////////////////////////////////

       if(!sfstarted)
	   {
	     SendMessage(P->Wnd,WM_SFS,0,0);
	   
	   }

	 //  SetEvent(P->hCliEventT);
	   CloseHandle(HReciSendThread);

	   //SendMessage(P->Wnd,WM_CALL,(WPARAM)&info,0);

	    HCallThread= CreateThread(NULL,0,CallThread,&info,0,&targetThreadID);

		CloseHandle(HCallThread);


	   //char sendBuf[50];
       // sprintf(P->ReceiIP,"%s",inet_ntoa(addrIn.sin_addr));
	   //send(sockConn,sendBuf,strlen(sendBuf)+1,0);
	   //char recvBuf[50];
	   //recv(sockConn,P->RecvBuf,1000,0);
	   //printf("%s\n",P->RecvBuf);


//	   a->ProcessData(P->RecvBuf);
//	   closesocket(sockConn);
		Sleep(100);
   }


  return 0;
}

DWORD WINAPI Socket::ReceSendThread(LPVOID Param)
{
  RecvSendInfo* pa=(RecvSendInfo*) Param;
  RecvSendInfo L=*pa;
  pa=&L;

  char* SendBuf=new char[500];
  char* MessageBuf=new char[500]; 
  unsigned char* RecvBuf=new unsigned char[1000] ; 
  unsigned char* temp=new unsigned char[1100] ; 
  char tmp[200];
  time_t t = time(0); 


  	HANDLE HSendThread;
	DWORD targetThreadID; 
  if(!RecvBuf)
  {
  	   ::MessageBox(NULL,TEXT("No sufficient memory!"),TEXT("Memory Error"),0);
       return -1;
  
  }
  int iLen;

  int i;

  RecvInfo rinfo;

  while(1)
  {

	  //	  FD_ZERO
	   OutputDebugString(TEXT("ReceSendThread loop1...\n==========\n"));
	  
	
	  iLen=recv(pa->conSock,(char*)RecvBuf,1000,0);
	  recnew=true;

	  if (iLen==0)
	  {
		  OutputDebugString(TEXT("ReceSendThread Exit1...\n==========\n"));
		  sprintf(MessageBuf,"Client:%s exit connection!",inet_ntoa((pa->Addr_in).sin_addr));


		  	if((logfp=fopen("log.txt","at+"))==NULL)
			{
				MessageBoxA(NULL, "Cannot open log file.\n","Alert",1);
			}
			else
		    { 
			 strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
			 fprintf(logfp,"%s, %s!!!!!!!!!!!!!!!! \n",tmp, MessageBuf);
			 
			}
			fclose(logfp);


		  Sleep(20000);
		//  MessageBoxA(NULL,MessageBuf,"Message",0);

		  if (RecvBuf)
		  {
			  delete[] RecvBuf;
			  RecvBuf=NULL;  
		  }

		  if (SendBuf)
		  {
			  delete[] SendBuf;
			  SendBuf=NULL;  
		  }

		  if (MessageBuf)
		  {
			  delete[] MessageBuf;
			  MessageBuf=NULL;  
		  }

          WaitForSingleObject(pa->pCliSock->hEvent,INFINITE);
          if (temp)
		  {
			  
		      ResetEvent(pa->pCliSock->hEvent);
			  delete[] temp;
			  temp=NULL;  
			 
		  }   
         

		  i=pa->point;
		  (pa->pCliSock->SockArr[i]).conn=false;
		  if(i==0)
		  {
			  sfstarted=false;
		  
		  }
		  SetEvent(pa->pCliSock->hEvent);

		  Sleep(1000);

		  closesocket(pa->conSock);
		  return 0;
	  }
	  else if(iLen<0)
	  {
		   OutputDebugString(TEXT("ReceSendThread Exit2...\n==========\n"));
		  sprintf(MessageBuf,"Please check if VisionCTI has exited!!! Receive message error, error number:%d,  Client:%s !",iLen,inet_ntoa((pa->Addr_in).sin_addr));
      //    MessageBoxA(NULL,MessageBuf,"Message",0);


		  	if((logfp=fopen("log.txt","at+"))==NULL)
			{
				MessageBoxA(NULL, "Cannot open log file.\n","Alert",1);
			}
			else
		    { 
			 strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
			 fprintf(logfp,"%s, %s!!!!!!!!!!!!!!!! \n",tmp, MessageBuf);
			 
			}
			fclose(logfp);



           Sleep(20000);
		  if (RecvBuf)
		  {
			  delete[] RecvBuf;
			  RecvBuf=NULL;  
		  }

		  if (SendBuf)
		  {
			  delete[] SendBuf;
			  SendBuf=NULL;  
		  }

		  if (MessageBuf)
		  {
			  delete[] MessageBuf;
			  MessageBuf=NULL;  
		  } 
		  
		  WaitForSingleObject(pa->pCliSock->hEvent,INFINITE);
           if (temp)
		  {
			 
		      ResetEvent(pa->pCliSock->hEvent);
			  delete[] temp;
			  temp=NULL;  
			  
		  }



		  i=pa->point;
		  (pa->pCliSock->SockArr[i]).conn=false;  

		   if(i==0)
		  {
			  sfstarted=false; 
		  }
		  
		  SetEvent(pa->pCliSock->hEvent);

		//  Sleep(1000);

          closesocket(pa->conSock);
		  return 0;
	  }
	  else
	  {		 
		// HANDLE HSendThread;
		// DWORD targetThreadID; 
         if (iLen>1000)  MessageBoxA(NULL,"Message too long","alert",0);
	//	 WaitForSingleObject(pa->pCliSock->hEvent,INFINITE);
	//	 ResetEvent(pa->pCliSock->hEvent);
		 memcpy(temp,RecvBuf,iLen);
         ResetEvent((pa->pCliSock->SockArr[pa->point]).hHandleReceEvnet);
///////////////////////////////////////////////////////////////////////////////
		 


		 rinfo.RecvLen=iLen;
		 rinfo.SockInfo=pa;
		 rinfo.buffer=temp;

		
		HSendThread=CreateThread(NULL,0,HandleReceThread,&rinfo,0,&targetThreadID);
		SetThreadPriority(HSendThread,14);

	
		
	//	SetEvent(pa->pCliSock->hEvent);
		Sleep(50);
	   
		CloseHandle(HSendThread);
		
	//    WaitForSingleObject(pa->pCliSock->hEvent,INFINITE);
	//	SetEvent(pa->pCliSock->hEvent); 
	//	WaitForSingleObject((pa->pCliSock->SockArr[pa->point]).hHandleReceEvnet,INFINITE);
/*	 
		  char* temp=new char[4000];
		  memset(temp,0,4000);

		  int i;
		  char *t=new char[16];

		  if ((RecvBuf)&&(iLen>0))
		  {
			  for(i=0;i<iLen;i++)
			  {
				  memset(t,0,16);
				  sprintf(t, " %02X", RecvBuf[i]); 
				  t[5]='\0';
	//			  MessageBoxA(NULL,t,"ff",0);
				  sprintf(temp,"%s%s",temp,t);

			  }

		  }

		  sprintf(temp,"%s ip:%s", temp,inet_ntoa((pa->Addr_in).sin_addr));
	  	  SendMessage(pa->pCliSock->Wnd,WM_SOCKR,(WPARAM)temp,0);



//		   send(pa->conSock,(char*)RecvBuf,iLen+1,0);

   	       delete[] temp;
		   delete[] t;
		   */
	  }
       OutputDebugString(TEXT("ReceSendThread loop2...\n==========\n"));


  }

 delete[] SendBuf;
 delete[] MessageBuf; 
 delete[] RecvBuf;
 return 1;

}




DWORD WINAPI Socket::HandleReceThread(LPVOID Param)
{

    OutputDebugString(TEXT("Enter HandleReceThread...\n==========\n"));
	recnew=false;
	static int controldisplay=1;

	RecvInfo* P=(RecvInfo*)Param;
	RecvInfo L=*P;
	P=&L;

	int len=P->RecvLen;
	RecvSendInfo*Ps=P->SockInfo;
	unsigned char* RBuf=new unsigned char[1100] ; 
	
	ResetEvent(P->SockInfo->pCliSock->hEvent);
	memcpy(RBuf,P->buffer,1000);
	SetEvent(P->SockInfo->pCliSock->hEvent);


//	SetEvent((P->SockInfo->pCliSock->SockArr[P->SockInfo->point]).hHandleReceEvnet);
	


//	WaitForSingleObject(P->SockInfo->pCliSock->hEvent,INFINITE);
//	

	char* temp=new char[5100];
	memset(temp,0,5100);

	int i;
	char *t=new char[16];

	if ((RBuf)&&(len>0))
	{
		for(i=0;i<len;i++)
		{
			memset(t,0,16);
			sprintf(t, " %02X", RBuf[i]); 
			t[5]='\0';
			//			  MessageBoxA(NULL,t,"ff",0);
			sprintf(temp,"%s%s",temp,t);

		}

	}

	sprintf(temp,"%s ip:%s", temp,inet_ntoa((Ps->Addr_in).sin_addr));
	on_cti_msg_recv_func((char*)RBuf, len, P);
	if (recnew)
	{
	 delete[] t;
	 delete[] RBuf;
	 delete[] temp;
	 temp=NULL;
	  return 0;
	}
	if(!((controldisplay+7)%8))
	{
	SendMessage(Ps->pCliSock->Wnd,WM_SOCKR,(WPARAM)temp,0);
	
	}
	controldisplay++;

	
  
  //  Sleep(100);

	OutputDebugString(TEXT("Exit HandleReceThread...\n==========\n"));

	//		   send(pa->conSock,(char*)RecvBuf,iLen+1,0);


	delete[] t;
	delete[] RBuf;
	delete[] temp;
	temp=NULL;

	return 1;

}



bool Socket::SendTo(const char* ContactIP)
{

  SOCKADDR_IN addrSrv;
  addrSrv.sin_addr.S_un.S_addr=inet_addr(ContactIP);
  addrSrv.sin_family=AF_INET;
  addrSrv.sin_port=htons(Port);
//  connect(SockClient,(SOCKADDR*)&addrSrv,sizeof(SOCKADDR));
 // send(SockClient,CliSendBuf,1000,0);
  //char recvBuf[50];
  //recv(sockClient,recvBuf,50,0);
  //printf("%s\n",recvBuf);
  
//  closesocket(SockClient);
  return true;

}


DWORD WINAPI Socket::CallThread(LPVOID Param)
{
	RecvSendInfo* pa=(RecvSendInfo*) Param;
	RecvSendInfo L=*pa;
	pa=&L;
	SendMessage(pa->pCliSock->Wnd,WM_CALL,(WPARAM)pa,0);
	Sleep(100);
	return 1;


}