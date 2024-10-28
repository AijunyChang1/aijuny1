#include <string>
//#include "ishow-engine.h"

#ifndef _SINA_ISHOW
#define _SINA_ISHOW 5000
#endif

/////////////////////////////////////////////////////////////////////////////
// CAboutDlg dialog used for App About
//#define STRING_COUNT 16;

//using namespace iShowEngine;
using namespace std;

long TestInt[]={0,-1,1, 10000000,-10000000};
double  TestFloat[]={0, -1,1,0.1,-0.1,2.0, 1000000.1, -1000000.1, 0.0000001,-0.000001};

char* TestStringA[]={
					//NULL,                
					 " ", 
					 "a",
  				     "1", 
					 "\\",
					 "\?",
					 "'",
					 "\"",
					 ";",
					 "!\"@#$%^&*(){}\?:><",
					 "abc",
					 "123",
					 "023",
					 "abc123",
					 "",
  				     "12123234421 fsafsa fdsafdsa fdsafdsa fsdafdafa fsdaffsa fdsaf 12123234421 fsafsa fdsafdsa fdsafdsa fsdafdafa fsdaffsa fdsa 12123234421 fsafsa fdsafdsa fdsafdsa fsdafdafa fsdaffsa fdsa ffdddf"
                    };
wchar_t* TestStringW[]={
						//NULL,
                         
						L" ",
						L"a",
						L"1", 
						L"\\",
						L"\?",
						L"'",
						L"\"",
						L";",
						L"!\"@#$%^&*(){}\?:><",
						L"abc",
						L"123",
						L"023",
						L"abc123",
						L"",
						L"12123234421 fsafsa fdsafdsa fdsafdsa fsdafdafa fsdaffsa fdsaf 12123234421 fsafsa fdsafdsa fdsafdsa fsdafdafa fsdaffsa fdsa 12123234421 fsafsa fdsafdsa fdsafdsa fsdafdafa fsdaffsa fdsa ffdddf" 
					 };

//string ReturnValuetoStr(RETURN_VALUE EValue)

 bool suc;
 HWND hWndF;
 HWND hWndRender;
 IWebcam* WebcamIns=NULL;

 BITMAPINFO* m_pBmpInfo;
 BITMAPINFO* m_pBmpInfoSil;
 CVdoFrameHandler* frame_handlerL;

 CWnd RDialog;
 CFXStcImage stcBufferPreview;
 CFXStcImage stcBufferSil;
 CRect rc,rcSil;
 bool EndProgram;
 FILE* fp ;


 //IMobiHEART* pMobiHeart;
 /*
 int numBody;
 MobiBody arrBody;
 MobiGesture ArrGesture;
 */

/*
const char* ReturnValuetoStr(int EValue)
{
	switch (EValue)
	{
	case RET_OK: return "RET_OK"; break;
	case RET_FAILED: return "RET_FAILED"; break;
	case RET_NOT_INIT: return "RET_NOT_INIT"; break;
	case RET_FORMAT_NOT_SUPPORT: return "RET_FORMAT_NOT_SUPPORT"; break;
	case RET_BUFFER_INVALID: return "RET_BUFFER_INVALID"; break;
	case RET_CONTENT_INVALID: return "RET_CONTENT_INVALID";break;
	case RET_CONTENT_NOT_AVAILABLE: return "RET_CONTENT_NOT_AVAILABLE"; break;
	case RET_FUNCTION_NOT_SUPPORT: return "RET_FUNCTION_NOT_SUPPORT"; break;
	default:  return "Invalid return value" ;
	}
	
}

string SlotRendertoStr(int SlotValue)
{
	switch (SlotValue)
	{
	case SLOT_TOPDOWN_LEFT: return "SLOT_TOPDOWN_LEFT"; break; 
	case SLOT_TOPDOWN_RIGHT: return "SLOT_TOPDOWN_RIGHT"; break;
	case SLOT_BOTTOMUP_LEFT: return "SLOT_BOTTOMUP_LEFT"; break;
	case SLOT_BOTTOMUP_RIGHT: return "SLOT_BOTTOMUP_RIGHT"; break; 
	case SLOT_TOP_LEFTRIGHT: return "SLOT_TOP_LEFTRIGHT"; break;  
	case SLOT_TOP_RIGHTLEFT: return "SLOT_TOP_RIGHTLEFT"; break;
	case SLOT_BOTTOM_LEFTRIGHT: return "SLOT_BOTTOM_LEFTRIGHT"; break;
	case SLOT_BOTTOM_RIGHTLEFT: return "SLOT_BOTTOM_RIGHTLEFT"; break;
	default: return "Invalid Slot Render Value";
	}
}

*/
void PrintTrace(int line,const char* FuncName,const char* expected,const char* actual)
{
//	char*str=new char[1000];
	printf("%d,   %s,   %s,   %s\n", line, FuncName,expected, actual);
//	delete str;
//	str=NULL;
}

