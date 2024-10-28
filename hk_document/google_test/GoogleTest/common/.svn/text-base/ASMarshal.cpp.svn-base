#include "StdAfx.h"
#include "ASMarshal.h"
#include "rapidxml.hpp"
#include "Util.h"

namespace asmarshal{
	using namespace rapidxml;

	wstring xmlEscape( const wchar_t* s ){
		wostringstream ss;
		size_t len = wcslen(s);
		for(size_t i=0; i<len; i++){
			int ch = s[i];
			switch(ch){
			case L'<':  ss << L"&lt;";   break;
			case L'>':  ss << L"&gt;";   break;
			case L'&':  ss << L"&amp;";  break;
			case L'\'': ss << L"&apos;"; break;
			case L'\"': ss << L"&quot;"; break;
			default: ss.put(ch);
			}
		}
		return ss.str();
	}

	CReqBuilder::CReqBuilder(const wchar_t* method){
		ss << L"<invoke name=\"" << method << L"\" returntype=\"xml\"><arguments>";
	}

	CReqBuilder& CReqBuilder::aStr(const wchar_t* v){
		ss << L"<string>" << xmlEscape(v) << L"</string>";
		return *this;
	}

	CReqBuilder& CReqBuilder::aInt(const int v){
			ss << L"<number>" << v << L"</number>";
		return *this;
	}

	CReqBuilder& CReqBuilder::aDouble(const double v){
		ss << L"<number>" << v << L"</number>";
		return *this;
	}

	CReqBuilder& CReqBuilder::aBool(const bool v){
		ss << v?L"<true/>":L"<false/>";
		return *this;
	}

	CReqBuilder& CReqBuilder::aNull(){
		ss << L"<null/>";
		return *this;
	}

	wstring CReqBuilder::end(){
		ss << L"</arguments></invoke>";
		return ss.str();
	}

	///\brief Internally used only.
	class CReqData{
	public:
		xml_document<wchar_t> doc;
		xml_node<wchar_t>* cur_arg;
		wchar_t* req;
		wstring method;
	};

	CReq::CReq(const wchar_t* sReq):d(new CReqData){
		d->req = _wcsdup(sReq);
		d->doc.parse<0>(d->req);
		d->method = d->doc.first_node(L"invoke")->first_attribute(L"name")->value();

		d->cur_arg = d->doc.first_node(L"invoke")->first_node(L"arguments")->first_node();
	}

	CReq::~CReq(){
		free(d->req);
		delete d;
	}

	const wchar_t* CReq::method(){
		return d->method.c_str();
	}

	const CReq& CReq::operator>>(wstring& v) const{
		if(!d->cur_arg) throw marshal_error("extract string");

		xml_node<wchar_t>& arg = *d->cur_arg;
		if(wcscmp(arg.name(), L"string")) throw marshal_error("extract string: wrong type");
		v = arg.value();

		d->cur_arg = d->cur_arg->next_sibling();
		return *this;
	}

	const CReq& CReq::operator>>(int& v) const{
		if(!d->cur_arg) throw marshal_error("extract int");

		xml_node<wchar_t>& arg = *d->cur_arg;
		if(wcscmp(arg.name(), L"number")) throw marshal_error("extract int: wrong type");
		v = _wtoi(arg.value());

		d->cur_arg = d->cur_arg->next_sibling();
		return *this;
	}

	const CReq& CReq::operator>>(double& v) const{
		if(!d->cur_arg) throw marshal_error("extract double");

		xml_node<wchar_t>& arg = *d->cur_arg;
		if(wcscmp(arg.name(), L"number")) throw marshal_error("extract double: wrong type");
		v = _wtof(arg.value());

		d->cur_arg = d->cur_arg->next_sibling();
		return *this;
	}

