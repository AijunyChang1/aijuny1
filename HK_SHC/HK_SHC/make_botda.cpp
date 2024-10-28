#include "stdafx.h"
#include "make_botda.h"
#include "encode.h"
#include <string>
#include "func.h"
using namespace std;

	
int parse_botda_msg(unsigned char ** messageBuf, int& msg_len, unsigned char* topic, unsigned char*msg_jason)
{
	write_log("Enter parse_botda_msg().");
	if ( *messageBuf == NULL ) return -1;
	if ( topic == NULL ) return -1;
	if ( msg_jason == NULL ) return -1;
	int len = msg_len;
	//char temp[100];
	//memset((char*)&temp[0], 0, sizeof(temp));
	string msg_temp= (char*) *messageBuf;
	string temp = fetch_head(msg_temp, ":");
	if (temp!="Package-Head") return -1;
	write_log("Enter parse_botda_msg(). 1");
	temp = fetch_head(msg_temp, ":");
	if (temp!="Mode") return -1;
	string mode_type = msg_temp.substr(0, 1);
	if(mode_type!="3") return -1;
	len = len - 19;
	msg_temp = msg_temp.substr(1, msg_temp.size());
	temp = fetch_mid(msg_temp, "Len:", "Name:");
	if (temp == "") return 1;
	len = len -13;
	len = len-strlen(temp.c_str());
	if (!(len>0)) return 1;
	write_log("Enter parse_botda_msg(). 2");
	msg_temp = msg_temp.substr(13+strlen(temp.c_str()), msg_temp.size());
	unsigned int jason_len=atoi(temp.c_str());
	if(len<jason_len) 
	{
		write_log("Enter parse_botda_msg(). 3");
		return 1;	
	}
	string msg_type=fetch_mid(msg_temp, "\"Name\":\"", "\",");
	if (msg_type=="") return -1;
	write_log("Enter parse_botda_msg(). 4");
	memcpy(topic, msg_type.c_str(), msg_type.size());
	len = len - jason_len;
	* messageBuf = * messageBuf + (msg_len - len);
	msg_len = len;
	memcpy(msg_jason, msg_temp.c_str(), jason_len-1);
	write_log("Leave parse_botda_msg().");


	return 0;
}

int make_reset_request_msg(unsigned char *ps,int &msg_len, const char *device_name)
{
	if (ps==NULL) return -1;
	if (device_name == NULL) return -1;
	
	char temp_jason[200];
	sprintf(temp_jason, "{\"Name\":\"ALARM_RESET\"}\n",device_name);
	int jason_len=strlen(temp_jason);
	sprintf((char*)ps, "Package-Head:Mode:3Len:%dName:0End%s",jason_len, temp_jason);
	msg_len=strlen((char*)ps);
	return 0;

}