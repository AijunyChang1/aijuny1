#include "StdAfx.h"
#include "KeyRunner.h"
#include "Util.h"

void CKeyRunner::pressKey( WORD key ){
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_KEYBOARD;
	input[0].ki.wVk = key;
	input[0].ki.wScan = MapVirtualKey(key, 0);
	addExtendedFlag(input[0].ki);

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::releaseKey( WORD key ){
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_KEYBOARD;
	input[0].ki.wVk = key;
	input[0].ki.wScan = MapVirtualKey(key, 0);
	input[0].ki.dwFlags = KEYEVENTF_KEYUP;
	addExtendedFlag(input[0].ki);

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::sendKey( WORD key ){
	INPUT input[2];
	memset(input,0,sizeof(input));
	input[0].type = input[1].type = INPUT_KEYBOARD;
	input[0].ki.wVk = input[1].ki.wVk = key;
	input[0].ki.wScan = input[1].ki.wScan = MapVirtualKey(key, 0);
	input[1].ki.dwFlags = KEYEVENTF_KEYUP;
	addExtendedFlag(input[0].ki);
	addExtendedFlag(input[1].ki);

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::sendCombine2( WORD modifier, WORD key )
{
	INPUT input[4];
	memset(input,0,sizeof(input));
	input[0].type = input[1].type = input[2].type = input[3].type = INPUT_KEYBOARD;
	input[0].ki.wVk = input[2].ki.wVk = modifier;
	input[0].ki.wScan = input[2].ki.wScan = MapVirtualKey(modifier, 0);
	input[1].ki.wVk = input[3].ki.wVk = key;
	input[1].ki.wScan = input[3].ki.wScan = MapVirtualKey(key, 0);
	input[2].ki.dwFlags = input[3].ki.dwFlags = KEYEVENTF_KEYUP;
	addExtendedFlag(input[0].ki);
	addExtendedFlag(input[1].ki);
	addExtendedFlag(input[2].ki);
	addExtendedFlag(input[3].ki);

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::sendCombines( WORD modifiers[], size_t nModifiers, WORD key )
{
	size_t numOfInputs = (nModifiers+1)*2;
	INPUT *input = new INPUT[numOfInputs];
	memset(input,0,sizeof(INPUT)*numOfInputs);

	INPUT *pInput = input;
	//[0,nModifiers): press modifiers key.
	for(size_t i=0; i<nModifiers; i++){
		pInput->type = INPUT_KEYBOARD;
		pInput->ki.wVk = modifiers[i];
		pInput->ki.wScan = MapVirtualKey(modifiers[i], 0);
		addExtendedFlag(pInput->ki);
		++pInput;
	}

	{
		pInput->type = INPUT_KEYBOARD;
		pInput->ki.wVk = key;
		pInput->ki.wScan = MapVirtualKey(key, 0);
		++pInput;

		pInput->type = INPUT_KEYBOARD;
		pInput->ki.wVk = key;
		pInput->ki.wScan = MapVirtualKey(key, 0);
		addExtendedFlag(pInput->ki);
		++pInput;
	}

	for(size_t i=0; i<nModifiers; i++){
		pInput->type = INPUT_KEYBOARD;
		pInput->ki.wVk = modifiers[i];
		pInput->ki.wScan = MapVirtualKey(modifiers[i], 0);
		addExtendedFlag(pInput->ki);
		++pInput;
	}
	CheckedSendInput(input, numOfInputs);
}

void CKeyRunner::pressMouse()
{
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::releaseMouse()
{
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_LEFTUP;

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::clickMouseF( float x, float y )
{
	INPUT input[3];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_MOUSE;
	input[1].type = INPUT_MOUSE;
	input[2].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE;
	input[1].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
	input[2].mi.dwFlags = MOUSEEVENTF_LEFTUP;
	int dx = int(x*65535);
	int dy = int(y*65535);
	if(dx<0) dx=0;
	if(dx>65535) dx=65535;
	if(dy<0) dy=0;
	if(dy>65535) dy=65535;
	input[0].mi.dx = dx;
	input[0].mi.dy = dy;

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::moveMouseF( float x, float y ){
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_MOVE|MOUSEEVENTF_ABSOLUTE;
	int dx = int(x*65535);
	int dy = int(y*65535);
	if(dx<0) dx=0;
	if(dx>65535) dx=65535;
	if(dy<0) dy=0;
	if(dy>65535) dy=65535;
	input[0].mi.dx = dx;
	input[0].mi.dy = dy;

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

bool CKeyRunner::isPressed( int key )
{
	SHORT ret = GetAsyncKeyState(key);
	return ret<0;
}

void CKeyRunner::clickMouse()
{
	INPUT input[2];
	memset(input,0,sizeof(input));
	input[0].type = input[1].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_LEFTDOWN;
	input[1].mi.dwFlags = MOUSEEVENTF_LEFTUP;

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::moveMouse( int dx, int dy, bool isRel ){
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_MOVE;
	input[0].mi.dx = dx;
	input[0].mi.dy = dy;

	if(isRel==false){
		int cx = GetSystemMetrics(SM_CXSCREEN);
		int cy = GetSystemMetrics(SM_CYSCREEN);

		input[0].mi.dwFlags |= MOUSEEVENTF_ABSOLUTE;
		input[0].mi.dx = dx*65535/(cx-1);
		input[0].mi.dy = dy*65535/(cy-1);
	}

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::dragMouse( int dx, int dy, bool isStart/*=true*/, bool isRel/*=true*/ )
{
	INPUT input[1];
	memset(input,0,sizeof(input));
	input[0].type = INPUT_MOUSE;
	input[0].mi.dwFlags = MOUSEEVENTF_MOVE|(isStart?MOUSEEVENTF_LEFTDOWN:MOUSEEVENTF_LEFTUP);
	input[0].mi.dx = dx;
	input[0].mi.dy = dy;

	if(isRel==false){
		int cx = GetSystemMetrics(SM_CXSCREEN);
		int cy = GetSystemMetrics(SM_CYSCREEN);

		input[0].mi.dwFlags |= MOUSEEVENTF_ABSOLUTE;
		input[0].mi.dx = dx*65535/(cx-1);
		input[0].mi.dy = dy*65535/(cy-1);
	}

	CheckedSendInput(input, sizeof(input)/sizeof(input[0]));
}

void CKeyRunner::CheckedSendInput( INPUT * input, size_t count ){
	//UINT n = SendInput((UINT)count, input, sizeof(INPUT));
	UINT n = 0;
	for(size_t i=0; i<count; Sleep(10),i++){
		SendInput((UINT)1, input+i, sizeof(INPUT));
	}

	DWORD err = 0;
	if(n==0) err = GetLastError();

	//if(n<count)
	{
		if(n==0){
			Logger::info("SendInput return: %d, errno=%d", n, err);
		}else{
			Logger::debug("SendInput return: %d", n);
		}
	}
}

//The extended keys consist of the ALT and CTRL keys on the right-hand side of the keyboard;
//the INS, DEL, HOME, END, PAGE UP, PAGE DOWN, and arrow keys in the clusters to the left of the numeric keypad;
//the NUM LOCK key; the BREAK (CTRL+PAUSE) key; the PRINT SCRN key;
//and the divide (/) and ENTER keys in the numeric keypad.
bool CKeyRunner::isExtendedKey( WORD key )
{
	switch(key){
		case VK_INSERT:
		case VK_DELETE:
		case VK_HOME:
		case VK_END:
		case VK_PRIOR:
		case VK_NEXT:
		case VK_LEFT:
		case VK_RIGHT:
		case VK_UP:
		case VK_DOWN:
			return true;
	}
	return false;
}

bool CKeyRunner::addExtendedFlag( KEYBDINPUT& ki )
{
	if(isExtendedKey(ki.wVk)){
		ki.dwFlags |= KEYEVENTF_EXTENDEDKEY;
		return true;
	}else{
		return false;
	}
}