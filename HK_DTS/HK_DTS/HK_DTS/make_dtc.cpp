#include "stdafx.h"
#include "make_dtc.h"
#include "encode.h"
int make_request_msg(unsigned char *ps, int &msg_len, unsigned short t_id, int fun_code, int ch_id, int regist_id, int regist_num)
{
	if (ps==NULL) return -1; 
	unsigned char *p = ps;
	encode_ushort_msg(&p,0,t_id,1);
	encode_ushort_msg(&p,0,0,1);
	encode_ushort_msg(&p,0,6,1);  

   	encode_uchar_msg(&p,0,ch_id,1);  
	encode_uchar_msg(&p,0,fun_code,1);

	encode_ushort_msg(&p,0,regist_id,1); 
	encode_ushort_msg(&p,0,regist_num,1);  
	msg_len=p-ps;


	return 0;

}



int parse_dts_msg(unsigned char ** messageBuf, int& msg_len, unsigned short&ref_id,unsigned short &ch_id, unsigned short&func_code,  unsigned short &regist_len,  unsigned short *regist_value)
{
	if ( *messageBuf == NULL ) return -1;
	if ( regist_value == NULL ) return -1;

	int len = msg_len;
	unsigned short code;
	unsigned char *p= *messageBuf;
	//memcpy(&code, p,2);
	code = decode_ushort_msg(&p,msg_len);
	//code =(code & 0x00F0);
	ref_id=code;
	
	code = decode_ushort_msg(&p,msg_len);
	code = decode_ushort_msg(&p,msg_len);
	unsigned short remain_len=code;
	if (remain_len>msg_len) return 1;

	unsigned char* pp =p;
	ch_id= *pp;
	p=p+1;
	func_code=*p;
	
	p=p+1;
	msg_len=msg_len-2;
    regist_len = *p;
	p=p+1;
	msg_len--;

	/*
	memcpy(regist_value, p,regist_len);
	p=p+regist_len;
	msg_len=msg_len-regist_len;
	*/
	unsigned short * temp_short=regist_value;
	if (regist_len>0)
	{
	     for (int i=0; i<regist_len/2; i++)
		 {
		     code = decode_ushort_msg(&p,msg_len);
			 *temp_short= code;
			 temp_short++;
		 
		 }
	}


	*messageBuf = p;


	return 0;

}