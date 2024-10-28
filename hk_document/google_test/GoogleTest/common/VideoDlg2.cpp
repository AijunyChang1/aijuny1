#include "stdafx.h"
#include "resource.h"

#include <assert.h>

#include "VideoDlg2.h"
#include "Util.h"

CVideoDlg2::CVideoDlg2()
{
	m_pVideoBuf = NULL;
	m_size = 0;
	m_lockBuf = CreateMutex(NULL, FALSE, NULL);
	assert(m_lockBuf);
}

CVideoDlg2::~CVideoDlg2()
{
	CloseHandle(m_lockBuf);
}

//LRESULT CVideoDlg2::OnPaint(HDC hdc)
//{
//	RECT rc;
//	GetWindowRect(&rc);
//
//	//Logger::info("CVideoDlg2::OnPaint in");
//	{
//		//SetMsgHandled(FALSE);
//		//PAINTSTRUCT ps;
//		//hdc = BeginPaint(&ps);
//		//if(WaitForSingleObject(m_lockBuf, 10)==WAIT_OBJECT_0){
//		//	CMutexRelease mutexRelease(m_lockBuf);
//		//	PAINTSTRUCT ps;
//		//	hdc = BeginPaint(&ps);
//		//	if(m_pVideoBuf){
//		//		//int r = Util::drawBuf(hdc, m_pVideoBuf, m_w, m_h, m_bitcount, rc.right-rc.left, rc.bottom-rc.top);
//		//		//SetMsgHandled(TRUE);
//		//	}
//		//	EndPaint(&ps);
//		//}else
//		{
//			PAINTSTRUCT ps;
//			hdc = BeginPaint(&ps);
//			EndPaint(&ps);
//		}
//	}
//	//Logger::info("CVideoDlg2::OnPaint out");
//	return TRUE;
//}

LRESULT CVideoDlg2::OnEraseBkgnd(HDC hdc){
	if(WaitForSingleObject(m_lockBuf, 100)==WAIT_OBJECT_0){
		CMutexRelease mutexRelease(m_lockBuf);
		if(m_pVideoBuf){
			RECT rc;
			GetWindowRect(&rc);
			int r = Util::drawBuf(hdc, m_pVideoBuf, m_w, m_h, m_bitcount, rc.right-rc.left, rc.bottom-rc.top);
			//SetMsgHandled(TRUE);
		}
	}
	return TRUE;
}

void CVideoDlg2::setVideoBuf( char* buf, int size, int w, int h, int bitcount, bool flipLR )
{
	if(::IsWindow(m_hWnd)==FALSE) return;

	//Logger::info("CVideoDlg::setVideoBuf in");
	{
		if(WaitForSingleObject(m_lockBuf, 100)==WAIT_OBJECT_0){
			CMutexRelease mutexRelease(m_lockBuf);
			if(size>m_size){
				delete [] m_pVideoBuf;
				m_pVideoBuf = NULL;
			}
			if(m_pVideoBuf==NULL){
				if(size!=320*240*3){
					Logger::info(L"alloc buf, size=%d", size);
				}
				m_pVideoBuf = new char[size];
			}
			if(flipLR){
				const int pitch = w*3;
				char* pSrc = buf;
				char* pDst = m_pVideoBuf;
				for(int y=0; y<h; y++){
					int x=0;
					int x2=pitch-3;
					while(x<pitch){
						pDst[x]   = pSrc[x2];
						pDst[x+1] = pSrc[x2+1];
						pDst[x+2] = pSrc[x2+2];
						x+=3;
						x2-=3;
					}
					pSrc+=pitch;
					pDst+=pitch;
				}
			}else{
				memcpy(m_pVideoBuf, buf, size);
			}
			m_size = size;
			m_w = w;
			m_h = h;
			m_bitcount = bitcount;
		}
	}
	//Logger::info("CVideoDlg::setVideoBuf out");

	InvalidateRect(NULL);
	UpdateWindow();

	//RedrawWindow(NULL, NULL, RDW_INVALIDATE | RDW_UPDATENOW | RDW_ERASENOW);
}

BOOL CVideoDlg2::PreTranslateMessage( MSG* pMsg )
{
	if(pMsg->message==WM_KEYDOWN){
		if((pMsg->wParam==VK_RETURN) || (pMsg->wParam==VK_ESCAPE || (pMsg->wParam==VK_F4))){
			return (TRUE);
		}
	}else if(pMsg->message==WM_SYSKEYDOWN){
		bool altDown = (pMsg->lParam&(1<<29))!=0;
		if((pMsg->wParam==VK_F4 && altDown)){
			return (TRUE);
		}
	}

	return CWindow::IsDialogMessage(pMsg);
}


LRESULT CVideoDlg2::OnInitDialog(HWND hwndFocus, LPARAM lParam)
{
	MoveWindow(0, 0, 320, 240);
	return TRUE; // set focus to default control
}

LRESULT CVideoDlg2::OnNCHitTest(CPoint Pt)
{
	if(m_bDragable)
		return HTCAPTION;
	else
		return DefWindowProc();
}

void CVideoDlg2::setDragable( bool bEnable )
{
	m_bDragable = bEnable;
}