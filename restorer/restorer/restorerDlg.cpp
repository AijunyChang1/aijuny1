// restorerDlg.cpp : ʵ���ļ�
//

#include "stdafx.h"
#include "restorer.h"
#include "restorerDlg.h"


#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
using namespace std;




#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// ����Ӧ�ó��򡰹��ڡ��˵���� CAboutDlg �Ի���

class CAboutDlg : public CDialog
{
public:
	CAboutDlg();

// �Ի�������
	enum { IDD = IDD_ABOUTBOX };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV ֧��

// ʵ��
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialog(CAboutDlg::IDD)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialog)
END_MESSAGE_MAP()


// CrestorerDlg �Ի���




CrestorerDlg::CrestorerDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CrestorerDlg::IDD, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CrestorerDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CrestorerDlg, CDialog)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	//}}AFX_MSG_MAP
	ON_BN_CLICKED(IDOK, &CrestorerDlg::OnBnClickedOk)
	ON_BN_CLICKED(IDC_BUTTON1, &CrestorerDlg::OnBnClickedButton1)
	ON_BN_CLICKED(IDC_BUTTON2, &CrestorerDlg::OnBnClickedButton2)
END_MESSAGE_MAP()


// CrestorerDlg ��Ϣ�������

BOOL CrestorerDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// ��������...���˵�����ӵ�ϵͳ�˵��С�

	// IDM_ABOUTBOX ������ϵͳ���Χ�ڡ�
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);
	AfxOleInit();//��ʼ��
	::CoInitialize(NULL);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		CString strAboutMenu;
		strAboutMenu.LoadString(IDS_ABOUTBOX);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// ���ô˶Ի����ͼ�ꡣ��Ӧ�ó��������ڲ��ǶԻ���ʱ����ܽ��Զ�
	//  ִ�д˲���
	SetIcon(m_hIcon, TRUE);			// ���ô�ͼ��
	SetIcon(m_hIcon, FALSE);		// ����Сͼ��

	// TODO: �ڴ���Ӷ���ĳ�ʼ������
	GetDlgItem(IDC_EDIT7)->SetWindowTextW(TEXT("0"));

	return TRUE;  // ���ǽ��������õ��ؼ������򷵻� TRUE
}

void CrestorerDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialog::OnSysCommand(nID, lParam);
	}
}

// �����Ի��������С����ť������Ҫ����Ĵ���
//  �����Ƹ�ͼ�ꡣ����ʹ���ĵ�/��ͼģ�͵� MFC Ӧ�ó���
//  �⽫�ɿ���Զ���ɡ�

void CrestorerDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // ���ڻ��Ƶ��豸������

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// ʹͼ���ڹ��������о���
		int cxIcon = GetSystemMetrics(SM_CXICON);
		int cyIcon = GetSystemMetrics(SM_CYICON);
		CRect rect;
		GetClientRect(&rect);
		int x = (rect.Width() - cxIcon + 1) / 2;
		int y = (rect.Height() - cyIcon + 1) / 2;

		// ����ͼ��
		dc.DrawIcon(x, y, m_hIcon);
	}
	else
	{
		CDialog::OnPaint();
	}
}

//���û��϶���С������ʱϵͳ���ô˺���ȡ�ù����ʾ��
//
HCURSOR CrestorerDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}