void Fail(const char* FuncName,const char* Param, int line,int exp, int act)
{
	fprintf(fp,"line: %d,  Function %s  return failed. Expected return:%d. Actual Return:%d.  param:%s \n", line, FuncName,exp,act, Param);
	suc=false;
}

void Faila(const char* FuncName, int line)
{
	printf("  Function %s failed at line: %d, \n",FuncName, line);
	suc=false;

}
#define FAIL_L(funcName,Param,exp, act) Fail(funcName,Param, __LINE__,exp, act)
#define FAILA_L(funcName) Faila(funcName, __LINE__)

/*
bool CheckRetVal(int ret){
	switch (ret)
	{
	case RET_OK: return true;
	case RET_FAILED:  return true;
	case RET_NOT_INIT:  return true;
	case RET_FORMAT_NOT_SUPPORT:  return true;
	case RET_BUFFER_INVALID:  return true;
	case RET_CONTENT_INVALID:  return true;
	case RET_CONTENT_NOT_AVAILABLE:  return true;
	case RET_FUNCTION_NOT_SUPPORT:  return true;
	default: 
		printf("Invalid return value: %d", ret); 
		return false;
	}
}
*/
#define CHECK_RETVAL(ret, funcName)	\
	if(CheckRetVal(ret)==false){	\
		FAILA_L(funcName);				\
	}

#define ASSERT_VAL(exp,act, funcName, Param)		\
		if(false==((exp)==(act))){				\
			FAIL_L(funcName,Param,exp, act);				\
		}

#define ASIZE(a) sizeof(a)/sizeof(a[0])
const int STRING_COUNT=ASIZE(TestStringW);
const int FLOAT_COUNT=ASIZE(TestFloat);
const int FLOAT_INT=ASIZE(TestInt);

/*
#define TEST_L(module,func)								\
	if(test_##module##_##func##(pIShow)){					\
	printf("\nTest " #func ": succeess.\nEnd testing for "#func"\n\n");	\
	}else{										\
	printf("\nTest " #func ": fail.\nEnd testing for " #func"\n\n");		\
	}
	*/

