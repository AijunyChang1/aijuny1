#pragma once

#define MOBIDLL
//#include "IMobiGR.h"
//#include "IMobiTrackMgr.h"
#pragma comment(lib, "MobiGR.lib")
//#pragma comment(lib, "MobiTrackMgr.lib")

#include "cxcore.h"
#include "cv.h"
#pragma comment(lib, "cxcore210.lib")

//HEART engine
#include "IMobiHEART.h"
#pragma comment(lib, "MobiHEART.lib")

#define LIC_FILEPATH L"teli.lic"

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

////\addtogroup Main

enum ETrackerInUse{
	eTIU_Body = 0,
	eTIU_Palm = 1
};

///Palm tracking result
struct HtResult{
	MobiFace face;
	MobiHand lHand;
	MobiHand rHand;
};

class CTrackMgrData;
///\brief Wrapper the tracker module.
class CTrackMgr
{
	//bool acceptVideo(int w, int h);
public:
	CTrackMgr(void);
	virtual ~CTrackMgr(void);

	bool init();
	void uninit();
	bool process(const void* pBuffer, int bufferSize, MobiGestureMode gesMode);
	//void setFlip(bool flip=true);

	bool hasModel();
	bool hasBody();
	bool hasHands();
	const MobiBody* getBodyPtr();
	const HtResult* getHandsPtr();

	int getGesture(MobiGesture &ges);
	int getSilhouette(void* const pBuffer, const int widthStep, const int height);

	int getBodyDataStr(char* buf, int len);
	void display_body(const void* pBuffer);
	void display_hands(const void* pBuffer);
	void display_result(const void* pBuffer);

	/**
	 \brief Enable additional tracker data.
	 @param iEnable 0: disable, 1: fingers bit, 2: legs bit.
	 */
	void enableFullData(int iEnable);

public:
	int GetAllModes(MobiGestureMode* &modes);
	char* GetModeName(MobiGestureMode mode);

	int GetAllGestures(MobiGestureEvent* &event);
	char* GetGestureName(MobiGestureEvent gesEvent);

private:
	CTrackMgrData* d;
};
