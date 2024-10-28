// TestIWebcam.cpp : Defines the entry point for the console application.
#include "stdafx.h"
#include <limits.h>
#include "IWebcam.h"
#include <gtest.h>
#include "resource.h"
#include <iostream>
#include <atlbase.h>
#include "FXStcImage.h"
#include "cv.h"
#include "highgui.h"
#include "IMobiGR.h"
#include "IMobiHEART.h"


using namespace std;


HWND hWndF;
HWND hWndRender;
IWebcam* WebcamIns;
IMobiHEART* MobiHeart;
IMobiGR* MobiGR;
CFXStcImage stcBufferPreview;
CFXStcImage stcBufferSil;
//HWND stcBufferPreview;
IplImage *scaled;
BITMAPINFO* m_pBmpInfo;
BITMAPINFO* m_pBmpInfo1;
BITMAPINFO* m_pBmpInfoSil;
BYTE* m_pImageBytes;
BYTE* m_pImageBytes1;
CWnd RDialog;
CRect rc,rcSil;
BYTE * pBuffer1;

int numBody;
MobiBody arrBody;
MobiGesture ArrGesture;




INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam);
DWORD WINAPI ThreadProc( LPVOID lpParameter );

int MakeBMPHeader()
{	
	DWORD  dwBitmapInfoSize;
	int m_iImageSize;
	m_pBmpInfo				            = NULL;
	m_pImageBytes                 = NULL;
	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER) ;  // + /*(m_iImageBitCount==8?256:1)*/256 * sizeof( RGBQUAD );
//	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER);
	m_pBmpInfo							= (BITMAPINFO *)new BYTE [dwBitmapInfoSize];


    m_iImageSize						= 320*240*(24>>3);
//	m_iImageSize						= 320*240;
//	m_pImageBytes						= new BYTE[m_iImageSize];
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

	//if (m_iImageBitCount == 8) {
		// Fill in the color table
	/*
		for( int Index = 0; Index < 256; ++Index ) {  
			m_pBmpInfo->bmiColors[Index].rgbBlue = Index;  
			m_pBmpInfo->bmiColors[Index].rgbGreen = Index;  
			m_pBmpInfo->bmiColors[Index].rgbRed = Index;  
		}
		*/
	//}

	return 0;
}

int MakeBMPHeader1()
{	
	DWORD  dwBitmapInfoSize;
	int m_iImageSize;
	m_pBmpInfoSil				        = NULL;
	m_pImageBytes                       = NULL;
	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER) + /*(m_iImageBitCount==8?256:1)*/2 * sizeof( RGBQUAD );
//	dwBitmapInfoSize					= sizeof(BITMAPINFOHEADER);
	m_pBmpInfoSil							= (BITMAPINFO *)new BYTE [dwBitmapInfoSize];


    m_iImageSize						= 320*240*(24>>3);
//	m_iImageSize						= 240*180;
//	m_pImageBytes1						= new BYTE[m_iImageSize];
//	memset(m_pImageBytes1, 0, m_iImageSize);

	ZeroMemory( m_pBmpInfoSil, dwBitmapInfoSize );
	m_pBmpInfoSil->bmiHeader.biSize			= sizeof(BITMAPINFOHEADER);
//	m_pBmpInfo->bmiHeader.biSize			= 40;
	m_pBmpInfoSil->bmiHeader.biWidth			= 320;
	m_pBmpInfoSil->bmiHeader.biHeight			= 240;
	m_pBmpInfoSil->bmiHeader.biPlanes			= 1;
//	m_pBmpInfo->bmiHeader.biBitCount		= 24;
	m_pBmpInfoSil->bmiHeader.biBitCount		= 8;
	m_pBmpInfoSil->bmiHeader.biCompression	    = BI_RGB;
//	m_pBmpInfoSil->bmiHeader.biCompression	    = 0;
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

void CMyFrameHandler::VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize)
{

	CPaintDC dc(&stcBufferPreview); // device context for painting
	CPaintDC dcSil(&stcBufferSil);

	GetClientRect(GetDlgItem(hWndRender,IDC_STATIC1),&rc);
	GetClientRect(GetDlgItem(hWndRender,IDC_STATIC),&rcSil);

	RDialog.Invalidate(false);

	if((pBuffer != NULL) &&(MobiHeart!=NULL))
	{
		dc.RealizePalette();
        dcSil.RealizePalette();
		SetStretchBltMode(dc.GetSafeHdc(), COLORONCOLOR);
        SetStretchBltMode(dcSil.GetSafeHdc(), COLORONCOLOR);
	    EXPECT_NO_THROW(MobiHeart->ProcessFrame(pBuffer,lBufferSize,numBody, &arrBody, &ArrGesture));
		EXPECT_NO_THROW(MobiHeart->GetSilhouette(pBuffer1,320*240,320, 240, 320));
//		EXPECT_NO_THROW(MobiHeart->GetSilhouette(pBuffer1,240*180,240, 180, 240));

		int nResult = ::StretchDIBits(
			dc.GetSafeHdc(),
			rc.left,
			rc.top,
			rc.right - rc.left,
			rc.bottom - rc.top,
			0,
			0,
			320, 
			240,
			pBuffer, 
			m_pBmpInfo,
			DIB_RGB_COLORS ,
			SRCCOPY);
	
		


		int nResult1 = ::StretchDIBits(
			dcSil.GetSafeHdc(),
			rcSil.left,
			rcSil.top,
			rcSil.right - rcSil.left,
			rcSil.bottom - rcSil.top,
			0,
			240,
			320, 
			-240,
			pBuffer1, 
			m_pBmpInfoSil,
			//m_pBmpInfoSil,
			DIB_RGB_COLORS ,
			SRCCOPY);
			
	//     RDialog.Invalidate(false);
	 //  EXPECT_NO_THROW(MobiHeart->ProcessFrame(pBuffer,lBufferSize,numBody, &arrBody, &ArrGesture));

	   HPEN penFocus = ::CreatePen(PS_SOLID, 4, RGB(255,128,128));
	   HPEN hOldPen = (HPEN)SelectObject(dc.GetSafeHdc(),penFocus);
	   SelectObject(dc.GetSafeHdc(),GetStockObject(NULL_BRUSH));

	   Ellipse(dc.GetSafeHdc(),arrBody.face.x*(rc.right - rc.left)/320-3,arrBody.face.y*(rc.bottom - rc.top)/240+3,arrBody.face.x*(rc.right - rc.left)/320+3,arrBody.face.y*(rc.bottom - rc.top)/240-3);
       Ellipse(dc.GetSafeHdc(),arrBody.nodeNeck.x-3,arrBody.nodeNeck.y+3,arrBody.nodeNeck.x+3,arrBody.nodeNeck.y-3);
	   Ellipse(dc.GetSafeHdc(),arrBody.nodeUpBody.x-3,arrBody.nodeUpBody.y+3,arrBody.nodeUpBody.x+3,arrBody.nodeUpBody.y-3);



	   	SelectObject(dc.GetSafeHdc(),hOldPen);
    	DeleteObject(penFocus);




	}

	dc.ReleaseOutputDC();
	dcSil.ReleaseOutputDC();





//	stcBufferPreview.ShowImage(pBuffer);	

//	stcBufferPreview.Invalidate(FALSE);
/*
	rc.left=0; rc.top=0;
	rc.right=1 ; rc.bottom=1;
	::InvalidateRect(hWndRender, &rc, true);
 
	::PostMessage(hWndRender,WM_ERASEBKGND,0,0);
	*/

//	printf("%ld\n", lBufferSize);
//	printf("%f\n",dblSampleTime);
//	scaled->imageData=(char*)pBuffer;
 /*
    memcpy(scaled->imageData, pBuffer, lBufferSize);

	scaled->imageSize=lBufferSize;

	cvShowImage("Capture", scaled);
	*/



}



