#include "StdAfx.h"
#include "Util.h"
#include <comdef.h>		// for using bstr_t class
#include <WINPERF.h>
#include <sstream>
#include <hash_set>
#include <atlenc.h>
#include <io.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <psapi.h>
#include <tlhelp32.h>
#include <vdmdbg.h>

//#include "sce.h"

#pragma comment(lib, "psapi.lib")

bool Logger::s_isOn = true;
bool Util::s_isDebugMode = false;
//FOR GETTING PROCESS ID AND CLOSE PROCESS
/*****************************************************************
 *                                                               *
 * Functions used to navigate through the performance data.      *
 *                                                               *
 *****************************************************************/

PPERF_OBJECT_TYPE FirstObject( PPERF_DATA_BLOCK PerfData )
{
    return( (PPERF_OBJECT_TYPE)((PBYTE)PerfData + 
        PerfData->HeaderLength) );
}

PPERF_OBJECT_TYPE NextObject( PPERF_OBJECT_TYPE PerfObj )
{
    return( (PPERF_OBJECT_TYPE)((PBYTE)PerfObj + 
        PerfObj->TotalByteLength) );
}

PPERF_INSTANCE_DEFINITION FirstInstance( PPERF_OBJECT_TYPE PerfObj )
{
    return( (PPERF_INSTANCE_DEFINITION)((PBYTE)PerfObj + 
        PerfObj->DefinitionLength) );
}

PPERF_INSTANCE_DEFINITION NextInstance( 
    PPERF_INSTANCE_DEFINITION PerfInst )
{
    PPERF_COUNTER_BLOCK PerfCntrBlk;

    PerfCntrBlk = (PPERF_COUNTER_BLOCK)((PBYTE)PerfInst + 
        PerfInst->ByteLength);

    return( (PPERF_INSTANCE_DEFINITION)((PBYTE)PerfCntrBlk + 
        PerfCntrBlk->ByteLength) );
}

PPERF_COUNTER_DEFINITION FirstCounter( PPERF_OBJECT_TYPE PerfObj )
{
    return( (PPERF_COUNTER_DEFINITION) ((PBYTE)PerfObj + 
        PerfObj->HeaderLength) );
}

PPERF_COUNTER_DEFINITION NextCounter( 
    PPERF_COUNTER_DEFINITION PerfCntr )
{
    return( (PPERF_COUNTER_DEFINITION)((PBYTE)PerfCntr + 
        PerfCntr->ByteLength) );
}


PPERF_COUNTER_BLOCK CounterBlock(PPERF_INSTANCE_DEFINITION PerfInst)
{
	return (PPERF_COUNTER_BLOCK) ((LPBYTE) PerfInst + PerfInst->ByteLength);
}

#define TOTALBYTES    64*1024
#define BYTEINCREMENT 1024

#define PROCESS_OBJECT_INDEX	230
#define PROC_ID_COUNTER			784

typedef BOOL (CALLBACK *PROCENUMPROC)(DWORD, WORD, LPTSTR, LPARAM);
typedef struct {
	DWORD          dwPID;
	PROCENUMPROC   lpProc;
	DWORD          lParam;
	BOOL           bEnd;
} EnumInfoStruct;

