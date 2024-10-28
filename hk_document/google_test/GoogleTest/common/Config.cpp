#include "StdAfx.h"
#include "Config.h"
#include "Util.h"

#include "Presets.h"
#include "VirtualKey.h"
#include "IMobiGR.h"

#include "FXAESCrypto.h"
#pragma comment(lib, "FXAESCrypto.lib")

#include <string>
#include <map>
using namespace std;

MobiGestureMode findGesture(string name);

CConfig::CConfig(void) : m_isFS(false)
{
}

CConfig::~CConfig(void)
{
}

int CConfig::readActions2( CMode& mode, CComPtr<IXMLDOMElement> elm ){
	HRESULT hr;

	CComPtr<IXMLDOMNodeList> nodes;
	hr = elm->getElementsByTagName(CComBSTR("action"), &nodes);
	if(FAILED(hr)) return 8;

	long count;
	hr = nodes->get_length(&count);
	if(FAILED(hr)) return 9;

	for(int i=0; i<count; i++){
		USES_CONVERSION;
		CAction action;

		CComPtr<IXMLDOMNode> node;
		hr = nodes->get_item(i, &node);
		if(FAILED(hr)) return 10;

		CComBSTR name;
		hr = node->get_nodeName(&name);
		//OutputDebugStringW(name);

		CComQIPtr<IXMLDOMElement> actionNode(node);
		string sGesture = strAttr(actionNode, "gesture");
		MobiGestureEvent gesture = GesEvt::nameToCode(sGesture.c_str());

		if(gesture!=gesUndefined){
			string sName = strAttr(actionNode, "name");
			action.setName(sName);
			Logger::debug("Got action %s.", sName.c_str());

			string sModifiers = strAttr(actionNode, "keyModifiers");
			string sKeyCode = strAttr(actionNode, "keyCode");
			action.parse(sModifiers,sKeyCode);

			mode.actions[gesture] = action;
		}else{
			Logger::warn("Gesture %s is not defined.", sGesture.c_str());
		}
	}
	return 0;
}

