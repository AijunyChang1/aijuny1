#include "StdAfx.h"
#include "KeyMapper.h"
#include "Util.h"
#include <shellapi.h>

#include "Settings.h"

bool CKeyMapper::s_bIsVista = false;

CKeyMapper::CKeyMapper(CConfig& cfg)
: m_cfg(cfg), m_pUserGestureRunner(NULL)
{
	m_mode = modeUndefined;

	OSVERSIONINFO osVer;
	osVer.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	BOOL bRet = GetVersionEx(&osVer);
	s_bIsVista = (osVer.dwMajorVersion==6);
	m_isPassive = false;
}

CKeyMapper::~CKeyMapper(void){
}

void CKeyMapper::setMode( KeyMapperMode mode ){
	Logger::info("setMode: %d -> %d", m_mode, mode);
	m_mode = mode;
}

HWND CKeyMapper::FindAppWnd(){
	return _FindAppWnd(m_mode);
}

//Before clear code, will clear unused code in keymapper.
void CKeyMapper::doAction( MobiGestureEvent gesture, void* pData ){
	if(gesture==gesUndefined || gesture==gesNeutral) return;

	Logger::info("doAction: gesture=%s, %d", GesEvt::codeToName(gesture), gesture);
	
	HWND hwnd = FindAppWnd();
	if(hwnd==NULL){
		Logger::info("doAction: app window not found.");
		return;
	}

	if(m_isPassive==false){
		if(hwnd!=GetForegroundWindow()){
			if(SetForegroundWindow(hwnd)==FALSE){
				Logger::info("doAction: SetForegroundWindow fail!");
				return;
			}else{				
				Logger::debug("doAction: SetForegroundWindow succeed.");
			}
		}
	}

	if(pData){
		float *coor = (float*)pData;
		m_x = coor[0];
		m_y = coor[1];
	}

	//use actions2
	if(!m_pUserGestureRunner || !m_pUserGestureRunner->doAppAction(m_mode, gesture))
	{
		//const char* modeName = CMode::codeToName(m_mode);
		//const char* actionName = CAction::codeToName(action);
		//CAction* pAction = m_cfg.findCAction(m_mode, actionName);
		CAction* pAction = m_cfg.findCAction(m_mode, gesture);
		if(pAction!=NULL){
			static int kGameTest = CMode::nameToCode("gameTest");
			if(m_mode==modeGameMoto || m_mode==modeGameBox){
				CMode *pMode = m_cfg.getMode(m_mode);
				if(pMode){
					if(pMode->winClass=="IEFrame"){
						focusFlashInIE(hwnd);
					}
				}
			}else if(m_mode==modeWebBrowser){
				CMode *pMode = m_cfg.getMode(m_mode);
				if(pMode){
					if(pMode->winClass=="IEFrame"){
						focusControl(hwnd, "Internet Explorer_Server");
					}
				}
			}else if(kGameTest!=modeUndefined && m_mode==kGameTest){
				CMode *pMode = m_cfg.getMode(m_mode);
				if(pMode){
					if(pMode->winClass=="HTML Application Host Window Class"){
						//TODO: need check Util::FindDescendants in focusControl, it seems it can't find control handle.
						focusControl(hwnd, "MacromediaFlashPlayerActiveX");
						Logger::info("kGameTest: focusControl");
					}
				}
			}else if(getGestureMode()==GR_GOOGLE_EARTH){
				focusControl(hwnd, "QWidget", "RenderWidget");
			}


			pAction->run(this);
		}
	}

	//if(0)
	//{
	//	WORD* modifiers;
	//	size_t numOfModifiers;
	//	WORD keyCode;
	//	//TODO: increase performance
	//	const char* modeName = getModeName(m_mode);
	//	const char* actionName = getActionName(action);
	//	int err = m_cfg.getActionKey(modeName, actionName, modifiers, numOfModifiers, keyCode);
	//	if(err==0){
	//		//In cases of IEFrame, set focus to flash control
	//		{
	//			const char *clz;
	//			const char *title;
	//			m_cfg.getWinInfo(modeName, clz, title);
	//			if(lstrcmpA("IEFrame", clz)==0){
	//				HWND hAppWnd = hwnd;
	//				focusFlashInIE(hAppWnd);
	//			}
	//		}
	//		sendCombines(modifiers, numOfModifiers, keyCode);
	//	}
	//}
}

