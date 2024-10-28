#pragma once
#include <string>
#include <map>

#include "Action.h"

enum MobiGestureMode;
enum KeyMapperMode{
	modeUndefined=0,
	modeMediaPhoto,
	modeMediaMusic,
	modeMediaVideo,
	modeViewMessage,
	modeGameBox,
	//modeGameDance,
	modeGameSkee,
	modeGameMoto,
	//modeView,
	modeNotepad,
	modeMediaCenter,
	modeWebBrowser,

	modeCustom1,
	modeCustom2,

	modeExtend1 = 100,
	modeExtend2,
	modeExtend3,
	modeExtend4,
	modeExtend5,
	modeExtend6,
	modeExtend7,
	modeExtend8,
	modeExtend9,
	modeExtend10,
};

typedef map<MobiGestureEvent, CAction> ActionMap;
class CMode{
public:
	KeyMapperMode mode;
	string name;
	string description;
	string appPath;
	string winClass;
	string winTitle;
	string postKeys;
	MobiGestureMode gesture; //specific which gesture group is using.

	ActionMap actions;

public:
	CMode(void);
	virtual ~CMode(void);

	bool match(const char *sClz, const char *sTitle);

	static KeyMapperMode RegisterMode(const char* name);
	static const char* codeToName(KeyMapperMode mode);
	static KeyMapperMode nameToCode(const char* name);

private:
	static int s_nextRegId;
};
