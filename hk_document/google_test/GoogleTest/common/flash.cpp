//
// flashshow.cpp
// $Id: flashshow.cpp 15934 2009-08-27 10:35:30Z tao.jiang $
// Copyright 2009 Mobinex, Inc.
//
#include "stdafx.h"
#include "Util.h"
#include <string>
#include <cassert>
#include <winsock2.h>

#include "f_in_box.h"
#include "flash.h"

#pragma comment(lib, "f_in_box.lib")
#pragma comment(lib, "Ws2_32.lib")

#include "FXAESCrypto.h"
#pragma comment(lib, "FXAESCrypto.lib")

using namespace std;

HFPC CFlash::m_hFPC = 0;

static HFPC loadOcx(const wchar_t* ocxPath);
CFlash::CFlash()
: m_bLoaded(false)
,m_hwndFlash(0),
m_pNewUrl(0),
m_callListener(0)
,m_bTransparency(true)
,m_hParent(NULL)
{
}

CFlash::~CFlash(void)
{
	unloadResHandler();
	if(::IsWindow(m_hwndFlash)){
		::DestroyWindow(m_hwndFlash);
	}
}

bool CFlash::resize(int w, int h)
{
	if (m_hFPC && m_hwndFlash)
	{
		RECT rc;
		GetWindowRect(m_hwndFlash,&rc);

		int centerx = (rc.right-rc.left)/2;
		int centery = (rc.bottom-rc.top)/2;

		return SetWindowPos(m_hwndFlash,HWND_TOPMOST,centerx-w/2,centery-h/2,w,h,SWP_SHOWWINDOW)==TRUE;
	}
	else
	{
		return false;
	}
}

bool CFlash::play()
{
	bool bResult = false;
	if (m_hwndFlash)
	{
		SFPCPlay SFPCplay;
		SendMessage(m_hwndFlash, FPCM_PLAY, 0, (LPARAM)&SFPCplay);
		if (SUCCEEDED(SFPCplay.hr))
			bResult = true;
	}
	return bResult;
}

bool CFlash::stop()
{
	bool bResult = false;
	if ( m_hwndFlash )
	{
		SFPCStop SFPCstop = {S_OK};
		SendMessage(m_hwndFlash, FPCM_STOP, 0, (LPARAM)&SFPCstop);
		if (SUCCEEDED(SFPCstop.hr))
		{
			bResult = true;
		}
	}

	return bResult;
}

bool CFlash::setLoop(bool inLoop)
{
	bool bResult = false;
	if (m_hwndFlash)
	{
		SFPCPutLoop SFPCputloop;
		if (inLoop) 
			SFPCputloop.Loop = VARIANT_TRUE;
		else
			SFPCputloop.Loop = VARIANT_FALSE;
		SendMessage(m_hwndFlash, FPCM_PUT_LOOP, 0, (LPARAM)&SFPCputloop);
		if (SUCCEEDED(SFPCputloop.hr))
			bResult = true;
	}
	return bResult;
}

bool CFlash::restart()
{
	bool bRet = false;
	if (m_hwndFlash)
	{
		if (SUCCEEDED(FPC_GotoFrame(m_hwndFlash, 1)))
		{
			if (SUCCEEDED(FPC_Play(m_hwndFlash)))
			{
				bRet = true;
			}
		}
	}
	return bRet;
}

int	CFlash::getReadyState()
{
	int bResult = -1;

	if (m_hwndFlash)
	{
		SFPCGetReadyState FPCreadystate;
		SendMessage(m_hwndFlash, FPCM_GET_READYSTATE, 0, (LPARAM)&FPCreadystate);
		if (SUCCEEDED(FPCreadystate.hr))
			bResult = FPCreadystate.ReadyState;
	}
	return bResult;
}

bool CFlash::isPlaying()
{
	bool bResult = false;
	if (m_hwndFlash)
	{
		SFPCGetPlaying info;  
		SendMessage(m_hwndFlash, FPCM_GET_PLAYING, 0, (LPARAM)&info);
		if (SUCCEEDED(info.hr))
			bResult = info.Playing==VARIANT_TRUE?true:false;
	}
	return bResult;
}

