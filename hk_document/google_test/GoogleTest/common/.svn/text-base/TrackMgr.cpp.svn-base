#include "StdAfx.h"
#include "TrackMgr.h"

#include "Settings.h"
#include "Util.h"

#include "math.h"
#include <vector>

class CTrackMgrData{
public:
	bool bInited;
	bool bPaused;
	bool hasModel;	//found body or hands.

	MobiBody bodyDisplay;
	MobiBody bodyLast;
	float factTemporal;

	//ProcessFrame result:
	int flag;
	MobiBody body;
	HtResult htRes;
	MobiGesture gesBody;
	//MobiGesPalm gesPalm;

	//IMobiGR* gr;
	//IMobiTrackMgr* tkMgr;
	IMobiHEART* tkMgr;

	//static replacements
	int lastBufferSize;
	//temporal factor for smooth torso
	float fInvFactTempo;
	bool bTracking;	// flag for doing detection or tracking

	int bodyDataFlags;///<0: disable, 1: fingers, 2: legs
};

#pragma warning(push)
#pragma warning(disable: 4244)
CTrackMgr::CTrackMgr(void): d(new CTrackMgrData){
	d->bInited = false;
	d->tkMgr = NULL;
	d->hasModel = false;
	d->factTemporal = 0.4f;

	d->bPaused = false;

	//used in process
	d->lastBufferSize = 0;
	d->fInvFactTempo = 1.0f - d->factTemporal;
	d->bTracking = false;	// flag for doing detection or tracking
	d->bodyDataFlags = 0;
}

CTrackMgr::~CTrackMgr(void){
	delete d;
}

bool CTrackMgr::init()
{
	//TrackMgrConfig config = {1, 1, 0, GR_MOTION_EXT_1};
	MobiGRConfig configGR = {GR_MOTION_EXT_1};

	char* licData = 0;
	{
		if(!Util::fileExists(LIC_FILEPATH)) goto fail;
		long flen = Util::getFileLen(LIC_FILEPATH);
		if(flen<0) goto fail;
		Logger::info(L"lic len=%d", flen);
		licData = new char[flen+1];
		if(!Util::loadData(LIC_FILEPATH, licData, flen)) goto fail;
		licData[flen] = 0;
		//Logger::info("lic data=%s", licData);
	}

	//d->gr = NULL;
	//Logger::info(L"create mobigr");
	//d->gr = CreateMobiGR();
	//if(!d->gr) Logger::info(L"create mobigr fail!");
	//Logger::info(L"init mobigr");
	//int res = d->gr->Initialize(licData);
	//Logger::info(L"init mobigr end, ret=%d", res);

	//d->tkMgr = CreateMobiTrackMgr();
	d->tkMgr = CreateMobiHEART();
	if(!d->tkMgr) goto fail;
	d->tkMgr->Initialize(licData);
	int retVal = d->tkMgr->SetGRConfig(configGR);
	if(retVal!=MOBI_SUCCEED) goto fail;

	bool flip = true;
	int iRet = d->tkMgr->SetImgFormat(VIDEO_W*3, VIDEO_H, VIDEO_W, MOBI_CM_RGB, flip);
	Logger::info("Set trackMgr format: %d, %d, flip=%d, ret=%d", VIDEO_W, VIDEO_H, flip, iRet);
	if(iRet!=MOBI_SUCCEED) goto fail;

	d->bInited = true;
	return true;

fail:
	//if(d->gr) ReleaseMobiGR(&d->gr);
	//if(d->tkMgr) ReleaseMobiTrackMgr(&d->tkMgr);
	if(d->tkMgr) ReleaseMobiHEART(&d->tkMgr);
	return false;
}

void CTrackMgr::uninit()
{
	//if(d->gr){
	//	ReleaseMobiGR(&d->gr);
	//	d->gr = NULL;
	//}

	if (d->tkMgr){
		//ReleaseMobiTrackMgr(&d->tkMgr);
		ReleaseMobiHEART(&d->tkMgr);
		d->tkMgr = NULL;
	}
}

