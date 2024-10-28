#pragma once
#include <atlwin.h>
#include "TrackMgr.h"
#include "RGB24Buffer.h"
#include "Webcam.h"
#include "IWebcam.h"
#include "FPSDetector.h"

class IGestureListener{
public:
	virtual void OnBodyFound(){}
	virtual void OnBodyLost(){}
	virtual void OnGotBody(const MobiBody* pBody){}
	virtual void OnHandsFound(){}
	virtual void OnHandsLost(){}
	virtual void OnGotHands(const HtResult* pHtRes){}
	virtual bool OnSetGestureMode(MobiGestureMode& gesMode){ gesMode=GR_MOTION_EXT_1; return true; }
	virtual void OnGesture(MobiGestureEvent e, void* data){}
};

class IVBufListener{
public:
	virtual void OnGotBuffer(RGB24Buffer* pRGB)=0;
	virtual void OnFpsLow(float fps)=0;
};

class CDummyWnd : public CFrameWindowImpl<CDummyWnd>{
	BEGIN_MSG_MAP(CDummyWnd)
	END_MSG_MAP()
};

class CTrackerGestureSource
	: public CVdoFrameHandler
{
public:
	CTrackerGestureSource(IGestureListener* l, IVBufListener* vbl);
	virtual ~CTrackerGestureSource(void);

	virtual void VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize);

	int start();
	bool started();
	int stop();
	void setShowResult(bool bShowResult);
	int getWebcamName(wchar_t* nameBuf, int len);

private:
	CFPSDetector<50> m_fpsDetector;
	RGB24Buffer* m_pRGB;
	CDummyWnd m_dummyWnd;
	IWebcam* m_pCam;
	CTrackMgr* m_pTracker;
	IGestureListener* m_gesListener;
	IVBufListener* m_vbListener;
	HANDLE m_hFgLock;
	bool m_bShowResult;
	bool m_bStarted;

	bool m_hasBodyLast;
	bool m_hasHandsLast;
};