#define TEST_L(module,func)	\
{  \
	fprintf(fp, "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n\n"); \
	fprintf(fp, "\\\\\\\\\\Module: " #module"    Function: "#func"\\\\\\\\\\\\\\\n\n"); \
	if(test_##module##_##func##()){					\
	fprintf(fp,"\nTest " #func "(): pass.\nEnd testing for "#func"\n\n");	\
	printf("\nTest " #func "(): pass.\nEnd testing for "#func"\n\n");	\
	}else{										\
	fprintf(fp,"\nTest " #func "(): fail.\nEnd testing for " #func"\n\n");		\
	printf("\nTest " #func "(): fail.\nEnd testing for " #func"\n\n");		\
	}    \
	fprintf(fp, "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\n\n"); \
	fprintf(fp,"\n\n\n");  \
}



int MakeBMPHeader()
{	
	DWORD  dwBitmapInfoSize;
	int m_iImageSize;
	m_pBmpInfo				            = NULL;
	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER) ;  // + /*(m_iImageBitCount==8?256:1)*/256 * sizeof( RGBQUAD );
	m_pBmpInfo							= (BITMAPINFO *)new BYTE [dwBitmapInfoSize];


    m_iImageSize						= 320*240*(24>>3);
//	m_iImageSize						= 320*240;
//	BYTE* m_pImageBytes						= new BYTE[m_iImageSize];
//	memset(m_pImageBytes, 0, m_iImageSize);

	ZeroMemory( m_pBmpInfo, dwBitmapInfoSize );
	m_pBmpInfo->bmiHeader.biSize			= sizeof(BITMAPINFOHEADER);
	m_pBmpInfo->bmiHeader.biWidth			= 320;
	m_pBmpInfo->bmiHeader.biHeight			= 240;
	m_pBmpInfo->bmiHeader.biPlanes			= 1;
	m_pBmpInfo->bmiHeader.biBitCount		= 24;
//	m_pBmpInfo->bmiHeader.biBitCount		= 8;
	m_pBmpInfo->bmiHeader.biCompression	    = BI_RGB;
	m_pBmpInfo->bmiHeader.biSizeImage		= m_iImageSize;
	m_pBmpInfo->bmiHeader.biXPelsPerMeter	= 0;
	m_pBmpInfo->bmiHeader.biYPelsPerMeter	= 0;
	m_pBmpInfo->bmiHeader.biClrUsed		    = 256;//256 /*m_iImageBitCount == 8?256:0*/;
	m_pBmpInfo->bmiHeader.biClrImportant	= 0;
/*
	if (m_iImageBitCount == 8) {
		// Fill in the color table

		for( int Index = 0; Index < 256; ++Index ) {  
			m_pBmpInfo->bmiColors[Index].rgbBlue = Index;  
			m_pBmpInfo->bmiColors[Index].rgbGreen = Index;  
			m_pBmpInfo->bmiColors[Index].rgbRed = Index;  
		}

	}
	*/

	return 0;
}

int MakeBMPHeader1()
{	
	DWORD  dwBitmapInfoSize;
	int m_iImageSize;
	m_pBmpInfoSil				        = NULL;
	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER) + /*(m_iImageBitCount==8?256:1)*/2 * sizeof( RGBQUAD );
	m_pBmpInfoSil							= (BITMAPINFO *)new BYTE [dwBitmapInfoSize];


    m_iImageSize						= 320*240*(24>>3);
//	m_iImageSize						= 240*180;
//	m_pImageBytes1						= new BYTE[m_iImageSize];
//	memset(m_pImageBytes1, 0, m_iImageSize);

	ZeroMemory( m_pBmpInfoSil, dwBitmapInfoSize );
	m_pBmpInfoSil->bmiHeader.biSize			= sizeof(BITMAPINFOHEADER);
	m_pBmpInfoSil->bmiHeader.biWidth			= 320;
	m_pBmpInfoSil->bmiHeader.biHeight			= 240;
	m_pBmpInfoSil->bmiHeader.biPlanes			= 1;
//	m_pBmpInfo->bmiHeader.biBitCount		= 24;
	m_pBmpInfoSil->bmiHeader.biBitCount		= 8;
	m_pBmpInfoSil->bmiHeader.biCompression	    = BI_RGB;
	m_pBmpInfoSil->bmiHeader.biSizeImage		= m_iImageSize;
//	m_pBmpInfoSil->bmiHeader.biSizeImage		= 0;
	m_pBmpInfoSil->bmiHeader.biXPelsPerMeter	= 0;
	m_pBmpInfoSil->bmiHeader.biYPelsPerMeter	= 0;
	m_pBmpInfoSil->bmiHeader.biClrUsed		    = 0;//256 /*m_iImageBitCount == 8?256:0*/;
	m_pBmpInfoSil->bmiHeader.biClrImportant	= 0;


	m_pBmpInfoSil->bmiColors[1].rgbBlue =200;  
	m_pBmpInfoSil->bmiColors[1].rgbGreen =200;  
	m_pBmpInfoSil->bmiColors[1].rgbRed =220; 
	m_pBmpInfoSil->bmiColors[1].rgbReserved=0;

	m_pBmpInfoSil->bmiColors[0].rgbBlue = 100;  
	m_pBmpInfoSil->bmiColors[0].rgbGreen =100;  
	m_pBmpInfoSil->bmiColors[0].rgbRed =100; 
	m_pBmpInfoSil->bmiColors[0].rgbReserved=255;

	/*
		m_pBmpInfoSil->bmiColors[2].rgbBlue = 60;  
	m_pBmpInfoSil->bmiColors[2].rgbGreen =60;  
	m_pBmpInfoSil->bmiColors[2].rgbRed =60; 
	m_pBmpInfoSil->bmiColors[2].rgbReserved=255;
	*/

	//if (m_iImageBitCount == 8) {
		// Fill in the color table
/*
		for( int Index = 0; Index < 256; ++Index ) { 

			m_pBmpInfoSil->bmiColors[Index].rgbBlue = Index;  
			m_pBmpInfoSil->bmiColors[Index].rgbGreen = Index;  
			m_pBmpInfoSil->bmiColors[Index].rgbRed = Index; 
			m_pBmpInfoSil->bmiColors[Index].rgbReserved=0;

		}
	//}
*/

	return 0;
}





class CMyFrameHandler: public CVdoFrameHandler
{
 void VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize);
};




INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{

		/*
			if ((WebcamIns)&&(hDlg==hWndF))
			{
			ReleaseWebcam(&WebcamIns);
			WebcamIns=NULL;
			}
			*/

			EndDialog(hDlg, LOWORD(wParam));

			return (INT_PTR)TRUE;
		}
		break;

	case WM_PAINT:
		if(hDlg==hWndRender)
		{
		 return true;
		}
		break;


	//	SendMessage(GetDlgItem(hWndRender,IDC_STATIC1),WM_PAINT,wParam,lParam);
/*
    case WM_ERASEBKGND:
		if(hDlg==hWndRender)
		{
	    HDC hdc =GetWindowDC(hWndRender); 
		stcBufferPreview.GetWindowRect(&rc);
		ScreenToClient(GetDlgItem(hWndRender,IDC_STATIC1),(LPPOINT)&rc);
		ExcludeClipRect(hdc,rc.left,rc.top,rc.right,rc.bottom);
 //       ReleaseDC(hWndRender,hdc);
		}
		return false;


    	break;
		*/
	case WM_DESTROY:
		hWndRender=NULL;


	}
	
	
	return (INT_PTR)FALSE;
}





