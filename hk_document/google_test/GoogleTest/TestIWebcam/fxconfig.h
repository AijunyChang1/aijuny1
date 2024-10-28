//********************************************
//Tri.Tran									 *	
//tri.tran@fix8.com							 *
//2007-10-13     							 *
//********************************************

/* thread support through Microsoft threads. */
#define HAVE_MS_THREAD 1
/* XML support through Microsoft XML. */
#define HAVE_MS_XML 1	
/* thread support */
#define HAVE_THREAD 1
/* Version number*/
#define VERSION "1.0.0"

typedef __int64 int64_t;

#ifdef WIN32
#pragma warning(disable : 4250 4251 4786 4290)
#endif

#ifdef MOBINEX_UTIL
	#define MOBINEX_UTIL_EXPORT __declspec(dllexport)
#else
	#define MOBINEX_UTIL_EXPORT 
#endif
#define _WIN32_WINNT 0x0400