void CrestorerDlg::OnBnClickedOk()  
{
	// TODO: �ڴ���ӿؼ�֪ͨ����������

	wchar_t f_recordid_w[100];
	wchar_t temp_path_w[200];
	wchar_t record_path_w[200];
	wchar_t storeid_w[50];
	wchar_t time_div_w[20];

	wchar_t msg[200000];

	char f_recordid[100];
	char temp_path[200];
	char record_path[50];
	char store[100];
	char time_div[20];

	USES_CONVERSION;

	GetDlgItem(IDC_EDIT1)->GetWindowTextW(f_recordid_w,100);
	GetDlgItem(IDC_EDIT6)->GetWindowTextW(temp_path_w,200);
	GetDlgItem(IDC_EDIT7)->GetWindowTextW(time_div_w,200);
    GetDlgItem(IDC_EDIT8)->GetWindowTextW(storeid_w,50);

	sprintf(f_recordid,"%s", W2A(f_recordid_w));
	sprintf(temp_path,"%s", W2A(temp_path_w));
	sprintf(time_div,"%s", W2A(time_div_w));
	sprintf(store,"%s", W2A(storeid_w));

	if((strlen(f_recordid)==0)||(f_recordid[0]==' ')) 
	{
		MessageBox(TEXT("�������һ��record_id��"),TEXT("����"),1);
		return;
	}
	else
	{
		if(strlen(f_recordid)!=14)
		{
			MessageBox(TEXT("�����record_id̫����̫�̣����������룡"),TEXT("����"),1);
		    return;
		}
	
	}

	if((strlen(store)==0)||(store[0]==' ')) 
	{
		MessageBox(TEXT("������洢���룡"),TEXT("����"),1);
		return;
	}

    if(strlen(temp_path)==0)
	{
	    MessageBox(TEXT("��������ʱ�ļ��У�"),TEXT("����"),1);
	
	}
	int len;
	len=strlen(temp_path);
	if(temp_path[len-1]!='\\')
	{
	    temp_path[len]='\\';	
		temp_path[len+1]='\0';
	}

    int div;
	div=atoi(time_div);


	first_recid=str_to_int64(f_recordid);
	current_recid=first_recid;
	string current_recid_str;


	if(first_recid==0)
	{
		MessageBox(TEXT("�����record_id��ʽ���ԣ����������룡"),TEXT("����"),1);
		return;
	
	}


	if(!db.status)  {
		MessageBox(TEXT("���ݿ�δ���ӣ����������ݿ���ٵ��룡"),TEXT("����"),1);
		return;
	
	}

///////////////////////////////////////////////////////////////////////////////////////
	string sql;
	string record_folder="";
	sql="select * from Store where FtpId=";
	sql=sql+store;
	try{
	  db.m_pRecordset->Open(sql.c_str(),db.m_pConnection.GetInterfacePtr(),adOpenDynamic,adLockOptimistic,adCmdText);
	//db.m_pRecordset->Open(_bstr_t(sql.c_str()),db.m_pConnection.GetInterfacePtr(),adOpenStatic,adLockOptimistic,adCmdText);

	  db.m_pRecordset->GetFields();
		
  //	db.m_pRecordset=db.execute(sql.c_str());
	  if (!db.m_pRecordset->adoEOF)
	  {
          _variant_t name=db.m_pRecordset->GetCollect("RealFolder");//������ֶα�ź��ֶ���������
		  if(name.vt != VT_NULL)
		  {
		      record_folder=(char*)_bstr_t(name);                       //ת����������
		  }
	  }
	}
	catch(...)
	{
	
	     MessageBox(L"���ݿ�����ʱ������û�������Oracle�û���ӦΪvxi_rec��", L"����",1);
		 return;
	
	}

	if(record_folder.length()<1)
	{
	   MessageBox(L"����Ĵ洢·�����벻�ԣ����������룡", L"����",1);
	   return;
	
	}
	db.m_pRecordset->Close();
	MessageBox(L"���record·���ɹ���", L"����",1);


	ifstream ifs; 
	vector<string> vec;   
	GetDlgItem(IDC_EDIT5)->GetWindowTextW(msg,100000);
//  ifs.open("E:/demo/restorer/debug/record.txt"); 
	ifs.open("record.txt"); 
//	ifs.open("test.txt"); 
	if (!ifs.rdbuf()->is_open()) 
	{     // ���ļ����� 
		_stprintf(msg,TEXT("%s\r\nOpen record.txt file: Fail!!!"),msg);
		GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);
		ifs.close();
		return;

	}   
	else
	{
	    _stprintf(msg,TEXT("%s\r\nOpen record.txt file: Success!"),msg);
		GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);
	}

