
// HK_FBGDlg.h : ͷ�ļ�
//

#pragma once
#include "sockclient.h"
#include "func.h"

// CHK_FBGDlg �Ի���
class CHK_FBGDlg : public CDialogEx
{
// ����
public:
	CHK_FBGDlg(CWnd* pParent = NULL);	// ��׼���캯��

// �Ի�������
	enum { IDD = IDD_HK_FBG_DIALOG };

	protected:
	virtual void DoDataExchange(CDataExchange* pDX);	// DDX/DDV ֧��


// ʵ��
protected:
	HICON m_hIcon;

	// ���ɵ���Ϣӳ�亯��
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
