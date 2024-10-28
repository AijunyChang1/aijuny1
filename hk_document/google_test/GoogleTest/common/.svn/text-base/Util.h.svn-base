#pragma once

#include <string>
#include <vector>
#include <shlobj.h>

using namespace std;

///\addtogroup CommonLib
///@{

///\brief Provide a mechanism on how to write and control log information.
class Logger
{
public:
	///Define log levels.
	enum Level{
		DBG = 0,
		INFO,
		WARN,
		ERR,
		OFF
	};

	///Allow log outputs.
	static void on(){
		s_isOn = true;
	}
	///Forbid log outputs.
	static void off(){
		s_isOn = false;
	}
	///\brief Set log level. Should be called when app init.
	static void showLevel(Level l){
		s_level = l;
	}

	static void log(const char* fmt, ...);
	static void debug(const char* fmt, ...);
	static void info(const char* fmt, ...);
	static void warn(const char* fmt, ...);
	static void error(const char* fmt, ...);

	static void log(const wchar_t* fmt, ...);
	static void debug(const wchar_t* fmt, ...);
	static void info(const wchar_t* fmt, ...);
	static void warn(const wchar_t* fmt, ...);
	static void error(const wchar_t* fmt, ...);

private:
	Logger(void){}
	~Logger(void){}

	static void logV(const char* fmt, const char* prefix, va_list args);
	static void logV(const wchar_t* fmt, const wchar_t* prefix, va_list args);

private:
	static Level s_level;
	static bool s_isOn;

};

///\brief A tool class that provide many handy functions as static functions.
class Util
{
	static bool s_isDebugMode;
	Util(void){}
	~Util(void){}
public:
	static void checkDebugMode();
	static bool isDebugMode();
	static bool base64FromFile(const char* path, char* &strB64);
	static bool saveString(const char* path, const char* data);
	static long getFileLen(const char* path);
	static long getFileLen(const wchar_t* path);
	static bool loadData(const char* path, void* data, size_t maxlen);
	static bool loadData(const wchar_t* path, void* data, size_t maxlen);
	static bool saveData(const char* path, void* data, size_t len);
	static bool fileExists(const char* path);
	static bool fileExists(const wchar_t* path);
	static bool copyFile(const char* pathSrc, const char* pathDst);
	static void showCurDir(const char* msg);
	/**
	 buf length should be MAX_PATH
	 if exe is "c:\abc\def.exe", prefixExePath(baseName) will be "c:\abc\<baseName>"
	 */
	static bool prefixExePath(wchar_t* buf, const wchar_t* baseName);
	static DWORD getWinVer(void);
	static bool isVista(void);
	static int drawBuf(HDC hdc, char* buf, int w, int h, int bitcount, int destW=-1, int destH=-1, int destX=0, int destY=0 );
	static HWND FindDescendants(HWND hParent, const char* clz, const char* text);
	static HWND FindDescendants(HWND hParent, const char* clz, const char* text, DWORD pid);
	static HWND FindWindow(const char* clz, const char* text);

	static string replace(const char* s, const char*t, const char* r);
	static int split(const string& input, const string& delimiter, vector<string>& results, bool includeEmpties = false);
	static int split(const wstring& input, const wstring& delimiter, vector<wstring>& results, bool includeEmpties = false);
	static string join(const string& joiner, vector<string>& parts);
	static char* strtolower(char* s);
	static const string strtolower(const string& s);
	static const wstring strtolower(const wstring& s);
	static bool endsWith(const string& s, const string& ends);
	static bool endsWith(const wstring& s, const wstring& ends);

	static DWORD pidFromHWND(HWND hwnd);
	static int procPathFromPID(DWORD pid, char* buf, int buflen, bool nameOnly=true);
	static int getWindowProcPath(HWND hWnd, char* buffer, int count, bool nameOnly=true);
	static int enumTopWindowsForExe(string exeName, vector<HWND> &winList);

	static wstring toUtf16(const char* sBuf, int nLen, UINT codePage=CP_ACP);
	static string toUtf8(const char* sBuf, int nLen, UINT codePage=CP_ACP);
	static string toUtf8(const wchar_t* sBuf, int nLen);
	static string xmlEscape(const string& sBuf);
	static wstring xmlEscape(const wstring& sBuf);

	static const wchar_t* getExt(const wchar_t* fileName);

	static const wstring getMp3Artist(const wchar_t* fileName);

	static void enableSwfCam();
	static void restoreSwfCam();

	static void showThreadPriority(const char* name);

	//Add for support adding webcam setting with new tutorial (03/03/2011 tri.tran)
	static void GetProcessID(LPCTSTR pProcessName, std::vector<DWORD>& SetOfPID);
	static void CloseProcessByID(DWORD pID);
	static HWND GetWindowHandle(const wchar_t* pName);
	static void HideOtherWindow(HWND wcsHWND, HWND flashHWND);
	static void  LeftMouseClick();														// Left clicks the mouse if called.
	static POINT GetMousePosition();												// Returns the mouses current position.
	static void  SetMousePosition(POINT& mp);
	static void Util::PressWindowAndDKey();
};

///\brief This class release hMutex in destructor.
class CMutexRelease{
	HANDLE hMutex;
public:
	CMutexRelease(HANDLE hMutex){
		this->hMutex = hMutex;
	}
	~CMutexRelease(){
		::ReleaseMutex(hMutex);
	}
};

///\brief Encapsulate file system related functions.
namespace FileSystem{
	///Define types of special folders.
	enum FolderType{
		eMyDocuments = CSIDL_PERSONAL,
		eMyVideo = CSIDL_MYVIDEO,
		eMyMusic = CSIDL_MYMUSIC,
		eMyPictures = CSIDL_MYPICTURES,
		eCommonVideo = CSIDL_COMMON_VIDEO,
		eCommonMusic = CSIDL_COMMON_MUSIC,
		eCommonPictures = CSIDL_COMMON_PICTURES,

		eMyStartMenu = CSIDL_STARTMENU,
		eCommonStartMenu = CSIDL_COMMON_STARTMENU,

		eMyStartup = CSIDL_ALTSTARTUP,
		eCommonStartup = CSIDL_COMMON_ALTSTARTUP,

		eAppData = CSIDL_APPDATA,
		eLocalAppData = CSIDL_LOCAL_APPDATA,
		eCommonAppData = CSIDL_COMMON_APPDATA,

		eProgFiles = CSIDL_PROGRAMS,
	};

	bool getSpecialDirA(FolderType ft, string &sPath); ///<Obtain the path of a special folder.
	bool getSpecialDirW(FolderType ft, wstring &sPath); ///<Obtain the path of a special folder.
	bool getDirFiles(const wchar_t* dirPath, vector<wstring> &files); ///<Obtain files in a folder.
	const wstring& FileTimeToStr(FILETIME &ft, wstring &s); ///<Format a file time to %4d-%02d-%02d %02d:%02d:%02d form.

	/**
	 \brief This class provide basic function to enumerate files in a folder(recursively).
	 */
	class CFind{
	public:
		const wchar_t* m_dirPath;

		CFind(const wchar_t* dirPath=NULL); ///<Pass in root path.
		bool run(); ///<Travel through file tree.
		virtual bool onItem(WIN32_FIND_DATAW &wfd); ///<Called when find a item(file or folder), return true to continue traverlling.
		virtual bool onDirItem(WIN32_FIND_DATAW &wfd){ return true; } ///<Called when find a folder item.
		virtual bool onFileItem(WIN32_FIND_DATAW &wfd){ return true;} ///<Called when find a file item.

		bool _walk( wstring &sDirPat );
	};
};
///@}
