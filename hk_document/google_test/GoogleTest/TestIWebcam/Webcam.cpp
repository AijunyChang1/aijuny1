#include "StdAfx.h"
#include "resource.h"
#include "CaptureVideo.h"
#include "Util.h"
#include "Settings.h"
#include "SelCamDlg2.h"
#include "Webcam.h"

#include <string>
#include <map>
using namespace std;

class ISelectCamera{
public:
	virtual int selectDevice( map<int, CameraInfo> &devices ) = 0;
	virtual BOOL showVirtual(){ return TRUE; }
};

class CWebcamImpl: public CVdoFrameHandler, ISelectCamera{
public:
	bool isSourceYUY2;
	bool bInited;
	bool bStarted;
	HWND hWnd;
	CCaptureVideo* pCap;
	CameraInfo sLastDeviceInfo;
	CVdoFrameHandler *frameHandler;

	virtual int selectDevice(map<int, CameraInfo> &devices){
		bool bForceShowDlg = false;
		if(GetAsyncKeyState(VK_CONTROL)&0x8000){
			bForceShowDlg = true;
		}
		if(devices.size()>1 || bForceShowDlg){
			map<int, wstring> deviceNames;
			for(map<int, CameraInfo>::iterator i=devices.begin(); i!=devices.end(); ++i){
				deviceNames[i->first] = i->second.name;
			}

			CSelCamDlg2 dlg;
			dlg.setDevices(&deviceNames);
			if(dlg.DoModal()==IDOK){
				return dlg.getSel();
			}else{
				return -1;
			}
		}else{
			return 0;
		}
	}
	virtual BOOL showVirtual(){
		if(GetAsyncKeyState(VK_CONTROL)&0x8000)
			return TRUE;
		else
			return FALSE;
	}
	virtual void VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize){
		if(frameHandler && bStarted){
			frameHandler->VdoFrameData(dblSampleTime, pBuffer, lBufferSize);
		}
	}
	void init(){
		pCap = new CCaptureVideo;
		bInited = true;
	}

	void uninit(){
		delete pCap;
		pCap = NULL;
		bInited = false;
	}
	bool inited() const{
		return bInited;
	}
	int chooseCamera( HWND hWnd, wstring &cameraName ){
		if(inited()==false) init();

		map<int, CameraInfo> devices;
		CameraInfo selectedDeviceInfo;

		int err = pCap->EnumDevices(devices, showVirtual());
		if(err<0){
			return eCamEnumDevices;
		}else if(devices.size()==0){
			return eCamNoCamera;
		}else{
			if(devices.size()>0){
				int deviceIndex = selectDevice(devices);
				if(deviceIndex==-1){
					return eCamUserCancel;
				}else{
					selectedDeviceInfo = devices[deviceIndex];
				}
			}
		}

		sLastDeviceInfo = selectedDeviceInfo;
		cameraName = selectedDeviceInfo.friendlyName;
		pCap->SetPreferredVideoSize(VIDEO_W, VIDEO_H);
		return eCamSucceed;
	}
};

CWebcam::CWebcam():d(new CWebcamImpl){
	d->bInited = false;
	d->bStarted = false;
	d->pCap = NULL;
	d->frameHandler = NULL;
}

CWebcam::~CWebcam(void){
	delete d;
}

int CWebcam::start( HWND hWnd, CVdoFrameHandler* frame_handler ){
	if(d->inited()==false) d->init();

	d->frameHandler = frame_handler;

	//select device
	if(d->sLastDeviceInfo.friendlyName.length()==0){
		wstring name;
		int err = d->chooseCamera(hWnd, name);
		if(err!=eCamSucceed) return err;
	}

	//try open camera
	videoSetDepth(24);
	HRESULT hr = d->pCap->Open((wchar_t*)d->sLastDeviceInfo.name.c_str(), hWnd, MEDIASUBTYPE_RGB24);
	if(hr==S_OK){
		Logger::info("Open camera(RGB24) succeed.");
	}else{
		d->pCap->Close();
		videoSetDepth(16);
		hr = d->pCap->Open((wchar_t*)d->sLastDeviceInfo.name.c_str(), hWnd, MEDIASUBTYPE_YUY2);
		if(SUCCEEDED(hr)){
			Logger::info("Open camera(YUY2) succeed.");
		}else{
			d->pCap->Close();
			return eCamCantOpen;
		}
	}

	if(SUCCEEDED(hr)){
		{
			int w, h, depth, frameRate;
			d->pCap->getGrabParams(w, h, depth, frameRate);
			videoSettings(w, h, depth);
		}
		d->pCap->GrabVideoFrames(TRUE, d);
		d->bStarted = true;
		return eCamSucceed;
	}else{
		Logger::error("CWebcam::start fail, hr=0x%x", hr);
		return eCamCantOpen;
	}
}

void CWebcam::stop(){
	if(d->bStarted){
		d->bStarted = false;
		d->pCap->GrabVideoFrames(FALSE, NULL);
		//d->pCap->Close();
		d->uninit();
	}
}

bool CWebcam::getFormat( int& width, int& height, int& frameRate ){
	if(d->pCap){
		int bits;
		d->pCap->getGrabParams(width, height, bits, frameRate);
		return true;
	}else{
		return false;
	}
}

bool CWebcam::started() const{
	return d->bStarted;
}

int CWebcam::getWebcamName( wchar_t* name, int len )
{
	wcscpy_s(name, len, d->sLastDeviceInfo.devicePath.c_str());
	return d->sLastDeviceInfo.devicePath.length();
}
