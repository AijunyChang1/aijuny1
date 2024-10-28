/* Copyright (c) 2009 Mobinex Inc. All right reserved. */

#ifndef _IMOBIHT_H_
#define _IMOBIHT_H_

#include "MobiBTCommon.h"

//hand states
#define MOBI_PALM_OPEN		1
#define MOBI_PALM_CLOSE		0
#define MOBI_PALM_UNKNOWN	-1

struct mobiPointf2D 
{
	float x;		//x motion: [-1, 1]
	float y;		//y motion: [-1, 1]
};

//mouse gesture struct
struct MobiGesPalm 
{
	int gesEvent;		//gesture event
	mobiPointf2D p;
};

enum MobiGesMode
{
	PALM_GR_NONE = -1,		//not defined
	PALM_GR_A,
	PALM_GR_WA,
	PALM_GR_MOUSE,
	PALM_GR_BOXING
};

enum MobiGesEvent
{
	palmGesUndefined = -1,	//undefined gestures
	
	//MODE A
	palmGesBothShow,		//both showing, and almost still
	palmGesLeftShow,		//only left hand showing
	palmGesLShowRLeft,		//left showing, right hand move to left
	palmGesLShowRRight,		//left showing, right hand move to right

	palmGesRShowLLeft,
	palmGesRShowLRight,
	
	//MODE WA
	palmGesRLeft,			//left not show, right hand move to left
	palmGesRRight,			//left not show, right hand move to right

	palmGesLLeft,
	palmGesLRight,

	//MODE MOUSE
	palmGesMoving,			//launch mouse mode with right hand fist
	palmGesLeftDown,		//left button down status for drag
	palmGesDbClick,			//open palm to launch

	//MODE BOXING
	palmGesBoxSelect,		//select button
	palmGesBoxRLeft,		//right hand moving to left
	palmGesBoxRRight,		//right hand moving to right
	palmGesBoxPaunch,		//paunch for boxing game
	palmGesBoxBlock,		//block for boxing game
	palmGesBoxQuit			//quit game
};

//Interface class for HT
class IMobiHT
{
public:
	// Initialize fd
	virtual int Initialize( 
		const char* sLicense )=0;	//license key

	//Set Image Format
	virtual int SetImgFormat(
		int widthStep,		//width step of image data in bytes, default: 320*3
		int height,			//image height, default: 240
		int width,			//image width, default: 320
		int colorMode,		//image color mode, default: MOBI_CM_RGB (24 bits RGB image)
		bool origin=false	//indicate the origin of image, 0: top-left, 1: bottom-left (windows bitmap style)
		)=0;

	//detect hands
	virtual int Detect(
		const void* bitmapPtr,		//input image data buffer
		int bufferSize,				//size of image data buffer in bytes
		MobiFace &face,				//pointer to MobiFace data
		MobiHand &handLeft,
		MobiHand &handRight,
		bool bAdapt = false			//flag to reproduce the adaptive skin model based on face region
		)=0;

	//output gestures
	virtual int GetGestures(
		int &mode,					//mode for gestures
		MobiGesPalm &gesPalm		//palm gesture information
		)=0;
};

MOBIAPI IMobiHT* CreateMobiHT();			// create IMobiHT instance, should be called firstly
MOBIAPI void ReleaseMobiHT(IMobiHT** p);	// release IMobiHT instance

#endif // _IMOBIHT_H_