/////////////////////////////////////////////////////////////////////////////////////////

    string date;
	string start_time;
	string ch;
	string recid;
    string length;
	string ext;
	string temp;
    int count=0;
	int fail=0;

	temp=W2A(msg);
	temp=temp+"\r\n";

	vec.clear(); 
	string buffer; 
	string datetime;
	
	while(getline(ifs,buffer)){   
//		vec.push_back(stmp);
		recid=fetch_mid(buffer, "recid:", " ");
		if(recid=="-1")
		{
			 date=fetch_mid(buffer, "date:", " "); temp=temp+"date:"+date+" ";			 
			 start_time=fetch_mid(buffer, "start:", " "); 
			 start_time=fetch_head(start_time, '.');temp=temp+"start:"+start_time+" ";
			 datetime=date.substr(0,4)+"-"+date.substr(4,2)+"-"+date.substr(6,2)+" "+start_time;
			 ch=fetch_mid(buffer, "dev:", " ");     temp=temp+"channel:"+ch+" ";				 
			 length=fetch_mid(buffer, "len:", " "); temp=temp+"length:"+length+" ";
			 ext=get_ext(start_time, ch);
			 string _t;
			 string rec_lno;
			 fetch_head(buffer, ' ');
			 fetch_head(buffer, ' ');
			 rec_lno=fetch_head(buffer, ' ');


			 if(ext!="-1")
			 {   
             /////////////////////////////////////////////////////////////////////////////////////////////////////
				 string calling="",called="";
				 Get_Calling_Called(ext,start_time,div, calling, called);



             /////////////////////////////////////////////////////////////////////////////////////////////////////


			     temp=temp+"ext:"+ext+" \r\n";
				 count=count+1;
				 current_recid_str=int_to_str(current_recid);
				 sql="insert into Records(RecordId, Answer,Extension, Channel, StartTime, StartDate,StartHour, TimeLen, VideoURL, AudioURL, VoiceType, finished,FileCount";
				 if(calling.length()>1)
				 {
				    sql=sql+",Calling";
				 }
				 if(called.length()>1)
				 {
				    sql=sql+",Called";
				 }
					
					 
					 
				 sql=sql+") values(";
				 sql= sql+current_recid_str+",";
				 sql= sql+"\'"+ext+"\',";
				 sql= sql+"\'"+ext+"\',";
				 sql= sql+"\'"+ch+"\',";
			//	 sql= sql+"\'"+datetime+"\',";
                 if(db.is_oral)
				 {
				    sql=sql+"to_date(\'";
				 }
				 else
				 {
				   sql=sql+"\'";
				 }
				 sql= sql+datetime;
                 if(db.is_oral)
				 {
					 sql=sql+"\',\'yyyy-mm-dd hh24:mi:ss\'),";
				 }
				 else
				 {

					sql=sql+"\',";
				 }
				 sql= sql+date+",";

				 sql= sql+start_time.substr(0,2)+",";
				 sql= sql+length+",";
				 sql= sql+store+",";
				 sql= sql+store+",7,1,2";
				 if(calling.length()>1)
				 {
				    sql=sql+","+calling;
				 }	
				 if(called.length()>1)
				 {
				    sql=sql+","+called;
				 }	

				 sql=sql+")";

				 db.execute(sql.c_str());
//				 MessageBox(L"��������ֵ",L"����",1);
				 current_recid++;

				 //////////////////////////////////////////////////////////////////////////////////////////////////
				 string sub_folder=date+"\\"+ch+"\\"+current_recid_str;
				 int created= make_dir(record_folder, sub_folder);
				 if(created==1)
				 {
					 temp=temp+"Create folder:"+sub_folder+" success!\r\n";
					 string target_file_a=record_folder+"\\"+sub_folder+"\\"+current_recid_str+".a.g711";
					 string target_file_b=record_folder+"\\"+sub_folder+"\\"+current_recid_str+".b.g711";
					 string src_file_a=temp_path+date+"\\"+date+"."+ch+"."+rec_lno+".a.g711";
					 string src_file_b=temp_path+date+"\\"+date+"."+ch+"."+rec_lno+".b.g711";
					 if ( !CopyFileA(src_file_a.c_str(), target_file_a.c_str(), FALSE) )
                     {
						 temp=temp+"Copy file: "+target_file_a+" failed!"+src_file_a+"\r\n";
                     }

					 if ( !CopyFileA(src_file_b.c_str(), target_file_b.c_str(), FALSE) )
                     {
						 temp=temp+"Copy file: "+target_file_b+" failed!"+src_file_a+"\r\n";
                     }


					 /////////////////////////////////////////////////////////////////////////////



					 /////////////////////////////////////////////////////////////////////////

				 
				 
				 }
				 else 
				 {
					 temp=temp+"Create folder:"+sub_folder+" fail! Error code:";
					 temp=temp+int_to_str(created)+"\r\n";
		             //  GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);				 

				 }

			 }
			 else
			 {
				 temp=temp+"extension: can not find ext in send file!!!\r\n";
				 fail=fail+1;
			 
			 }

		}


	}

	temp=temp+"Total restore DB success:";
	_stprintf(msg,L"%s", A2W(temp.c_str()));
	_stprintf(msg,L"%s%d,  fail:%d", msg,count, fail);
	GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);

	ifs.close();


