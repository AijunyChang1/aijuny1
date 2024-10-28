


void encode_uchar_msg(unsigned char **pp, int elemid, unsigned char value, bool fixed);

void encode_ushort_msg(unsigned char **pp, int elemid, unsigned short value, bool fixed);

void encode_bool_msg(unsigned char **pp, int elemid, unsigned short value, bool fixed);

void encode_uint_msg(unsigned char **pp, int elemid, unsigned int value, bool fixed);

void encode_str_msg(unsigned char **pp, int elemid, char *value, bool fixed);

void encode_str_msg(unsigned char **pp, int elemid, char *value, bool fixed);

int encode_msg(unsigned char *msgbuf, unsigned char *endp);

void encode_fushort_msg(unsigned char **pp, int elemid, char *value, bool fixed);


