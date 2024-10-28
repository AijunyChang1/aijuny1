#pragma once

class CAutorun{

private:
	const char* m_sRegEntryName;
	bool m_bForAllUser;
	char m_sAppPath[MAX_PATH*2];
	

	HKEY openRegRunKey();

public:
	CAutorun(bool forAllUser=false, const char* entryName = "Teli");
	virtual ~CAutorun(void);

	bool isInstalled();
	void install();
	void uninstall();
};
