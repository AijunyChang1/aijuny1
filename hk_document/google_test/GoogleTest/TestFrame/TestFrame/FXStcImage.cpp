#include "StdAfx.h"
#include "FXStcImage.h"
#include "FXUtil.h"

CFXStcImage::CFXStcImage(void)
{
	m_pImageBytes		= NULL;
	m_pBmpInfo			= 0;
	m_iImageBitCount	= 0;
	m_iImageWidth		= 0;
	m_iImageHeight		= 0;
	m_hMutex			= CreateMutex( NULL, FALSE, NULL );
}

CFXStcImage::~CFXStcImage(void)
{
	delete[] m_pImageBytes;
	delete[] m_pBmpInfo;
	if (m_hMutex != NULL) {
		CloseHandle(m_hMutex);
		m_hMutex = NULL;
	}
}

// CShowpic message handlers
BEGIN_MESSAGE_MAP(CFXStcImage, CStatic)
	//{{AFX_MSG_MAP(CFXStcImage)
	ON_WM_PAINT()
	//}}AFX_MSG_MAP
END_MESSAGE_MAP()

BITMAPINFO* CFXStcImage::MakeBMPHeader()
{	
	DWORD  dwBitmapInfoSize;
	delete[] m_pBmpInfo;
	delete[] m_pImageBytes;
	BITMAPINFO* pResult					= NULL;
	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER) + /*(m_iImageBitCount==8?256:1)*/256 * sizeof( RGBQUAD );
	pResult								= (BITMAPINFO *)new BYTE [dwBitmapInfoSize];
	m_pBmpInfo							= pResult;

	m_iImageSize						= m_iImageWidth*m_iImageHeight*(m_iImageBitCount>>3);
	m_pImageBytes						= new BYTE[m_iImageSize];
	memset(m_pImageBytes, 0, m_iImageSize);

	ZeroMemory( m_pBmpInfo, dwBitmapInfoSize );
	pResult->bmiHeader.biSize			= sizeof(BITMAPINFOHEADER);
	pResult->bmiHeader.biWidth			= m_iImageWidth;
	pResult->bmiHeader.biHeight			= m_iImageHeight;
	pResult->bmiHeader.biPlanes			= 1;
	pResult->bmiHeader.biBitCount		= (unsigned short)m_iImageBitCount;
	pResult->bmiHeader.biCompression	= BI_RGB;
	pResult->bmiHeader.biSizeImage		= m_iImageSize;
	pResult->bmiHeader.biXPelsPerMeter	= 0;
	pResult->bmiHeader.biYPelsPerMeter	= 0;
	pResult->bmiHeader.biClrUsed		= 256/*m_iImageBitCount == 8?256:0*/;
	pResult->bmiHeader.biClrImportant	= 0;

	//if (m_iImageBitCount == 8) {
		// Fill in the color table
		for( int Index = 0; Index < 256; ++Index ) {  
			m_pBmpInfo->bmiColors[Index].rgbBlue = Index;  
			m_pBmpInfo->bmiColors[Index].rgbGreen = Index;  
			m_pBmpInfo->bmiColors[Index].rgbRed = Index;  
		}
	//}

	return pResult;
}

void CFXStcImage::OnPaint()
{
	CRect rc;
	CPaintDC dc(this); // device context for painting
	// TODO: Add your message handler code here
	GetClientRect(&rc);

	if(m_pImageBytes != NULL) {
		dc.RealizePalette();
		SetStretchBltMode(dc.GetSafeHdc(), COLORONCOLOR);

		int nResult = ::StretchDIBits(
			dc.GetSafeHdc(),
			rc.left,
			rc.top,
			rc.right - rc.left,
			rc.bottom - rc.top,
			0,
			0,
			m_iImageWidth, 
			m_iImageHeight,
			m_pImageBytes, 
			m_pBmpInfo,
			DIB_RGB_COLORS,
			SRCCOPY);
	}

}

void CFXStcImage::ShowImage(BYTE *pImageBytes)
{
	WaitForSingleObject( m_hMutex, INFINITE );
	if(pImageBytes != NULL) {
		memcpy(m_pImageBytes, pImageBytes, m_iImageSize);
		this->Invalidate (false);
		//this->GetParent
		OnPaint();
	}
	ReleaseMutex( m_hMutex );
}

void CFXStcImage::SetImageFormat(int iWidth, int iHeight, int iBitCount)
{
	WaitForSingleObject( m_hMutex, INFINITE );
	if (m_iImageWidth != iWidth
		|| m_iImageHeight != iHeight
		|| m_iImageBitCount != iBitCount) {
		m_iImageWidth = iWidth;
		m_iImageHeight = iHeight;
		m_iImageBitCount = iBitCount;
		MakeBMPHeader();
	}
	ReleaseMutex( m_hMutex );
}

void CFXStcImage::GetImageFormat(int& iWidth, int& iHeight, int& iBitCount)
{
	WaitForSingleObject( m_hMutex, INFINITE );
	iWidth = m_iImageWidth;
	iHeight = m_iImageHeight;
	iBitCount = m_iImageBitCount;
	ReleaseMutex( m_hMutex );
}