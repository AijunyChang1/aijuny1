#include "StdAfx.h"//for outputdebug string
#include "gesture.h"

#include "math.h"


#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

//#define HAND_FAST_MOTION

CGesture::CGesture()
: m_numScreen(0)
, m_xScreen (0.5f)
, m_yScreen (0.5f)
, m_xScreenLast(0.0f)
, m_yScreenLast(0.0f)
, m_bScreenInit(false)
{
	leftBaseX=0, leftBaseY=0, rightBaseX=0, rightBaseY=0;
	leftTopX=0, leftTopY=0, rightTopX=0, rightTopY=0;
	leftFirstMoving=0, rightFirstMoving=0;
	yTorso = 0;
	suTorso = 0;
	lastLeftDir = -1, lastRightDir = -1;
	justHitLeft = 0, justHitRight = 0, justHitBoth = 0, justHitZoom = 0;
	m_justHitLeftFast = 0;
	m_justHitRightFast = 0;
	frame_count = 0;
	lastLostFrame = -1, lastBeginFrame = -1;
	noStatusNum = 0;

	//for game
	xTorso = 0;
	xTorsoBase = 0;//when enter the game, the body position

	first = 0;
	last = 0;

	m_bHandMoveFast = 0;

	m_bLeftFast = 0;
	m_bRightFast = 0;

	m_bHeadTurnLeft = 0;
	m_bHeadTurnRight = 0;
	m_rotateAngle = 0;
	m_rotateAngleLast = 0;
}

CGesture::~CGesture()
{
	if(first)
	{
		for(last=first; last!=NULL; )
		{
			HAND_POSITION_PT* temp = last;
			last = last->next;
			temp->next = NULL;
			delete temp;
			temp = last;
		}
		first = NULL;
		last = NULL;
	}
}

//int CGesture::Reset()
//{
//	leftBaseX=0, leftBaseY=0, rightBaseX=0, rightBaseY=0;
//	leftTopX=0, leftTopY=0, rightTopX=0, rightTopY=0;
//	leftFirstMoving=0, rightFirstMoving=0;
//	yTorso = 0;
//	suTorso = 0;
//	lastLeftDir = -1, lastRightDir = -1;
//	justHitLeft = 0, justHitRight = 0, justHitBoth = 0, justHitZoom = 0;
//	frame_count = 0;
//	lastLostFrame = -1, lastBeginFrame = -1;
//	noStatusNum = 0;
//
//	xTorso = 0;
//	xTorsoBase = 0;//when enter the game, the body position
//}

int CGesture::handMovingEvents(int leftD, int rightD, int mode)
{
	if(!last)
		return -2;

	int ret = -1;
	switch(mode)
	{
	case HAND_MODE_CONTROL:
		return handMovingEventsControl(first, last, leftD, rightD);
		break;
	case HAND_MODE_VIEW:		
		return handMovingEventsView(first, last, leftD, rightD);
		break;
	case HAND_MODE_GAME_CAR:			
		ret = handMovingEventsMoto(first, last, leftD, rightD);	
		if(ret == EVENT_LEFT_UP || ret == EVENT_RIGHT_UP)
		{
			SetTorsoBasePosition(xTorso);
		}
		return ret;
		break;
	case HAND_MODE_GAME_BOXING:		
		//return handMovingEventsBoxing(first, last, leftD, rightD);
		ret = handMovingEventsBoxing(first, last, leftD, rightD);	
		if(ret == EVENT_LEFT_UP || ret == EVENT_RIGHT_UP)
		{
			SetTorsoBasePosition(xTorso);
		}
		return ret;
		break;
	case HAND_MODE_GAME_SKEE:		
		//return handMovingEventsSkee(first, last, leftD, rightD);
		ret = handMovingEventsSkee(first, last, leftD, rightD);	
		if(ret == EVENT_LEFT_UP || ret == EVENT_RIGHT_UP)
		{
			SetTorsoBasePosition(xTorso);
		}
		return ret;
		break;
		//case HAND_MODE_GAME_DANCE:
		//	ret = checkBothHandsUp(first, last, leftD, rightD);
		//	if(ret>0)
		//		return ret;
		//	else
		//		return handMovingEventsDance(first, last, leftD, rightD);
		//	break;
	}

	return EVENT_UNDEFINED;
}

int CGesture::recordTrajectory(int leftX, int leftY, int rightX, int rightY)
{
	//save hand position
	if(frame_count - lastBeginFrame == 1)
	{
		HAND_POSITION_PT *lastPosition = new HAND_POSITION_PT;				
		lastPosition->leftX = leftX;//m_body.handL.node.x;
		lastPosition->leftY = leftY;//m_body.handL.node.y;
		lastPosition->rightX = rightX;//m_body.handR.node.x;
		lastPosition->rightY = rightY;//m_body.handR.node.y;
		lastPosition->next = NULL;

		first = lastPosition;
		last = lastPosition;
	}
	else if(frame_count - lastBeginFrame < GESTURE_RECORD_POSITION+1)//continuous frame
	{
		HAND_POSITION_PT *lastPosition = new HAND_POSITION_PT;
		lastPosition->leftX = leftX;//m_body.handL.node.x;
		lastPosition->leftY = leftY;//m_body.handL.node.y;
		lastPosition->rightX = rightX;// m_body.handR.node.x;
		lastPosition->rightY = rightY;//m_body.handR.node.y;
		lastPosition->next = NULL;

		last->next = lastPosition;
		last = lastPosition;
	}
	else
	{
		HAND_POSITION_PT * temp = first;
		first = first->next;

		temp->leftX = leftX;//m_body.handL.node.x;
		temp->leftY = leftY;//m_body.handL.node.y;
		temp->rightX = rightX;//m_body.handR.node.x;
		temp->rightY = rightY;//m_body.handR.node.y;
		temp->next = NULL;

		last->next = temp;
		last = temp;
	}
	lastLostFrame = frame_count;

	frame_count++;

	//Test recording result
	//sprintf(msg, "%s\n%s", msg1, msg2);
	//FILE* fp = fopen("hand_position.txt", "a");
	//for(HAND_POSITION* temp=first; temp!=NULL; )
	//{
	//	fprintf(fp, "%d %d %d %d\n", temp->leftX, temp->leftY, temp->rightX, temp->rightY);
	//	temp = temp->next;
	//}
	//fprintf(fp, "----------------\n");
	//fclose(fp);

	return 1;
}

int CGesture::anasysTragectory(int flag)
{
	if(!first || !first->next)
		return -1;

	//left hand
	int minX = 9999;
	int maxX = 0;

	int minY = 9999;
	int maxY = 0;

	int Limits50 = int(0.55*suTorso);//int(0.65*suTorso);//int Limits50 = int(0.65*suTorso);//50 when suTorso=76
	//int Limits60 = 0.79*suTorso;
	int Limits20 = int(0.25*suTorso);//20
	int Limits30 = int(0.4*suTorso);
	int Limits10 = int(0.1*suTorso);
	int currX, currY;

	HAND_POSITION_PT* temp = first;
	for(; temp!= NULL;)
	{
		if(flag==0)
		{
			currX = temp->leftX;
			currY = temp->leftY;
		}else{
			currX = temp->rightX;
			currY = temp->rightY;
		}

		if(minX > currX)
		{
			minX = currX;
		}
		if(maxX < currX)
		{
			maxX = currX;
		}

		if(minY > currY)
		{
			minY = currY;
		}
		if(maxY < currY)
		{
			maxY = currY;
		}


		temp = temp->next;
	}

	if(maxY-minY < maxX - minX)
	{
		if((maxX - minX > Limits50) )//maxY-minY < Limits30 && 
		{	
			if(flag==0)
			{
				currX = last->leftX;
			}else{
				currX = last->rightX;
			}
			if(abs(currX-minX) > abs(currX-maxX))
			{
				return 1;//x move right
			}else{
				return 2;
			}
			//if((currX - minX)>0)
			//{		

			//	return 1;//x move right
			//}else{

			//	return 2;//x move left
			//}
		}
	}else
	{

		if((maxY - minY > Limits50) )//maxX - minX < Limits30 && 
		{	
			if(flag==0)
			{
				currY = last->leftY;
			}else{
				currY = last->rightY;
			}

			if(abs(currY-minY) > abs(currY-maxY))
			{
				return 3;//y move down
			}else{
				return 4;//y move up
			}
			//if((currY - minY)>0)
			//{			

			//	return 3;//y move down
			//}else{

			//	return 4;//y move up
			//}
		}
	}

	return -1;
}

void CGesture::RecordMovingPara(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int flag, int hDir)
{	

	//////////////////////////////////////////////////////////////////////////
	//left hand
	int minX = 9999;
	int maxX = 0;

	int minY = 9999;
	int maxY = 0;

	int currX, currY;

	HAND_POSITION_PT* temp = first;
	for(; temp!= NULL;)
	{
		if(flag==0)
		{
			currX = temp->leftX;
			currY = temp->leftY;
		}else{
			currX = temp->rightX;
			currY = temp->rightY;
		}

		if(minX > currX)
		{
			minX = currX;
		}
		if(maxX < currX)
		{
			maxX = currX;
		}

		if(minY > currY)
		{
			minY = currY;
		}
		if(maxY < currY)
		{
			maxY = currY;
		}


		temp = temp->next;
	}

	if(hDir==1)
	{
		if(flag==0)
		{
			if(leftFirstMoving==0)
			{
				leftBaseX = minX;
				leftBaseY = currY;

				leftTopX = maxX;
				leftTopY = currY;
			}
			leftFirstMoving++;
		}
		else
		{
			if(rightFirstMoving==0)
			{
				rightBaseX = minX;
				rightBaseY = currY;

				rightTopX = maxX;
				rightTopY = currY;
			}
			rightFirstMoving++;
		}
	}

	if(hDir==2)
	{
		if(flag==0)
		{
			if(leftFirstMoving==0)
			{
				leftBaseX = maxX;
				leftBaseY = currY;

				leftTopX = minX;
				leftTopY = currY;
			}
			leftFirstMoving++;
		}
		else
		{
			if(rightFirstMoving==0)
			{
				rightBaseX = maxX;
				rightBaseY = currY;

				rightTopX = minX;
				rightTopY = currY;
			}
			rightFirstMoving++;
		}
	}

	if(hDir==3)
	{
		if(flag==0)
		{
			if(leftFirstMoving==0)
			{
				leftBaseX = currX;
				leftBaseY = minY;

				leftTopX = currX;
				leftTopY = maxY;
			}
			leftFirstMoving++;
		}
		else
		{
			if(rightFirstMoving==0)
			{
				rightBaseX = currX;
				rightBaseY = minY;

				rightTopX = currX;
				rightTopY = maxY;
			}
			rightFirstMoving++;
		}
	}

	if(hDir==4)
	{
		if(flag==0)
		{
			if(leftFirstMoving==0)
			{
				leftBaseX = currX;
				leftBaseY = maxY;

				leftTopX = currX;
				leftTopY = minY;
			}
			leftFirstMoving++;
		}
		else
		{
			if(rightFirstMoving==0)
			{
				rightBaseX = currX;
				rightBaseY = maxY;

				rightTopX = currX;
				rightTopY = minY;
			}
			rightFirstMoving++;
		}
	}	
}

