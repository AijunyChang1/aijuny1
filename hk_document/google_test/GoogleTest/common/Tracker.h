#pragma once

#define MOBIDLL
#include "IMobiFD.h"
#include "IMobiFFT.h"
#include "IMobiBT.h"
//#include "gesture.h"
#include "IMobiGR.h"

#pragma comment(lib, "MobiFD.lib")
#pragma comment(lib, "MobiFFT.lib")
#pragma comment(lib, "MobiBT.lib")
#ifndef DEBUG
	#pragma comment(lib, "MobiGR.lib")
#else
	#pragma comment(lib, "MobiGRD.lib")
#endif

#include "cxcore.h"
#include "cv.h"
#pragma comment(lib, "cxcore210.lib")

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

class CTracker
{
	bool acceptVideo(int w, int h);
	bool m_bPaused;
public:
	CTracker(void);
	~CTracker(void);

	bool init();
	void uninit();
	bool process(const void* pBuffer, int bufferSize, int* hand);
	void setFlip(bool flip=true);

	//TODO: Remove the following 2 functions. Because when resolution changed, the tracker need be re-initialized.
	//for changing video size
	void onChangeToFilter(int w, int h);
	void onBackToDShow();

	bool hasBody() { return m_hasBody; }
	const MobiBody* getBodyPtr() { return &m_body; }

	//fc
	int faceCompare(int mode, int &ret, float &sim, char* nameFace);
	int checkFace();//return faceState
	void saveFace(const char* name);//return faceState
	bool isRegistered() {return m_fc_sim>0.8;} //return if it is exist user
	const char* getFaceName() { return m_fc_name; }
	void getFaceCenter(int &x, int &y);
	int getFaceSize()
	{
		return (int)max(m_body.nodeTorso.z, m_body.face.z); 
	}

//	int toEvent(int* hand);

	int handEvents(MobiGestureMode mode);
//	int SetTorsoPosition();

//	void GetScreenXY(float &dx, float &dy){m_Gesture.GetScreenXY(dx,dy);}
//	void GetTiltAngle(float &angle){m_Gesture.GetTiltAngle(angle);}

	int getBodyDataStr(char* buf, int len);
	void display_body(const void* pBuffer);
	void display_body_yuv2(const void* pBuffer);

private:
	MobiBody m_body;
	MobiBody m_bodyDisplay;
	//IMobiFD* m_fd;
	//IMobiFFT* m_fft;
	IMobiBT* m_bt;
	bool m_hasBody;
	MobiBody m_bodyLast;
	float m_factTemporal;

	//for face comparison(save parameters).
	float m_fc_sim;
	char m_fc_name[256];

	//CGesture m_Gesture;
	IMobiGR* m_Ges;
public:
	MobiGesture m_gestureResult;

	int GetAllModes(MobiGestureMode* &modes);
	char* GetModeName(MobiGestureMode mode);

	int GetAllGestures(MobiGestureEvent* &event);
	char* GetGestureName(MobiGestureEvent gesEvent);
};
