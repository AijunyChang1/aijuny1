// restorerDlg.h : ͷ�ļ�
//

#pragma once

#include "func.h"


// CrestorerDlg �Ի���
class CrestorerDlg : public CDialog
{
// ����
public:
	CrestorerDlg(CWnd* pParent = NULL);	// ��׼���캯��

// �Ի�������
	enum { IDD = IDD_RESTORER_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV ֧��


// ʵ��
protected:
	HICON m_hIcon;

	// ���ɵ���Ϣӳ�亯��
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
