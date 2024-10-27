#ifndef MAKE_FBG_H
#define MAKE_FBG_H

#include "encode.h"

struct Sensor_Node
{
	char sensor_id[7];
	float data;
	struct Sensor_Node *next;
};
 
int parse_fbg_msg(unsigned char ** messageBuf, int& msg_len, char* dev_id, char* rec_time,int& data_n, Sensor_Node**data); 



#endif