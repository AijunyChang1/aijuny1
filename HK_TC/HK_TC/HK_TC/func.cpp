#include "stdafx.h"
#include "func.h"

string fetch_mid(const string &source, const string &begin, const string &end)
{
    if (begin.length() < 1 || end.length() < 1) {
        return source;
    }
    int pos = source.find(begin.c_str(), 0);

    string result = "";
    string strTemp = "";
    if (pos != -1) {
        strTemp = source.substr(pos + begin.length(), source.size());
        pos = strTemp.find(end.c_str(), 0);
        if (pos != -1) {
            result = strTemp.substr(0, pos);
        }
        else {
            result = strTemp;
        }
    }
    else {
    	result = "";
    }
    return result;
}

__int64 str_to_int64(const string &str)
{
	const char *point = str.c_str();
    __int64 result = 0;
    if (point != NULL) {
    	result = _atoi64(point);
    }
    return result;
}

string int_to_str(__int64 num,int radix)
{
   	char ch[33] = { 0 };
    return _i64toa(num, ch, radix);

}

string fetch_head(string &source, const string &fix)
{
    if ( fix.length() < 1) {
        return source;
    }
	int pos = source.find(fix.c_str(), 0);
    string result = "";
    if (pos != -1) {
    	result = source.substr(0, pos);
        source = source.substr(pos + fix.length(), source.size());
    }
    else {
    	result = source;
        source = "";
    }
    return result;
}


string fetch_head(string &source, char fix)
{
	int pos = source.find(fix, 0);
    string result = "";
    if (pos != -1) {
    	result = source.substr(0, pos);
        source = source.substr(pos + 1, source.size());
    }
    else {
    	result = source;
        source = "";
    }
    return result;
}

BOOL DirectoryExists(string strPath)
{
    WIN32_FIND_DATAA wfd;
    BOOL rValue = FALSE;
    HANDLE hFind = FindFirstFileA(strPath.c_str(), &wfd);

    if ((hFind!=INVALID_HANDLE_VALUE) &&
         (wfd.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY))
    {
        rValue = TRUE;
    }
    FindClose(hFind);
    return rValue;
}


BOOL CreateDir(string strPath)
{
    SECURITY_ATTRIBUTES attrib;
    attrib.bInheritHandle = FALSE;
    attrib.lpSecurityDescriptor = NULL;
    attrib.nLength = sizeof(SECURITY_ATTRIBUTES);
    //上面定义的属性可以省略
    //直接使用return ::CreateDirectory(path, NULL);即可
    return ::CreateDirectoryA(strPath.c_str(), &attrib);
}


int make_dir(const string&root, const string &subdir)     //1-success, -1-create fail, -2-Create fail, 0-crash
{
	int Success = -1;

	try{
      string Root = root.c_str();
      string SubDir = subdir.c_str();
      bool Finished = false;
      while (!Finished) {        

  //      if (!DirectoryExists(Root)) {
		  if (Root[Root.length()-1] != '\\') {
             Root += "\\";
			 Root[Root.length()]='\0';
          }
		  
		  CreateDir(Root.c_str());
		  /*
          if (!CreateDir(Root.c_str())) {
            break;
          }
    //    }

		else
		{
		   Success = -2;
		
		}
		*/
		if (Root[Root.length()-1] != '\\') {
          Root += "\\";
        }
        if (SubDir.length() > 0) {
            int nPos = SubDir.find("\\");
            if(nPos > 0) {
              Root += SubDir.substr(0, nPos);
              SubDir = SubDir.substr(nPos + 1, SubDir.length());
            }
            else {
              Root += SubDir;
              SubDir = "";
            }
         }
         else {
            Finished = true;
	        Success = 1;
         }
       
	  }
	  return Success;
	}    
    catch(...)
	{
        return  0;
	}
}

void str_to_day(string src,int &year,int& month, int& day)
{

	string h_t;

	h_t=src.substr(0,4);
	year=atoi(h_t.c_str());
	h_t=src.substr(4,2);
	if(h_t[0]=='0')
	{
		h_t=h_t.substr(1,1);
	}
	month=atoi(h_t.c_str());
	h_t=src.substr(6,2);
	if(h_t[0]=='0')
	{
		h_t=h_t.substr(1,1);

	}
	day=atoi(h_t.c_str());

}

