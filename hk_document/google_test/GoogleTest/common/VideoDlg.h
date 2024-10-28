#pragma once
#include <afxmt.h>


// CVideoDlg dialog

class CVideoDlg : public CDialog
{
	DECLARE_DYNAMIC(CVideoDlg)

public:
	CVideoDlg(CWnd* pParent = NULL);   // standard constructor
	virtual ~CVideoDlg();

	void setVideoBuf(char* buf, int size, int w, int h, int bitcount);

// Dialog Data
	enum { IDD = IDD_VIDEO };

private:
	//CCriticalSection m_lockBuf;
	CMutex m_lockBuf;
	char* m_pVideoBuf;
	int m_size;
	int m_w;
	int m_h;
	int m_bitcount;

protected:
	virtual void DoDataExchange(CDataExchange* pDX);    // DDX/DDV support

	DECLARE_MESSAGE_MAP()
public:
	afx_msg void OnPaint();
	afx_msg BOOL OnEraseBkgnd(CDC* pDC);
	virtual BOOL PreTranslateMessage(MSG* pMsg);
};
