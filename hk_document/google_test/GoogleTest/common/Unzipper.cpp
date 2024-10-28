#include "stdafx.h"
#include "Unzipper.h"

#include <io.h>
#include <direct.h>
#include <cstdio>
#include <string>
using namespace std;

#include "zip.h"
#include "unzip.h"
#pragma comment(lib, "zlibstat.lib")
#pragma comment(linker, "/NODEFAULTLIB:libc.lib")

CUnzipper::CUnzipper(void)
{
}

CUnzipper::~CUnzipper(void)
{
}

namespace{
	bool exists(const char* path){
		return _access(path, 0)==0;
	}

	bool isdir(const char* path){
		if(exists(path) && ::GetFileAttributesA(path)&FILE_ATTRIBUTE_DIRECTORY){
			return true;
		}else{
			return false;
		}
	}

	bool makedirs(const char* path){
		if(isdir(path)){
			return true;
		}else if(exists(path)){
			return false;
		}

		char szAbsDir[MAX_PATH+1];
		_fullpath(szAbsDir, path, MAX_PATH);
		char* pEnd = szAbsDir + strlen(szAbsDir) - 1;
		if(pEnd[0]=='\\') pEnd[0]=0;

		char szDrive[MAX_PATH+1];
		char szDir[MAX_PATH+1];
		char szName[MAX_PATH+1];
		char szExt[MAX_PATH+1];
		_splitpath_s(szAbsDir, szDrive, MAX_PATH, szDir, MAX_PATH, szName, MAX_PATH, szExt, MAX_PATH);

		char szParent[MAX_PATH];
		_makepath_s(szParent, MAX_PATH, szDrive, szDir, NULL, NULL);
		if(makedirs(szParent)){
			int e = _mkdir(path);
			return e?false:true;
		}else{
			return false;
		}
	}
}

bool CUnzipper::Unzip( const char* szZipFile, const char* szFolder )
{
	int ret;

	//todo: make dir szFolder.
	makedirs(szFolder);

	zipFile zf = ::unzOpen(szZipFile);

	unz_global_info uzgi;
	ret = ::unzGetGlobalInfo(zf, &uzgi);
	const int n = uzgi.number_entry;
	if(n>0){
		::unzGoToFirstFile(zf);
		int count=n;
		while(count--){
			//get file info
			{
				unz_file_info uzfi;
				char szFileName[MAX_PATH+1];
				char szComment[MAX_PATH+1];
				::unzGetCurrentFileInfo(zf, &uzfi, szFileName, MAX_PATH, NULL, 0, szComment, MAX_PATH);

				bool bFolder = ((uzfi.external_fa & FILE_ATTRIBUTE_DIRECTORY) == FILE_ATTRIBUTE_DIRECTORY);

				//get abs target path
				char szAbsPath[MAX_PATH+1];
				lstrcpyA(szAbsPath, szFolder);
				lstrcatA(szAbsPath, "\\");
				lstrcatA(szAbsPath, szFileName);

				if(bFolder){
					makedirs(szAbsPath);
				}else{
					::unzOpenCurrentFile(zf);
					FILE* fp;
					errno_t e = fopen_s(&fp, szAbsPath, "wb");
					{
						int nRet = 0;
						char* buf = new char[1024];
						do{
							nRet = ::unzReadCurrentFile(zf, buf, 1024);
							if(nRet>0) fwrite(buf, 1, nRet, fp);
						}while(nRet>0);
						
						delete[] buf;
					}
					fclose(fp);
					::unzCloseCurrentFile(zf);
				}

				printf("%s, %d\n", szFileName, bFolder);
			}
			unzGoToNextFile(zf);
		}
	}

	ret = ::unzClose(zf);

	return true;
}