bool CTrackMgr::process( const void* pBuffer, int bufferSize, MobiGestureMode gesMode )
{
	if(!d->bInited) return false;
	if(d->bPaused) return false;

	if(bufferSize!=1440000 && bufferSize!=d->lastBufferSize){
		Logger::debug("bufferSize change: %s -> %d", d->lastBufferSize, bufferSize);
		d->lastBufferSize = bufferSize;
	}

	int ret;
	{
		//TrackMgrConfig tmConfig = {1,1,0,gesMode};
		//d->tkMgr->SetConfig(tmConfig);
		MobiGRConfig tmConfig = {gesMode};
		d->tkMgr->SetGRConfig(tmConfig);

		int nBody;
		//[out] flag: 0, body; 1, palm
		//MobiGesPalm gesPalm;
		__try
		{
			//ret = d->tkMgr->ProcessFrame(pBuffer, bufferSize, nBody, &d->body, d->htRes.face, d->htRes.lHand, d->htRes.rHand, d->gesBody, gesPalm, d->flag);
			ret = d->tkMgr->ProcessFrame(pBuffer, bufferSize, nBody, &d->body, &d->gesBody);
			d->flag = 0;
			if(ret==MOBI_SUCCEED){
				Logger::debug(L"Got_gesture %d\n", d->gesBody.gestureCode);
			}
		}
		__except(EXCEPTION_EXECUTE_HANDLER){
			Logger::error(L"Something bad happens in ProcessFrame!\n");
			ret = MOBI_SUCCEED+1;
		}
		d->hasModel = ( MOBI_SUCCEED == ret );
		if(d->hasModel){
			bool bAssert = (d->flag==0 || d->flag==1);
			if(!bAssert){
				Logger::warn("ProcessFrame return 0 but flag=%d\n", d->flag);
			}
		}
	}

	//smooth torso/hands
	if (d->hasModel)
	{
		if(d->flag==eTIU_Body){
			d->bodyDisplay = d->body;
			if (d->bTracking)
			{
				//smooth body/torso position
				d->body.nodeTorso.x = d->body.nodeTorso.x*d->factTemporal + d->bodyLast.nodeTorso.x *d->fInvFactTempo;
				d->body.nodeTorso.y = d->body.nodeTorso.y*d->factTemporal + d->bodyLast.nodeTorso.y *d->fInvFactTempo;
				d->body.nodeTorso.z = d->body.nodeTorso.z*d->factTemporal + d->bodyLast.nodeTorso.z *d->fInvFactTempo;

				d->body.face.x = d->body.face.x*d->factTemporal + d->bodyLast.face.x *d->fInvFactTempo;
				d->body.face.y = d->body.face.y*d->factTemporal + d->bodyLast.face.y *d->fInvFactTempo;
				d->body.face.z = d->body.face.z*d->factTemporal + d->bodyLast.face.z *d->fInvFactTempo;

				//smooth hands position
				if ( abs(d->body.handL.node.x-d->bodyLast.handL.node.x)<d->body.handL.node.z
					&& abs(d->body.handL.node.y-d->bodyLast.handL.node.y)<d->body.handL.node.z )
				{
					d->body.handL.node.x = d->body.handL.node.x *0.45f + d->bodyLast.handL.node.x *0.55f;
					d->body.handL.node.y = d->body.handL.node.y *0.45f + d->bodyLast.handL.node.y *0.55f;
					d->body.handL.node.z = d->body.handL.node.z *0.45f + d->bodyLast.handL.node.z *0.55f;
				}
				if ( abs(d->body.handR.node.x-d->bodyLast.handR.node.x)<d->body.handR.node.z
					&& abs(d->body.handR.node.y-d->bodyLast.handR.node.y)<d->body.handR.node.z )
				{
					d->body.handR.node.x = d->body.handR.node.x *0.45f + d->bodyLast.handR.node.x *0.55f;
					d->body.handR.node.y = d->body.handR.node.y *0.45f + d->bodyLast.handR.node.y *0.55f;
					d->body.handR.node.z = d->body.handR.node.z *0.45f + d->bodyLast.handR.node.z *0.55f;
				}
			}
			else
			{
				d->bTracking = true;	//first frame for smooth body/torso/hands
			}
			d->bodyLast = d->body;
		}
	}
	else
	{
		d->bTracking = false;
		static int oldRet=-1;
		if(ret!=oldRet){
			oldRet = ret;
			Logger::debug("ProcessFrame fail = %d", ret);
		}
	}

	return d->hasModel;
}

int CTrackMgr::getGesture( MobiGesture &ges )
{
	if(d->hasModel){
		ges = d->gesBody;
		return d->gesBody.gestureCode;
	}else{
		return gesUndefined;
	}
}