int CConfig::load( const wchar_t* path )
{
	bool isEncrypt = false;
	{
		size_t len = wcslen(path);
		if(len>5){
			if(wcscmp(path+len-5, L".teli")==0){
				isEncrypt = true;
			}
		}
	}

	HRESULT hr;
	CComPtr<IXMLDOMDocument> m_pDom;

	hr = m_pDom.CoCreateInstance(__uuidof(DOMDocument));
	if(FAILED(hr)) return 1;

	hr = m_pDom->put_async(FALSE);
	if(FAILED(hr)) return 2;

	VARIANT_BOOL bRes;
	if(isEncrypt){
		USES_CONVERSION;
		CFXAESCrypto c;
		c.SetDecryptKey((byte*)"Mobinex TeliLite");

		long xmlLen = 0;
		const long size = 1024*50;
		char* bufXml = new char[size];
		if(c.DecryptFileToString(path, (byte*)bufXml, xmlLen)){
			bufXml[xmlLen] = 0;
			hr = m_pDom->loadXML(A2OLE(bufXml), &bRes);
		}
		delete[] bufXml;
	}else{
		hr = m_pDom->load(CComVariant(path), &bRes);
	}
	if(FAILED(hr)) return 3;
	if(bRes==VARIANT_FALSE) return 4;

	CComPtr<IXMLDOMElement> elm;
	hr = m_pDom->get_documentElement(&elm);
	ATLVERIFY(SUCCEEDED(hr));

	//read modes
	{
		CComPtr<IXMLDOMNodeList> nodes;
		hr = elm->getElementsByTagName(CComBSTR("mode"), &nodes);
		if(FAILED(hr)) return 5;

		long count;
		hr = nodes->get_length(&count);
		if(FAILED(hr)) return 6;

		for(int i=0; i<count; i++){
			USES_CONVERSION;
			CMode mode;

			CComPtr<IXMLDOMNode> node;
			hr = nodes->get_item(i, &node);
			if(FAILED(hr)) return 7;

			CComBSTR name;
			hr = node->get_nodeName(&name);
			//OutputDebugStringW(name);

			CComQIPtr<IXMLDOMElement> modeNode(node);
			CComVariant val;
			hr = modeNode->getAttribute(CComBSTR("name"), &val);
			//OutputDebugStringW(val.bstrVal);
			mode.name = W2A(val.bstrVal);
			mode.mode = CMode::RegisterMode(mode.name.c_str());

			hr = modeNode->getAttribute(CComBSTR("appPath"), &val);
			//OutputDebugStringW(val.bstrVal);
			mode.appPath = W2A(val.bstrVal);

			mode.description = strAttr(modeNode, "description");
			mode.winClass = strAttr(modeNode, "winClass");
			mode.winTitle = strAttr(modeNode, "winTitle");
			mode.postKeys = strAttr(modeNode, "postKeys");
			{
				string sGesture  = strAttr(modeNode, "gestureMode");
				mode.gesture = findGesture(sGesture);
			}

			//read actions
			int err2 = readActions2(mode, modeNode);
			if(err2) return err2;

			//m_modes.push_back(mode);
			//m_modes.insert(ModeMap::value_type(mode.name, mode));
			m_modes.insert(ModeMap::value_type(mode.mode, mode));
		}
	}

	//read if it is fullscreen
	{
		CComPtr<IXMLDOMNodeList> nodes;
		hr = elm->getElementsByTagName(CComBSTR("ui"), &nodes);
		if(FAILED(hr)) return 11;
		long len = 0;
		hr = nodes->get_length(&len);
		if(len>0){
			CComPtr<IXMLDOMNode> nodeUI;
			hr = nodes->get_item(0, &nodeUI);
			CComQIPtr<IXMLDOMElement> elmUI(nodeUI);
			string s = strAttr(elmUI, "isFullScreen");
			if(s=="true"){
				this->m_isFS = true;
			}
		}
	}
	return 0;
}

int CConfig::save( char* path )
{
	//TODO:


	return 0;
}

std::string CConfig::strAttr( IXMLDOMElement* elm, const char* attrName )
{
	USES_CONVERSION;
	HRESULT hr;
	CComVariant val;
	hr = elm->getAttribute(CComBSTR(attrName), &val);
	if(hr==S_OK){
		//OutputDebugStringW(val.bstrVal);
		return W2A(val.bstrVal);
	}else{
		return "";
	}
}

int CConfig::getLaunchPath( KeyMapperMode mode, const char* &sPath, const char* &sPosKeys )
{
	ModeMap::iterator iterMode = m_modes.find(mode);
	if(iterMode==m_modes.end()){
		return 1;
	}

	CMode& rMode = iterMode->second;
	sPath = rMode.appPath.c_str();
	sPosKeys = rMode.postKeys.c_str();
	return 0;
}

int CConfig::getWinInfo( KeyMapperMode mode, const char* &sClassName, const char* &sTitle )
{
	ModeMap::iterator iterMode = m_modes.find(mode);
	if(iterMode==m_modes.end()){
		return 1;
	}

	CMode& rMode = iterMode->second;
	if(rMode.winClass.length()>0){
		sClassName = rMode.winClass.c_str();
	}else{
		sClassName = NULL;
	}
	if(rMode.winTitle.length()>0){
		sTitle = rMode.winTitle.c_str();;
	}else{
		sTitle = NULL;
	}
	return 0;
}

CMode* CConfig::getMode( KeyMapperMode mode )
{
	ModeMap::iterator iMode = m_modes.find(mode);
	if(iMode!=m_modes.end()){
		return &iMode->second;
	}else{
		return NULL;
	}
}

size_t CConfig::getModes( vector<KeyMapperMode> &modes )
{
	for(ModeMap::iterator i=m_modes.begin(); i!=m_modes.end(); ++i){
		modes.push_back(i->first);
	}
	return modes.size();
}