void Util::GetProcessID(LPCTSTR pProcessName, std::vector<DWORD>& SetOfPID){
	OSVERSIONINFO  osver;
	HINSTANCE      hInstLib  = NULL;
	HINSTANCE      hInstLib2 = NULL;
	HANDLE         hSnapShot = NULL;
	LPDWORD        lpdwPIDs  = NULL;
	PROCESSENTRY32 procentry;
	BOOL           bFlag;
	DWORD          dwSize;
	DWORD          dwSize2;
	DWORD          dwIndex;
	HMODULE        hMod;
	HANDLE         hProcess;
	TCHAR          szFileName[MAX_PATH];
	EnumInfoStruct sInfo;

	// ToolHelp Function Pointers.
	HANDLE (WINAPI *lpfCreateToolhelp32Snapshot)(DWORD, DWORD);
	BOOL (WINAPI *lpfProcess32First)(HANDLE, LPPROCESSENTRY32);
	BOOL (WINAPI *lpfProcess32Next)(HANDLE, LPPROCESSENTRY32);

	// PSAPI Function Pointers.
	BOOL (WINAPI *lpfEnumProcesses)(DWORD *, DWORD, DWORD *);
	BOOL (WINAPI *lpfEnumProcessModules)(HANDLE, HMODULE *, DWORD, 
		LPDWORD);
	DWORD (WINAPI *lpfGetModuleBaseName)(HANDLE, HMODULE, LPTSTR, DWORD);

	// VDMDBG Function Pointers.
	INT (WINAPI *lpfVDMEnumTaskWOWEx)(DWORD, TASKENUMPROCEX, LPARAM);

	// Retrieve the OS version
	osver.dwOSVersionInfoSize = sizeof(osver);
	if (!GetVersionEx(&osver))
		return;

	SetOfPID.clear();

	// If Windows NT 4.0
	if (osver.dwPlatformId == VER_PLATFORM_WIN32_NT
		&& osver.dwMajorVersion == 4) {

			__try {

				// Get the procedure addresses explicitly. We do
				// this so we don't have to worry about modules
				// failing to load under OSes other than Windows NT 4.0 
				// because references to PSAPI.DLL can't be resolved.
				hInstLib = LoadLibraryW(L"PSAPI.DLL");
				if (hInstLib == NULL)
					__leave;

				hInstLib2 = LoadLibraryW(L"VDMDBG.DLL");
				if (hInstLib2 == NULL)
					__leave;

				// Get procedure addresses.
				lpfEnumProcesses = (BOOL (WINAPI *)(DWORD *, DWORD, DWORD*))
					GetProcAddress(hInstLib, "EnumProcesses");

				lpfEnumProcessModules = (BOOL (WINAPI *)(HANDLE, HMODULE *,
					DWORD, LPDWORD)) GetProcAddress(hInstLib,
					"EnumProcessModules");

				lpfGetModuleBaseName = (DWORD (WINAPI *)(HANDLE, HMODULE,
					LPTSTR, DWORD)) GetProcAddress(hInstLib,
					"GetModuleBaseNameW");

				lpfVDMEnumTaskWOWEx = (INT (WINAPI *)(DWORD, TASKENUMPROCEX,
					LPARAM)) GetProcAddress(hInstLib2, "VDMEnumTaskWOWEx");

				if (lpfEnumProcesses == NULL 
					|| lpfEnumProcessModules == NULL 
					|| lpfGetModuleBaseName == NULL 
					|| lpfVDMEnumTaskWOWEx == NULL)
					__leave;


				dwSize2 = 256 * sizeof(DWORD);
				do {

					if (lpdwPIDs) {
						HeapFree(GetProcessHeap(), 0, lpdwPIDs);
						dwSize2 *= 2;
					}

					lpdwPIDs = (LPDWORD) HeapAlloc(GetProcessHeap(), 0, 
						dwSize2);
					if (lpdwPIDs == NULL)
						__leave;

					if (!lpfEnumProcesses(lpdwPIDs, dwSize2, &dwSize))
						__leave;

				} while (dwSize == dwSize2);

				// How many ProcID's did we get?
				dwSize /= sizeof(DWORD);

				// Loop through each ProcID.
				for (dwIndex = 0; dwIndex < dwSize; dwIndex++) {

					szFileName[0] = 0;

					// Open the process (if we can... security does not
					// permit every process in the system to be opened).
					hProcess = OpenProcess(
						PROCESS_QUERY_INFORMATION | PROCESS_VM_READ,
						FALSE, lpdwPIDs[dwIndex]);
					if (hProcess != NULL) {

						// Here we call EnumProcessModules to get only the
						// first module in the process. This will be the 
						// EXE module for which we will retrieve the name.
						if (lpfEnumProcessModules(hProcess, &hMod,
							sizeof(hMod), &dwSize2)) {

								// Get the module name
								if (!lpfGetModuleBaseName(hProcess, hMod,
									szFileName, sizeof(szFileName)))
									szFileName[0] = 0;
						}
						CloseHandle(hProcess);
					}
					// Regardless of OpenProcess success or failure, we
					// still call the enum func with the ProcID.
					//if (!lpProc(lpdwPIDs[dwIndex], 0, szFileName, lParam))
					//	break;
					if(_tcsicmp(szFileName, pProcessName)==0)
						SetOfPID.push_back(lpdwPIDs[dwIndex]);

					// Did we just bump into an NTVDM?
					if (_tcsicmp(szFileName, _T("NTVDM.EXE")) == 0) {

						// Fill in some info for the 16-bit enum proc.
						sInfo.dwPID = lpdwPIDs[dwIndex];
						//sInfo.lpProc = lpProc;
						//sInfo.lParam = (DWORD) lParam;
						sInfo.bEnd = FALSE;

						// Did our main enum func say quit?
						if (sInfo.bEnd)
							break;
					}
				}

			} __finally {

				if (hInstLib)
					FreeLibrary(hInstLib);

				if (hInstLib2)
					FreeLibrary(hInstLib2);

				if (lpdwPIDs)
					HeapFree(GetProcessHeap(), 0, lpdwPIDs);
			}

			// If any OS other than Windows NT 4.0.
	} else if (osver.dwPlatformId == VER_PLATFORM_WIN32_WINDOWS
		|| (osver.dwPlatformId == VER_PLATFORM_WIN32_NT
		&& osver.dwMajorVersion > 4)) {

			__try {

				hInstLib = LoadLibraryW(L"Kernel32.DLL");
				if (hInstLib == NULL)
					__leave;

				// If NT-based OS, load VDMDBG.DLL.
				if (osver.dwPlatformId == VER_PLATFORM_WIN32_NT) {
					hInstLib2 = LoadLibraryW(L"VDMDBG.DLL");
					if (hInstLib2 == NULL)
						__leave;
				}

				lpfCreateToolhelp32Snapshot =
					(HANDLE (WINAPI *)(DWORD,DWORD))
					GetProcAddress(hInstLib, "CreateToolhelp32Snapshot");

				

				lpfProcess32First =
					(BOOL (WINAPI *)(HANDLE,LPPROCESSENTRY32))
					GetProcAddress(hInstLib, "Process32FirstW");

				lpfProcess32Next =
					(BOOL (WINAPI *)(HANDLE,LPPROCESSENTRY32))
					GetProcAddress(hInstLib, "Process32NextW");

				if (lpfProcess32Next == NULL
					|| lpfProcess32First == NULL
					|| lpfCreateToolhelp32Snapshot == NULL)
					__leave;

				if (osver.dwPlatformId == VER_PLATFORM_WIN32_NT) {
					lpfVDMEnumTaskWOWEx = (INT (WINAPI *)(DWORD, TASKENUMPROCEX,
						LPARAM)) GetProcAddress(hInstLib2, "VDMEnumTaskWOWEx");
					if (lpfVDMEnumTaskWOWEx == NULL)
						__leave;
				}

				// Get a handle to a Toolhelp snapshot of all processes.
				hSnapShot = lpfCreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
				if (hSnapShot == INVALID_HANDLE_VALUE) {
					FreeLibrary(hInstLib);
					return;
				}

				// Get the first process' information.
				procentry.dwSize = sizeof(PROCESSENTRY32);
				bFlag = lpfProcess32First(hSnapShot, &procentry);

				// While there are processes, keep looping.
				while (bFlag) {

					// Call the enum func with the filename and ProcID.
					//if (lpProc(procentry.th32ProcessID, 0,
					//	procentry.szExeFile, lParam)) {

					if(_tcsicmp(procentry.szExeFile, pProcessName)==0)
					//if(strcmp(procentry.szExeFile, pProcessName)==0)
						SetOfPID.push_back(procentry.th32ProcessID);

							// Did we just bump into an NTVDM?
							if (_tcsicmp(procentry.szExeFile, _T("NTVDM.EXE")) == 0) {

								// Fill in some info for the 16-bit enum proc.
								sInfo.dwPID = procentry.th32ProcessID;
								//sInfo.lpProc = lpProc;
								//sInfo.lParam = (DWORD) lParam;
								sInfo.bEnd = FALSE;

								// Did our main enum func say quit?
								if (sInfo.bEnd)
									break;
							}

							procentry.dwSize = sizeof(PROCESSENTRY32);
							bFlag = lpfProcess32Next(hSnapShot, &procentry);

					//} else
					//	bFlag = FALSE;
				}

			} __finally {

				if (hInstLib)
					FreeLibrary(hInstLib);

				if (hInstLib2)
					FreeLibrary(hInstLib2);
			}

	} else
		return;

	// Free the library.
	FreeLibrary(hInstLib);

	return;
}
void Util::CloseProcessByID(DWORD pID){
	HANDLE hProcess = OpenProcess(PROCESS_ALL_ACCESS,FALSE,pID);
	DWORD fdwExit = 0;
	GetExitCodeProcess(hProcess, &fdwExit);
	TerminateProcess(hProcess, fdwExit);
	CloseHandle(hProcess);
}

