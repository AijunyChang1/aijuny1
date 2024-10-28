// testmainDlg.cpp : 实现文件
//

#include "stdafx.h"
#include "testmain.h"
#include "testmainDlg.h"
//#include "Socket.h"
#include "..\..\testdll\testdll\lib.h"
#include "sockudpclient.h"




// CtestmainDlg 对话框





CtestmainDlg::CtestmainDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CtestmainDlg::IDD, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CtestmainDlg::DoDataExchange(CDataExchange* pDX)
{
	DDX_Text(pDX,IDC_STATIC,DisplayNum);
	DDX_Text(pDX,IDC_Port,iPort);
	//DDX_Text(pDX,IDC_EDIT_RECV,RecDisplay);
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CtestmainDlg, CDialog)
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	//}}AFX_MSG_MAP
	ON_BN_CLICKED(IDOK, &CtestmainDlg::OnBnClickedOk)
	ON_EN_CHANGE(IDC_EDIT2, &CtestmainDlg::OnEnChangeEdit2)
	ON_MESSAGE(WM_SOCKR,OnSocketServer)
	ON_MESSAGE(WM_CALL,OnCall)
	ON_MESSAGE(WM_SFS, SFStart)
	ON_BN_CLICKED(IDC_BUTTON1, &CtestmainDlg::OnBnClickedButton1)
	ON_BN_CLICKED(IDC_BUTTON2, &CtestmainDlg::OnBnClickedButton2)
	ON_BN_CLICKED(IDC_SOFT_CALL, &CtestmainDlg::OnBnClickedSoftCall)
	ON_BN_CLICKED(IDC_BUTTON3, &CtestmainDlg::OnBnClickedButton3)
	ON_BN_CLICKED(IDCANCEL, &CtestmainDlg::OnBnClickedCancel)
	ON_BN_CLICKED(IDC_BUTTON4, &CtestmainDlg::OnBnClickedButton4)
END_MESSAGE_MAP()


// CtestmainDlg 消息处理程序

BOOL CtestmainDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// 设置此对话框的图标。当应用程序主窗口不是对话框时，框架将自动
	//  执行此操作
	SetIcon(m_hIcon, TRUE);			// 设置大图标
	SetIcon(m_hIcon, FALSE);		// 设置小图标


	// TODO: 在此添加额外的初始化代码
//	Socket* Sock;
    iPort=42027;   //UCCE port
	SockVrs=NULL;
//	Sock=new Socket(this->GetSafeHwnd(),iPort,SOCK_STREAM);
//	Sock->StartListen();
	hCallidEvent=CreateEvent(NULL,FALSE,TRUE,NULL);
	sfstarted=false;
   
	FILE* fp;
    if((fp=fopen("config.dat","r"))==NULL)
	{
		MessageBoxA(NULL, "Cannot open config file.\n","Alert",1);
        
        //return;
    }
	else
	{
		char buf[50];
		fscanf(fp,"%s",buf);
	    callid=atoi(buf);
	    fclose(fp);
		OutputDebugStringA(buf);
	}

	firstcallid=callid;
	
	((CEdit*)GetDlgItem(IDC_NUM1))->SetWindowTextW(TEXT("1200"));
	((CEdit*)GetDlgItem(IDC_NUM2))->SetWindowTextW(TEXT("1000"));
	((CEdit*)GetDlgItem(IDC_EDIT4))->SetWindowTextW(TEXT("100"));
   

	 if((logfp=fopen("log.txt","at+"))==NULL)
	 {
		 MessageBoxA(NULL, "Cannot open log file.\n","Alert",1);
    }
	 else
	 {
	 
      time_t t = time(0);  
	  char tmp[64];
	  fprintf(logfp,"===========================================================================\n");
	  strftime(tmp, sizeof(tmp), "Start testing:          Date: %a, %d %b %Y %X GMT\n",localtime(&t));
	  fprintf(logfp,tmp);
	  fprintf(logfp,"===========================================================================\n");
      fclose(logfp);
	 }
    


//	Sock=new Socket(this->GetSafeHwnd(),iPort,SOCK_STREAM);
	UpdateData(false);

	return TRUE;  // 除非将焦点设置到控件，否则返回 TRUE
}

