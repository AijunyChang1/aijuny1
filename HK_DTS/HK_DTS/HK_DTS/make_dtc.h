#ifndef MAKE_DTC_H
#define MAKE_DTC_H

#include "encode.h"

int make_request_msg(unsigned char *ps,int &msg_len, unsigned short t_id, int fun_code, int ch_id,  int regist_id, int regist_num);


int parse_dts_msg(unsigned char ** messageBuf, int& msg_len, unsigned short&ref_id, unsigned short &ch_id,unsigned short&func_code,  unsigned short &regist_len,  unsigned short *regist_value); 

#endif