bool CKeyMapper::launchApp(KeyMapperMode mode){
	HINSTANCE hInst = (HINSTANCE)33;

	const char* sPath;
	const char* sPostKeys;
	//int err = m_cfg.getLaunchPath(CMode::codeToName(mode), sPath, sPostKeys);
	int err = m_cfg.getLaunchPath(mode, sPath, sPostKeys);
	if(err==0){
		hInst = ShellExecuteA( NULL, "open", sPath, NULL, "", SW_SHOWMAXIMIZED );
		waitAppWnd(mode);
		size_t nKeys = strlen(sPostKeys);
		if(nKeys>0){
			for(size_t i=0; i<nKeys; i++){
				switch(sPostKeys[i]){
					case 'l':
						sendKey(VK_LEFT);
						break;
					case 'r':
						sendKey(VK_RIGHT);
						break;
					case 'u':
						sendKey(VK_UP);
						break;
					case 'd':
						sendKey(VK_DOWN);
						break;
					case 'e':
						sendKey(VK_RETURN);
						break;
					case 't':
						sendKey(VK_TAB);
						break;
					case 'p':
						::Sleep(1000);
						break;
					default:
						sendKey(toupper(sPostKeys[i]));
						break;
				}
			}
		}
	}else{
		switch(mode){
		case modeMediaPhoto:
			{
				//if(PHOTO_AS_POWERCINEMA){
				//	hInst = ShellExecuteA( NULL, "open", "PowerCinema.exe", NULL, "", SW_SHOWMAXIMIZED );
				//}else{
					hInst = ShellExecuteA( NULL, "open", "photo\\U3326P704DT20090917142756.jpg", NULL, "", SW_SHOWMAXIMIZED );
				//}
			}
			break;
		case modeMediaMusic:
			hInst = ShellExecuteA( NULL, "open", "mplayer\\teli_music.wpl", NULL, "", SW_SHOWMAXIMIZED );
			break;
		case modeMediaVideo:
			hInst = ShellExecuteA( NULL, "open", "mplayer\\teli_video.wpl", NULL, "", SW_SHOWMAXIMIZED );
			break;
		case modeViewMessage:
			hInst = ShellExecuteA( NULL, "open", "message.wpl", NULL, "", SW_SHOWMAXIMIZED );
			break;
		case modeNotepad:
			hInst = ShellExecuteA( NULL, "open", "test.txt", NULL, "", SW_SHOWNORMAL );
			break;
		case modeGameMoto:
			hInst = ShellExecuteA( NULL, "open", "moto.swf", NULL, "", SW_SHOWMAXIMIZED);	//SW_SHOWNORMAL//
			break;
		case modeGameSkee:
			hInst = ShellExecuteA( NULL, "open", "skee.swf", NULL, "", SW_SHOWMAXIMIZED);
			break;
		case modeGameBox:
			hInst = ShellExecuteA( NULL, "open", "boxer.swf", NULL, "", SW_SHOWMAXIMIZED );	//SW_SHOWNORMAL//
			break;
		}
	}

	waitAppWnd(mode);
	return (DWORD_PTR(hInst)>32);
}

bool CKeyMapper::checkAppQuit(){
	if(FindAppWnd()==NULL){
		setMode(modeUndefined);
		return true;
	}else{
		return false;
	}
}

void CKeyMapper::runAction( SInputType input )
{
	switch(input){
		case esiMoveMouse:
			{
				moveMouseF(m_x, m_y);
				Logger::debug("moveMouse called by CAction::run: to (%1.3f, %1.3f)\n", m_x, m_y);
				break;
			}
		case esiMoveMouseCenterY:
			{
				RECT rec;
				POINT currPos;
				int yCenter;

				GetCursorPos(&currPos);
				getClientRect(&rec);
				yCenter = (rec.top + rec.bottom)>>1;				
				SetCursorPos(currPos.x, yCenter);				

				Logger::debug("moveMouseCenterY: CursorPos:(%d, %d)", currPos.x, currPos.y);
				Logger::debug("moveMouseCenterY: rec:(%d, %d, %d, %d)", rec.left, rec.top, rec.right, rec.bottom);
				Logger::debug("moveMouseCenterY: called by CAction::run: to (%d, %d)\n", currPos.x, yCenter);
				break;
			}
	}

}

//wait for app window created, set flash player to fullscreen.
HWND CKeyMapper::waitAppWnd( KeyMapperMode mode ){
	HWND hwnd = NULL;
	for(int i=0; i<10; i++){
		if(hwnd = _FindAppWnd(mode)) break;
		Sleep(200);
	}

	if(GetForegroundWindow()!=hwnd){
		SwitchToThisWindow(hwnd, TRUE);
		switch(mode){
			case modeGameMoto:
			case modeGameBox:
				//Sleep(1000);
				sendCombine2(VK_CONTROL, 'F');
				break;
		}
	}
	return hwnd;
}

