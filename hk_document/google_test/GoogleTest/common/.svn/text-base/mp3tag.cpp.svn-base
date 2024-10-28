#include "stdafx.h"

#include <stdio.h>
#include <string>
using namespace std;

#include "id3/readers.h"
#include "id3/tag.h"

#ifdef DEBUG
#pragma comment(lib, "../id3lib/id3libD.lib")
#else
#pragma comment(lib, "../id3lib/id3lib.lib")
#endif

#include "Util.h"

const wstring Util::getMp3Artist( const wchar_t* fileName )
{
	wstring ret;

	ID3_Tag myTag;
	//char* buf;
	//size_t len, readlen;
	//FILE* f = NULL;
	//errno_t e = _wfopen_s(&f, fileName, L"rb");
	//if(!e){
	//	len = 64*1024;
	//	buf = new char[len];
	//	readlen = fread(buf, 1, len, f);
	//	fclose(f);
	//}
	//ID3_MemoryReader mr(buf, readlen);

	ifstream fin(fileName, ios::in|ios::binary);
	if(fin){
		ID3_IStreamReader ir(fin);

		int types[] = {ID3TT_ID3V2, ID3TT_ID3V1};
		for(size_t i=0; i<_countof(types); ++i){
			myTag.Link(ir, types[i]);
			ID3_Frame* myFrame = myTag.Find(ID3FID_LEADARTIST);
			if (NULL != myFrame)
			{
				// do something with myFrame
				ID3_FrameID fid = myFrame->GetID();
				const char* sfid = myFrame->GetTextID();
				ID3_Field* fld = myFrame->GetField(ID3FN_TEXT);
				ID3_TextEnc te = fld->GetEncoding();
				if(ID3TE_IS_DOUBLE_BYTE_ENC(te)){
					wchar_t* s = (wchar_t*)fld->GetRawUnicodeText();
					size_t l = fld->Size()/2;
					s[l] = 0;
					for(size_t i=0; i<l; i++){
						s[i] = ((s[i]&0xff00)>>8)|((s[i]&0xff)<<8);
					}
					//wprintf(L"unicode: %s\n", s);
					ret = s;
				}else{
					const char* s = fld->GetRawText();
					ret = Util::toUtf16(s, static_cast<int>(fld->Size()), 936);
					//printf("ascii: %s\n", s);
					//wprintf(L"converted: %s\n", ret.c_str());
				}
				if(ret.length()) break;
			}
		}
	}else{
		Logger::error(L"Open file %s fail!\n", fileName);
	}

	return ret;
}

