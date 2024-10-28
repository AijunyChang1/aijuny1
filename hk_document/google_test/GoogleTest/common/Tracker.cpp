#include "StdAfx.h"
#include "Tracker.h"

#include "KeyMapper.h"
#include "Settings.h"
#include "Util.h"

#include "math.h"
#include <vector>

#define LIC_FILEPATH L"teli.lic"
//#define TEST_LIC "licensor = Mobinex Inc.;licensee = ;software = MFTE SDK;hostid = 0;expires = NEVER;platform = WIN32;signature = 6EBBE41A2CEDCD1586E7601FBB54FFC423BAE2870341D384B8105CF86A164C7014DDA15D2A8EE229B5CB3D55962FBB0E823EE1283641BA39920560AA485C69F84CADA78DF1F8A8BA014F21346CA1E2A4B161A6D59F46E27EDFC1A289D5CCD79124F4C980D8F5D9038936E82EDBB9992217F4B99FA53824B48444F39F831F227FFCE22032C633AF07D93379E604C7BC201A364BB41A400A3FAC5D21DAD6E68AB9A8BEB2193C326EF8A48EFAD7F383E2134D5BF16E9F1CA2A2B21FF4ECBF1A6B6EB7241537A3CF7AAA1ECA3DAEE37F2E197F98385CCF972B887A969FC0345330D738020139FA8AC2DF98C26883DA6F94669F3E5774965A0D4A5026D313A0AB659B;"
//#define TEST_LIC "licensor = Mobinex Inc.;licensee = BesTV;software = MBTE SDK;hostid = af751e83;expires = 20100515;platform = WIN32;signature = 8D742A2270045BD914E9DEBAD3A36A48BF05783C5185D4A02E9D40D7A827149BF609117548170D04DC57A80A537A2DE8B4C931BDDAA0A4A4E00FFBFC284176DB23F5D6DFB8B852A4DDBBAEEC27CCD1294E576925732B20C715765EC75CB17138CC3FA20E74004CB7853694E909315EF582C044159D48F41FA9494310E33D6E18FB362C497255F66B9B4BC10FF3CB3B33BAF9B7FC2C78A4E4FDD12C66465D24A16EE66E7EA900B884DF002769F91DC02712B6B9E3F268F988D84A42D211602D937B22F29C4E7BD60FCDB2211FC8EBDC6113F614402E6D9738D313F1226DD7C7DC80D72F36B90488F3A22028E19CC675DE2B4B26D0BCDF649189DC4EFB52BF42C4;"

#pragma warning(push)
#pragma warning(disable: 4244)
CTracker::CTracker(void)
{
	//m_fd = NULL;
	//m_fft = NULL;
	m_bt = NULL;
	m_Ges = NULL;
	m_hasBody = false;
	m_factTemporal = 0.4f;
	
	m_bPaused = false;
}

CTracker::~CTracker(void)
{
}

bool CTracker::init()
{
	MobiBTConfig config = {1, 1};

	char* licData = 0;
	if(!m_bt) goto fail;
	{
		if(!Util::fileExists(LIC_FILEPATH)) goto fail;
		long flen = Util::getFileLen(LIC_FILEPATH);
		if(flen<0) goto fail;
		licData = new char[flen];
		if(!Util::loadData(LIC_FILEPATH, licData, flen)) goto fail;
	}


	m_bt = CreateMobiBT();
	m_bt->Initialize(licData);
	int retVal = m_bt->SetConfig(config);
	if(retVal!=MOBI_SUCCEED) goto fail;

	m_Ges = CreateMobiGR();
	if(!m_Ges) goto fail;
	m_Ges->Initialize(licData);
	MobiGRConfig grConfig;
	grConfig.modeGR = GR_MOTION;
	retVal = m_Ges->SetConfig(grConfig);
	if(retVal!=MOBI_SUCCEED) goto fail;

	return true;

fail:
	//if(m_fd) ReleaseMobiFD(&m_fd);
	//if(m_fft) ReleaseMobiFFT(&m_fft);
	if(m_bt) ReleaseMobiBT(&m_bt);
	if(m_Ges) ReleaseMobiGR(&m_Ges);
	return false;
}

void CTracker::uninit()
{
	if (m_bt){
		ReleaseMobiBT(&m_bt);
		m_bt = NULL;
	}

	if (m_Ges){
		ReleaseMobiGR(&m_Ges);
		m_Ges = NULL;
	}
}