// 如果向对话框添加最小化按钮，则需要下面的代码
//  来绘制该图标。对于使用文档/视图模型的 MFC 应用程序，
//  这将由框架自动完成。

void CtestmainDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // 用于绘制的设备上下文

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// 使图标在工作矩形中居中
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// 绘制图标
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

//当用户拖动最小化窗口时系统调用此函数取得光标显示。
//
HCURSOR CtestmainDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
	//this->GetDlgItem(1)->GetWindowText();
}


void CtestmainDlg::OnBnClickedOk()
{
	UpdateData(TRUE);
	TCHAR* a=new TCHAR[50];
	_stprintf(a,TEXT("Result: %d"),add(2,3));
	// TODO: 在此添加控件通知处理程序代码
//	MessageBox(a,TEXT("Hello"),1);
	DisplayNum=add(2,3);

 //   Sock=new Socket(this,iPort,SOCK_STREAM);


	UpdateData(FALSE);
//	OnOK();
//	GetDlgItem(IDC_STATIC)->
}

void CtestmainDlg::OnEnChangeEdit2()
{
	// TODO:  如果该控件是 RICHEDIT 控件，则它将不会
	// 发送该通知，除非重写 CDialog::OnInitDialog()
	// 函数并调用 CRichEditCtrl().SetEventMask()，
	// 同时将 ENM_CHANGE 标志“或”运算到掩码中。

	// TODO:  在此添加控件通知处理程序代码
}

/*
int CtestmainDlg::ProcessData(char* a)
{
	if (!a)
	{
	  MessageBox(TEXT("No data received"),TEXT("Process receiced data error"),0);
	  return 0;
	}

	return 0;
}
*/
LRESULT CtestmainDlg::OnSocketServer(WPARAM wParam, LPARAM lParam)
{
//	UpdateData(true);
    char*Mg;
//	static int line=0;
	Mg=(char*)wParam;
	USES_CONVERSION;
	CString temp;
	wchar_t aa[5100];
	memcpy(aa,A2W(Mg),5050);
	aa[5051]=TEXT('\0');
	int n;

	//_stprintf(aa,TEXT("%s"),A2W(Mg));
	temp=aa;
	RecDisplay=temp+TEXT("\r\n")+RecDisplay;
	line=line+1;

	if (line>200)
	{
//	line=200;
	 n= RecDisplay.ReverseFind(TEXT('\r\n'));
	RecDisplay= RecDisplay.Left(n-1);
	}


//	RecDisplay=RecDisplay+aa+TEXT("\r\n");	
//	UpdateData(false);
//	
	if(!((line+14)%15))
	{
	GetDlgItem(IDC_EDIT_RECV)->SetWindowText(RecDisplay);
	if(line>400) line=200;
	}
//   UpdateData(true);
//	_stprintf(aa,TEXT("Message:%s"),aa);
//	MessageBox(RecDisplay,TEXT("Message"),0);

return 0;


}

LRESULT CtestmainDlg::OnCall(WPARAM wParam, LPARAM lParam)
{
//	UpdateData(true);
    RecvSendInfo*Mg;
	RecvSendInfo L;
	Mg=(RecvSendInfo*)wParam;
	L=*Mg;

	//char aa[50];
	//sprintf(aa,"%d",L.point);
//	sprintf(aa,"%d",iThreadNum);
	ThParam Lp;

	Lp.resInfo=L;

//	MessageBoxA(NULL,aa,"test",1);


	DWORD targetThreadID;
	HANDLE  HCallThread;



	HCallThread=CreateThread(NULL,0,MakeCallThread,&Lp,0,&targetThreadID);
/*
	for (int i=0;i<iThreadNum;i++)
	{
		Lp.threadnum=i;
		HCallThread=CreateThread(NULL,0,CallThread,&Lp,0,&targetThreadID);
		CloseHandle(HCallThread);
		Sleep(1000);
	}
	*/
    Sleep(100);
	CloseHandle(HCallThread);

//	GetDlgItem(IDC_EDIT_RECV)->SetWindowText(RecDisplay);

//	_stprintf(aa,TEXT("Message:%s"),aa);
//	MessageBox(RecDisplay,TEXT("Message"),0);

return 0;


}


