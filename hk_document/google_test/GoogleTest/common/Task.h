#pragma once

#include <vector>
#include "Util.h"

using namespace std;

class CTask{
public:
	virtual void run()=0;
	virtual const wchar_t* toString()=0;
	virtual ~CTask(){};
};

class CTaskQueue{
	HANDLE m_lock;
	vector<CTask*> m_tasks;
public:
	CTaskQueue();
	~CTaskQueue();
	bool putTask(CTask* pTask);
	bool getTask(CTask *& pTask, int nTimeout=100);
	bool runAll();
	bool runOne();
	size_t length();
};
