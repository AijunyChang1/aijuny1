
// HK_FBGDlg.h : 头文件
//

#pragma once
#include "sockclient.h"
#include "func.h"

// CHK_FBGDlg 对话框
class CHK_FBGDlg : public CDialogEx
{
// 构造
public:
	CHK_FBGDlg(CWnd* pParent = NULL);	// 标准构造函数

// 对话框数据
	enum { IDD = IDD_HK_FBG_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持


// 实现
protected:
	HICON m_hIcon;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()

private:
	string m_hostip;
	int m_hostport;
	string m_localip;
	string m_dbdsn;
	string m_dbusername;
	string m_dbpassword;
	SockClient* m_sock_client;
public:
	afx_msg void OnBnClickedOk();
};