HWND CKeyMapper::_FindAppWnd( KeyMapperMode mode )
{
	HWND hWnd = NULL;

	const char* sClz;
	const char* sTitle;
	int err = m_cfg.getWinInfo(mode, sClz, sTitle);
	if(err==0){
		//hWnd = FindWindow(sClz, sTitle);
		hWnd = Util::FindWindow(sClz, sTitle);
	}else{
		hWnd = NULL;
	}

	bool fail = (hWnd==NULL);
	if(fail){
		Logger::warn("FindAppWnd %s, hWnd=%x", "fail", hWnd);
	}
	return hWnd;
}

//TODO: do following for presets modes support:
//      1. add m_cfg2 for custom xml, 
//      2. add local store for saving user settings(which custom modes used.)
//      3. update SettingsDlg for display use selection.
bool CKeyMapper::detectMode(MobiGestureMode &gMode){
	static HWND s_lastFGWnd = NULL;
	static MobiGestureMode s_lastGesMode = GR_SEPARATE;

	HWND hwnd = GetForegroundWindow();

	{
		DWORD procId = 0;
		GetWindowThreadProcessId(hwnd, &procId);
		if(procId==GetCurrentProcessId()){
			gMode = GR_SEPARATE;
			return false;
		}
	}

	if(hwnd==s_lastFGWnd && s_lastGesMode!=GR_SEPARATE){
		gMode = s_lastGesMode;
		return true;
	}

	char sClz[MAX_PATH] = "";
	char sTitle[MAX_PATH] = "";
	GetClassNameA(hwnd, sClz, MAX_PATH);
	GetWindowTextA(hwnd, sTitle, MAX_PATH);

	static string lastWndTitle;
	if(lastWndTitle!=sTitle){
		lastWndTitle = sTitle;
		Logger::debug("detectMode: FG -> %s, %s", sClz, sTitle);
	}

	CMode* pMode = m_cfg.findMode(sClz, sTitle);
	if(pMode){
		gMode = pMode->gesture;
		if(gMode!=s_lastGesMode){
			s_lastGesMode = gMode;
			Logger::info("detectMode: found -> %s", pMode->name.c_str());
		}
		m_mode = CMode::nameToCode(pMode->name.c_str());
		return true;
	}else{
		gMode = GR_SEPARATE;
		return false;
	}
}

//KeyMapperAction CKeyMapper::gestureToAction( int evt )
//{
//	switch(m_mode)
//	{			
//		case modeGameBox:
//			switch(evt)
//			{
//				case gesMouseMove: return actionScreenMove;
//				case gesMouseClick: return actionScreenClick;
//
//
//				case gesBodyLeft: return actionBodyLeft;
//				case gesBodyRight: return actionBodyRight;
//
//				case gesHandsMovingFront: return actionPunch;
//				case gesLeftLiftShift: return actionBlock;
//
//				case gesHandsMovingBodyLeft:return actionPunchLeft;
//				case gesHandsMovingBodyRight:return actionPunchRight;
//				case gesLeftLiftShiftBodyLeft:return actionBlockLeft;
//				case gesLeftLiftShiftBodyRight:return actionBlockRight;
//
//				case gesBothUp: return actionHandsUp;
//				default: return actionUndefined;
//			}
//			break;
//		case modeGameSkee:
//			switch(evt)
//			{
//				//case EVENT_RIGHT_LEFT: return actionRHandLeft;
//				//case EVENT_LEFT_RIGHT: return actionLHandRight;
//				//case EVENT_LEFT_UP: return actionLHandUp;
//				//case EVENT_RIGHT_UP: return actionRHandUp;		
//				case gesMouseMove: return actionScreenMove;
//				case gesMouseClick: return actionScreenClick;
//
//				case gesBodyLeft: return actionBodyLeft;
//				case gesBodyRight: return actionBodyRight;			
//				case gesBothUp: return actionHandsUp;
//				default: return actionUndefined;
//			}
//		break;
//	case modeGameMoto:
//		switch(evt)
//		{
//			//case EVENT_RIGHT_LEFT: return actionRHandLeft;
//			//case EVENT_LEFT_RIGHT: return actionLHandRight;
//			//case EVENT_LEFT_UP: return actionLHandUp;
//			//case EVENT_RIGHT_UP: return actionRHandUp;		
//			case gesMouseMove: return actionScreenMove;
//			case gesMouseClick: return actionScreenClick;
//
//			case gesLeftHigherRightBottom: return actionBodyLeft;
//			case gesLeftLowerRightBottom: return actionBodyRight;
//			case gesLeftEqualRightMiddle:return actionSpeedUp;
//			case gesLeftHigherRightMiddle: return actionSpeedLeft;
//			case gesLeftLowerRightMiddle:return actionSpeedRight;
//				//case EVENTS_CAR_JUST_BRAKE:return actionBrake;
//			case gesBothUp: return actionHandsUp;
//			default: return actionUndefined;
//		}
//		break;
//	case modeMediaCenter:
//	case modeWebBrowser:
//		switch(evt){			
//			case gesRightLeft: return actionRHandLeft;
//			case gesRightRight: return actionRHandRight;			
//			case gesRightUp: return actionRHandUp;
//			case gesRightDown: return actionRHandDown;
//			case gesRightHold: return actionRHandHold;
//			case gesBothUpChest: return actionHandsUpChest;
//			case gesBothUp: return actionHandsUp;
//			case gesLeftUp: return actionLHandUp;
//			default: return actionUndefined;
//		}
//		break;
//	case modeMediaPhoto:
//	case modeMediaMusic:
//	case modeMediaVideo:
//		switch(evt){
//			case gesRightLeft: return actionRHandLeft;
//			case gesLeftRight: return actionLHandRight;
//			case gesLeftUp: return actionLHandUp;
//			case gesRightUp: return actionRHandUp;
//			case gesBothUp: return actionHandsUp;
//			case gesHandsFar: return actionZoomIn;
//			case gesHandsClose: return actionZoomOut;
//			case gesLeftUpShift: return actionLHandUpShift;
//			case gesRightUpShift: return actionRHandUpShift;
//			default: return actionUndefined;
//		}
//		break;				
//	case modeNotepad:
//	default://modeControl
//		switch(evt){
//			case gesRightLeft: return actionRHandLeft;
//			case gesLeftRight: return actionLHandRight;
//			case gesRightLeftFast: return actionRHandLeftFast;
//			case gesLeftRightFast: return actionLHandRightFast;
//			case gesStopLeftFast: return actionFastStopLeft;
//			case gesStopRightFast: return actionFastStopRight;
//			case gesLeftUp: return actionLHandUp;
//			case gesRightUp: return actionRHandUp;
//			case gesBothUp: return actionHandsUp;
//			default: return actionUndefined;
//		}
//		break;				
//	}		
//}