class FullTest:public testing::Test 
{ 

public:
    IWebcam* WebcamInsL;
    HWND hWndFL;
	CVdoFrameHandler* frame_handlerL;
	int width;
	int height;
	int frames;
	IMobiGR* pMobiGR;

	FullTest()
	{
//	hWndF=hWnd;
	} 
    virtual ~FullTest() 
	{
		if(WebcamInsL)
		{
		//	WebcamInsL->stop();
            WebcamInsL=0;
		}
	
	} 
  
    //如果构造、析构还不能满足你，还有下面两个虚拟函数 
    virtual void SetUp() 
	{ 

        hWndFL=hWndF;
		frame_handlerL=new CMyFrameHandler();
		WebcamInsL=WebcamIns;

       /*
        WebcamIns=CreateWebcam();
		*/
	    EXPECT_NO_THROW(WebcamIns->start(hWndFL,frame_handlerL))<<"Testing: Start exception.";
	//	EXPECT_NO_THROW(WebcamIns->start(NULL,frame_handlerL))<<"Testing: Start exception.";
	//	EXPECT_ANY_THROW(WebcamIns->start(hWndFL,frame_handlerL));
		EXPECT_NO_THROW(pMobiGR=CreateMobiGR())<<"Testing: Create Mobi Gesture Recognization exception.";
		MobiGR=pMobiGR;


 
    } 
  
    virtual void TearDown() 
	{ 
//     	EXPECT_NO_THROW(ReleaseMobiGR(&pMobiGR))<<"Testing: Release Mobi Gesture Recognization exception.";
//		EXPECT_NO_THROW(ReleaseMobiHEART(&MobiHeart))<<"Testing: Release Mobi Heart.";
	
	}   // 在析构前调用 
}; 


/*
int aa(int a)
{
 return a;
}
*/


TEST_F(FullTest, StartStop)  
{ 

	EXPECT_EQ(true,WebcamInsL->started() )<<L"Testing: Start Fail!!!"; 
	EXPECT_NO_THROW(WebcamInsL->stop())<<"Testing: Stop webcam throws the exception."; 
	EXPECT_EQ(false,WebcamInsL->started() )<<"Testing: Stop funcion has problem, has not stopped actually."; 
	EXPECT_NO_THROW(WebcamIns->start(hWndFL,frame_handlerL))<<"Testing: Start webcam throws the exception.";
//	EXPECT_NO_THROW(WebcamIns->start(NULL,frame_handlerL))<<"Testing: Start webcam throws the exception.";

}


TEST_F(FullTest, GetSize)  
{ 
   EXPECT_EQ(true,WebcamInsL->getFormat(width, height, frames));
   EXPECT_EQ(320,width);
   EXPECT_EQ(240,height);
   EXPECT_EQ(30,frames);
   width=640;
   height=480;
   frames=16;
   EXPECT_EQ(true,WebcamInsL->getFormat(width, height, frames));
   EXPECT_EQ(320,width);
   EXPECT_EQ(240,height);
   EXPECT_EQ(30,frames);
}

TEST_F(FullTest, GetWebcamName)  
{ 

  wchar_t* nameBuf;
  nameBuf=new wchar_t[256];
  int len=0;
  USES_CONVERSION;
   
   EXPECT_NE(0,WebcamInsL->getWebcamName(nameBuf,len))<<"Get webcam name failed.";
   printf("WebcamName: %s\n",W2A(nameBuf));
   EXPECT_NE(0,len)<<"Testing:Webcam Name length is incorrect.";

   delete[] nameBuf;
   cout<<"End testing for webcam========================================================\n";

}

TEST_F(FullTest, InitializeMobiGR)
{
	EXPECT_NE(MOBI_SUCCEED,pMobiGR->Initialize(""))<<"MobiGR initialize should not pass.";
	EXPECT_NE(MOBI_SUCCEED,pMobiGR->Initialize(NULL))<<"MobiGR initialize should not pass.";
	EXPECT_NE(MOBI_SUCCEED,pMobiGR->Initialize(" "))<<"MobiGR initialize should not pass.";
	EXPECT_NE(MOBI_SUCCEED,pMobiGR->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;"))<<"Testing:MobiGR initialize should not pass.";
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;"))<<"Testing error: Initialize MobiGR failed!!!";
}

TEST_F(FullTest, SetConfigMobiGR)
{
	MobiGRConfig LConfig;
	LConfig.modeGR=GR_STATUS;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Status format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_STATUS,LConfig.modeGR);

	LConfig.modeGR=GR_MOUSE;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Mouse format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MOUSE,LConfig.modeGR);

	LConfig.modeGR=GR_MOTION;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Motion format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MOTION,LConfig.modeGR);

    LConfig.modeGR=GR_SEPARATE;
    EXPECT_EQ(MOBI_NOT_IMPLEMENTED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Separate format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_NE(GR_SEPARATE,LConfig.modeGR);



	/////////////////Extention mode
	LConfig.modeGR=GR_MOTION_EXT_1;
    EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Extension motion1 format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MOTION_EXT_1,LConfig.modeGR);

	LConfig.modeGR=GR_MOTION_EXT_2;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Extension motion2 format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MOTION_EXT_2,LConfig.modeGR);

	LConfig.modeGR=GR_MOTION_EXT_3;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Extension motion3 format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MOTION_EXT_3,LConfig.modeGR);

	LConfig.modeGR=GR_COMBINE;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Combine format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_COMBINE,LConfig.modeGR)<<"Get Combine format failed.";

	LConfig.modeGR=GR_COMBINE_1;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Combine1 format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_COMBINE_1,LConfig.modeGR)<<"Get Combine1 format failed.";


	LConfig.modeGR=GR_COMBINE_2;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Combine2 format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_COMBINE_2,LConfig.modeGR)<<"Get Combine2 format failed.";

	
	LConfig.modeGR=GR_MEDIA_CENTER;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Media format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MEDIA_CENTER,LConfig.modeGR)<<"Get Media center format failed.";


	LConfig.modeGR=GR_SOLITAIRE;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Solitaire format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_SOLITAIRE,LConfig.modeGR)<<"Get SOLITAIRE format failed.";


	LConfig.modeGR=GR_GOOGLE_EARTH;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Google earth format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_GOOGLE_EARTH,LConfig.modeGR)<<"Get Google earth format failed.";


	LConfig.modeGR=GR_JOY_STICK;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Joy Stick format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_JOY_STICK,LConfig.modeGR)<<"Get Joy Stick format failed.";

	LConfig.modeGR=GR_TREASURE_HUNTER;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Treasure Hunter format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_TREASURE_HUNTER,LConfig.modeGR)<<"Get Treasure hunter format failed.";


	LConfig.modeGR=GR_MOTION_EXT_1;
	EXPECT_EQ(MOBI_SUCCEED,pMobiGR->SetConfig(LConfig))<<"MobiGR set Extension motion1 format failed.";
	pMobiGR->GetConfig(LConfig);
	EXPECT_EQ(GR_MOTION_EXT_1,LConfig.modeGR);

}