	const CReq& CReq::operator>>(bool& v) const{
		if(!d->cur_arg) throw marshal_error("extract bool");

		xml_node<wchar_t>& arg = *d->cur_arg;

		if(wcscmp(arg.name(), L"true")==0){
			v = true;
		}else if(wcscmp(arg.name(), L"false")==0){
			v = false;
		}else{
			throw marshal_error("extract bool: wrong type");
		}

		d->cur_arg = d->cur_arg->next_sibling();
		return *this;
	}

	CReqBuilder CReq::start(const wchar_t* method){
		return method;
	}

	wstring CRet::str(const wchar_t* v){
		wostringstream ss;
		ss << L"<string>" << xmlEscape(v) << L"</string>";
		return ss.str();
	}
	wstring CRet::str(const int v){
		wostringstream ss;
		ss << L"<number>" << v << L"</number>";
		return ss.str();
	}
	wstring CRet::str(const double v){
		wostringstream ss;
		ss << L"<number>" << v << L"</number>";
		return ss.str();
	}
	wstring CRet::str(const bool v){
		return v?L"<true/>":L"<false/>";
	}
	wstring CRet::str(){
		return L"<null/>";
	}

	wstring CRet::parseStr(const wchar_t* s){
		xml_document<wchar_t> doc;
		doc.parse<parse_non_destructive>((wchar_t*)s);
		xml_node<wchar_t>* node = doc.first_node();

		if(wcsncmp(node->name(), L"string", node->name_size())==0){
			return wstring(node->value(), node->value_size());
		}else{
			throw marshal_error("CRet::parseStr");
		}
	}

	int CRet::parseInt(const wchar_t* s){
		xml_document<wchar_t> doc;
		doc.parse<parse_non_destructive>((wchar_t*)s);
		xml_node<wchar_t>* node = doc.first_node();

		if(wcsncmp(node->name(), L"number", node->name_size())==0){
			return _wtoi(node->value());
		}else{
			throw marshal_error("CRet::parseInt");
		}
	}

	double CRet::parseDouble(const wchar_t* s){
		xml_document<wchar_t> doc;
		doc.parse<parse_non_destructive>((wchar_t*)s);
		xml_node<wchar_t>* node = doc.first_node();

		if(wcsncmp(node->name(), L"number", node->name_size())==0){
			return _wtof(node->value());
		}else{
			throw marshal_error("CRet::parseDouble");
		}
	}

	bool CRet::parseBool(const wchar_t* s){
		if(wcscmp(s, L"<true/>")==0) return true;
		if(wcscmp(s, L"<false/>")==0) return false;

		throw marshal_error("CRet::parseBool");
	}

	bool CRet::isNull(const wchar_t* s){
		if(wcscmp(s, L"<null/>")==0) return true;
		return false;
	}

	int test(){
		int ret = 0;
		try{
			wchar_t buf[] = \
				L"<invoke name=\"functionName\" returntype=\"xml\">" \
				L"<arguments>" \
				L"<string>abc</string>" \
				L"<number>123.45</number>" \
				L"<number>911</number>" \
				L"<true/>" \
				L"<false/>" \
				L"</arguments>" \
				L"</invoke>";

			asmarshal::CReq r(buf);
			wstring method = r.method();
			wstring s;
			double d;
			int i;
			bool b1, b2;
			r >> s >> d >> i >> b1 >> b2;

			wstring req = asmarshal::CReq::start(L"testCall").aInt(5).aDouble(54.32).aStr(L"ajflsjfl").end();
			s = asmarshal::CRet::parseStr(L"<string>abc</string>");
			d = asmarshal::CRet::parseDouble(L"<number>123.45</number>");
			i = asmarshal::CRet::parseInt(L"<number>abc911.1</number>");
			b1 = asmarshal::CRet::parseBool(L"<1true/>");
			b2 = asmarshal::CRet::parseBool(L"<2false/>");
			bool b3 = asmarshal::CRet::isNull(L"<null/>");
			bool b4 = asmarshal::CRet::isNull(L"<true/>");
		}catch(asmarshal::marshal_error e){
			Logger::error(e.what());
			ret = 1;
		}
		return ret;
	}
}