//	OnOK();
}


string CrestorerDlg::get_ext(string start_time, string ch)
{
	wchar_t msg[200000];
	GetDlgItem(IDC_EDIT5)->GetWindowTextW(msg,100000);
	ifstream ifs; 
//	ifs.open("E:/demo/restorer/debug/send.txt"); 
	ifs.open("send.txt"); 
	if (!ifs.rdbuf()->is_open()) 
	{     // ���ļ����� 
		_stprintf(msg,TEXT("%s\r\nOpen send.txt file: Fail!!!"),msg);
		GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);
		ifs.close();
		return "-1";

	}   

	string buffer; 
	string date;
	string time;
	string channel;
	string ext;
	while(getline(ifs,buffer)){   
//		vec.push_back(stmp);
		date=fetch_head(buffer, ' ');
		time=fetch_head(buffer, ' ');
		if(time==start_time)
		{
          channel=fetch_mid(buffer, ".[", "].");
		  if(channel==ch)
		  {
		     ext=channel=fetch_mid(buffer, "ext=", " ");
			 if(ext.length()>0)
			 {
			    ifs.close();
				return ext;
			 }
		  }
		}		

   }


   ifs.close();
   return "-1";

}


bool  CrestorerDlg::Get_Calling_Called(string ext,string start_time,int del, string& calling, string& called)
{
   	wchar_t msg[200000];
	GetDlgItem(IDC_EDIT5)->GetWindowTextW(msg,100000);
	ifstream ifs; 
//	ifs.open("E:/demo/restorer/debug/cti_send.txt"); 
	ifs.open("cti_send.txt"); 
	if (!ifs.rdbuf()->is_open()) 
	{     // ���ļ����� 
		_stprintf(msg,TEXT("%s\r\nOpen cti_send.txt file: Fail!!!"),msg);
		GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);
		ifs.close();
		return false;

	}

	string buffer; 
	string date;
	string time;
	string ext_l;
	string h_t;
	int cti_year=0,cti_month=0,cti_day=0;
	int cti_hour=0,cti_min=0,cti_sec=0;
	int vrs_hour=0,vrs_min=0,vrs_sec=0;
	CTime t1;

	while(getline(ifs,buffer))
	{
	   ext_l=fetch_mid(buffer, "].[", "].");
	   if(ext==ext_l)
	   {
           date=fetch_head(buffer, ' ');
		   str_to_day(date,cti_year,cti_month,cti_day);

           time=fetch_head(buffer, ' ');
		   str_to_time(time,cti_hour,cti_min,cti_sec);
		   str_to_time(start_time,vrs_hour,vrs_min,vrs_sec);
           CTime t_cti( cti_year, cti_month, cti_day, cti_hour, cti_min, cti_sec ); 
		   CTime t_vrs( cti_year, cti_month, cti_day, vrs_hour, vrs_min, vrs_sec ); 
		   CTimeSpan ts = t_cti - t_vrs-del;  // Subtract 2 
	       int sec= ts.GetTotalSeconds();
		   if (abs(sec)<5)
		   { 
			   calling=fetch_mid(buffer, "oci.calling=", " ");
			   if(calling.length()<1)
			   {
			      calling=fetch_mid(buffer, "calling=", " ");
			   }

			   called=fetch_mid(buffer, "oci.called=", " ");
			   if(called.length()<1)
			   {
			       called=fetch_mid(buffer, "called=", " ");
			      
			   }
			   return true;
		   		   
		   }

	   }
	}

	ifs.close();
    return false;

}