TEST_F(FullTest, GetAllModes)
{
    MobiGestureMode* AllModes;
	int num;
	num=pMobiGR->GetAllModes(AllModes);
	EXPECT_NE(0,num);
	if (num)
	{
		cout<<"Status num:"<<num<<'\n';
		for (int j=0; j<num; j++)
		{
			switch (AllModes[j]) 
			{
			case GR_STATUS: cout<<"Mode: GR_STATUS\n"; break;
			case GR_MOUSE: cout<<"Mode: GR_MOUSE\n";   break;
			case GR_MOTION: cout<<"Mode: GR_MOTION\n"; break;
			case GR_SEPARATE: cout<<"Mode: GR_SEPARATE\n"; break;
			case GR_MOTION_EXT_1: cout<<"Mode: GR_MOTION_EXT_1\n"; break;
			case GR_MOTION_EXT_2: cout<<"Mode: GR_MOTION_EXT_2\n"; break;
			case GR_MOTION_EXT_3: cout<<"Mode: GR_MOTION_EXT_3\n"; break;
			case GR_COMBINE: cout<<"Mode: GR_COMBINE\n"; break;
			case GR_COMBINE_1: cout<<"Mode: GR_COMBINE_1\n"; break;
            case GR_COMBINE_2: cout<<"Mode: GR_COMBINE_2\n"; break;
            case GR_MEDIA_CENTER: cout<<"Mode: GR_MEDIA_CENTER\n"; break;				
            case GR_SOLITAIRE: cout<<"Mode: GR_SOLITAIRE\n"; break;	
			case GR_GOOGLE_EARTH: cout<<"Mode: GR_GOOGLE_EARTH\n"; break;	
			case GR_JOY_STICK: cout<<"Mode: GR_JOY_STICK\n"; break;	
			case GR_TREASURE_HUNTER: cout<<"Mode: GR_TREASURE_HUNTER\n"; break;	
			default: FAIL() << "We shouldn't get here.";
			
			}
		
		}

//		Sleep(5000);
		
	}

}

TEST_F(FullTest, GetModeName)
{
  MobiGestureMode GestureMode;
  char* ModeName=NULL;
  for(int i=0;i<16;i++)
  {
	GestureMode=(MobiGestureMode)i;
    ModeName=pMobiGR->GetModeName(GestureMode);
    EXPECT_NE(NULL,(int)ModeName);
	cout<<i<<":"<<ModeName<<'\n';
  }

}

TEST_F(FullTest, GetAllEvents)
{
    MobiGestureEvent* AllEvents;
	int num=0;
	num=pMobiGR->GetAllGestures(AllEvents);
	EXPECT_NE(0,num);
	if (num)
	{
		cout<<"Gestures event num:"<<num<<" "<<AllEvents[0]<<'\n';
		for (int j=0; j<num; j++)
		{   
			EXPECT_EQ(j, AllEvents[j]+1);
			switch (AllEvents[j]) 
			{
			case gesUndefined: cout<<"Event: Undefine\n"; break;
			case gesNeutral: cout<<"Event: gesNeutral\n"; break;
			case gesL5R7: cout<<"Event: gesL5R7\n"; break;
			case gesL5R1: cout<<"Event: gesL5R1\n"; break;
			case gesL5R6: cout<<"Event: gesL5R6\n"; break;
			case gesL4R8: cout<<"Event: gesL4R8\n"; break;
			case gesL1R8: cout<<"Event: gesL1R8\n"; break;
			case gesL3R8: cout<<"Event: gesL3R8\n"; break;
			case gesL4R7: cout<<"Event: gesL4R7\n"; break;
			case gesL1R7: cout<<"Event: gesL1R7\n"; break;
			case gesL4R1: cout<<"Event: gesL4R1\n"; break;
            case gesL1R1: cout<<"Event: gesL1R1\n"; break;
            case gesL3R7: cout<<"Event: gesL3R7\n"; break;				
            case gesL3R1: cout<<"Event: gesL3R1\n"; break;	
			case gesL4R6: cout<<"Event: gesL4R6\n"; break;	
			case gesL1R6: cout<<"Event: gesL1R6\n"; break;	
			case gesL3R6: cout<<"Event: gesL3R6\n"; break;	
			case gesL1R2: cout<<"Event: gesL1R2\n"; break;	
			case gesL2R1: cout<<"Event: gesL2R1\n"; break;	
			case gesL2R6: cout<<"Event: gesL2R6\n"; break;
			case gesL2R7: cout<<"Event: gesL2R7\n"; break;
			case gesL3R2: cout<<"Event: gesL3R2\n"; break;
			case gesL4R2: cout<<"Event: gesL4R2\n"; break;
			case gesL5R2: cout<<"Event: gesL5R2\n"; break;

			case gesMouseMove: cout<<"Event: gesMouseMove\n"; break;
			case gesMouseClick: cout<<"Event: gesMouseClick\n"; break;
			case gesMouseDBClick: cout<<"Event: gesMouseDBClick\n"; break;
			case gesMouseLeftDown: cout<<"Event: gesMouseLeftDown\n"; break;

			case gesLeftLeft: cout<<"Event: gesLeftLeft\n"; break;
			case gesLeftRight: cout<<"Event: gesLeftRight\n"; break;
			case gesRightLeft: cout<<"Event: gesRightLeft\n"; break;
			case gesRightRight: cout<<"Event: gesRightRight\n"; break;
			case gesLeftUp: cout<<"Event: gesLeftUp\n"; break;
			case gesLeftDown: cout<<"Event: gesLeftDown\n"; break;
			case gesRightUp: cout<<"Event: gesRightUp\n"; break;
			case gesRightDown: cout<<"Event: gesRightDown\n"; break;
			case gesBothUp: cout<<"Event: gesBothUp\n"; break;
			case gesBothDown: cout<<"Event: gesBothDown\n"; break;
			case gesBodyLeft: cout<<"Event: gesBodyLeft\n"; break;
			case gesBodyRight: cout<<"Event: gesBodyRight\n"; break;

			case gesHandsFar: cout<<"Event: gesHandsFar\n"; break;
			case gesHandsClose: cout<<"Event: gesHandsClose\n"; break;

			case gesLeftRightFast: cout<<"Event: gesLeftRightFast\n"; break;
			case gesRightLeftFast: cout<<"Event: gesRightLeftFast\n"; break;
			case gesStopLeftFast: cout<<"Event:  gesStopLeftFast\n"; break;
			case gesStopRightFast: cout<<"Event: gesStopRightFast\n"; break;

			case gesLeftUpShift: cout<<"Event: gesLeftUpShift\n"; break;
			case gesRightUpShift: cout<<"Event:  gesRightUpShift\n"; break;
			case gesHeadTilt: cout<<"Event: gesHeadTilt\n"; break;
			case gesHandsMovingFront: cout<<"Event: gesHandsMovingFront\n"; break;
			case gesLeftLiftShift: cout<<"Event:  gesLeftLiftShift\n"; break;
			case gesRightLiftShift: cout<<"Event: gesRightLiftShift\n"; break;
			case gesHandsMovingBodyLeft: cout<<"Event: gesHandsMovingBodyLeft\n"; break;
			case gesHandsMovingBodyRight: cout<<"Event: gesHandsMovingBodyRight\n"; break;
			case gesLeftLiftShiftBodyLeft: cout<<"Event: gesLeftLiftShiftBodyLeft\n"; break;
			case gesLeftLiftShiftBodyRight: cout<<"Event: gesLeftLiftShiftBodyRight\n"; break;
			case gesRightLiftShiftBodyLeft: cout<<"Event: gesRightLiftShiftBodyLeft\n"; break;
            case gesRightLiftShiftBodyRight: cout<<"Event: gesRightLiftShiftBodyRight\n"; break;
			case gesLeftHigherRightMiddle: cout<<"Event: gesLeftHigherRightMiddle\n"; break;
			case gesLeftLowerRightMiddle: cout<<"Event: gesLeftLowerRightMiddle\n"; break;
			case gesLeftEqualRightMiddle: cout<<"Event: gesLeftEqualRightMiddle\n"; break;
            case gesLeftHigherRightBottom: cout<<"Event: gesLeftHigherRightBottom\n"; break;
			case gesLeftLowerRightBottom: cout<<"Event: gesLeftLowerRightBottom\n"; break;
			case gesRightHold: cout<<"Event: gesRightHold\n"; break;
			case gesBothUpChest: cout<<"Event: gesBothUpChest\n"; break;
            case gesRightMiddle: cout<<"Event: gesRightMiddle\n"; break;
			case gesLeftUpRightActive: cout<<"Event: gesLeftUpRightActive\n"; break;

			case gesLeftUpRightNotActive: cout<<"Event: gesLeftUpRightNotActive\n"; break;
			case gesLeftTilt: cout<<"Event: gesLeftTilt\n"; break;
            case gesRightTilt: cout<<"Event: gesRightTilt\n"; break;
			case gesHandsMovingFrontStop: cout<<"Event: gesHandsMovingFrontStop\n"; break;

			case gesCrouch: cout<<"Event: gesCrouch\n"; break;
            case gesCrouchUp: cout<<"Event: gesCrouchUp\n"; break;
			case gesBodyHold: cout<<"Event: gesBodyHold\n"; break;
			default: FAIL() << "We shouldn't get here."<<j;

			}
		
		}
	
	}
}


