/* Copyright (c) 2009 Mobinex Inc. All right reserved. */

#ifndef _IMOBIBT_H_
#define _IMOBIBT_H_

#include "MobiBTCommon.h"


//Interface class for body tracking
class IMobiBT
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

	//Set/Get FD Config
	virtual int SetConfig(const MobiBTConfig &config)=0;	//fd configurations
	virtual void GetConfig(MobiBTConfig &config)=0;
	
	//Init body
	virtual int InitBody(
		const void* bitmapPtr,	//pointer of input image data buffer
		int bufferSize,			//size of input image data buffer
		int &numBody,			//number of detected human body
		MobiBody* arrBody		//array of detected human body
		)=0;

	//Process frame
	virtual int ProcessFrame(
		const void* bitmapPtr,	//pointer of input image data buffer
		int bufferSize,			//size of input image data buffer
		const int numBody,		//number of detected human body
		MobiBody* arrBody		//array of tracked human body
		)=0;

	//Face comparison processing
	virtual int FaceComparison(
		int mode,				//operation mode: 0-register, 1-compare, 2-save
		int &ret,				//comparison status returned: '-1'-face not detected, 0-face detected, 1-frontal face got, 2-mouth-open got, 3-mouth-close got
		float &sim,				//similarity of comparison: max matched person
		char* nameFace)=0;		//registered/matched face name
};

MOBIAPI IMobiBT* CreateMobiBT();			// create IMobiBT instance, should be called firstly
MOBIAPI void ReleaseMobiBT(IMobiBT** p);	// release IMobiBT instance

#endif // _IMOBIBT_H_
