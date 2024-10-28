#include "stdafx.h"

#include "sockvrs.h"


SockVRSClient::SockVRSClient(char*ipaddr, int portn):port(portn)
{
	//sprintf(ipadd,ipaddr);
	strcpy(ipadd,ipaddr);
	int a=1;

    for(int i=0;i<iThreadNum; i++)
    {
       SockClient[i]=socket(AF_INET,SOCK_STREAM,0);
	   if (SockClient[i]==INVALID_SOCKET)
	   {
	    ::MessageBox(NULL,TEXT("Create Socket error!"),TEXT("Socket Error"),0);
	   }
	   setsockopt(SockClient[i],SOL_SOCKET,SO_KEEPALIVE,(char*)&a,4);

	   

    }


	 for (int i=0;i<iThreadNum;i++)
	  {
	    bAddr[i]=false;
		porttag[i]=0;
	  
	  }

     


}

SockVRSClient::~SockVRSClient()
{
	for(int i=0;i<iThreadNum; i++)
    {
	   closesocket(SockClient[i]);
    }

}

int SockVRSClient::Connect()
{

  
	  char aa[500];
	  ConSrv.sin_addr.S_un.S_addr=inet_addr(ipadd);
      ConSrv.sin_family=AF_INET;
      ConSrv.sin_port=htons(port); 
	  VrsParam thisParam;
	  int iCallNum,oCallNum;
	  char * temp=new char[500];
	  int len;
     
	  

	 
	  for (int i=0;i<iThreadNum;i++)
	  {

		  if (connect(SockClient[i],(SOCKADDR*)&ConSrv,sizeof(SOCKADDR))<0)
		  {
			  closesocket(SockClient[i]);
			  SockClient[i]=socket(AF_INET,SOCK_STREAM,0);
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
		

		  thisParam.pVrsSock=this;
		  thisParam.point=i;
          HCliThread=CreateThread(NULL,0,VrsListenThread,&thisParam,0,&targetThreadID);
		  sprintf(aa, "VRS Thread: %d created####################\n",i);
		  OutputDebugStringA(aa);
           Sleep(200);
	
		  CloseHandle(HCliThread);

		 
		  

	  }


      delete[] temp;
	  return true;


}


DWORD WINAPI SockVRSClient::VrsListenThread(LPVOID Param)
{
	VrsParam*P=(VrsParam*)Param;
	VrsParam L=*P;
	int ipoint=P->point;
	P=&L;
	P->point=ipoint;
	char MessageBuf[2001];
	char* MessageBufp;
	char temp[50];
	//char temp2[1500];
	int iLen;
	char* point;
	temp[0]='\0';

	char a[200];
	porttag[P->point]=0;
	int sdfnum=0;
	char tmp[64];
    static int rOK=0;
	static int rPort=0;
	char* oldpoint;

	char tt[100];


	char temtt[100];



	while(1)
	{
		OutputDebugString(TEXT("VrsListenThread loop1...\n==========\n"));
        

		memset(MessageBuf, 0, sizeof(MessageBuf));
		iLen=recv(P->pVrsSock->SockClient[P->point],MessageBuf,2000,0);

		if ((iLen<0)||(iLen==0))
		/*
		{
		 Sleep(2000);
		 continue;
		
		}
		
        
		sprintf(temtt,"iLen:%d,   parseLen:%d", iLen, strlen(MessageBuf));
		OutputDebugStringA(temtt);
		*/
		/*
		if(iLen<strlen(MessageBuf))
		{
		
		  		  if((logfp=fopen("log.txt","at+"))==NULL)
				   {
					   MessageBoxA(NULL, "Cannot open log file.\n","Alert2",1);
				   }
				   else
				   {
					    time_t t = time(0);       
	                    strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
						fprintf(logfp,"%s, VRS thread %d received \\0:)\n",tmp, P->point);

				   }

				   fclose(logfp);	
		
		
		
		}
		*/
 //////////////////////        Long connect
		{    

			   closesocket(P->pVrsSock->SockClient[P->point]);
               		
			   sprintf(a, "len: %d",P->point);
			   OutputDebugStringA(a);
			   if((logfp=fopen("log.txt","at+"))==NULL)
			   {
				  MessageBoxA(NULL, "Cannot open log file.\n","Alert2",1);
			    }
				else
				{
					  time_t t = time(0);  
	           //         char tmp[64];
	                  strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
					  fprintf(logfp,"%s, VRS thread %d connect terminate,reconnecting...\n",tmp, P->point);

				 }

			    Sleep(1000);
			//  MessageBoxA(NULL,"Can not connect1!","Alert",1);
			   if (connect(P->pVrsSock->SockClient[P->point],(SOCKADDR*)&(P->pVrsSock->ConSrv),sizeof(SOCKADDR))<0)
			   {

				   closesocket(P->pVrsSock->SockClient[P->point]);




				   fclose(logfp);	  


				   Sleep(6000);

				   P->pVrsSock->SockClient[P->point]=socket(AF_INET,SOCK_STREAM,0);


				  //////////////////////////////////////////////////////////
				
				  if (connect(P->pVrsSock->SockClient[P->point],(SOCKADDR*)&(P->pVrsSock->ConSrv),sizeof(SOCKADDR))<0)
				  {
				   // MessageBoxA(NULL,"Can not connect2!","Alert",1);
					closesocket(P->pVrsSock->SockClient[P->point]);
	//					SetEvent(P->pCliSock->hCliEvent[P->point]);
                   
				
					OutputDebugString(TEXT("CliListenThread Exit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!...\n!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
					
					
					continue;
				  }
				  	

			

			

	             
	          }
		//	  send(P->pVrsSock->SockClient[P->point],P->pVrsSock->msgarry[P->point],1500,0);
			  
		//	  SetEvent(P->pCliSock->hCliEvent[P->point]);
			  continue;

		}




		//MessageBoxA(NULL,temp1,"alert",1);
		
		temp[0]='\0';

		char *p;
		int iplen;


		MessageBufp=&MessageBuf[0];
	//	OutputDebugStringA(MessageBuf);





		if (((point=strstr(MessageBufp,"IN IP4 "))-MessageBufp)>0)
		{
            point=point+7;
			p= min(strchr(point,'\r\n'),strchr(point,' '));

			iplen=p-point;
			if (iplen>0)
			{
				strncpy(P->pVrsSock->RecordIP,point,iplen);
				P->pVrsSock->RecordIP[iplen]='\0';
			//	 MessageBoxA(NULL, P->pVrsSock->RecordIP, "Alert",0);

			}	
			else
			{
			  //MessageBoxA(NULL,"Cross package!!!","Alert",1);
			}


		}

         oldpoint=&MessageBufp[0];

		while (((point=strstr(oldpoint,"0 OK"))-oldpoint)>0)
		{
			rOK++;
			oldpoint=point+4;
			sprintf(tt,"OK message number:%d\n",rOK);
			OutputDebugStringA(tt);
		}

	


	//	while(((point=strstr(MessageBufp,"m=audio "))-MessageBufp)>0)
		while(((point=strstr(MessageBufp,"dio "))-MessageBufp)>0)
		{
		//	point=point+8;
            point=point+4;
			p= min(strchr(point,'\r\n'),strchr(point,' '));
			iplen=p-point;
			MessageBufp=p;


			rPort++;
			sprintf(tt,"Port message number:%d\n",rPort);
			OutputDebugStringA(tt);
			
			if (p>point)
			{

			  if (porttag[P->point]==0)
			  {
				strncpy(temp,point,iplen);
				P->pVrsSock->RecordPort[P->point][0]=atoi(temp);
	//			P->pVrsSock->bAddr[P->point]=true;
   //             MessageBoxA(NULL, temp, "Alert",0);
		//		porttag[P->point]=0;
				porttag[P->point]++;
/*
				  if((logfp=fopen("log.txt","at+"))==NULL)
				   {
					   MessageBoxA(NULL, "Cannot open log file.\n","Alert2",1);
				   }
				   else
				   {
					    time_t t = time(0);       
	                    strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
						fprintf(logfp,"%s, VRS thread %d port1: %d\n",tmp, P->point,atoi(temp));

				   }
                   fclose(logfp);
*/
				}
				else
				{

					strncpy(temp,point,iplen);
				    P->pVrsSock->RecordPort[P->point][1]=atoi(temp);
					porttag[P->point]=0;
					P->pVrsSock->bAddr[P->point]=true;
/*
					if((logfp=fopen("log.txt","at+"))==NULL)
				   {
					   MessageBoxA(NULL, "Cannot open log file.\n","Alert2",1);
				   }
				   else
				   {
					    time_t t = time(0);       
	                    strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
						fprintf(logfp,"%s, VRS thread %d port2: %d\n",tmp, P->point,atoi(temp));

				   }
					fclose(logfp);
*/
				
				
				}




			}
			else
			{


				   if((logfp=fopen("log.txt","at+"))==NULL)
				   {
					   MessageBoxA(NULL, "Cannot open log file.\n","Alert2",1);
				   }
				   else
				   {
					    time_t t = time(0);       
	                    strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
						fprintf(logfp,"%s, VRS thread %d received part package, normal miss recording :)\n",tmp, P->point);

				   }

				   fclose(logfp);	 
	
			}
          

		}

		if ((((point=strstr(MessageBufp,"m=aud"))-MessageBufp)>0)
			||(((point=strstr(MessageBufp,"m=audi"))-MessageBufp)>0))
		{
					   
				   if((logfp=fopen("log.txt","at+"))==NULL)
				   {
					   MessageBoxA(NULL, "Cannot open log file.\n","Alert2",1);
				   }
				   else
				   {
			            time_t t = time(0);       
	                    strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
						fprintf(logfp,"%s, VRS thread %d received part package, normal miss recording 1:)\n",tmp, P->point);
				   }
				   fclose(logfp);
		
		}

	}
  

	return 0;
}
