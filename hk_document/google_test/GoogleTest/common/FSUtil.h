#pragma once
#include <map>
#include <string>
using namespace std;

///\addtogroup CommonLib
///@{

///\brief Determine if the application is in the Teli's support list.
class CAppFilter{
public:
	map<wstring, wstring> m_apps;
	
	bool isApproved(const wstring path, wstring& name);
};

///\brief Do file system related miscellaneous works.
class CFSUtil
{
public:
	CFSUtil(void);
	~CFSUtil(void);

	static bool genFileList(); ///<Search and generate list of files in specific folder and with specific extensions.
	static bool genAppList(CAppFilter& af); ///<Search and generate list of application path that may be supported by Teli.
	static bool getMp3ArtistUtf8(const wchar_t* sPath, string& sArtist);///<Get artist information of a mp3 file from its tag.
	static bool getMp3Artist(const wchar_t* sPath, string& sArtist); ///<Get artist information of a mp3 file from its tag.

	static bool getPicFolderFirst(wstring& fPath); ///<Return the first picture file found in My Pictures folder. Return false if not file found.
	static bool genVideoPlaylist(); ///<Generate play list file for windows media player.
};

///@}
