/* Copyright (c) 2009 Mobinex Inc. All right reserved. */

#ifndef MobiCommon_Header
#define MobiCommon_Header

#ifndef SVN_ID
#define SVN_ID $Revision$
#endif

#ifdef MOBIDLL
	#ifdef MOBIDLL_EXPORTS
		#define MOBIAPI __declspec( dllexport )
	#else
		#define MOBIAPI __declspec( dllimport )
	#endif
#else
	#define MOBIAPI
#endif

#ifdef MOBITRACKER
	#ifdef MOBITRACKER_EXPORTS
		#define MOBITRACKERAPI __declspec( dllexport )
	#else
		#define MOBITRACKERAPI __declspec( dllimport )
	#endif
#else
	#define MOBITRACKERAPI
#endif

/* Define NULL pointer value */
#ifndef NULL
	#ifdef  __cplusplus
		#define NULL    0
	#else
		#define NULL    ((void *)0)
	#endif
#endif

// error definition
#define MOBI_SUCCEED			0	// succeed
#define MOBI_DETECT_FAIL		1	// detection fail
#define MOBI_NO_FACE			2	// no face can be found
#define MOBI_BAD_IMAGE			3	// input image quality is bad
#define MOBI_BIG_ANGLE_X		4	// angle x of face is big
#define MOBI_BIG_ANGLE_Y		5	// angle y of face is big
#define MOBI_BIG_ANGLE_Z		6	// angle z of face is big
#define MOBI_BIG_FACE			7	// face size is too big
#define MOBI_SMALL_FACE			8	// face size is too small
#define MOBI_CLOSE_TO_EDGE		9	// face is close to the image edge
#define MOBI_TRACK_FAIL			10	// track face failed
#define MOBI_OUT_OF_MEMORY		11	// out of memory
#define MOBI_INVALID_ARG		12	// invalid input argument
#define MOBI_NOT_IMPLEMENTED	13	// not implemented
#define MOBI_FILE_NOT_FOUND		14	// file not found
#define MOBI_INVALID_LICENSE	15	// invalid license

//image color mode
#define MOBI_CM_GREY	0		//8 bits gray scale image
#define MOBI_CM_RGB		1		//24 bits rgb color image
#define MOBI_CM_RGBA	2		//32 bits rgba color image

// typedef
// integer rectangle in an image
typedef struct _MobiRect
{ 
	int 	xMin;			/* x position top-left corner */
	int 	yMin;			/* y position top-left corner */
	int 	xMax;			/* x position bottom-right corner */
	int 	yMax;			/* y position bottom-right corner */
} MobiRect;

// node (feature point)
typedef struct _MobiNode
{
	float	x;				/* x position */
	float	y;				/* y position */
	float	z;				/* z position, future use */
	int		id;				/* node ID */
	float	confidence;		/* confidence value */
} MobiNode;

// face, defined by the middle point of two pupils, eye distance and the pose information
typedef struct _MobiFace
{
	MobiRect	rectFace;			// rect area of face
	MobiNode	nodeLP;				// node of left pupil
	MobiNode	nodeRP;				// node of right pupil
	float		x;					// x position
	float		y;					// y position
	float		eyeDistance;		// distance of two pupils
	float		confidence;			// confidence value
	float		pose[3];			// euler angles: angleX, angleY, angleZ, future use
} MobiFace;

#endif //MobiCommon_Header
