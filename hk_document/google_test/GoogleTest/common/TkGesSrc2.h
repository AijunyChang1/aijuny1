#pragma once
#include <atlwin.h>
#include "TrackMgr.h"
#include "RGB24Buffer.h"
#include "Webcam.h"
#include "IWebcam.h"
#include "FPSDetector.h"
#include "Thread.h"
#include "UserMsgs.h"
#include "Util.h"
#include "TrackerThread.h"
#include "IGameController.h"

class CDummyWnd : public CFrameWindowImpl<CDummyWnd>{
	BEGIN_MSG_MAP(CDummyWnd)
	END_MSG_MAP()
};

///\addtogroup Main
///@{

///\brief Manage tracker and webcam modules.
class CTrackerGestureSource
	: public CVdoFrameHandler
{
public:
	CTrackerGestureSource(HWND hwndApp, IGameController* pGame);
	virtual ~CTrackerGestureSource(void);

	virtual void VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize);///< Receive frame data from webcam.

	int start(); ///< Create and start tracker and webcam modules.
	bool started(); ///< Determine if sub modules are started.
	int stop(); ///< Stop and release webcam and tracker modules.
	void setShowResult(bool bShowResult); ///< Show/hide tracking results.
	void setGestureMode( int iMode ); ///< Set the way that gestures are recognized. 
	int restartCam(); ///< Restart webcam.

	void enableTrackerFullData(int iEnable); ///< Tell tracker thread

private:
	CTrackerThread m_tkThread;
	CFPSDetector<50> m_fpsDetector;

	CDummyWnd m_dummyWnd;
	IWebcam* m_pCam;
	HANDLE m_hFgLock;
	bool m_bShowResult;
	bool m_bStarted;

	RGB24Buffer* m_pRGB;
	HWND m_hwndApp;
	IGameController* m_pGame;
};

///@}