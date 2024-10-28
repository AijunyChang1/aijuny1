#include "stdafx.h"
#include "FSWatcher.h"
#include <assert.h>

CFSWatcher::CFSWatcher( const wchar_t* pDir, IFSListener* l, BOOL bRecursive )
:m_dwNotifyFilter(FILE_NOTIFY_CHANGE_FILE_NAME|FILE_NOTIFY_CHANGE_LAST_WRITE|FILE_NOTIFY_CHANGE_DIR_NAME)
{
	wcscpy_s(m_sDir, MAX_PATH-1, pDir);
	size_t len = wcslen(m_sDir);
	if(m_sDir[len-1]!=L'\\'){
		m_sDir[len] = L'\\';
		m_sDir[len+1] = 0;
	}

	m_bRecursive = bRecursive;
	m_bHasPending = false;
	m_pBuffer = new FILE_NOTIFY_INFORMATION[1024];

	m_hDir = CreateFile(pDir, GENERIC_READ, FILE_SHARE_READ|FILE_SHARE_WRITE|FILE_SHARE_DELETE,
		NULL, OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS|FILE_FLAG_OVERLAPPED, NULL);
	assert( INVALID_HANDLE_VALUE != m_hDir );
	m_fsl = l;

	//overlapped init
	ZeroMemory(&m_ol, sizeof(m_ol));
	{
		m_hEvt = CreateEvent( NULL, TRUE, TRUE, NULL);
		assert(m_hEvt);
		m_ol.hEvent = m_hEvt;
	}
}

CFSWatcher::~CFSWatcher(void)
{
	CloseHandle(m_hDir);
	CloseHandle(m_hEvt);
	delete[] m_pBuffer;
}

bool CFSWatcher::check()
{
	FILE_NOTIFY_INFORMATION* const pNotify=(FILE_NOTIFY_INFORMATION *)m_pBuffer;
	DWORD BytesReturned=0;

	if(!m_bHasPending){
		BOOL bRet = ::ReadDirectoryChangesW( m_hDir, pNotify, sizeof(FILE_NOTIFY_INFORMATION)*1024, m_bRecursive,
			m_dwNotifyFilter, &BytesReturned, &m_ol, NULL );
		if(bRet){
			m_bHasPending = true;
		}else{
			assert(false);
		}
	}
	if(m_bHasPending){
		if(WAIT_OBJECT_0==WaitForSingleObject(m_hEvt, 0)){
			BOOL bRet2 = GetOverlappedResult(m_hDir, &m_ol, &BytesReturned, FALSE);
			if(bRet2){
				OnNotify(pNotify);
			}else{
				assert(false);
			}
			m_bHasPending = false;
			return true;
		}
	}
	return false;
}

bool CFSWatcher::check2()
{
	FILE_NOTIFY_INFORMATION* const pNotify=(FILE_NOTIFY_INFORMATION *)m_pBuffer;
	DWORD BytesReturned=0;

	if(!m_bHasPending){
		BOOL bRet = ::ReadDirectoryChangesW( m_hDir, pNotify, sizeof(FILE_NOTIFY_INFORMATION)*1024, m_bRecursive,
			m_dwNotifyFilter, &BytesReturned, &m_ol, NotifyRoutine );
		if(bRet){
			m_bHasPending = true;
		}else{
			assert(false);
		}
	}else{
		SleepEx(0, TRUE);
		if(!m_bHasPending)
			return true;
	}
	return false;
}

VOID CALLBACK CFSWatcher::NotifyRoutine( DWORD dwErrorCode, DWORD dwNumberOfBytesTransfered, LPOVERLAPPED lpOverlapped )
{
	//CFSWatcher* pThis = (CFSWatcher*)lpOverlapped->hEvent;
	CFSWatcher* pThis = (CFSWatcher*)((DWORD_PTR)lpOverlapped - ((DWORD_PTR)&((CFSWatcher*)0)->m_ol));

	FILE_NOTIFY_INFORMATION* const pNotify=(FILE_NOTIFY_INFORMATION *)pThis->m_pBuffer;
	DWORD BytesReturned;
	BOOL bRet = GetOverlappedResult(pThis->m_hDir, lpOverlapped, &BytesReturned, TRUE);
	if(bRet){
		pThis->OnNotify(pNotify);
		pThis->m_bHasPending = false;
	}else{
		assert(false);
	}
}

void CFSWatcher::OnNotify( FILE_NOTIFY_INFORMATION* const pNotify )
{
	for( FILE_NOTIFY_INFORMATION* p=pNotify; p; )
	{
		WCHAR c = p->FileName[p->FileNameLength/2];
		p->FileName[p->FileNameLength/2] = L'\0';

		m_fsl->notifyChange(m_sDir, p->Action, p->FileName);

		p->FileName[p->FileNameLength/2] = c;
		if( p->NextEntryOffset )
			p  = (PFILE_NOTIFY_INFORMATION)( (BYTE*)p + p->NextEntryOffset );
		else
			p = 0;
	}
}