bool CFlash::show(bool bshow)
{
	Logger::info(L"CFlash::show: enter");
	bool bResult = false;
	if (m_hwndFlash)
	{
		if (bshow){
			BOOL ret = ShowWindow(m_hwndFlash, SW_SHOW);
			if(ret){
				ret = InvalidateRect(m_hwndFlash, NULL, TRUE);
				if(ret) bResult=true;
			}else{
				Logger::error(L"CFlash::show: fail to ShowWindow!");
			}
		}else{
			BOOL ret = ShowWindow(m_hwndFlash, SW_HIDE);
			if(ret) bResult=true;
		}
	}
	Logger::info(L"CFlash::show: exit with ret=%d", bResult);
	return bResult;
}

bool CFlash::isEnded()
{
	if (m_hwndFlash)
	{
		long current, total;
		if (SUCCEEDED(FPC_CurrentFrame(m_hwndFlash, &current)) && SUCCEEDED(FPC_GetTotalFrames(m_hwndFlash, &total)))
		{
			if (current==total-1)
				return true;
		}
	}
	return false;
}

int CFlash::execute(const wchar_t* command, wstring& ret){
	CComBSTR bstrRequest(command);
	CComBSTR bstrResponse;

	Logger::debug(L"CALL_FLASH:\t%s", command);

	HRESULT hr = FPCCallFunctionBSTR(m_hwndFlash, bstrRequest, &bstrResponse);
	if(SUCCEEDED(hr)){
		ret = bstrResponse;
		return 0;
	}else{
		Logger::error(L"CALL_FLASH FAIL! ==> p=%x, hr=%x, %s, %s", this, hr, bstrRequest, bstrResponse);
		return (int)hr;
	}
}

void WINAPI CFlash::FPCListener(HWND hwndFlashPlayerControl, LPARAM lParam, NMHDR* pNMHDR)
{   
	USES_CONVERSION;
	CFlash* pFlash = (CFlash*)lParam;
	HWND hwndFlash = pFlash->m_hwndFlash;

	if(hwndFlash == pNMHDR->hwndFrom){
		switch (pNMHDR->code){
			case FPCN_PAINT_STAGE:
				{
					SFPCNPaintStage* info = (SFPCNPaintStage*)pNMHDR;
					if(pFlash->m_callListener){
						pFlash->m_callListener->OnPaintStage(pNMHDR->hwndFrom, info->hdc, info->dwStage);
					}
					break;
				}
			case FPCN_FLASHCALL:
				{   
					SFPCFlashCallInfoStruct* pInfo = (SFPCFlashCallInfoStruct*)pNMHDR;
					Logger::info(_T("FlashCalled: %s"), pInfo->request);
					if(pFlash->m_callListener){
						wstring strResponse;
						int ret = pFlash->m_callListener->OnFlashCalled(pFlash, T2W((LPTSTR)pInfo->request), strResponse);
						FPCSetReturnValueW(hwndFlash, strResponse.c_str());
					}else{
						FPCSetReturnValueW(hwndFlash, L"<null/>");
					}
					break;   
				}
			case FPCN_FSCOMMAND:
				{   
					SFPCFSCommandInfoStruct* pInfo = (SFPCFSCommandInfoStruct*)lParam;   
					if(pFlash->m_callListener){
						int ret = pFlash->m_callListener->OnFSCommand(T2W((LPTSTR)pInfo->command), T2W((LPTSTR)pInfo->args));
					}
					break;   
				}
		}
	}
}  

CFlash* CFlash::fromFile(const wchar_t* path, int x, int y, int w, int h, bool bTrans, HWND hwndParent)
{
	assert(m_hFPC);

	CFlash* p = new CFlash;
	p->setParent(hwndParent);
	p->createWnd(x, y, w, h, bTrans);
	if(p->loadMovie(path)){
		return p;
	}else{
		delete p;
		return NULL;
	}
}

