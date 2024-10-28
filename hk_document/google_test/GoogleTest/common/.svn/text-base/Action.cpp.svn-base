#include "StdAfx.h"

#include <windows.h>
#include <string>
#include <map>
#include <set>
#include <algorithm>

#include "IMobiGR.h"
#include "VirtualKey.h"
#include "KeyRunner.h"
#include "Action.h"
#include "Util.h"

using namespace std;

struct SInput{
	SInputType type;
	INPUT input;
};

class CActionData{
public:
	MobiGestureEvent m_evt;
	string m_name;
	string m_description;
	vector<SInput> m_inputs;
};

namespace{
	bool isPressed( WORD key ){
		SHORT ret = GetAsyncKeyState(key);
		return ret&0x8000 ? true:false;
	}

	void releaseKey( WORD key ){
		if(isPressed(key)){
			INPUT input = {0};
			input.type = INPUT_KEYBOARD;
			input.ki.wVk = key;
			input.ki.wScan = MapVirtualKey(key, 0);
			input.ki.dwFlags = KEYEVENTF_KEYUP;
			CKeyRunner::addExtendedFlag(input.ki);
			SendInput(1, &input, sizeof(INPUT));
		}
	}

	SInput makeKeyDown( WORD key ){
		SInput i = {esiRaw, {0}};
		i.input.type = INPUT_KEYBOARD;
		i.input.ki.wVk = key;
		i.input.ki.wScan = MapVirtualKey(key, 0);
		CKeyRunner::addExtendedFlag(i.input.ki);
		return i;
	}

	SInput makeKeyUp( WORD key ){
		SInput i = makeKeyDown(key);
		i.input.ki.dwFlags |= KEYEVENTF_KEYUP;
		return i;
	}

	SInput makeMouseLButtonDown(){
		SInput i = {esiRaw, {0}};
		i.input.type = INPUT_MOUSE;
		i.input.mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
		return i;
	}

	SInput makeMouseLButtonUp(){
		SInput i = {esiRaw, {0}};
		i.input.type = INPUT_MOUSE;
		i.input.mi.dwFlags = MOUSEEVENTF_LEFTUP;
		return i;
	}

	SInput makeMouseMove(){
		SInput i = {esiMoveMouse, {0}};
		return i;
	}

	SInput makeMouseMoveCenterY(){
		SInput i = {esiMoveMouseCenterY, {0}};
		return i;
	}
}


CAction::CAction( void ):d(new CActionData){
}

CAction::CAction(const char *name):d(new CActionData){
	 d->m_name = name;
}

CAction::~CAction(void){
	delete d;
}

CAction::CAction( const CAction& a ){
	d = new CActionData;
	*d = *a.d;
}

CAction& CAction::operator=( const CAction& a ){
	*d = *a.d;
	return *this;
}

std::string CAction::getName(){
	return d->m_name;
}

void CAction::setName( string &name ){
	d->m_name = name;
}

std::string CAction::toString(){
	return d->m_description;
}

// fill m_description (for settings dialog) and m_inputs (for keymapping) fields
//can get from string
//keyCode extension:
//	"Left|Up", dual keys
//	"_Left", press only
//	"~Left", release only
//	"?Left", release if pressed
//	"!", mouseClick
//	"#", mouse mouse to event coordinate.
//	"@esiMoveMouseCenterY", move mouse to event coordinate x, center y in client.
void CAction::parse( string sModifiers, string sKeys )
{
	vector<WORD> vModifiers;
	string &s = sModifiers;
	for(size_t j=0; j<s.length(); j++){
		switch(s[j]){
				case 'C':
					d->m_description += "Ctrl";
					vModifiers.push_back(VK_CONTROL);
					d->m_inputs.push_back(makeKeyDown(VK_CONTROL));
					break;
				case 'A':
					d->m_description += "Alt";
					vModifiers.push_back(VK_MENU);
					d->m_inputs.push_back(makeKeyDown(VK_MENU));
					break;
				case 'S':
					d->m_description += "Shift";
					vModifiers.push_back(VK_SHIFT);
					d->m_inputs.push_back(makeKeyDown(VK_SHIFT));
					break;
				case 'W':
					d->m_description += "LWin";
					vModifiers.push_back(VK_LWIN);
					d->m_inputs.push_back(makeKeyDown(VK_LWIN));
					break;
				default:
					break;
		}
	}
	if(d->m_description.length()>0) d->m_description+=" - ";

	vector<string> keys;
	int n = Util::split(sKeys, "|", keys);
	for(int i=0; i<n; i++){
		USES_CONVERSION;
		wchar_t *key = A2W(keys[i].c_str());

		if(key[0]=='_'){
			//press only
			WORD wKey = CVirtualKey::parse(key+1);
			if(wKey!=0) {
				d->m_description += CVirtualKey::toString(wKey);
				d->m_inputs.push_back(makeKeyDown(wKey));
			}
		}else if(key[0]=='~'){
			//release only
			WORD wKey = CVirtualKey::parse(key+1);
			if(wKey!=0) {
				d->m_description += CVirtualKey::toString(wKey);
				d->m_inputs.push_back(makeKeyUp(wKey));
			}
		}else if(key[0]=='!'){
			//mouse click
			d->m_description += "MouseClick";
			d->m_inputs.push_back(makeMouseLButtonDown());
			d->m_inputs.push_back(makeMouseLButtonUp());
		}else if(key[0]=='#'){
			d->m_description += "MouseMove";
			//mouse move
			d->m_inputs.push_back(makeMouseMove());
		}else if(key[0]=='@'){
			string cmd = keys[i].substr(1);
			d->m_description += cmd;

			if(cmd=="moveCenterY"){
				//mouse move with center y
				d->m_inputs.push_back(makeMouseMoveCenterY());
			}
		}else{
			WORD wKey = CVirtualKey::parse(key);
			if(wKey!=0) {
				d->m_description += CVirtualKey::toString(wKey);
				d->m_inputs.push_back(makeKeyDown(wKey));
				d->m_inputs.push_back(makeKeyUp(wKey));
			}
		}
	}

	for(size_t i=0; i<vModifiers.size(); i++){
		d->m_inputs.push_back(makeKeyUp(vModifiers[i]));
	}
}

