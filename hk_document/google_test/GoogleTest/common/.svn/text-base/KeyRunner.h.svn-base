#pragma once

class CKeyRunner{
public:
	static bool isPressed(int key);
	static void pressKey( WORD key );
	static void releaseKey( WORD key );
	static void sendKey( WORD key );
	static void sendCombine2(WORD modifier, WORD key);
	static void sendCombines(WORD modifiers[], size_t nModifiers, WORD key);
	static void clickMouse();
	static void pressMouse();
	static void releaseMouse();
	static void moveMouse(int dx, int dy, bool isRel=true);
	static void dragMouse(int dx, int dy, bool isStart=true, bool isRel=true);
	static void moveMouseF(float x, float y);
	static void clickMouseF(float x, float y);
	static void CheckedSendInput( INPUT * input, size_t count );
	static bool isExtendedKey(WORD key);
	static bool addExtendedFlag(KEYBDINPUT& ki);
};