DWORD WINAPI CtestmainDlg::MakeCallThread(LPVOID Param)
{
	ThParam*Mg;
	Mg=(ThParam*)Param;
	ThParam Lp;
	Lp=*Mg;

	DWORD targetThreadID;
	HANDLE  HCallThread;
	SockVrs=new SockVRSClient(VrsIP,5060);
	SockVrs->Connect();

	for (int i=0;i<iThreadNum;i++)
	{
		Lp.threadnum=i;
		HCallThread=CreateThread(NULL,0,CallThread,&Lp,0,&targetThreadID);
		SetThreadPriority(HCallThread,13);
		Sleep(1000);
		CloseHandle(HCallThread);
	}
    Sleep(100);
//	GetDlgItem(IDC_EDIT_RECV)->SetWindowText(RecDisplay);

//	_stprintf(aa,TEXT("Message:%s"),aa);
//	MessageBox(RecDisplay,TEXT("Message"),0);

return 0;




}

void CtestmainDlg::OnBnClickedButton1()
{
	
	RecDisplay.Empty();
	line=0;
    UpdateData(false);
	// TODO: 在此添加控件通知处理程序代码
}

DWORD WINAPI CtestmainDlg::CallThread(LPVOID Param)
{
	ThParam*Mg;
	Mg=(ThParam*)Param;
	ThParam K;
	K=*Mg;
	RecvSendInfo L;
	int lcallid;

	char aiNum[30];
	char aoNum[30];
	int threadnum=K.threadnum;
    sprintf(aiNum,"%d",atoi(inNum)+threadnum);
	sprintf(aoNum,"%d",atoi(outNum)+threadnum);




	char aa[50];
	sprintf(aa,"%d",threadnum);
//	MessageBoxA(NULL,aa,"test",1);



	L=K.resInfo;
	int i=L.point;
	sprintf(aa,"%d",i);
	OutputDebugStringA(aa);

	int a=1;
    time_t t;       
	char tmp[50];
 
	int stopflag=1;
    
	//MessageBoxA(NULL,aa,"test",1);
	//Sleep(50);
	
	
	while (1)
	{
		OutputDebugString(TEXT("CallThread loop1...\n==========\n"));

		if(sfstarted==false) 
		{
			OutputDebugString(TEXT("Softphone exit!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n==========\n"));
		}

		//	MessageBoxA(NULL,aa,"test",1);
		if(((L.pCliSock)->SockArr[i]).conn)
		{
			WaitForSingleObject(hCallidEvent,INFINITE);
		    ResetEvent(hCallidEvent);
		    callid=callid+1;
		    lcallid=callid;
		    SetEvent(hCallidEvent);
/*  Short
			SockVrs->SockClient[threadnum]=socket(AF_INET,SOCK_STREAM,0);
			if (SockVrs->SockClient[threadnum]==INVALID_SOCKET)
			{
				::MessageBox(NULL,TEXT("Create Socket error!"),TEXT("Socket Error"),0);
			}
			setsockopt(SockVrs->SockClient[threadnum],SOL_SOCKET,SO_KEEPALIVE,(char*)&a,4);

		//	stopflag=(callid-firstcallid)/5000;



			if (connect(SockVrs->SockClient[threadnum],(SOCKADDR*)&(SockVrs->ConSrv),sizeof(SOCKADDR))<0)
		   {
			  closesocket(SockVrs->SockClient[threadnum]);
			  SockVrs->SockClient[threadnum]=socket(AF_INET,SOCK_STREAM,0);
              if (connect(SockVrs->SockClient[threadnum],(SOCKADDR*)&(SockVrs->ConSrv),sizeof(SOCKADDR))<0)
			  {

			   	t = time(0);       
	            strftime(tmp, sizeof(tmp), "Time: %a, %d %b %Y %X GMT",localtime(&t));
				fprintf(logfp,"%s, VRS Socket thread %d can not connect\n",tmp, threadnum);
			    OutputDebugString(TEXT("VRS SockClient Connect fail...!!!!!!!!!!!!!!!!!!!!!!!!!\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"));
			  }
		   }
Short*/
        	if (((lcallid-firstcallid)>(stopflag*10000)) && ((lcallid-firstcallid)<(stopflag*10000+iThreadNum+1)))
			{
			   Sleep(1800000);
			   stopflag++;

			  
			}

			on_begin_call_event(L,aiNum,aoNum,lcallid);
			on_call_delivered_event(L,aiNum,aoNum,lcallid);
			on_rtp_started_event(L,aiNum,aoNum,lcallid);

			Sleep(3000);
			on_call_established_event(L,aiNum,aoNum,lcallid);

			on_invite_vrs(K,aiNum,aoNum,lcallid);

			Sleep(10000+sqrt((double)threadnum*9)*1000+threadnum);
			on_conn_clear_event(L,aiNum,aoNum,lcallid);
			on_end_call_event(L,aiNum,aoNum,lcallid);
			on_end_vrs(K,aiNum,aoNum,lcallid);
			Sleep(1000);
//Short			closesocket(SockVrs->SockClient[threadnum]);
			Sleep(5000);
	
		}	
		else
		{
          OutputDebugString(TEXT("Exit CallThread loop2...!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n==========\n"));
		  return 0;
		}
		OutputDebugString(TEXT("CallThread loop2...\n==========\n"));

	}

     return 0;
}
void CtestmainDlg::OnBnClickedButton2()
{
	// TODO: 在此添加控件通知处理程序代码
	CEdit* editNum1;
	CEdit* editNum2;
	CEdit* editTNum;
	CButton* butStart;

	CIPAddressCtrl* VrsIpAddress;
	byte fd1,fd2,fd3,fd4;


	wchar_t in[30];
	wchar_t out[30];
	wchar_t thnum[30];

	static bool running=false;
	butStart=(CButton*)GetDlgItem(IDC_BUTTON2);
	butStart->SetWindowTextW(TEXT("正在测试..."));
	if (running)
	{
        
	
		MessageBox(TEXT("测试已经启动!"),TEXT("Alert"),1);

	}
	else
	{
	
		editNum1=(CEdit*)GetDlgItem(IDC_NUM1);
		editNum1->GetWindowTextW(in,30);
	//	MessageBox(in,TEXT("test"),0);
		editNum2=(CEdit*)GetDlgItem(IDC_NUM2);
		editNum2->GetWindowTextW(out,30);

		editTNum=(CEdit*)GetDlgItem(IDC_EDIT4);
		editTNum->GetWindowTextW(thnum,30);
	



		USES_CONVERSION;
		//inNum=new char[30];
		//outNum=new char[30];

		sprintf(inNum,"%s",W2A(in));
	//	MessageBoxA(NULL,inNum,"alert",0);
		sprintf(outNum,"%s",W2A(out));
		iThreadNum=atoi(W2A(thnum));

		if (iThreadNum==0) iThreadNum=1;

		
		CString tempString;
		tempString=inNum;
		tempString.Trim();

		//char aa[30];
		//sprintf(aa,"%d",tempString.Empty());
		//MessageBoxA(NULL,aa,"Alert",1);

  //      

		if (editNum1->GetWindowTextLength()<2)
		{
		  MessageBox(TEXT("请输入呼入电话号码!"),TEXT("Alert"),1);
		  return;
		}

        if (editNum2->GetWindowTextLength()<2) 
		{
		  MessageBox(TEXT("请输入呼出电话号码!"),TEXT("Alert"),1);
		  return;
		}


        VrsIpAddress=(CIPAddressCtrl*)GetDlgItem(IDC_IPADDRESS1);
		VrsIpAddress->GetAddress(fd1,fd2,fd3,fd4);

		sprintf(VrsIP, "%d.%d.%d.%d",fd1,fd2,fd3,fd4);

		//MessageBoxA(NULL,VrsIP,"Alert", 0);




		running=true;
		Sock=new Socket(this->GetSafeHwnd(),iPort,SOCK_STREAM);
		Sock->StartListen();



	}


}