HWND Util::GetWindowHandle(const wchar_t* pName){
	/*std::vector<DWORD> SetOfPID;
	Util::GetProcessID(pName,SetOfPID);			
	if (!SetOfPID.empty()){		// Process is running
		for (int i=0;i < SetOfPID.size(); i++)
		{	
			HWND h = ::GetTopWindow(0 );
			while ( h )
			{
				  DWORD pid;
				  DWORD dwTheardId = ::GetWindowThreadProcessId( h,&pid);
				 if ( pid == SetOfPID[i])
				 {
					// here h is the handle to the window
					  return h;
				 }
				 h = ::GetNextWindow( h , GW_HWNDNEXT);
			}
		}
	}/**/
	return NULL;
}
//Hide other window except flash and webcam setting window
void Util::HideOtherWindow(HWND wcsHWND, HWND flashHWND){
		HWND h = ::GetTopWindow(0 );
		while ( h )
		{
			if(h != wcsHWND && h != flashHWND){
				::ShowWindow(h,SW_HIDE);
			}
			 h = ::GetNextWindow( h , GW_HWNDNEXT);
		}
}

// Desc    : Clicks the left mouse button down and releases it.
// Returns : Nothing.
//
void Util::LeftMouseClick()
{  
	INPUT    Input={0};													// Create our input.

	Input.type        = INPUT_MOUSE;									// Let input know we are using the mouse.
	Input.mi.dwFlags  = MOUSEEVENTF_LEFTDOWN;							// We are setting left mouse button down.
	SendInput( 1, &Input, sizeof(INPUT) );								// Send the input.

	ZeroMemory(&Input,sizeof(INPUT));									// Fills a block of memory with zeros.
	Input.type        = INPUT_MOUSE;									// Let input know we are using the mouse.
	Input.mi.dwFlags  = MOUSEEVENTF_LEFTUP;								// We are setting left mouse button up.
	SendInput( 1, &Input, sizeof(INPUT) );								// Send the input.
}

//
// Desc    : Gets the cursors current position on the screen.
// Returns : The mouses current on screen position.
// Info    : Used a static POINT, as sometimes it would return trash values
//
POINT Util::GetMousePosition()
{
	static POINT m;
	POINT mouse;
	GetCursorPos(&mouse);
	m.x = mouse.x;
	m.y = mouse.y;
	return m;
}