bool CTracker::process( const void* pBuffer, int bufferSize, int* hand )
{
	if(m_bPaused) return false;

	int nBody;
	int ret;

	static int lastBufferSize = 0;
	if(bufferSize!=1440000 && bufferSize!=lastBufferSize){
		Logger::info("bufferSize change: %d -> %d!", lastBufferSize, bufferSize);
		lastBufferSize = bufferSize;
	}

	if (!m_hasBody){
		ret = m_bt->InitBody(pBuffer, bufferSize, nBody, &m_body);
	}else{
		ret = m_bt->ProcessFrame(pBuffer, bufferSize, 1, &m_body);
	}
	m_hasBody = ( MOBI_SUCCEED == ret );

	//smooth torso/hands
	//temporal factor for smooth torso
	static float fInvFactTempo = 1.0f - m_factTemporal;
	static bool bTracking = false;	// flag for doing detection or tracking
	if (m_hasBody)
	{
		m_bodyDisplay = m_body;
		if (bTracking)
		{
			//smooth body/torso position
			m_body.nodeTorso.x = m_body.nodeTorso.x*m_factTemporal + m_bodyLast.nodeTorso.x *fInvFactTempo;
			m_body.nodeTorso.y = m_body.nodeTorso.y*m_factTemporal + m_bodyLast.nodeTorso.y *fInvFactTempo;
			m_body.nodeTorso.z = m_body.nodeTorso.z*m_factTemporal + m_bodyLast.nodeTorso.z *fInvFactTempo;

			m_body.face.x = m_body.face.x*m_factTemporal + m_bodyLast.face.x *fInvFactTempo;
			m_body.face.y = m_body.face.y*m_factTemporal + m_bodyLast.face.y *fInvFactTempo;
			m_body.face.z = m_body.face.z*m_factTemporal + m_bodyLast.face.z *fInvFactTempo;

			//smooth hands position
			if ( abs(m_body.handL.node.x-m_bodyLast.handL.node.x)<m_body.handL.node.z
				&& abs(m_body.handL.node.y-m_bodyLast.handL.node.y)<m_body.handL.node.z )
			{
				m_body.handL.node.x = m_body.handL.node.x *0.45f + m_bodyLast.handL.node.x *0.55f;
				m_body.handL.node.y = m_body.handL.node.y *0.45f + m_bodyLast.handL.node.y *0.55f;
				m_body.handL.node.z = m_body.handL.node.z *0.45f + m_bodyLast.handL.node.z *0.55f;
			}
			if ( abs(m_body.handR.node.x-m_bodyLast.handR.node.x)<m_body.handR.node.z
				&& abs(m_body.handR.node.y-m_bodyLast.handR.node.y)<m_body.handR.node.z )
			{
				m_body.handR.node.x = m_body.handR.node.x *0.45f + m_bodyLast.handR.node.x *0.55f;
				m_body.handR.node.y = m_body.handR.node.y *0.45f + m_bodyLast.handR.node.y *0.55f;
				m_body.handR.node.z = m_body.handR.node.z *0.45f + m_bodyLast.handR.node.z *0.55f;
			}
		}
		else
		{
			bTracking = true;	//first frame for smooth body/torso/hands
		}
	}
	else
	{
		bTracking = false;
		static int oldRet=-1;
		if(ret!=oldRet){
			oldRet = ret;
			Logger::debug("body fail = %d", ret);
		}
	}
	m_bodyLast = m_body;

	return m_hasBody;
}

void CTracker::setFlip(bool flip)
{
	int iRet = m_bt->SetImgFormat(VIDEO_W*3, VIDEO_H, VIDEO_W, MOBI_CM_RGB, flip);
	Logger::info("Set bt format: %d, %d, flip=%d, ret=%d", VIDEO_W, VIDEO_H, flip, iRet);
}

//////////////////////////////////////////////////////////////////////////
int CTracker::handEvents(MobiGestureMode mode)
{	
	MobiGRConfig grConfig;
	grConfig.modeGR = mode;
	m_Ges->SetConfig(grConfig);

	m_Ges->RecogGesture(m_body, m_gestureResult);

	return m_gestureResult.gestureCode;	
}


