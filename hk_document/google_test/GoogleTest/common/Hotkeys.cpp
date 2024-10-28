#include "StdAfx.h"
#include "Hotkeys.h"

#include "imm.h"
#include "Resource.h"
#include "Util.h"

CHotkeys::CHotkeys(void) : m_hwnd(NULL)
{
	m_keys[ID_TRAY_VIDEO] = pair<UINT,UINT>(MOD_ALT|MOD_SHIFT, 'V');
#ifdef ID_TRAY_START
	m_keys[ID_TRAY_START] = pair<UINT,UINT>(MOD_ALT|MOD_SHIFT, 'S');
#endif
	//m_keys[ID_DEBUG_SHOWFLASH] = pair<UINT,UINT>(MOD_ALT|MOD_SHIFT, 'F');
#ifdef ID_DEBUG_SHOWDIALOG
	m_keys[ID_DEBUG_SHOWDIALOG] = pair<UINT,UINT>(MOD_ALT|MOD_SHIFT, 'D');
#endif
}

CHotkeys::~CHotkeys(void)
{
}

bool CHotkeys::addHotkey( int id, UINT modifiers, UINT vk )
{
	if(m_hwnd){
		m_keys[id] = pair<UINT,UINT>(modifiers, vk);
		BOOL ret = RegisterHotKey(m_hwnd, id, modifiers, vk);
		return ret==TRUE;
	}else{
		return false;
	}
}

void CHotkeys::install( HWND hwnd )
{
	m_hwnd = hwnd;
	for(HkMap::iterator i=m_keys.begin(); i!=m_keys.end(); ++i){
		int id = i->first;
		UINT fsModifiers = i->second.first;
		UINT vk = i->second.second;
		BOOL ret = RegisterHotKey(hwnd, id, fsModifiers, vk);
		if(!ret){
			Logger::error("RegisterHotKey(fsModifiers:%d, vk=%d) fail, err=%d\n", fsModifiers, vk, GetLastError());
		}
	}
}

void CHotkeys::uninstall()
{
	for(HkMap::iterator i=m_keys.begin(); i!=m_keys.end(); ++i){
		BOOL ret = UnregisterHotKey(m_hwnd, i->first);
	}
}

LRESULT CHotkeys::OnHotKey( WPARAM wParam, LPARAM lParam )
{
	if(m_keys.find((int)wParam)!=m_keys.end()){
		PostMessage(m_hwnd, WM_COMMAND, wParam, 0);
	}
	return 0;
}
