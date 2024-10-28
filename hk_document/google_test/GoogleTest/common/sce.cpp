#include "StdAfx.h"
#include "sce.h"

#include <windows.h>
#include <string.h>
#include "Util.h"

namespace sce{

#define LOG(msg) OutputDebugStringW(L##msg)
#define FAIL(n, msg) { LOG(msg); return (n); }
#define BACKUP_NAME (L"backupsol.tmp")
#define _SIG ("\x0\xbf\x0\x0")

	static int findstrend(char* buf, int buflen, const char* str){
		int slen = (int)strlen(str);
		for(int i=0; i<buflen-slen; i++){
			if(memcmp(buf+i, str, slen)==0) return i+slen;
		}
		return -1;
	}

	int setAlways( LPCWSTR fpath ){
		HANDLE h = CreateFileW(fpath, GENERIC_READ|GENERIC_WRITE, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);
		if(h==INVALID_HANDLE_VALUE){
			FAIL(1, "Can't open sol file.");
		}

		LOG("Open sol file.");

		char fbuf[1024];
		DWORD nRead=0;
		BOOL r = ReadFile(h, fbuf, 1024, &nRead, NULL);
		int e = ::GetLastError();
		if(!r){
			CloseHandle(h);
			FAIL(2, "Read file fail!");
		}

		if(nRead<=32){
			CloseHandle(h);
			FAIL(3, "Too short sol file.");
		}

		if(memcmp(fbuf, _SIG, sizeof(_SIG)-1)!=0){
			CloseHandle(h);
			FAIL(4, "Wrong file header!");
		}


		bool bFound = false;
		int pos = findstrend(fbuf, nRead, "\005allow\001");
		if(pos!=-1){
			bFound = true;
			if(!fbuf[pos]){
				DWORD curPos = ::SetFilePointer(h, LONG(pos), NULL, FILE_BEGIN);
				BYTE b = 1;
				DWORD nWritten=0;
				WriteFile(h, &b, 1, &nWritten, NULL);
			}
		}
		if(!bFound){
			CloseHandle(h);
			FAIL(5, "Can't found data seg1!");
		}

		bFound = false;
		pos = findstrend(fbuf, nRead, "\006always\001");
		if(pos!=-1){
			bFound = true;
			if(!fbuf[pos]){
				DWORD curPos = ::SetFilePointer(h, LONG(pos), NULL, FILE_BEGIN);
				BYTE b = 1;
				DWORD nWritten=0;
				WriteFile(h, &b, 1, &nWritten, NULL);
			}
		}
		if(!bFound){
			CloseHandle(h);
			FAIL(6, "Can't found data seg2!");
		}

		CloseHandle(h);
		return 0;
	}

	//************************************
	// Method:    set
	// FullName:  sce::set
	// Access:    public 
	// Returns:   void
	// Qualifier:
	// Parameter: bool bSetAlways: true enable webcam, false restore to previous settings
	//************************************
	void set(bool bSetAlways){
		WCHAR back_path[1024];
		::GetEnvironmentVariableW(L"TEMP", back_path, 1024);
		lstrcatW(back_path, L"\\");
		lstrcatW(back_path, BACKUP_NAME);

		wstring sCommonAppData;
		if(!FileSystem::getSpecialDirW(FileSystem::eCommonAppData, sCommonAppData)){
			Logger::error(L"Can't get common appdata folder.");
		}
		//WCHAR buf[1024];
		//DWORD ret = ::GetEnvironmentVariableW(L"APPDATA", buf, 1024);
		wstring fpath = sCommonAppData + L"\\Macromedia\\Flash Player\\macromedia.com\\support\\flashplayer\\sys\\#local\\settings.sol";
		OutputDebugStringW(fpath.c_str());

		if(bSetAlways){
			CopyFileW(fpath.c_str(), back_path, FALSE);
			setAlways(fpath.c_str());
		}else{
			CopyFileW(back_path, fpath.c_str(), FALSE);
			DeleteFileW(back_path);
		}
	}
}
