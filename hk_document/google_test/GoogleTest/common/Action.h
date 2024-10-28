#pragma once

#include <string>
using namespace std;

enum SInputType{
	esiRaw = 0,
	esiMoveMouse,
	esiMoveMouseCenterY
};

//interface to run some action
class IActionRunner{
public:
	virtual void runAction(SInputType input) = 0;
};

enum MobiGestureEvent;
class CActionData;
class CAction{
public:
	CAction(void);
	CAction(const char *name);
	~CAction(void);

	CAction(const CAction& a);
	CAction& operator=(const CAction& a);

	string getName();
	void setName(string &name);
	string toString();

	// fill m_description (for settings dialog) and m_inputs (for keymapping) fields
	void parse(string sModifiers, string sKeys);
	void run(IActionRunner *pAR);

private:
	CActionData* d;
};

class GesEvt{
public:
	static MobiGestureEvent nameToCode(const char* name);
	static const char* codeToName(MobiGestureEvent evt);
};
