#include <stdio.h>
#include <stdlib.h>

// #define saturate_zero(a) a=((((unsigned int)a>>24)^255)&a)
#define saturate_zero(a) ((((unsigned int)a>>24)^255)&a)

void brightness(unsigned char *buffer, int len, int v)
{
int t,r;

  if (v>0)
  {
    for (t=0; t<len; t++)
    {
      r=buffer[t]+v;
      if (r>255) r=255;
      buffer[t]=r;
    }
  }
    else
  {
    for (t=0; t<len; t++)
    {
      r=buffer[t]+v;
      if (r<0) r=0;
      buffer[t]=r;
    }
  }
}

void contrast(unsigned char *buffer, int len, int v)
{
int t,r;

  if (v>0)
  {
    for (t=0; t<len; t++)
    {
      r=buffer[t]*v;
      if (r<0) r=0;
      if (r>255) r=255;
      buffer[t]=r;
    }
  }
    else
  {
    v=-v;
    for (t=0; t<len; t++)
    {
      r=buffer[t]/v;
      if (r<0) r=0;
      if (r>255) r=255;
      buffer[t]=r;
    }
  }
}

/*

http://en.wikipedia.org/wiki/YUV

From YUV to RGB:
R =     Y + 1.13983 V
G =     Y - 0.39466 U - 0.58060 V
B =     Y + 2.03211 U

*/

void yuv2rgb_float(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height)
{
float u1,uv1,v1;
float u,v;
int len;
int r,g,b;
int rgb_ptr,y_ptr,t;

  len=width*height*2;

  rgb_ptr=0;
  y_ptr=0;

  for (t=0; t<len; t+=4)  /* process 2 pixels at a time */
  {
	  int i = t/4*6;
    /* Compute parts of the UV components */
    u=(float)(yuv_buffer[t+1]-128);
    v=(float)(yuv_buffer[t+3]-128);

    v1=(1.13983f*(float)v);
    uv1=-(0.39466f*(float)u)-(0.58060f*(float)v);
    u1=(2.03211f*(float)u);

    /* Run even pixel through formula */

    r=(int)(yuv_buffer[t] + v1);
    g=(int)(yuv_buffer[t] + uv1);
    b=(int)(yuv_buffer[t] + u1);

    if (r>255) r=255;
    if (g>255) g=255;
    if (b>255) b=255;

    if (r<0) r=0;
    if (g<0) g=0;
    if (b<0) b=0;

    rgb_buffer[i  ]=b;
    rgb_buffer[i+1]=g;
    rgb_buffer[i+2]=r;

    /* Run odd pixel through formula */

    r=(int)(yuv_buffer[t+2] + v1);
    g=(int)(yuv_buffer[t+2] + uv1);
    b=(int)(yuv_buffer[t+2] + u1);

    if (r>255) r=255;
    if (g>255) g=255;
    if (b>255) b=255;

    if (r<0) r=0;
    if (g<0) g=0;
    if (b<0) b=0;

    rgb_buffer[i+3]=b;
    rgb_buffer[i+4]=g;
    rgb_buffer[i+5]=r;
  }
}