CFlash* CFlash::fromRes(HMODULE hModule,int res_id, int x, int y, int w, int h, bool bTrans)
{
	assert(m_hFPC);

	CFlash* p = new CFlash;
	p->createWnd(x, y, w, h, bTrans);

	BOOL bRet = FPCPutMovieFromResourceW(p->m_hwndFlash, hModule, MAKEINTRESOURCEW(res_id), L"SWF");
	if(!bRet)
	{
		HRSRC hResInfo = FindResourceW(hModule, MAKEINTRESOURCEW(res_id), L"ESW");
		if(hResInfo){
			HGLOBAL hResData = LoadResource(hModule, hResInfo);
			if(hResData){
				LPVOID lpMovieData = LockResource(hResData);
				if(lpMovieData){
					DWORD dwMovieSize = SizeofResource(hModule, hResInfo);
					CFXAESCrypto c;
					c.SetDecryptKey((byte*)"Mobinex TeliLite");
					char* bufSwf = new char[dwMovieSize];
					long outLen = 0;
					if(c.DecryptString((byte*)lpMovieData, (byte*)bufSwf, dwMovieSize, outLen)){
						bRet = FPCPutMovieFromMemory(p->m_hwndFlash, bufSwf, outLen);
					}
					delete[] bufSwf;
				}
			}
		}
	}
	if(bRet){
		p->m_bLoaded = true;
		p->afterLoaded();
		return p;
	}else{
		delete p;
		return NULL;
	}
}

//load flash according calling module path or res_id
CFlash* CFlash::fromFileOrRes( HMODULE hModule, const wchar_t* psPath, int res_id, int w, int h, bool bTrans/*=true*/ )
{
	CFlash* pFlash = NULL;
	{
		bool bExist = false;
		wstring sLoadPath;
		if(psPath){
			wchar_t buf[MAX_PATH];
			Util::prefixExePath(buf, psPath);
			sLoadPath = buf;
			if(Util::fileExists(sLoadPath.c_str())){
				bExist = true;
			}
		}else{
			wchar_t exePath[MAX_PATH];
			GetModuleFileNameW(hModule, exePath, MAX_PATH-1);
			sLoadPath = exePath;
			sLoadPath = sLoadPath.substr(0, sLoadPath.rfind(L'.'))+L".esw";
			if(Util::fileExists(sLoadPath.c_str())){
				bExist = true;
			}else{
				sLoadPath = exePath;
				sLoadPath = sLoadPath.substr(0, sLoadPath.rfind(L'.'))+L".swf";
				if(Util::fileExists(sLoadPath.c_str())){
					bExist = true;
				}
			}
		}
		
		if(bExist){
			pFlash =  CFlash::fromFile(sLoadPath.c_str(), 0, 0, w, h, bTrans);
			Logger::info(L"Using swf at %s for debug.", sLoadPath.c_str());
		}
		else{
			pFlash = CFlash::fromRes(hModule, res_id, 0, 0, w, h, bTrans);
			if(!pFlash){
				Logger::error(L"CFlash::fromRes fail!");
			}
		}
	}
	if(pFlash) pFlash->center();
	return pFlash;
}

bool CFlash::isLoaded()
{
	return m_bLoaded;
}

bool CFlash::unloadMovie(){
	m_bLoaded = false;
	FPC_PutMovieW(m_hwndFlash, L"____");
	return true;
}

