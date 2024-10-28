// TestFrame.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include "resource.h"
#include <fstream>



#include "defineh.h"

#include "IMobiHEART.h"


using namespace std;

IMobiHEART* pMobiHeart;
 int numBody;
 MobiBody arrBody;
 MobiGesture ArrGesture;
 BYTE * pBuffer1;

void CMyFrameHandler::VdoFrameData(double dblSampleTime, BYTE * pBuffer, long lBufferSize)
{   

	if ((EndProgram)||(!pMobiHeart)) return;
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
        pMobiHeart->ProcessFrame(pBuffer,lBufferSize,numBody, &arrBody, &ArrGesture);
		//EXPECT_NO_THROW(MobiHeart->GetSilhouette(pBuffer1,320*240,320, 240, 320));
//		EXPECT_NO_THROW(MobiHeart->GetSilhouette(pBuffer1,240*180,240, 180, 240));
		pMobiHeart->GetSilhouette(pBuffer1,320*240,320, 240, 320);

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


}

//Test implementation
bool test_test_module_test_func()
{
	if(::MessageBox(NULL,TEXT("This is a testing"),TEXT("Test Window"),1)==IDOK)
	{
	return true;
	}
	else
	{
	return false;
	}
}


///////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_CreateReleaseMobiHEART()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  fprintf(fp,"Test cases.\n");
  char* Case[]={
                "1.Have not called CreateMobiHEART(), call ReleaseMobiHEART().\n",
				"2.Called CreateMobiHEART() first, then call ReleaseMobiHEART(). \n",
                "3.Called CreateMobiHEART() first, then call ReleaseMobiHEART(), then call ReleaseMobiHEART() again.\n"
               };
  for (int i=0;i<3; i++)
  {
  fprintf(fp,Case[i]);
  }
  fprintf(fp,"\n");

  try
  {

	ReleaseMobiHEART(&MobiHeart);
	MobiHeart=NULL;
  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, have not called Function CreateMobiHEART(), ReleaseMobiHeart() crashed\n", __LINE__);
    suc=false;
	
  }

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		suc=false;
	}
	ReleaseMobiHEART(&MobiHeart);
	ReleaseMobiHEART(&MobiHeart);
  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then ReleaseMobiHeart() crashed\n", __LINE__);
    suc=false;
	
  }

  return suc;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_Initialize()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;

  fprintf(fp,"Test cases: \n");
  char* Case[]={
	            "1.sLicense: Space\n",
				"2.sLicense: 0\n",
				"3.sLicense: expired License\n",
				"4.sLicense: Update expires to 20120630\n",
				"5.sLicense: Wrong signature\n",
				"6.sLicense: Wrong licensor\n",
				"7.sLicense: A correct license\n"
               };
  for (int i=0;i<7; i++)
  {
  fprintf(fp,Case[i]);
  }
  fprintf(fp,"\n");

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		suc=false;
	}
	else
	{
	ret=MobiHeart->Initialize("");
	ASSERT_VAL(MOBI_INVALID_LICENSE,ret, "Initialize()", "");
	ret=MobiHeart->Initialize(NULL);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "Initialize()", "sLicense:NULL");
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e84;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
    ASSERT_VAL(MOBI_INVALID_LICENSE,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e84;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ret=MobiHeart->Initialize("licensor = Mobi.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_INVALID_LICENSE,ret, "Initialize()", "License: licensor = Mobi.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951401;");
	ASSERT_VAL(MOBI_INVALID_LICENSE,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951401;");
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110330;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_INVALID_LICENSE,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110330;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");

	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20120630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_INVALID_LICENSE,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20120630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");


	ReleaseMobiHEART(&MobiHeart);
	}
  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then ReleaseMobiHeart(), then Initialize() crashed\n", __LINE__);
    suc=false;
	
  }
  return suc;

}


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_SetImgFormat()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;


  fprintf(fp,"Test cases: \n");
  char* Case[]={
	            "Resolution: 320X240, 160X120, 176X144, 640X480,600X400, 800X600\n",
				"Color mode: MOBI_CM_RGB, MOBI_CM_RGBA, MOBI_CM_GREY,3\n",
				"Origin: TRUE, FALSE\n",
               };
  for (int i=0;i<3; i++)
  {
  fprintf(fp,Case[i]);
  }
  fprintf(fp,"\n");

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
    ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGB,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_RGB, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGB,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_RGB, Origin: FALSE");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGBA,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_RGBA, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGBA,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_RGBA, Origin: FALSE");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_RGB,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_RGB, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_RGB,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_RGB, Origin: false");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_RGBA,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_RGBA, Origin: true");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_RGBA,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_RGBA, Origin: false");
	ret=MobiHeart->SetImgFormat(176*3,144,176,MOBI_CM_RGBA,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:176*3, Height:144, Width:176, ColorMode: MOBI_CM_RGBA, Origin: false");
	ret=MobiHeart->SetImgFormat(176*3,144,176,MOBI_CM_RGBA,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:176*3, Height:144, Width:176, ColorMode: MOBI_CM_RGBA, Origin: true");


	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_GREY,true);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_GREY, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_GREY,false);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_GREY, Origin: FALSE");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_GREY,true);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_GREY, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_GREY,false);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: MOBI_CM_GREY, Origin: FALSE");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_GREY,true);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_GREY, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_GREY,false);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_GREY, Origin: false");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_GREY,true);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_GREY, Origin: true");
	ret=MobiHeart->SetImgFormat(160*3,120,160,MOBI_CM_GREY,false);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:160*3, Height:120, Width:160, ColorMode: MOBI_CM_GREY, Origin: false");
	ret=MobiHeart->SetImgFormat(176*3,144,176,MOBI_CM_GREY,false);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:176*3, Height:144, Width:176, ColorMode: MOBI_CM_GREY, Origin: false");
	ret=MobiHeart->SetImgFormat(176*3,144,176,MOBI_CM_GREY,true);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:176*3, Height:144, Width:176, ColorMode: MOBI_CM_GREY, Origin: true");
	ret=MobiHeart->SetImgFormat(320*3,240,320,3,true);
	ASSERT_VAL(MOBI_INVALID_ARG,ret, "SetImgFormat()", "WidthStep:320*3, Height:240, Width:320, ColorMode: 3, Origin: TRUE");


	ret=MobiHeart->SetImgFormat(640*3,480,640,MOBI_CM_RGB,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:640*3, Height:480, Width:640, ColorMode: MOBI_CM_RGB, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(640*3,480,640,MOBI_CM_RGB,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:640*3, Height:480, Width:640, ColorMode: MOBI_CM_RGB, Origin: FALSE");
	ret=MobiHeart->SetImgFormat(640*3,480,640,MOBI_CM_RGBA,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:640*3, Height:480, Width:640, ColorMode: MOBI_CM_RGBA, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(640*3,480,640,MOBI_CM_RGBA,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:640*3, Height:480, Width:640, ColorMode: MOBI_CM_RGBA, Origin: FALSE");
	ret=MobiHeart->SetImgFormat(600*3,400,600,MOBI_CM_RGB,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:600*3, Height:400, Width:600, ColorMode: MOBI_CM_RGB, Origin: TRUE");
	ret=MobiHeart->SetImgFormat(600*3,400,600,MOBI_CM_RGB,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:600*3, Height:400, Width:600, ColorMode: MOBI_CM_RGB, Origin: false");
	ret=MobiHeart->SetImgFormat(600*3,400,600,MOBI_CM_RGBA,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:600*3, Height:400, Width:600, ColorMode: MOBI_CM_RGBA, Origin: true");
	ret=MobiHeart->SetImgFormat(600*3,400,600,MOBI_CM_RGBA,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:600*3, Height:400, Width:600, ColorMode: MOBI_CM_RGBA, Origin: false");
	ret=MobiHeart->SetImgFormat(800*3,600,800,MOBI_CM_RGBA,false);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:800*3, Height:600, Width:800, ColorMode: MOBI_CM_RGBA, Origin: false");
	ret=MobiHeart->SetImgFormat(800*3,600,800,MOBI_CM_RGBA,true);
	ASSERT_VAL(MOBI_SUCCEED,ret, "SetImgFormat()", "WidthStep:800*3, Height:600, Width:800, ColorMode: MOBI_CM_RGBA, Origin: true");


	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then SetImgFormat() crashed\n", __LINE__);
    suc=false;
	
  }

  return suc;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_SetGetConfig()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiHEARTConfig tConfig;
  MobiHEARTConfig Config[]={
	                        {0,0,1,1,0,0},
							{0,0,1,0,0,0},
							{0,0,0,1,0,0},
                            {0,0,0,0,1,0},
							{0,0,0,0,0,1},
							{1,0,0,0,0,0},
                            {0,1,0,0,0,0},
							{1,1,0,0,0,0},
							{0,0,1,1,0,0},
							{0,0,0,0,1,1},
							{0,0,0,1,1,1},
							{1,1,1,0,0,0},
							{0,0,0,0,0,0},
                            {1,1,1,1,1,1},
                            };

 char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  
	for (int i=0;i<14;i++)
	{
		ret=MobiHeart->SetConfig(Config[i]);
		sprintf(temp, "bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,(Config[i].bLegs)?1:0,(Config[i].bFingers)?1:0);
		ASSERT_VAL(MOBI_SUCCEED,ret, "SetConfig()", temp);
		MobiHeart->GetConfig(tConfig);
		ASSERT_VAL(Config[i].bFFT,tConfig.bFFT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFR,tConfig.bFR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bBT,tConfig.bBT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bGR,tConfig.bGR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bLegs,tConfig.bLegs,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFingers,tConfig.bFingers,"GetConfig()",temp);

	}												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then Set(Get)Config() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


bool test_MobiHeart_SetGetBTConfig()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiBTConfig BTConfig[]={
	                     {1,0},
						 {1,1},
						 {2,0},
						 {2,1},
						 {3,0},
						 {3,1},
						 {0,0},
						 {0,1},
						 {-1,0},
						 {-1,1},
						 {1,3},
						 {2,3}
                         };
  MobiBTConfig tBTConfig;

 char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  

	for (int i=0;i<12;i++)
	{
		ret=MobiHeart->SetBTConfig(BTConfig[i]);
		sprintf(temp,"MaxNum:%d, ModeBT:%d", BTConfig[i].maxNum, BTConfig[i].modeBT);
		if((BTConfig[i].maxNum>2)||(BTConfig[i].maxNum<1)||(BTConfig[i].modeBT>1)||(BTConfig[i].modeBT<0))
		{
			ASSERT_VAL(MOBI_INVALID_ARG,ret,"SetBTConfig()",temp);
		
		}
		else
		{
			ASSERT_VAL(MOBI_SUCCEED,ret,"SetBTConfig()",temp);
			MobiHeart->GetBTConfig(tBTConfig);
			ASSERT_VAL(tBTConfig.maxNum,BTConfig[i].maxNum,"GetBTConfig()",temp);
			ASSERT_VAL(tBTConfig.modeBT,BTConfig[i].modeBT,"GetBTConfig()",temp);
		
		}
	}
												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then Set(Get)BTConfig() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
bool test_MobiHeart_SetGetGRConfig()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiGRConfig GRConfig[]={GR_STATUS,GR_MOUSE,GR_MOTION,GR_SEPARATE,GR_MOTION_EXT_1,GR_MOTION_EXT_2,GR_MOTION_EXT_3,GR_COMBINE,GR_COMBINE_1,GR_COMBINE_2,GR_MEDIA_CENTER,GR_SOLITAIRE,GR_GOOGLE_EARTH,GR_JOY_STICK,GR_TREASURE_HUNTER};
  MobiGRConfig tGRConfig;

 char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  

	for (int i=0;i<15;i++)
	{
		ret=MobiHeart->SetGRConfig(GRConfig[i]);
		sprintf(temp,"ModeGR:%d", GRConfig[i].modeGR);
		ASSERT_VAL(MOBI_SUCCEED,ret,"SetGRConfig()",temp);
		MobiHeart->GetGRConfig(tGRConfig);
		ASSERT_VAL(tGRConfig.modeGR,GRConfig[i].modeGR,"GetGRConfig()",temp);
	}
												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then Set(Get)GRConfig() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_GetGRModes()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiGestureMode* AllModes;
  int num;

  char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  
    num=MobiHeart->GetGRModes(AllModes);
	ASSERT_VAL(15,num,"GetGRModes()","");


	for (int i=0;i<15;i++)
	{
			switch (AllModes[i]) 
			{
			case GR_STATUS: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_STATUS\n", i); break;
			case GR_MOUSE:  fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_MOUSE\n",i);   break;
			case GR_MOTION: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_MOTION\n",i); break;
			case GR_SEPARATE: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_SEPARATE\n",i); break;
			case GR_MOTION_EXT_1: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_MOTION_EXT_1\n",i); break;
			case GR_MOTION_EXT_2: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_MOTION_EXT_2\n",i); break;
			case GR_MOTION_EXT_3: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_MOTION_EXT_3\n",i); break;
			case GR_COMBINE:      fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_COMBINE\n",i); break;
			case GR_COMBINE_1:    fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_COMBINE_1\n",i); break;
            case GR_COMBINE_2:    fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_COMBINE_2\n",i); break;
            case GR_MEDIA_CENTER: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_MEDIA_CENTER\n",i); break;				
            case GR_SOLITAIRE:    fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_SOLITAIRE\n",i); break;	
			case GR_GOOGLE_EARTH: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_GOOGLE_EARTH\n",i); break;	
			case GR_JOY_STICK:    fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_JOY_STICK\n",i); break;	
			case GR_TREASURE_HUNTER: fprintf(fp, "Number: %d, MobiHeart Gesture Mode: GR_TREASURE_HUNTER\n",i); break;	
			default: fprintf(fp, "Number: %d, Mode:%d, Error: We shouldn't get here.\n",i,AllModes[i]); suc=false;
			
			}
	}
												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then GetGRModes() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_GetGRModeName()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiGestureMode GestureMode;
  char* ModeName=NULL;

  char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  

	for(int i=0;i<16;i++)
   {
	GestureMode=(MobiGestureMode)i;
    ModeName=MobiHeart->GetGRModeName(GestureMode);
	fprintf(fp,"ModeNum:%d, Mode Name:%s\n",i,ModeName);
   }
												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then GetGRModeName() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_GetGRGestures()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiGestureEvent* AllGR;
  int num;

  char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  
    num=MobiHeart->GetGRGestures(AllGR);
	ASSERT_VAL(74,num,"GetGRGestures()","");


	for (int i=0;i<75;i++)
	{
			switch (AllGR[i]) 

			{
			case gesUndefined: fprintf(fp, "Num: %d, Event: Undefine\n", i); break;
			case gesNeutral: fprintf(fp, "Num: %d, Event: gesNeutral\n", i); break;
			case gesL5R7: fprintf(fp, "Num: %d, Event: gesL5R7\n", i); break;
			case gesL5R1: fprintf(fp, "Num: %d, Event: gesL5R1\n", i); break;
			case gesL5R6: fprintf(fp, "Num: %d, Event: gesL5R6\n", i); break;
			case gesL4R8: fprintf(fp, "Num: %d, Event: gesL4R8\n", i); break;
			case gesL1R8: fprintf(fp, "Num: %d, Event: gesL1R8\n", i); break;
			case gesL3R8: fprintf(fp, "Num: %d, Event: gesL3R8\n", i); break;
			case gesL4R7: fprintf(fp, "Num: %d, Event: gesL4R7\n", i); break;
			case gesL1R7: fprintf(fp, "Num: %d, Event: gesL1R7\n", i); break;
			case gesL4R1: fprintf(fp, "Num: %d, Event: gesL4R1\n", i); break;
            case gesL1R1: fprintf(fp, "Num: %d, Event: gesL1R1\n", i); break;
            case gesL3R7: fprintf(fp, "Num: %d, Event: gesL3R7\n", i); break;				
            case gesL3R1: fprintf(fp, "Num: %d, Event: gesL3R1\n", i); break;	
			case gesL4R6: fprintf(fp, "Num: %d, Event: gesL4R6\n", i); break;	
			case gesL1R6: fprintf(fp, "Num: %d, Event: gesL1R6\n", i); break;	
			case gesL3R6: fprintf(fp, "Num: %d, Event: gesL3R6\n", i); break;	
			case gesL1R2: fprintf(fp, "Num: %d, Event: gesL1R2\n", i); break;	
			case gesL2R1: fprintf(fp, "Num: %d, Event: gesL2R1\n", i); break;	
			case gesL2R6: fprintf(fp, "Num: %d, Event: gesL2R6\n", i); break;
			case gesL2R7: fprintf(fp, "Num: %d, Event: gesL2R7\n", i); break;
			case gesL3R2: fprintf(fp, "Num: %d, Event: gesL3R2\n", i); break;
			case gesL4R2: fprintf(fp, "Num: %d, Event: gesL4R2\n", i); break;
			case gesL5R2: fprintf(fp, "Num: %d, Event: gesL5R2\n", i); break;

			case gesMouseMove: fprintf(fp, "Num: %d, Event: gesMouseMove\n", i); break;
			case gesMouseClick: fprintf(fp, "Num: %d, Event: gesMouseClick\n", i); break;
			case gesMouseDBClick: fprintf(fp, "Num: %d, Event: gesMouseDBClick\n", i); break;
			case gesMouseLeftDown: fprintf(fp, "Num: %d, Event: gesMouseLeftDown\n", i); break;

			case gesLeftLeft: fprintf(fp, "Num: %d, Event: gesLeftLeft\n", i); break;
			case gesLeftRight: fprintf(fp, "Num: %d, Event: gesLeftRight\n", i); break;
			case gesRightLeft: fprintf(fp, "Num: %d, Event: gesRightLeft\n", i); break;
			case gesRightRight: fprintf(fp, "Num: %d, Event: gesRightRight\n", i); break;
			case gesLeftUp: fprintf(fp, "Num: %d, Event: gesLeftUp\n", i); break;
			case gesLeftDown: fprintf(fp, "Num: %d, Event: gesLeftDown\n", i); break;
			case gesRightUp: fprintf(fp, "Num: %d, Event: gesRightUp\n", i); break;
			case gesRightDown: fprintf(fp, "Num: %d, Event: gesRightDown\n", i); break;
			case gesBothUp: fprintf(fp, "Num: %d, Event: gesBothUp\n", i); break;
			case gesBothDown: fprintf(fp, "Num: %d, Event: gesBothDown\n", i); break;
			case gesBodyLeft: fprintf(fp, "Num: %d, Event: gesBodyLeft\n", i); break;
			case gesBodyRight: fprintf(fp, "Num: %d, Event: gesBodyRight\n", i); break;

			case gesHandsFar: fprintf(fp, "Num: %d, Event: gesHandsFar\n", i); break;
			case gesHandsClose: fprintf(fp, "Num: %d, Event: gesHandsClose\n", i); break;

			case gesLeftRightFast: fprintf(fp, "Num: %d, Event: gesLeftRightFast\n", i); break;
			case gesRightLeftFast: fprintf(fp, "Num: %d, Event: gesRightLeftFast\n", i); break;
			case gesStopLeftFast: fprintf(fp, "Num: %d, Event:  gesStopLeftFast\n", i); break;
			case gesStopRightFast: fprintf(fp, "Num: %d, Event: gesStopRightFast\n", i); break;

			case gesLeftUpShift: fprintf(fp, "Num: %d, Event: gesLeftUpShift\n", i); break;
			case gesRightUpShift: fprintf(fp, "Num: %d, Event:  gesRightUpShift\n", i); break;
			case gesHeadTilt: fprintf(fp, "Num: %d, Event: gesHeadTilt\n", i); break;
			case gesHandsMovingFront: fprintf(fp, "Num: %d, Event: gesHandsMovingFront\n", i); break;
			case gesLeftLiftShift: fprintf(fp, "Num: %d, Event:  gesLeftLiftShift\n", i); break;
			case gesRightLiftShift: fprintf(fp, "Num: %d, Event: gesRightLiftShift\n", i); break;
			case gesHandsMovingBodyLeft: fprintf(fp, "Num: %d, Event: gesHandsMovingBodyLeft\n", i); break;
			case gesHandsMovingBodyRight: fprintf(fp, "Num: %d, Event: gesHandsMovingBodyRight\n", i); break;
			case gesLeftLiftShiftBodyLeft: fprintf(fp, "Num: %d, Event: gesLeftLiftShiftBodyLeft\n", i); break;
			case gesLeftLiftShiftBodyRight: fprintf(fp, "Num: %d, Event: gesLeftLiftShiftBodyRight\n", i); break;
			case gesRightLiftShiftBodyLeft: fprintf(fp, "Num: %d, Event: gesRightLiftShiftBodyLeft\n", i); break;
            case gesRightLiftShiftBodyRight: fprintf(fp, "Num: %d, Event: gesRightLiftShiftBodyRight\n", i); break;
			case gesLeftHigherRightMiddle: fprintf(fp, "Num: %d, Event: gesLeftHigherRightMiddle\n", i); break;
			case gesLeftLowerRightMiddle: fprintf(fp, "Num: %d, Event: gesLeftLowerRightMiddle\n", i); break;
			case gesLeftEqualRightMiddle: fprintf(fp, "Num: %d, Event: gesLeftEqualRightMiddle\n", i); break;
            case gesLeftHigherRightBottom: fprintf(fp, "Num: %d, Event: gesLeftHigherRightBottom\n", i); break;
			case gesLeftLowerRightBottom: fprintf(fp, "Num: %d, Event: gesLeftLowerRightBottom\n", i); break;
			case gesRightHold: fprintf(fp, "Num: %d, Event: gesRightHold\n", i); break;
			case gesBothUpChest: fprintf(fp, "Num: %d, Event: gesBothUpChest\n", i); break;
            case gesRightMiddle: fprintf(fp, "Num: %d, Event: gesRightMiddle\n", i); break;
			case gesLeftUpRightActive: fprintf(fp, "Num: %d, Event: gesLeftUpRightActive\n", i); break;

			case gesLeftUpRightNotActive: fprintf(fp, "Num: %d, Event: gesLeftUpRightNotActive\n", i); break;
			case gesLeftTilt: fprintf(fp, "Num: %d, Event: gesLeftTilt\n", i); break;
            case gesRightTilt: fprintf(fp, "Num: %d, Event: gesRightTilt\n", i); break;
			case gesHandsMovingFrontStop: fprintf(fp, "Num: %d, Event: gesHandsMovingFrontStop\n", i); break;

			case gesCrouch: fprintf(fp, "Num: %d, Event: gesCrouch\n", i); break;
            case gesCrouchUp: fprintf(fp, "Num: %d, Event: gesCrouchUp\n", i); break;
			case gesBodyHold: fprintf(fp, "Num: %d, Event: gesBodyHold\n", i); break;
			default: fprintf(fp,"We shouldn't get here. Num: %d, Event: %d\n",i, AllGR[i]);

			
			}
	}
												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then GetGRGestures() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_GetGRGestureName()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiGestureEvent gesEvent;
  char* GesName=NULL;

  char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  

	for(int i=-1;i<75;i++)
   {
	gesEvent=(MobiGestureEvent)i;
    GesName=MobiHeart->GetGRGestureName(gesEvent);
	fprintf(fp,"ModeNum:%d, Mode Name:%s\n",i,GesName);
   }
												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then GetGRGestureName() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_EnableLegs()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiHEARTConfig tConfig;
  MobiHEARTConfig Config[]={
	                        {0,0,1,1,0,0},
							{0,0,1,0,0,0},
							{0,0,0,1,0,0},
                            {0,0,0,0,1,0},
							{0,0,0,0,0,1},
							{1,0,0,0,0,0},
                            {0,1,0,0,0,0},
							{1,1,0,0,0,0},
							{0,0,1,1,0,0},
							{0,0,0,0,1,1},
							{0,0,0,1,1,1},
							{1,1,1,0,0,0},
							{0,0,0,0,0,0},
                            {1,1,1,1,1,1},
                            };

 char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  
	for (int i=0;i<14;i++)
	{
		ret=MobiHeart->SetConfig(Config[i]);
		sprintf(temp, "bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,(Config[i].bLegs)?1:0,(Config[i].bFingers)?1:0);
		ASSERT_VAL(MOBI_SUCCEED,ret, "SetConfig()", temp);

		MobiHeart->GetConfig(tConfig);
		ASSERT_VAL(Config[i].bFFT,tConfig.bFFT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFR,tConfig.bFR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bBT,tConfig.bBT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bGR,tConfig.bGR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bLegs,tConfig.bLegs,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFingers,tConfig.bFingers,"GetConfig()",temp);

		MobiHeart->EnableLegs(true);
		MobiHeart->GetConfig(tConfig);
		sprintf(temp, "After setting true: bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,1,(Config[i].bFingers)?1:0);
		ASSERT_VAL(1,tConfig.bLegs,"GetConfig()",temp);

        MobiHeart->EnableLegs(false);
		MobiHeart->GetConfig(tConfig);
		sprintf(temp, "After setting false: bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,0,(Config[i].bFingers)?1:0);
		ASSERT_VAL(0,tConfig.bLegs,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFFT,tConfig.bFFT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFR,tConfig.bFR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bBT,tConfig.bBT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bGR,tConfig.bGR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFingers,tConfig.bFingers,"GetConfig()",temp);


	}												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then EnableLegs() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

bool test_MobiHeart_EnableFingers()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiHEARTConfig tConfig;
  MobiHEARTConfig Config[]={
	                        {0,0,1,1,0,0},
							{0,0,1,0,0,0},
							{0,0,0,1,0,0},
                            {0,0,0,0,1,0},
							{0,0,0,0,0,1},
							{1,0,0,0,0,0},
                            {0,1,0,0,0,0},
							{1,1,0,0,0,0},
							{0,0,1,1,0,0},
							{0,0,0,0,1,1},
							{0,0,0,1,1,1},
							{1,1,1,0,0,0},
							{0,0,0,0,0,0},
                            {1,1,1,1,1,1},
                            };

 char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  
	for (int i=0;i<14;i++)
	{
		ret=MobiHeart->SetConfig(Config[i]);
		sprintf(temp, "bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,(Config[i].bLegs)?1:0,(Config[i].bFingers)?1:0);
		ASSERT_VAL(MOBI_SUCCEED,ret, "SetConfig()", temp);

		MobiHeart->GetConfig(tConfig);
		ASSERT_VAL(Config[i].bFFT,tConfig.bFFT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFR,tConfig.bFR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bBT,tConfig.bBT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bGR,tConfig.bGR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bLegs,tConfig.bLegs,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFingers,tConfig.bFingers,"GetConfig()",temp);

		MobiHeart->EnableFingers(true);
		MobiHeart->GetConfig(tConfig);
		sprintf(temp, "After setting finger true: bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,(Config[i].bLegs)?1:0,1);
		ASSERT_VAL(1,tConfig.bFingers,"GetConfig()",temp);

        MobiHeart->EnableFingers(false);
		MobiHeart->GetConfig(tConfig);
		sprintf(temp, "After setting finger false: bFFT:%d, bFR:%d, bBT:%d, bGR:%d, bLegs:%d, bFingers:%d",(Config[i].bFFT)?1:0,(Config[i].bFR)?1:0,(Config[i].bBT)?1:0,(Config[i].bGR)?1:0,(Config[i].bLegs)?1:0,0);
		ASSERT_VAL(0,tConfig.bFingers,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFFT,tConfig.bFFT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bFR,tConfig.bFR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bBT,tConfig.bBT,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bGR,tConfig.bGR,"GetConfig()",temp);
		ASSERT_VAL(Config[i].bLegs,tConfig.bLegs,"GetConfig()",temp);


	}												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then EnableFingers() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



bool test_MobiHeart_ProcessFrame()
{
  suc = true;
  IMobiHEART* MobiHeart;
  MobiHeart=NULL;
  int ret;
  MobiGRConfig LConfig;
  MobiHEARTConfig HeartConfig;
  MobiBTConfig BTConfig, BTConfig1;

  char temp[200];

  try
  {

    MobiHeart=CreateMobiHEART();
	if (!MobiHeart)
	{
		fprintf(fp,"\\\\\\line: %d,  Function CreateMobiHEART() return failed\n", __LINE__);
		return false;
	}
	ret=MobiHeart->Initialize("licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");
	ASSERT_VAL(MOBI_SUCCEED,ret, "Initialize()", "License: licensor = Mobinex Inc.;licensee = ;software = MBTE SDK;hostid = af751e83;expires = 20110630;platform = WIN32;signature = 8FF0DB2BFB72D04586FA15FCD18E06760CAD9283C30863299C93DD4318172633CAB0EB24B3F77F02830B9F22A0B42AADE9E1304D722305542E160256FC78ECF0485CD6F41DDF181011A800F4A43024A18A43B94047D87339FA14DDE9F832A8248ECFB953498171636E8147FC3D0D53CE45F89232E356340D7F2D0FB0DD97FDFFDAAD1C7D6A58EBADB092CBB07072C7A34D50B14ECEAF9722AF12405FA26AA2DA9C573ECA5F46E40F8104614298D710C1D1F7DD4E5B1F7CE9820BC500EE032BF9763873545E50854496F7898A94D4371AC98F9EC70EB8CF513A0C85BC57C3DF6BEC8699106B3803F07AD8AA2F001C6E611BF3C47FC12E70AF45FCCD6262951400;");  
    MobiHeart->SetImgFormat(320*3,240,320,MOBI_CM_RGB,true);
	LConfig.modeGR=GR_MOTION_EXT_1;
	MobiHeart->SetGRConfig(LConfig);

	 HeartConfig.bBT=true;
	 HeartConfig.bFFT=false;
	 HeartConfig.bFingers=false;
	 HeartConfig.bFR=false;
	 HeartConfig.bGR=true;
	 HeartConfig.bLegs=false;
	 MobiHeart->SetConfig(HeartConfig);

	 BTConfig.maxNum=1;
	 BTConfig.modeBT=0;
	 MobiHeart->SetBTConfig(BTConfig);
	 pMobiHeart=MobiHeart;
	 pBuffer1=new BYTE[320*240*3];


     StartWebcam(); 
	 printf("Press Enter key to exit...");
	 std::cin.get();

	 EndProgram=true;
	 Sleep(100);
	 if (pBuffer1)
	 {
	 delete[] pBuffer1;
	 pBuffer1=NULL;
	 }

												

	ReleaseMobiHEART(&MobiHeart);

  }
  catch(...)
  {
	fprintf(fp,"\\\\\\line: %d, Function CreateMobiHEART() then ProcessFrame() crashed\n", __LINE__);
    return false;
	
  }

  return suc;
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////




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
//	FILE* fp = NULL;
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
//    StartWebcam();       //If do not need to start webcam for testing, just comment out this line.
 //////Please add the test case here.





     if(func_num==-1)        //Test all cases;
	 {

//		TEST_L(test_module,test_func);	
		 TEST_L(MobiHeart, CreateReleaseMobiHEART);
		 TEST_L(MobiHeart, Initialize);
         TEST_L(MobiHeart, SetImgFormat);
		 TEST_L(MobiHeart, SetGetConfig);
		 TEST_L(MobiHeart, SetGetBTConfig);
		 TEST_L(MobiHeart, SetGetGRConfig);
		 TEST_L(MobiHeart, GetGRModes);
		 TEST_L(MobiHeart,GetGRModeName);
		 TEST_L(MobiHeart,GetGRGestures);
		 TEST_L(MobiHeart,GetGRGestureName);
		 TEST_L(MobiHeart,EnableLegs);
		 TEST_L(MobiHeart,EnableFingers);
		 TEST_L(MobiHeart,ProcessFrame);

	//	 StartWebcam();       //If do not need to start webcam for testing, just comment out this line.

	 }

	 else
	 {
		 switch (func_num) 
		 {
			case 1:   TEST_L(MobiHeart, CreateReleaseMobiHEART);  break;//case1;
			case 2:   TEST_L(MobiHeart, Initialize);     break;         //case2:
			case 3:   TEST_L(MobiHeart, SetImgFormat);   break;
			case 4:   TEST_L(MobiHeart, SetGetConfig);   break;
			case 5:   TEST_L(MobiHeart, SetGetBTConfig); break;
			case 6:   TEST_L(MobiHeart, SetGetGRConfig); break;
			case 7:   TEST_L(MobiHeart, GetGRModes);     break;
			case 8:   TEST_L(MobiHeart,GetGRModeName);   break;
			case 9:   TEST_L(MobiHeart,GetGRGestures);   break;
			case 10:  TEST_L(MobiHeart,GetGRGestureName); break;
			case 11:  TEST_L(MobiHeart,EnableLegs);       break;
			case 12:  TEST_L(MobiHeart,EnableFingers);    break;
			case 13:  TEST_L(MobiHeart,ProcessFrame);     break;
		    default:  Sleep(5000); fprintf(fp,"please input correct case number\n"); break;

		 
		 
		 }
	 
	 
		 if (!(func_num==13))  
		 {
			 printf("Press Enter key to exit...");
			 std::cin.get();
		 }
	 
	 }

	fprintf(fp,"End Testing.\n");

	fclose(fp);
	ExitTesting();

	return 0;
}