void CAction::run( IActionRunner *pAR )
{
	//store keys pressed but not released.
	static set<WORD> pressedKeys;

	Logger::debug("CAction::run: start");
	//release keys if they are pressed.
	if(pressedKeys.empty()==false){
		for(set<WORD>::iterator i=pressedKeys.begin(); i!=pressedKeys.end(); ++i){
			WORD key = *i;
			releaseKey(key);
			Logger::debug("CAction::run: release key: %d, %s", key, CVirtualKey::toString(key));
		}
		pressedKeys.clear();
	}

	Logger::debug("CAction::run: -");

	for(size_t i=0; i<d->m_inputs.size(); i++){
		if(d->m_inputs[i].type==esiRaw){
			//send input(keyboard and mouse events) directly
			INPUT &in = d->m_inputs[i].input;
			if(1!=SendInput(1, &in, sizeof(INPUT))){
				Logger::error(L"SendInput fail, err=0x%x", ::GetLastError());
			}
			Sleep(10);

			//check and store key status
			//process keyboard events only
			if(in.type==INPUT_KEYBOARD){
				WORD key = in.ki.wVk;
				if( (in.ki.dwFlags&KEYEVENTF_KEYUP)==0 ){
					Logger::debug("CAction::run: press key: %d, %s", key, CVirtualKey::toString(key));
					pressedKeys.insert(key);
				}else{
					Logger::debug("CAction::run: release key: %d, %s", key, CVirtualKey::toString(key));
					//pressedKeys.erase(key);
				}
			}
			if(in.type==INPUT_MOUSE){
				if(in.mi.dwFlags&MOUSEEVENTF_LEFTDOWN){
					Logger::debug("CAction::run: press LBUTTON");
				}
				if(in.mi.dwFlags&MOUSEEVENTF_LEFTUP){
					Logger::debug("CAction::run: release LBUTTON");
				}
			}
		}else if(d->m_inputs[i].type==esiMoveMouse){
			if(pAR){
				pAR->runAction(esiMoveMouse);
				Logger::debug("CAction::run: moveMouse");
			}
		}else if(d->m_inputs[i].type==esiMoveMouseCenterY){
			if(pAR){
				pAR->runAction(esiMoveMouseCenterY);
				Logger::debug("CAction::run: moveMouseCenterY");
			}
		}
	}

	Logger::debug("CAction::run: end");
}

static void _initMaps();
static map<string, MobiGestureEvent> _mapNameToCode;
static map<MobiGestureEvent, string> _mapCodeToName;

MobiGestureEvent GesEvt::nameToCode( const char* name ){
	_initMaps();

	map<string, MobiGestureEvent>::iterator iGesture = _mapNameToCode.find(name);
	if(iGesture!=_mapNameToCode.end()){
		return iGesture->second;
	}else{
		return gesUndefined;
	}
}

const char* GesEvt::codeToName( MobiGestureEvent evt ){
	_initMaps();

	map<MobiGestureEvent, string>::iterator iGesture = _mapCodeToName.find(evt);
	if(iGesture!=_mapCodeToName.end()){
		return iGesture->second.c_str();
	}else{
		return "<Undefined gesture>";
	}
}

static void _initMaps(){
	if(_mapCodeToName.empty() || _mapNameToCode.empty()){
		IMobiGR *pGR = CreateMobiGR();
		MobiGestureEvent *gestures;
		int count = pGR->GetAllGestures(gestures);
		for(int i=0; i<count; ++i){
			MobiGestureEvent gesture = gestures[i];
			string gestureName = pGR->GetGestureName(gesture);
			_mapCodeToName[gesture] = gestureName;
			_mapNameToCode[gestureName] = gesture;
		}
		ReleaseMobiGR(&pGR);
	}
}
