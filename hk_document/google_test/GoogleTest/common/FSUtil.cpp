#include "StdAfx.h"
#include "FSUtil.h"
#include "Util.h"

#include <set>
#include <string>
#include <cstdio>
using namespace std;

#pragma pack(push, 1)
struct Mp3Tag{
	char header[3];
	char title[30];
	char artist[30];
	char album[30];
	char year[4];
	char no_track;
	char track;
	char genre;
};
#pragma pack(pop)

///\addtogroup CommonLib
///@{

///\brief Common processing for generating a xml-format file list of files in specific folder.
class FindMediaBase : public FileSystem::CFind{
public:
	vector<wstring> m_dirStack;
	FILE *m_fh;
	FindMediaBase(const wchar_t* dirPath=NULL, FILE* fh=NULL) : CFind(dirPath), m_fh(fh){}
	bool run(){
		m_dirStack.push_back(m_dirPath);
		wstring sDirPat = m_dirPath;
		sDirPat += L"\\*";

		bool ret = _walk(sDirPat);
		m_dirStack.pop_back();
		return ret;
	}
	virtual bool onDirItem(WIN32_FIND_DATAW &wfd){
		wstring info = wfd.cFileName;
		string info_u8 = Util::toUtf8(info.c_str(), info.size()+1);
		info_u8 = Util::xmlEscape(info_u8);
		if(m_fh) fprintf(m_fh, "\t\t<folder title=\"%s\">\n", info_u8.c_str());
		wstring s = m_dirPath;
		s+=L"\\";
		s+=wfd.cFileName;
		m_dirStack.push_back(s);
		s+=L"\\*";
		_walk(s);
		m_dirStack.pop_back();
		if(m_fh) fprintf(m_fh, "\t\t</folder>\n");
		return true;
	}
};

///\brief Find jpg and png files.
class FindPictures : public FindMediaBase{
public:
	FindPictures(const wchar_t* dirPath, FILE* fh) : FindMediaBase(dirPath, fh){
	}

	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = wfd.cFileName;
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"jpg" || ext==L"png"){
			wstring sTime;
			FileSystem::FileTimeToStr(wfd.ftLastWriteTime, sTime);
			string info_u8 = Util::toUtf8(info.c_str(), info.size()+1);
			info_u8 = Util::xmlEscape(info_u8);
			fprintf(m_fh, "\t\t<file title=\"%s\" modifiedTime=\"%s\"/>\n", info_u8.c_str(), sTime.c_str());
		}
		return true;
	}
};

///\brief Find first picture file.
class FindFirstPicture : public FindMediaBase{
public:
	wstring m_path;
	FindFirstPicture(const wchar_t* dirPath) : FindMediaBase(dirPath){
	}

	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = wfd.cFileName;
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"jpeg" || ext==L"jpg" || ext==L"png" || ext==L"bmp"){
			m_path = m_dirStack.back();
			m_path += L"\\";
			m_path += info;
			return false;
		}
		return true;
	}
};

///\brief Find vidoe files.
class FindVideo : public FindMediaBase{
public:
	FindVideo(const wchar_t* dirPath, FILE* fh) : FindMediaBase(dirPath, fh){
	}
	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = Util::xmlEscape(wfd.cFileName);
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"flv" || ext==L"avi"){
			wstring sTime;
			FileSystem::FileTimeToStr(wfd.ftLastWriteTime, sTime);
			string info_u8 = Util::toUtf8(info.c_str(), info.size()+1);
			info_u8 = Util::xmlEscape(info_u8);
			fprintf(m_fh, "\t\t<file title=\"%s\" artist=\"\" modifiedTime=\"%s\"/>\n", info_u8.c_str(), sTime.c_str());
		}
		return true;
	}
};

