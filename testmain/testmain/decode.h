#include "socket.h"

struct ThParam
{
  RecvSendInfo resInfo;
  int threadnum;

};

//#include "testmainDlg.h"

void decode_msg(unsigned char *msgbuf, int len, RecvInfo* Param);

void on_cti_msg_parse(const unsigned char *buf, int len,RecvInfo* Param);

void on_cti_msg_recv_func(const char *buf, int len,RecvInfo* Param);

unsigned int decode_uint_msg(unsigned char **pp, int &len);

unsigned short decode_ushort_msg(unsigned char **pp, int &len);

bool decode_bool_msg(unsigned char **pp, int &len);

char* decode_str_msg(int elemid, unsigned char **pp, int &len);

unsigned int decode_uint_msg(int elemid, unsigned char **pp, int &len);

unsigned short decode_ushort_msg(int elemid, unsigned char **pp, int &len);

//void decode_float_msg(VXI_Event &evt, unsigned char **pp, int &len, int msgtype);


void on_open_conf(unsigned char *ps,RecvInfo* Param);

void on_heartbeat_conf(unsigned char *ps,RecvInfo* Param);

void on_close_conf(unsigned char *ps,RecvInfo* Param);

void on_query_device_info_conf(unsigned char *ps,RecvInfo* Param);

void on_query_agent_state_conf(unsigned char *ps,RecvInfo* Param);

void on_begin_call_event(RecvSendInfo Param,char* inNum,char* outNum,int callid);

void on_call_delivered_event(RecvSendInfo Param,char* inNum,char* outNum,int callid);

void on_call_established_event(RecvSendInfo Param,char* inNum,char* outNum, int callid);

void on_conn_clear_event(RecvSendInfo Param,char* inNum,char* outNum,int callid);

void on_end_call_event(RecvSendInfo Param,char* inNum,char* outNum, int callid);

void on_rtp_started_event(RecvSendInfo Param,char* inNum,char* outNum,int callid);

void on_set_agent_state_conf(unsigned char *ps,RecvInfo* Param);


void on_invite_vrs(ThParam Param,char* inNum,char* outNum,int callid);

void on_end_vrs(ThParam Param,char* inNum,char* outNum,int callid);


