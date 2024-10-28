// restorerDlg.h : 头文件
//

#pragma once

#include "func.h"


// CrestorerDlg 对话框
class CrestorerDlg : public CDialog
{
// 构造
public:
	CrestorerDlg(CWnd* pParent = NULL);	// 标准构造函数

// 对话框数据
	enum { IDD = IDD_RESTORER_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV 支持


// 实现
protected:
	HICON m_hIcon;

	// 生成的消息映射函数
	virtual BOOL OnInitDialog();
	afx_msg void OnSysCommand(UINT nID, LPARAM lParam);
	afx_msg void OnPaint();
	afx_msg HCURSOR OnQueryDragIcon();
	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnBnClickedOk();

    db_factory db;
	__int64 first_recid;
	__int64 current_recid;


public:
	afx_msg void OnBnClickedButton1();
	string get_ext(string start_time, string ch);
	bool  Get_Calling_Called(string ext,string start_time, int del, string& calling, string& called);
public:
	afx_msg void OnBnClickedButton2();
};