///\brief Find media files and generate a playlist file for windows media player.
class FindGenVideoPlaylist : public FindMediaBase{
public:
	FindGenVideoPlaylist(const wchar_t* dirPath, FILE* fh) : FindMediaBase(dirPath, fh){
	}
	virtual bool onDirItem(WIN32_FIND_DATAW &wfd){
		wstring s = m_dirPath;
		s+=L"\\";
		s+=wfd.cFileName;
		m_dirStack.push_back(s);
		s+=L"\\*";
		_walk(s);
		m_dirStack.pop_back();
		return true;
	}
	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = Util::xmlEscape(m_dirStack.back()+L"\\"+wfd.cFileName);
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"mp3" || ext==L"wma" || ext==L"avi" || ext==L"wmv" || ext==L"asf"){
			string info_u8 = Util::toUtf8(info.c_str(), info.size()+1);
			info_u8 = Util::xmlEscape(info_u8);
			fprintf(m_fh, "\t\t\t<media src=\"%s\" />\n", info_u8.c_str());
		}
		return true;
	}
};

///\brief Find music files.
class FindMusic : public FindMediaBase{
public:
	FindMusic(const wchar_t* dirPath, FILE* fh) : FindMediaBase(dirPath, fh){
	}
	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = wfd.cFileName;
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"mp3"){
			wstring sTime;
			FileSystem::FileTimeToStr(wfd.ftLastWriteTime, sTime);
			string info_u8 = Util::toUtf8(info.c_str(), info.size()+1);
			info_u8 = Util::xmlEscape(info_u8);
			wstring fullPath = m_dirStack.back() + L"\\" + wfd.cFileName;

			string u8Artist;
			//CFSUtil::getMp3ArtistUtf8(fullPath.c_str(), u8Artist);
			wstring wsArtist;
			wsArtist = Util::getMp3Artist(fullPath.c_str());
			if(wsArtist.length()){
				u8Artist = Util::toUtf8(wsArtist.c_str(), wsArtist.length()+1);
			}

			u8Artist = Util::xmlEscape(u8Artist);
			fprintf(m_fh, "\t\t<file title=\"%s\" artist=\"%s\" modifiedTime=\"%s\"/>\n", info_u8.c_str(), u8Artist.c_str(), sTime.c_str());
		}
		return true;
	}
};

///\brief Find jpg and png files.
class FindEBooks : public FindMediaBase{
public:
	FindEBooks(const wchar_t* dirPath, FILE* fh) : FindMediaBase(dirPath, fh){
	}

	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = wfd.cFileName;
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"epub"){
			wstring sTime;
			FileSystem::FileTimeToStr(wfd.ftLastWriteTime, sTime);
			string info_u8 = Util::toUtf8(info.c_str(), info.size()+1);
			info_u8 = Util::xmlEscape(info_u8);
			fprintf(m_fh, "\t\t<file title=\"%s\" modifiedTime=\"%s\"/>\n", info_u8.c_str(), sTime.c_str());
		}
		return true;
	}
};

///\brief Find shotcut files (.lnk) in specific folders.
class FindSLink : public FileSystem::CFind{
	set<wstring> m_exeCache;
public:
	vector<wstring> m_dirStack;
	FILE *m_fh;
	CAppFilter& m_af;

