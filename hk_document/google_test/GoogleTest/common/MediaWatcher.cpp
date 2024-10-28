#include "StdAfx.h"
#include "MediaWatcher.h"

#include <string>
#include "Util.h"
#include "FSUtil.h"
#include "FSWatcher.h"

using namespace std;
namespace FS=FileSystem;

/**
 \brief Receive file system changes and send notifications to a IMediaWatchListener.
 */
class MyFSListener : public IFSListener{
	wstring m_group;
	IMediaWatchListener *m_pListener;
	vector<wstring> m_filters;
public:
	MyFSListener(const wchar_t* sGroup, IMediaWatchListener *pListener, const wstring filters) : m_group(sGroup), m_pListener(pListener){
		Util::split(filters, L";", m_filters);
	}

	virtual void notifyChange(const wchar_t* psDir, DWORD action, const wchar_t* fileName){
		USES_CONVERSION;

		{
			bool bMatch = false;
			for(size_t i=0; i<m_filters.size(); i++){
				wstring fname = fileName;
				fname = Util::strtolower(fname);
				if(Util::endsWith(fname, m_filters[i])){
					bMatch = true;
					break;
				}
			}
			if(!bMatch) return;
		}

		wstring fileStr = fileName;
		fileStr += L"|";
		fileStr += m_group;
		fileStr += L"|";
		{
			wstring sTime;
			WIN32_FILE_ATTRIBUTE_DATA wfad;
			GetFileAttributesExW(fileName, GetFileExInfoStandard, &wfad);
			FileSystem::FileTimeToStr(wfad.ftLastWriteTime, sTime);

			fileStr += sTime;
		}
		fileStr += L"|";

		{
			wstring ext = Util::getExt(fileName);
			if(_wcsicmp(ext.c_str(), L"mp3")==0){
				wstring sPath = psDir;
				sPath += fileName;
				string sArtist;
				if( CFSUtil::getMp3Artist(sPath.c_str(), sArtist)){
					fileStr += A2W(sArtist.c_str());
				}
			}
		}
		switch(action){
			case FILE_ACTION_REMOVED:
			case FILE_ACTION_RENAMED_OLD_NAME:
				m_pListener->OnFileChanged(L"", fileStr.c_str());
				break;
			case FILE_ACTION_ADDED:
			case FILE_ACTION_RENAMED_NEW_NAME:
				m_pListener->OnFileChanged(fileStr.c_str(), L"");
				break;
		}
	}
};

CMediaWatcher::CMediaWatcher(IMediaWatchListener* pListener) : m_pListener(pListener)
{
	struct{
		FS::FolderType eFolder;
		const wchar_t* groupName;
		const wchar_t* filters;
	}initData[]={
		{FS::eMyMusic, L"music_current", L".mp3"},
		{FS::eCommonMusic, L"music_all", L".mp3"},
		{FS::eMyVideo, L"video_current", L".flv"},
		{FS::eCommonVideo, L"video_all", L".flv"},
		{FS::eMyPictures, L"photo_current", L".jpg;.png"},
		{FS::eCommonPictures, L"photo_all", L".jpg;.png"},
	};

	for(size_t i=0; i<_countof(initData); i++){
		wstring sDir;
		FS::getSpecialDirW(initData[i].eFolder, sDir);
		addDir(initData[i].groupName, sDir.c_str(), initData[i].filters);
	}
}

CMediaWatcher::~CMediaWatcher(void)
{
	for(size_t i=0; i<m_watchers.size(); i++){
		delete m_watchers[i];
	}
	m_watchers.clear();
	for(size_t i=0; i<m_watchers.size(); i++){
		delete m_listeners[i];
	}
	m_listeners.clear();
}

int CMediaWatcher::check()
{
	int nRet = 0;
	for(size_t i=0; i<m_watchers.size(); i++){
		if(m_watchers[i]->check()){
			nRet++;
		}
	}
	return nRet;
}

void CMediaWatcher::addDir( const wchar_t* szGroupName, const wchar_t* szDir, const wchar_t* filters )
{
	IFSListener* pListener = new MyFSListener(szGroupName, m_pListener, filters);
	CFSWatcher* pWatcher = new CFSWatcher(szDir, pListener);
	m_listeners.push_back(pListener);
	m_watchers.push_back(pWatcher);
}