DWORD WINAPI ThreadProc( LPVOID lpParameter )
{
   MSG msg;

	hWndF=(HWND)CreateDialog(NULL, MAKEINTRESOURCE(IDD_DIALOG1), 0, About);
	ShowWindow(hWndF,SW_SHOW);
	UpdateWindow(hWndF);
	CWnd a;
	a.Attach(hWndF);
	a.ModifyStyle(0,WS_CLIPCHILDREN|WS_CLIPSIBLINGS);



	hWndRender=(HWND)CreateDialog(NULL, MAKEINTRESOURCE(IDD_DIALOG2), 0, About);
	ShowWindow(hWndRender,SW_SHOW);
	UpdateWindow(hWndRender);


   while (GetMessage (&msg, NULL, 0, 0))
   {
     if((hWndF == 0 || !IsDialogMessage (hWndF, &msg))&&(hWndRender== 0 || !IsDialogMessage (hWndRender, &msg)))
     { 
 
		TranslateMessage(&msg);
        DispatchMessage(&msg);
 
    }
    Sleep(15);
  }
  

	return 0;
}

void StartWebcam()
{

	HANDLE hThread;
	DWORD dwThreadId;

	MakeBMPHeader();
	MakeBMPHeader1();
	
	EndProgram=false;
	hThread = CreateThread(
		 NULL,    
		 NULL,    
		 ThreadProc,   //线程入口地址(执行线程的函数)
		 NULL,         //传给函数的参数
		 0,            //指定线程立即执行
		 &dwThreadId   //返回线程的ID号
		 );
	printf("Now another thread has been Created,ID:%d\n\n\nInitialize OK. Start testing...\n\n",dwThreadId);
    Sleep(1000);
	stcBufferPreview.Attach(GetDlgItem(hWndRender,IDC_STATIC1));
    stcBufferPreview.SetImageFormat(320, 240, 24);
	stcBufferPreview.SetWindowPos(NULL, 0, 0, 320, 240, SWP_NOMOVE | SWP_NOZORDER|SWP_NOACTIVATE);
    stcBufferPreview.ModifyStyle(0, WS_CLIPCHILDREN|WS_CLIPSIBLINGS);
    stcBufferSil.Attach(GetDlgItem(hWndRender,IDC_STATIC2));
    stcBufferSil.SetImageFormat(320, 240, 8);
	stcBufferSil.SetWindowPos(NULL, 0, 0, 320, 240, SWP_NOMOVE | SWP_NOZORDER|SWP_NOACTIVATE);
	stcBufferSil.ModifyStyle(0, WS_CLIPCHILDREN|WS_CLIPSIBLINGS);
	RDialog.Attach(hWndRender);
	WebcamIns=CreateWebcam();

	CVdoFrameHandler* frame_handlerL;
	frame_handlerL=new CMyFrameHandler();
	WebcamIns->start(hWndF,frame_handlerL);


}

void ExitTesting()
{

	EndProgram=true;

	Sleep(100);
    
	if(m_pBmpInfo)
	{
		delete[] m_pBmpInfo;
		m_pBmpInfo=NULL;
	}

	if(m_pBmpInfoSil)
	{
		delete[] m_pBmpInfoSil;
		m_pBmpInfoSil=NULL;
	
	}

	if(frame_handlerL)
	{
	delete frame_handlerL;
	frame_handlerL=NULL;
	
	}
	if (WebcamIns)
	{
	WebcamIns->stop();
    ReleaseWebcam(&WebcamIns);
    WebcamIns=NULL;
	}
  

}