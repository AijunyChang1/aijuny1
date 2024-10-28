
#include "stdafx.h"

#include <assert.h>
#include "mdump.h"

//#define SAVE_BIGDUMP

LPCSTR MiniDumper::m_szAppName;

MiniDumper::MiniDumper( LPCSTR szAppName )
{
	// if this assert fires then you have two instances of MiniDumper
	// which is not allowed
	assert( m_szAppName==NULL );

	if(szAppName){
		m_szAppName = _strdup(szAppName);
	}else{
		char buf[MAX_PATH];
		::GetModuleFileNameA(NULL, buf, MAX_PATH);
		const char* p = strrchr(buf, '\\');
		if(p){
			m_szAppName = _strdup(p+1);
		}else{
			m_szAppName = "Application";
		}
	}

	::SetUnhandledExceptionFilter( TopLevelFilter );
}

LONG MiniDumper::TopLevelFilter( struct _EXCEPTION_POINTERS *pExceptionInfo )
{
	OutputDebugStringA("Enter TopLevelFilter");

	{
		char sTid[256];
		sprintf_s(sTid, 255, "tid = %d", GetCurrentThreadId());
		OutputDebugStringA(sTid);
	}

	LONG retval = EXCEPTION_CONTINUE_SEARCH;
	HWND hParent = NULL;						// find a better value for your app

	// firstly see if dbghelp.dll is around and has the function we need
	// look next to the EXE first, as the one in System32 might be old 
	// (e.g. Windows 2000)
	HMODULE hDll = NULL;
	char szDbgHelpPath[_MAX_PATH];

	if (GetModuleFileNameA( NULL, szDbgHelpPath, _MAX_PATH ))
	{
		char *pSlash = (char*)strrchr( szDbgHelpPath, '\\' );
		if (pSlash)
		{
			size_t bufSize = (szDbgHelpPath+_MAX_PATH)-(pSlash+1);
			strcpy_s( pSlash+1, bufSize, "DBGHELP.DLL" );
			hDll = ::LoadLibraryA( szDbgHelpPath );
		}
	}

	if (hDll==NULL)
	{
		// load any version we can
		hDll = ::LoadLibraryA( "DBGHELP.DLL" );
	}

	LPCSTR szResult = NULL;

	if (hDll)
	{
		MINIDUMPWRITEDUMP pDump = (MINIDUMPWRITEDUMP)::GetProcAddress( hDll, "MiniDumpWriteDump" );
		if (pDump)
		{
			char szDumpPath[_MAX_PATH];
			char szScratch [_MAX_PATH];

			// work out a good place for the dump file
			if (!GetTempPathA( _MAX_PATH, szDumpPath )){
				strcpy_s( szDumpPath, _MAX_PATH, "c:\\temp\\" );
			}

#ifdef SAVE_BIGDUMP
			char szBigDumpPath[_MAX_PATH];
			// work out a good place for the dump file
			if (!GetTempPathA( _MAX_PATH, szBigDumpPath )){
				strcpy_s( szBigDumpPath, _MAX_PATH, "c:\\temp\\" );
			}
			strcat_s( szBigDumpPath, _MAX_PATH, m_szAppName );
			strcat_s( szBigDumpPath, _MAX_PATH, "_big.dmp" );
#endif

			strcat_s( szDumpPath, _MAX_PATH, m_szAppName );
			strcat_s( szDumpPath, _MAX_PATH, ".dmp" );

			// ask the user if they want to save a dump file
			//if (::MessageBoxA( NULL, "Something bad happened in your program, would you like to save a diagnostic file?", m_szAppName, MB_YESNO )==IDYES)
			{
				// create the file
				HANDLE hFile = ::CreateFileA( szDumpPath, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS,
											FILE_ATTRIBUTE_NORMAL, NULL );
#ifdef SAVE_BIGDUMP
				HANDLE hFileBig = ::CreateFileA( szBigDumpPath, GENERIC_WRITE, FILE_SHARE_WRITE, NULL, CREATE_ALWAYS,
											FILE_ATTRIBUTE_NORMAL, NULL );
#endif

				if (hFile!=INVALID_HANDLE_VALUE)
				{
					_MINIDUMP_EXCEPTION_INFORMATION ExInfo;

					ExInfo.ThreadId = ::GetCurrentThreadId();
					ExInfo.ExceptionPointers = pExceptionInfo;
					ExInfo.ClientPointers = NULL;

					// write the dump
					BOOL bOK = pDump( GetCurrentProcess(), GetCurrentProcessId(), hFile, MiniDumpNormal, &ExInfo, NULL, NULL );
					if (bOK)
					{
						sprintf_s( szScratch, _MAX_PATH, "Saved dump file to '%s'", szDumpPath );
						szResult = szScratch;

						retval = EXCEPTION_EXECUTE_HANDLER;
					}
					else
					{
						sprintf_s( szScratch, _MAX_PATH, "Failed to save dump file to '%s' (error %d)", szDumpPath, GetLastError() );
						szResult = szScratch;
					}
					::CloseHandle(hFile);

#ifdef SAVE_BIGDUMP
					if(hFileBig){
						OutputDebugStringA("Write big dump.");
						pDump( GetCurrentProcess(), GetCurrentProcessId(), hFileBig, MiniDumpWithFullMemory, &ExInfo, NULL, NULL );
						::CloseHandle(hFileBig);
					}
#endif
				}
				else
				{
					sprintf_s( szScratch, _MAX_PATH, "Failed to create dump file '%s' (error %d)", szDumpPath, GetLastError() );
					szResult = szScratch;
				}
			}
		}
		else
		{
			szResult = "DBGHELP.DLL too old";
		}
	}
	else
	{
		szResult = "DBGHELP.DLL not found";
	}

	if (szResult)
		::MessageBoxA( NULL, szResult, m_szAppName, MB_OK );

	if(::MessageBoxA( NULL, "Do you want to debug?", m_szAppName, MB_YESNO )==IDYES){
		retval = EXCEPTION_CONTINUE_SEARCH;
	}

	OutputDebugStringA("Exit TopLevelFilter");
	return retval;
}