//void CTrackMgr::setFlip(bool flip)
//{
//	if(!d->bInited) return;
//	int iRet = d->tkMgr->SetImgFormat(VIDEO_W*3, VIDEO_H, VIDEO_W, MOBI_CM_RGB, flip);
//	Logger::info("Set trackMgr format: %d, %d, flip=%d, ret=%d", VIDEO_W, VIDEO_H, flip, iRet);
//}

void CTrackMgr::display_result( const void* pBuffer )
{
	if(hasBody()){
		display_body(pBuffer);
	}
	if(hasHands()){
		display_hands(pBuffer);
	}
}

//#define PT(p) cvCircle(img, p, 10, CV_RGB(255, 0, 0), 10)
//#define LINE(p1, p2) cvLine(img, p1, p2, CV_RGB(255, 255, 0), line_thickness)
#define PT(p) pts.push_back(p)
#define LINE(p1, p2) 	lines.push_back(pair<CvPoint, CvPoint>(p1, p2));
//display body rect on image
void CTrackMgr::display_body( const void* pBuffer ){
	if(!d->hasModel) return;

	int line_thickness = VIDEO_W/200+1;
	int circle_radius = VIDEO_W/80+1;

	//draw lines
	static IplImage *img = 0;
	if(img==0){
		img = cvCreateImageHeader(cvSize(VIDEO_W, VIDEO_H), IPL_DEPTH_8U, 3);
	}
	int step = VIDEO_W*3;
	cvSetImageData(img, (char*)pBuffer, step);
	MobiBody &body = d->bodyDisplay;

	//draw skeletal
	CvPoint p1, p2;
	using std::vector;
	vector<CvPoint> pts;
	typedef pair<CvPoint, CvPoint> LineType;
	vector<LineType> lines;

	p1.x = body.nodeRoot.x;
	p1.y = VIDEO_H-1-body.nodeRoot.y;
	PT(p1);

	p2.x = body.nodeUpBody.x;
	p2.y = VIDEO_H-1-body.nodeUpBody.y;
	PT(p2);
	LINE(p1, p2);

	p1.x = body.nodeShoulderL.x;
	p1.y = VIDEO_H-1-body.nodeShoulderL.y;
	PT(p1);
	LINE(p1, p2);

	p1.x = body.nodeShoulderR.x;
	p1.y = VIDEO_H-1-body.nodeShoulderR.y;
	PT(p1);
	LINE(p1, p2);

	p1.x = body.nodeNeck.x;
	p1.y = VIDEO_H-1-body.nodeNeck.y;
	PT(p1);
	LINE(p1, p2);

	p2.x = body.face.x;
	p2.y = VIDEO_H-1-body.face.y;
	PT(p2);
	LINE(p1, p2);

	//left upper arm
	p1.x = body.nodeShoulderL.x;
	p1.y = VIDEO_H-1-body.nodeShoulderL.y;
	p2.x = body.nodeElbowL.x;
	p2.y = VIDEO_H-1-body.nodeElbowL.y;
	PT(p2);
	LINE(p1, p2);

	//left forearm
	p1.x = body.handL.node.x;
	p1.y = VIDEO_H-1-body.handL.node.y;
	PT(p1);
	LINE(p1, p2);

	//right upper arm
	p1.x = body.nodeShoulderR.x;
	p1.y = VIDEO_H-1-body.nodeShoulderR.y;
	p2.x = body.nodeElbowR.x;
	p2.y = VIDEO_H-1-body.nodeElbowR.y;
	PT(p2);
	LINE(p1, p2);

	//right forearm
	p1.x = body.handR.node.x;
	p1.y = VIDEO_H-1-body.handR.node.y;
	PT(p1);
	LINE(p1, p2);

	////left leg
	//p1.x = body.nodeRoot.x;
	//p1.y = VIDEO_H-1-body.nodeRoot.y;
	//p2.x = body.nodeFootL.x;
	//p2.y = VIDEO_H-1-body.nodeFootL.y;
	//PT(p2);
	//LINE(p1, p2);

	////right leg
	//p1.x = body.nodeRoot.x;
	//p1.y = VIDEO_H-1-body.nodeRoot.y;
	//p2.x = body.nodeFootR.x;
	//p2.y = VIDEO_H-1-body.nodeFootR.y;
	//PT(p2);
	//LINE(p1, p2);

	for(size_t i=0; i<lines.size(); ++i){
		LineType line = lines[i];
		cvLine(img, line.first, line.second, CV_RGB(255, 255, 0), line_thickness);
	}
	for(size_t i=0; i<pts.size(); ++i){
		cvCircle(img, pts[i], circle_radius, CV_RGB(255, 0, 0), circle_radius);
	}
}