int CTracker::faceCompare( int mode, int &ret, float &sim, char* nameFace )
{
#if 1
	return m_bt->FaceComparison(mode, ret, sim, nameFace);
#else
	//do face comparison
	static bool bStartCompare = false;
	static int numFrameCompare = 0;
	int faceState = -1;
	float similarity = 0;
	char strNameFace[256];
	char msgFace1[256];
	if (m_hasBody && !bStartCompare)
	{
		//compare
		m_bt->FaceComparison(1, faceState, similarity, strNameFace);

		switch(faceState)
		{						
		case 1:		//frontal face got
			sprintf(msgFace1, "Now open your mouth, please.");
			break;
		case 2:		//mouth-open got
			sprintf(msgFace1, "Now close your mouth, please.");
			break;
		case 3:		//mouth-close got
			sprintf(msgFace1, "Finished.");
			break;
		default:	//-1: face not detected
			break;
		}

		if(faceState == 3)	//automatic show statistics
		{
			sprintf(msgFace1, "\tMatched ID: %s\n\tConfidence Level: %d%%\n", strNameFace, int(similarity*100));
			bStartCompare = true;

			if (similarity<0.8)
			{
				sprintf(strNameFace, "TEST0");
				m_bt->FaceComparison(2, faceState, similarity, strNameFace);	//save to database
			}
		}

		++numFrameCompare;
	}
	return 0;
#endif
}

int CTracker::checkFace(){
	int faceState = -1;
	m_bt->FaceComparison(1, faceState, m_fc_sim, m_fc_name);

	Logger::log("fastState = %d, similarity of %s = %f, ", faceState, m_fc_name, m_fc_sim);

	return faceState;
}

void CTracker::saveFace( const char* name ){
	int faceState;
	m_bt->FaceComparison(2, faceState, m_fc_sim, (char*)name);
}

void CTracker::getFaceCenter( int &x, int &y ){
	x = (int)m_body.face.x;
	y = (int)m_body.face.y;
}

//#define PT(p) cvCircle(img, p, 10, CV_RGB(255, 0, 0), 10)
//#define LINE(p1, p2) cvLine(img, p1, p2, CV_RGB(255, 255, 0), line_thickness)
#define PT(p) pts.push_back(p)
#define LINE(p1, p2) 	lines.push_back(pair<CvPoint, CvPoint>(p1, p2));
//display body rect on image
void CTracker::display_body( const void* pBuffer ){
	if(!m_hasBody) return;

	int line_thickness = VIDEO_W/200+1;
	int circle_radius = VIDEO_W/80+1;

	//draw lines
	static IplImage *img = 0;
	if(img==0){
		img = cvCreateImageHeader(cvSize(VIDEO_W, VIDEO_H), IPL_DEPTH_8U, 3);
	}
	int step = VIDEO_W*3;
	cvSetImageData(img, (char*)pBuffer, step);
	MobiBody &body = m_bodyDisplay;

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

	for(size_t i=0; i<lines.size(); ++i){
		LineType line = lines[i];
		cvLine(img, line.first, line.second, CV_RGB(255, 255, 0), line_thickness);
	}
	for(size_t i=0; i<pts.size(); ++i){
		cvCircle(img, pts[i], circle_radius, CV_RGB(255, 0, 0), circle_radius);
	}
}

void CTracker::display_body_yuv2( const void* pBuffer )
{
	if(!m_hasBody) return;

	int line_thickness = VIDEO_W/200+1;
	int circle_radius = VIDEO_W/80+1;

	//draw lines
	static IplImage *img = 0;
	if(img==0){
		img = cvCreateImageHeader(cvSize(VIDEO_W, VIDEO_H), IPL_DEPTH_8U, 2);
	}
	int step = VIDEO_W*2;
	cvSetImageData(img, (char*)pBuffer, step);
	MobiBody &body = m_bodyDisplay;

	//draw skeletal
	CvPoint p1, p2;
	using std::vector;
	vector<CvPoint> pts;
	typedef pair<CvPoint, CvPoint> LineType;
	vector<LineType> lines;

	p1.x = body.nodeRoot.x;
	p1.y = body.nodeRoot.y;//VIDEO_H-1-
	pts.push_back(p1);

	p2.x = body.nodeUpBody.x;
	p2.y = body.nodeUpBody.y;//VIDEO_H-1-
	PT(p2);
	LINE(p1, p2);

	p1.x = body.nodeShoulderL.x;
	p1.y = body.nodeShoulderL.y;//VIDEO_H-1-
	PT(p1);
	LINE(p1, p2);

	p1.x = body.nodeShoulderR.x;
	p1.y = body.nodeShoulderR.y;//VIDEO_H-1-
	PT(p1);
	LINE(p1, p2);

	p1.x = body.nodeNeck.x;
	p1.y = body.nodeNeck.y;//VIDEO_H-1-
	PT(p1);
	LINE(p1, p2);

	p2.x = body.face.x;
	p2.y = body.face.y;//VIDEO_H-1-
	PT(p2);
	LINE(p1, p2);

	//left upper arm
	p1.x = body.nodeShoulderL.x;
	p1.y = body.nodeShoulderL.y;//VIDEO_H-1-
	p2.x = body.nodeElbowL.x;
	p2.y = body.nodeElbowL.y;//VIDEO_H-1-
	PT(p2);
	LINE(p1, p2);

	//left forearm
	p1.x = body.handL.node.x;
	p1.y = body.handL.node.y;//VIDEO_H-1-
	PT(p1);
	LINE(p1, p2);

	//right upper arm
	p1.x = body.nodeShoulderR.x;
	p1.y = body.nodeShoulderR.y;//VIDEO_H-1-
	p2.x = body.nodeElbowR.x;
	p2.y = body.nodeElbowR.y;//VIDEO_H-1-
	PT(p2);
	LINE(p1, p2);

	//right forearm
	p1.x = body.handR.node.x;
	p1.y = body.handR.node.y;//VIDEO_H-1-
	PT(p1);
	LINE(p1, p2);

	//make a YUY2 RED color
	CvScalar yuvRed = CV_RGB(255, 255, 0);
	CvScalar yuvGreen = CV_RGB(255, 80, 0);
	
	for(size_t i=0; i<lines.size(); ++i){
		LineType line = lines[i];
		cvLine(img, line.first, line.second, yuvGreen, line_thickness);
	}
	for(size_t i=0; i<pts.size(); ++i){
		cvCircle(img, pts[i], circle_radius, yuvRed, circle_radius);
	}
}

