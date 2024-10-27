#ifndef MAKE_MQTT_H
#define MAKE_MQTT_H

#include "encode.h"

int make_connect_request_msg(unsigned char *ps,int &msg_len, const char * local_ip);

int make_ping_request_msg(unsigned char *ps,int &msg_len);

int make_suscribe_request_msg(unsigned char *ps,int &msg_len, const char * sus_str);

int make_unsuscribe_request_msg(unsigned char *ps,int &msg_len, const char * sus_str);

int parse_mqtt_msg(unsigned char ** messageBuf, int& msg_len, unsigned char* , unsigned char*msg_jason); 

#endif