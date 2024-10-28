#include "StdAfx.h"
#include "Autorun.h"

CAutorun::CAutorun(bool bForAllUser, const char* entryName){
	m_bForAllUser = bForAllUser;
	m_sRegEntryName = entryName;
	char exePath[MAX_PATH];
	DWORD dwRet = GetModuleFileNameA(NULL, exePath, MAX_PATH);
	sprintf_s(m_sAppPath, MAX_PATH*2, "\"%s\" auto selectcam", exePath);
}

CAutorun::~CAutorun(void){
}

bool CAutorun::isInstalled(){
	bool bInstalled = false;
	HKEY hKey = openRegRunKey();

	char val[MAX_PATH]="";
	DWORD type;
	DWORD len = MAX_PATH;
	LONG res = ::RegQueryValueExA(hKey,m_sRegEntryName,NULL,&type,(LPBYTE)val,&len);
	if(res==ERROR_SUCCESS && type==REG_SZ){
		if(strcmp(val, m_sAppPath)==0)
			bInstalled = true;
	}
	::RegCloseKey(hKey);

	return bInstalled;
}

void CAutorun::install(){
	HKEY hKey = openRegRunKey();
	LONG lRet = ::RegSetValueExA(hKey,m_sRegEntryName,NULL,REG_SZ,(LPBYTE)m_sAppPath,(DWORD)strlen(m_sAppPath));
	::RegCloseKey(hKey);
}

void CAutorun::uninstall(){
	HKEY hKey = openRegRunKey();
	LONG lRet = ::RegDeleteKeyA(hKey, m_sRegEntryName);
	lRet = ::RegDeleteValueA(hKey, m_sRegEntryName);
	//todo: try enum key/values
	char buf[MAX_PATH] = "Software\\Microsoft\\Windows\\CurrentVersion\\Run\\";
	strcat_s(buf, MAX_PATH, m_sRegEntryName);
	lRet = ::RegDeleteValueA(hKey, buf);
	::RegCloseKey(hKey);
}

HKEY CAutorun::openRegRunKey()
{
	HKEY hKey;
	LPCSTR data_Set = "Software\\Microsoft\\Windows\\CurrentVersion\\Run";

	HKEY hParentKey;
	if(m_bForAllUser){
		hParentKey = HKEY_LOCAL_MACHINE;
	}else{
		hParentKey = HKEY_CURRENT_USER;
	}
	::RegOpenKeyExA(hParentKey,data_Set,0,KEY_READ|KEY_WRITE,&hKey);

	return hKey;
}