
// HK_DTS.h : PROJECT_NAME Ӧ�ó������ͷ�ļ�
//

#pragma once

#ifndef __AFXWIN_H__
	#error "�ڰ������ļ�֮ǰ������stdafx.h�������� PCH �ļ�"
#endif

#include "resource.h"		// ������


// CHK_DTSApp:
// �йش����ʵ�֣������ HK_DTS.cpp
//

class CHK_DTSApp : public CWinApp
{
public:
	CHK_DTSApp();

// ��д
public:
	virtual BOOL InitInstance();

// ʵ��

	DECLARE_MESSAGE_MAP()
};

extern CHK_DTSApp theApp;