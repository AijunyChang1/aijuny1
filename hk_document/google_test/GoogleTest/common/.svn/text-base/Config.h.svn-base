#pragma once

#include <atlbase.h>
#include <atlcom.h>
#include <msxml2.h>

#include <string>
#include <vector>
#include <map>

#include "Mode.h"

using namespace std;

class CConfig{
	typedef map<KeyMapperMode, CMode> ModeMap;

	//built-in modes
	ModeMap m_modes;

	//extended modes
	ModeMap m_presets;
	vector<KeyMapperMode> m_presetModes;

	bool m_isFS;

private:
	static string strAttr( IXMLDOMElement* elm, const char* attrName );
	int readActions2( CMode& mode, CComPtr<IXMLDOMElement> elm );

public:
	CConfig(void);
	virtual ~CConfig(void);

	int load(const wchar_t* path);
	int save(char* path);

	//add modes in aCfg;
	//	replace: the modes exist will be replaced or not.
	int loadPresets(CConfig &aCfg, bool replace=false);

	//add modes not only in aCfg, but also in (sel1,sel2). the modes has same names with built-in modes will not be merged.
	int applyPresets();

	bool hasMode(KeyMapperMode mode);
	int getLaunchPath(KeyMapperMode mode, const char* &sPath, const char* &postKeys);
	int getWinInfo(KeyMapperMode mode, const char* &sClassName, const char* &sTitle);

	CMode* getMode(KeyMapperMode mode);
	CMode* findMode(const char* sClz, const char* sTitle);
	CAction* findCAction(KeyMapperMode mode, MobiGestureEvent gesture);

	bool isFlashFullScreen(){return m_isFS; }

	size_t getModes(vector<KeyMapperMode> &names);
	size_t getDownloadedNames(vector<string> &names);
};
