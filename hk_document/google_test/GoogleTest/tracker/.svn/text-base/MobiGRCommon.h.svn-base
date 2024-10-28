/* Copyright (c) 2010 Mobinex Inc. All right reserved. */


#pragma once


enum MobiGestureMode
{
	//Status mode
	GR_STATUS,
	//mouse mode
	GR_MOUSE,
	//move mode
	GR_MOTION,

	//NO USE, Just for basic mode and extend mode separate
	GR_SEPARATE,

	//Other mode undefined, call extend gesture function
	//besides motion, add motion shift, far/close
	GR_MOTION_EXT_1,
	//besides motion, add left lower/higher right
	GR_MOTION_EXT_2,
	//besides motion, add handsMovingFront/LeftLiftShift
	GR_MOTION_EXT_3,

	//combination mode	
	//combine mouse and motion
	GR_COMBINE,
	//combine mouse and motion, add left lower/higher right (game moto)
	GR_COMBINE_1,
	//combine mouse and motion, add body left/right, hands moving front, and left lift shift. (game box)
	GR_COMBINE_2,

	//for medial center
	GR_MEDIA_CENTER,

	//for solitaire
	GR_SOLITAIRE,

	//for Google Earth
	GR_GOOGLE_EARTH,

	//for game joystick
	GR_JOY_STICK,

	//for game treasure hunter
	GR_TREASURE_HUNTER
};

enum MobiGestureEvent
{
	gesUndefined = -1,
	gesNeutral,

	//status mode
	/*
	6        |           0            |         3
	_________|________________________|____________     yThresh1
	7        |           1            |         4
	_________|________________________|____________     yThresh2
	8        |           2            |         5

	xThresh1                xThresh2
	*/
	gesL5R7,
	gesL5R1,
	gesL5R6,
	gesL4R8,
	gesL1R8,
	gesL3R8,
	gesL4R7,
	gesL1R7,
	gesL4R1,
	gesL1R1,
	gesL3R7,
	gesL3R1,
	gesL4R6,
	gesL1R6,
	gesL3R6,
	gesL1R2,
	gesL2R1,
	gesL2R6,
	gesL2R7,
	gesL3R2,
	gesL4R2,
	gesL5R2,

	//////////////////////////////////////////////////////////////////////////
	//mouse mode
	gesMouseMove,
	gesMouseClick,
	gesMouseDBClick,
	gesMouseLeftDown,

	//////////////////////////////////////////////////////////////////////////
	//motion mode
	gesLeftLeft,
	gesLeftRight,
	gesRightLeft,
	gesRightRight,
	gesLeftUp,
	gesLeftDown,
	gesRightUp,
	gesRightDown,
	gesBothUp,
	gesBothDown,

	gesBodyLeft,
	gesBodyRight,

	gesHandsFar,
	gesHandsClose,

	gesLeftRightFast,
	gesRightLeftFast,
	gesStopLeftFast,
	gesStopRightFast,

	gesLeftUpShift,
	gesRightUpShift,
	gesHeadTilt,

	//////////////////////////////////////////////////////////////////////////
	//extend & combine modes
	gesHandsMovingFront,
	gesLeftLiftShift,
	gesRightLiftShift,
	gesHandsMovingBodyLeft,
	gesHandsMovingBodyRight,
	gesLeftLiftShiftBodyLeft,
	gesLeftLiftShiftBodyRight,
	gesRightLiftShiftBodyLeft,
	gesRightLiftShiftBodyRight,

	gesLeftHigherRightMiddle,
	gesLeftLowerRightMiddle,
	gesLeftEqualRightMiddle,
	gesLeftHigherRightBottom,
	gesLeftLowerRightBottom,

	//for media center
	gesRightHold,
	gesBothUpChest,

	//for solitaire
	gesRightMiddle,
	gesLeftUpRightActive,
	gesLeftUpRightNotActive,

	//for google earth
	gesLeftTilt,
	gesRightTilt,

	//for game treasure hunter	
	gesHandsMovingFrontStop,
	gesCrouch,
	gesCrouchUp,
	gesBodyHold
};

typedef struct _MobiPoint
{
	float x;
	float y;
} MobiPoint;

//gesture recognition result
typedef struct _MobiGesture
{
	int gestureCode;
	union
	{
		float fAngle;
		MobiPoint fPoint;
	}data;
} MobiGesture;

//configuration struct
typedef struct _MobiGRConfig
{	
	MobiGestureMode modeGR;					//mode of Gesture recognition
} MobiGRConfig;

