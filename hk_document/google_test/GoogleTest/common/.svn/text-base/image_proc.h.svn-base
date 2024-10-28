#include <stdio.h>
#include <stdlib.h>

#ifdef  __cplusplus
extern "C" {
#endif

void brightness(unsigned char *buffer, int len, int v);
void contrast(unsigned char *buffer, int len, int v);

void brightness_sse(unsigned char *buffer, int len, int v);
void contrast_sse(unsigned char *buffer, int len, int v);

void yuv2rgb_float(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height);
void yuv2rgb_int(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height);
void yuv2rgb_int_sat(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height);

int yuv2rgb_float_sse(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height);

void yuv2rgb_int_flip(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height);
#ifdef  __cplusplus
}
#endif