TEST_F(FullTest, GetEventsName)
{

  MobiGestureEvent GestureEvent;
  char* GestureName=NULL;
  for(int i=-1;i<74;i++)
  {
	GestureEvent=(MobiGestureEvent)i;
    GestureName=pMobiGR->GetGestureName(GestureEvent);
    EXPECT_NE(NULL,(int)GestureName);
	cout<<i<<":"<<GestureName<<'\n';
  }

}


TEST_F(FullTest,  RecogGesture)
{
	MobiGesture LGesture;

    EXPECT_EQ(MOBI_SUCCEED,pMobiGR->RecogGesture(arrBody, LGesture));


		switch (LGesture.gestureCode) 
		{
		case gesUndefined: cout<<"Event: Undefine\n"; break;
		case gesNeutral: cout<<"Event: gesNeutral\n"; break;
		case gesL5R7: cout<<"Event: gesL5R7\n"; break;
		case gesL5R1: cout<<"Event: gesL5R1\n"; break;
		case gesL5R6: cout<<"Event: gesL5R6\n"; break;
		case gesL4R8: cout<<"Event: gesL4R8\n"; break;
		case gesL1R8: cout<<"Event: gesL1R8\n"; break;
		case gesL3R8: cout<<"Event: gesL3R8\n"; break;
		case gesL4R7: cout<<"Event: gesL4R7\n"; break;
		case gesL1R7: cout<<"Event: gesL1R7\n"; break;
		case gesL4R1: cout<<"Event: gesL4R1\n"; break;
        case gesL1R1: cout<<"Event: gesL1R1\n"; break;
        case gesL3R7: cout<<"Event: gesL3R7\n"; break;				
        case gesL3R1: cout<<"Event: gesL3R1\n"; break;	
		case gesL4R6: cout<<"Event: gesL4R6\n"; break;	
		case gesL1R6: cout<<"Event: gesL1R6\n"; break;	
		case gesL3R6: cout<<"Event: gesL3R6\n"; break;	
		case gesL1R2: cout<<"Event: gesL1R2\n"; break;	
		case gesL2R1: cout<<"Event: gesL2R1\n"; break;	
		case gesL2R6: cout<<"Event: gesL2R6\n"; break;
		case gesL2R7: cout<<"Event: gesL2R7\n"; break;
		case gesL3R2: cout<<"Event: gesL3R2\n"; break;
		case gesL4R2: cout<<"Event: gesL4R2\n"; break;
		case gesL5R2: cout<<"Event: gesL5R2\n"; break;

		case gesMouseMove: cout<<"Event: gesMouseMove\n"; break;
		case gesMouseClick: cout<<"Event: gesMouseClick\n"; break;
		case gesMouseDBClick: cout<<"Event: gesMouseDBClick\n"; break;
		case gesMouseLeftDown: cout<<"Event: gesMouseLeftDown\n"; break;

		case gesLeftLeft: cout<<"Event: gesLeftLeft\n"; break;
		case gesLeftRight: cout<<"Event: gesLeftRight\n"; break;
		case gesRightLeft: cout<<"Event: gesRightLeft\n"; break;
		case gesRightRight: cout<<"Event: gesRightRight\n"; break;
		case gesLeftUp: cout<<"Event: gesLeftUp\n"; break;
		case gesLeftDown: cout<<"Event: gesLeftDown\n"; break;
		case gesRightUp: cout<<"Event: gesRightUp\n"; break;
		case gesRightDown: cout<<"Event: gesRightDown\n"; break;
		case gesBothUp: cout<<"Event: gesBothUp\n"; break;
		case gesBothDown: cout<<"Event: gesBothDown\n"; break;
		case gesBodyLeft: cout<<"Event: gesBodyLeft\n"; break;
		case gesBodyRight: cout<<"Event: gesBodyRight\n"; break;

		case gesHandsFar: cout<<"Event: gesHandsFar\n"; break;
		case gesHandsClose: cout<<"Event: gesHandsClose\n"; break;

		case gesLeftRightFast: cout<<"Event: gesLeftRightFast\n"; break;
		case gesRightLeftFast: cout<<"Event: gesRightLeftFast\n"; break;
		case gesStopLeftFast: cout<<"Event:  gesStopLeftFast\n"; break;
		case gesStopRightFast: cout<<"Event: gesStopRightFast\n"; break;

		case gesLeftUpShift: cout<<"Event: gesLeftUpShift\n"; break;
		case gesRightUpShift: cout<<"Event:  gesRightUpShift\n"; break;
		case gesHeadTilt: cout<<"Event: gesHeadTilt\n"; break;
		case gesHandsMovingFront: cout<<"Event: gesHandsMovingFront\n"; break;
		case gesLeftLiftShift: cout<<"Event:  gesLeftLiftShift\n"; break;
		case gesRightLiftShift: cout<<"Event: gesRightLiftShift\n"; break;
		case gesHandsMovingBodyLeft: cout<<"Event: gesHandsMovingBodyLeft\n"; break;
		case gesHandsMovingBodyRight: cout<<"Event: gesHandsMovingBodyRight\n"; break;
		case gesLeftLiftShiftBodyLeft: cout<<"Event: gesLeftLiftShiftBodyLeft\n"; break;
		case gesLeftLiftShiftBodyRight: cout<<"Event: gesLeftLiftShiftBodyRight\n"; break;
		case gesRightLiftShiftBodyLeft: cout<<"Event: gesRightLiftShiftBodyLeft\n"; break;
        case gesRightLiftShiftBodyRight: cout<<"Event: gesRightLiftShiftBodyRight\n"; break;
		case gesLeftHigherRightMiddle: cout<<"Event: gesLeftHigherRightMiddle\n"; break;
		case gesLeftLowerRightMiddle: cout<<"Event: gesLeftLowerRightMiddle\n"; break;
		case gesLeftEqualRightMiddle: cout<<"Event: gesLeftEqualRightMiddle\n"; break;
        case gesLeftHigherRightBottom: cout<<"Event: gesLeftHigherRightBottom\n"; break;
		case gesLeftLowerRightBottom: cout<<"Event: gesLeftLowerRightBottom\n"; break;
		case gesRightHold: cout<<"Event: gesRightHold\n"; break;
		case gesBothUpChest: cout<<"Event: gesBothUpChest\n"; break;
        case gesRightMiddle: cout<<"Event: gesRightMiddle\n"; break;
		case gesLeftUpRightActive: cout<<"Event: gesLeftUpRightActive\n"; break;

		case gesLeftUpRightNotActive: cout<<"Event: gesLeftUpRightNotActive\n"; break;
		case gesLeftTilt: cout<<"Event: gesLeftTilt\n"; break;
        case gesRightTilt: cout<<"Event: gesRightTilt\n"; break;
		case gesHandsMovingFrontStop: cout<<"Event: gesHandsMovingFrontStop\n"; break;

		case gesCrouch: cout<<"Event: gesCrouch\n"; break;
        case gesCrouchUp: cout<<"Event: gesCrouchUp\n"; break;
		case gesBodyHold: cout<<"Event: gesBodyHold\n"; break;
		default: FAIL() << "We shouldn't get here."<<LGesture.gestureCode;

		}

	cout<<"End testing for MobiGR========================================================\n";

}