//
// Desc    : Sets the cursors position to the point you enter (POINT& mp).
// Returns : Nothing.
//
void Util::SetMousePosition(POINT& mp)
{
	long fScreenWidth	    = GetSystemMetrics( SM_CXSCREEN ) - 1; 
	long fScreenHeight	    = GetSystemMetrics( SM_CYSCREEN ) - 1; 

	// http://msdn.microsoft.com/en-us/library/ms646260(VS.85).aspx
	// If MOUSEEVENTF_ABSOLUTE value is specified, dx and dy contain normalized absolute coordinates between 0 and 65,535.
	// The event procedure maps these coordinates onto the display surface.
	// Coordinate (0,0) maps onto the upper-left corner of the display surface, (65535,65535) maps onto the lower-right corner.
	float fx		        = mp.x * ( 65535.0f / fScreenWidth  );
	float fy		        = mp.y * ( 65535.0f / fScreenHeight );		  
				
	INPUT Input             = { 0 };			
	Input.type		        = INPUT_MOUSE;

	Input.mi.dwFlags	    = MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE;
				
	Input.mi.dx		        = (long)fx;
	Input.mi.dy		        = (long)fy;

	SendInput(1,&Input,sizeof(INPUT));
}
////send "WIN_KEY + D" to minimize all the windows to task bar
void Util::PressWindowAndDKey(){
	INPUT input[4];
	memset(input,0,sizeof(input));
	input[0].type = input[1].type = input[2].type = input[3].type = INPUT_KEYBOARD;
	input[0].ki.wVk = input[2].ki.wVk = VK_LWIN;
	input[0].ki.wScan = input[2].ki.wScan = MapVirtualKey(VK_LWIN, 0);
	input[1].ki.wVk = input[3].ki.wVk = 'D';
	input[1].ki.wScan = input[3].ki.wScan = MapVirtualKey('D', 0);
	input[2].ki.dwFlags = input[3].ki.dwFlags = KEYEVENTF_KEYUP;

	//CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
	UINT n = 0;
	for(size_t i=0; i<4; Sleep(10),i++){
		SendInput((UINT)1, input+i, sizeof(INPUT));
	}	
}
//END FOR GET PRECESS ID AND CLOSE PREOCESS processing
void Util::checkDebugMode(){
	if(GetAsyncKeyState(VK_CONTROL)&0x8000){
		s_isDebugMode = true;
	}
}

bool Util::isDebugMode(){
	return s_isDebugMode;
}

bool Util::base64FromFile( const char* path, char* &strB64 )
{
	HANDLE hFile = CreateFileA(path, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);   

	if(hFile){
		DWORD dwJpgSize = GetFileSize(hFile, NULL);   
		HANDLE hFileMapping = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, dwJpgSize, NULL);   

		int dwJpgBase64Size = Base64EncodeGetRequiredLength(dwJpgSize);
		char *lpJpgBase64 = new char[dwJpgBase64Size+1];
		//char *lpJpgBase64 = strB64.GetBuffer(dwJpgBase64Size+1);
		LPVOID lpJpgData = MapViewOfFile(hFileMapping, FILE_MAP_READ, 0, 0, 0);
		BOOL ret = Base64Encode((BYTE*)lpJpgData, dwJpgSize, lpJpgBase64, &dwJpgBase64Size, ATL_BASE64_FLAG_NOCRLF);
		ATLASSERT(ret);
		lpJpgBase64[dwJpgBase64Size] = 0;
		UnmapViewOfFile(lpJpgData);   
		CloseHandle(hFileMapping);   
		CloseHandle(hFile);

		//strB64.ReleaseBuffer();
		strB64 = lpJpgBase64;
		return true;
	}else{
		return false;
	}
}

DWORD Util::pidFromHWND( HWND hwnd )
{
	DWORD pid;
	DWORD tid = GetWindowThreadProcessId(hwnd, &pid);
	return pid;
}

int Util::procPathFromPID( DWORD pid, char* buf, int buflen, bool nameOnly )
{
	int byteCopied = 0;

	HANDLE proc;
	if (proc = OpenProcess(PROCESS_QUERY_INFORMATION, false, pid)) {
		char path[MAX_PATH];
		DWORD pathLen;
		if (pathLen = GetProcessImageFileNameA(proc, path, _countof(path))) {
			errno_t err;
			if(nameOnly){
				const char *base = strrchr(path, _T('\\'));
				if (base) {
					base++;
				} else {
					base = path;
				}
				err = strcpy_s(buf, buflen, base);
			}else{
				err = strcpy_s(buf, buflen, path);
			}

			if (err) {
				Logger::error("Failed to copy ProcessImageFileName <%d>", err);
				buf[0] = 0;
				byteCopied = 0;
			} else {
				//Logger::info("Found ProcessImageFileName base <%s>", buf);
				byteCopied = pathLen;
			}
		} else {
			// failed to get the process name
			Logger::error("GetProcessImageFileName returned error <%d>", GetLastError());
			byteCopied = 0;
		}

		CloseHandle(proc);
	}

	return byteCopied;
}

int Util::getWindowProcPath( HWND hWnd, char* buffer, int count, bool nameOnly )
{
	// Return the process name
	DWORD pid = pidFromHWND(hWnd);
	//Logger::info("Foreground Window PID = <%x>", pid);

	return procPathFromPID(pid, buffer, count, nameOnly);
}

int Util::drawBuf( HDC hdc, char* buf, int w, int h, int bitcount, int destW, int destH, int destX, int destY )
{
	BITMAPINFO bmi;
	BITMAPINFOHEADER* bmih = &(bmi.bmiHeader);

	memset( bmih, 0, sizeof(*bmih));
	bmih->biSize = sizeof(BITMAPINFOHEADER);
	bmih->biWidth = w;
	bmih->biHeight = h;
	bmih->biPlanes = 1;
	bmih->biBitCount = (unsigned short)bitcount;
	bmih->biCompression = BI_RGB;

	int iRet = 0;
	bool stretch = (destW!=-1 && destH!=-1);
	if(stretch){
		//use stretch
		SetStretchBltMode(hdc, COLORONCOLOR);
		iRet = StretchDIBits(hdc, destX, destY, destW, destH, 0, 0, w, h, buf, &bmi, DIB_RGB_COLORS,SRCCOPY);
	}else{
		//use no stretch
		iRet = SetDIBitsToDevice(hdc, destX, destY, w, h, 0, 0, 0, h, buf+(w*3*(h-1)), &bmi, DIB_RGB_COLORS);
	}
	return iRet;
}

