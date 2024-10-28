#pragma once
#include "Resource.h"

#define WM_ICONNOTIFY	(WM_USER+200)

///\addtogroup CommonLib

///\brief This class helps to manage tray icon and menu.
class CTrayMgr
{
	const char *m_pszTipText;
	NOTIFYICONDATAA m_tnd;

	HICON m_hIconPaused;
	HICON m_hIconWell;
	HICON m_hIconBad;

	HWND m_hWnd;

	bool m_bMute;
	bool m_bAutorun;
public:
	enum State{
		PAUSED = 0,
		WELL,
		BAD
	};

	CTrayMgr(const char* pszTip="Teli");

	void init( HWND hwnd, DWORD nID );
	virtual ~CTrayMgr(void);

	void add();
	void remove();
	void update();
	void setState(State st);

	bool getMute() const { return m_bMute; }
	void setMute(bool val) { m_bMute = val; }
	bool getAutorun() const { return m_bAutorun; }
	void setAutorun(bool val) { m_bAutorun = val; }

	//OnIconNotified(WPARAM wParam, LPARAM lParam)
	///\brief Call this in WM_ICONNOTIFY message handler
	///@see CMainDlg::OnWmIconnotify.
	LRESULT OnIconNotified(WPARAM wParam, LPARAM lParam, bool videoVisible, bool started );
};
