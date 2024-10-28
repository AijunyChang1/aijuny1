#include "stdafx.h"
#include "make_mqtt.h"
#include "encode.h"
int make_connect_request_msg(unsigned char *ps,int &msg_len, const char * local_ip)
{
	if (ps==NULL) return -1; 
	unsigned char *p = ps;
	encode_uchar_msg(&p,0,16,1);
	encode_uchar_msg(&p,0,28,1);
	encode_ushort_msg(&p,0,4,1);
	encode_str_msg(&p,0,"MQTT",false);
   	encode_uchar_msg(&p,0,4,1);   //MQTT version: 3.1.1
	encode_uchar_msg(&p,0,2,1);   //Connect flags
	encode_ushort_msg(&p,0,15,1);
	unsigned short clientid_len = strlen(local_ip);
	encode_ushort_msg(&p,0,clientid_len,1);
	encode_str_msg(&p,0,(char*)local_ip,false);
	msg_len=p-ps;
    unsigned short load_len=12+clientid_len;
	p=ps+1;
	encode_uchar_msg(&p,0,load_len,1);

	return 0;

}

int make_ping_request_msg(unsigned char *ps,int &msg_len)
{
	if (ps==NULL) return -1; 
	unsigned char *p = ps;
	encode_uchar_msg(&p,0,0xC0,1);
	encode_uchar_msg(&p,0,0,1);
	msg_len=p-ps;

	return 0;
}

int make_suscribe_request_msg(unsigned char *ps,int &msg_len, const char * sus_str)
{
	if (ps==NULL) return -1; 
	if (sus_str==NULL) return -1;
	unsigned char *p = ps;
	//encode_uchar_msg(&p,0,128,1);
	encode_uchar_msg(&p,0,130,1);
	encode_uchar_msg(&p,0,28,1);    //Length
	encode_ushort_msg(&p,0,2,1);
	//encode_uchar_msg(&p,0,0,1);
	unsigned short sustr_len = strlen(sus_str);
	encode_ushort_msg(&p,0,sustr_len,1);   //Length
	encode_str_msg(&p,0,(char*)sus_str,false);
	encode_uchar_msg(&p,0,0,1);
	msg_len=p-ps;
    unsigned short load_len=5+sustr_len;
	p=ps+1;
	encode_uchar_msg(&p,0,load_len,1);

	return 0;

}

int make_unsuscribe_request_msg(unsigned char *ps,int &msg_len, const char * sus_str)
{
	if (ps==NULL) return -1; 
	if (sus_str==NULL) return -1;
	unsigned char *p = ps;
	//encode_uchar_msg(&p,0,128,1);
	encode_uchar_msg(&p,0,162,1);
	encode_uchar_msg(&p,0,28,1);    //Length
	encode_ushort_msg(&p,0,3,1);
	unsigned short sustr_len = strlen(sus_str);
	encode_ushort_msg(&p,0,sustr_len,1);   //Length
	encode_str_msg(&p,0,(char*)sus_str,false);
	msg_len=p-ps;
	unsigned short load_len=4+sustr_len;
	p=ps+1;
	encode_uchar_msg(&p,0,load_len,1);


	return 0;

}

int parse_mqtt_msg(unsigned char ** messageBuf, int& msg_len, unsigned char*topic , unsigned char*msg_jason)
{
	if ( *messageBuf == NULL ) return -1;
	if ( topic == NULL ) return -1;
	if ( msg_jason == NULL ) return -1;
	int len = msg_len;
	unsigned short code;
	memcpy(&code, *messageBuf,2);
	code =(code & 0x00F0);
//	unsigned char* t=(unsigned char*)&code;
//  	int len_t=2;
//	code= decode_ushort_msg(&t, len_t);
	if (code==48)
	{

	    unsigned char *p = *messageBuf+1;

	    len = len - 1;
		//memcpy(&code, p, 2);
		//code =(code & 0x00FF);
	    unsigned short pure_len = decode_msg_length(&p, len);
		if (pure_len>len)
		{
		    return 1;
		}
		
	    int topic_len = decode_ushort_msg(&p, len);
		if (topic_len > len) 
		{
			return 1;
		}
		if(topic_len<100)
		{
	        memcpy(topic, p, topic_len);
		}
		else
		{
		    memcpy(topic, p, 99);
		}
		len = len-topic_len;

	    p = p + topic_len;
	    int jason_len = pure_len - 2 - topic_len;
		if (jason_len>len) 
		{
		    return 1;
		}
		if (jason_len<BUF_SIZE)
		{
	        memcpy(msg_jason, p, jason_len);
		}
		else
		{
		    memcpy(msg_jason, p, BUF_SIZE-1);
		}
		p = p + jason_len;
		msg_len= msg_len - (p-(*messageBuf));
		*messageBuf = p;

	}

	return 0;

}