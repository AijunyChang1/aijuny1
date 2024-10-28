#include "StdAfx.h"
#include "VirtualKey.h"

static struct{
	wchar_t *str;
	DWORD code;
}_codeMap[] = {
	{L"Left",	VK_LEFT},
	{L"Right",	VK_RIGHT},
	{L"Up",		VK_UP},
	{L"Down",	VK_DOWN},
	{L"Enter",	VK_RETURN},
	{L"Esc",	VK_ESCAPE},
	{L"Tab",	VK_TAB},
	{L"Backspace",	VK_BACK},
	{L"Home",	VK_HOME},
	{L"End",	VK_END},
	{L"PgUp",	VK_PRIOR},
	{L"PgDn",	VK_NEXT},
	{L"Insert",	VK_INSERT},
	{L"Delete",	VK_DELETE},
	{L"F1",		VK_F1},
	{L"F2",		VK_F2},
	{L"F3",		VK_F3},
	{L"F4",		VK_F4},
	{L"F5",		VK_F5},
	{L"F6",		VK_F6},
	{L"F7",		VK_F7},
	{L"F8",		VK_F8},
	{L"F9",		VK_F9},
	{L"F10",	VK_F10},
	{L"F11",	VK_F11},
	{L"F12",	VK_F12},
	{L"+",		VK_ADD},
	{L"-",		VK_SUBTRACT},
	{L"Space",	VK_SPACE},

	{L"Ctrl",	VK_CONTROL},
	{L"Shift",	VK_SHIFT},
	{L"Alt",	VK_MENU},
	{L"LWin",	VK_LWIN},
	{L"RWin",	VK_RWIN},

	{L"0",		0x30},
	{L"1",		0x31},
	{L"2",		0x32},
	{L"3",		0x33},
	{L"4",		0x34},
	{L"5",		0x35},
	{L"6",		0x36},
	{L"7",		0x37},
	{L"8",		0x38},
	{L"9",		0x39},

	{L"A",		0x41},
	{L"B",		0x42},
	{L"C",		0x43},
	{L"D",		0x44},
	{L"E",		0x45},
	{L"F",		0x46},
	{L"G",		0x47},
	{L"H",		0x48},
	{L"I",		0x49},
	{L"J",		0x4a},
	{L"K",		0x4b},
	{L"L",		0x4c},
	{L"M",		0x4d},
	{L"N",		0x4e},
	{L"O",		0x4f},
	{L"P",		0x50},
	{L"Q",		0x51},
	{L"R",		0x52},
	{L"S",		0x53},
	{L"T",		0x54},
	{L"U",		0x55},
	{L"V",		0x56},
	{L"W",		0x57},
	{L"X",		0x58},
	{L"Y",		0x59},
	{L"Z",		0x5a},
};

CVirtualKey::CVirtualKey(void)
{
}

CVirtualKey::~CVirtualKey(void)
{
}

WORD CVirtualKey::parse( wchar_t *s )
{
	if(s==0) return (WORD)0;

	for(int i=0; i<_countof(_codeMap); i++){
		if(_wcsicmp(s, _codeMap[i].str)==0){
			return (WORD)_codeMap[i].code;
		}
	}

	return (WORD)toupper(s[0]);
}

const wchar_t* CVirtualKey::toWString( WORD k )
{
	for(int i=0; i<_countof(_codeMap); i++){
		if(_codeMap[i].code==k){
			return _codeMap[i].str;
		}
	}

	return L"<Unknown key>";
}

const char* CVirtualKey::toString( WORD k )
{
	USES_CONVERSION;
	static char str[260];
	strcpy_s(str, 260, W2A(toWString(k)));
	return str;
}
