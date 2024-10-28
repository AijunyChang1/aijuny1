// VideoDlg.cpp : implementation file
//

#include "stdafx.h"
#include "resource.h"
#include "VideoDlg.h"
#include "Util.h"


// CVideoDlg dialog

IMPLEMENT_DYNAMIC(CVideoDlg, CDialog)

CVideoDlg::CVideoDlg(CWnd* pParent /*=NULL*/)
	: CDialog(CVideoDlg::IDD, pParent)
{
	m_pVideoBuf = NULL;
	m_size = 0;
}

CVideoDlg::~CVideoDlg()
{
}

void CVideoDlg::DoDataExchange(CDataExchange* pDX)
{
	CDialog::DoDataExchange(pDX);
}


BEGIN_MESSAGE_MAP(CVideoDlg, CDialog)
	ON_WM_PAINT()
	ON_WM_ERASEBKGND()
END_MESSAGE_MAP()


BOOL CVideoDlg::PreTranslateMessage(MSG* pMsg){
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

	return CDialog::PreTranslateMessage(pMsg);
}

// CVideoDlg message handlers

void CVideoDlg::OnPaint()
{
	CPaintDC dc(this); // device context for painting
	RECT rc;
	GetClientRect(&rc);

	Logger::debug("CVideoDlg::OnPaint in");
	{
		//CSingleLock bufLock(&m_lockBuf, TRUE);
		CSingleLock lock(&m_lockBuf);
		if(lock.Lock(100))
		{
		//m_lockBuf.Lock();
		//Sleep(100);
			if(m_pVideoBuf){
				Util::drawBuf(dc.GetSafeHdc(), m_pVideoBuf, m_w, m_h, m_bitcount, rc.right, rc.bottom);
			}
		}
	}
	Logger::debug("CVideoDlg::OnPaint out");
}

void CVideoDlg::setVideoBuf( char* buf, int size, int w, int h, int bitcount )
{
	if(::IsWindow(m_hWnd)==FALSE) return;

	Logger::debug("CVideoDlg::setVideoBuf in");
	{
		//CSingleLock bufLock(&m_lockBuf, TRUE);
		CSingleLock lock(&m_lockBuf);
		if(lock.Lock(100)){
		//if(::TryEnterCriticalSection(m_lockBuf))
		//{

			if(size>m_size){
				delete [] m_pVideoBuf;
				m_pVideoBuf = NULL;
			}
			if(m_pVideoBuf==NULL){
				m_pVideoBuf = new char[size];
			}
			memcpy(m_pVideoBuf, buf, size);
			m_size = size;
			m_w = w;
			m_h = h;
			m_bitcount = bitcount;

		//::LeaveCriticalSection(m_lockBuf);
		//}
		}
	}
	Logger::debug("CVideoDlg::setVideoBuf out");

	InvalidateRect(NULL);
}
BOOL CVideoDlg::OnEraseBkgnd(CDC* pDC)
{
	{
		//CSingleLock bufLock(&m_lockBuf, TRUE);

		if(m_pVideoBuf){
			return TRUE;
		}
	}

	return CDialog::OnEraseBkgnd(pDC);
}


