

#pragma once

#include "IMobiBT.h"

//Hand Moving Events
//mode:
#define HAND_MODE_CONTROL	100
#define HAND_MODE_VIEW		200
#define HAND_MODE_GAME_CAR	300
#define HAND_MODE_GAME_BOXING	400
#define HAND_MODE_GAME_DANCE	500
#define HAND_MODE_GAME_SKEE 600

#define EVENT_HAND_SCREEN_MOVE 700
#define EVENT_HAND_SCREEN_CLICK 800

//HAND_MODE_CONTROL events
#define EVENT_UNDEFINED		-1
#define EVENT_LEFT_LEFT		0
#define EVENT_LEFT_RIGHT	1
#define EVENT_RIGHT_LEFT	2
#define EVENT_RIGHT_RIGHT	3
#define EVENT_LEFT_UP		4
#define EVENT_LEFT_DOWN		5
#define EVENT_RIGHT_UP		6
#define EVENT_RIGHT_DOWN	7
#define EVENT_BOTH_UP		8
#define EVENT_BOTH_DOWN		9
#define EVENT_HANDS_FAR		10
#define EVENT_HANDS_CLOSE	11

#define EVENT_LEFT_LEFT_FAST 12//not used
#define EVENT_LEFT_RIGHT_FAST 13
#define EVENT_RIGHT_LEFT_FAST 14
#define EVENT_RIGHT_RIGHT_FAST 15//not used

#define EVENT_FAST_STOP_LEFT 16
#define EVENT_FAST_STOP_RIGHT 17

#define EVENT_HEAD_TILT 18

#define EVENT_LEFT_UP_SHIFT 19
#define EVENT_RIGHT_UP_SHIFT 20

//HAND_MODE_VIEW events
//#define EVENTS_VIEW_LEFT	201
//#define EVENTS_VIEW_RIGHT	202
//#define EVENTS_VIEW_UP		203
//#define EVENTS_VIEW_DOWN	204
//#define EVENTS_VIEW_ZOOM_IN	205
//#define EVENTS_VIEW_ZOOM_OUT	206
//#define EVENTS_VIEW_HOME	207
//#define EVENTS_VIEW_END		208

//HAND_MODE_GAME_CAR events
#define EVENTS_CAR_JUST_LEFT	301
#define EVENTS_CAR_JUST_RIGHT 302
#define EVENTS_CAR_JUST_SPEED 303
#define EVENTS_CAR_JUST_BRAKE 304
#define EVENTS_CAR_SPEED_LEFT 305
#define EVENTS_CAR_SPEED_RIGHT 306
#define EVENTS_CAR_BRAKE_LEFT 307
#define EVENTS_CAR_BRAKE_RIGHT 308

//HAND_MODE_GAME_BOXING events
#define EVENTS_BOX_LEFT	401
#define EVENTS_BOX_RIGHT 402
#define EVENTS_BOX_PUNCH	403
#define EVENTS_BOX_BLOCK 404
#define EVENTS_PUNCH_LEFT 405
#define EVENTS_PUNCH_RIGHT 406
#define EVENTS_BLOCK_LEFT 407
#define EVENTS_BLOCK_RIGHT 408

//HAND_MODE_GAME_DANCE events
#define EVENTS_DANCE_LEFT	501
#define EVENTS_DANCE_RIGHT	502
#define EVENTS_DANCE_UP		503
#define EVENTS_DANCE_DOWN	504
#define EVENTS_DANCE_LEFT_UP 505
#define EVENTS_DANCE_LEFT_DOWN 506
#define EVENTS_DANCE_RIGHT_UP 507
#define EVENTS_DANCE_RIGHT_DOWN	508
#define EVENTS_DANCE_LEFT_RIGHT	509
#define EVENTS_DANCE_UP_DOWN	510
#define EVENTS_DANCE_STOP		511

//HAND MODE_GAME_SKEE events
#define EVENTS_SKEE_LEFT	601
#define EVENTS_SKEE_RIGHT	602

struct HAND_POSITION_PT
{
	int leftX; int leftY;
	int rightX; int rightY;
	HAND_POSITION_PT* next;
};

#define GESTURE_RECORD_POSITION 4


class CGesture
{
public:
	CGesture();
	~CGesture();

public:
	int recordTrajectory(int leftX, int leftY, int rightX, int rightY);
	int anasysTragectory(int flag);
	int handMovingEvents(int leftD, int rightD, int mode);

	//for game
	int SetTorsoBasePosition(int x);

	void GetScreenXY(float &dx, float &dy){dx = m_xScreen; dy = m_yScreen;}

	void GetTiltAngle(float &angle){angle = m_rotateAngle;}

private:
	int handMovingEventsControl(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	int handOneEvents(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int flag, int hDir);
	int handBothEvents(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int hDir);
	void RecordMovingPara(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int flag, int hDir);

	//for game	
	int checkBothHandsUp(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	//for boxing
	int handMovingEventsBoxing(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	//for motocycle
	int handMovingEventsMoto(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	//for dancing
	int handMovingEventsDance(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	//for game skee
	int handMovingEventsSkee(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	//for photo viewing
	int handMovingEventsView(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD);

	int someHandsMoving(HAND_POSITION_PT* first, HAND_POSITION_PT* last);
	int isHandMoving(int flag);

	//for headMoving position when boxing
	int GetHeadMovingMapping();

	//for mapping mouse click when select flash game menu
	int handScreenMapping();
	int handScreenMappingNew();
	int handScreenOperation();
	int handScreenOperationNew();

	int isHandMovingFast(int flag, int dir);

private:
	int leftBaseX, leftBaseY, rightBaseX, rightBaseY;
	int leftTopX, leftTopY, rightTopX, rightTopY;
	int leftFirstMoving, rightFirstMoving;
	
	int lastLeftDir, lastRightDir;
	int justHitLeft, justHitRight, justHitBoth, justHitZoom;
	int m_justHitLeftFast, m_justHitRightFast;
	int frame_count;
	int lastLostFrame, lastBeginFrame;
	int noStatusNum;

	HAND_POSITION_PT* first, *last;

	//hand screen mapping	
	float m_xScreen, m_yScreen;
	float m_xScreenLast, m_yScreenLast;
	int m_numScreen;

	double m_xTorsoScreen, m_yTorsoScreen;
	double m_suTorsoHalf, m_yUpDownTh;
	float m_xminScreen, m_xmaxScreen, m_yminScreen, m_ymaxScreen;
	float m_widthMapScreen, m_heightMapScreen;
	bool m_bScreenInit;
	//new strategy for screen mapping
	int m_xLastForMouse0, m_yLastForMouse0;
	int m_xLastForMouse1, m_yLastForMouse1;
	int m_xLastForMouse2, m_yLastForMouse2;
	float m_MotionUnit;

	int m_bLeftFast, m_bRightFast;

	int m_bHeadTurnLeft, m_bHeadTurnRight;
	float m_rotateAngle, m_rotateAngleLast;

public:
	int yTorso;
	int suTorso;

	//for game
	int xTorso;
	int xTorsoBase;

	//screen mapping
	MobiBody m_body;

	int m_bHandMoveFast;
};