void yuv2rgb_int(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height)
{
int u1,uv1,v1;
int u,v;
int len;
int r,g,b;
int y1;
int t;

  len=width*height*2;

  for (t=0; t<len; t+=4)  /* process 2 pixels at a time */
  {
	  int i = t/4*6;
    /* Compute parts of the UV components */

    u=yuv_buffer[t+1]-128;
    v=yuv_buffer[t+3]-128;

    v1=(5727*v);
    uv1=-(1617*u)-(2378*v);
    u1=(8324*u);

    /* Run even pixel through formula */

    y1=yuv_buffer[t]<<12;

    r=(y1 + v1)>>12;
    g=(y1 + uv1)>>12;
    b=(y1 + u1)>>12;

    if (r>255) r=255;
    if (g>255) g=255;
    if (b>255) b=255;

    if (r<0) r=0;
    if (g<0) g=0;
    if (b<0) b=0;

    rgb_buffer[i  ]=b;
    rgb_buffer[i+1]=g;
    rgb_buffer[i+2]=r;

/*
    if (r>255) rgb_buffer[rgb_ptr]=255;
      else
    if (r<0) rgb_buffer[rgb_ptr]=0;
      else
    rgb_buffer[rgb_ptr]=r;

    if (g>255) rgb_buffer[rgb_ptr+1]=255;
      else
    if (g<0) rgb_buffer[rgb_ptr+1]=0;
      else
    rgb_buffer[rgb_ptr+1]=g;

    if (b>255) rgb_buffer[rgb_ptr+2]=255;
      else
    if (b<0) rgb_buffer[rgb_ptr+2]=0;
      else
    rgb_buffer[rgb_ptr+2]=b;
*/

    /* Run odd pixel through formula */

    y1=yuv_buffer[t+2]<<12;

    r=(y1 + v1)>>12;
    g=(y1 + uv1)>>12;
    b=(y1 + u1)>>12;

    if (r>255) r=255;
    if (g>255) g=255;
    if (b>255) b=255;

    if (r<0) r=0;
    if (g<0) g=0;
    if (b<0) b=0;

    rgb_buffer[i+3]=b;
    rgb_buffer[i+4]=g;
    rgb_buffer[i+5]=r;

/*
    if (r>255) rgb_buffer[rgb_ptr+3]=255;
      else
    if (r<0) rgb_buffer[rgb_ptr+3]=0;
      else
    rgb_buffer[rgb_ptr+3]=r;

    if (g>255) rgb_buffer[rgb_ptr+4]=255;
      else
    if (g<0) rgb_buffer[rgb_ptr+4]=0;
      else
    rgb_buffer[rgb_ptr+4]=g;

    if (b>255) rgb_buffer[rgb_ptr+5]=255;
      else
    if (b<0) rgb_buffer[rgb_ptr+5]=0;
      else
    rgb_buffer[rgb_ptr+5]=b;
*/
  }
}

void yuv2rgb_int_sat(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height)
{
unsigned char *u_buffer,*v_buffer;
int u1,uv1,v1;
int u,v;
int len;
int r,g,b;
int rgb_ptr,y_ptr,t;
int y1;

  len=width*height;

  u_buffer=yuv_buffer+len;
  len=len/2;
  v_buffer=u_buffer+len;

  rgb_ptr=0;
  y_ptr=0;

  for (t=0; t<len; t++)  /* process 2 pixels at a time */
  {
    /* Compute parts of the UV components */

    u=u_buffer[t]-128;
    v=v_buffer[t]-128;

    v1=(5727*v);
    uv1=-(1617*u)-(2378*v);
    u1=(8324*u);

    /* Run even pixel through formula */

    y1=yuv_buffer[y_ptr]<<12;

    r=(y1 + v1)>>12;
    g=(y1 + uv1)>>12;
    b=(y1 + u1)>>12;


    // saturate_zero(r);
    // saturate_zero(g);
    // saturate_zero(b);

    if (r>255) r=255;
      else
    rgb_buffer[rgb_ptr]=saturate_zero(r);

    if (g>255) g=255;
      else
    rgb_buffer[rgb_ptr+1]=saturate_zero(g);

    if (b>255) b=255;
      else
    rgb_buffer[rgb_ptr+2]=saturate_zero(b);

    /* Run odd pixel through formula */

    y1=yuv_buffer[y_ptr+1]<<12;

    r=(y1 + v1)>>12;
    g=(y1 + uv1)>>12;
    b=(y1 + u1)>>12;


    // saturate_zero(r);
    // saturate_zero(g);
    // saturate_zero(b);

    if (r>255) rgb_buffer[rgb_ptr+3]=255;
      else 
    rgb_buffer[rgb_ptr+3]=saturate_zero(r);

    if (b>255) b=255;
      else
    rgb_buffer[rgb_ptr+4]=saturate_zero(g);

    if (g>255) g=255;
      else
    rgb_buffer[rgb_ptr+5]=saturate_zero(b);

    rgb_ptr+=6;
    y_ptr+=2;
  }
}

void yuv2rgb_int_flip(unsigned char *yuv_buffer, unsigned char *rgb_buffer, int width, int height){
	unsigned char *yuv = yuv_buffer;
	unsigned char *rgb = rgb_buffer+width*3*(height-1);
	const int yuv_step = width*2;
	const int rgb_step = -width*3;
	int y;
	for(y=0; y<height; ++y){
		yuv2rgb_int(yuv, rgb, width, 1);
		yuv+=yuv_step;
		rgb+=rgb_step;
	}
}
