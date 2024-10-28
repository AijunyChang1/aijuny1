#include "stdafx.h"
#include "socket.h"
#include <stdio.h>
#include "CTILink.h"
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
            *p = elemid; p++;
            int len = strlen(value);
            if (len > 0) {
                *p = len + 1; p++;
                memcpy(p, value, len);
                p += len + 1;
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





