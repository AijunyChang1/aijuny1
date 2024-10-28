#ifndef MAKE_BOTDA_H
#define MAKE_BOTDA_H

#include "encode.h"
int make_ping_request_msg(unsigned char *ps,int &msg_len);
int make_reset_request_msg(unsigned char *ps,int &msg_len, const char *device_name);
int parse_botda_msg(unsigned char ** messageBuf, int& msg_len, unsigned char* topic, unsigned char*msg_jason);

#endif