void CrestorerDlg::OnBnClickedButton1()                                              //�������ݿ�
{
	// TODO: �ڴ���ӿؼ�֪ͨ����������
   	wchar_t dsn_w[100];
	wchar_t username_w[100];
	wchar_t password_w[100];

	wchar_t msg[100000];

	char dsn[100];
	char username[100];
	char password[100];


	USES_CONVERSION;

	GetDlgItem(IDC_EDIT2)->GetWindowTextW(dsn_w,100);
	GetDlgItem(IDC_EDIT3)->GetWindowTextW(username_w,100);
	GetDlgItem(IDC_EDIT4)->GetWindowTextW(password_w,100);


	sprintf(dsn,"%s", W2A(dsn_w));
	sprintf(username,"%s", W2A(username_w));
	sprintf(password,"%s", W2A(password_w));

	if((strlen(dsn)==0)||(dsn[0]==' ')) 
	{
		MessageBox(TEXT("���������ݿ�IP(sql_server)������Դ(oracle)��"),TEXT("����"),1);
		return;
	}

	if((strlen(username)==0)||(username[0]==' ')) 
	{
		MessageBox(TEXT("�������û�����"),TEXT("����"),1);
		return;
	}

	if((dsn[0]>'0')&&(dsn[0]<'9'))  
	{
		db.is_oral=false;
	}
	else
	{
		db.is_oral=true;
	}

	string con_string;

	if(db.is_oral)
	{
	   // con_string="Provider=MSDAORA;Data Source=";
		con_string="Provider=OraOLEDB.Oracle.1;Data Source=";
	    con_string=con_string+dsn;
	    con_string=con_string+";User ID=";
	    con_string=con_string+username;
	    con_string=con_string+";Password=";
	    con_string=con_string+password;
	    con_string=con_string+";";

		con_string=con_string+"Persist Security Info=True";
	
	}
	else
	{

	    con_string="Provider=SQLOLEDB;Server=";
	    con_string=con_string+dsn;
        con_string=con_string+";Database=vxi_rec";
	    con_string=con_string+";uid=";
	    con_string=con_string+username;
	    con_string=con_string+";pwd=";
	    con_string=con_string+password;
	    con_string=con_string+";";

	}
	
	GetDlgItem(IDC_EDIT5)->GetWindowTextW(msg,10000);
    bool con_status;
	con_status=db.open(con_string.c_str(),"","",adModeUnknown);
	
	
	if (!con_status)
	{
	  _stprintf(msg,TEXT("%s\r\nConnected to database: Fail!!!"),msg);
	  GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);
	  CString temp;
	  if(db.is_oral)
	  {
	     temp="������Oracle���ݿ⣡��ȷ�����ú��������ӣ�";
	  }
	  else
	  {
	    temp="������SQL Server���ݿ⣡��ȷ�����ú��������ӣ�";
	  }
	  MessageBox(temp,TEXT("����"),1);
	  return;
	}

	db.status=true;	
	_stprintf(msg,TEXT("%s\r\nConnected to database: Success!"),msg);
	GetDlgItem(IDC_EDIT5)->SetWindowTextW(msg);
	GetDlgItem(IDC_BUTTON1)->EnableWindow(false);


}



