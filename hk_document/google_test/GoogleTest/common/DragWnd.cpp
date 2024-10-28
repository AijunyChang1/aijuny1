#include "StdAfx.h"
#include "DragWnd.h"

LRESULT CALLBACK CDragWnd::DragWndProc( HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam )
{
	CDragWnd *p = reinterpret_cast<CDragWnd *>(GetWindowLong(hwnd, GWL_USERDATA));
	switch (message){
	case WM_LBUTTONDOWN:
		{
			POINT pt = { (int)(short)LOWORD(lParam), (int)(short)HIWORD(lParam) };
			RECT rc;
			::GetWindowRect(hwnd, &rc);

			p->m_nX = rc.left + pt.x;
			p->m_nY = rc.top + pt.y;
			p->m_nLeft = rc.left;

			p->m_nTop = rc.top;

			p->m_bCaptured = TRUE;

			::SetCapture(hwnd);
			if(p->m_oldWndProc)
				return p->m_oldWndProc(hwnd, message, wParam, lParam);
		}
	case WM_LBUTTONUP:
		{
			p->m_bCaptured = FALSE;
			::ReleaseCapture();
			break;
		}

	case WM_MOUSEMOVE:
		{
			if (p->m_bCaptured)
			{
				POINT pt = { (int)(short)LOWORD(lParam), (int)(short)HIWORD(lParam) };

				RECT rc;
				::GetWindowRect(hwnd, &rc);

				int nWidth = rc.right - rc.left;
				int nHeight = rc.bottom - rc.top;

				rc.left = p->m_nLeft + (pt.x + rc.left - p->m_nX);
				rc.top = p->m_nTop + (pt.y + rc.top - p->m_nY);

				::MoveWindow(hwnd, rc.left, rc.top, nWidth, nHeight, TRUE);

				if(p->m_oldWndProc)
					return p->m_oldWndProc(hwnd, message, wParam, lParam);
			}
		}
	default:
		{
		}
	}
	if(p->m_oldWndProc)
		return p->m_oldWndProc(hwnd, message, wParam, lParam);
	else
		return TRUE;
}

void CDragWnd::makeDragable( HWND hwnd )
{
	if(::IsWindowUnicode(hwnd)){
		LONG oldData = SetWindowLongW(hwnd, GWL_USERDATA, reinterpret_cast<LONG>(this));
		m_oldWndProc = reinterpret_cast<WNDPROC>(SetWindowLongW(hwnd, GWL_WNDPROC, reinterpret_cast<LONG>(DragWndProc)));
	}else{
		LONG oldData = SetWindowLongA(hwnd, GWL_USERDATA, reinterpret_cast<LONG>(this));
		m_oldWndProc = reinterpret_cast<WNDPROC>(SetWindowLongA(hwnd, GWL_WNDPROC, reinterpret_cast<LONG>(DragWndProc)));
	}
}
