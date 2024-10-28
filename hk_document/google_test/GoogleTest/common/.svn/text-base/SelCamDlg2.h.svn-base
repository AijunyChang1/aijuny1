#pragma once
#include <map>
#include <string>

using namespace std;

class CSelCamDlg2 : public CDialogImpl<CSelCamDlg2>, public CMessageFilter
{
public:
	enum { IDD = IDD_SELCAM };

	CSelCamDlg2(void);
	~CSelCamDlg2(void);

	virtual BOOL PreTranslateMessage(MSG* pMsg);

	BEGIN_MSG_MAP(CSelCamDlg2)
		MESSAGE_HANDLER(WM_INITDIALOG, OnInitDialog)
		MESSAGE_HANDLER(WM_DESTROY, OnDestroy)
		COMMAND_ID_HANDLER(IDOK, OnOK)
		COMMAND_ID_HANDLER(IDCANCEL, OnCancel)
	END_MSG_MAP()

	LRESULT OnInitDialog(UINT /*uMsg*/, WPARAM /*wParam*/, LPARAM /*lParam*/, BOOL& /*bHandled*/);
	LRESULT OnDestroy(UINT /*uMsg*/, WPARAM /*wParam*/, LPARAM /*lParam*/, BOOL& /*bHandled*/);
	LRESULT OnOK(WORD /*wNotifyCode*/, WORD wID, HWND /*hWndCtl*/, BOOL& /*bHandled*/);
	LRESULT OnCancel(WORD /*wNotifyCode*/, WORD wID, HWND /*hWndCtl*/, BOOL& /*bHandled*/);

	void CloseDialog(int nVal);

	void setDevices(map<int, wstring>* devices);
	int getSel();

private:
	CListBox m_listWebcam;
	CComboBox m_cbFormats;

	map<int, wstring>* m_pDevices;
	int m_sel;
	int m_selFormat;
};