LRESULT CtestmainDlg::SFStart(WPARAM wParam, LPARAM lParam)
{

		HANDLE HCallThread;
		DWORD targetThreadID;
        HCallThread=CreateThread(NULL,0,StartCliSockThread,this,0,&targetThreadID);
		CloseHandle(HCallThread);
		
		return 0;

}




DWORD WINAPI CtestmainDlg::StartCliSockThread(LPVOID Param)
{      
	    OutputDebugString(TEXT("StartCliSockThread...\n==========\n"));

	     sfstarted=true;
		 
	     CtestmainDlg* dlg=  (CtestmainDlg*) Param;
		 char temp[500];
 	     sprintf(temp,"%s","<socket-data>\ndomain=0\ntype=512\nevent=677\nsrc=Softphone</socket-data>\n");
		// sprintf(temp,"%s","aaa");
		// WaitForSingleObject(dlg->Sock->hCliEventT,INFINITE);
		 dlg->Sock->StartClientSock();

//		 SetEvent(dlg->Sock->hCliEventT);
		 Sleep(3000);
		 int len;
		 len=strlen(temp);
		 for(int i=0;i<iThreadNum;i++)
		 {
		     send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
		 }
       
         CWnd *tempButton=dlg->GetDlgItem(IDC_SOFT_CALL);
		 tempButton->EnableWindow(true);

		 int iCallNum, oCallNum;

		 int i,j;


//		 Sleep(1000);
//		 iThreadNum=1;
/*
		 for (i=0;i<iThreadNum;i++)
		 {
		  iCallNum=atoi(inNum)+i;
		  oCallNum=atoi(outNum)+i;
		  sprintf(temp,"%s","<socket-data>\ndomain=0\ntype=512\nevent=677\nsrc=Softphone</socket-data>\n");
		  len=strlen(temp);
		  send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
		  Sleep(1000);


		  
		  sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=673\ndev=%d</socket-data>\n",iCallNum);
		  len=strlen(temp);
		  send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);

		//  sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=673\ndev=%d</socket-data>\n",oCallNum);
		//  send(dlg->Sock->SockClient[i],(char*)temp,500,0);
		 
		 
		 }
		 */
       //  Sleep(1000);
		 while (1)
		 {
		//	 WaitForSingleObject(dlg->Sock->hCliEvent,INFINITE);
			  OutputDebugString(TEXT("StartCliSockThread Loop1...\n==========\n"));

			  	 if(sfstarted==false)
				 {

				   for(j=0;j<iThreadNum;j++)
				   {
					   closesocket(dlg->Sock->SockClient[j]);
				   }
				   if((dlg->Sock->SockArr[0]).conn)
				   {
					   Sleep(20000);
					   ResetEvent(dlg->Sock->hCliEventT);
			 	     ::SendMessage(dlg->m_hWnd,WM_SFS,0,0);
					  //WaitForSingleObject(dlg->Sock->hCliEventT,INFINITE);
					  
				   }
				   return 0;
				 
				 }
	
			  for (i=0;i<iThreadNum;i++)
			  {
		//		 WaitForSingleObject(dlg->Sock->hCliEvent[i],INFINITE);

				 
				 iCallNum=atoi(inNum)+i;
				 oCallNum=atoi(outNum)+i;
				 
				 sprintf(temp,"<socket-data>\ndomain=0\ntype=512\nevent=678\nsrc=%s:%d</socket-data>\n",SerIP,dlg->Sock->SockClient[i]);
				 len=strlen(temp);
				 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);

                 Sleep(300);
				 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=529\ndev=%d</socket-data>\n",oCallNum);
				 len=strlen(temp);
				 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);

			//	 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=529\ndev=%d</socket-data>\n",oCallNum);
			//	 send(dlg->Sock->SockClient[i],(char*)temp,500,0);
			


			 }

             OutputDebugString(TEXT("StartCliSockThread Loop2...\n==========\n"));
			 Sleep(30000/sqrt((float)iThreadNum));
             OutputDebugString(TEXT("StartCliSockThread Loop3...\n==========\n"));
		 
		 
		 }


		 return 0;


}
void CtestmainDlg::OnBnClickedSoftCall()
{
	// TODO: 在此添加控件通知处理程序代码

		HANDLE HCallThread;
		DWORD targetThreadID;
		static int ins=0;

		char temp[10];
		ins++;
		sprintf(temp,"%d", ins);
		CString a;
		a=TEXT("软电话...线程数:");
		USES_CONVERSION;
		a=a+A2W(temp);
        
		CButton* butStart;

	    static bool running=false;
	    butStart=(CButton*)GetDlgItem(IDC_SOFT_CALL);
	    butStart->SetWindowTextW(a);

        HCallThread=CreateThread(NULL,0,SoftPhoneThread,this,0,&targetThreadID);
		CloseHandle(HCallThread);
		
//		return 0;
}