	FindSLink(const wchar_t* dirPath, FILE* fh, CAppFilter& af) : CFind(dirPath), m_fh(fh), m_af(af){}
	bool run(){
		m_dirStack.push_back(m_dirPath);
		wstring sDirPat = m_dirPath;
		sDirPat += L"\\*";

		bool ret = _walk(sDirPat);
		m_dirStack.pop_back();
		return ret;
	}
	virtual bool onDirItem(WIN32_FIND_DATAW &wfd){
		wstring s = m_dirStack.back();
		s+=L"\\";
		s+=wfd.cFileName;
		m_dirStack.push_back(s);
		s+=L"\\*";
		bool ret = _walk(s);
		m_dirStack.pop_back();
		return ret;
	}
	virtual bool onFileItem(WIN32_FIND_DATAW &wfd){
		wstring info = wfd.cFileName;
		wstring ext = info.substr(info.rfind(L'.')+1);
		ext = Util::strtolower(ext);
		if(ext==L"lnk"){
			wstring lnkPath = m_dirStack.back() + L"\\" + wfd.cFileName;
			wstring targetPath;
			if(getLnkTarget(lnkPath.c_str(), targetPath)){
				string lnkPathUtf8 = Util::toUtf8(lnkPath.c_str(), lnkPath.size()+1);

				//fprintf(m_fh, "\t\t<app title=\"%s\" target=\"%s\"/>\n", lnkPathUtf8.c_str(), targetPath.c_str());
				//find app
				wstring appName;
				wstring startPath;
				size_t pos0 = targetPath.rfind(L'\\');
				size_t pos1 = targetPath.rfind(L".exe");
				if(pos0!=string::npos && pos1!=string::npos){
					//ends with ".exe"
					wstring title = targetPath.substr(pos0+1, pos1-pos0+3);
					if(m_exeCache.find(title)==m_exeCache.end()){
						m_exeCache.insert(title);
						if(targetPath.size() && m_af.isApproved(targetPath, appName)){
							startPath = targetPath;
						}
					}
				}else if(m_af.isApproved(lnkPath, appName)){
					startPath = lnkPath;
				}
				if(appName.size()){
					USES_CONVERSION;
					string startPath_u8 = Util::toUtf8(startPath.c_str(), startPath.size());
					startPath_u8 = Util::xmlEscape(startPath_u8);
					fprintf(m_fh, "\t\t<app title=\"%s\" path=\"%s\"/>\n", W2A(appName.c_str()), startPath_u8.c_str());
				}
				//Logger::info("getLnkTarget succeed: %s --> %s\n", lnkPath.c_str(), targetPath.c_str());
				if(lnkPath.size()==0){
					Logger::info(L"%s\n -->", lnkPath.c_str());
					Logger::info(L"\t%s\n", targetPath.c_str());
				}
			}else{
				Logger::error(L"getLnkTarget fail: %s", lnkPath.c_str());
			}
		}
		return true;
	}
	static bool getLnkTarget(const wchar_t* lnkPath, wstring &targetPath){
		HRESULT hres = S_OK;

		wstring info;
		IShellLinkW* psl;
		//Create the ShellLink object
		hres = CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER, IID_IShellLinkW, (LPVOID*) &psl);

		if (SUCCEEDED(hres)){
			IPersistFile* ppf;
			//Bind the ShellLink object to the Persistent File
			hres = psl->QueryInterface( IID_IPersistFile, (LPVOID *) &ppf);
			if (SUCCEEDED(hres)){
				//Read the link into the persistent file
				hres = ppf->Load(lnkPath, 0);

				if (SUCCEEDED(hres)){
					//Read the target information from the link object
					//UNC paths are supported (SLGP_UNCPRIORITY)
					WCHAR buf[1024];
					hres = psl->GetPath(buf, 1024, NULL, SLGP_UNCPRIORITY);
					if(buf[0]==0){
						Logger::warn(L"Can't get path of %s", lnkPath);
						LPITEMIDLIST pil;
						hres = psl->GetIDList(&pil);
						if(SUCCEEDED(hres)){
							wchar_t pszPath[MAX_PATH];
							BOOL ret = SHGetPathFromIDListW(pil, pszPath);
							if(ret){
								info = pszPath;
								Logger::info("SHGetPathFromIDListA -> %s", pszPath);
							}
						}
					}
					info = buf;

					//Read the arguments from the link object
					//psl->GetArguments(buf, 1024);
					//info += " ";
					//info += buf;
				}
			}
		}
		psl->Release();
		//Return the Target and the Argument as a CString
		targetPath = info;
		return true;
	}
};

CFSUtil::CFSUtil(void)
{
}

CFSUtil::~CFSUtil(void)
{
}