int CGesture::handMovingEventsControl(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
#if 0
	int ret0 = leftD;
	int ret1 = rightD;

	if(ret0>0)
		RecordMovingPara(first, last, 0, ret0);
	if(ret1>0)
		RecordMovingPara(first, last, 1, ret1);

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int diffY = abs(yR - yL)*1.8;
	int yLimits = yTorso + suTorso*0.5;	
	int xTorsoLimits = suTorso*0.5;
	//int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*0.2;

	if(ret0 >0 || ret1 >0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits))
	{	
		if( (lastLeftDir == 3 && lastRightDir == 3) ||
			(lastLeftDir == 4 && lastRightDir == 4) ||
			((lastLeftDir == 3 || lastLeftDir == 4) && diffY < suTorso && last->leftY<yLimits) ||
			((lastRightDir == 3 || lastRightDir == 4) && diffY < suTorso && last->rightY<yLimits) ||
			(ret0==-1 && (ret1==3 || ret1==4) && (lastLeftDir==ret1) && diffY < suTorso) ||
			(ret1==-1 && (ret0==3 || ret0==4) && (lastRightDir==ret0) && diffY < suTorso) ||
			(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
		{
			if((ret0>0 && lastLeftDir>0 && lastLeftDir!=ret0) || 
				(ret1>0 && lastRightDir>0 && lastRightDir!=ret1) ||
				(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
			{
				justHitBoth = 0;					
			}
			if(ret0<0 && diffY < suTorso) ret0 = ret1;
			if(ret1<0 && diffY < suTorso) ret1 = ret0;
			lastLeftDir = ret0;
			lastRightDir = ret1;
		}		
		else
		{
			if(lastLeftDir != ret0)
			{
				if(lastLeftDir!=-1 || (lastLeftDir=-1 && ret0 >1) || (yL<yTorso-xTorsoLimits && ret0<0))
				{
					justHitLeft = 0;
					leftFirstMoving = 0;
				}
				lastLeftDir = ret0;
			}
			if(lastRightDir != ret1)
			{
				if(lastRightDir!=-1 || (lastRightDir=-1 && ret1 >1) || (yR<yTorso-xTorsoLimits && ret1<0))
				{
					justHitRight = 0;
					rightFirstMoving = 0;
				}
				lastRightDir = ret1;
			}
		}

		if(ret0 >0 || ret1 >0)
			noStatusNum = 0;
	}

	//BOTH hands up
	if( (leftD == 3 && rightD == 3) ||
		(leftD == 4 && rightD == 4) ||
		((leftD == 3 || leftD == 4) && diffY < suTorso && last->leftY<yLimits) ||
		((rightD == 3 || rightD == 4) && diffY < suTorso && last->rightY<yLimits) ||
		(last->leftY < yTorso - xTorsoLimits && last->rightY < yTorso - xTorsoLimits))
	{
		int dBoth = handBothEvents(first, last, leftD);
		if(dBoth>0 && !justHitBoth)
		{
			justHitBoth = 1;
			return dBoth;
		}
	}

	//operation
	//one hand control
	int dX = -1, dY = -1;
	if(leftD>0)
	{			
		dX = handOneEvents(first, last, 0, leftD);
	}
	if(rightD>0)
	{
		dY = handOneEvents(first, last, 1, rightD);
	}

	if(dX >= 0 && !justHitLeft)
	{
		justHitLeft = 1;
		return dX;
	}

	if(dY >= 0 && !justHitRight)
	{
		justHitRight = 1;
		return dY;
	}	

	if(ret0<0 && ret1<0)
	{
		if(noStatusNum>30)
		{
			lastLeftDir = ret0;
			lastRightDir = ret1;
			justHitLeft = 0;
			justHitRight = 0;
			justHitBoth = 0;
			justHitZoom = 0;
			leftFirstMoving = 0;
			rightFirstMoving = 0;

			noStatusNum = -1;
		}
		noStatusNum++;

	}

	return EVENT_UNDEFINED;
#else
	int ret0 = leftD;
	int ret1 = rightD;

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;
	int xTorsoLimits = suTorso*0.5;

	//int y1 = m_body.nodeShoulderL.y;
	//int y2 = m_body.nodeShoulderR.y;

	int xTorsoCenter = m_body.nodeTorso.x;//(m_body.nodeShoulderL.x + m_body.nodeShoulderR.x)/2;//	m_body.nodeNeck.x;//			
	int xFace = m_body.face.x;	
	static int xFaceLast = xFace;
	float faceMoveThre = suTorso*0.4;
	float faceNeckThre = suTorso*0.35;
	//float shoulderDiffThre = suTorso*0.6;

	if(ret0> 0 || ret1 > 0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits) ||
		abs(xFace - xFaceLast)>faceMoveThre || abs(xFace - xTorsoCenter) > faceNeckThre)// || abs(y2 - y1) > shoulderDiffThre
	{
		if(ret0> 0 || ret1 > 0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits))
		{		
			int diffY = abs(last->leftY - last->rightY)*1.8;
			int yLimits = yTorso + suTorso*0.5;

			if( (lastLeftDir == 3 && lastRightDir == 3) ||
				(lastLeftDir == 4 && lastRightDir == 4) ||
				((lastLeftDir == 3 || lastLeftDir == 4) && diffY < suTorso && last->leftY<yLimits) ||
				((lastRightDir == 3 || lastRightDir == 4) && diffY < suTorso && last->rightY<yLimits) ||
				(ret0==-1 && (ret1==3 || ret1==4) && (lastLeftDir==ret1) && diffY < suTorso) ||
				(ret1==-1 && (ret0==3 || ret0==4) && (lastRightDir==ret0) && diffY < suTorso) ||
				(last->leftY < yTorso - xTorsoLimits && last->rightY < yTorso - xTorsoLimits))
			{
				if( (ret0>0 && lastLeftDir>0 && lastLeftDir!=ret0) || 
					(ret1>0 && lastRightDir>0 && lastRightDir!=ret1) ||
					(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
				{
					justHitBoth = 0;					
				}
				if(ret0<0 && diffY < suTorso) ret0 = ret1;
				if(ret1<0 && diffY < suTorso) ret1 = ret0;
				lastLeftDir = ret0;
				lastRightDir = ret1;
			}		
			else
			{
				if(lastLeftDir != ret0)
				{
					if(lastLeftDir!=-1 || (lastLeftDir=-1 && ret0 >1) || (yL<yTorso-xTorsoLimits && ret0<0))
					{
						justHitLeft = 0;
						leftFirstMoving = 0;

						//m_bLeftFast = 0;
						m_justHitLeftFast = 0;
					}
					lastLeftDir = ret0;
				}
				if(lastRightDir != ret1)
				{
					if(lastRightDir!=-1 || (lastRightDir=-1 && ret1 >1) || (yR<yTorso-xTorsoLimits && ret1<0))
					{
						justHitRight = 0;
						rightFirstMoving = 0;

						//m_bRightFast =0;
						m_justHitRightFast =0;
					}
					lastRightDir = ret1;
				}
			}
			if(ret0>0)
				RecordMovingPara(first, last, 0, ret0);
			if(ret1>0)
				RecordMovingPara(first, last, 1, ret1);

			if(ret0 >0 || ret1 >0)
				noStatusNum = 0;

			//int et = handMovingEvents(first, last, ret0, ret1, mode);//m_suTorso

			//int diffY = int(abs(last->leftY - last->rightY)*1.8);
			//int yLimits = yTorso + suTorso*0.5;

			if( (leftD == 3 && rightD == 3) ||
				(leftD == 4 && rightD == 4) ||
				((leftD == 3 || leftD == 4) && diffY < suTorso && last->leftY<yLimits) ||
				((rightD == 3 || rightD == 4) && diffY < suTorso && last->rightY<yLimits) ||
				(last->leftY < yTorso - xTorsoLimits && last->rightY < yTorso - xTorsoLimits))
			{
				int dBoth = handBothEvents(first, last, leftD);
				if(dBoth>0 && !justHitBoth)
				{
					justHitBoth = 1;
					return dBoth;
				}
			}		
			else
			{
				int dX = -1, dY = -1;
				if(leftD>0)
				{			
					dX = handOneEvents(first, last, 0, leftD);
				}

	#ifdef HAND_FAST_MOTION
				if(dX>=0 && m_bHandMoveFast && !m_justHitLeftFast)
				{
					justHitLeft = 1;
					m_justHitLeftFast = 1;
					m_bLeftFast = 1;
					m_bRightFast = 0;
					return EVENT_LEFT_RIGHT_FAST;
				}
	#endif

				if(rightD>0)
				{
					dY = handOneEvents(first, last, 1, rightD);
				}

	#ifdef HAND_FAST_MOTION
				if(dY>=0 && m_bHandMoveFast && !m_justHitRightFast)
				{
					justHitRight = 1;
					m_bRightFast = 1;
					m_bLeftFast = 0;
					m_justHitRightFast =1;
					return EVENT_RIGHT_LEFT_FAST;
				}

				if(m_bLeftFast>0)
				{
					static int rightStop = 0;
					if(last->rightY<yTorso+suTorso*1.2)
					{
						rightStop ++;					
					}
					if(rightStop > 3)
					{
						rightStop = 0;
						m_bLeftFast = 0;

						return EVENT_FAST_STOP_LEFT;
					}
					//return EVENT_UNDEFINED;
				}

				if(m_bRightFast>0)
				{
					static int leftStop = 0;
					if(last->leftY<yTorso+suTorso*1.2)
					{
						leftStop ++;					
					}
					if(leftStop > 3)
					{
						leftStop = 0;
						m_bRightFast = 0;

						return EVENT_FAST_STOP_RIGHT;
					}
					//return EVENT_UNDEFINED;
				}
	#endif

				if(dX >= 0 && !justHitLeft)	
				{
					justHitLeft = 1;
					return dX;
				}

				if(dY >= 0 && !justHitRight)
				{
					justHitRight = 1;			
					return dY;
				}
			}
		}
		else
		{

			if(noStatusNum>30)
			{
				lastLeftDir = ret0;
				lastRightDir = ret1;
				justHitLeft = 0;
				justHitRight = 0;
				justHitBoth = 0;
				justHitZoom = 0;
				leftFirstMoving = 0;
				rightFirstMoving = 0;

				//m_bLeftFast =0;
				//m_bRightFast =0;
				m_justHitLeftFast = 0;
				m_justHitRightFast = 0;

				noStatusNum = -1;
			}
			noStatusNum++;

		}

		//------ for tilt event -----//
		if(abs(xFace - xFaceLast)>faceMoveThre || abs(xFace - xTorsoCenter) > faceNeckThre)// || abs(y2 - y1) > shoulderDiffThre
		{
			float angleRotate = 0.0f;

			//if(abs(y2 - y1) > shoulderDiffThre)
			//{
			//	//angleRotate = atan2((float)(y2 - y1), (float)suTorso);
			//	angleRotate = atan2((float)(xFace-xTorsoCenter),(float)suTorso);

			//	//CStringA buf;
			//	//buf.Format("y2>y1, angle is %f", angleRotate);
			//	//OutputDebugStringA(buf);

			//}
			//else 
			if(abs(xFace - xTorsoCenter) > faceNeckThre)
			{
				angleRotate = atan2((float)(xFace-xTorsoCenter),(float)suTorso);

				//CStringA buf;
				//buf.Format("xFace>xTorsoCenter, angle is %f", angleRotate);
				//OutputDebugStringA(buf);
			}else		
				//if(abs(xFace - xFaceLast)>suTorso*0.02)
			{
				//angleRotate = atan2((float)(xFace-xFaceLast),(float)suTorso)/2.5;

				angleRotate = atan2((float)(xFace-xTorsoCenter),(float)suTorso)*1.2;

				//CStringA buf;
				//buf.Format("xFace>xFaceLast, angle is %f", angleRotate);
				//OutputDebugStringA(buf);
			}

			xFaceLast = xFace;

			//if(abs(m_rotateAngle - angleRotate)>0.005)	

			//if(abs(angleRotate)<0.09)//about 5 degree
			//{
			//	m_rotateAngle = angleRotate;
			//}else
			//{
			//	m_rotateAngle = angleRotate/1.5;
			//}
			m_rotateAngle = -angleRotate/1.5;

			return EVENT_HEAD_TILT;

		}
	}

	return EVENT_UNDEFINED;
#endif
}

int CGesture::SetTorsoBasePosition(int x)
{
	xTorsoBase = x;

	return 1;
}

int CGesture::handMovingEventsBoxing(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
#if 1
	int ret0 = leftD;
	int ret1 = rightD;

	if(ret0>0)
		RecordMovingPara(first, last, 0, ret0);
	if(ret1>0)
		RecordMovingPara(first, last, 1, ret1);

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int diffY = abs(last->leftY - last->rightY)*1.8;
	int yLimits = yTorso + suTorso*0.5;
	int xTorsoLimits = suTorso*0.5;
	//int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*1.2;

	if(ret0 >0 || ret1 >0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits))
	{	

		//if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
		//	(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
		if( (lastLeftDir == 3 && lastRightDir == 3) ||
			(lastLeftDir == 4 && lastRightDir == 4) ||
			((lastLeftDir == 3 || lastLeftDir == 4) && diffY < suTorso && last->leftY<yLimits) ||
			((lastRightDir == 3 || lastRightDir == 4) && diffY < suTorso && last->rightY<yLimits) ||
			(ret0==-1 && (ret1==3 || ret1==4) && (lastLeftDir==ret1) && diffY < suTorso) ||
			(ret1==-1 && (ret0==3 || ret0==4) && (lastRightDir==ret0) && diffY < suTorso) ||
			(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
		{
			if((ret0>0 && lastLeftDir>0 && lastLeftDir!=ret0) || 
				(ret1>0 && lastRightDir>0 && lastRightDir!=ret1) ||
				(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
			{
				justHitBoth = 0;					
			}
			if(ret0<0 && diffY < suTorso) ret0 = ret1;
			if(ret1<0 && diffY < suTorso) ret1 = ret0;
			lastLeftDir = ret0;
			lastRightDir = ret1;
		}		
		else
		{
			if(lastLeftDir != ret0)
			{
				if(lastLeftDir!=-1 || (lastLeftDir=-1 && ret0 >1) || (yL<yTorso-xTorsoLimits && ret0<0))
				{
					justHitLeft = 0;
					leftFirstMoving = 0;
				}
				lastLeftDir = ret0;
			}
			if(lastRightDir != ret1)
			{
				if(lastRightDir!=-1 || (lastRightDir=-1 && ret1 >1) || (yR<yTorso-xTorsoLimits && ret1<0))
				{
					justHitRight = 0;
					rightFirstMoving = 0;
				}
				lastRightDir = ret1;
			}
		}

		if(ret0 >0 || ret1 >0)
			noStatusNum = 0;
	}

	//BOTH hands up
	int yMostUpLimits = yTorso - 1.5*suTorso;
	if(ret0> 0 || ret1 > 0 || (yL < yMostUpLimits && yR < yMostUpLimits))
	{

		if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
			(yL < yMostUpLimits && yR < yMostUpLimits && (leftD==4 || rightD==4) && diffY < suTorso) &&
			abs(xL - xR)>suTorso*1.5
			)
		{
			return EVENT_BOTH_UP;
		}	
	}

	//mouse event
	int ret = handScreenOperation();
	if(ret>0)
	{
		return ret;
	}

	//operation
	//PUNCH OR BLOCK:
	int width = suTorso*8;
	int chestY = yTorso + suTorso*2;	
	if((yL < chestY && yL > yUp) &&	(yR < chestY && yR > yUp) &&
		someHandsMoving(first, last)
		)
	{
		if(abs(xTorso - xTorsoBase) > xTorsoLimits)
		{
			GetHeadMovingMapping();

			if(xTorso > xTorsoBase)//go to right
			{
				return EVENTS_PUNCH_LEFT;
			}else{
				return EVENTS_PUNCH_RIGHT;
			}

		}else
		{
			return EVENTS_BOX_PUNCH;
		}
	}
	if(yL<yTorso && xL > xTorso+suTorso
		&& yR<chestY && yR>yUp && xR>xTorso-width && xR<xTorso+width)
	{

		if(abs(xTorso - xTorsoBase) > xTorsoLimits)
		{
			GetHeadMovingMapping();

			if(xTorso > xTorsoBase)//go to right
			{
				return EVENTS_BLOCK_LEFT;
			}else{
				return EVENTS_BLOCK_RIGHT;
			}
		}else
		{	
			return EVENTS_BOX_BLOCK;
		}
	}

	//int dX = -1, dY = -1;	
	//if(rightD>0)
	//{
	//	dY = handOneEvents(first, last, 1, rightD);
	//}

	//if(dY == EVENT_RIGHT_LEFT)
	//	return EVENTS_BOX_PUNCH;

	//int xL = last->leftX;
	//int yL = last->leftY;
	//int xR = last->rightX;
	//int yR = last->rightY;

	//int xTorsoLimits = suTorso*0.5;
	//if(abs(xL - xR)<suTorso && abs(yL-yR)<xTorsoLimits && yL < yTorso+suTorso && yR < yTorso+suTorso)
	//	return EVENTS_BOX_BLOCK;

	//torso turn left or right	
	if(abs(xTorso - xTorsoBase) > xTorsoLimits)
	{
		GetHeadMovingMapping();

		if(xTorso > xTorsoBase)//go to right
		{
			return EVENTS_BOX_LEFT;
		}else{
			return EVENTS_BOX_RIGHT;
		}

	}

	//one hand control
/*	int dX = -1, dY = -1;
	if(leftD>0)
	{			
		dX = handOneEvents(first, last, 0, leftD);
	}
	if(rightD>0)
	{
		dY = handOneEvents(first, last, 1, rightD);
	}

	if(dX >= 0 && !justHitLeft)
	{
		justHitLeft = 1;
		return dX;
	}

	if(dY >= 0 && !justHitRight)
	{
		justHitRight = 1;
		return dY;
	}*/	

	if(ret0<0 && ret1<0)
	{
		if(noStatusNum>30)
		{
			lastLeftDir = ret0;
			lastRightDir = ret1;
			justHitLeft = 0;
			justHitRight = 0;
			justHitBoth = 0;
			justHitZoom = 0;
			leftFirstMoving = 0;
			rightFirstMoving = 0;

			noStatusNum = -1;
		}
		noStatusNum++;

	}

	return EVENT_UNDEFINED;
#else
	//PUNCH OR BLOCK:
	int dX = -1, dY = -1;	
	if(rightD>0)
	{
		dY = handOneEvents(first, last, 1, rightD);
	}

	if(dY == EVENT_RIGHT_LEFT)
		return EVENTS_BOX_PUNCH;

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int xTorsoLimits = suTorso*0.5;
	if(abs(xL - xR)<suTorso && abs(yL-yR)<xTorsoLimits && yL < yTorso+suTorso && yR < yTorso+suTorso)
		return EVENTS_BOX_BLOCK;

	//torso turn left or right	
	if(abs(xTorso - xTorsoBase) > xTorsoLimits)
	{
		if(xTorso > xTorsoBase)//go to right
		{
			return EVENTS_BOX_RIGHT;
		}else{
			return EVENTS_BOX_LEFT;
		}

	}
	else{
		return handMovingEventsControl(first, last, leftD, rightD);
	}

	return EVENT_UNDEFINED;
#endif
}

int CGesture::handMovingEventsMoto(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
	int ret0 = leftD;
	int ret1 = rightD;

	if(ret0>0)
		RecordMovingPara(first, last, 0, ret0);
	if(ret1>0)
		RecordMovingPara(first, last, 1, ret1);

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int diffY = abs(last->leftY - last->rightY)*1.8;
	int yLimits = yTorso + suTorso*0.5;

	int chestY = yTorso + suTorso*1.5;
	int xTorsoLimits = suTorso*0.5;
	//int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*1.2;

	//1. reset the recording flags
	if(ret0 >0 || ret1 >0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits))
	{	

		//if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
		//	(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
		if( (lastLeftDir == 3 && lastRightDir == 3) ||
			(lastLeftDir == 4 && lastRightDir == 4) ||
			((lastLeftDir == 3 || lastLeftDir == 4) && diffY < suTorso && last->leftY<yLimits) ||
			((lastRightDir == 3 || lastRightDir == 4) && diffY < suTorso && last->rightY<yLimits) ||
			(ret0==-1 && (ret1==3 || ret1==4) && (lastLeftDir==ret1) && diffY < suTorso) ||
			(ret1==-1 && (ret0==3 || ret0==4) && (lastRightDir==ret0) && diffY < suTorso) ||
			(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
		{
			if((ret0>0 && lastLeftDir>0 && lastLeftDir!=ret0) || 
				(ret1>0 && lastRightDir>0 && lastRightDir!=ret1)||
				(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
			{
				justHitBoth = 0;					
			}
			if(ret0<0 && diffY < suTorso) ret0 = ret1;
			if(ret1<0 && diffY < suTorso) ret1 = ret0;
			lastLeftDir = ret0;
			lastRightDir = ret1;
		}		
		else
		{
			if(lastLeftDir != ret0)
			{
				if(lastLeftDir!=-1 || (lastLeftDir=-1 && ret0 >1) || (yL<yTorso-xTorsoLimits && ret0<0))
				{
					justHitLeft = 0;
					leftFirstMoving = 0;
				}
				lastLeftDir = ret0;
			}
			if(lastRightDir != ret1)
			{
				if(lastRightDir!=-1 || (lastRightDir=-1 && ret1 >1) || (yR<yTorso-xTorsoLimits && ret1<0))
				{
					justHitRight = 0;
					rightFirstMoving = 0;
				}
				lastRightDir = ret1;
			}
		}

		if(ret0 >0 || ret1 >0)
			noStatusNum = 0;
	}

	if(yL > chestY && yR > chestY)
		return EVENT_UNDEFINED;

	//2. 
	//if(abs(yL - yR)>suTorso*0.2)//if(abs(xTorso - xTorsoBase) > xTorsoLimits)//Body moved
	{
		//BOTH hands up
		int yMostUpLimits = yTorso - 1.5*suTorso;
		if(ret0> 0 || ret1 > 0 || (yL < yMostUpLimits && yR < yMostUpLimits))//yTorso - xTorsoLimits
		{
			//int yLimits = yTorso + suTorso*0.5;

			if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
				(yL < yMostUpLimits && yR < yMostUpLimits && (leftD==4 || rightD==4) && diffY < suTorso))//yTorso - xTorsoLimits
			{
				return EVENT_BOTH_UP;
			}	
		}		

		//mouse event
		int ret = handScreenOperation();
		if(ret>0)
		{
			return ret;
		}

		//operation
		if(yL < chestY && yR < chestY  && yL>yUp && yR > yUp )//&& diffY < suTorso
		{
			if(abs(yL-yR)>suTorso*0.5)
			{
				if(yL>yR)//if(xTorso > xTorsoBase)
				{
					return EVENTS_CAR_SPEED_LEFT;
				}
				else
				{
					return EVENTS_CAR_SPEED_RIGHT;
				}
			}
			else
			{
				return EVENTS_CAR_JUST_SPEED;
			}
		}

		if(abs(yL-yR)>suTorso*0.5)//if((yL>chestY && yR<chestY) || (yL<chestY && yR>chestY))//if(yL > chestY && yR > chestY)//stop
		{
			if(yL>yR)//if(xTorso > xTorsoBase)
			{
				return EVENTS_CAR_JUST_LEFT;
			}
			else
			{
				return EVENTS_CAR_JUST_RIGHT;
			}
		}

		////one hand control
		//int dX = -1, dY = -1;
		//if(leftD>0)
		//{			
		//	dX = handOneEvents(first, last, 0, leftD);
		//}
		//if(rightD>0)
		//{
		//	dY = handOneEvents(first, last, 1, rightD);
		//}

		//if(dX >= 0)	// && !justHitLeft
		//{
		//	//justHitLeft = 1;
		//	return dX;
		//}

		//if(dY >= 0)// && !justHitRight
		//{
		//	//justHitRight = 1;
		//	return dY;
		//}	

	}
	//else
	//{
	//	//BOTH hands up
	//	if(ret0> 0 || ret1 > 0 || (yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
	//	{
	//		//int yLimits = yTorso + suTorso*0.5;

	//		if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
	//			(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
	//		{
	//			return EVENT_BOTH_UP;
	//		}	
	//	}

	//	//mouse event
	//	int ret = handScreenOperation();
	//	if(ret>0)
	//	{
	//		return ret;
	//	}

	//	//operation
	//	if(yL < chestY && yR < chestY && diffY < suTorso && yL>yUp && yR > yUp)
	//	{
	//		return EVENTS_CAR_JUST_SPEED;
	//	}


	//	////one hand control
	//	//int dX = -1, dY = -1;
	//	//if(leftD>0)
	//	//{			
	//	//	dX = handOneEvents(first, last, 0, leftD);
	//	//}
	//	//if(rightD>0)
	//	//{
	//	//	dY = handOneEvents(first, last, 1, rightD);
	//	//}

	//	//if(dX >= 0 && !justHitLeft)
	//	//{
	//	//	justHitLeft = 1;
	//	//	return dX;
	//	//}

	//	//if(dY >= 0 && !justHitRight)
	//	//{
	//	//	justHitRight = 1;
	//	//	return dY;
	//	//}
	//}	
	
	if(ret0<0 && ret1<0)
	{
		if(noStatusNum>30)
		{
			lastLeftDir = ret0;
			lastRightDir = ret1;
			justHitLeft = 0;
			justHitRight = 0;
			justHitBoth = 0;
			justHitZoom = 0;
			leftFirstMoving = 0;
			rightFirstMoving = 0;

			noStatusNum = -1;
		}
		noStatusNum++;

	}

	return EVENT_UNDEFINED;

#if 0

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int chestY = yTorso + suTorso;
	int xTorsoLimits = suTorso*0.5;
	int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*0.2;

	int ret0 = leftD;
	int ret1 = rightD;

#if 1
	if(abs(xTorso - xTorsoBase) > xTorsoLimits)//Body moved
	{
		//BOTH hands up
		if(ret0> 0 || ret1 > 0)
		{
			int yLimits = yTorso + suTorso*0.5;

			if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
				(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
			{
				return EVENT_BOTH_UP;
			}	
		}		
		
		//operation
		if(yL < chestY && yR < chestY && diffY < suTorso && yL>yUp && yR > yUp)
		{
			if(xTorso > xTorsoBase)
			{
				return EVENTS_CAR_SPEED_LEFT;
			}
			else
			{
				return EVENTS_CAR_SPEED_RIGHT;
			}
		}
		
		if(yL > chestY && yR > chestY)//stop
		{
			if(xTorso > xTorsoBase)
			{
				return EVENTS_CAR_JUST_LEFT;
			}
			else
			{
				return EVENTS_CAR_JUST_RIGHT;
			}
		}

		//one hand control
		int dX = -1, dY = -1;
		if(leftD>0)
		{			
			dX = handOneEvents(first, last, 0, leftD);
		}
		if(rightD>0)
		{
			dY = handOneEvents(first, last, 1, rightD);
		}

		if(dX >= 0)	// && !justHitLeft
		{
			//justHitLeft = 1;
			return dX;
		}

		if(dY >= 0)// && !justHitRight
		{
			//justHitRight = 1;
			return dY;
		}	
		
	}
	else
	{
		//BOTH hands up
		if(ret0> 0 || ret1 > 0)
		{
			int yLimits = yTorso + suTorso*0.5;

			if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
				(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
			{
				return EVENT_BOTH_UP;
			}	
		}

		//operation
		if(yL < chestY && yR < chestY && diffY < suTorso && yL>yUp && yR > yUp)
		{
			return EVENTS_CAR_JUST_SPEED;
		}


		//one hand control
		int dX = -1, dY = -1;
		if(leftD>0)
		{			
			dX = handOneEvents(first, last, 0, leftD);
		}
		if(rightD>0)
		{
			dY = handOneEvents(first, last, 1, rightD);
		}

		if(dX >= 0 && !justHitLeft)
		{
			justHitLeft = 1;
			return dX;
		}

		if(dY >= 0 && !justHitRight)
		{
			justHitRight = 1;
			return dY;
		}	



		//if(yL > chestY && yR > chestY)//stop
		//{
		//	return EVENTS_CAR_JUST_BRAKE;
		//}
	}	

	return EVENT_UNDEFINED;

#else
	int ret = handMovingEventsControl(first, last, leftD, rightD);
	if(ret>0 && ret!=EVENT_RIGHT_RIGHT && ret !=EVENT_LEFT_DOWN && ret!=EVENT_RIGHT_DOWN && ret!=EVENT_BOTH_DOWN)
	{
		return ret;
	}else
	{
		if(yL < chestY && yR < chestY && diffY < suTorso)//speed
		{

			if(abs(xTorso - xTorsoBase) > xTorsoLimits)//left, right
			{
				if(xTorso > xTorsoBase)
				{
					return EVENTS_CAR_SPEED_LEFT;
				}
				else
				{
					return EVENTS_CAR_SPEED_RIGHT;
				}
			}else{
				return EVENTS_CAR_JUST_SPEED;
			}
		}

		if(yL > chestY && yR > chestY)//stop			
		{	
			if(abs(xTorso - xTorsoBase) > xTorsoLimits)//left, right
			{
				if(xTorso > xTorsoBase)
				{
					return EVENTS_CAR_JUST_LEFT;
				}
				else
				{
					return EVENTS_CAR_JUST_RIGHT;
				}
			}
			else
			{
				return EVENTS_CAR_JUST_BRAKE;
			}

		}

		return EVENT_UNDEFINED;

	}
#endif

#endif
}

int CGesture::handMovingEventsDance(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int dxL = abs(xL - xTorso);
	int dyL = abs(yL - yTorso);
	int dxR = abs(xR - xTorso);
	int dyR = abs(yR - yTorso);

	int farMostLimits = suTorso*2.5;
	int thresh = suTorso*0.5;

	if(dxL > farMostLimits || dyL > farMostLimits || dxR > farMostLimits || dyR > farMostLimits)
	{
		//case 1: left
		if(dxL > farMostLimits && dyL < thresh && dxR < farMostLimits && dyR < farMostLimits)
			return EVENTS_DANCE_LEFT;

		//case 2: right
		if(dxR > farMostLimits && dyR < thresh && dxL < farMostLimits && dyL < farMostLimits)
			return EVENTS_DANCE_RIGHT;

		//case 3: up
		if(dxL < thresh && dyL < thresh && yL < yTorso && dxR < farMostLimits && dyR < farMostLimits)
			return EVENTS_DANCE_UP;

		//case 4: down

		//case 5: left+up
		if(dxL > farMostLimits && dyL < thresh && dxR < thresh && dyR > farMostLimits && yR < yTorso)
			return EVENTS_DANCE_LEFT_UP;

		//case 6: left+down

		//case 7: right+up
		if(dxL < thresh && dyL > farMostLimits && yL < yTorso && dxR > farMostLimits && dyR < thresh)
			return EVENTS_DANCE_RIGHT_UP;

		//case 8: right+down

		//case 9: left+right
		if(dxL > farMostLimits && dyL < thresh && dxR > farMostLimits && dyR < thresh)
			return EVENTS_DANCE_LEFT_RIGHT;

		//case 10: up+down
	}
	
	return EVENT_UNDEFINED;

	
}

int CGesture::handMovingEventsSkee(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
	int ret0 = leftD;
	int ret1 = rightD;

	if(ret0>0)
		RecordMovingPara(first, last, 0, ret0);
	if(ret1>0)
		RecordMovingPara(first, last, 1, ret1);

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int diffY = abs(last->leftY - last->rightY)*1.8;
	int yLimits = yTorso + suTorso*0.5;

	int chestY = yTorso + suTorso;
	int xTorsoLimits = suTorso*0.5;
	//int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*0.5;

	if(ret0 >0 || ret1 >0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits))
	{	

		//if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
		//	(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
		if( (lastLeftDir == 3 && lastRightDir == 3) ||
			(lastLeftDir == 4 && lastRightDir == 4) ||
			((lastLeftDir == 3 || lastLeftDir == 4) && diffY < suTorso && last->leftY<yLimits) ||
			((lastRightDir == 3 || lastRightDir == 4) && diffY < suTorso && last->rightY<yLimits) ||
			(ret0==-1 && (ret1==3 || ret1==4) && (lastLeftDir==ret1) && diffY < suTorso) ||
			(ret1==-1 && (ret0==3 || ret0==4) && (lastRightDir==ret0) && diffY < suTorso) ||
			(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
		{
			if((ret0>0 && lastLeftDir>0 && lastLeftDir!=ret0) || 
				(ret1>0 && lastRightDir>0 && lastRightDir!=ret1) )
			{
				justHitBoth = 0;					
			}
			if(ret0<0 && diffY < suTorso) ret0 = ret1;
			if(ret1<0 && diffY < suTorso) ret1 = ret0;
			lastLeftDir = ret0;
			lastRightDir = ret1;
		}		
		else
		{
			if(lastLeftDir != ret0)
			{
				if(lastLeftDir!=-1 || (lastLeftDir=-1 && ret0 >1) || (yL<yTorso-xTorsoLimits && ret0<0))
				{
					justHitLeft = 0;
					leftFirstMoving = 0;
				}
				lastLeftDir = ret0;
			}
			if(lastRightDir != ret1)
			{
				if(lastRightDir!=-1 || (lastRightDir=-1 && ret1 >1) || (yR<yTorso-xTorsoLimits && ret1<0))
				{
					justHitRight = 0;
					rightFirstMoving = 0;
				}
				lastRightDir = ret1;
			}
		}

		if(ret0 >0 || ret1 >0)
			noStatusNum = 0;
	}

	//BOTH hands up
	if(ret0> 0 || ret1 > 0 || (yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits))
	{
		//int yLimits = yTorso + suTorso*0.5;

		if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
			(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
		{
			return EVENT_BOTH_UP;
		}	
	}		

	//mouse event
	int ret = handScreenOperation();
	if(ret>0)
	{
		return ret;
	}

	//operation
	if(abs(xTorso - xTorsoBase) > xTorsoLimits)//left, right
	{
		//GetHeadMovingMapping();

		if(xTorso > xTorsoBase)
		{
			return EVENTS_SKEE_LEFT;
		}
		else
		{
			return EVENTS_SKEE_RIGHT;
		}
	}	


	//one hand control
	//int dX = -1, dY = -1;
	//if(leftD>0)
	//{			
	//	dX = handOneEvents(first, last, 0, leftD);
	//}
	//if(rightD>0)
	//{
	//	dY = handOneEvents(first, last, 1, rightD);
	//}

	//if(dX >= 0 && !justHitLeft)
	//{
	//	justHitLeft = 1;
	//	return dX;
	//}

	//if(dY >= 0&& !justHitRight)
	//{
	//	justHitRight = 1;
	//	return dY;
	//}

	if(ret0<0 && ret1<0)
	{
		if(noStatusNum>30)
		{
			lastLeftDir = ret0;
			lastRightDir = ret1;
			justHitLeft = 0;
			justHitRight = 0;
			justHitBoth = 0;
			justHitZoom = 0;
			leftFirstMoving = 0;
			rightFirstMoving = 0;

			noStatusNum = -1;
		}
		noStatusNum++;

	}

	return EVENT_UNDEFINED;

}

int CGesture::handMovingEventsView(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
	int ret0 = leftD;
	int ret1 = rightD;

	if(ret0>0)
		RecordMovingPara(first, last, 0, ret0);
	if(ret1>0)
		RecordMovingPara(first, last, 1, ret1);

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	int diffY = abs(last->leftY - last->rightY)*1.8;
	int yLimits = yTorso + suTorso*0.5;

	int chestY = yTorso + suTorso*1.5;
	int xTorsoLimits = suTorso*0.5;
	//int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*0.5;

	//Step 1: reset some flags
	if(ret0 >0 || ret1 >0 || (yL < yTorso - xTorsoLimits || yR < yTorso - xTorsoLimits))
	{	
		//both hands up condition
		if( (lastLeftDir == 3 && lastRightDir == 3) ||
			(lastLeftDir == 4 && lastRightDir == 4) ||
			((lastLeftDir == 3 || lastLeftDir == 4) && diffY < suTorso && last->leftY<yLimits) ||
			((lastRightDir == 3 || lastRightDir == 4) && diffY < suTorso && last->rightY<yLimits) ||
			(ret0==-1 && (ret1==3 || ret1==4) && (lastLeftDir==ret1) && diffY < suTorso) ||
			(ret1==-1 && (ret0==3 || ret0==4) && (lastRightDir==ret0) && diffY < suTorso))
		{
			if((ret0>0 && lastLeftDir>0 && lastLeftDir!=ret0) || 
				(ret1>0 && lastRightDir>0 && lastRightDir!=ret1) )
			{
				justHitBoth = 0;					
			}
			if(ret0<0 && diffY < suTorso) ret0 = ret1;
			if(ret1<0 && diffY < suTorso) ret1 = ret0;
			lastLeftDir = ret0;
			lastRightDir = ret1;
		}		
		else//one hand up condition
		{
			if(lastLeftDir != ret0)
			{
				if(lastLeftDir!=-1 || (lastLeftDir=-1 && ret0 >1) || (yL<yTorso-xTorsoLimits && ret0<0))
				{
					justHitLeft = 0;
					leftFirstMoving = 0;
				}
				lastLeftDir = ret0;
			}
			if(lastRightDir != ret1)
			{
				if(lastRightDir!=-1 || (lastRightDir=-1 && ret1 >1) || (yR<yTorso-xTorsoLimits && ret1<0))
				{
					justHitRight = 0;
					rightFirstMoving = 0;
				}
				lastRightDir = ret1;
			}
		}

		if(ret0 >0 || ret1 >0)
			noStatusNum = 0;
	}

	//Step 2: hand events: hands up -> zoom in/out -> one hand events
	//2.1 BOTH hands up
	if(ret0> 0 || ret1 > 0)
	{
		//int yLimits = yTorso + suTorso*0.5;
		int yMostUpLimits = yTorso - 0.6*suTorso;

		if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
			(yL < yMostUpLimits && yR < yMostUpLimits && (leftD==4 || rightD==4) && diffY < suTorso))
		{
			return EVENT_BOTH_UP;
		}	
	}	

	if(yL > chestY && yR > chestY)
		return EVENT_UNDEFINED;

	//2.2 operation: zoom in/out
	if(yL < chestY && yL >  yUp && yR < chestY && yR >  yUp && diffY < suTorso)
	{
		static int lastHandDist = 0, handDist = 0;
		static int frameClose = 0, frameFar = 0;

		if(lastHandDist==0 && handDist==0)
		{		
			handDist = abs(xL - xR);
			lastHandDist = handDist;			
		}else
		{
			handDist = abs(xL - xR);

			int xThresh = 0.08*suTorso;//min(0.1*suTorso, 8);
			if(handDist-lastHandDist>xThresh)
			{			
				frameClose = 0;
				frameFar++;
				if(frameFar>3)
				{
					frameFar = 0;
					handDist = 0;
					lastHandDist = 0;
					return EVENT_HANDS_FAR;
				}				
				lastHandDist = handDist;
			}
			if(lastHandDist - handDist>xThresh)
			{
				frameFar = 0;
				frameClose++;

				if(frameClose>3)
				{
					frameClose = 0;
					handDist = 0;
					lastHandDist = 0;
					return EVENT_HANDS_CLOSE;
				}
				
				lastHandDist = handDist;
			}
		}


		if(leftD == 1 && rightD==2)
		{			
			return EVENT_HANDS_FAR;
		}

		if(leftD == 2 && rightD==1)
		{			
			return EVENT_HANDS_CLOSE;
		}		

		//return EVENT_UNDEFINED;//original need this
	}

	//2.3 One hand control
	int dX = -1, dY = -1;
	if(leftD>0)
	{			
		dX = handOneEvents(first, last, 0, leftD);
	}
	if(rightD>0)
	{
		dY = handOneEvents(first, last, 1, rightD);
	}

	if(dX >= 0 && !justHitLeft)
	{
		justHitLeft = 1;
		return dX;
	}

	if(dY >= 0&& !justHitRight)
	{
		justHitRight = 1;
		return dY;
	}

	if(ret0<0 && ret1<0)
	{
		if(noStatusNum>30)
		{
			lastLeftDir = ret0;
			lastRightDir = ret1;
			justHitLeft = 0;
			justHitRight = 0;
			justHitBoth = 0;
			justHitZoom = 0;
			leftFirstMoving = 0;
			rightFirstMoving = 0;

			noStatusNum = -1;
		}
		noStatusNum++;

	}

	return EVENT_UNDEFINED;
}

int CGesture::checkBothHandsUp(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int leftD, int rightD)
{
	int yLimits = yTorso + suTorso*0.5;

	int xL = last->leftX;
	int yL = last->leftY;
	int xR = last->rightX;
	int yR = last->rightY;

	//int chestY = yTorso + suTorso;
	int xTorsoLimits = suTorso*0.5;
	int diffY = abs(yR - yL);

	int yUp = yTorso - suTorso*0.2;

	int ret0 = leftD;
	int ret1 = rightD;

	if( (leftD == 4 && rightD == 4 && yL< yUp && yR<yUp) ||
		(yL < yTorso - xTorsoLimits && yR < yTorso - xTorsoLimits && (leftD==4 || rightD==4) && diffY < suTorso))
	{
		return EVENT_BOTH_UP;
	}	

	//int diffY = int(abs(last->leftY - last->rightY)*1.8);
	//int yLimits = yTorso + suTorso*0.5;

	//if( (leftD == 3 && rightD == 3) ||
	//   (leftD == 4 && rightD == 4) ||
	//   ((leftD == 3 || leftD == 4) && diffY < suTorso && last->leftY<yLimits) ||
	//   ((rightD == 3 || rightD == 4) && diffY < suTorso && last->rightY<yLimits) )
	//{
	//	int dBoth = handBothEvents(first, last, leftD);
	//	if(dBoth>0 && !justHitBoth)
	//	{
	//		justHitBoth = 1;
	//		return dBoth;
	//	}

	//}

	return EVENT_UNDEFINED;
}

int CGesture::handOneEvents(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int flag, int hDir)
{	
	int currX, currY, dist2 = 0;
	int su2 = suTorso*0.3;//suTorso*suTorso;
	int su_fast = suTorso*1.2;	//for fast motion

	//float suTorsoBack = 0.15f*suTorso;
	m_bHandMoveFast = 0;

	if(flag==0)
	{
		currX = last->leftX;
		currY = last->leftY;

		if(hDir==1 || hDir==2)
		{
			dist2 = abs(currX - leftBaseX);
		}
		if(hDir==3 || hDir == 4)
		{
			dist2 = abs(currY - leftBaseY);
		}
		//dist2 = (currX - leftBaseX)*(currX - leftBaseX) + (currY - leftBaseY)*(currY - leftBaseY);

		if((dist2 > su2 
			|| leftFirstMoving > 3
			|| currY < yTorso-0.5*suTorso) )
		{
			if(last->rightY > yTorso + suTorso*1.5)
			{
				if(hDir == 1)
				{				
					if(currY>yTorso-suTorso && currY<yTorso+suTorso)
						return EVENT_LEFT_LEFT;			
				}
				if(hDir == 2)
				{				
					if(currY>yTorso-suTorso && currY<yTorso+suTorso)
					{
	#ifdef HAND_FAST_MOTION
						m_bHandMoveFast = isHandMovingFast(flag, hDir);
						if (dist2>su_fast)	//fast motion
						{
							m_bHandMoveFast = 1;
						}
						else
						{
							m_bHandMoveFast = 0;
						}
	#endif

						return EVENT_LEFT_RIGHT;
					}
				}
				if(hDir == 3)
				{				
					if(currY>yTorso-0.1*suTorso)
						return EVENT_LEFT_DOWN;
				}
			}

			if(hDir == 4)
			{				
				if(currY<yTorso-0.2*suTorso)//if(currY<yTorso-0.2*suTorso)//
				{
					if(last->rightY > yTorso + 1.5*suTorso)
						return EVENT_LEFT_UP;

					if(last->rightY < yTorso + 1.5*suTorso && last->rightY > yTorso - 0.5*suTorso)
						return EVENT_LEFT_UP_SHIFT;
				}
			}
		}
	}
	else
	{
		currX = last->rightX;
		currY = last->rightY;

		if(hDir==1 || hDir==2)
		{
			dist2 = abs(currX - rightBaseX);
		}
		if(hDir==3 || hDir == 4)
		{
			dist2 = abs(currY - rightBaseY);
		}
		//dist2 = (currX - rightBaseX)*(currX - rightBaseX) + (currY - rightBaseY)*(currY - rightBaseY);

		if((dist2 > su2 || rightFirstMoving > 3 || currY < yTorso-0.5*suTorso ) )
		{
			if(last->leftY > yTorso + suTorso*1.5)
			{
				if(hDir == 1)
				{				
					if(currY>yTorso-suTorso && currY<yTorso+suTorso )//if(currY>yTorso-0.2*suTorso && currY<yTorso+suTorso)//
					{
	#ifdef HAND_FAST_MOTION
						m_bHandMoveFast = isHandMovingFast(flag, hDir);
						if (dist2>su_fast)	//fast motion
						{
							m_bHandMoveFast = 1;
						}
						else
						{
							m_bHandMoveFast = 0;
						}
	#endif

						return EVENT_RIGHT_LEFT;
					}
				}
				if(hDir == 2)
				{				
					if(currY>yTorso-suTorso && currY<yTorso+suTorso)//if(currY>yTorso-0.2*suTorso && currY<yTorso+suTorso)//
						return EVENT_RIGHT_RIGHT;
				}
				if(hDir == 3)
				{				
					if(currY>yTorso-0.1*suTorso)
						return EVENT_RIGHT_DOWN;
				}
			}

			if(hDir == 4)
			{				
				if(currY<yTorso-0.2*suTorso)
				{					
					if(last->leftY > yTorso + 1.5*suTorso)
						return EVENT_RIGHT_UP;

					if(last->leftY < yTorso + 1.5*suTorso && last->leftY > yTorso - 0.5*suTorso)
						return EVENT_RIGHT_UP_SHIFT;
				}					
			}
		}
	}

	return EVENT_UNDEFINED;
}

int CGesture::handBothEvents(HAND_POSITION_PT* first, HAND_POSITION_PT* last, int hDir)
{	
	int currX, currY, dist2 = 0, dist2R;
	int su2 = suTorso*suTorso;

	currX = last->leftX;
	currY = last->leftY;

	dist2 = (currX - leftBaseX)*(currX - leftBaseX) + (currY - leftBaseY)*(currY - leftBaseY);

	int currXR = last->rightX;
	int currYR = last->rightY;

	dist2R = (currXR - rightBaseX)*(currXR - rightBaseX) + (currYR - rightBaseY)*(currYR - rightBaseY);

	if((dist2>su2 || leftFirstMoving > 5) 
		&& (dist2R>su2 || rightFirstMoving > 5))
	{
		if(hDir==3 && (currY>yTorso) && (currYR>yTorso))
			return EVENT_BOTH_DOWN;
		if(hDir==4 && (currY<yTorso-0.5*suTorso) && (currYR<yTorso-0.5*suTorso))
			return EVENT_BOTH_UP;
	}

	return EVENT_UNDEFINED;
}

int CGesture::someHandsMoving(HAND_POSITION_PT* first, HAND_POSITION_PT* last)
{
	if(!first || !first->next)
		return 0;

	//left hand
	int minX = 9999;
	int maxX = 0;

	int minY = 9999;
	int maxY = 0;

	int currX, currY;

	HAND_POSITION_PT* temp = first;

	int flag = 0;
	for(; temp!= NULL;)
	{
		if(flag==0)
		{
			currX = temp->leftX;
			currY = temp->leftY;
		}else{
			currX = temp->rightX;
			currY = temp->rightY;
		}

		if(minX > currX)
		{
			minX = currX;
		}
		if(maxX < currX)
		{
			maxX = currX;
		}

		if(minY > currY)
		{
			minY = currY;
		}
		if(maxY < currY)
		{
			maxY = currY;
		}


		temp = temp->next;
	}

	int handLimits = 0.1*suTorso;
	if(maxY - minY > handLimits || maxX - minX > handLimits)
		return 1;

	//right hand
	minX = 9999;
	maxX = 0;
	minY = 9999;
	maxY = 0;
	temp = first;
	flag = 1;
	for(; temp!= NULL;)
	{
		if(flag==0)
		{
			currX = temp->leftX;
			currY = temp->leftY;
		}else{
			currX = temp->rightX;
			currY = temp->rightY;
		}

		if(minX > currX)
		{
			minX = currX;
		}
		if(maxX < currX)
		{
			maxX = currX;
		}

		if(minY > currY)
		{
			minY = currY;
		}
		if(maxY < currY)
		{
			maxY = currY;
		}


		temp = temp->next;
	}
	
	if(maxY - minY > handLimits || maxX - minX > handLimits)
		return 1;
	
	return 0;
}

int CGesture::GetHeadMovingMapping()
{
#if 1
	//estimate mapping window
	int xmin = xTorsoBase - suTorso*2;
	int xmax = xTorsoBase + suTorso*2;	
	//int widthMap =  xmax - xmin;

	float coef = 1.0f/(suTorso*3);

	//get screen mapping position
	if(xTorso < xTorsoBase)
	{
		m_xScreen = 1 - (xTorso - xmin )*coef;
	}
	else{
		m_xScreen = 0.5 - (xTorso - xmin-suTorso*2.5)*coef;
	}
#else
	//estimate mapping window
	int xmin = xTorsoBase - suTorso*3;
	int xmax = xTorsoBase + suTorso*3;	
	//int widthMap =  xmax - xmin;

	float coef = 1.0f/(suTorso*5);

	//int notMovingArea = suTorso*0.5;

	//get screen mapping position
	if(xTorso < xTorsoBase)
	{
		m_xScreen = 1 - (xTorso - xmin )*coef;
	}
	else{
		m_xScreen = 0.5 - (xTorso - xmin-suTorso*3.5)*coef;
	}
#endif
	if (m_xScreen<0.00001f)
	{
		m_xScreen = 0.00001f;
	}
	else if (m_xScreen>1.0f)
	{
		m_xScreen = 1.0f;
	}
	m_yScreen = 0.5f;

	return MOBI_SUCCEED;	
}

//mapping right hand position to screen (cursor position)
int CGesture::handScreenMapping()
{
	//judge if is cursor operation mode: left hand is neutrally down, right hand is upside (upper than elbow)
	if (!m_bScreenInit)
	{
		m_xTorsoScreen = m_body.nodeTorso.x;
		m_yTorsoScreen = m_body.nodeTorso.y;
		m_suTorsoHalf = m_body.nodeTorso.z*0.5;
		m_yUpDownTh = yTorso+m_suTorsoHalf*3.5;

		//judge if left hand is neutral down
		if ( m_body.handL.node.y < m_yUpDownTh || m_body.handL.node.x<m_xTorsoScreen+m_suTorsoHalf)
		{
			return -1;	//not neutral pose
		}

		//judge if right hand is in screen operation area
		if ( m_body.handR.node.y>m_yUpDownTh || m_body.handR.node.x>m_xTorsoScreen-m_suTorsoHalf )
		{
			return -1;	//not in screen operation area
		}

		//estimate mapping window
		m_xminScreen = m_xTorsoScreen - m_suTorsoHalf*6.0;
		m_xmaxScreen = m_xTorsoScreen - m_suTorsoHalf;
		m_yminScreen = m_yTorsoScreen - m_suTorsoHalf*2.0;
		m_ymaxScreen = m_yTorsoScreen + m_suTorsoHalf*3.0;
		m_widthMapScreen =  m_xmaxScreen - m_xminScreen;
		m_heightMapScreen = m_ymaxScreen - m_yminScreen;

		m_xLastForMouse0 = m_body.handR.node.x;
		m_yLastForMouse0 = m_body.handR.node.y;
		m_xLastForMouse1 = m_xLastForMouse2 = m_xLastForMouse0;
		m_yLastForMouse1 = m_yLastForMouse2 = m_yLastForMouse0;
		m_MotionUnit = m_suTorsoHalf*0.12;	//0.4

		//init position of cursor
		//m_xScreen = 0.5;
		//m_yScreen = 1.0;

		m_bScreenInit = true;
	}
	else
	{
		double xTorso = m_body.nodeTorso.x;
		double yTorso = m_body.nodeTorso.y;
		double suTorsoHalf = m_body.nodeTorso.z*0.5;
		double yUpDownTh = yTorso+suTorsoHalf*3.5;

		//judge if left hand is neutral down
		if ( m_body.handL.node.y < yUpDownTh || m_body.handL.node.x<xTorso+suTorsoHalf)
		{
			m_bScreenInit = false;
			return -1;	//not neutral pose
		}

		//judge if right hand is in screen operation area
		if ( m_body.handR.node.y>yUpDownTh || m_body.handR.node.x>xTorso-suTorsoHalf )
		{
			m_bScreenInit = false;
			return -1;	//not in screen operation area
		}
	}

#if 1
	int ret = isHandMoving(1);
	int currX, currY;

	if(ret>0)
	{
		currX =  m_body.handR.node.x;//m_body.nodeTorso.x;
		currY =  m_body.handR.node.y;//m_body.nodeTorso.y;
	}
	else
	{
		double sumX = 0.0, sumY = 0.0;
		int count = 0;

		HAND_POSITION_PT* temp = first;
		for(; temp!= NULL;)
		{			
			sumX += temp->rightX;
			sumY += temp->rightY;
			count ++;
			temp = temp->next;
		}
		if(count==0)
		{
			currX = m_body.handR.node.x;//m_body.nodeTorso.x;
			currY =  m_body.handR.node.y;//m_body.nodeTorso.y;
		}
		else
		{
			currX = sumX / count;
			currY = sumY / count;
		}
	}
#else
	int currX = m_body.handR.node.x;
	int currY = m_body.handR.node.y;
#endif

#if 0

	//get screen mapping position
	m_xScreen = (m_xmaxScreen - currX)/m_widthMapScreen;//m_body.handR.node.x
	if (m_xScreen<0.00001f)
	{
		m_xScreen = 0.00001f;
	}
	else if (m_xScreen>1.0f)
	{
		m_xScreen = 1.0f;
	}

	m_yScreen = (currY - m_yminScreen)/m_heightMapScreen;//m_body.handR.node.y

	if (m_yScreen<0.00001f)
	{
		m_yScreen = 0.00001f;
	}
	else if (m_yScreen>1.0f)
	{
		m_yScreen = 1.0f;
	}

	//normalize to 100*100
	int handx = (int)(m_xScreen*200);
	int handy = (int)(m_yScreen*150);
	m_xScreen = handx/200.0f;
	m_yScreen = handy/150.0f;

#else

	//new strategy for screen mapping
	float dxMotion = (m_xLastForMouse1 - currX) / m_MotionUnit;
	float dyMotion = (currY - m_yLastForMouse1) / m_MotionUnit;
	if ( abs(dxMotion)>25 || abs(dyMotion)>25 )
	{
		m_xScreen += dxMotion*0.01*4.0;
		m_yScreen += dyMotion*0.01*4.0;
	}
	else if ( abs(dxMotion)>12 || abs(dyMotion)>12 )
	{
		m_xScreen += dxMotion*0.01*2.0;
		m_yScreen += dyMotion*0.01*2.0;
	}
	else if ( abs(dxMotion)<3 && abs(dyMotion)<3 )
	{
		m_xScreen += dxMotion*0.01*0.5;
		m_yScreen += dyMotion*0.01*0.5;
	}
	else
	{
		m_xScreen += dxMotion*0.01;
		m_yScreen += dyMotion*0.01;
	}

	if (m_xScreen<0.00001f)
	{
		m_xScreen = 0.00001f;
	}
	else if (m_xScreen>1.0f)
	{
		m_xScreen = 1.0f;
	}

	if (m_yScreen<0.00001f)
	{
		m_yScreen = 0.00001f;
	}
	else if (m_yScreen>1.0f)
	{
		m_yScreen = 1.0f;
	}

	//normalize to 800*600
	int handx = (int)(m_xScreen*800);
	int handy = (int)(m_yScreen*600);
	m_xScreen = handx/800.0f;
	m_yScreen = handy/600.0f;

	//keep last hand position
	m_xLastForMouse2 = m_xLastForMouse1;
	m_yLastForMouse2 = m_yLastForMouse1;
	m_xLastForMouse1 = m_xLastForMouse0;
	m_yLastForMouse1 = m_yLastForMouse0;
	m_xLastForMouse0 = currX;
	m_yLastForMouse0 = currY;

#endif

	return MOBI_SUCCEED;
}


//mapping right hand position to screen (cursor position)
int CGesture::handScreenMappingNew()
{
	//judge if is cursor operation mode: left hand is neutrally down, right hand is upside (upper than elbow)
	if (!m_bScreenInit)
	{
		m_xTorsoScreen = m_body.nodeTorso.x;
		m_yTorsoScreen = m_body.nodeTorso.y;
		m_suTorsoHalf = m_body.nodeTorso.z*0.5;
		m_yUpDownTh = yTorso+m_suTorsoHalf*3.5;

		//judge if left hand is neutral down
		if ( m_body.handL.node.y < m_yUpDownTh || m_body.handL.node.x<m_xTorsoScreen+m_suTorsoHalf)
		{
			m_bScreenInit = false;
			return -1;	//not neutral pose
		}

		//judge if right hand is in screen operation area
		if ( m_body.handR.node.y>m_yUpDownTh || m_body.handR.node.x>m_xTorsoScreen-m_suTorsoHalf )
		{
			m_bScreenInit = false;
			return -1;	//not in screen operation area
		}

		//estimate mapping window
		m_xminScreen = m_xTorsoScreen - m_suTorsoHalf*6.0;
		m_xmaxScreen = m_xTorsoScreen - m_suTorsoHalf;
		m_yminScreen = m_yTorsoScreen - m_suTorsoHalf*2.0;
		m_ymaxScreen = m_yTorsoScreen + m_suTorsoHalf*3.0;
		m_widthMapScreen =  m_xmaxScreen - m_xminScreen;
		m_heightMapScreen = m_ymaxScreen - m_yminScreen;

		m_xLastForMouse0 = m_body.handR.node.x;
		m_yLastForMouse0 = m_body.handR.node.y;
		m_xLastForMouse1 = m_xLastForMouse2 = m_xLastForMouse0;
		m_yLastForMouse1 = m_yLastForMouse2 = m_yLastForMouse0;
		m_MotionUnit = m_suTorsoHalf*0.12;

		//m_xScreen = 0.5;
		//m_yScreen = 1.0;

		m_bScreenInit = true;
	}
	else
	{
		double xTorso = m_body.nodeTorso.x;
		double yTorso = m_body.nodeTorso.y;
		double suTorsoHalf = m_body.nodeTorso.z*0.5;
		double yUpDownTh = yTorso+suTorsoHalf*3.5;

		//judge if left hand is neutral down
		if ( m_body.handL.node.y < yUpDownTh || m_body.handL.node.x<xTorso+suTorsoHalf)
		{
			m_bScreenInit = false;
			return -1;	//not neutral pose
		}

		//judge if right hand is in screen operation area
		if ( m_body.handR.node.y>yUpDownTh || m_body.handR.node.x>xTorso-suTorsoHalf )
		{
			m_bScreenInit = false;
			return -1;	//not in screen operation area
		}
	}

	//int ret = isHandMoving(1);
	int currX, currY;

	//if(ret>0)
	//{
	//	currX =  m_body.handR.node.x;//m_body.nodeTorso.x;
	//	currY =  m_body.handR.node.y;//m_body.nodeTorso.y;
	//}
	//else
	//{
	//	double sumX = 0.0, sumY = 0.0;
	//	int count = 0;

	//	HAND_POSITION_PT* temp = first;
	//	for(; temp!= NULL;)
	//	{			
	//		sumX += temp->rightX;
	//		sumY += temp->rightY;
	//		count ++;
	//		temp = temp->next;
	//	}
	//	if(count==0)
	//	{
	//		currX = m_body.handR.node.x;//m_body.nodeTorso.x;
	//		currY =  m_body.handR.node.y;//m_body.nodeTorso.y;
	//	}
	//	else
	//	{
	//		currX = sumX / count;
	//		currY = sumY / count;
	//	}
	//}
	currX =  m_body.handR.node.x;
	currY =  m_body.handR.node.y;

	float dxMotion = (m_xLastForMouse2 - currX) / m_MotionUnit;
	float dyMotion = (currY - m_yLastForMouse2) / m_MotionUnit;

	if ( abs(dxMotion)>25 || abs(dyMotion)>25 )
	{
		m_xScreen += dxMotion*0.01*4.0;
		m_yScreen += dyMotion*0.01*4.0;
	}
	else if ( abs(dxMotion)>12 || abs(dyMotion)>12 )
	{
		m_xScreen += dxMotion*0.01*2.0;
		m_yScreen += dyMotion*0.01*2.0;
	}
	else if ( abs(dxMotion)<3 && abs(dyMotion)<3 )
	{
		m_xScreen += dxMotion*0.01*0.5;
		m_yScreen += dyMotion*0.01*0.5;
	}
	else
	{
		m_xScreen += dxMotion*0.01;
		m_yScreen += dyMotion*0.01;
	}	

	//get screen mapping position
	//m_xScreen = (m_xmaxScreen - currX)/m_widthMapScreen + dxMotion;
	if(abs(dxMotion)< 0.04)
		m_xScreen = m_xScreenLast+dxMotion;//(m_xmaxScreen - (currX+m_xLastForMouse0+m_xLastForMouse1)/3.0)/m_widthMapScreen + dxMotion;
	else
		m_xScreen = (m_xmaxScreen - (currX+m_xLastForMouse0+m_xLastForMouse1)/3.0)/m_widthMapScreen;

	if (m_xScreen<0.00001f)
	{
		m_xScreen = 0.00001f;
	}
	else if (m_xScreen>1.0f)
	{
		m_xScreen = 1.0f;
	}

	//m_yScreen = (currY - m_yminScreen)/m_heightMapScreen + dyMotion;
	if(abs(dyMotion)< 0.04)
		m_yScreen = m_yScreenLast+dyMotion;//((currY+m_yLastForMouse0+m_yLastForMouse1)/3.0 - m_yminScreen)/m_heightMapScreen + dyMotion;
	else
		m_yScreen = ((currY+m_yLastForMouse0+m_yLastForMouse1)/3.0 - m_yminScreen)/m_heightMapScreen;

	if (m_yScreen<0.00001f)
	{
		m_yScreen = 0.00001f;
	}
	else if (m_yScreen>1.0f)
	{
		m_yScreen = 1.0f;
	}

	//normalize to 800*600
	int handx = (int)(m_xScreen*800);
	int handy = (int)(m_yScreen*600);
	m_xScreen = handx/800.0f;
	m_yScreen = handy/600.0f;

	//keep last hand position
	m_xLastForMouse2 = m_xLastForMouse1;
	m_yLastForMouse2 = m_yLastForMouse1;
	m_xLastForMouse1 = m_xLastForMouse0;
	m_yLastForMouse1 = m_yLastForMouse0;
	m_xLastForMouse0 = currX;
	m_yLastForMouse0 = currY;

	return MOBI_SUCCEED;
}

//get screen operation events
int CGesture::handScreenOperation()
{
	int ret = handScreenMapping();
	if (MOBI_SUCCEED != ret)
	{
		return -1;	//no screen operation
	}

	float dxScreen = m_xScreen - m_xScreenLast;
	float dyScreen = m_yScreen - m_yScreenLast;
	if ( abs(dxScreen)<0.006f && abs(dyScreen)<0.006f )
	{
		++m_numScreen;
		//if(m_numScreen > 15)
		{
			m_xScreen = m_xScreenLast;
			m_yScreen = m_yScreenLast;
		}
	}
	else
	{
		m_numScreen=0;
	}
	m_xScreenLast = m_xScreen;
	m_yScreenLast = m_yScreen;

	if (m_numScreen<40)
	{
		return EVENT_HAND_SCREEN_MOVE; //screen position
	}
	else
	{
		m_numScreen = 0;
		return EVENT_HAND_SCREEN_CLICK;	//screen click
	}
}


//get screen operation events
int CGesture::handScreenOperationNew()
{
	int ret = handScreenMappingNew();
	if (MOBI_SUCCEED != ret)
	{
		return -1;	//no screen operation
	}

	float dxScreen = m_xScreen - m_xScreenLast;
	float dyScreen = m_yScreen - m_yScreenLast;

	if( (abs(dxScreen)<0.01f && abs(dyScreen)<0.1f ) ||
		(abs(dyScreen)<0.01f && abs(dxScreen)<0.1f ))
	{
		++m_numScreen;

		if(m_numScreen > 15)
		{
			if(abs(dxScreen)<0.01f && abs(dyScreen)<0.1f)
				m_yScreen = m_yScreenLast;
			if(abs(dyScreen)<0.01f && abs(dxScreen)<0.1f)
				m_xScreen = m_xScreenLast;
		}
	}
	//else if((abs(dxScreen)<0.02f && abs(dyScreen)>0.03f)
	//	|| (abs(dyScreen)<0.02f && abs(dxScreen)>0.03f))
	//{
	//	if(m_numScreen>15)
	//	{
	//		m_numScreen = 14;
	//	}
	//	else if(m_numScreen>5)
	//	{
	//		--m_numScreen;
	//	}

	//}
	else
	{		
		m_numScreen = 0;
	}

	m_xScreenLast = m_xScreen;
	m_yScreenLast = m_yScreen;

	if (m_numScreen<40)
	{
		return EVENT_HAND_SCREEN_MOVE; //screen position
	}
	else
	{
		m_numScreen = 0;
		return EVENT_HAND_SCREEN_CLICK;	//screen click
	}
}

int CGesture::isHandMoving(int flag)
{
	if(!first || !first->next)
		return 0;

	//left hand
	int minX = 9999;
	int maxX = 0;

	int minY = 9999;
	int maxY = 0;

	int currX, currY;

	HAND_POSITION_PT* temp = first;	
	for(; temp!= NULL;)
	{
		if(flag==0)
		{
			currX = temp->leftX;
			currY = temp->leftY;
		}else{
			currX = temp->rightX;
			currY = temp->rightY;
		}

		if(minX > currX)
		{
			minX = currX;
		}
		if(maxX < currX)
		{
			maxX = currX;
		}

		if(minY > currY)
		{
			minY = currY;
		}
		if(maxY < currY)
		{
			maxY = currY;
		}

		temp = temp->next;
	}

	int handLimits = 0.15*suTorso;
	if(maxY - minY > handLimits || maxX - minX > handLimits)
		return 1;

	return 0;
}


int CGesture::isHandMovingFast(int flag, int dir)
{
	int currX, currY, baseX, baseY;
	if(flag == 0)
	{
		baseX = leftBaseX;
		baseY = leftBaseY;

		currX = last->leftX;
		currY = last->leftY;
	}
	else
	{
		baseX = rightBaseX;
		baseY = rightBaseY;

		currX = last->rightX;
		currY = last->rightY;
	}

	//int chestY = yTorso + suTorso*1.2;
	//int yUp = yTorso - suTorso*0.3;
	//if(currY > chestY || currY < yUp)
	//	return 0;

	//if(!((flag==0 &&dir==2) || (flag==1&&dir==1)))
	//	return 0;

	int diffX[10] = {0};
	int diffY[10] = {0};
	int posD = 0;

	HAND_POSITION_PT* temp = first;	
	for(; temp!= NULL;)
	{
		if(flag==0)
		{
			currX = temp->leftX;
			currY = temp->leftY;
		}
		else
		{
			currX = temp->rightX;
			currY = temp->rightY;
		}

		diffX[posD] = abs(currX - baseX);
		diffY[posD] = abs(currY - baseY);

		temp = temp->next;
		posD ++;
	}

	//if((flag==0 &&dir==2) || (flag==1&&dir==1))
	//{
	//	int thresh = 0.4*suTorso;

	//	if(diffX[posD-1] > thresh)
	//	{
	//		return 1;
	//	}
	//}

	//return 0;

	int count = 0;
	int thresh = 0.35*suTorso;	

	for(int i=1; i<posD; ++i)
	{
		if(diffX[i] - diffX[i-1] > thresh )//|| abs(diffY[i] - diffY[i-1]) > thresh
		{
			count ++;
		}
	}

	if(diffX[0]> 0.85*suTorso || diffY[0] >  0.5*suTorso)
	{
		count++;
	}

	if(count > posD/2 )//&& diffX[posD] > suTorso*1.5
	{
		return 1;
	}

	return 0;
	
}

