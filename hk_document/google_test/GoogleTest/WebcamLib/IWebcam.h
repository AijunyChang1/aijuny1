#pragma once
#include "vdoframehandler.h"

#ifdef WEBCAM_EXPORTS
#define WEBCAMAPI __declspec(dllexport)
#else
#define WEBCAMAPI __declspec(dllimport)
#endif

///\addtogroup Webcam
///@{
enum ECamError{
	eCamSucceed = 0,
	eCamNoCamera,
	eCamCantOpen,
	eCamFormatNotSupport,
	eCamNoFilter,
	eCamNoData
};

/**
 \brief Interface to control a webcam.
 */
class IWebcam{
public:
	/**
	 \brief Start a webcam.
	 @param hWnd a handle of window to contain video window, can be NULL.
	 @param frame_handler a interface to receive incoming video frames.
	 @retval error code
	 @see ECamError for error code.
	 */
	virtual int start(HWND hWnd, CVdoFrameHandler* frame_handler) = 0;
	virtual bool started() const = 0;
	virtual void stop() = 0;
	/**
	 @deprecated
	 @retval length of name
	 */
	virtual int getWebcamName(wchar_t* nameBuf, int len) = 0;
	virtual bool getFormat(int& width, int& height, int& frames) = 0;
};

WEBCAMAPI IWebcam* CreateWebcam();
WEBCAMAPI void ReleaseWebcam(IWebcam** p);
///@}