bool CFlash::loadMovie( const wchar_t* path )
{
	BOOL bRet = FALSE;
	if(Util::endsWith(Util::strtolower(path), L"esw")){
		DWORD dwMovieSize = Util::getFileLen(path);
		CFXAESCrypto c;
		c.SetDecryptKey((byte*)"Mobinex TeliLite");
		char* bufSwf = new char[dwMovieSize];
		long outLen = 0;
		if(c.DecryptFileToString(path, (byte*)bufSwf, outLen)){
			bRet = FPCPutMovieFromMemory(m_hwndFlash, bufSwf, outLen);
			Logger::error("loadMovie,FPCPutMovieFromMemory=FALSE");
		}else{
			Logger::error("loadMovie,DecryptFileToString=false");
		}
		delete[] bufSwf;
	}else{
		HRESULT hr = FPC_PutMovieW(m_hwndFlash, path);
		if(SUCCEEDED(hr)){
			bRet = TRUE;
		}else{
			Logger::error("loadMovie,FPC_PutMovieW fail!");
		}
	}
	if(bRet){
		m_bLoaded = true;
		afterLoaded();
		return true;
	}else{
		return false;
	}
}

bool CFlash::loadMovieRes(HMODULE hModule, int res_id){
	BOOL bRet = FPCPutMovieFromResourceW(m_hwndFlash, hModule, MAKEINTRESOURCEW(res_id), L"SWF");
	if(bRet){
		m_bLoaded = true;
		afterLoaded();
		return true;
	}else{
		return false;
	}
}

bool CFlash::loadMovieFromFileOrRes(HMODULE hModule, const wchar_t* path, int res_id )
{
	if(Util::fileExists(path)){
		return loadMovie(path);
	}else{
		return loadMovieRes(hModule, res_id);
	}
}

void CFlash::uninit()
{
	if(m_hFPC){
		BOOL ret = FPC_UnloadCode(m_hFPC);
		Logger::warn("loadMovie,FPC_PutMovieW fail!");
		m_hFPC = NULL;
		//DllEntry(GetModuleHandleA(NULL), DLL_PROCESS_DETACH, NULL);
	}
}

CFlash::Error CFlash::init()
{
	//BOOL dllEntry = DllEntry(GetModuleHandleA(NULL), DLL_PROCESS_ATTACH, NULL);

	const wchar_t* ocxPath = L"flash_dat";
	if(Util::fileExists(ocxPath)){
		m_hFPC = loadOcx(ocxPath);
	}
	if(m_hFPC==NULL){
		BOOL swfInstalled = FPCIsFlashInstalled();
		if(swfInstalled==FALSE){
			return eNotInstalled;
			//OutputDebugStringA("Flash is not installed!");
			//MessageBoxA(NULL, "Flash is not installed!", "Warning", MB_OK);
			//exit(1);
		}
		assert(swfInstalled);

		if(NULL==m_hFPC){
			m_hFPC = FPC_LoadRegisteredOCX();
		}
	}
	assert(m_hFPC);
	if(!m_hFPC){
		return eLoadFailed;
		//MessageBoxA(NULL, "Load flash fail!", "Warning", MB_OK);
		//exit(2);
	}
	DWORD dwVer = FPC_GetVersion(m_hFPC);
	Logger::info(L"FV: %d.%d.%d.%d", (dwVer>>24)&0xff, (dwVer>>16)&0xff, (dwVer>>8)&0xff, dwVer&0xff);
	
	//check if the flash version is higher than 10.0.0.0
	if(dwVer<0xa000000){
		return eLowVersion;
		//MessageBoxA(NULL, "The version of flash you installed is too low!\r\nPlease install latest version.", "Warning", MB_OK);
		//exit(3);
	}
	return eSucceed;
}

void CFlash::createWnd(int x, int y, int w, int h, bool bTrans)
{
	Logger::info(L"CFlash::createWnd: bTrans=%d", bTrans);
	DWORD dwStyle = 0;
	DWORD dwExStyle = 0;

	if(m_hParent){
		dwStyle = WS_CHILD|WS_VISIBLE;
		if(bTrans){
			dwStyle |= WS_CLIPSIBLINGS|FPCS_TRANSPARENT;
		}
		m_hwndFlash = CreateWindow((LPCTSTR)FPC_GetClassAtom(m_hFPC),    
			NULL, 
			dwStyle,
			x,y,w,h,
			m_hParent,    
			NULL, NULL, NULL);
	}else{
		dwStyle = WS_POPUP;
		dwExStyle = WS_EX_TOOLWINDOW;
		if(bTrans) dwExStyle |= WS_EX_LAYERED;

		m_hwndFlash = FPC_CreateWindowW(m_hFPC,
			dwExStyle,//WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW,
			NULL,
			dwStyle,// | WS_VISIBLE,
			x,y,w,h,
			NULL,//AfxGetMainWnd()->m_hWnd,
			NULL, NULL, NULL);
	}

	if(!m_hwndFlash) Logger::error("FPC_CreateWindowW fail!");
	FPC_SetContext(m_hwndFlash, "9a3c822f-5818-4499-ad96-354101e9a7df");
}

