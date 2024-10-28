#ifndef _Settings_H_
#define _Settings_H_

#include <map>
#include <vector>
#include <string>

using namespace std;
//class to manager settings data except <key mappings>
class CSettings{
	//inner types
	enum ItemType{
		tNumber = 0,
		tString
	};
	//Item type
	class Item{
	public:
		ItemType type;
		int iVal;
		string sVal;
		bool operator ==(const Item &inst) const{
			return ( (type==inst.type) && 
						((type==tNumber && iVal==inst.iVal) || (type==tString && sVal==inst.sVal)) );
		}
		bool operator !=(const Item &inst) const{
			return (inst==(*this))==false;
		}
	};

	//data
private:
	typedef map<string, Item> DataType;
	DataType m_data;

public:
	void set(string name, int val){
		Item &i = m_data[name];
		i.type= tNumber;
		i.iVal = val;
	}
	void set(string name, string val){
		Item &i = m_data[name];
		i.type= tString;
		i.sVal = val;
	}
	int getNumber(string name){
		return m_data[name].iVal;
	}
	string getString(string name){
		return m_data[name].sVal;
	}
	bool operator ==(const CSettings &inst) const{
		return inst.m_data==m_data;
	}
	bool operator !=(const CSettings &inst) const{
		return inst.m_data!=m_data;
	}
	//search modified or added keys:
	vector<string> getChangedKeys(CSettings &base){
		vector<string> diff_keys;
		for(DataType::iterator i=m_data.begin(); i!=m_data.end(); ++i){
			const string &key = i->first;
			if(base.m_data.find(key)==base.m_data.end()){
				diff_keys.push_back(key);
			}else if(base.m_data[key]!=m_data[key]){
				diff_keys.push_back(key);
			}
		}
		return diff_keys;
	}
	//TODO: load, save
};

//Flash size
//#define FLASHWIN_W 800
//#define FLASHWIN_H 600
extern int FLASHWIN_W;
extern int FLASHWIN_H;

//show debug window
//#define DBGWIN_W 200
//#define DBGWIN_H 150
extern int DBGWIN_W;
extern int DBGWIN_H;

//webcam video size
//#define VIDEO_W (800)
//#define VIDEO_H (600)
//#define VIDEO_DEPTH (24)
extern int VIDEO_W;
extern int VIDEO_H;
extern int VIDEO_DEPTH;

extern int FILTER_VIDEO_W;
extern int FILTER_VIDEO_H;

extern BOOL SHOW_VIRTUAL;

extern void videoSettings(int video_w, int video_h, int video_depth=24);
extern void videoSetDepth(int video_depth);
extern void setShowVirtual(BOOL isShow);


//extern CConfig m_cfg;
//extern CSettings g_settings;
#endif // _Settings_H_