/*

TEST(MobiHeart, SetHeartConfig)
{

	MobiHEARTConfig HeartConf, HeartConf1={false,false,false,false,false,false};
	HeartConf.bBT=true;
	HeartConf.bFFT=true;
	HeartConf.bFingers=false;

//	HeartConf.bFingers=true;


	HeartConf.bFR=false;
	HeartConf.bGR=true;
	HeartConf.bLegs=false;
    EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";
    EXPECT_NO_THROW(MOBI_SUCCEED,MobiHeart->GetConfig(HeartConf1))<<"MobiHeart set Status format failed.";
    EXPECT_TRUE(HeartConf1.bFFT);
	EXPECT_TRUE(HeartConf1.bGR);
	EXPECT_TRUE(HeartConf1.bBT);
	EXPECT_FALSE(HeartConf1.bFingers);
	EXPECT_FALSE(HeartConf1.bFR);
	EXPECT_FALSE(HeartConf1.bLegs);
    ///////////////////////////////////////////////////////////////////////////////////////////


	HeartConf.bGR=false;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";
	HeartConf.bFFT=false;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";
	HeartConf.bGR=true;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";
	HeartConf.bBT=true;
	HeartConf.bFFT=true;
	HeartConf.bFingers=true;
	HeartConf.bFR=true;
	HeartConf.bLegs=true;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";
	HeartConf.bLegs=false;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";
	HeartConf.bFingers=false;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";

}
*/

/*

TEST(MobiHeart, SetImgFormat)
{
	EXPECT_EQ(MOBI_INVALID_ARG,MobiHeart->SetImgFormat(320*2,240,320,MOBI_CM_RGB,false))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320,240,320,MOBI_CM_GREY,false))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320*4,240,320,MOBI_CM_RGBA,false))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(352*3,288,352,MOBI_CM_RGB,false))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(352,288,352,MOBI_CM_GREY,false))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGB,false))<<"MobiHeart set Status format failed.";

	EXPECT_EQ(MOBI_INVALID_ARG,MobiHeart->SetImgFormat(320*2,240,320,MOBI_CM_RGB,true))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320,240,320,MOBI_CM_GREY,true))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320*4,240,320,MOBI_CM_RGBA,true))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(352*3,288,352,MOBI_CM_RGB,true))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(352,288,352,MOBI_CM_GREY,true))<<"MobiHeart set Status format failed.";
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGB,true))<<"MobiHeart set Status format failed.";

}
*/


/*

TEST(MobiHeart, SetBTConfig)
{
	
	MobiBTConfig BTConfig, BTConfig1;

	BTConfig.maxNum=0;
	BTConfig.modeBT=0;
	EXPECT_NE(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:0, ModeBT:0";


   MobiHeart->GetBTConfig(BTConfig1);
	EXPECT_EQ(0, BTConfig1.maxNum)<<"Fail: MaxNum:0, ModeBT:0, MaxNum is not 0";
	EXPECT_EQ(0, BTConfig1.modeBT)<<"Fail: MaxNum:0, ModeBT:0, ModeBT is not 0";


	BTConfig.maxNum=0;
	BTConfig.modeBT=1;
	EXPECT_NE(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:0, ModeBT:1";


	MobiHeart->GetBTConfig(BTConfig1);
	EXPECT_EQ(0, BTConfig1.maxNum)<<"Fail: MaxNum:0, ModeBT:1, MaxNum is not 0";
	EXPECT_EQ(1, BTConfig1.modeBT)<<"Fail: MaxNum:0, ModeBT:1, ModeBT is not 1";


	BTConfig.maxNum=-1;
	BTConfig.modeBT=-1;
	EXPECT_NE(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:-1, ModeBT:-1";
	EXPECT_EQ(MOBI_INVALID_ARG,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:-1, ModeBT:-1";
	


	BTConfig.maxNum=-1;
	BTConfig.modeBT=0;
	EXPECT_EQ(MOBI_INVALID_ARG,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:-1, ModeBT:0";
	BTConfig.maxNum=0;
	BTConfig.modeBT=-1;
	EXPECT_EQ(MOBI_INVALID_ARG,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:0, ModeBT:-1";
	


	BTConfig.maxNum=1;
	BTConfig.modeBT=0;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:1, ModeBT:0";

	MobiHeart->GetBTConfig(BTConfig1);
	EXPECT_EQ(1, BTConfig1.maxNum)<<"Fail: MaxNum:1, ModeBT:0, MaxNum is not 1";
	EXPECT_EQ(0, BTConfig1.modeBT)<<"Fail: MaxNum:1, ModeBT:0, ModeBT is not 0";




	BTConfig.maxNum=100;
	BTConfig.modeBT=1;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:100, ModeBT:1";

	BTConfig.maxNum=1;
	BTConfig.modeBT=1;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:1, ModeBT:1";

	BTConfig.maxNum=1;
	BTConfig.modeBT=100;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:1, ModeBT:100";

	MobiHEARTConfig HeartConf;
	HeartConf.bBT=true;
	HeartConf.bFFT=true;
	HeartConf.bFingers=false;
	HeartConf.bFR=false;
	HeartConf.bGR=true;
	HeartConf.bLegs=false;
    EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";

	BTConfig.maxNum=1;
	BTConfig.modeBT=0;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:1, ModeBT:0";

	HeartConf.bBT=false;
	HeartConf.bFFT=true;
	HeartConf.bFingers=false;
	HeartConf.bFR=false;
	HeartConf.bGR=true;
	HeartConf.bLegs=false;
    EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConf))<<"MobiHeart set Status format failed.";

}

*/

