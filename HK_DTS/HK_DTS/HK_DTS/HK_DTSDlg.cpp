
// HK_DTSDlg.cpp : 实现文件
//

#include "stdafx.h"
#include "HK_DTS.h"
#include "HK_DTSDlg.h"
#include "afxdialogex.h"
#include "func.h"

#ifdef _DEBUG
#define new DEBUG_NEW
#endif


// 用于应用程序“关于”菜单项的 CAboutDlg 对话框

class CAboutDlg : public CDialogEx
{
public:
	CAboutDlg();

// 对话框数据
	enum { IDD = IDD_ABOUTBOX };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV 支持

// 实现
protected:
	DECLARE_MESSAGE_MAP()
};

CAboutDlg::CAboutDlg() : CDialogEx(CAboutDlg::IDD)
{
}

void CAboutDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CAboutDlg, CDialogEx)
END_MESSAGE_MAP()


// CHK_DTSDlg 对话框




CHK_DTSDlg::CHK_DTSDlg(CWnd* pParent /*=NULL*/)
	: CDialogEx(CHK_DTSDlg::IDD, pParent)
{
	m_hIcon = AfxGetApp()->LoadIcon(IDR_MAINFRAME);
}

void CHK_DTSDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialogEx::DoDataExchange(pDX);
}

BEGIN_MESSAGE_MAP(CHK_DTSDlg, CDialogEx)
	ON_WM_SYSCOMMAND()
	ON_WM_PAINT()
	ON_WM_QUERYDRAGICON()
	ON_BN_CLICKED(IDOK, &CHK_DTSDlg::OnBnClickedOk)
	ON_BN_CLICKED(IDCANCEL, &CHK_DTSDlg::OnBnClickedCancel)
END_MESSAGE_MAP()


// CHK_DTSDlg 消息处理程序

BOOL CHK_DTSDlg::OnInitDialog()
{
	CDialogEx::OnInitDialog();

	// 将“关于...”菜单项添加到系统菜单中。

	// IDM_ABOUTBOX 必须在系统命令范围内。
	ASSERT((IDM_ABOUTBOX & 0xFFF0) == IDM_ABOUTBOX);
	ASSERT(IDM_ABOUTBOX < 0xF000);

	CMenu* pSysMenu = GetSystemMenu(FALSE);
	if (pSysMenu != NULL)
	{
		BOOL bNameValid;
		CString strAboutMenu;
		bNameValid = strAboutMenu.LoadString(IDS_ABOUTBOX);
		ASSERT(bNameValid);
		if (!strAboutMenu.IsEmpty())
		{
			pSysMenu->AppendMenu(MF_SEPARATOR);
			pSysMenu->AppendMenu(MF_STRING, IDM_ABOUTBOX, strAboutMenu);
		}
	}

	// 设置此对话框的图标。当应用程序主窗口不是对话框时，框架将自动
	//  执行此操作
	SetIcon(m_hIcon, TRUE);			// 设置大图标
	SetIcon(m_hIcon, FALSE);		// 设置小图标

	// TODO: 在此添加额外的初始化代码
	GetDlgItem(IDC_EDIT1)->SetWindowText(TEXT("192.168.100.2"));
	GetDlgItem(IDC_EDIT2)->SetWindowText(TEXT("502"));
	GetDlgItem(IDC_EDIT3)->SetWindowText(TEXT("hk_dts"));

	m_sock_client = NULL;
	hlog=CreateEvent(NULL,FALSE,TRUE,NULL);

	WSADATA wsData;
    ::WSAStartup(MAKEWORD(2,2), &wsData);

	BYTE *p; 
	char host_name[200]; 
	memset(host_name, 0, sizeof(host_name));
	unsigned long hlen = sizeof(host_name) - 1;
    struct hostent *hp;
    char local_ip[16];
	memset(local_ip, 0, sizeof(local_ip));

	if(GetComputerName(host_name, &hlen))
    {
        if((hp =gethostbyname(host_name))!=0)
        {
			p =(BYTE *)hp->h_addr; 
            sprintf(local_ip, "%d.%d.%d.%d", p[0], p[1], p[2], p[3]);
		}
	} 

    ::WSACleanup();

	GetDlgItem(IDC_EDIT7)->SetWindowText(local_ip);

	write_log("Start ===========================================================================\n");

	return TRUE;  // 除非将焦点设置到控件，否则返回 TRUE
}

