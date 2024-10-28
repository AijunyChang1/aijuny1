// testmainDlg.h : 头文件
//


#pragma once
//#include "socket.h"
#include "decode.h"
#include "sockvrs.h"

/*
struct ThParam
{
  RecvSendInfo resInfo;
  int threadnum;

};
*/

// CtestmainDlg 对话框
class CtestmainDlg : public CDialog
{
// 构造
public:
	CtestmainDlg(CWnd* pParent = NULL);	// 标准构造函数

// 对话框数据
	enum { IDD = IDD_TESTMAIN_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持


// 实现
protected:
	HICON m_hIcon;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
    afx_msg LRESULT OnSocketServer(WPARAM wParam, LPARAM lParam); 
	afx_msg LRESULT OnCall(WPARAM wParam, LPARAM lParam); 
	afx_msg LRESULT SFStart(WPARAM wParam, LPARAM lParam); 

	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnBnClickedOk();
	int DisplayNum;
	int iPort;
	CString RecDisplay;


//	char inNum[30];
//	char outNum[30];
public:
	afx_msg void OnEnChangeEdit2();

public:
 //   int ProcessData(char* a=NULL);
	Socket* Sock;


  
public:
	afx_msg void OnBnClickedButton1();
	static DWORD WINAPI MakeCallThread(LPVOID Param);
	static DWORD WINAPI CallThread(LPVOID Param);
	static DWORD WINAPI StartCliSockThread(LPVOID Param);
	static DWORD WINAPI SoftPhoneThread(LPVOID Param);
public:
	afx_msg void OnBnClickedButton2();
public:
	afx_msg void OnBnClickedSoftCall();
public:
	afx_msg void OnBnClickedButton3();
public:
	afx_msg void OnBnClickedCancel();
public:
	afx_msg void OnBnClickedButton4();
};
