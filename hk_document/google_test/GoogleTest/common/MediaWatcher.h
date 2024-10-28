#pragma once
#include <vector>
using namespace std;

///\addtogroup CommonLib
///@{

///\brief Client implement this interface to receive notifications of media file folder changes.
class IMediaWatchListener{
public:
	virtual void OnFileChanged(const wchar_t* fpath_new, const wchar_t* fpath_old)=0;
};

class CFSWatcher;
class IFSListener;
///\brief This class monitor a specific group folders for their changes.
class CMediaWatcher{
public:
	CMediaWatcher(IMediaWatchListener* pListener);
	virtual ~CMediaWatcher(void);
	void addDir( const wchar_t* szGroupName, const wchar_t* szDir, const wchar_t* szFilters );///< Add folder to monitor.
	int check(); ///< Check changes. \b Must be called periodly.

private:
	IMediaWatchListener* m_pListener;
	vector<CFSWatcher*> m_watchers;
	vector<IFSListener*> m_listeners;

};

///@}