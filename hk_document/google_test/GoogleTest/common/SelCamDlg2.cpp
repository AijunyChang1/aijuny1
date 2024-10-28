#include "StdAfx.h"
#include "resource.h"

#include "SelCamDlg2.h"

CSelCamDlg2::CSelCamDlg2(void)
{
	m_sel = -1;
}

CSelCamDlg2::~CSelCamDlg2(void)
{
}

LRESULT CSelCamDlg2::OnInitDialog( UINT /*uMsg*/, WPARAM /*wParam*/, LPARAM /*lParam*/, BOOL& /*bHandled*/ )
{
	m_listWebcam.Attach(GetDlgItem(IDC_LIST_WEBCAM));
	m_cbFormats.Attach(GetDlgItem(IDC_COMBO_FORMAT));

	{
		USES_CONVERSION;
		for(map<int, wstring>::iterator i = m_pDevices->begin(); i!=m_pDevices->end(); ++i){
			LPCTSTR s = (LPCTSTR)W2T((LPWSTR)i->second.c_str());
			int idx = m_listWebcam.AddString(s);
			m_listWebcam.SetItemData(idx, i->first);
		}
		m_listWebcam.SetCurSel(0);
		m_sel = 0;

		m_cbFormats.SetItemData(m_cbFormats.AddString(_T("320x240")), 0);
		m_cbFormats.SetItemData(m_cbFormats.AddString(_T("640x480")), 1);
		m_cbFormats.SetItemData(m_cbFormats.AddString(_T("800x600")), 2);
		m_cbFormats.SetCurSel(0);
		m_selFormat = 0;
		//UpdateData(FALSE);
	}

	CenterWindow(GetParent());
	return TRUE;
}

LRESULT CSelCamDlg2::OnDestroy( UINT /*uMsg*/, WPARAM /*wParam*/, LPARAM /*lParam*/, BOOL& /*bHandled*/ )
{
	return 0;
}

LRESULT CSelCamDlg2::OnOK( WORD /*wNotifyCode*/, WORD wID, HWND /*hWndCtl*/, BOOL& /*bHandled*/ )
{
	m_sel = m_listWebcam.GetCurSel();
	m_selFormat = m_cbFormats.GetCurSel();
	extern void videoSettings(int video_w, int video_h, int video_depth=24);
	switch(m_selFormat){
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
	EndDialog(wID);
	return 0;
}

LRESULT CSelCamDlg2::OnCancel( WORD /*wNotifyCode*/, WORD wID, HWND /*hWndCtl*/, BOOL& /*bHandled*/ )
{
	EndDialog(wID);
	return 0;
}

void CSelCamDlg2::CloseDialog( int nVal )
{
	DestroyWindow();
	//::PostQuitMessage(nVal);
}

BOOL CSelCamDlg2::PreTranslateMessage( MSG* pMsg )
{
	return CWindow::IsDialogMessage(pMsg);
}

void CSelCamDlg2::setDevices( map<int, wstring>* devices )
{
	m_pDevices = devices;
}

int CSelCamDlg2::getSel()
{
	return m_sel;
}