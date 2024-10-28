/* Copyright (c) 2009 Mobinex Inc. All right reserved. */

#pragma once

#include "MobiCommon.h"


//struct five fingertips for one hand
typedef struct _MobiFingers
{
	double		palmSize;		//palm size of diameter
	MobiNode	tipThumb;		//thumb fingertip
	MobiNode	tipIndex;		//index fingertip
	MobiNode	tipMiddle;		//middle fingertip
	MobiNode	tipRing;		//ring fingertip
	MobiNode	tipLittle;		//little fingertip
	MobiNode	rootThumb;		//thumb root
	MobiNode	rootIndex;		//index root
	MobiNode	rootMiddle;		//middle root
	MobiNode	rootRing;		//ring root
	MobiNode	rootLittle;		//little root
} MobiFingers;

//hand struct
typedef struct _MobiHand
{
	MobiFingers	fingers;		//fingertips position
	MobiNode	node;			//hand position
	MobiRect 	rect;			//hand rect, reserved for future use
	int			state;			//hand state, reserved for future use
} MobiHand;

//body struct
typedef struct _MobiBody
{
	int			skeletalUnit;	//unit for skeletal body
	MobiNode 	face;			//face position
	MobiNode	nodeTorso;		//torso node for cursor window mapping
	MobiHand	handL;			//left hand
	MobiHand	handR;			//right hand
	MobiNode	nodeElbowL;		//left elbow
	MobiNode	nodeElbowR;		//right elbow
	MobiNode	nodeShoulderL;	//left shoulder
	MobiNode	nodeShoulderR;	//right shoulder
	MobiNode	nodeNeck;		//neck
	MobiNode	nodeUpBody;		//joint UB
	MobiNode	nodeRoot;		//upper body root
	MobiNode	nodeHipL;		//left node of hip joint
	MobiNode	nodeHipR;		//right node of hip joint
	MobiNode	nodeKneeL;		//left node of knee
	MobiNode	nodeKneeR;		//right node of knee
	MobiNode	nodeFootL;		//left node of foot
	MobiNode	nodeFootR;		//right node of foot
} MobiBody;


//BT configuration struct
typedef struct _MobiBTConfig
{
	int	maxNum;					//max number of detected body
	int modeBT;					//mode of body tracking
} MobiBTConfig;