struct _FindDescendantsS{
	const char* clz;
	const char* text;
	const DWORD pid;	//0 for all process
	HWND  ret;
	static BOOL CALLBACK proc( HWND hwnd, LPARAM lParam ){
		_FindDescendantsS *fws = reinterpret_cast<_FindDescendantsS *>(lParam);
		bool found = true;

		char sClz[MAX_PATH];
		GetClassNameA(hwnd, sClz, MAX_PATH);
		if(NULL!=fws->clz && lstrcmpA(sClz, fws->clz)!=0)
			found = false;

		//check pid
		if(fws->pid){
			DWORD pid = Util::pidFromHWND(hwnd);
			//DWORD tid = GetWindowThreadProcessId(hwnd, &pid);
			if(pid!=fws->pid) found = false;
		}

		if(found){
			char sText[MAX_PATH];
			GetWindowTextA(hwnd, sText, MAX_PATH);
			if(NULL!=fws->text && lstrcmpA(sText, fws->text)!=0)
				found = false;
		}
		if(found){
			fws->ret =	 hwnd;
			return FALSE;
		}else{
			HWND h2 = Util::FindDescendants(hwnd, fws->clz, fws->text);
			if(h2){
				fws->ret = h2;
				return FALSE;
			}else
				return TRUE;
		}
	}
};
HWND Util::FindDescendants( HWND hParent, const char* clz, const char* text )
{
	_FindDescendantsS fd = {clz, text, -1, NULL};
	EnumChildWindows(hParent, _FindDescendantsS::proc, reinterpret_cast<LPARAM>(&fd));
	return fd.ret;
}
HWND Util::FindDescendants( HWND hParent, const char* clz, const char* text, DWORD pid )
{
	_FindDescendantsS fd = {clz, text, pid, NULL};
	EnumChildWindows(hParent, _FindDescendantsS::proc, reinterpret_cast<LPARAM>(&fd));
	return fd.ret;
}

//find window whose class and title mathed with given parameters.
struct _FindWindowS{
	const char* clz;
	const char* text;
	HWND  ret;
	static BOOL CALLBACK proc( HWND hwnd, LPARAM lParam ){
		_FindWindowS *fws = reinterpret_cast<_FindWindowS *>(lParam);
		bool found = true;

		char sClz[MAX_PATH];
		GetClassNameA(hwnd, sClz, MAX_PATH);
		if(NULL!=fws->clz && lstrcmpA(sClz, fws->clz)!=0)
			found = false;

		if(found){
			char sText[MAX_PATH];
			GetWindowTextA(hwnd, sText, MAX_PATH);
			//match title at only beginning
			if(NULL!=fws->text && strstr(sText, fws->text)!=sText)
				found = false;
		}
		if(found){
			fws->ret = hwnd;
			return FALSE;
		}else{
			return TRUE;
		}
	}
};
HWND Util::FindWindow( const char* clz, const char* text )
{
	_FindWindowS fws = {clz, text, NULL};
	EnumWindows(_FindWindowS::proc, reinterpret_cast<LPARAM>(&fws));
	return fws.ret;
}

//replace occurence of t in s to r.
std::string Util::replace( const char* s, const char*t, const char* r ){
	if( !s || !t || !r ) return 0;

	size_t lenS = strlen(s);
	size_t lenT = strlen(t);
	size_t lenR = strlen(r);

	vector<char*> hits(lenS/lenT+1);

	int count = 0;
	char* f=(char*)s;
	while(f=(char*)strstr(f, t)){
		hits[count++] = (char*)f;
		f += lenT;
	}
	hits[count] = (char*)s + lenS;

	string sRet;
	sRet.reserve(lenS+count*(lenR-lenT)+1);

	//process beginning
	sRet.append(s, hits[0]-s);

	for(int j=0; j<count; ++j){
		//replace t with r;
		sRet.append(r, lenR);
		//copy non-replaced chars
		sRet.append(hits[j]+lenT, hits[j+1] - hits[j] - lenT);
	}
	return sRet;
}

int Util::split( const string& input, const string& delimiter, vector<string>& results, bool includeEmpties /*= false*/ ){
	if(input.size()==0 || delimiter.size()==0) return 0;

	int numFound = 0;
	string::size_type posBegin = 0;
	string::size_type posEnd = 0;
	string::size_type len = input.length();
	while(posEnd!=string::npos){
		posEnd = input.find_first_of(delimiter, posBegin);
		if(posEnd==string::npos){
			if(posBegin<len){
				++numFound;
				results.push_back(input.substr(posBegin));
			}
		}else{
			if(posBegin<posEnd){
				++numFound;
				results.push_back(input.substr(posBegin, posEnd-posBegin));
			}
			if(posEnd+1<len){
				posBegin=posEnd+1;
			}
		}
	}
	return numFound;
}