void CHK_DTSDlg::OnSysCommand(UINT nID, LPARAM lParam)
{
	if ((nID & 0xFFF0) == IDM_ABOUTBOX)
	{
		CAboutDlg dlgAbout;
		dlgAbout.DoModal();
	}
	else
	{
		CDialogEx::OnSysCommand(nID, lParam);
	}
}

// 如果向对话框添加最小化按钮，则需要下面的代码
//  来绘制该图标。对于使用文档/视图模型的 MFC 应用程序，
//  这将由框架自动完成。

void CHK_DTSDlg::OnPaint()
{
	if (IsIconic())
	{
		CPaintDC dc(this); // 用于绘制的设备上下文

		SendMessage(WM_ICONERASEBKGND, reinterpret_cast<WPARAM>(dc.GetSafeHdc()), 0);

		// 使图标在工作区矩形中居中
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
		CDialogEx::OnPaint();
	}
}

//当用户拖动最小化窗口时系统调用此函数取得光标
//显示。
HCURSOR CHK_DTSDlg::OnQueryDragIcon()
{
	return static_cast<HCURSOR>(m_hIcon);
}



void CHK_DTSDlg::OnBnClickedOk()
{
	// TODO: 在此添加控件通知处理程序代码
	char host_ip[50];
	char local_ip[50];
	char host_port[10];
	char local_port[10];
	char db_dsn[50];
	char db_username[50];
	char db_password[50];
	
    GetDlgItem(IDC_EDIT1)->GetWindowText(host_ip,30);
	m_hostip = host_ip;
	if ((m_hostip.length()==0)||(m_hostip==" "))
	{
	    MessageBox(TEXT("请输入服务器IP！"),TEXT("警告"),1);
		return;
	}

	GetDlgItem(IDC_EDIT2)->GetWindowText(host_port, 8);
	if((strlen(host_port)==0)||(host_port[0]=='0'))
	{
	    m_hostport = 502;
	}
	else
	{
	    m_hostport = atoi(host_port);
	}

	GetDlgItem(IDC_EDIT7)->GetWindowText(local_ip,30);
	m_localip=local_ip;

	GetDlgItem(IDC_EDIT3)->GetWindowText(db_dsn,30);
	m_dbdsn=db_dsn;
	if ((m_dbdsn.length() == 0)||(m_dbdsn == " "))
	{
	    MessageBox(TEXT("请输入数据库DSN！"),TEXT("警告"),1);
		return;
	} 

	GetDlgItem(IDC_EDIT4)->GetWindowText(db_username,30);
	m_dbusername=db_username;
	if ((m_dbusername.length() == 0)||(m_dbusername == " "))
	{
	    MessageBox(TEXT("请输入数据库用户名！"),TEXT("警告"),1);
		return;
	}  

	GetDlgItem(IDC_EDIT5)->GetWindowText(db_password,30);
	m_dbpassword=db_password;

	char ch[5];
	GetDlgItem(IDC_COMBO1)->GetWindowText(ch,30);
	string s_ch=ch;
	if ((s_ch.length() == 0)||(s_ch == " "))
	{
	    MessageBox(TEXT("请选择通道号！"),TEXT("警告"),1);
		return;
	}  


	m_sock_client = new SockClient(m_hostip.c_str(), m_hostport, m_localip.c_str());
    if (m_sock_client==NULL) return;

	m_sock_client->m_ch = stoi(s_ch);		
	bool db_fail = m_sock_client->ConnectDB(m_dbdsn.c_str(), m_dbusername.c_str(), m_dbpassword.c_str());
	if (db_fail) 
	{
		write_log("Can not connect to Database!!!!!!!!!!!!!!!!!!");
	}
	else
	{
	    write_log("Connect to database successfully!");
	}

	if (m_sock_client != NULL)
	{
	    m_sock_client->ConnectTo();
	}
	if (m_sock_client->m_connected==false)
	{
	    delete m_sock_client;
		m_sock_client = NULL;
		char log[100];
		sprintf(log, "Can not connect to DTS server!!!!!!!!!!!!!!!!!!");
		write_log(log);
		return;
	}
	write_log("Connect to DTS server successfully!");
	int msg_len=0;
	m_sock_client->clean_send_buf();
# ifdef DTS
    m_sock_client->start_send_getstat();
# endif
    m_sock_client->start_send_heartbeat();
//	CDialogEx::OnOK();
}


void CHK_DTSDlg::OnBnClickedCancel()
{
	// TODO: 在此添加控件通知处理程序代码
	CDialogEx::OnCancel();
}
