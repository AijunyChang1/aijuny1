#pragma once

#include <atlbase.h>
#include <atlapp.h>
#include <atlcrack.h>

///\addtogroup CommonLib

/**
 \brief Show live video in a draggable window.
 */
class CVideoDlg2 : public CDialogImpl<CVideoDlg2>, public CMessageFilter{
public:
	enum { IDD = IDD_VIDEO };
	CVideoDlg2();
	~CVideoDlg2();

	virtual BOOL PreTranslateMessage(MSG* pMsg);

	BEGIN_MSG_MAP(CVideoDlg2)
		//MSG_WM_PAINT(OnPaint)
		MSG_WM_ERASEBKGND(OnEraseBkgnd)
		MSG_WM_INITDIALOG(OnInitDialog)
		MSG_WM_NCHITTEST(OnNCHitTest)
	END_MSG_MAP()

	HANDLE m_lockBuf;
	char* m_pVideoBuf;
	int m_size;
	int m_w;
	int m_h;
	int m_bitcount;
	bool m_bDragable;
public:
	void setVideoBuf(char* buf, int size, int w, int h, int bitcount, bool flipLR=false);
	void setDragable(bool bEnable);

	//LRESULT OnPaint(HDC hdc);
	LRESULT OnEraseBkgnd(HDC hdc);
	LRESULT OnInitDialog(HWND hwndFocus, LPARAM lParam);
	LRESULT OnNCHitTest(CPoint Pt);
};
