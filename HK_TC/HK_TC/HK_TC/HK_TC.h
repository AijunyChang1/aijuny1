
// HK_TC.h : PROJECT_NAME Ӧ�ó������ͷ�ļ�
//

#pragma once

#ifndef __AFXWIN_H__
	#error "�ڰ������ļ�֮ǰ������stdafx.h�������� PCH �ļ�"
#endif

#include "resource.h"		// ������


// CHK_TCApp:
// �йش����ʵ�֣������ HK_TC.cpp
//

class CHK_TCApp : public CWinApp
{
public:
	CHK_TCApp();

// ��д
public:
	virtual BOOL InitInstance();

// ʵ��

	DECLARE_MESSAGE_MAP()
};

extern CHK_TCApp theApp;