#pragma once
#include "afxwin.h"

/** 
* @class CFXStcImage
* @brief
* Image Static control
*
* @author James Duy Trinh (duydinhtrinh@gmail.com)
* @version 1.0.0.1
* @date    15 April 2009
*/
class CFXStcImage :
	public CStatic
{
public:
	CFXStcImage(void);
	~CFXStcImage(void);

	BYTE* GetImageBytes() {return m_pImageBytes;}
	void ShowImage(BYTE *pImageBytes);
	void SetImageFormat(int iWidth, int iHeight, int iBitCount);
	void GetImageFormat(int& iWidth, int& iHeight, int& iBitCount);

	// Generated message map functions
protected:
	//{{AFX_MSG(CShowpic)
	afx_msg void OnPaint();
	//}}AFX_MSG

	DECLARE_MESSAGE_MAP()

protected: // Functions
	BITMAPINFO* MakeBMPHeader();

private: // Variables
	BYTE*		m_pImageBytes;
	int			m_iImageWidth;
	int			m_iImageHeight;
	int			m_iImageBitCount;
	int			m_iImageSize;
	BITMAPINFO*	m_pBmpInfo;
	HANDLE		m_hMutex;
};