void CFlash::closeWnd()
{
	BOOL ret = DestroyWindow(m_hwndFlash);
	if(!ret) Logger::warn(L"DestroyWindow(m_hwndFlash) return false.");
}

void CFlash::focusWnd()
{
	//SetForegroundWindow(m_hwndFlash);
	SetFocus(m_hwndFlash);
}

bool CFlash::center()
{
	if (m_hFPC && m_hwndFlash)
	{
		RECT rc;
		GetWindowRect(m_hwndFlash, &rc);

		int cx = GetSystemMetrics(SM_CXSCREEN);
		int cy = GetSystemMetrics(SM_CYSCREEN);

		int w = (rc.right-rc.left);
		int h = (rc.bottom-rc.top);
		int x = (cx-w)/2;
		int y = (cy-h)/2;

		//return SetWindowPos(m_hwndFlash,HWND_TOPMOST,x,y,w,h,SWP_SHOWWINDOW)==TRUE;
		//return SetWindowPos(m_hwndFlash,HWND_TOP,x,y,w,h,SWP_HIDEWINDOW)==TRUE;
		return MoveWindow(m_hwndFlash,x,y,w,h,FALSE)==TRUE;
	}
	else
	{
		return false;
	}
}

bool CFlash::enableFullScreen( bool bEnable ){
	return (FPC_EnableFullScreen(m_hwndFlash, (bEnable?TRUE:FALSE))==TRUE);
	return false;
}

bool CFlash::isFullScreenEnabled(){
	return (FPC_IsFullScreenEnabled(m_hwndFlash)==TRUE);
}

//workaround for renderer problem.
HRESULT WINAPI CFlash::GlobalOnLoadExternalResourceHandler(LPCWSTR lpszURL, IStream** ppStream, HFPC hFPC){
	HRESULT hr = E_FAIL;

	{
		Logger::debug(L"Flash loading: %s", lpszURL);
	}
	if(m_callListener){
		HRESULT hr = m_callListener->OnLoadResource(lpszURL, ppStream);
		if(SUCCEEDED(hr)) return hr;
	}

	if(_tcslen(lpszURL)>9 && _tcsncmp(lpszURL, _T("file://"), 7)==0){
		wchar_t* wbuf = new wchar_t[1024];
		DWORD outlen = 1024;

		{
			LPWSTR urlCopy = _wcsdup(lpszURL);
			UrlUnescapeW(urlCopy, wbuf, &outlen, URL_DONT_UNESCAPE_EXTRA_INFO);
			free(urlCopy);
		}

		if(wbuf[9]==L'|') wbuf[9]=L':';
		wchar_t* fname = wbuf+8;
		{
			IStream* pMemStream = NULL;   
			HRESULT hr2 = CreateStreamOnHGlobal(NULL, TRUE, &pMemStream);
			if(SUCCEEDED(hr2)){
				long sz = Util::getFileLen(fname);
				if(sz>=0){
					char* buf = new char[sz];
					if(Util::loadData(fname, buf, sz)){
						ULONG cbWritten = -1;
						hr2 = pMemStream->Write(buf, sz, &cbWritten);
						if(SUCCEEDED(hr2)){
							*ppStream = pMemStream;
							hr = S_OK;
						}
					}
					delete[] buf;
				}
			}
		}
		delete[] wbuf;
	}else if (0 == lstrcmpi(lpszURL, _T("http://FLV/FlashVideo.flv")))
	{
		IStream* pMemStream = NULL;
		CreateStreamOnHGlobal(NULL, TRUE, &pMemStream);

		char* m_strFLVPath = "abc.flv";
		HANDLE hFile = CreateFileA(m_strFLVPath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, 0, NULL);

		if (INVALID_HANDLE_VALUE != hFile)
		{
			const DWORD nBufferSize = 1024 * 1024;
			BYTE* pBuffer = new BYTE[nBufferSize];
			DWORD dwNumberOfBytesRead;
			ULONG nWritten;

			while (true)
			{
				BOOL bRes = ReadFile(hFile, pBuffer, nBufferSize, &dwNumberOfBytesRead, NULL);

				if (!bRes || 0 == dwNumberOfBytesRead)
					break;

				pMemStream->Write(pBuffer, dwNumberOfBytesRead, &nWritten);
			}

			delete[] pBuffer;

			CloseHandle(hFile);

			LARGE_INTEGER liZero = { 0 };
			ULARGE_INTEGER ulNewPosition;
			pMemStream->Seek(liZero, STREAM_SEEK_SET, &ulNewPosition);

			*ppStream = pMemStream;
			hr = S_OK;
		}
	}

	return hr;
}

