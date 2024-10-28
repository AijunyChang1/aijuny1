#include "StdAfx.h"
#include "TkGesSrc2.h"
#include "Util.h"
#include "Settings.h"

#define USE_WEBCAMLIB
#ifdef USE_WEBCAMLIB
#pragma comment(lib, "IWebcam.lib")
#endif

CTrackerGestureSource::CTrackerGestureSource(HWND hwndApp, IGameController* pGame)
:m_pCam(NULL)
,m_tkThread(hwndApp, pGame)
,m_pRGB(NULL)
,m_bShowResult(false)
,m_bStarted(false)
,m_hwndApp(hwndApp)
,m_pGame(pGame)
{
	m_hFgLock = CreateMutex(NULL, FALSE, _T("DShowLock"));
	if(!m_hFgLock){
		Logger::error("Create DShowLock fail!");
	}
}

CTrackerGestureSource::~CTrackerGestureSource(void)
{
	CloseHandle(m_hFgLock);
}

int CTrackerGestureSource::start()
{
	//create buffer
	m_pRGB = new RGB24Buffer(320, 240);

#ifdef USE_WEBCAMLIB
	if(!m_pCam) m_pCam = CreateWebcam();
#else
	if(!m_pCam) m_pCam = new CWebcam();
#endif
	if(!m_pCam){
		AtlMessageBox(NULL, _T("CreateWebcam return null!"));
		exit(1);
	}else{
		m_dummyWnd.Create(NULL);
		//m_dummyWnd.MoveWindow(0,0,320,240);
		//m_dummyWnd.ShowWindow(SW_SHOW);
		assert((HWND)m_dummyWnd);

		//start cam
		Logger::info(L"m_pCam->start: enter.");
#ifdef USE_WEBCAMLIB
		int e = m_pCam->start(NULL, this);
#else
		int e = m_pCam->start(m_dummyWnd, this);
#endif
		Logger::info(L"m_pCam->start: end, ret=%d", e);
		if(e) return e;

		//m_dummyWnd.ShowWindow(SW_HIDE);
		{
			int w=0;
			int h=0;
			int frameRate=0;
			Logger::info(L"m_pCam->getFormat: enter.");
			bool bRet = m_pCam->getFormat(w,h,frameRate);
			Logger::info(L"m_pCam->getFormat: end, ret=%d", bRet);
			Logger::info(L"m_pCam->getFormat: w=%d, h=%d, fr=%d.", w, h, frameRate);
			if(!bRet){
				Logger::error(L"fail in get camera format.!");
				AtlMessageBox(NULL, _T("Can't get camera format!"));
				return eCamFormatNotSupport;
			}
			if(w!=320 || h!=240){
				Logger::warn(L"%dx%d format may not be supported!", w, h);
			}
		}

		//init tracker
		m_tkThread.Start();
	}
	m_bStarted = true;
	return 0;
}

bool CTrackerGestureSource::started(){
	return m_bStarted;
}

int CTrackerGestureSource::stop()
{
	int times = 10;
	while(times--){
		if(WaitForSingleObject(m_hFgLock, 200)==WAIT_OBJECT_0){
			CMutexRelease mutexRelease(m_hFgLock);
			if(m_pCam){
				Logger::info(L"m_pCam->started(): enter");
				if(m_pCam->started()){
					Logger::info(L"m_pCam->started(): end with true");
					Logger::info(L"m_pCam->stop(): enter");
					m_pCam->stop();
					//Sleep(200);
					Logger::info(L"m_pCam->stop(): end");
					m_dummyWnd.DestroyWindow();
				}else{
					Logger::info(L"m_pCam->started(): end with false");
				}
#ifdef USE_WEBCAMLIB
				Logger::info(L"Before ReleaseWebcam");
				ReleaseWebcam(&m_pCam);
				Logger::info(L"After ReleaseWebcam");
#else
				delete m_pCam;
#endif
				m_pCam = NULL;
			}

			{
				BOOL ret = m_tkThread.Stop();
				ret = m_tkThread.WaitForQuit();
				Logger::info(L"m_tkThread.WaitForQuit(), ret=%d", ret);
			}

			Logger::info("CTrackerGestureSource::stop(): succeed!");
			break;
		}else{
			Logger::info("CTrackerGestureSource::stop(): timeout!!!");
		}
	}
	if(m_pRGB){
		delete m_pRGB;
		m_pRGB = NULL;
	}
	return 0;
}

void CTrackerGestureSource::VdoFrameData( double dblSampleTime, BYTE * pBuffer, long lBufferSize )
{
	static bool first = true; if(first){ first = false;	Util::showThreadPriority("dshow"); }

	m_fpsDetector.OnGotFrame();
	if(!m_bStarted) return;

	float fps = m_fpsDetector.getFPS();
	//Logger::info("VdoFrameData: fpsLow %1.3f", fps);
	//Logger::warn(L"FPS: %1.3f", fps);
	if(m_fpsDetector.isLowFPS(fps)){
		Logger::warn(L"lowFPS: %1.3f", fps);
		m_pGame->showErrorMsg(201);
	}

	if(lBufferSize!=230400){
		Logger::warn("VdoFrameData(%1.6f, %x, %d)", dblSampleTime, pBuffer, lBufferSize );
		return;
	}

	//memcpy(m_pBuf, pBuffer, lBufferSize);
	if(m_pRGB->trySetImgData(pBuffer, lBufferSize)){
		BOOL ret = m_tkThread.PostThreadMsg(UM_VIDEOBUF, (WPARAM)m_pRGB, 0);
		if(!ret) Logger::warn(L"Post UM_VIDEOBUF fail!");
	}else{
		Logger::warn(L"VdoFrameData: m_pRGB is busy.");
	}

	m_pGame->postVideoBuffer(pBuffer, lBufferSize, 320, 240, 24);
}

void CTrackerGestureSource::setShowResult( bool bShowResult )
{
	m_bShowResult = bShowResult;
	m_tkThread.PostThreadMsg(UM_SHOWRESULT, (WPARAM)bShowResult, 0);
}

void CTrackerGestureSource::setGestureMode( int iMode ){
	m_tkThread.PostThreadMsg(UM_GESTUREMODE, (WPARAM)iMode);
}

int CTrackerGestureSource::restartCam()
{
	if(m_pCam){
		if(m_pCam->started()){
			m_pCam->stop();
			Logger::info(L"m_pCam->stop: before restart.");
		}else{
			Logger::info(L"m_pCam has stoped: before restart.");
		}

		Logger::info(L"m_pCam->start: enter.");
		int e = m_pCam->start(NULL, this);
		Logger::info(L"m_pCam->start: end, ret=%d", e);
		if(e) return e;
	}else{
		Logger::error(L"m_pCam has not initialized.");
	}
	return 0;
}

void CTrackerGestureSource::enableTrackerFullData( int iEnable )
{
	//Logger::error(L"Kevin: CTrackerGestureSource::enableTrackerFullData(%d) called.", iEnable);
	m_tkThread.PostThreadMsg(UM_FULLBODYDATA, (WPARAM)iEnable);
}