void CrestorerDlg::OnBnClickedButton2()
{
	// TODO: �ڴ���ӿؼ�֪ͨ����������
	wchar_t f_recordid_w[100];
	wchar_t time_div_w[20];
	wchar_t rec_count_w[20];

	wchar_t msg[200000];

	char f_recordid[100];
	char time_div[20];
	char rec_count[20];

	USES_CONVERSION;

	GetDlgItem(IDC_EDIT1)->GetWindowTextW(f_recordid_w,100);
	GetDlgItem(IDC_EDIT7)->GetWindowTextW(time_div_w,20);
	GetDlgItem(IDC_EDIT9)->GetWindowTextW(rec_count_w,20);

	sprintf(f_recordid,"%s", W2A(f_recordid_w));
	sprintf(time_div,"%s", W2A(time_div_w));
	sprintf(rec_count,"%s", W2A(rec_count_w));
	int div=atoi(time_div);

	if((strlen(f_recordid)==0)||(f_recordid[0]==' ')) 
	{
		MessageBox(TEXT("�������һ��record_id��"),TEXT("����"),1);
		return;
	}
	else
	{
		if(strlen(f_recordid)!=14)
		{
			MessageBox(TEXT("�����record_id̫����̫�̣����������룡"),TEXT("����"),1);
		    return;
		}
	
	}

	if((strlen(rec_count)==0)||(rec_count[0]==' ')) 
	{
		MessageBox(TEXT("������Ҫ�ָ���������¼��������"),TEXT("����"),1);
		return;
	}

    first_recid=str_to_int64(f_recordid);
	int count=atoi(rec_count);
	current_recid=first_recid;
	string current_recid_str;
	_int64 last_recid;
	string l_recordid;
	last_recid=first_recid+count-1;
    l_recordid=int_to_str(last_recid);


	if(first_recid==0)
	{
		MessageBox(TEXT("�����record_id��ʽ���ԣ����������룡"),TEXT("����"),1);
		return;
	
	}

	if(!db.status)  {
		MessageBox(TEXT("���ݿ�δ���ӣ������������ݿ⣡"),TEXT("����"),1);
		return;
	
	}
///////////////////////////////////////////////////////////////////////////////////////////////
	string sql;
	string date_time="";
	string date, time;
	string ext="";
	sql="select * from Records where RecordId>=";
	sql=sql+f_recordid+" and RecordId<="+l_recordid;
	//db.m_pRecordset->Open(sql.c_str(),db.m_pConnection.GetInterfacePtr(),adOpenDynamic,adLockOptimistic,adCmdText);
	BSTR bstrSQL = ((CString)sql.c_str()).AllocSysString();

	db.m_pRecordset->Open(bstrSQL,((IDispatch*)db.m_pConnection),adOpenDynamic,adLockOptimistic,adCmdText);
	db.m_pRecordset->GetFields();
	while(!db.m_pRecordset->adoEOF)
	{
		date_time="";
		ext="";
		current_recid_str="";
        _variant_t name=db.m_pRecordset->GetCollect("RecordId");//������ֶα�ź��ֶ���������
		if(name.vt != VT_NULL)
		{
		   current_recid_str=(char*)_bstr_t(name);
		}
		if(current_recid_str.length()>0)
		{
		   name=db.m_pRecordset->GetCollect("Extension");
		   if(name.vt != VT_NULL)
		   {
		       ext=(char*)_bstr_t(name);
		   }

		   name=db.m_pRecordset->GetCollect("StartTime");
		   if(name.vt != VT_NULL)
		   {
		       date_time=(char*)_bstr_t(name);
		   }

		   if(date_time.length()>0)
		   {
		       date=fetch_head(date_time, ' ');
			   time=date_time;
		   }
		   if((time.length()>0)&&(ext.length()>0))
		   {
		      string calling="",called="";
		      Get_Calling_Called(ext,time,div, calling, called);

			  if((calling.length()>1)||(called.length()>1))
			  {
		   	     string update_sql="update Records set";
				 if (calling.length()>1)
				 {
					 update_sql=update_sql+" Calling=\'"+calling+"\'";
					 if(called.length()>1)
					 {
					    update_sql=update_sql+",Called=\'"+called+"\'";
					 
					 }
				 }
				 else
				 { 
				      if(called.length()>1)
					 {
					    update_sql=update_sql+"Called=\'"+called+"\'";
					 
					 }
				 
				 }
				 update_sql=update_sql+" where RecordId="+current_recid_str;

		         db.execute(update_sql.c_str());
			  }
		   }
		
		}




		db.m_pRecordset->MoveNext();
	}


	db.m_pRecordset->Close();



///////////////////////////////////////////////////////////////////////////////////////////////


}
