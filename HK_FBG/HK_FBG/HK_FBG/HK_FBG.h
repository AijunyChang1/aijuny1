
// HK_FBG.h : PROJECT_NAME Ӧ�ó������ͷ�ļ�
//

#pragma once

#ifndef __AFXWIN_H__
	#error "�ڰ������ļ�֮ǰ������stdafx.h�������� PCH �ļ�"
#endif

#include "resource.h"		// ������


// CHK_FBGApp:
// �йش����ʵ�֣������ HK_FBG.cpp
//

class CHK_FBGApp : public CWinApp
{
public:
	CHK_FBGApp();

// ��д
public:
	virtual BOOL InitInstance();

// ʵ��

	DECLARE_MESSAGE_MAP()
};

extern CHK_FBGApp theApp;