void CTrackMgr::display_hands( const void* pBuffer )
{
	int line_thickness = VIDEO_W/200+1;
	int circle_radius = VIDEO_W/80+1;

	//draw lines
	static IplImage *img = 0;
	if(img==0){
		img = cvCreateImageHeader(cvSize(VIDEO_W, VIDEO_H), IPL_DEPTH_8U, 3);
	}
	int step = VIDEO_W*3;
	cvSetImageData(img, (char*)pBuffer, step);

	//draw face, hands
	CvPoint p1, p2;
	using std::vector;
	vector<CvPoint> pts;
	typedef pair<CvPoint, CvPoint> LineType;
	vector<LineType> lines;

	//face
	MobiFace &face = d->htRes.face;
	p1.x = face.rectFace.xMin;
	p1.y = VIDEO_H-1-face.rectFace.yMin;
	p2.x = face.rectFace.xMax;
	p2.y = VIDEO_H-1-face.rectFace.yMax;
	cvRectangle(img, p1, p2, CV_RGB(255, 255, 0), 3);

	//left
	MobiHand &left = d->htRes.lHand;
	p1.x = left.rect.xMin;
	p1.y = VIDEO_H-1-left.rect.yMin;
	p2.x = left.rect.xMax;
	p2.y = VIDEO_H-1-left.rect.yMax;
	cvRectangle(img, p1, p2, CV_RGB(0, 0, 255), 2);

	//right
	MobiHand &right = d->htRes.rHand;
	p1.x = right.rect.xMin;
	p1.y = VIDEO_H-1-right.rect.yMin;
	p2.x = right.rect.xMax;
	p2.y = VIDEO_H-1-right.rect.yMax;
	cvRectangle(img, p1, p2, CV_RGB(0, 255, 0), 2);
}

int CTrackMgr::getBodyDataStr( char* buf, int len )
{
	if(d->hasModel==false) return 1;
	if(!d->bodyDataFlags){
		if(len<80) return 2;
		int copied = _snprintf_s(buf, len, _TRUNCATE,
			"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", 
			(int)d->body.nodeRoot.x, (int)d->body.nodeRoot.y,
			(int)d->body.nodeUpBody.x, (int)d->body.nodeUpBody.y,
			(int)d->body.nodeShoulderL.x, (int)d->body.nodeShoulderL.y,
			(int)d->body.nodeShoulderR.x, (int)d->body.nodeShoulderR.y,
			(int)d->body.nodeNeck.x, (int)d->body.nodeNeck.y,
			(int)d->body.face.x, (int)d->body.face.y,
			(int)d->body.nodeElbowL.x, (int)d->body.nodeElbowL.y,
			(int)d->body.handL.node.x, (int)d->body.handL.node.y,
			(int)d->body.nodeElbowR.x, (int)d->body.nodeElbowR.y,
			(int)d->body.handR.node.x, (int)d->body.handR.node.y
			);
		if(copied==-1) return 3; //truncated
	}else{
		if(len<240) return 2;
		int copied = _snprintf_s(buf, len, _TRUNCATE,
			"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" /*10 points for body*/
			",%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d" /*6 points for feet*/
			",%d,%d,%1.3f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", /*1 size for right palm, 11 points for fingers*/
			//body part
			(int)d->body.nodeRoot.x, (int)d->body.nodeRoot.y,
			(int)d->body.nodeUpBody.x, (int)d->body.nodeUpBody.y,
			(int)d->body.nodeShoulderL.x, (int)d->body.nodeShoulderL.y,
			(int)d->body.nodeShoulderR.x, (int)d->body.nodeShoulderR.y,
			(int)d->body.nodeNeck.x, (int)d->body.nodeNeck.y,
			(int)d->body.face.x, (int)d->body.face.y,
			(int)d->body.nodeElbowL.x, (int)d->body.nodeElbowL.y,
			(int)d->body.handL.node.x, (int)d->body.handL.node.y,
			(int)d->body.nodeElbowR.x, (int)d->body.nodeElbowR.y,
			(int)d->body.handR.node.x, (int)d->body.handR.node.y,
			//feet part: L(hip, knee, foot), R(hip, knee, foot)
			(int)d->body.nodeHipL.x, (int)d->body.nodeHipL.y,
			(int)d->body.nodeKneeL.x, (int)d->body.nodeKneeL.y,
			(int)d->body.nodeFootL.x, (int)d->body.nodeFootL.y,
			(int)d->body.nodeHipR.x, (int)d->body.nodeHipR.y,
			(int)d->body.nodeKneeR.x, (int)d->body.nodeKneeR.y,
			(int)d->body.nodeFootR.x, (int)d->body.nodeFootR.y,
			//palm and fingers part: point palm, double palmSize, line thumb, line index, line middle, line ring, line little.
			(int)d->body.handR.node.x, (int)d->body.handR.node.y,
			(float)d->body.handR.fingers.palmSize,
			(int)d->body.handR.fingers.rootThumb.x, (int)d->body.handR.fingers.rootThumb.y,
			(int)d->body.handR.fingers.tipThumb.x, (int)d->body.handR.fingers.tipThumb.y,
			(int)d->body.handR.fingers.rootIndex.x, (int)d->body.handR.fingers.rootIndex.y,
			(int)d->body.handR.fingers.tipIndex.x, (int)d->body.handR.fingers.tipIndex.y,
			(int)d->body.handR.fingers.rootMiddle.x, (int)d->body.handR.fingers.rootMiddle.y,
			(int)d->body.handR.fingers.tipMiddle.x, (int)d->body.handR.fingers.tipMiddle.y,
			(int)d->body.handR.fingers.rootIndex.x, (int)d->body.handR.fingers.rootIndex.y,
			(int)d->body.handR.fingers.tipIndex.x, (int)d->body.handR.fingers.tipIndex.y,
			(int)d->body.handR.fingers.rootLittle.x, (int)d->body.handR.fingers.rootLittle.y,
			(int)d->body.handR.fingers.tipLittle.x, (int)d->body.handR.fingers.tipLittle.y
			);
		if(copied==-1) return 3; //truncated
	}
	return 0;
}