int Util::split( const wstring& input, const wstring& delimiter, vector<wstring>& results, bool includeEmpties /*= false*/ ){
	if(input.size()==0 || delimiter.size()==0) return 0;

	int numFound = 0;
	wstring::size_type posBegin = 0;
	wstring::size_type posEnd = 0;
	wstring::size_type len = input.length();
	while(posEnd!=wstring::npos){
		posEnd = input.find_first_of(delimiter, posBegin);
		if(posEnd==wstring::npos){
			if(posBegin<len){
				++numFound;
				results.push_back(input.substr(posBegin));
			}
		}else{
			if(posBegin<posEnd){
				++numFound;
				results.push_back(input.substr(posBegin, posEnd-posBegin));
			}
			if(posEnd+1<len){
				posBegin=posEnd+1;
			}
		}
	}
	return numFound;
}

string Util::join( const string& joiner, vector<string>& parts ){
	string output;
	for(size_t i=0; i<parts.size(); i++){
		if(output.length()!=0){
			output += joiner;
		}
		output += parts[i];
	}
	return output;
}

int Util::enumTopWindowsForExe( string exeName, vector<HWND> &winList )
{
	int n=0;
	for(HWND h=::FindWindow(NULL, NULL); h!=NULL; h=GetWindow(h, GW_HWNDNEXT)){
		char sText[MAX_PATH] = "";
		char sClz[MAX_PATH] = "";
		GetWindowTextA(h, sText, MAX_PATH);
		GetClassNameA(h, sClz, MAX_PATH);

		char fullPath[MAX_PATH];
		getWindowProcPath(h, fullPath, MAX_PATH);

		const char* exePath = strrchr(fullPath, '\\');
		if(exePath==NULL)
			exePath = fullPath;
		else
			exePath++;
		if(_stricmp(exePath, exeName.c_str())==0){
			winList.push_back(h);
			n++;
		}
	}
	return n;
}

bool Util::saveString( const char* path, const char* data )
{
	FILE *fp = NULL;
	if(fopen_s(&fp, path, "wb")==0){
		fwrite(data, 1, strlen(data), fp);
		fclose(fp);
		return true;
	}
	return false;
}

long Util::getFileLen( const char* path )
{
	long sz = -1;
	int fd = 0;
	if(_sopen_s(&fd, path,_O_RDONLY, _SH_DENYNO, _S_IREAD)==0){
		if(fd!=-1){
			sz = _filelength(fd);
			_close(fd);
		}
		return sz;
	}
	return -1;
}

long Util::getFileLen( const wchar_t* path )
{
	long sz = -1;
	int fd = 0;
	if(_wsopen_s(&fd, path,_O_RDONLY, _SH_DENYNO, _S_IREAD)==0){
		if(fd!=-1){
			sz = _filelength(fd);
			_close(fd);
		}
		return sz;
	}
	return -1;
}

bool Util::loadData( const char* path, void* data, size_t maxlen )
{
	FILE *fp = NULL;
	if(fopen_s(&fp, path, "rb")==0){
		fread(data, 1, maxlen, fp);
		fclose(fp);
		return true;
	}
	return false;
}

bool Util::loadData( const wchar_t* path, void* data, size_t maxlen )
{
	FILE *fp = NULL;
	if(_wfopen_s(&fp, path, L"rb")==0){
		fread(data, 1, maxlen, fp);
		fclose(fp);
		return true;
	}
	return false;
}

bool Util::saveData( const char* path, void* data, size_t len )
{
	FILE *fp = NULL;
	if(fopen_s(&fp, path, "wb")==0){
		fwrite(data, 1, len, fp);
		fclose(fp);
		return true;
	}
	return false;
}

bool Util::fileExists( const char* path )
{
	errno_t e = _access_s(path, 0);
	return (e==0);
}

bool Util::fileExists( const wchar_t* path )
{
	errno_t e = _waccess_s(path, 0);
	return (e==0);
}

bool Util::copyFile( const char* pathSrc, const char* pathDst )
{
	FILE *fpIn = NULL;
	FILE *fp = NULL;
	if(fopen_s(&fpIn, pathSrc, "rb")==0 && fopen_s(&fp, pathDst, "wb")==0){
		char buf[1024];
		size_t bytesRead = 0;
		while(bytesRead=fread(buf, 1, 1024, fpIn)){
			fwrite(buf, 1, bytesRead, fp);
		}
		fclose(fp);
		fclose(fpIn);
		return true;
	}
	return false;
}

void Util::showCurDir( const char* msg )
{
	char buf[MAX_PATH];
	GetCurrentDirectoryA(MAX_PATH, buf);
	Logger::log("%s: dir=%s", msg, buf);
}

bool Util::prefixExePath( wchar_t* buf, const wchar_t* baseName )
{
	GetModuleFileNameW(NULL, buf, MAX_PATH);
	wchar_t *pSlash = (wchar_t*)wcsrchr( buf, L'\\' );
	if(pSlash){
		wchar_t* sEnd = buf+MAX_PATH;
		size_t bufSize = sEnd-(pSlash+1);
		if(wcsncpy_s( pSlash+1, bufSize, baseName, _TRUNCATE)==0){
			return true;
		}
	}
	return false;
}

DWORD Util::getWinVer( void )
{
	OSVERSIONINFO osVer;
	osVer.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	BOOL bRet = GetVersionEx(&osVer);
	return osVer.dwMajorVersion;
}

bool Util::isVista( void )
{
	OSVERSIONINFO osVer;
	osVer.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	BOOL bRet = GetVersionEx(&osVer);
	return (osVer.dwMajorVersion==6);
}

char* Util::strtolower( char* s )
{
	char* p = s;
	while(*p){
		*p = tolower(*p);
		p++;
	}
	return s;
}