void str_to_time(string src,int& hour,int& min, int& sec)
{
	string h_t;
	h_t=fetch_head(src, ':');
	if(h_t[0]=='0')
	{
		h_t=h_t.substr(1,1);

	}
	hour=atoi(h_t.c_str());
	h_t=fetch_head(src, ':');
	if(h_t[0]=='0')
	{
		//  h_t[0]=h_t[1];
		//  h_t[1]='\0';
		h_t=h_t.substr(1,1);

	}
	min=atoi(h_t.c_str());
	if(src[0]=='0')
	{

		src=src.substr(1,1);

	}

	sec=atoi(src.c_str());

}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
bool db_factory::open(_bstr_t ConnectionString, _bstr_t UserID, _bstr_t Password, long Options)
{

    HRESULT hr;
    try
    {
	    CoInitialize(NULL);
	    hr = m_pConnection.CreateInstance("ADODB.Connection");///创建Connection对象
	   //hr = m_pConnection.CreateInstance(__uuidof(Connection));///创建Connection对象
	    if(SUCCEEDED(hr))
	    {
		   hr= m_pConnection->Open(ConnectionString, UserID, Password, Options);
	    } 
	    if (hr != S_OK) return false;
	   
	    m_pRecordset.CreateInstance(__uuidof(Recordset));	// 初始化Recordset指针
	    m_pCommand.CreateInstance(__uuidof(Command));	// 初始化Command指针


	   // m_pRecordset->PutRefActiveConnection(m_pConnection);///////////////////////////////////////////////////////////////////////////
	    status=true;

	    return true;
    }
  
    catch(_com_error e)///捕捉异常
    {
	    char errormessage[100];
	    sprintf(errormessage, "Connect to DB failed, Error msg:%s",e.ErrorMessage());
	    write_log(errormessage);
	    status=false;
	    return false;
	   //	AfxMessageBox(errormessage);///显示错误信息
    } 

}


bool db_factory::execute(_bstr_t query_cmd)
{
	try
	{
        if(m_pConnection==NULL) 
		{
			open(connect_str.c_str(),"","",adModeUnknown);
		}
        if (strlen(query_cmd)<5) return false;
        if(status)
        {
            m_pConnection->Execute(query_cmd,NULL,1); //用Execute执行sql语句来删除
            return true;
        }
        else
       {
           return false;
       }
   }
   catch(_com_error e)
   {
	   	char errormessage[100];
	    sprintf(errormessage, "Insert into DB failed, Error msg:%s",e.ErrorMessage());
	    write_log(errormessage);
	    return false;
   }

}

int write_log(string log)
{
    char tmp[200];
	time_t t = time(0); 
	memset(&tmp[0], 0, sizeof(tmp));
	strftime(tmp, sizeof(tmp), "%Y%m%d",localtime(&t));
	string logfile = "log";
	logfile = logfile + tmp + ".txt";
	WaitForSingleObject(hlog,INFINITE);
	if((logfp=fopen(logfile.c_str(),"at+"))==NULL)
	{
		SetEvent(hlog);
		return -1;
	}
	else
	{ 
		strftime(tmp, sizeof(tmp), "%Y%m%d %X",localtime(&t));
		fprintf(logfp,"%s %s \n",tmp, log.c_str());			 
	}
	fclose(logfp);
	SetEvent(hlog);

	return 0;
}

/*
a-缩写星期几 Sun
A-完整星期几 Sunday
B-完整月份   March
b-缩写月份   Mar
c-时间和数字表示法  Sun Aug 19 02:56:02 2021
d-月中第几天 19
H-24小时格式小时 14
l-12小时格式小时 02
j-一年中的第几天 230
m-十进制月份 08
M-分（00-59）55
p-AM或PM    PM
S-秒 （00-60）02
U/W-一年中的第几周 33
w-十进制表示的星期几 4
x-日期  08/19/12
X-时间 02:50:06
y-年份，最后两位数字 01
Y-年份    2001
Z-时区    CDT

*/