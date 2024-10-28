#include "stdafx.h"
#include "Settings.h"

int FLASHWIN_W = 800;
int FLASHWIN_H = 600;

int VIDEO_W = 320;
int VIDEO_H = 240;

int FILTER_VIDEO_W = VIDEO_W;
int FILTER_VIDEO_H = VIDEO_H;

//TODO: remove this var
int VIDEO_DEPTH = 24;

int DBGWIN_H = 150;
int DBGWIN_W = DBGWIN_H*VIDEO_W/VIDEO_H;

BOOL SHOW_VIRTUAL = FALSE;

//CConfig m_cfg;
//CSettings g_settings;

void videoSettings(int video_w, int video_h, int video_depth){
	VIDEO_W = video_w;
	VIDEO_H = video_h;
	VIDEO_DEPTH = video_depth;

	DBGWIN_W = DBGWIN_H*VIDEO_W/VIDEO_H;
}

void videoSetDepth(int video_depth){
	VIDEO_DEPTH = video_depth;
}

void setShowVirtual(BOOL isShow){
	SHOW_VIRTUAL = isShow;
}