/*
TEST(MobiHeart, SetGRConfig)
{
	   MobiGRConfig LConfig, LConfig1;
	   LConfig.modeGR=GR_STATUS;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_STATUS Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_STATUS,LConfig1.modeGR)<<"MobiHeart Get status format GR_STATUS error";

	   LConfig.modeGR=GR_MOUSE;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MOUSE Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MOUSE,LConfig1.modeGR)<<"MobiHeart Get status format GR_MOUSE error";

	   LConfig.modeGR=GR_MOTION;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MOTION Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MOTION,LConfig1.modeGR)<<"MobiHeart Get status format GR_MOTION error";

	   LConfig.modeGR=GR_SEPARATE;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_SEPARATE Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_SEPARATE,LConfig1.modeGR)<<"MobiHeart Get status format GR_SEPARATE error";

	   LConfig.modeGR=GR_MOTION_EXT_1;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MOTION_EXT_1 Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MOTION_EXT_1,LConfig1.modeGR)<<"MobiHeart Get status format GR_MOTION_EXT_1 error";

	   LConfig.modeGR=GR_MOTION_EXT_2;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MOTION_EXT_2 Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MOTION_EXT_2,LConfig1.modeGR)<<"MobiHeart Get status format GR_MOTION_EXT_2 error";

	   LConfig.modeGR=GR_MOTION_EXT_3;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MOTION_EXT_3 Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MOTION_EXT_3,LConfig1.modeGR)<<"MobiHeart Get status format GR_MOTION_EXT_3 error";

	   LConfig.modeGR=GR_COMBINE;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_COMBINE Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_COMBINE,LConfig1.modeGR)<<"MobiHeart Get status format GR_COMBINE error";

	   LConfig.modeGR=GR_COMBINE_1;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_COMBINE_1 Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_COMBINE_1,LConfig1.modeGR)<<"MobiHeart Get status format GR_COMBINE_1 error";

	   LConfig.modeGR=GR_COMBINE_2;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_COMBINE_2 Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_COMBINE_2,LConfig1.modeGR)<<"MobiHeart Get status format GR_COMBINE_2 error";

	   LConfig.modeGR=GR_MEDIA_CENTER;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MEDIA_CENTER Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MEDIA_CENTER,LConfig1.modeGR)<<"MobiHeart Get status format GR_MEDIA_CENTER error";

	   LConfig.modeGR=GR_SOLITAIRE;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_SOLITAIRE Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_SOLITAIRE,LConfig1.modeGR)<<"MobiHeart Get status format GR_SOLITAIRE error";

	   LConfig.modeGR=GR_GOOGLE_EARTH;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_GOOGLE_EARTH Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_GOOGLE_EARTH,LConfig1.modeGR)<<"MobiHeart Get status format GR_GOOGLE_EARTH error";

       LConfig.modeGR=GR_JOY_STICK;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_JOY_STICK Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_JOY_STICK,LConfig1.modeGR)<<"MobiHeart Get status format GR_JOY_STICK error";

	   LConfig.modeGR=GR_TREASURE_HUNTER;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_TREASURE_HUNTER Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_TREASURE_HUNTER,LConfig1.modeGR)<<"MobiHeart Get status format GR_TREASURE_HUNTER error";

	   LConfig.modeGR=GR_MOTION_EXT_1;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiHEART set GR_MOTION_EXT_1 Status format failed.";
	   MobiHeart->GetGRConfig(LConfig1);
	   EXPECT_EQ(GR_MOTION_EXT_1,LConfig1.modeGR)<<"MobiHeart Get status format GR_MOTION_EXT_1 error";


}
*/



TEST(MobiHeart, GetGRModes)
{

	MobiGestureMode* AllModes;
	int num;
	num=MobiHeart->GetGRModes(AllModes);
	EXPECT_NE(0,num);
	if (num)
	{
		cout<<"Status num:"<<num<<'\n';
		for (int j=0; j<num; j++)
		{
			switch (AllModes[j]) 
			{
			case GR_STATUS: cout<<"MobiHeart Gesture Mode: GR_STATUS\n"; break;
			case GR_MOUSE: cout<<"MobiHeart Gesture Mode: GR_MOUSE\n";   break;
			case GR_MOTION: cout<<"MobiHeart Gesture Mode: GR_MOTION\n"; break;
			case GR_SEPARATE: cout<<"MobiHeart Gesture Mode: GR_SEPARATE\n"; break;
			case GR_MOTION_EXT_1: cout<<"MobiHeart Gesture Mode: GR_MOTION_EXT_1\n"; break;
			case GR_MOTION_EXT_2: cout<<"MobiHeart Gesture Mode: GR_MOTION_EXT_2\n"; break;
			case GR_MOTION_EXT_3: cout<<"MobiHeart Gesture Mode: GR_MOTION_EXT_3\n"; break;
			case GR_COMBINE: cout<<"MobiHeart Gesture Mode: GR_COMBINE\n"; break;
			case GR_COMBINE_1: cout<<"MobiHeart Gesture Mode: GR_COMBINE_1\n"; break;
            case GR_COMBINE_2: cout<<"MobiHeart Gesture Mode: GR_COMBINE_2\n"; break;
            case GR_MEDIA_CENTER: cout<<"MobiHeart Gesture Mode: GR_MEDIA_CENTER\n"; break;				
            case GR_SOLITAIRE: cout<<"MobiHeart Gesture Mode: GR_SOLITAIRE\n"; break;	
			case GR_GOOGLE_EARTH: cout<<"MobiHeart Gesture Mode: GR_GOOGLE_EARTH\n"; break;	
			case GR_JOY_STICK: cout<<"MobiHeart Gesture Mode: GR_JOY_STICK\n"; break;	
			case GR_TREASURE_HUNTER: cout<<"MobiHeart Gesture Mode: GR_TREASURE_HUNTER\n"; break;	
			default: FAIL() << "We shouldn't get here.";
			
			}
		
		}

		Sleep(1000);
	}

}


TEST(MobiHeart, GetGRModeName)
{

  MobiGestureMode GestureMode;
  char* ModeName=NULL;
  for(int i=0;i<16;i++)
  {
	GestureMode=(MobiGestureMode)i;
    ModeName=MobiHeart->GetGRModeName(GestureMode);
    EXPECT_NE(NULL,(int)ModeName);
	cout<<i<<":"<<ModeName<<'\n';
  }


}


