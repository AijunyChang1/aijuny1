#pragma once

///\addtogroup CommonLib

///\brief This class makes a window draggable.
class CDragWnd{

public:
	CDragWnd(){
		m_nX = 0;
		m_nY = 0;
		m_nLeft = 0;
		m_nTop = 0;
		m_bCaptured = FALSE;
		m_oldWndProc = 0;
	}
	void makeDragable(HWND hwnd);

private:
	LONG m_nX;
	LONG m_nY;
	LONG m_nLeft;
	LONG m_nTop;
	BOOL m_bCaptured;
	WNDPROC m_oldWndProc;

	static LRESULT CALLBACK DragWndProc(HWND hwnd, UINT message, WPARAM wParam, LPARAM lParam);
};
