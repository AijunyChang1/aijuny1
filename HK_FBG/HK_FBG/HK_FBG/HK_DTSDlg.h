
// HK_DTSDlg.h : ͷ�ļ�
//

#pragma once
#include <string>
#include "sockclient.h"
using namespace std;

// CHK_DTSDlg �Ի���
class CHK_DTSDlg : public CDialogEx
{
// ����
public:
	CHK_DTSDlg(CWnd* pParent = NULL);	// ��׼���캯��

// �Ի�������
	enum { IDD = IDD_HK_DTS_DIALOG };

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

private:
	string m_hostip;
	int m_hostport;
	string m_localip;
	string m_dbdsn;
	string m_dbusername;
	string m_dbpassword;
	SockClient* m_sock_client;
public:
	afx_msg void OnBnClickedCancel();
};