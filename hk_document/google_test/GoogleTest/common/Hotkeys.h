#pragma once

#include <map>

using namespace std;

///\addtogroup CommonLib

///\brief This class helps to manage application's hotkeys.
class CHotkeys
{
	typedef pair<UINT, UINT> KeyCombine;
	typedef map<int, KeyCombine> HkMap;
	HkMap m_keys;
	HWND m_hwnd;
public:
	CHotkeys(void);
	~CHotkeys(void);

	bool addHotkey(int id, UINT modifiers, UINT vk);
	void install(HWND hwnd);
	void uninstall();
	LRESULT OnHotKey(WPARAM wParam, LPARAM lParam);
};