const string Util::strtolower(const string& s )
{
	string cpy = s;
	for(size_t i=0; i<s.size(); i++){
		cpy[i] = tolower(s[i]);
	}
	return cpy;
}

const wstring Util::strtolower(const wstring& s )
{
	wstring cpy = s;
	for(size_t i=0; i<s.size(); i++){
		cpy[i] = tolower(s[i]);
	}
	return cpy;
}

std::wstring Util::toUtf16( const char* sBuf, int nLen, UINT codePage )
{
	wchar_t *wBuf = new wchar_t[nLen+1];
	int ret = MultiByteToWideChar(codePage, 0, sBuf, int(nLen), wBuf, int(nLen+1));
	wBuf[ret] = 0;
	wstring sU = wBuf;

	delete[] wBuf;
	return sU;
}

string Util::toUtf8( const char* sBuf, int nLen, UINT codePage )
{
	wchar_t *wBuf = new wchar_t[nLen+1];
	char *u8Buf = new char[nLen+nLen/2+2];

	int ret = MultiByteToWideChar(codePage, 0, sBuf, int(nLen), wBuf, int(nLen+1));
	wBuf[ret] = 0;

	ret = WideCharToMultiByte(CP_UTF8, 0, wBuf, ret, u8Buf, int(nLen+nLen/2+2), NULL, NULL);
	u8Buf[ret] = 0;
	string sU8 = u8Buf;

	delete[] u8Buf;
	delete[] wBuf;
	return sU8;
}

string Util::toUtf8( const wchar_t* wsBuf, int nLen )
{
	int bufLen = nLen*3+4;
	char *u8Buf = new char[bufLen];

	int ret = WideCharToMultiByte(CP_UTF8, 0, wsBuf, nLen, u8Buf, bufLen, NULL, NULL);
	if(!ret){
		DWORD lastError = GetLastError();
		if(lastError==ERROR_INSUFFICIENT_BUFFER){
			delete[] u8Buf;
			bufLen = WideCharToMultiByte(CP_UTF8, 0, wsBuf, -1, NULL, 0, NULL, NULL);
			u8Buf = new char[bufLen+1];
			ret = WideCharToMultiByte(CP_UTF8, 0, wsBuf, nLen, u8Buf, bufLen, NULL, NULL);
		}
	}
	u8Buf[ret] = 0;
	string sU8 = u8Buf;

	delete[] u8Buf;
	return sU8;
}

const wchar_t* Util::getExt( const wchar_t* fileName )
{
	const wchar_t *pRet = wcsrchr(fileName, L'.');
	if(pRet){
		return pRet+1;
	}else{
		return fileName + wcslen(fileName);
	}
}

bool Util::endsWith( const string& s, const string& ends )
{
	size_t nLenStr = s.size();
	size_t nLenEnd = ends.size();
	if(nLenStr>=nLenEnd){
		if(s.substr(nLenStr-nLenEnd)==ends){
			return true;
		}
	}
	return false;
}

bool Util::endsWith( const wstring& s, const wstring& ends )
{
	size_t nLenStr = s.size();
	size_t nLenEnd = ends.size();
	if(nLenStr>=nLenEnd){
		if(s.substr(nLenStr-nLenEnd)==ends){
			return true;
		}
	}
	return false;
}

string Util::xmlEscape( const string& sBuf )
{
	ostringstream ss;
	size_t len = sBuf.size();
	for(size_t i=0; i<len; i++){
		int ch = sBuf[i];
		switch(ch)
		{
		case '<':
			ss << "&lt;";
			break;
		case '>':
			ss << "&gt;";
			break;
		case '&':
			ss << "&amp;";
			break;
		case '\'':
			ss << "&apos;";
			break;
		case '\"':
			ss << "&quot;";
			break;
		default:
			ss.put(ch);
		}
	}
	return ss.str();
}

wstring Util::xmlEscape( const wstring& sBuf )
{
	wostringstream ss;
	size_t len = sBuf.size();
	for(size_t i=0; i<len; i++){
		int ch = sBuf[i];
		switch(ch)
		{
		case L'<':
			ss << L"&lt;";
			break;
		case L'>':
			ss << L"&gt;";
			break;
		case L'&':
			ss << L"&amp;";
			break;
		case L'\'':
			ss << L"&apos;";
			break;
		case L'\"':
			ss << L"&quot;";
			break;
		default:
			ss.put(ch);
		}
	}
	return ss.str();
}

void Util::enableSwfCam(){
	//sce::set(true);
}

void Util::restoreSwfCam(){
	//sce::set(false);
}

void Util::showThreadPriority( const char* name )
{
	HANDLE hThread = GetCurrentThread();
	int tp = GetThreadPriority(hThread);
	BOOL bBoost;
	BOOL bRet = GetThreadPriorityBoost(hThread, &bBoost);
	if(bRet){
		Logger::info("[%s] thread, priority=%d, boost=%d\n", name, tp, bBoost);
	}else{
		Logger::info("[%s] thread, priority=%d", name, tp);
	}
}

Logger::Level Logger::s_level = Logger::INFO;

