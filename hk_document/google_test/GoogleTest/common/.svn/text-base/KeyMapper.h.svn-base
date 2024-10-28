#pragma once

#include "IMobiGR.h"
#include "Mode.h"
#include "KeyRunner.h"
#include "Config.h"

class IGestureRunner{
public:
	virtual bool doAppAction(KeyMapperMode mode, MobiGestureEvent ges)=0;
};

class CKeyMapper : public IActionRunner, private CKeyRunner{
	MobiGestureMode m_gestureMode;
	KeyMapperMode m_mode;
	static bool s_bIsVista;
	bool m_isPassive;
	float m_x;
	float m_y;

	CConfig& m_cfg;

	IGestureRunner* m_pUserGestureRunner; //For the actions that can't be executed with keyboard and mouse simulation, or other action cannot be run with keymapper.

private:
	void getClientRect(RECT *pRect){
		HWND hwnd = FindAppWnd();
		GetClientRect(hwnd, pRect);
		LPPOINT pt = (LPPOINT)pRect;
		ClientToScreen(hwnd, &pt[0]);
		ClientToScreen(hwnd, &pt[1]);
	}

	void getClientMouthPos(LPPOINT currPos){
		HWND hwnd = FindAppWnd();		
		GetCursorPos(currPos);		
		ClientToScreen(hwnd, currPos);		
	}

	virtual void runAction(SInputType input);

public:
	CKeyMapper(CConfig& cfg);
	~CKeyMapper(void);

	void setPassive(bool bPassive=true){ m_isPassive=bPassive; }

	
	void setMode(KeyMapperMode mode);
	bool setModeByName(const char* appName, KeyMapperMode& mode);
	KeyMapperMode getMode(){return m_mode;}
	MobiGestureMode getGestureMode();

	void setUserGestureRunner(IGestureRunner* pGesRunner);

	bool isInApp(){ return (m_mode!=modeUndefined); }
	bool isInThisMode(KeyMapperMode modeOfApp){ return (modeOfApp==m_mode); }
	HWND FindAppWnd();

	bool checkAppQuit();
	void doAction(MobiGestureEvent gesture, void* pData=0);

	void focusFlashInIE( HWND hAppWnd );
	void focusControl( HWND hwndParent, const char* sClz, const char* sText=NULL );
	void focusWindow( HWND hwndFlash );
	HWND _FindAppWnd( KeyMapperMode mode );
	bool launchApp(KeyMapperMode mode);
	HWND waitAppWnd( KeyMapperMode mode );

	//since TeliLite
	//detect current teli mode by window class/title and exename
	bool detectMode(MobiGestureMode &gMode);
	//KeyMapperAction gestureToAction(int evt);
};
