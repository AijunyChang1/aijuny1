#include "StdAfx.h"
#include "Mode.h"

#include <string>
#include <map>

using namespace std;

int CMode::s_nextRegId = modeExtend10+1;

static struct{
	KeyMapperMode mode;
	const char* name;
}_modeMap[] = {
	{modeMediaPhoto, "mediaPhoto"},
	{modeMediaMusic, "mediaMusic"},
	{modeMediaVideo, "mediaVideo"},
	{modeViewMessage, "viewMessage"},
	{modeGameBox, "gameBox"},
	{modeGameSkee, "gameSkee"},
	{modeGameMoto, "gameMoto"},
	{modeMediaCenter, "mediaCenter"},
	{modeWebBrowser, "webBrowser"},
};

CMode::CMode(void){
}

CMode::~CMode(void){
}

bool CMode::match( const char *sClz, const char *sTitle ){
	if(winClass.length()>0){
		if(winClass!=sClz){
			return false;
		}
	}
	if(winTitle.length()>0){
		//if winTitle.startswith(sTitle)
		if(strstr(sTitle, winTitle.c_str())!=sTitle){
			return false;
		}
	}
	return true;
}

static void _initMaps();
static map<KeyMapperMode, string> _mapCodeToName;
const char* CMode::codeToName( KeyMapperMode mode ){
	_initMaps();

	map<KeyMapperMode, string>::iterator i =_mapCodeToName.find(mode);
	if(i!=_mapCodeToName.end()){
		return i->second.c_str();
	}else{
		return "<Undefined or Custom Mode>";
	}
}

static map<string, KeyMapperMode> _mapNameToCode;
KeyMapperMode CMode::nameToCode( const char* name ){
	_initMaps();

	map<string, KeyMapperMode>::iterator i =_mapNameToCode.find(name);
	if(i!=_mapNameToCode.end()){
		return i->second;
	}else{
		return modeUndefined;
	}
}

KeyMapperMode CMode::RegisterMode( const char* name ){
	KeyMapperMode mode = nameToCode(name);
	if(mode==modeUndefined){
		mode = (KeyMapperMode)s_nextRegId;
		_mapNameToCode[name] = mode;
		_mapCodeToName[mode] = name;
		++s_nextRegId;
	}
	return mode;
}

static void _initMaps(){
	if(_mapCodeToName.empty()){
		for(size_t i=0; i<_countof(_modeMap); ++i){
			_mapCodeToName[_modeMap[i].mode] = _modeMap[i].name;
		}
	}
	if(_mapNameToCode.empty()){
		for(size_t i=0; i<_countof(_modeMap); ++i){
			_mapNameToCode[_modeMap[i].name] = _modeMap[i].mode;
		}
	}
}