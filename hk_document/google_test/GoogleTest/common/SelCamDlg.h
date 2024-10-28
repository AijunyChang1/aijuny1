#pragma once
#include "afxwin.h"

#include <map>
#include <string>
using namespace std;

// CSelCamDlg dialog

class CSelCamDlg : public CDialog
{
	DECLARE_DYNAMIC(CSelCamDlg)

public:
	CSelCamDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~CSelCamDlg();

// Dialog Data
	enum { IDD = IDD_SELCAM };

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support
	CListBox m_cam_list;
	int m_sel;
	map<int, wstring>* m_pDevices;

	CComboBox m_cbFormat;
	int m_selFormat;

	DECLARE_MESSAGE_MAP()

public:
	void setDevices(map<int, wstring>* devices);
	int getSel();
	virtual BOOL OnInitDialog();
	afx_msg void OnLbnSelchangeListWebcam();
	afx_msg void OnCbnSelchangeComboFormat();
};
