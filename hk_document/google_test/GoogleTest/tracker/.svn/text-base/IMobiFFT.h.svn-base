//
// IMobiFFT.h
// $Id: IMobiFFT.h 14798 2009-04-23 07:38:57Z raphael.ko $
// Copyright (c) 2009 Mobinex Inc. All right reserved.
//

#ifndef IMobiFFT_Header
#define IMobiFFT_Header

#include "MobiCommon.h"

//tracking mode
#define FFT_26	0
#define FFT_22	1
#define FFT_15	2
#define FFT_8	3

//facial feature points number
#define NUM_FFT_26	26	//output 26 facial feature points

//face pose properties number
#define NUM_POSE_6	6	//size of face pose array

// index of all nodes (26 feature points)
#define NODE_LP			0		// left pupil
#define NODE_RP			1		// right pupil
#define NODE_LBC		2		// left brow center
#define NODE_LBI		3		// left brow inner
#define NODE_LECO		4		// left eye corner outer
#define NODE_LECI		5		// left eye corner inner
#define NODE_LELU		6		// left eye lid upper
#define NODE_LELL		7		// left eye lid lower
#define NODE_LNS		8		// left nose side
#define NODE_LNT		9		// left nostril
#define NODE_LMC		10		// left mouth corner
#define NODE_LUL		11		// left upper lip
#define NODE_LLL		12		// left lower lip
#define NODE_RBC		13		// right brow center
#define NODE_RBI		14		// right brow inner
#define NODE_RECO		15		// right eye corner outer
#define NODE_RECI		16		// right eye corner inner
#define NODE_RELU		17		// right eye lid upper
#define NODE_RELL		18		// right eye lid lower
#define NODE_RNS		19		// right nose side
#define NODE_RNT		20		// right nostril
#define NODE_RMC		21		// right mouth corner
#define NODE_RUL		22		// right upper lip
#define NODE_RLL		23		// right lower lip
#define NODE_ULC		24		// upper lip center
#define NODE_LLC		25		// lower lip center

// expression number
#define NUM_EXPRESSION		18		// number of expressions

// Expression index
#define EX_E_CLOSE_SYM		0		// EX1 - Symmetric eye close
#define EX_E_CLOSE_R		1		// EX2 - Right eye close
#define EX_E_CLOSE_L		2		// EX3 - Left eye close
#define EX_E_OPEN_SYM		3		// EX4 - Symmetric wide eye open
#define EX_B_RAISE_SYM		4		// EX5 - Symmetric eyebrow raise
#define EX_B_RAISE_R		5		// EX6 - Right eyebrow raise
#define EX_B_RAISE_L		6		// EX7 - Left eyebrow raise
#define EX_B_FURROW_SYM		7		// EX8 - Symmetric eyebrow furrow
#define EX_M_AH				8		// EX9 - Ah-shape mouth open
#define EX_M_DIS			9		// EX10 - Disgusted mouth shape
#define EX_M_DOWN			10		// EX11 - Downward displacement of the mouth
#define EX_M_OH				11		// EX12 - Oh-shaped mouth
#define EX_M_EH				12		// EX13 - Eh-shaped mouth
#define EX_M_CLOSE_SMILE	13		// EX14 - Mouth-closed smile
#define EX_M_OPEN_SMILE		14		// EX15 - Mouth-open smile
#define EX_M_FROWN			15		// EX16 - Frown mouth shape
#define EX_M_PULL_RIGHT		16		// EX17 - Pull of the right mouth corner
#define EX_M_PULL_LEFT		17		// EX18 - Pull of the left mouth corner

//FFT configuration struct
typedef struct Mobi_FFT_Config
{
	int		modeFFT;
	float	confidenceT;	//confidence threshold, range 0 - 1.0f
}FFTConfig;

// interface class for facial feature detection/tracking
class IMobiFFT
{
public:
	// Initialize
	virtual int Initialize( const char* sLicense = 0 )=0;

	//Set Image Format
	virtual int SetImgFormat(
		int widthStep,			//width step of image data in bytes
		int height,				//image height, default: 240
		int width,				//image width, default: 320
		int colorMode,			//color mode, default: MOBI_CM_RGB
		bool origin=false		//indicate the origin of image, false: top-left, true: bottom-left (windows bitmap style)
		)=0;

	//Set/Get FFT Config
	virtual int SetConfig(const FFTConfig &config)=0;	//fd configurations
	virtual void GetConfig(FFTConfig &config)=0;

	//track facial features
	virtual int Detect(
		const void* bitmapPtr,		//input image data buffer
		int bufferSize,				//size of image data buffer in bytes
		const MobiFace& face,		//face data in the image
		MobiNode* fFeaturePoints,	// [o] allocated buffer to store the feature position data
		float* fFacePose			// [o] 6 components: position x, y, z (scale), angle x, y, z
		)=0;

	//track facial features
	virtual int Track(
		const void* bitmapPtr,		//input image data buffer
		int bufferSize,				//size of image data buffer in bytes
		MobiNode* fFeaturePoints,	// [o] allocated buffer to store the feature position data
		float* fFacePose,			// [o] 6 components: position x, y, z (scale), angle x, y, z
		int &iWarnings				// warning information
		)=0;

	// mapping expression
	virtual bool DoMapping(	float* fExpressions)=0;		// [o] returned 18 expression values

};

MOBIAPI IMobiFFT* CreateMobiFFT();			// create IMobiFFT instance
MOBIAPI void ReleaseMobiFFT(IMobiFFT** p);	// release IMobiFFT instance

#endif	// end IMobiFFT head file