//bool CTrackMgr::acceptVideo( int w, int h )
//{
//	if( (w==800 && h==600) || (w==640 &&  h==480)  || (w==320 &&  h==240) ){
//		return true;
//	}else{
//		return false;
//	}
//}

int CTrackMgr::GetAllModes( MobiGestureMode* &modes ){
	//if(d->gr){
	//	return d->gr->GetAllModes(modes);
	if(d->tkMgr){
		return d->tkMgr->GetGRModes(modes);
	}else{
		return 0;
	}
}

char* CTrackMgr::GetModeName( MobiGestureMode mode ){
	//if(d->gr){
	//	return d->gr->GetModeName(mode);
	if(d->tkMgr){
		return d->tkMgr->GetGRModeName(mode);
	}else{
		return NULL;
	}
}

int CTrackMgr::GetAllGestures( MobiGestureEvent* &event ){
	//if(d->gr){
	//	return d->gr->GetAllGestures(event);
	if(d->tkMgr){
		return d->tkMgr->GetGRGestures(event);
	}else{
		return 0;
	}
}

char* CTrackMgr::GetGestureName( MobiGestureEvent gesEvent ){
	//if(d->gr){
	//	return d->gr->GetGestureName(gesEvent);
	if(d->tkMgr){
		return d->tkMgr->GetGRGestureName(gesEvent);
	}else{
		return NULL;
	}
}

bool CTrackMgr::hasModel()
{
	return d->hasModel;
}

bool CTrackMgr::hasBody()
{
	return d->hasModel && d->flag==eTIU_Body;
}

bool CTrackMgr::hasHands()
{
	return d->hasModel && d->flag==eTIU_Palm;
}

const MobiBody* CTrackMgr::getBodyPtr()
{
	return &d->body;
}

const HtResult* CTrackMgr::getHandsPtr()
{
	return &d->htRes;
}

int CTrackMgr::getSilhouette( void* const pBuffer, const int widthStep, const int height )
{
	int width = widthStep;
	return d->tkMgr->GetSilhouette(pBuffer, widthStep*height, width, height, widthStep);
}

void CTrackMgr::enableFullData( int iEnable )
{
	//Logger::error(L"Kevin: enableFullData(%d) called.", iEnable);

	d->bodyDataFlags = iEnable;
	//test finger bit (1)
	d->tkMgr->EnableFingers( (iEnable&1)?true:false );
	Logger::error(L"Kevin: EnableFingers(%d) called.", (iEnable&1)?true:false);

	//test legs bit (2)
	d->tkMgr->EnableLegs( (iEnable&2)?true:false );
	Logger::error(L"Kevin: EnableLegs(%d) called.", (iEnable&2)?true:false);
}
#pragma warning(pop)
