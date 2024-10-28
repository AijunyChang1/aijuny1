#include "StdAfx.h"
#include "Thread.h"
#include "Util.h"

CThread::CThread(void){
	m_nSleepTime = 1;
	m_hThread = NULL;
	m_evtQuit = NULL;
}

CThread::~CThread(void){
}

BOOL CThread::IsStart(){
	return m_hThread != NULL;
}

BOOL CThread::WaitForQuit( DWORD dwMilli ){
	if(!m_evtQuit) return TRUE;

	if(WAIT_OBJECT_0==::WaitForSingleObject(m_evtQuit, dwMilli)){
		return TRUE;
	}else{
		return FALSE;
	}
}

BOOL CThread::Start(){
	m_hThread = (HANDLE)_beginthreadex(NULL, 0, ThreadProc, this, 0, (unsigned int*)&m_tid);
	if(m_hThread){
		m_evtQuit = ::CreateEvent(NULL, TRUE, FALSE, NULL);
	}
	return m_hThread != NULL;
}


BOOL CThread::PostThreadMsg(UINT message, WPARAM wParam, LPARAM lParam){
	if( m_hThread ){
		return ::PostThreadMessageW(m_tid, message, wParam, lParam);
	}
	return FALSE;
}

BOOL CThread::Stop(){
	if( m_hThread ){
		return ::PostThreadMessage(m_tid, WM_CLOSE,0,0);
	}
	return FALSE;
}


void  CThread::OnThreadStart(){
}

void CThread::OnQuit(){
}

void CThread::OnThreadMsg(UINT message, WPARAM wParam, LPARAM lParam){
}

void CThread::EnableSleep(BOOL bEanble){
	if (bEanble){
		m_nSleepTime = 1;
	}else{
		m_nSleepTime = 0;
	}
}

void CThread::Run(){
}

unsigned CThread::ThreadProc(void* param){
	CThread *pThread = (CThread*)param;
	pThread->OnThreadStart();

	MSG msg;

	while(true){
		while( PeekMessage(&msg,NULL,0,0,PM_REMOVE) ){
		//while( GetMessage(&msg,NULL,0,0) ){
			if(msg.message==WM_CLOSE){
				pThread->OnQuit();
				Logger::info(L"Thread %d end by WM_QUIT", pThread->m_tid);
				SetEvent(pThread->m_evtQuit);
				return 0;
			}else if(msg.hwnd){
				::TranslateMessage(&msg);
				::DispatchMessage(&msg);
			}else{
				pThread->OnThreadMsg(msg.message,msg.wParam,msg.lParam);
			}
		}

		pThread->Run();
		if( pThread->m_nSleepTime > 0 ){
			Sleep(pThread->m_nSleepTime);
		}
		pThread->m_nSleepTime = 1;
	}
	Logger::info(L"Thread %d end return", pThread->m_tid);
	SetEvent(pThread->m_evtQuit);
	return 0;
}
