#pragma once

#include "IWebcam.h"

enum ECamErrorEx{
	eCamEnumDevices = eCamFormatNotSupport+1,
	eCamUserCancel,
	eCamGetFormat,
	eCamSetFormat,
};

class CWebcamImpl;
class CWebcam : public IWebcam{
public:
	CWebcam();
	~CWebcam(void);

	virtual int start(HWND hWnd, CVdoFrameHandler* frame_handler=NULL); //return error, defined in ECamError
	virtual bool started() const;
	virtual void stop();
	virtual int getWebcamName(wchar_t* name, int len);
	virtual bool getFormat(int& width, int& height, int& frameRate);

private:
	CWebcamImpl* d;
};

class CNullWebcam : public IWebcam{
public:
	CNullWebcam(){}
	~CNullWebcam(void){}

	virtual int start(HWND hWnd, CVdoFrameHandler* frame_handler=NULL){ return 0; }
	virtual bool started() const{ return true; }
	virtual void stop(){}
	virtual int getWebcamName(wchar_t* name, int len){ name[0] = 0; return 0; }
	virtual bool getFormat(int& width, int& height, int& frameRate){ width=320, height=240; frameRate=30; return true; }
};
