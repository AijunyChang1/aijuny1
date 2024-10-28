#pragma once

#include "Util.h"
#include "Config.h"
#include "Settings.h"

#include <fstream>
#include <vector>
#include <string>

using namespace std;

#define PRESETS_DIR "presets"
#define PRESETS_CFG PRESETS_DIR ## "\\cfg2.ini"

class CPresets
{
	static string m_sel1;
	static string m_sel2;
public:
	CPresets(void);
	~CPresets(void);

	//list: enumerate downloaded presets files:
	static int getList(vector<string> &fList){
		int count = 0;
		WIN32_FIND_DATAA wfd;
		BOOL hasMore = TRUE;
		string filter=PRESETS_DIR;
		filter+="\\*.xml";

		for(HANDLE h = FindFirstFileA(filter.c_str(), &wfd);  
					h!=INVALID_HANDLE_VALUE && hasMore;  
					hasMore=FindNextFileA(h, &wfd))
		{
				Logger::info("Found preset: %s", wfd.cFileName);
				fList.push_back(wfd.cFileName);
				count++;
		}
		Logger::info("%d presets found.", count);
		return count;
	}

	//called when application int
	//load: load specific preset file and add mode to config.
	static int update(CConfig& cfg){
		int succeed = 0;

		loadSelection();

		vector<string> fList;
		int n = getList(fList);
		CConfig cfg2;
		for(size_t i=0; i<fList.size(); i++){
			USES_CONVERSION;
			string fpath = PRESETS_DIR;
			fpath+="\\";
			fpath+=fList[i];

			int error = cfg2.load(A2W(fpath.c_str()));
			if(error){
				Logger::error("Load presets file[%s] fail, error=%d", fpath.c_str(), error);
			}else{
				Logger::info("Presets file [%s] loaded.", fpath.c_str());
				succeed++;
			}
		}

		//merge to global config
		cfg.loadPresets(cfg2);
		int m = cfg.applyPresets();
		Logger::info("%d modes in %s is merged.", m, PRESETS_DIR);
		
		return succeed;
	}

	//load/save/get presets selection.
	static void loadSelection(){
		ifstream fin(PRESETS_CFG);
		if(!fin){
			Logger::warn("%s not exists.", PRESETS_CFG);
		}else{
			fin >> m_sel1 >> m_sel2;
			fin.close();
		}
	}
	static void saveSelection(){
		ofstream fout(PRESETS_CFG);
		if(!fout){
			Logger::error("open %s fail!", PRESETS_CFG);
		}else{
			fout << m_sel1 << " " << m_sel2;
			fout.close();
		}
	}
	static void getSelection(string &sel1, string &sel2){
		sel1 = m_sel1;
		sel2 = m_sel2;
	}
	static void setSelection(string sel1, string sel2){
		m_sel1 = sel1;
		m_sel2 = sel2;
	}
};

