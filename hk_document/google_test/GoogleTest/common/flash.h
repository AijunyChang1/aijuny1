#pragma once

#include <vector>
#include <string>
#include <exception>
#include "DragWnd.h"

using namespace std;

struct HFPC_;
#define HFPC HFPC_*

class CFlashException : public exception{
	DWORD m_code;
public:
	CFlashException(const char* msg, DWORD code=0):exception(msg), m_code(code){
	}
	DWORD code(){
		return m_code;
	}
};

class IFlashCallListener;
/**
 \brief Wrapper to f_in_box library.
 To create it:
 @see fromFile|fromRes|fromFileOrRes
 For usage:
 @see CFlashThread
 */
class CFlash
{
public:
	enum Error{
		eSucceed = 0,
		eNotInstalled,
		eLowVersion,
		eLoadFailed
	};
private:
	CFlash();
	static void WINAPI FPCListener(HWND hwndFlashPlayerControl, LPARAM lParam, NMHDR* pNMHDR);

	void afterLoaded(); //disable context menu, add listeners
	void unloadResHandler(); //remove resource handler

	bool m_bLoaded;
	HWND m_hParent;

public:
	virtual ~CFlash(void);
	static Error init();
	static void uninit();
	static CFlash* fromFile(const wchar_t* path, int x, int y, int w, int h, bool bTrans=true, HWND hwndParent=NULL);
	static CFlash* fromRes(HMODULE hModule,int res_id, int x, int y, int w, int h, bool bTrans=true);
	static CFlash* fromFileOrRes(HMODULE hModule, const wchar_t* psPath, int res_id, int w, int h, bool bTrans=true);

	bool isLoaded();
	bool unloadMovie();
	bool loadMovie(const wchar_t* path);
	bool loadMovieRes(HMODULE hModule, int res_id);
	bool loadMovieFromFileOrRes(HMODULE hModule, const wchar_t* path, int res_id);


	void setParent(HWND hwnd);
	HWND getHwnd();
	void createWnd(int x, int y, int w, int h, bool bTrans=true);
	void closeWnd();
	void focusWnd();
	void setFlashCallListener(IFlashCallListener* val);
	bool enableFullScreen(bool bEnable);
	bool isFullScreenEnabled();

	bool play();
	bool stop();
	bool setLoop(bool inLoop);
	bool restart();
	int	getReadyState();
	bool isPlaying();
	bool isEnded();
	bool show(bool bshow);
	bool resize(int w, int h);
	bool center();
	int execute(const wchar_t* command, wstring& ret);
	bool isShown();
	void makeDragable();
	void setAlwayOnTop(bool bEnable);
	void setTransparent(bool bTrans);
	void toFront();
	void toBack();

protected:
	static HFPC m_hFPC;
	HWND m_hwndFlash;
	IFlashCallListener* m_callListener;
	CDragWnd m_dragWnd;

private:
	wchar_t* m_pNewUrl;
	DWORD m_dwHandlerCookie;
	DWORD m_dwHandlerCookie2;
	bool  m_bTransparency;

	static HRESULT WINAPI StaticGlobalOnLoadExternalResourceHandler(LPCWSTR lpszURL, IStream** ppStream, HFPC hFPC, LPARAM lParam);
	HRESULT WINAPI GlobalOnLoadExternalResourceHandler(LPCWSTR lpszURL, IStream** ppStream, HFPC hFPC);

	static void WINAPI StaticGlobalOnPreProcessURLHandler(HFPC hFPC, LPARAM lParam, LPWSTR* pszURL, BOOL* pbContinue);
	void WINAPI GlobalOnPreProcessURLHandler( HFPC hFPC, LPARAM lParam, LPWSTR* pszURL, BOOL* pbContinue );
};

/**
 \brief A interface for handling calls from flash and events from flash player.
 */
class IFlashCallListener{
public:
	virtual int OnFlashCalled(CFlash* pFlash, const wchar_t* request, wstring& response) { return 0; } ///<When flash calls (ExternalInterface).
	virtual int OnFSCommand(const wchar_t* cmd, const wchar_t* args){ return 0; } ///<When flash send commonds (FSCommand)
	/**
	 Flash library provide a chance to draw something before/after flash content is rendered.
	 @see CFlashThread::OnPaintStage
	 */
	virtual int OnPaintStage(const HWND hwnd, const HDC hdc, const BOOL bAfter){ return 0; }
	///\brief Called when flash is to load a resource file.
	virtual HRESULT OnLoadResource(LPCWSTR lpszURL, IStream** ppStream){ return E_FAIL; }
};
