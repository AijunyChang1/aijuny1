 #ifndef _FUNC
#define _FUNC

#include <iostream>
#include <fstream>
#include <string>
#include <sstream>
#include <vector>
#include <comdef.h>
#include "stdafx.h"
using namespace std;



string fetch_mid(const string &source, const string &begin, const string &end);
__int64 str_to_int64(const string &str);
string int_to_str(__int64 num, int radix = 10);     //radix: 制式，默认为十进制
string fetch_head(string &source, const string &fix);
string fetch_head(string &source, char fix = ',');
int make_dir(const string&root, const string &subdir);
void str_to_day(string src,int& year,int& month, int& day);
void str_to_time(string src,int& hour,int& min, int& sec);

int write_log(string log);


class db_factory{
 public:
	  _ConnectionPtr	m_pConnection;
      _RecordsetPtr 	m_pRecordset;
	  _CommandPtr	    m_pCommand;

	  bool status;
	//  bool is_oral;

	  string connect_str;


 public:
	db_factory(){

	    status=false;
		//is_oral=false;

	
	}
    
	~db_factory(){
	
		if(status)
		{
		  m_pConnection->Close();
		}
	}


	bool open(_bstr_t ConnectionString, _bstr_t UserID, _bstr_t Password, long Options);
	bool execute(_bstr_t query_cmd); //用Execute执行sql语句来删除


};

#endif
