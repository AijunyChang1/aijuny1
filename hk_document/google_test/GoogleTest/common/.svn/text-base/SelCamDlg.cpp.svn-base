// SelCamDlg.cpp : implementation file
//

#include "stdafx.h"
#include "Resource.h"
#include "SelCamDlg.h"
#include "Settings.h"


// CSelCamDlg dialog

IMPLEMENT_DYNAMIC(CSelCamDlg, CDialog)

CSelCamDlg::CSelCamDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CSelCamDlg::IDD, pParent)
{
	m_sel = -1;
}

CSelCamDlg::~CSelCamDlg()
{
}

void CSelCamDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
	DDX_Control(pDX, IDC_LIST_WEBCAM, m_cam_list);
	DDX_Control(pDX, IDC_COMBO_FORMAT, m_cbFormat);
}


BEGIN_MESSAGE_MAP(CSelCamDlg, CDialog)
	ON_LBN_SELCHANGE(IDC_LIST_WEBCAM, &CSelCamDlg::OnLbnSelchangeListWebcam)
	ON_CBN_SELCHANGE(IDC_COMBO_FORMAT, &CSelCamDlg::OnCbnSelchangeComboFormat)
END_MESSAGE_MAP()

void CSelCamDlg::setDevices( map<int, wstring>* devices )
{
	m_pDevices = devices;
}

// CSelCamDlg message handlers

BOOL CSelCamDlg::OnInitDialog()
{
	CDialog::OnInitDialog();

	// TODO:  Add extra initialization here
	//fill list
	{
		USES_CONVERSION;
		for(map<int, wstring>::iterator i = m_pDevices->begin(); i!=m_pDevices->end(); ++i){
			LPCTSTR s = (LPCTSTR)W2T(i->second.c_str());
			int idx = m_cam_list.AddString(s);
			m_cam_list.SetItemData(idx, i->first);
		}
		m_cam_list.SetCurSel(0);
		m_sel = 0;

		m_cbFormat.SetItemData(m_cbFormat.AddString(_T("320x240")), 0);
		m_cbFormat.SetItemData(m_cbFormat.AddString(_T("640x480")), 1);
		m_cbFormat.SetItemData(m_cbFormat.AddString(_T("800x600")), 2);
		m_cbFormat.SetCurSel(0);
		m_selFormat = 0;
		UpdateData(FALSE);
	}
	SetForegroundWindow();

	return TRUE;  // return TRUE unless you set the focus to a control
	// EXCEPTION: OCX Property Pages should return FALSE
}

int CSelCamDlg::getSel()
{
	int format_id = m_selFormat;
	switch(format_id){
		case 0:
			videoSettings(320, 240, 24);
			break;
		case 1:
			videoSettings(640, 480, 24);
			break;
		case 2:
			videoSettings(800, 600, 24);
			break;
	}
	return m_sel;
}
void CSelCamDlg::OnLbnSelchangeListWebcam()
{
	// TODO: Add your control notification handler code here
	int sel = (int)m_cam_list.GetItemData(m_cam_list.GetCurSel());
	m_sel = m_cam_list.GetCurSel();
	ASSERT(sel==m_sel);
}
void CSelCamDlg::OnCbnSelchangeComboFormat()
{
	// TODO: Add your control notification handler code here
	int format_id = (int)m_cbFormat.GetItemData(m_cbFormat.GetCurSel());
	m_selFormat = format_id;
}
