// TestFrame.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "resource.h"
#include <fstream>



#include "defineh.h"


using namespace std;

void CMyFrameHandler::VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize)
{   

	if (EndProgram) return;
	CPaintDC dc(&stcBufferPreview); // device context for painting

	CPaintDC dcSil(&stcBufferSil);


	GetClientRect(GetDlgItem(hWndRender,IDC_STATIC1),&rc);
	GetClientRect(GetDlgItem(hWndRender,IDC_STATIC2),&rcSil);

	RDialog.Invalidate(false);

//	if((pBuffer != NULL) &&(MobiHeart!=NULL))
	{
		dc.RealizePalette();
        dcSil.RealizePalette();
		SetStretchBltMode(dc.GetSafeHdc(), COLORONCOLOR);
        SetStretchBltMode(dcSil.GetSafeHdc(), COLORONCOLOR);
	   // EXPECT_NO_THROW(MobiHeart->ProcessFrame(pBuffer,lBufferSize,numBody, &arrBody, &ArrGesture));
		//EXPECT_NO_THROW(MobiHeart->GetSilhouette(pBuffer1,320*240,320, 240, 320));
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

		
/*
/////////////////Add the code for process data and display

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
			*/
			
	//     RDialog.Invalidate(false);
	 //  EXPECT_NO_THROW(MobiHeart->ProcessFrame(pBuffer,lBufferSize,numBody, &arrBody, &ArrGesture));
/*
	   HPEN penFocus = ::CreatePen(PS_SOLID, 4, RGB(255,128,128));
	   HPEN hOldPen = (HPEN)SelectObject(dc.GetSafeHdc(),penFocus);
	   SelectObject(dc.GetSafeHdc(),GetStockObject(NULL_BRUSH));

	   Ellipse(dc.GetSafeHdc(),arrBody.face.x*(rc.right - rc.left)/320-3,arrBody.face.y*(rc.bottom - rc.top)/240+3,arrBody.face.x*(rc.right - rc.left)/320+3,arrBody.face.y*(rc.bottom - rc.top)/240-3);
       Ellipse(dc.GetSafeHdc(),arrBody.nodeNeck.x-3,arrBody.nodeNeck.y+3,arrBody.nodeNeck.x+3,arrBody.nodeNeck.y-3);
	   Ellipse(dc.GetSafeHdc(),arrBody.nodeUpBody.x-3,arrBody.nodeUpBody.y+3,arrBody.nodeUpBody.x+3,arrBody.nodeUpBody.y-3);



	   	SelectObject(dc.GetSafeHdc(),hOldPen);
    	DeleteObject(penFocus);


*/


	}
	dc.ReleaseOutputDC();
	dcSil.ReleaseOutputDC();


}

//Test implementation
bool test_test_module_test_func()
{
	if(::MessageBox(NULL,TEXT("This is a testing"),TEXT("Test Window"),1))
	{
	return true;
	}
	else
	{
	return false;
	}
}

//int _tmain(int argc, char* argv[])
int main(int argc, char* argv[])
{


	int func_num =-1;
	if(argc>2){
		printf("Wrong number of arguments.\n");
		return 1;
	}else if(argc==1){
		printf("test cases as many as possible.\n");
	}else{
		func_num = atoi(argv[1]);
	}

 
////////////////////////////////////////////////////////////////
	FILE* fp = NULL;
    fp = fopen("testlog.txt", "a+");
	if (!fp)
	{
		ofstream fout("testlog.txt");
		
		fout.close();
		fp = fopen("testlog.txt", "a+");
  
	}
///////////////////////////////////////////////////////////////

//	fprintf(fp,"Testing module:   Function name: \n");
	fprintf(fp,"Start Testing...\n");
    StartWebcam();       //If do not need to start webcam for testing, just comment out this line.
 //////Please add the test case here.



     if(func_num==-1)        //Test all cases;
	 {

		TEST_L(test_module,test_func);	
	 }

	 else
	 {
		 switch (func_num) 
		 {
			case 1:    break;//case1;
			case 2:    break;//case2:
		    default:  Sleep(10000); fprintf(fp,"please input correct case number\n"); break;

		 
		 
		 }
	 
	 
	 
	 
	 }

	std::cin.get();
	fprintf(fp,"End Testing.\n");

	fclose(fp);
	ExitTesting();

	return 0;
}

