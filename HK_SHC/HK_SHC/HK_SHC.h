
// HK_SHC.h : PROJECT_NAME Ӧ�ó������ͷ�ļ�
//

#pragma once

#ifndef __AFXWIN_H__
	#error "�ڰ������ļ�֮ǰ������stdafx.h�������� PCH �ļ�"
#endif

#include "resource.h"		// ������


// CHK_SHCApp:
// �йش����ʵ�֣������ HK_SHC.cpp
//

class CHK_SHCApp : public CWinApp
{
public:
	CHK_SHCApp();

// ��д
public:
	virtual BOOL InitInstance();

// ʵ��

	DECLARE_MESSAGE_MAP()
};

extern CHK_SHCApp theApp;