bool CFSUtil::genFileList()
{
	//write filelist.xml
	FILE *fh = NULL;
	errno_t e = fopen_s(&fh, "filelist.xml", "w");
	if(e){
		Logger::error(L"Create filelist.xml fail!");
		return false;
	}
	fprintf(fh, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
	fprintf(fh, "<groups>\n");

	//pic group
	{
		wstring sPicDir;

		//for all user
		//{
		//	FileSystem::getSpecialDirA(FileSystem::eCommonPictures, sPicDir);
		//	fprintf(fh, "\t<photo title=\"all\" path=\"%s\">\n", sPicDir.c_str());
		//	FindPictures fp(sPicDir.c_str(), fh);
		//	fp.run();
		//	fprintf(fh, "\t</photo>\n");
		//}

		//for current user
		{
			FileSystem::getSpecialDirW(FileSystem::eMyPictures, sPicDir);
			sPicDir = Util::xmlEscape(sPicDir);
			string u8buf = Util::toUtf8(sPicDir.c_str(), sPicDir.length()+1);
			fprintf(fh, "\t<photo title=\"current\" path=\"%s\">\n", u8buf.c_str());
			FindPictures fp(sPicDir.c_str(), fh);
			fp.run();
			fprintf(fh, "\t</photo>\n");
		}
	}

	//video group
	{
		wstring sVideoDir;

		//for all user
		//{
		//	FileSystem::getSpecialDirA(FileSystem::eCommonVideo, sVideoDir);
		//	fprintf(fh, "\t<video title=\"all\" path=\"%s\">\n", sVideoDir.c_str());

		//	FindVideo fv(sVideoDir.c_str(), fh);
		//	fv.run();
		//	fprintf(fh, "\t</video>\n");
		//}

		//for current user
		{
			FileSystem::getSpecialDirW(FileSystem::eMyVideo, sVideoDir);
			sVideoDir = Util::xmlEscape(sVideoDir);
			string u8buf = Util::toUtf8(sVideoDir.c_str(), sVideoDir.length()+1);
			fprintf(fh, "\t<video title=\"current\" path=\"%s\">\n", u8buf.c_str());

			FindVideo fv(sVideoDir.c_str(), fh);
			fv.run();
			fprintf(fh, "\t</video>\n");
		}
	}

	//music group
	{
		wstring sMusicDir;

		//for all user
		//{
		//	FileSystem::getSpecialDirA(FileSystem::eCommonMusic, sMusicDir);
		//	fprintf(fh, "\t<music title=\"all\" path=\"%s\">\n", sMusicDir.c_str());
		//	FindMusic fm(sMusicDir.c_str(), fh);
		//	fm.run();
		//	fprintf(fh, "\t</music>\n");
		//}

		//for current user
		{
			FileSystem::getSpecialDirW(FileSystem::eMyMusic, sMusicDir);
			sMusicDir = Util::xmlEscape(sMusicDir);
			string u8buf = Util::toUtf8(sMusicDir.c_str(), sMusicDir.length()+1);
			fprintf(fh, "\t<music title=\"current\" path=\"%s\">\n", u8buf.c_str());
			FindMusic fm(sMusicDir.c_str(), fh);
			fm.run();
			fprintf(fh, "\t</music>\n");
		}
	}
	//Ebook Group
	{
		wstring sEBookDir;
		//for current user
		{
			FileSystem::getSpecialDirW(FileSystem::eMyDocuments, sEBookDir);
			sEBookDir += L"\\My EBook";
			sEBookDir = Util::xmlEscape(sEBookDir);
			string u8buf = Util::toUtf8(sEBookDir.c_str(), sEBookDir.length()+1);
			fprintf(fh, "\t<ebook title=\"current\" path=\"%s\">\n", u8buf.c_str());
			FindEBooks fp(sEBookDir.c_str(), fh);
			fp.run();
			fprintf(fh, "\t</ebook>\n");
		}
	}
	fprintf(fh, "</groups>\n");
	fclose(fh);

	return true;
}

bool CFSUtil::genAppList(CAppFilter& af)
{
	//write filelist.xml
	FILE *fh = NULL;
	errno_t e = fopen_s(&fh, "apps.xml", "w");
	if(e){
		Logger::error(L"Create apps.xml fail!");
		return false;
	}
	::CoInitialize(NULL);

	//fprintf(fh, "<?xml version=\"1.0\" encoding=\"gb2312\"?>\n");
	fprintf(fh, "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");
	fprintf(fh, "<apps>\n");

	//check firefox and google earth default path
	{
		wstring sProgFiles;
		FileSystem::getSpecialDirW(FileSystem::eProgFiles, sProgFiles);

		wstring sPathFirefox = sProgFiles + L"\\Mozilla Firefox\\firefox.exe";
		if(Util::fileExists(sPathFirefox.c_str())){
			wstring appName;
			if(af.isApproved(sPathFirefox, appName)){
				USES_CONVERSION;
				string startPath_u8 = Util::toUtf8(sPathFirefox.c_str(), sPathFirefox.length()+1);
				startPath_u8 = Util::xmlEscape(startPath_u8);
				fprintf(fh, "\t\t<app title=\"%s\" path=\"%s\"/>\n", W2A(appName.c_str()), startPath_u8.c_str());
			}
		}

		wstring sLocalAppData;
		FileSystem::getSpecialDirW(FileSystem::eLocalAppData, sLocalAppData);
		//"C:\Documents and Settings\xiaofeng.hu\Local Settings\Application Data\Google\Chrome\Application\chrome.exe"
		wstring sPathGoogleearth = sLocalAppData + L"\\Google\\Chrome\\Application\\chrome.exe";
		if(Util::fileExists(sPathGoogleearth.c_str())){
			wstring appName;
			if(af.isApproved(sPathGoogleearth, appName)){
				USES_CONVERSION;
				string startPath_u8 = Util::toUtf8(sPathGoogleearth.c_str(), sPathGoogleearth.length()+1);
				startPath_u8 = Util::xmlEscape(startPath_u8);
				fprintf(fh, "\t\t<app title=\"%s\" path=\"%s\"/>\n", W2A(appName.c_str()), startPath_u8.c_str());
			}
		}
	}

	//current user start menu
	{
		wstring sStartMenu;
		FileSystem::getSpecialDirW(FileSystem::eMyStartMenu, sStartMenu);
		FindSLink fslink(sStartMenu.c_str(), fh, af);
		fslink.run();
	}

	//all users start menu
	{
		wstring sStartMenu;
		FileSystem::getSpecialDirW(FileSystem::eCommonStartMenu, sStartMenu);
		FindSLink fslink(sStartMenu.c_str(), fh, af);
		fslink.run();
	}

	//quick launch
	{
		//"Microsoft\Internet Explorer\Quick Launch"
		wstring sQuickLaunch;
		FileSystem::getSpecialDirW(FileSystem::eAppData, sQuickLaunch);
		sQuickLaunch += L"\\Microsoft\\Internet Explorer\\Quick Launch";
		FindSLink fslink(sQuickLaunch.c_str(), fh, af);
		fslink.run();
	}

	//fprintf(fh, "<app title=\"windowsphoto\" />\n");

	fprintf(fh, "</apps>\n");
	fclose(fh);

	::CoUninitialize();
	return true;
}

bool CFSUtil::getMp3ArtistUtf8(const wchar_t* sPath, string& sArtist){
	bool bRet = false;
	FILE* fh = NULL;
	errno_t e = _wfopen_s(&fh, sPath, L"rb");
	if(!e){
		Mp3Tag tags;
		if(0==fseek(fh, -128, SEEK_END)){
			fread(&tags, 1, sizeof(Mp3Tag), fh);
			if(strncmp(tags.header,"TAG", 3)==0){
				tags.artist[29] = 0;
				sArtist = tags.artist;
				sArtist = Util::toUtf8(sArtist.c_str(), sArtist.size()+1);
				fclose(fh);
				bRet = true;
			}
		}
		fclose(fh);
	}
	return bRet;
}

bool CFSUtil::getMp3Artist(const wchar_t* sPath, string& sArtist){
	bool bRet = false;
	FILE* fh = NULL;
	errno_t e = _wfopen_s(&fh, sPath, L"rb");
	if(!e){
		Mp3Tag tags;
		if(0==fseek(fh, -128, SEEK_END)){
			fread(&tags, 1, sizeof(Mp3Tag), fh);
			if(strncmp(tags.header,"TAG", 3)==0){
				tags.artist[29] = 0;
				sArtist = tags.artist;
				fclose(fh);
				bRet = true;
			}
		}
		fclose(fh);
	}
	return bRet;
}

bool CFSUtil::getPicFolderFirst( wstring& fPath )
{
	wstring path;

	FileSystem::getSpecialDirW(FileSystem::eMyPictures, path);
	FindFirstPicture ffp(path.c_str());
	ffp.run();

	if(ffp.m_path.size()){
		fPath = ffp.m_path;
		return true;
	}
	return false;
}

bool CFSUtil::genVideoPlaylist()
{
	//write videos.wpl
	FILE *fh = NULL;

	wstring path;

	FileSystem::getSpecialDirW(FileSystem::eMyDocuments, path);
	wstring wplPath = path+L"\\videos.wpl";
	errno_t e = _wfopen_s(&fh, wplPath.c_str(), L"w");
	if(e){
		Logger::error(L"Create videos.wpl fail!");
		return false;
	}

	//write file header
	fprintf(fh, "<?wpl version=\"1.0\"?>\n");
	fprintf(fh, "<smil>\n");
	fprintf(fh, "\t<head>\n");
	fprintf(fh, "\t\t<title>Teli absolute</title>\n");
	fprintf(fh, "\t</head>\n");
	fprintf(fh, "\t<body>\n");
	fprintf(fh, "\t\t<seq>\n");

	FileSystem::getSpecialDirW(FileSystem::eMyVideo, path);
	FindGenVideoPlaylist fgvpVideo(path.c_str(), fh);
	fgvpVideo.run();

	FileSystem::getSpecialDirW(FileSystem::eMyMusic, path);
	FindGenVideoPlaylist fgvpMusic(path.c_str(), fh);
	fgvpMusic.run();

	//write file end
	fprintf(fh, "\t\t</seq>\n");
	fprintf(fh, "\t</body>\n");
	fprintf(fh, "</smil>\n");

	fclose(fh);

	return true;
}

bool CAppFilter::isApproved(const wstring path, wstring& name )
{
	//Logger::info("isApproved: %s", path.c_str());
	wstring path2 = Util::strtolower(path);
	//disable solitaire for now.
	//if( (m_apps.find("solitaire")==m_apps.end())
	//	&& (Util::endsWith(path2, "solitaire.exe")|| Util::endsWith(path2, "solitaire.lnk"))
	//	)
	//{
	//	name = "solitaire";
	//	m_apps[name] = path;
	//	return true;
	//}

	if( (m_apps.find(L"firefox")==m_apps.end())
		&& (Util::endsWith(path2, L"firefox.exe")|| Util::endsWith(path2, L"firefox.lnk"))
		)
	{
		name = L"firefox";
		m_apps[name] = path;
		return true;
	}

	//if( (m_apps.find("windowsmedia")==m_apps.end())
	//	&& (Util::endsWith(path2, "wmplayer.exe")|| Util::endsWith(path2, "Windows Media Player.lnk"))
	//	)
	//{
	//	name = "windowsmedia";
	//	m_apps[name] = path;
	//	return true;
	//}

	//if( (m_apps.find(L"googleearth")==m_apps.end())
	//	&& (Util::endsWith(path2, L"googleearth.exe"))
	//	)
	//{
	//	name = L"googleearth";
	//	m_apps[name] = path;
	//	return true;
	//}

	return false;
}
///@}
