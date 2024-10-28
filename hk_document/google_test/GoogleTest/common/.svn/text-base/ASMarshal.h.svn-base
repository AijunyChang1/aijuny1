#pragma once
/**
	Check the following URL for the XML format of ActionScript3's ExternalInterface protocol.
	http://help.adobe.com/zh_CN/ActionScript/3.0_ProgrammingAS3/WS5b3ccc516d4fbf351e63e3d118a9b90204-7caf.html
*/

#include <string>
#include <sstream>

///\addtogroup CommonLib
///@{

///\brief This namespace contains several classes to build/parse xml strings for calls/return-value to ActionScript3.
namespace asmarshal{
	using namespace std;

	///\brief Error when parse requests from flash.
	class marshal_error : public exception{
	public:
		marshal_error(const char* msg):exception(msg){}
	};

	///\brief Internally used only.
	class CReqBuilder{
		wstringstream ss;
		//static wstring xmlEscape(const wchar_t* s);
	public:
		CReqBuilder(const wchar_t* method);
		CReqBuilder& aStr(const wchar_t* v);
		CReqBuilder& aInt(const int v);
		CReqBuilder& aDouble(const double v);
		CReqBuilder& aBool(const bool v);
		CReqBuilder& aNull();
		wstring end();
	};

	class CReqData;
	/**
	\brief Use to build a call to ActionSript3.
	
	@sa CDH::OnPreProcessThreadMsg

	Example:
	\code
	wstring req = CReq::start(L"fileUpdate").aStr(fpath_new).aStr(fpath_old).end();
	pThread->getFlash()->execute(req.c_str(), ret);
	\endcode
	*/
	class CReq{
	public:
		CReq(const wchar_t* sReq);
		~CReq();
		const wchar_t* method();
		const CReq& operator>>(wstring& v) const;
		const CReq& operator>>(int& v) const;
		const CReq& operator>>(double& v) const;
		const CReq& operator>>(bool& v) const;

		//build
		static CReqBuilder start(const wchar_t* method);
	private:
		//parse
		CReqData* d;
	};

	/**
	\brief Build or parse a xml-form return value from ActionScript3.

	@sa CFlashThreadDH::OnFlashCalled

	Example:
	\code
	//build
	wstring response = CRet::str(L"abc");
	//parse
	wstring s = CRet::parseStr(L"<string>abc</string>");
	int I = CRet::parseInt(L"<number>1</number>");
	\endcode
	*/
	class CRet{
	public:
		//build
		static wstring str(const wchar_t* v);
		static wstring str(const int v);
		static wstring str(const double s);
		static wstring str(const bool s);
		static wstring str();

		//parse
		static wstring parseStr(const wchar_t* s);
		static int parseInt(const wchar_t* s);
		static double parseDouble(const wchar_t* s);
		static bool parseBool(const wchar_t* s);
		static bool isNull(const wchar_t* s);
	};

	int test();
}

///@}