TEST(MobiHeart, GetGRGestures)
{
	
    MobiGestureEvent* AllEvents;
	int num=0;
	num=MobiHeart->GetGRGestures(AllEvents);
	EXPECT_NE(0,num);
	if (num)
	{
		cout<<"Gestures event num:"<<num<<" "<<AllEvents[0]<<'\n';
		for (int j=0; j<num; j++)
		{   
			EXPECT_EQ(j, AllEvents[j]+1);
			switch (AllEvents[j]) 
			{
			case gesUndefined: cout<<"Event: Undefine\n"; break;
			case gesNeutral: cout<<"Event: gesNeutral\n"; break;
			case gesL5R7: cout<<"Event: gesL5R7\n"; break;
			case gesL5R1: cout<<"Event: gesL5R1\n"; break;
			case gesL5R6: cout<<"Event: gesL5R6\n"; break;
			case gesL4R8: cout<<"Event: gesL4R8\n"; break;
			case gesL1R8: cout<<"Event: gesL1R8\n"; break;
			case gesL3R8: cout<<"Event: gesL3R8\n"; break;
			case gesL4R7: cout<<"Event: gesL4R7\n"; break;
			case gesL1R7: cout<<"Event: gesL1R7\n"; break;
			case gesL4R1: cout<<"Event: gesL4R1\n"; break;
            case gesL1R1: cout<<"Event: gesL1R1\n"; break;
            case gesL3R7: cout<<"Event: gesL3R7\n"; break;				
            case gesL3R1: cout<<"Event: gesL3R1\n"; break;	
			case gesL4R6: cout<<"Event: gesL4R6\n"; break;	
			case gesL1R6: cout<<"Event: gesL1R6\n"; break;	
			case gesL3R6: cout<<"Event: gesL3R6\n"; break;	
			case gesL1R2: cout<<"Event: gesL1R2\n"; break;	
			case gesL2R1: cout<<"Event: gesL2R1\n"; break;	
			case gesL2R6: cout<<"Event: gesL2R6\n"; break;
			case gesL2R7: cout<<"Event: gesL2R7\n"; break;
			case gesL3R2: cout<<"Event: gesL3R2\n"; break;
			case gesL4R2: cout<<"Event: gesL4R2\n"; break;
			case gesL5R2: cout<<"Event: gesL5R2\n"; break;

			case gesMouseMove: cout<<"Event: gesMouseMove\n"; break;
			case gesMouseClick: cout<<"Event: gesMouseClick\n"; break;
			case gesMouseDBClick: cout<<"Event: gesMouseDBClick\n"; break;
			case gesMouseLeftDown: cout<<"Event: gesMouseLeftDown\n"; break;

			case gesLeftLeft: cout<<"Event: gesLeftLeft\n"; break;
			case gesLeftRight: cout<<"Event: gesLeftRight\n"; break;
			case gesRightLeft: cout<<"Event: gesRightLeft\n"; break;
			case gesRightRight: cout<<"Event: gesRightRight\n"; break;
			case gesLeftUp: cout<<"Event: gesLeftUp\n"; break;
			case gesLeftDown: cout<<"Event: gesLeftDown\n"; break;
			case gesRightUp: cout<<"Event: gesRightUp\n"; break;
			case gesRightDown: cout<<"Event: gesRightDown\n"; break;
			case gesBothUp: cout<<"Event: gesBothUp\n"; break;
			case gesBothDown: cout<<"Event: gesBothDown\n"; break;
			case gesBodyLeft: cout<<"Event: gesBodyLeft\n"; break;
			case gesBodyRight: cout<<"Event: gesBodyRight\n"; break;

			case gesHandsFar: cout<<"Event: gesHandsFar\n"; break;
			case gesHandsClose: cout<<"Event: gesHandsClose\n"; break;

			case gesLeftRightFast: cout<<"Event: gesLeftRightFast\n"; break;
			case gesRightLeftFast: cout<<"Event: gesRightLeftFast\n"; break;
			case gesStopLeftFast: cout<<"Event:  gesStopLeftFast\n"; break;
			case gesStopRightFast: cout<<"Event: gesStopRightFast\n"; break;

			case gesLeftUpShift: cout<<"Event: gesLeftUpShift\n"; break;
			case gesRightUpShift: cout<<"Event:  gesRightUpShift\n"; break;
			case gesHeadTilt: cout<<"Event: gesHeadTilt\n"; break;
			case gesHandsMovingFront: cout<<"Event: gesHandsMovingFront\n"; break;
			case gesLeftLiftShift: cout<<"Event:  gesLeftLiftShift\n"; break;
			case gesRightLiftShift: cout<<"Event: gesRightLiftShift\n"; break;
			case gesHandsMovingBodyLeft: cout<<"Event: gesHandsMovingBodyLeft\n"; break;
			case gesHandsMovingBodyRight: cout<<"Event: gesHandsMovingBodyRight\n"; break;
			case gesLeftLiftShiftBodyLeft: cout<<"Event: gesLeftLiftShiftBodyLeft\n"; break;
			case gesLeftLiftShiftBodyRight: cout<<"Event: gesLeftLiftShiftBodyRight\n"; break;
			case gesRightLiftShiftBodyLeft: cout<<"Event: gesRightLiftShiftBodyLeft\n"; break;
            case gesRightLiftShiftBodyRight: cout<<"Event: gesRightLiftShiftBodyRight\n"; break;
			case gesLeftHigherRightMiddle: cout<<"Event: gesLeftHigherRightMiddle\n"; break;
			case gesLeftLowerRightMiddle: cout<<"Event: gesLeftLowerRightMiddle\n"; break;
			case gesLeftEqualRightMiddle: cout<<"Event: gesLeftEqualRightMiddle\n"; break;
            case gesLeftHigherRightBottom: cout<<"Event: gesLeftHigherRightBottom\n"; break;
			case gesLeftLowerRightBottom: cout<<"Event: gesLeftLowerRightBottom\n"; break;
			case gesRightHold: cout<<"Event: gesRightHold\n"; break;
			case gesBothUpChest: cout<<"Event: gesBothUpChest\n"; break;
            case gesRightMiddle: cout<<"Event: gesRightMiddle\n"; break;
			case gesLeftUpRightActive: cout<<"Event: gesLeftUpRightActive\n"; break;

			case gesLeftUpRightNotActive: cout<<"Event: gesLeftUpRightNotActive\n"; break;
			case gesLeftTilt: cout<<"Event: gesLeftTilt\n"; break;
            case gesRightTilt: cout<<"Event: gesRightTilt\n"; break;
			case gesHandsMovingFrontStop: cout<<"Event: gesHandsMovingFrontStop\n"; break;

			case gesCrouch: cout<<"Event: gesCrouch\n"; break;
            case gesCrouchUp: cout<<"Event: gesCrouchUp\n"; break;
			case gesBodyHold: cout<<"Event: gesBodyHold\n"; break;
			default: FAIL() << "We shouldn't get here."<<j;

			}
		
		}
	
	}


}


TEST(MobiHeart, GetGRGestureName)
{

  MobiGestureEvent GestureEvent;
  char* GestureName=NULL;
  for(int i=-1;i<74;i++)
  {
	GestureEvent=(MobiGestureEvent)i;
    GestureName=MobiHeart->GetGRGestureName(GestureEvent);
    EXPECT_NE(NULL,(int)GestureName);
	cout<<i<<":"<<GestureName<<'\n';
  }

}

/*
TEST(MobiHeart, EnableLegs)
{
	EXPECT_NO_THROW(MobiHeart->EnableLegs(true))<<"MobiHeart enable leg fail: True.";
	EXPECT_NO_THROW(MobiHeart->EnableLegs(false))<<"MobiHeart enable leg fail: False.";

}

TEST(MobiHeart, EnableFingers)
{

	EXPECT_NO_THROW(MobiHeart->EnableFingers(true))<<"MobiHeart enable fingers fail: True.";
	EXPECT_NO_THROW(MobiHeart->EnableFingers(false))<<"MobiHeart enable fingers fail: False.";

}
*/





