#include "StdAfx.h"
#include "HugeCursor.h"

#include <atlimage.h>

#ifndef OEMRESOURCE
#define OCR_NORMAL          32512
#define OCR_IBEAM           32513
#define OCR_WAIT            32514
#define OCR_CROSS           32515
#define OCR_UP              32516
#define OCR_SIZE            32640   /* OBSOLETE: use OCR_SIZEALL */
#define OCR_ICON            32641   /* OBSOLETE: use OCR_NORMAL */
#define OCR_SIZENWSE        32642
#define OCR_SIZENESW        32643
#define OCR_SIZEWE          32644
#define OCR_SIZENS          32645
#define OCR_SIZEALL         32646
#define OCR_ICOCUR          32647   /* OBSOLETE: use OIC_WINLOGO */
#define OCR_NO              32648
#define OCR_HAND            32649
#define OCR_APPSTARTING     32650
#endif

CHugeCursor::CHugeCursor(void)
{
}

CHugeCursor::~CHugeCursor(void)
{
	stop();
}

static bool setCursor( LPCTSTR pngPath, DWORD idCursor );
bool CHugeCursor::start()
{
	bool ret = setCursor(_T("cursors\\mouse6.png"), OCR_NORMAL);
	ret = (ret && setCursor(_T("cursors\\mouse4.png"), OCR_HAND));
	ret = (ret && setCursor(_T("cursors\\mouse5.png"), OCR_IBEAM));
	return ret;
}

void CHugeCursor::stop()
{
	SystemParametersInfo(SPI_SETCURSORS, 0, NULL, SPIF_SENDWININICHANGE);
}

static bool setCursor( LPCTSTR pngPath, DWORD idCursor )
{
	CImage img;
	img.Load(pngPath);
	if(!img.IsNull() && img.GetBPP()==32){
		ICONINFO ii;
		ii.fIcon = FALSE;
		ii.hbmColor = img;
		ii.hbmMask = img;
		ii.xHotspot = 3;
		ii.yHotspot = 3;
		HCURSOR hCursor = CreateIconIndirect(&ii);
		BOOL ret = SetSystemCursor(hCursor, idCursor);
		if(ret) return true;
		else return false;
	}else{
		return false;
	}
}