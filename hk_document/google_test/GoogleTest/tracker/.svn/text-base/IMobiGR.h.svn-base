/* Copyright (c) 2009 Mobinex Inc. All right reserved. */

#ifndef _IMOBI_GR_H_
#define _IMOBI_GR_H_


#include "MobiBTCommon.h"
#include "MobiGRCommon.h"


//Interface class for Gesture Recognition
class IMobiGR
{
public:
	//Initialize GR
	virtual int Initialize(const char* sLicense)=0;	//license key 

	//Set/Get GR Config
	virtual int SetConfig(const MobiGRConfig &config)=0;	//configurations
	virtual void GetConfig(MobiGRConfig &config)=0;

	virtual int GetAllModes(MobiGestureMode* &modes)=0;
	virtual char* GetModeName(MobiGestureMode mode)=0;

	virtual int GetAllGestures(MobiGestureEvent* &event)=0;
	virtual char* GetGestureName(MobiGestureEvent gesEvent)=0;

	//Process frame
	virtual int RecogGesture(		
		const MobiBody &body,		//input human body information
		MobiGesture &gesture		//output gesture result
		)=0;	
};

MOBIAPI IMobiGR* CreateMobiGR();			// create IMobiGR instance, should be called firstly
MOBIAPI void ReleaseMobiGR(IMobiGR** p);	// release IMobiGR instance


#endif