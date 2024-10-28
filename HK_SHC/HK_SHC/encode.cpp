#include "stdafx.h"
// #include "socket.h"
#include <stdio.h>
#include "encode.h"


void encode_uchar_msg(unsigned char **pp, int elemid, unsigned char value, bool fixed)
{
    unsigned char *p = *pp;
    if (fixed) {
        *p = value;
        p += 1;

        *pp = p;
    }
    else {
    }
}

void encode_ushort_msg(unsigned char **pp, int elemid, unsigned short value, bool fixed)
{
    unsigned char *p = *pp;
    if (fixed) {
        unsigned short inet = htons(value);
		//unsigned short inet = value;
        memcpy(p, &inet, 2);
        p += 2;

        *pp = p;
    }
    else {
    }
}

void encode_bool_msg(unsigned char **pp, int elemid, unsigned short value, bool fixed)
{
    encode_ushort_msg(pp, elemid, value, fixed);
}

void encode_uint_msg(unsigned char **pp, int elemid, unsigned int value, bool fixed)
{
    unsigned char *p = *pp;
    if (fixed) {
        unsigned int inet = htonl(value);
        memcpy(p, &inet, 4);
        p += 4;
        *pp = p;
    }
    else {
    }
}

void encode_str_msg(unsigned char **pp, int elemid, char *value, bool fixed)
{
    unsigned char *p = *pp;
    if (fixed) {
    }
    else {
        if (value != NULL) {
          //  *p = elemid; p++;
            int len = strlen(value);
            if (len > 0) {
               // *p = len + 1; p++;
                memcpy(p, value, len);
                p += len;
            }
            else {
              //  *p = 0 + 1; p++;
              //  *p = 0;
              //  p += 0 + 1;
            }
        }
        else {
           // *p = elemid; p++;
          //  *p = 0; p++;
        }
        *pp = p;
    }
}


void encode_fushort_msg(unsigned char **pp, int elemid, char *value, bool fixed)
{
    unsigned char *p = *pp;
    if (fixed) {
    }
    else {
        if (value != NULL) {
            *p = elemid; p++;
            int len = 2;
            if (len > 0) {
                *p = len ; p++;
                memcpy(p, value, len);
                p += len ;
            }
            else {
                *p = 0 + 1; p++;
                *p = 0;
                p += 0 + 1;
            }
        }
        else {
            *p = elemid; p++;
            *p = 0; p++;
        }
        *pp = p;
    }
}




int encode_msg(unsigned char *msgbuf, unsigned char *endp)
{
    unsigned int body_len = endp - msgbuf - 8;
    unsigned int net_body_len = htonl(body_len);
    memcpy(msgbuf, &net_body_len, 4);
    return body_len + 8;
}

/////////////////////////////////////////////////////////////


unsigned int decode_uint_msg(unsigned char **pp, int &len)
{
    unsigned int n = -1;
    if (len >= 4) {
        unsigned char *p = *pp;
        n = *p << 24; p++;
        n += *p << 16; p++;
        n += *p << 8; p++;
        n += *p; p++;
        *pp = p;
        len -= 4;
    }
    return n;
}

unsigned short decode_ushort_msg(unsigned char **pp, int &len)
{
    unsigned short n = -1;
    if (len >= 2) {
        unsigned char *p = *pp;
        n = *p << 8; p++;
        n += *p; p++;
        *pp = p;
        len -= 2;
    }
    return n;
}

unsigned short decode_msg_length(unsigned char **pp, int &len)
{
    unsigned short n = -1;
	unsigned char t_byte;
	unsigned char mask = 0x80;
	bool is_long = false;
    if (len >= 1) {
        unsigned char *p = *pp;
		t_byte = *p;
		is_long = (((t_byte & mask)==mask)?1:0);
		n = t_byte & 0x7f;
		p = p + 1;
		len = len - 1;
		if ((is_long) && (len >= 1))
		{
			t_byte = *p;
		    int n1 = t_byte & 0x7f;
			n1 = n1 * 128;
			n = n + n1;
			p = p + 1;
			len = len -1;
		}
        *pp = p;

    }	

    return n;
}

bool decode_bool_msg(unsigned char **pp, int &len)
{
    return (decode_ushort_msg(pp, len) > 0);
}

char* decode_str_msg(int elemid, unsigned char **pp, int &len)
{
    static char strmsg[512] = { 0 };
    memset(strmsg, 0, sizeof(strmsg));
    if (len > 0) {
        unsigned char *p = *pp;
        int elem = *p;
        if (elem == elemid) {
            p++; len--;
            int elem_len = *p; p++; len--;
            if (len >= elem_len) {
                memcpy(strmsg, p, elem_len);
                p += elem_len;
                len -= elem_len;
            }
        }
        *pp = p;
    }
    return strmsg;
}

unsigned int decode_uint_msg(int elemid, unsigned char **pp, int &len)
{
    unsigned int n = 0;
    if (len > 0) {
        unsigned char *p = *pp;
        int elem = *p;
        if (elem == elemid) {
            p++; len--;
            int elem_len = *p; p++; len--;
            if (len >= elem_len) {
                n = *p << 24; p++;
                n += *p << 16; p++;
                n += *p << 8; p++;
                n += *p; p++;
                len -= 4;
            }
        }
        *pp = p;
    }
    return n;
}

unsigned short decode_ushort_msg(int elemid, unsigned char **pp, int &len)
{
    unsigned short n = 0;
    if (len > 0) {
        unsigned char *p = *pp;
        int elem = *p;
        if (elem == elemid) {
            p++; len--;
            int elem_len = *p; p++; len--;
            if (len >= elem_len) {
                n = *p << 8; p++;
                n += *p; p++;
                len -= 2;
            }
        }
        *pp = p;
    }
    return n;
}