DWORD WINAPI CtestmainDlg::SoftPhoneThread(LPVOID Param)
{      
	    OutputDebugString(TEXT("SoftPhoneThread...\n==========\n"));
        CtestmainDlg* dlg=  (CtestmainDlg*) Param;

		
         int iCallNum,oCallNum;
		 char temp[500];
		 int len;
         int i;


      while(1)
	  {
          if(sfstarted==false)
		  {
		 //   return 0;
		  }

		 Slogin=2;

		 for (i=0;i<iThreadNum;i++)
		 {
			 iCallNum=atoi(inNum)+i;
			 oCallNum=atoi(outNum)+i;

			 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=529\nagent=%d\ndev=%d</socket-data>\n",oCallNum,oCallNum );
			 len=strlen(temp);
			 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
			 Sleep(100);


			 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=533\nagent=%d\nagt.mode=1\ndev=%d\npwd=12345</socket-data>\n",oCallNum,oCallNum );
			 len=strlen(temp);
			 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
	//		 Sleep(1000);
	//		 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);

		 }


		 Sleep(20000);
		 Slogin=3;
		 for (i=0;i<iThreadNum;i++)
		 {
			 iCallNum=atoi(inNum)+i;
			 oCallNum=atoi(outNum)+i;

			 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=529\nagent=%d\ndev=%d</socket-data>\n",oCallNum,oCallNum );
			 len=strlen(temp);
			 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
			 Sleep(100);


			 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=533\nagent=%d\nagt.mode=4\ndev=%d\nresn.code=2</socket-data>\n",oCallNum,oCallNum );
			 len=strlen(temp);
			 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
		 }


		 Sleep(20000);


		 Slogin=1;
		 for (i=0;i<iThreadNum;i++)
		 {
			 iCallNum=atoi(inNum)+i;
			 oCallNum=atoi(outNum)+i;

			 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=529\nagent=%d\ndev=%d</socket-data>\n",oCallNum,oCallNum );
			 len=strlen(temp);
			 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
			 Sleep(100);


			 sprintf(temp,"<socket-data>\ndomain=40960\ntype=512\nevent=533\nagent=%d\nagt.mode=2\ndev=%d\nresn.code=2</socket-data>\n",oCallNum,oCallNum );
			 len=strlen(temp);
			 send(dlg->Sock->SockClient[i],(char*)temp,len+1,0);
		 }

         Sleep(20000);
	  }

			    
	//	Sleep(10000);
		
		//sfstarted=true;
		 
	   return 0; 

}
void CtestmainDlg::OnBnClickedButton3()
{
	// TODO: 在此添加控件通知处理程序代码

	CButton* butStart;

	wchar_t thnum[30];
	int callnum=callid-firstcallid;


	char temp[10];
	sprintf(temp,"%d", callnum);
	CString a;
	a=TEXT("已拨电话数: ");
	USES_CONVERSION;
	a=a+A2W(temp);
	a=a+TEXT("\r\n\r\n点击刷新...  ");


	butStart=(CButton*)GetDlgItem(IDC_BUTTON3);
	butStart->SetWindowTextW(a);


	
}

void CtestmainDlg::OnBnClickedCancel()
{
	// TODO: 在此添加控件通知处理程序代码
	if (SockVrs)
	{
	  delete SockVrs;
	  SockVrs=NULL;
	}
	OnCancel();
	//fclose(logfp);
}

void CtestmainDlg::OnBnClickedButton4()
{

	CButton* butStart;
	float missrate=0.0;

	wchar_t thnum[50];
	int callnum=callid-firstcallid;
	if (callnum)
	{
	 missrate=((float)(callnum-missnum))*100/callnum;

	}


	char temp[100];
	sprintf(temp,"%5.2f\%", missrate);
	CString a;
	a=TEXT("录音率: ");
	USES_CONVERSION;
	a=a+A2W(temp);
   // a=a+TEXT("\r\n\r\n点击刷新...  ");


	butStart=(CButton*)GetDlgItem(IDC_BUTTON4);
	butStart->SetWindowTextW(a);

}
