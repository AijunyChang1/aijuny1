#pragma once

#include <windows.h>

///\addtogroup CommonLib
///@{

///\brief Client implement this interface to receive notifications of file system changes.
///\sa MyFSListener::notifyChange
class IFSListener{
public:
	virtual void notifyChange(const wchar_t* psDir, DWORD action, const wchar_t* fileName) = 0;
};

///\brief This class check and notify clients for file system changes.
///\remarks To use this class, check or check2 must be called periodly.
class CFSWatcher{

public:
	CFSWatcher(const wchar_t* pDir, IFSListener* l, BOOL m_bRecursive=true);
	virtual ~CFSWatcher(void);

	bool check();	///<Check changes with GetOverlappedResult.
	bool check2();	///<Check changes with CompletionRoutine.

private:
	wchar_t m_sDir[MAX_PATH];
	HANDLE m_hDir;	//handle to the dir watched
	const DWORD m_dwNotifyFilter;	//what events need be notified
	BOOL m_bRecursive;	//watch sub dir or not
	IFSListener *m_fsl;	//notification handler

	OVERLAPPED m_ol;	//overlapped data used by GetOverlappedResult or CompletionRoutine
	HANDLE m_hEvt;		//signal for GetOverlappedResult
	bool m_bHasPending;	//indicate if has uncompleted changes reading request
	FILE_NOTIFY_INFORMATION *m_pBuffer;	//data buffer to retreive notifications

	//
	void OnNotify( FILE_NOTIFY_INFORMATION* const pNotify );
	static VOID CALLBACK NotifyRoutine(DWORD dwErrorCode, DWORD dwNumberOfBytesTransfered, LPOVERLAPPED lpOverlapped);
};

///@}