void CKeyMapper::focusWindow( HWND hwndCtrl )
{
	//gain focus to flash control:
	HWND oldFocus = NULL;
	HWND newFocus = NULL;
	{
		DWORD tid, pid, tidCurrent;
		tid = GetWindowThreadProcessId(hwndCtrl, &pid);
		tidCurrent = GetCurrentThreadId();

		BOOL bRet = FALSE;
		if(tid!=tidCurrent){
			bRet = AttachThreadInput(tidCurrent, tid, TRUE);
			if(bRet==FALSE){
				Logger::error("AttachThreadInput TRUE, fail!");
			}
		}

		oldFocus = SetFocus(hwndCtrl);
		newFocus = GetFocus();

		if(tid!=tidCurrent){
			bRet = AttachThreadInput(tidCurrent, tid, FALSE);
			if(bRet==FALSE){
				Logger::error("AttachThreadInput FALSE, fail!");
			}
		}
	}
	if(newFocus==hwndCtrl){
		Logger::debug("doAction: SetFocus succeed!");
	}
}

void CKeyMapper::focusFlashInIE( HWND hAppWnd )
{
	HWND hwndFlash = Util::FindDescendants(hAppWnd, "MacromediaFlashPlayerActiveX", NULL);
	if(hwndFlash){
		Logger::debug("doAction: Found flash control handle!");

		focusWindow(hwndFlash);
	}else{
		Logger::info("doAction: Can't find flash control handle!");
	}
}

void CKeyMapper::focusControl( HWND hwndParent, const char* sClz, const char* sText )
{
	HWND hwndCtrl = Util::FindDescendants(hwndParent, sClz, sText);
	if(hwndCtrl){
		Logger::debug("doAction: Found control handle!");

		focusWindow(hwndCtrl);
	}else{
		Logger::info("doAction: Can't find control handle!");
	}
}

bool CKeyMapper::setModeByName( const char* appName, KeyMapperMode& mode )
{
	KeyMapperMode aMode = CMode::nameToCode(appName);
	if(aMode==m_mode){
		Logger::warn(L"set to current mode!\n");
		return false;
	}else if(aMode!=modeUndefined){
		mode = aMode;
		setMode(aMode);
		return true;
	}else{
		return false;
	}
}

MobiGestureMode CKeyMapper::getGestureMode()
{
	CMode* pMode = m_cfg.getMode(m_mode);
	if(pMode){
		return pMode->gesture;
	}else{
		return GR_SEPARATE;
	}
}

void CKeyMapper::setUserGestureRunner( IGestureRunner* pGesRunner )
{
	m_pUserGestureRunner = pGesRunner;
}