int main(int argc, TCHAR* argv[]) 
{ 
    //用来处理Test相关的命令行开关，如果不关注也可不加 

//	 MessageBox(NULL, L"Hello!", L"title", MB_OK);

//		IWebcam* WebcamIns;
		double dblSampleTime;
		BYTE * pBuffer;
		long lBufferSize;

	   HANDLE hThread;
	   DWORD dwThreadId;
	   MobiHEARTConfig HeartConfig;


	   MobiGRConfig LConfig;

/*
	   try {
      //create a buffered reader that connects to the console, we use it so we can read lines
      BufferedReader in = new BufferedReader(new InputStreamReader(System.in));

      //read a line from the console
      String lineFromInput = in.readLine();

      //create an print writer for writing to a file
      PrintWriter out = new PrintWriter(new FileWriter("output.txt"));

      //output to the file a line
      out.println(lineFromInput);

      //close the file (VERY IMPORTANT!)
      out.close();
   }
      catch(IOException e1) {
        System.out.println("Error during reading/writing");
   }
   */



	  
	//  cvNamedWindow("Capture");

	   MakeBMPHeader1();
	   MakeBMPHeader();

	   pBuffer1=new BYTE[320*240*3];


	   hThread = CreateThread(
		 NULL,    
		 NULL,    
		 ThreadProc,   //线程入口地址(执行线程的函数)
		 NULL,         //传给函数的参数
		 0,            //指定线程立即执行
		 &dwThreadId   //返回线程的ID号
		 );
	//   WaitForSingleObject(hThread,INFINITE);
	   printf("Now another thread has been Created,ID:%d\n\n\nInitialize OK. Start testing...\n\n",dwThreadId);


        Sleep(1000);

	//	CVdoFrameHandler* frame_handler;
       EXPECT_NO_THROW(WebcamIns=CreateWebcam());
	   EXPECT_NO_THROW(MobiHeart=CreateMobiHEART());
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;"));
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGB,true));
	   LConfig.modeGR=GR_MOTION_EXT_1;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetGRConfig(LConfig))<<"MobiGR set Status format failed.";

	
	   HeartConfig.bBT=true;
	   HeartConfig.bFFT=false;
	   HeartConfig.bFingers=false;
	   HeartConfig.bFR=false;
	   HeartConfig.bGR=true;
	   HeartConfig.bLegs=false;
	   EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetConfig(HeartConfig));

	 MobiBTConfig BTConfig, BTConfig1;

/*
	BTConfig.maxNum=100;
	BTConfig.modeBT=1;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Fail: MaxNum:100, ModeBT:1";
*/
	 /*
	BTConfig.maxNum=0;
	BTConfig.modeBT=0;
	EXPECT_NE(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Main: Fail: MaxNum:0, ModeBT:0";


   MobiHeart->GetBTConfig(BTConfig1);
   EXPECT_EQ(0, BTConfig1.maxNum)<<"Main: Fail: MaxNum:0, ModeBT:0, MaxNum is not 0";
   EXPECT_EQ(0, BTConfig1.modeBT)<<"Main: Fail: MaxNum:0, ModeBT:0, ModeBT is not 0";
   */


//	 MobiBTConfig BTConfig, BTConfig1;
	BTConfig.maxNum=1;
	BTConfig.modeBT=0;
	EXPECT_EQ(MOBI_SUCCEED,MobiHeart->SetBTConfig(BTConfig))<<"Main: Fail: MaxNum:1, ModeBT:1";


    MobiHeart->GetBTConfig(BTConfig1);
    EXPECT_EQ(1, BTConfig1.maxNum)<<"Main: Fail: MaxNum:1, ModeBT:1, MaxNum is not 1";
    EXPECT_EQ(0, BTConfig1.modeBT)<<"Main: Fail: MaxNum:1, ModeBT:0, ModeBT is not 0";





	   
	   stcBufferPreview.Attach(GetDlgItem(hWndRender,IDC_STATIC1));
	  
	  //  stcBufferPreview.Attach(hWndRender);
	//     stcBufferPreview=GetDlgItem(hWndRender,IDC_STATIC1);
	//	 CstcBufferPreview.Attach(stcBufferPreview);

	  // stcBufferPreview.GetDlgItem(IDC_STATIC);

	    stcBufferPreview.SetImageFormat(320, 240, 24);
	    stcBufferPreview.SetWindowPos(NULL, 0, 0, 320, 240, SWP_NOMOVE | SWP_NOZORDER|SWP_NOACTIVATE);
//		RDialog.Attach(hWndRender);
	    RDialog.SubclassWindow(GetDlgItem(hWndRender,IDC_STATIC1));
        stcBufferPreview.ModifyStyle(0, WS_CLIPCHILDREN|WS_CLIPSIBLINGS);

		 stcBufferSil.Attach(GetDlgItem(hWndRender,IDC_STATIC));

		 stcBufferSil.SetImageFormat(320, 240, 8);
		// 	 stcBufferSil.SetImageFormat(240, 180, 8);

		 RDialog.SubclassWindow(GetDlgItem(hWndRender,IDC_STATIC));
	     stcBufferSil.SetWindowPos(NULL, 0, 0, 320, 240, SWP_NOMOVE | SWP_NOZORDER|SWP_NOACTIVATE);
		// stcBufferSil.SetWindowPos(NULL, 0, 0, 240, 180, SWP_NOMOVE | SWP_NOZORDER|SWP_NOACTIVATE);
		
        stcBufferSil.ModifyStyle(0, WS_CLIPCHILDREN|WS_CLIPSIBLINGS);
    
  	    RDialog.Attach(hWndRender);
    //	RDialog.ModifyStyle(0,WS_CLIPSIBLINGS);//
		
        testing::InitGoogleTest(&argc,argv);  

 
       int r = RUN_ALL_TESTS(); 


//		int r=0;
  
      std::cin.get();  
	  if(WebcamIns)
	  {
		  WebcamIns->stop();
		  ReleaseWebcam(&WebcamIns);
		  WebcamIns=NULL;
		
	  }
	  delete[] m_pBmpInfo;
	  delete[] m_pBmpInfo1;
	  delete[] m_pImageBytes;
	  delete[] m_pImageBytes1;
	  delete[] pBuffer1;
	  ReleaseMobiGR(&MobiGR);
	  ReleaseMobiHEART(&MobiHeart);
  
    return r;

} 


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
			if ((WebcamIns)&&(hDlg==hWndF))
			{
			ReleaseWebcam(&WebcamIns);
			WebcamIns=NULL;
			}

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

	}
	
	
	return (INT_PTR)FALSE;
}



INT_PTR CALLBACK About1(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
	UNREFERENCED_PARAMETER(lParam);
	switch (message)
	{
	case WM_INITDIALOG:
		return (INT_PTR)TRUE;

	case WM_COMMAND:
		if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
		{
			if ((WebcamIns)&&(hDlg==hWndF))
			{
			ReleaseWebcam(&WebcamIns);
			WebcamIns=NULL;
			}

			EndDialog(hDlg, LOWORD(wParam));

			return (INT_PTR)TRUE;
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

	}
	
	
	return (INT_PTR)FALSE;
}



DWORD WINAPI ThreadProc( LPVOID lpParameter )
{
   MSG msg;

	hWndF=(HWND)CreateDialog(NULL, MAKEINTRESOURCE(IDD_DIALOG1), 0, About);
	ShowWindow(hWndF,SW_SHOW);
	UpdateWindow(hWndF);



	hWndRender=(HWND)CreateDialog(NULL, MAKEINTRESOURCE(IDD_DIALOG2), 0, About);
	ShowWindow(hWndRender,SW_SHOW);
	UpdateWindow(hWndRender);

	
//	cvNamedWindow("TestProcessPause");

//	scaled = cvCreateImage(cvSize(320, 240), IPL_DEPTH_16U, 3);


  while (GetMessage (&msg, NULL, 0, 0))
  {
    if((hWndF == 0 || !IsDialogMessage (hWndF, &msg))&&(hWndRender== 0 || !IsDialogMessage (hWndRender, &msg)))
    { 
//	 if(hWndRender== 0 || !IsDialogMessage (hWndRender, &msg))
//	 {
		TranslateMessage(&msg);
        DispatchMessage(&msg);
//	 }
    }
    Sleep(20);
  }
  

	return 0;
}