int CTracker::getBodyDataStr( char* buf, int len )
{
	if(m_hasBody==false) return 1;
	if(len<80) return 2;
	int copied = _snprintf_s(buf, len, _TRUNCATE,
		"%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d", 
		(int)m_body.nodeRoot.x, (int)m_body.nodeRoot.y,
		(int)m_body.nodeUpBody.x, (int)m_body.nodeUpBody.y,
		(int)m_body.nodeShoulderL.x, (int)m_body.nodeShoulderL.y,
		(int)m_body.nodeShoulderR.x, (int)m_body.nodeShoulderR.y,
		(int)m_body.nodeNeck.x, (int)m_body.nodeNeck.y,
		(int)m_body.face.x, (int)m_body.face.y,
		(int)m_body.nodeElbowL.x, (int)m_body.nodeElbowL.y,
		(int)m_body.handL.node.x, (int)m_body.handL.node.y,
		(int)m_body.nodeElbowR.x, (int)m_body.nodeElbowR.y,
		(int)m_body.handR.node.x, (int)m_body.handR.node.y
		);
	if(copied==-1) return 3; //truncated
	return 0;
}

bool CTracker::acceptVideo( int w, int h )
{
	if( (w==800 && h==600) || (w==640 &&  h==480)  || (w==320 &&  h==240) ){
		return true;
	}else{
		return false;
	}
}

void CTracker::onChangeToFilter( int w, int h )
{
	if(acceptVideo(w, h)){
		if( w!=VIDEO_W || h!=VIDEO_H ){
			Logger::info("Set BT format 3: %d, %d", w, h);
			m_bt->SetImgFormat(w*3, h, w, MOBI_CM_RGB);
			FILTER_VIDEO_W = w;
			FILTER_VIDEO_H = h;
		}
		m_bPaused = false;
	}else{
		m_bPaused = true;
	}
}

void CTracker::onBackToDShow()
{
	m_bPaused = false;
	//if( FILTER_VIDEO_W!=VIDEO_W || FILTER_VIDEO_H!=VIDEO_H ){
	//	Logger::info("Set BT format 4: %d, %d", VIDEO_W, VIDEO_H);
	//	m_bt->SetImgFormat(VIDEO_W*3, VIDEO_H, VIDEO_W, MOBI_CM_RGB, true);
	//}
}

int CTracker::GetAllModes( MobiGestureMode* &modes ){
	if(m_Ges){
		return m_Ges->GetAllModes(modes);
	}else{
		return 0;
	}
}

char* CTracker::GetModeName( MobiGestureMode mode ){
	if(m_Ges){
		return m_Ges->GetModeName(mode);
	}else{
		return NULL;
	}
}

int CTracker::GetAllGestures( MobiGestureEvent* &event ){
	if(m_Ges){
		return m_Ges->GetAllGestures(event);
	}else{
		return 0;
	}
}

char* CTracker::GetGestureName( MobiGestureEvent gesEvent ){
	if(m_Ges){
		return m_Ges->GetGestureName(gesEvent);
	}else{
		return NULL;
	}
}
#pragma warning(pop)