void WINAPI CFlash::GlobalOnPreProcessURLHandler( HFPC hFPC, LPARAM lParam, LPWSTR* pszURL, BOOL* pbContinue )
{
	USES_CONVERSION;
	Logger::debug(L"Flash accessing url: %s", *pszURL);

	if(wcsncmp(*pszURL, L"http://", 7)==0){
		m_pNewUrl = 0;
		//get host string from url:
		const wchar_t* pHostEnd = wcschr((*pszURL+7), L':');
		if(pHostEnd==0){
			pHostEnd = wcschr((*pszURL+7), L'/');
		}
		wchar_t* pHost = NULL;
		size_t hostLen = 0;
		if(pHostEnd){
			hostLen = pHostEnd-*pszURL-6;
		}else{
			hostLen = wcslen(*pszURL+7)+1;
		}
		pHost = new wchar_t[hostLen];
		wcsncpy_s(pHost, hostLen, *pszURL+7, hostLen-1);

		//convert host to ip address:
		char* sIp = NULL;
		{
			WSADATA inet_WsaData;
			int ret = -1;
			ret = WSAStartup(MAKEWORD(1,1), &inet_WsaData);//0x0101
			hostent* h = gethostbyname(W2A(pHost));
			sIp = inet_ntoa(*(struct in_addr *)*h->h_addr_list);
			WSACleanup();
			delete[] pHost;
		}

		if(strncmp(sIp, "192.168.", 8)==0){
			//replace host by ip address:
			wchar_t buf[1024] = L"http://";
			wcscat_s(buf, 1024, A2W(sIp));
			wcscat_s(buf, 1024, *pszURL+7+hostLen-1);

			if(m_pNewUrl){
				free(m_pNewUrl);
				m_pNewUrl = 0;
			}
			m_pNewUrl = _wcsdup(buf);
			*pszURL = m_pNewUrl;
		}
	}
}

void CFlash::afterLoaded()
{
	FPC_PutStandardMenu(m_hwndFlash, FALSE);
	FPCSetEventListener(m_hwndFlash, FPCListener, (LPARAM)this);

	m_dwHandlerCookie = FPC_AddOnLoadExternalResourceHandlerW(m_hFPC, &StaticGlobalOnLoadExternalResourceHandler, (LPARAM)this);
	//m_dwHandlerCookie2 = FPC_SetPreProcessURLHandler(m_hFPC, &StaticGlobalOnPreProcessURLHandler, (LPARAM)this);
}

void CFlash::unloadResHandler()
{
	if(m_pNewUrl){
		free(m_pNewUrl);
		m_pNewUrl = 0;
	}
	FPC_RemoveOnLoadExternalResourceHandler(m_hFPC, m_dwHandlerCookie);
}

