
// HK_TCDlg.h : ͷ�ļ�
//

#pragma once
#include <string>
#include "sockclient.h"

using namespace std;

// CHK_TCDlg �Ի���
class CHK_TCDlg : public CDialogEx
{
// ����
public:
	CHK_TCDlg(CWnd* pParent = NULL);	// ��׼���캯��

// �Ի�������
	enum { IDD = IDD_HK_TC_DIALOG };

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
	afx_msg void OnBnClickedCancel();


private:
	string m_hostip;
	int m_hostport;
	string m_localip;
	string m_dbdsn;
	string m_dbusername;
	string m_dbpassword;
	
	SockClient* m_sock_client;
};
