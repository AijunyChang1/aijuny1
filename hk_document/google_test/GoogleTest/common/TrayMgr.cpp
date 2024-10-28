#include "StdAfx.h"
#include "TrayMgr.h"
#include "Autorun.h"
#include <assert.h>

CTrayMgr::CTrayMgr(const char* pszTip)
	:m_bMute(false), m_pszTipText(pszTip)
{
}

CTrayMgr::~CTrayMgr(void){
}

LRESULT CTrayMgr::OnIconNotified( WPARAM wParam, LPARAM lParam, bool videoVisible, bool started ){
	UINT uID=(UINT) wParam;
	UINT uMouseMsg=(UINT) lParam;
	POINT pt;
	HMENU hMenu;

	//if (uMouseMsg == WM_RBUTTONDOWN || uMouseMsg == WM_LBUTTONDOWN)
	if (uMouseMsg == WM_RBUTTONUP || uMouseMsg == WM_LBUTTONUP)
	{
		switch(uID){
		case IDR_MAINFRAME:
			{
				GetCursorPos(&pt);
				//Pop Menu
				hMenu = ::LoadMenu(GetModuleHandleA(NULL), MAKEINTRESOURCE(IDR_TRAYMENU));
				hMenu = ::GetSubMenu(hMenu,0);
				assert(hMenu);

				//change text by status:
				if(started){
					::ModifyMenuA(hMenu, ID_TRAY_START, MF_BYCOMMAND, ID_TRAY_START, "Stop");
				}else{
					::ModifyMenuA(hMenu, ID_TRAY_START, MF_BYCOMMAND, ID_TRAY_START, "Start");
				}
				if(videoVisible){
					::ModifyMenuA(hMenu, ID_TRAY_VIDEO, MF_BYCOMMAND, ID_TRAY_VIDEO, "Hide Video");
				}else{
					::ModifyMenuA(hMenu, ID_TRAY_VIDEO, MF_BYCOMMAND, ID_TRAY_VIDEO, "Show Video");
				}

#ifdef ID_TRAY_MUTE
				if(m_bMute){
					::CheckMenuItem(hMenu, ID_TRAY_MUTE, MF_CHECKED);
				}else{
					::CheckMenuItem(hMenu, ID_TRAY_MUTE, MF_UNCHECKED);
				}
#endif

#ifdef ID_TRAY_MUTE
				if(m_bAutorun){
					::CheckMenuItem(hMenu, ID_TRAY_AUTOSTART, MF_CHECKED);
				}else{
					::CheckMenuItem(hMenu, ID_TRAY_AUTOSTART, MF_UNCHECKED);
				}
#endif

				::SetForegroundWindow(m_tnd.hWnd);
				::TrackPopupMenu(hMenu,0,pt.x,pt.y,0,m_tnd.hWnd,NULL);
			}
			break;

		default:
			break;
		}
	} 
	return 0;
}

void CTrayMgr::setState( State st ){
	switch(st){
		case PAUSED:
			m_tnd.hIcon = m_hIconPaused;
			break;
		case WELL:
			m_tnd.hIcon = m_hIconWell;
			break;
		case BAD:
			m_tnd.hIcon = m_hIconBad;
			break;
	}
}

void CTrayMgr::add(){
	Shell_NotifyIconA(NIM_ADD, &m_tnd);
}

void CTrayMgr::remove(){
	Shell_NotifyIconA(NIM_DELETE, &m_tnd);
}

void CTrayMgr::update(){
	Shell_NotifyIconA(NIM_MODIFY, &m_tnd);
}

void CTrayMgr::init( HWND hwnd, DWORD nID ){
	m_tnd.cbSize = sizeof(NOTIFYICONDATA);
	m_tnd.hWnd = hwnd;
	m_tnd.uID = nID;
	m_tnd.uFlags = NIF_MESSAGE | NIF_ICON | NIF_TIP;
	m_tnd.uCallbackMessage = WM_ICONNOTIFY;
	strcpy_s(m_tnd.szTip, 128, m_pszTipText);

	m_hIconWell   = LoadIcon(GetModuleHandleA(NULL), MAKEINTRESOURCE(IDI_MOBI16));
	m_hIconBad    = LoadIcon(GetModuleHandleA(NULL), MAKEINTRESOURCE(IDI_MOBI16));
	m_hIconPaused = LoadIcon(GetModuleHandleA(NULL), MAKEINTRESOURCE(IDI_MOBI16));
	//m_hIconBad    = LoadIcon(GetModuleHandleA(NULL), MAKEINTRESOURCE(IDI_MOBI16_ALERT));
	//m_hIconPaused = LoadIcon(GetModuleHandleA(NULL), MAKEINTRESOURCE(IDI_MOBI16_GREY));

	m_tnd.hIcon = m_hIconPaused;
}