void CFlash::makeDragable()
{
	m_dragWnd.makeDragable(m_hwndFlash);
}

void CFlash::setAlwayOnTop( bool bEnable )
{
	if(bEnable){
		::SetWindowPos(m_hwndFlash, HWND_TOPMOST, 0,0,0,0, SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE|SWP_NOOWNERZORDER);
	}else{
		::SetWindowPos(m_hwndFlash, HWND_NOTOPMOST, 0,0,0,0, SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE|SWP_NOOWNERZORDER);
		//::SetWindowPos(m_hwndFlash, HWND_TOP, 0,0,0,0, SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE|SWP_NOOWNERZORDER);
	}
}

void CFlash::setTransparent( bool bTrans )
{
	Logger::info(L"CFlash::setTransparent: %d", bTrans);
	CWindow w(m_hwndFlash);
	if(bTrans){
		w.ModifyStyleEx(0, WS_EX_LAYERED);
	}else{
		w.ModifyStyleEx(WS_EX_LAYERED, 0);
	}
}

void CFlash::toFront()
{
	::BringWindowToTop(m_hwndFlash);
}

void CFlash::toBack()
{
	::SetWindowPos(m_hwndFlash, HWND_BOTTOM, 0, 0, 0, 0, SWP_NOSIZE|SWP_NOMOVE);
	//::SetWindowPos(m_hwndFlash, GetForegroundWindow(), 0, 0, 0, 0, SWP_NOSIZE|SWP_NOMOVE|SWP_NOACTIVATE|SWP_NOOWNERZORDER);
}

HWND CFlash::getHwnd()
{
	return this->m_hwndFlash;
}

bool CFlash::isShown()
{
	if(m_hwndFlash!=NULL){
		return ::IsWindowVisible(m_hwndFlash)==TRUE;
	}else{
		return false;
	}
}

HRESULT WINAPI CFlash::StaticGlobalOnLoadExternalResourceHandler( LPCWSTR lpszURL, IStream** ppStream, HFPC hFPC, LPARAM lParam )
{
	CFlash* pThis = (CFlash*)lParam;

	return pThis->GlobalOnLoadExternalResourceHandler(lpszURL, ppStream, hFPC);
}

void WINAPI CFlash::StaticGlobalOnPreProcessURLHandler( HFPC hFPC, LPARAM lParam, LPWSTR* pszURL, BOOL* pbContinue )
{
	CFlash* pThis = (CFlash*)lParam;

	pThis->GlobalOnPreProcessURLHandler(hFPC, lParam, pszURL, pbContinue);
}

void CFlash::setParent( HWND hwnd )
{
	m_hParent = hwnd;
}

void CFlash::setFlashCallListener( IFlashCallListener* val )
{
	m_callListener = val;
}

static HFPC loadOcx(const wchar_t* ocxPath){
	HANDLE hFile = CreateFileW(ocxPath, GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL);

	if(hFile==INVALID_HANDLE_VALUE){
		return NULL;
	}

	DWORD dwFlashOCXCodeSize = GetFileSize(hFile, NULL);   
	HANDLE hFileMapping = CreateFileMapping(hFile, NULL, PAGE_READONLY, 0, dwFlashOCXCodeSize, NULL);   
	LPVOID lpFlashOCXCodeData = MapViewOfFile(hFileMapping, FILE_MAP_READ, 0, 0, 0);   

	HFPC hFPC = FPC_LoadOCXCodeFromMemory(lpFlashOCXCodeData, dwFlashOCXCodeSize);   
	if (NULL == hFPC){   
		// Error  
		::MessageBoxA(NULL, "FPC_LoadOCXCodeFromMemory() failed", "Error", MB_OK);
	}else{
		UnmapViewOfFile(lpFlashOCXCodeData);   
		CloseHandle(hFileMapping);   
		CloseHandle(hFile);  
	}
	return hFPC;
}
