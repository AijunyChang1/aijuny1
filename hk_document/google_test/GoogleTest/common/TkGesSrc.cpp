#include "StdAfx.h"
#include "TkGesSrc.h"
#include "Util.h"
#include "Settings.h"

#define USE_WEBCAMLIB
#ifdef USE_WEBCAMLIB
#pragma comment(lib, "IWebcam.lib")
#endif

CTrackerGestureSource::CTrackerGestureSource(IGestureListener* l, IVBufListener* vbl)
:m_pCam(NULL)
,m_pTracker(NULL)
,m_pRGB(NULL)
,m_gesListener(l)
,m_vbListener(vbl)
,m_bShowResult(false)
,m_bStarted(false)
,m_hasBodyLast(false)
,m_hasHandsLast(false)
{
	m_hFgLock = CreateMutex(NULL, FALSE, _T("DShowLock"));
	if(!m_hFgLock){
		Logger::error("Create DShowLock fail!\n");
	}
}

CTrackerGestureSource::~CTrackerGestureSource(void)
{
	CloseHandle(m_hFgLock);
	m_hFgLock = NULL;
}

int CTrackerGestureSource::start()
{
#ifdef USE_WEBCAMLIB
	if(!m_pCam) m_pCam = CreateWebcam();
#else
	if(!m_pCam) m_pCam = new CNullWebcam();
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
			::videoSettings(w, h);
			m_pRGB = new RGB24Buffer(w, h);
		}

		//init tracker
		if(!m_pTracker){
			m_pTracker = new CTrackMgr;
			m_pTracker->init();
			//m_pTracker->setFlip(true);
		}
	}
	m_bStarted = true;
	return 0;
}

bool CTrackerGestureSource::started(){
	//bool bStarted = false;
	//if(m_pCam){
	//	Logger::info(L"m_pCam->started(): enter");
	//	bStarted = m_pCam->started();
	//	Logger::info(L"m_pCam->started(): exit, ret=%d", bStarted);
	//}
	//return bStarted;
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

			if(m_pRGB){
				delete m_pRGB;
				m_pRGB = NULL;
			}

			if(m_pTracker){
				Logger::info(L"m_pTracker->uninit(): enter");
				m_pTracker->uninit();
				Logger::info(L"m_pTracker->uninit(): end");
				delete m_pTracker;
				m_pTracker = NULL;
			}

			Logger::info("CTrackerGestureSource::stop(): succeed!");
			break;
		}else{
			Logger::info("CTrackerGestureSource::stop(): timeout!!!");
		}
	}
	return 0;
}

void CTrackerGestureSource::VdoFrameData( double dblSampleTime, BYTE * pBuffer, long lBufferSize )
{
	static bool first = true; if(first){ first = false;	Util::showThreadPriority("dshow"); }

	if(!m_bStarted) return;

	if(lBufferSize!=230400){
		Logger::warn("VdoFrameData(%1.6f, %x, %d)", dblSampleTime, pBuffer, lBufferSize );
		return;
	}

	//skip first 100 frames
	//static int trackFrames = 0;
	//trackFrames++;
	//if(trackFrames<5) return;

	if(WaitForSingleObject(m_hFgLock, 100)==WAIT_OBJECT_0){
		CMutexRelease mutexRelease(m_hFgLock);
		if(!m_pCam){
			return;
		}

		//__try
		{
			//m_pRGB->setImgData(pBuffer, lBufferSize, m_pCam->isUsingYUY2());
			m_pRGB->setImgData(pBuffer, lBufferSize);

			//////////////////////////////////////////////////////////////////////////
			if(!m_gesListener) return ;

			MobiGestureMode gesMode;
			if(!m_gesListener->OnSetGestureMode(gesMode)){
				gesMode = GR_MOTION_EXT_1;
			}

			byte* pBuffer = m_pRGB->lock();
			//if(trackFrames==100) Util::saveData("test.raw", pBuffer, m_pRGB->getSize());
			bool hasModel = m_pTracker->process(pBuffer, m_pRGB->getSize(), gesMode);
			m_pRGB->unlock();

			bool hasBody = m_pTracker->hasBody();
			bool hasHands = m_pTracker->hasHands();
			{
				//fire OnBodyFound/OnHandsFound
				if(hasBody!=m_hasBodyLast){
					m_hasBodyLast = hasBody;
					if(hasBody){
						m_gesListener->OnBodyFound();
					}else{
						m_gesListener->OnBodyLost();
					}
				}
				if(hasHands!=m_hasHandsLast){
					m_hasHandsLast = hasHands;
					if(hasHands){
						m_gesListener->OnHandsFound();
					}else{
						m_gesListener->OnHandsLost();
					}
				}
			}
			if(hasModel){
				//fire OnGesture
				{
					MobiGesture ges;
					int evt = m_pTracker->getGesture(ges);
					//the gesNeutral event is sent too frequently, that reduce the performance of c++ to flash communication, so ban it.
					if(gesUndefined!=evt && gesNeutral!=evt){
						m_gesListener->OnGesture((MobiGestureEvent)evt, &ges);
					}
				}

				//fire OnGotBody
				if(hasBody)
					m_gesListener->OnGotBody(m_pTracker->getBodyPtr());

				if(hasHands)
					m_gesListener->OnGotHands(m_pTracker->getHandsPtr());

				if(m_bShowResult)
				{
					m_pTracker->display_result(m_pRGB->lock());
					m_pRGB->unlock();
				}
			}else{
			}
			//fire OnGotBuffer
			m_fpsDetector.OnGotFrame();
			float fps = m_fpsDetector.getFPS();
			Logger::warn(L"FPS: %1.3f\n", fps);
			//if(fps<m_fpsDetector.getThreshold())
			if(m_fpsDetector.isLowFPS(fps))
			{
				Logger::warn(L"lowFPS: %1.3f\n", fps);
				m_vbListener->OnFpsLow(fps);
			}
			m_vbListener->OnGotBuffer(m_pRGB);
		}
		//__except(EXCEPTION_EXECUTE_HANDLER){
		//	Logger::error(L"Something bad happens in VdoFrameData!\n");
		//}
	}
}

void CTrackerGestureSource::setShowResult( bool bShowResult )
{
	m_bShowResult = bShowResult;
}

int CTrackerGestureSource::getWebcamName( wchar_t* nameBuf, int len ){
	Logger::info(L"m_pCam->getWebcamName: begin");
	int ret = -1;
	if(m_pCam){
		ret = m_pCam->getWebcamName(nameBuf, len);
	}else{
		Logger::warn(L"Call getWebcamName but m_pCam is NULL!");
	}
	Logger::info(L"m_pCam->getWebcamName: end");
	return ret;
}