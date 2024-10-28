#pragma once

///\addtogroup CommonLib
///@{

/**
 \brief This class provide supports to worker thread or GUI thread.
 @see CFlashThread|CFlashThreadDH|CTrackerThread|CUpdateThread
 */
class CThread
{
public:
	CThread(void);
	virtual ~CThread(void);

public:
	virtual BOOL Start();	///<Start to run.
	virtual BOOL Stop();	///<Stop running.
	virtual void Run();		///<Be called repeatly
	void EnableSleep(BOOL bEanble);	///<To enable/disable Sleep calls between 

	virtual void OnThreadMsg(UINT message, WPARAM wParam, LPARAM lParam);	///<Overload this method to handle thread messages.
	//virtual void OnThreadWndMsg(MSG* pMsg);

	virtual void OnThreadStart();
	virtual void OnQuit();	///<Called when thread quit.

	BOOL PostThreadMsg(UINT message, WPARAM wParam=0, LPARAM lParam=0);	///<Post message to this thread.
	BOOL IsStart();	///<Return if the thread is started.
	BOOL WaitForQuit(DWORD dwMilli=INFINITE);	///<Wait for quiting.

private:
	DWORD m_tid;
	HANDLE m_hThread;
	HANDLE m_evtQuit;
	static unsigned __stdcall ThreadProc(void* param);
	int m_nSleepTime;
};
///@}