void Logger::logV( const char* fmt, const char* prefix, va_list args )
{
	if(!s_isOn) return;

	char sbuf[MAX_PATH];
	_vsnprintf_s(sbuf, MAX_PATH, _TRUNCATE, fmt, args);
	if(prefix){
		char sPrefixed[MAX_PATH];
		//s.Format("[%s]\t", prefix);
		_snprintf_s(sPrefixed, MAX_PATH, _TRUNCATE, "[%s]\t%s\n", prefix, sbuf);
		//strncat_s(sPrefixed, MAX_PATH, sbuf, _TRUNCATE);
		OutputDebugStringA(sPrefixed);
	}else{
		strncat_s(sbuf, MAX_PATH, "\n", _TRUNCATE);
		OutputDebugStringA(sbuf);
	}
}

void Logger::logV( const wchar_t* fmt, const wchar_t* prefix, va_list args )
{
	if(!s_isOn) return;

	wchar_t sbuf[MAX_PATH];
	_vsnwprintf_s(sbuf, MAX_PATH, _TRUNCATE, fmt, args);
	if(prefix){
		wchar_t sPrefixed[MAX_PATH];
		_snwprintf_s(sPrefixed, MAX_PATH, _TRUNCATE, L"[%s]\t%s\n", prefix, sbuf);
		//wcsncat_s(sPrefixed, MAX_PATH, sbuf, _TRUNCATE);
		OutputDebugStringW(sPrefixed);
	}else{
		wcsncat_s(sbuf, MAX_PATH, L"\n", _TRUNCATE);
		OutputDebugStringW(sbuf);
	}
}

void Logger::log( const char* fmt, ... )
{
	va_list args;
	va_start(args, fmt);
	logV(fmt, NULL, args);
	va_end(args);
}

void Logger::log( const wchar_t* fmt, ... )
{
	va_list args;
	va_start(args, fmt);
	logV(fmt, NULL, args);
	va_end(args);
}
void Logger::info( const char* fmt, ... )
{
	if(s_level>INFO) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, "info", args);
	va_end(args);
}

void Logger::info( const wchar_t* fmt, ... )
{
	if(s_level>INFO) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, L"info", args);
	va_end(args);
}

void Logger::warn( const char* fmt, ... )
{
	if(s_level>WARN) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, "warning", args);
	va_end(args);
}

void Logger::warn( const wchar_t* fmt, ... )
{
	if(s_level>WARN) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, L"warning", args);
	va_end(args);
}

void Logger::error( const char* fmt, ... )
{
	if(s_level>ERR) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, "error", args);
	va_end(args);
}

void Logger::error( const wchar_t* fmt, ... )
{
	if(s_level>ERR) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, L"error", args);
	va_end(args);
}

void Logger::debug( const char* fmt, ... )
{
	if(s_level>DBG) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, "debug", args);
	va_end(args);
}

void Logger::debug( const wchar_t* fmt, ... )
{
	if(s_level>DBG) return;
	va_list args;
	va_start(args, fmt);
	logV(fmt, L"debug", args);
	va_end(args);
}

namespace FileSystem{
	bool getSpecialDirA( FolderType ft, string &sPath )
	{
		char buf[MAX_PATH];
		if(::SHGetSpecialFolderPathA(NULL, buf, ft, TRUE)){
			sPath = buf;
			return true;
		}else{
			return false;
		}
	}

	bool getSpecialDirW( FolderType ft, wstring &sPath )
	{
		wchar_t buf[MAX_PATH];
		if(::SHGetSpecialFolderPathW(NULL, buf, ft, TRUE)){
			sPath = buf;
			return true;
		}else{
			return false;
		}
	}

	bool getDirFiles( const wchar_t* dirPath, vector<wstring> &files )
	{
		WIN32_FIND_DATAW wfd;
		ZeroMemory(&wfd, sizeof(wfd));
		HANDLE hFFF = FindFirstFileW(dirPath, &wfd);
		if(hFFF){
			do{
				wstring fname = wfd.cFileName;
				if(wfd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY){
					fname+=L"\\";
				}
				files.push_back(fname);
			}while(FindNextFileW(hFFF, &wfd));
			FindClose(hFFF);
			return true;
		}else{
			return false;
		}
	}

	CFind::CFind( const wchar_t* dirPath ) :m_dirPath(dirPath)
	{

	}

	bool CFind::run()
	{
		wstring sDirPat = m_dirPath;
		sDirPat += L"\\*";

		return _walk(sDirPat);
	}

	bool CFind::onItem( WIN32_FIND_DATAW &wfd )
	{
		if(wfd.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY){
			if(wfd.cFileName[0]!=L'.')
				return onDirItem(wfd);
			else
				return true;
		}else{
			return onFileItem(wfd);
		}
	}

	bool CFind::_walk( wstring &sDirPat )
	{
		bool ret=true;
		WIN32_FIND_DATAW wfd;
		ZeroMemory(&wfd, sizeof(wfd));
		HANDLE hFFF = FindFirstFileW(sDirPat.c_str(), &wfd);
		if(hFFF){
			do{
				ret = onItem(wfd);
				if(!ret) break;
			}while(FindNextFileW(hFFF, &wfd));
			FindClose(hFFF);
			return ret;
		}else{
			return true;
		}
	}
	const wstring& FileTimeToStr( FILETIME &ft, wstring &s )
	{
		FILETIME ftLocal;
		FileTimeToLocalFileTime(&ft, &ftLocal);
		SYSTEMTIME st;
		FileTimeToSystemTime(&ftLocal, &st);
		wchar_t buf[20];
		_snwprintf_s(buf, 20, _TRUNCATE, L"%4d-%02d-%02d %02d:%02d:%02d", st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
		s = buf;
		return s;
	}
}