int CConfig::loadPresets( CConfig &another, bool replace )
{
	int replaced = 0;
	m_presetModes.clear();

	for(ModeMap::iterator i=another.m_modes.begin(); i!=another.m_modes.end(); ++i){
		KeyMapperMode mode = i->first;
		CMode &rMode = i->second;
		if(m_presets.find(mode)!=m_presets.end()){
			if(replace){
				m_presets[mode] = i->second;
				replaced++;
				Logger::warn("preset [%s] is overrided!", rMode.name.c_str());
			}else{
				Logger::info("preset [%s] is ignored.", rMode.name.c_str());
			}
		}else{
			m_presets[mode] = i->second;
			m_presetModes.push_back(mode);
			Logger::info("preset [%s] is inserted.", rMode.name.c_str());
		}
	}

	return replaced;
}

//return num of modes conflicted.
int CConfig::applyPresets()
{
	string sel1;
	string sel2;
	CPresets::getSelection(sel1, sel2);

	//remove old merged firstly
	size_t presetsNum = m_presetModes.size();
	if(presetsNum>0){
		for(size_t i=0; i<presetsNum; i++){
			ModeMap::iterator iMode = m_modes.find(m_presetModes[i]);
			if(iMode!=m_modes.end()){
				m_modes.erase(iMode);
			}
		}
	}
		
	int merged = 0;
	for(ModeMap::iterator i=m_presets.begin(); i!=m_presets.end(); ++i){
		KeyMapperMode presetMode = i->first;
		string &presetName = i->second.name;
		if(m_modes.find(presetMode)!=m_modes.end()){
			Logger::warn("mode [%s] is used by built-in mode, can't override!", presetName.c_str());
		}else{
			if(presetName==sel1 || presetName==sel2){
				m_modes[presetMode] = i->second;
				merged++;
				Logger::info("preset [%s] is merged.", presetName.c_str());
			}
		}
	}

	return merged;
}

bool CConfig::hasMode( KeyMapperMode mode ){
	return m_modes.find(mode)!=m_modes.end();
}

CMode* CConfig::findMode( const char* sClz, const char* sTitle )
{
	for(ModeMap::iterator i=m_modes.begin(); i!=m_modes.end(); ++i){
		if(i->second.match(sClz, sTitle)){
			return &i->second;
		}
	}
	return NULL;
}

CAction* CConfig::findCAction( KeyMapperMode mode, MobiGestureEvent gesture )
{
	ModeMap::iterator iMode = m_modes.find(mode);
	if(iMode!=m_modes.end()){
		CMode &mode = iMode->second;
		ActionMap::iterator iAction = mode.actions.find(gesture);
		if(iAction!=mode.actions.end()){
			return &iAction->second;
		}
	}
	return NULL;
}

size_t CConfig::getDownloadedNames( vector<string> &names ){
	for(size_t i=0; i<m_presetModes.size(); ++i){
		names.push_back(CMode::codeToName(m_presetModes[i]));
	}
	return names.size();
}

static MobiGestureMode findGesture(string name){
	static map<string, MobiGestureMode> _mapGesNameToCode;
	if(_mapGesNameToCode.empty()){
		IMobiGR *pGR = CreateMobiGR();
		MobiGestureMode *modes;
		int count = pGR->GetAllModes(modes);
		for(int i=0; i<count; ++i){
			MobiGestureMode mode = modes[i];
			string modeName = pGR->GetModeName(mode);
			_mapGesNameToCode[modeName] = mode;
		}
		ReleaseMobiGR(&pGR);
	}

	{
		map<string, MobiGestureMode>::iterator iMode = _mapGesNameToCode.find(name);
		if(iMode!=_mapGesNameToCode.end()){
			return iMode->second;
		}else{
			return (MobiGestureMode)-1;
		}
	}
}
