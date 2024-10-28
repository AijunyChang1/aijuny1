/* Copyright (c) 2010 Mobinex Inc. All right reserved. */

#ifndef _IMOBI_TRACK_MGR_H_
#define _IMOBI_TRACK_MGR_H_

#include "IMobiBT.h"
#include "IMobiGR.h"
#include "IMobiHT.h"

//BT configuration struct
typedef struct _TrackMgrConfig
{
	int	maxNum;					//max number of detected body
	int modeBT;					//mode of body tracking
	int modeHT;					//mode of palm tracker
	int modeGesture;			//mode of body track gesture
} TrackMgrConfig;


enum TRACK_MODE
{
	modeIdle = -1, 
	modeBody, 
	modePalm
};

//Interface class for body tracking
class IMobiTrackMgr
{
public:
	//Initialize bt
	virtual int Initialize(const char* sLicense)=0;	//license key 

	//Set Image Format
	virtual int SetImgFormat(
		int widthStep,			//width step of image data in bytes, default: 320*3
		int height,				//image height, default: 240
		int width,				//image width, default: 320
		int colorMode,			//image color mode, default: MOBI_CM_RGB (24 bits RGB image)
		bool origin=false		//indicate the origin of image, false: top-left, true: bottom-left (windows bitmap style)
		)=0;

	//Set/Get Config
	virtual int SetConfig(const TrackMgrConfig &config)=0;	//configurations
	virtual void GetConfig(TrackMgrConfig &config)=0;


	//Process frame
	virtual int ProcessFrame(
		const void* bitmapPtr,	//pointer of input image data buffer
		int bufferSize,			//size of input image data buffer
		int &numBody,			//number of detected human body
		MobiBody* arrBody,		//array of tracked human body
		MobiFace &face,			//MobiFace data from fd module
		MobiHand &handLeft,		//palm track, left hand position
		MobiHand &handRight,	//palm track, right hand position
		MobiGesture &gesBody,	//body track gestures
		MobiGesPalm &gesPalm,	//palm track gestures		
		int &flag				//current track: 0, body tracker, 1, palm track
		)=0;
	
};

MOBIAPI IMobiTrackMgr* CreateMobiTrackMgr();			// create IMobiBT instance, should be called firstly
MOBIAPI void ReleaseMobiTrackMgr(IMobiTrackMgr** p);	// release IMobiBT instance

#endif // _IMOBI_TRACK_MGR_H_
