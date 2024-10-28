
#ifndef ENCODE_H
#define ENCODE_H  

#ifdef MQTT
#define BUF_SIZE 2000
#endif

#ifdef BOTDA
#define BUF_SIZE 200000
#endif

#ifdef DTS
#define BUF_SIZE 2000
#endif

void encode_uchar_msg(unsigned char **pp, int elemid, unsigned char value, bool fixed);

void encode_ushort_msg(unsigned char **pp, int elemid, unsigned short value, bool fixed);

void encode_bool_msg(unsigned char **pp, int elemid, unsigned short value, bool fixed);

void encode_uint_msg(unsigned char **pp, int elemid, unsigned int value, bool fixed);

void encode_str_msg(unsigned char **pp, int elemid, char *value, bool fixed);

void encode_str_msg(unsigned char **pp, int elemid, char *value, bool fixed);

int encode_msg(unsigned char *msgbuf, unsigned char *endp);

void encode_fushort_msg(unsigned char **pp, int elemid, char *value, bool fixed);


/////////////////////////////////////////////////////////////////////////////////////////

unsigned int decode_uint_msg(unsigned char **pp, int &len);

unsigned short decode_ushort_msg(unsigned char **pp, int &len);

bool decode_bool_msg(unsigned char **pp, int &len);

char* decode_str_msg(int elemid, unsigned char **pp, int &len);

unsigned int decode_uint_msg(int elemid, unsigned char **pp, int &len);

unsigned short decode_ushort_msg(int elemid, unsigned char **pp, int &len);

unsigned short decode_msg_length(unsigned char **pp, int &len);

#endif

                   