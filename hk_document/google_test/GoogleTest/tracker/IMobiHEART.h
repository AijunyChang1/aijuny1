/* Copyright (c) 2010 Mobinex Inc. All right reserved. */

#pragma once


#include "MobiBTCommon.h"
#include "MobiGRCommon.h"


//MobiHEART configuration struct
typedef struct _MobiHEARTConfig
{
	bool	bFFT;				//flag for activating facial feature tracking
	bool	bFR;				//flag for activating face comparison
	bool	bBT;				//flag for activating body tracking
	bool	bGR;				//flag for activating gesture recognition
	bool	bLegs;				//flag for activating legs tracking
	bool	bFingers;			//flag for activating fingertips tracking
} MobiHEARTConfig;


//Interface class for MobiHEART library
class IMobiHEART
{
public:
	//Initialize bt
	virtual int Initialize(const char* sLicense)=0;	//license key 

	//Set Image Format
	virtual int SetImgFormat(
		int		widthStep,			//width step of image data in bytes, default: 320*3
		int		height,				//image height, default: 240
		int		width,				//image width, default: 320
		int		colorMode,			//image color mode, default: MOBI_CM_RGB (24 bits RGB image)
		bool	origin = false		//indicate the origin of image, false: top-left, true: bottom-left (windows bitmap style)
		)=0;

	//Set/Get HEART Config
	virtual int SetConfig(const MobiHEARTConfig &config)=0;	//configurations
	virtual void GetConfig(MobiHEARTConfig &config)=0;

	//Set/get BT config
	virtual int SetBTConfig(const MobiBTConfig &configBT)=0;
	virtual void GetBTConfig(MobiBTConfig &configBT)=0;

	//Set/get GR config
	virtual int SetGRConfig(const MobiGRConfig &configGR)=0;
	virtual void GetGRConfig(MobiGRConfig &configGR)=0;

	//GR: mode names and gesture names
	virtual int GetGRModes(MobiGestureMode* &modes)=0;
	virtual char* GetGRModeName(MobiGestureMode mode)=0;
	virtual int GetGRGestures(MobiGestureEvent* &events)=0;
	virtual char* GetGRGestureName(MobiGestureEvent gesEvent)=0;

	//Enable legs tracking
	virtual void EnableLegs(bool bLegs)=0;

	//Enable fingers tracking
	virtual void EnableFingers(bool bFinger)=0;

	//Process one video frame
	virtual int ProcessFrame(
		const void* bitmapPtr,		//pointer of input image data buffer
		int			bufferSize,		//size of input image data buffer
		int &		numBody,		//number of detected/tracked human body
		MobiBody*	arrBody,		//array of tracked human body
		MobiGesture	*arrGesture		//array of gesture corresponding to tracked body
		)=0;

	//get silhouette image
	virtual int GetSilhouette(
		void* pBuffer,				//pointer of buffer to get silhouette image data
		int buffersize,				//size of buffer  = widthstep*height
		int width,					//image width of buffer
		int height,					//image height of buffer
		int widthstep				//image widthstep of buffer 
		)=0;
};

MOBIAPI IMobiHEART* CreateMobiHEART();			// create IMobiHEART instance, should be called first
MOBIAPI void ReleaseMobiHEART(IMobiHEART** p);	// release IMobiHEART instance
