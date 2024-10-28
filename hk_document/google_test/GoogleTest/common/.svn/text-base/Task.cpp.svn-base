#include "StdAfx.h"
#include "Task.h"


CTaskQueue::CTaskQueue()
{
	m_lock = ::CreateMutex(NULL, FALSE, NULL);
}

CTaskQueue::~CTaskQueue()
{
	if(::WaitForSingleObject(m_lock, 5000)==WAIT_OBJECT_0){
		for(size_t i=0; i<m_tasks.size(); i++){
			delete m_tasks[i];
		}
		m_tasks.clear();
	}
	::ReleaseMutex(m_lock);
}

bool CTaskQueue::putTask( CTask* pTask )
{
	bool ret = false;
	if(::WaitForSingleObject(m_lock, 100)==WAIT_OBJECT_0){
		m_tasks.push_back(pTask);
		ret = true;
		::ReleaseMutex(m_lock);
	}
	return ret;
}

bool CTaskQueue::getTask( CTask *& pTask, int nTimeout/*=100*/ )
{
	bool ret = false;
	if(::WaitForSingleObject(m_lock, nTimeout)==WAIT_OBJECT_0){
		if(!m_tasks.empty()){
			pTask = m_tasks[0];
			pTask = m_tasks.front();
			m_tasks.erase(m_tasks.begin());
			ret = true;
		}
		::ReleaseMutex(m_lock);
	}
	return ret;
}

bool CTaskQueue::runAll()
{
	bool ret = false;
	if(::WaitForSingleObject(m_lock, 10)==WAIT_OBJECT_0){
		if(!m_tasks.empty()){
			//const int nTasks = m_tasks.size();
			//if(nTasks>2){
			//	Logger::warn(L"There're %d tasks!\n", nTasks);
			//	for(size_t i=0; i<nTasks; i++){
			//		Logger::warn(m_tasks[i]->toString());
			//	}
			//}
			for(size_t i=0; i<m_tasks.size(); i++){
				m_tasks[i]->run();
				delete m_tasks[i];
			}
			m_tasks.clear();
			ret = true;
		}else{
			//Logger::warn(L"There is no task!\n");
			ret = true;
		}
		::ReleaseMutex(m_lock);
	}
	return ret;
}

bool CTaskQueue::runOne()
{
	bool ret = false;
	if(::WaitForSingleObject(m_lock, 10)==WAIT_OBJECT_0){
		if(!m_tasks.empty()){
			CTask* pTask = *m_tasks.begin();
			pTask->run();
			m_tasks.erase(m_tasks.begin());
			delete pTask;
			ret = true;
		}else{
			//Logger::warn(L"There is no task!\n");
			ret = true;
		}
		::ReleaseMutex(m_lock);
	}
	return ret;
}

size_t CTaskQueue::length()
{
	return m_tasks.size();
}