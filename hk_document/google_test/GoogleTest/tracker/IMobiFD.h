//
// IMobiFD.h
// $Id: IMobiFD.h 14798 2009-04-23 07:38:57Z raphael.ko $
// Copyright (c) 2009 Mobinex Inc. All right reserved.
//

#ifndef _IMOBIFD_H_
#define _IMOBIFD_H_

#include "MobiCommon.h"

//FD (Face Detection) configuration struct
typedef struct Mobi_FD_Config
{
	int maxNumFace;			//max number of faces to be detected, range: 1 - 64
	int minEyeDistance;		//min eye distance (in pixels) of face when detecting, >=20
	int maxEyeDistance;		//max eye distance (in pixels) of face when detecting, 0 means largest detectable
	float confidenceT;		//the confidence threshold to judge if a true face detected, range 0.0 - 1.0
} FDConfig;

//Interface class for FD
class IMobiFD
{
public:
	// Initialize fd
	virtual int Initialize( void )=0;

	//Set Image Format
	virtual int SetImgFormat(
		int widthStep,		//width step of image data in bytes, default: 320*3
		int height,			//image height, default: 240
		int width,			//image width, default: 320
		int colorMode,		//image color mode, default: MOBI_CM_RGB (24 bits RGB image)
		bool origin=0		//indicate the origin of image, 0: top-left, 1: bottom-left (windows bitmap style)
		)=0;

	//Set/Get FD Config
	virtual int SetConfig(const FDConfig &config)=0;	//fd configurations
	virtual void GetConfig(FDConfig &config)=0;
	
	//detect face(s)
	virtual int Detect(
		const void* bitmapPtr,		//input image data buffer
		int bufferSize,				//size of image data buffer in bytes
		MobiFace* faceData,			//pointer to array of MobiFace to receive detected face data, 
									//array size should be maxNumFace in the fd configuration
		int &numOfFaces, 			//variable receive the detected face number
		const int rotation=0,		//optional rotation angle for detection, should be 0, 90, 180, or 270
		const MobiRect *roi=0,		//optional rect selected for face search
		const char* sLicense = 0	//the license key
		)=0;
};

MOBIAPI IMobiFD* CreateMobiFD();			// create IMobiFD instance, should be called firstly
MOBIAPI void ReleaseMobiFD(IMobiFD** p);	// release IMobiFD instance

#endif // _IMOBIFD_H_
