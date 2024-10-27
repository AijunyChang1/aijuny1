#include "stdafx.h"
#include "make_fbg.h"
#include "encode.h"


int parse_fbg_msg(unsigned char ** messageBuf, int& msg_len, char* dev_id, char* rec_time, int& data_n, Sensor_Node** data)
{
	if ( *messageBuf == NULL ) return -1;        //-1： 未作任何处理
	                                             //0： 成功处理一个消息
	                                             //1： 不完整消息

	int len = msg_len;
	unsigned short code;
	unsigned char *p= *messageBuf;
	unsigned char *p_next=p+1;
	code=(*p)<<8;
	code=((*p)<<8)+(*p_next);
	while ((code!=65260)&&(msg_len>1)) //0xFEEC
	//while ((code!=60670)&&(msg_len>1)) //0xFEEC
	{
		p=p+1;
		p_next=p+1;
		msg_len=msg_len-1;
	    code=(*p)<<8+*p_next;
	}
	if (msg_len==1)  return -1;
	*messageBuf=p+2;
	p=*messageBuf;

	code = decode_ushort_msg(&p,msg_len);  //parse version && pack type 0x1050=4176
	memcpy(dev_id, p, 8);
	msg_len=msg_len-8;
	if(msg_len<4) return 1;
	p=p+8;
	unsigned int pack_len = decode_uint_msg(&p,msg_len);
	if((p - *messageBuf + msg_len)<pack_len) return 1;
	data_n=(pack_len-29)/10;
	unsigned __int64 msg_time;
	msg_time = decode_uint64_msg(&p,msg_len);
	msg_time = 1711536627612;
	//char t[30;
	time_t t( msg_time);
	time (&t);
    struct tm* systemtime;
	systemtime=localtime(&t);
	char time[80];
	strftime(rec_time, 25, "%Y%m%d %X",systemtime);
	//strftime(&time[0], 80, "%Y-%m-%d",systemtime);

	code = *p;   //采样频率
	p++;
	msg_len--;
	struct Sensor_Node * node = NULL;
	struct Sensor_Node * sen_node=new struct Sensor_Node;
	struct Sensor_Node * sen_node_f=sen_node;
	node = sen_node;
	float temp_data=0.0;
	for(int i =0;i<data_n; i++)
	{
		if (node == NULL)
		{
		     node = new struct Sensor_Node;
			 memset(node, 0, sizeof(struct Sensor_Node));
			 node->next=NULL;

			 if(sen_node_f!=NULL) sen_node_f->next=node;
			 sen_node_f=node;
		}
		memcpy(node->sensor_id, p, 6);
		p=p+6;
		msg_len=msg_len-6;
		memcpy(&temp_data,p,4);
		p=p+4;
		msg_len=msg_len-4;
		node->data = temp_data;

		node = NULL;
	
	}
	*data=sen_node;

	/////////////////////////////////////
	code = decode_ushort_msg(&p,msg_len); //crc
	code = decode_ushort_msg(&p,msg_len); //结束位
	msg_len=msg_len-2;
	*messageBuf = p;


	return 0;

}