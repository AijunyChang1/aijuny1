#include "StdAfx.h"

#include "RGB24Buffer.h"
#include "image_proc.h"
#include "Util.h"

RGB24Buffer::RGB24Buffer( size_t w, size_t h ) :width(w), height(h)
{
	data = NULL;
	size = 0;
	hLock = CreateMutex(NULL, FALSE, NULL);
}

void RGB24Buffer::freeBuffer()
{
	if(data){
		delete[] data;
		data = NULL;
	}
	size = 0;
}

RGB24Buffer::~RGB24Buffer()
{
	freeBuffer();
	CloseHandle(hLock);
}

void RGB24Buffer::internalSetImgData( BYTE * pBuffer, long lBufferSize, bool flipLR/*=false*/, bool isYUY2/*=false*/ )
{
	if(data) freeBuffer();
	{
		size = int(width * height * 3);
		data = new BYTE[size];
	}
	if(!isYUY2 && lBufferSize!=size){
		Logger::warn("VideoDataSt::setImgData: Different buffer size! %d vs %d", lBufferSize, size);
	}
	if(isYUY2){
		yuv2rgb_int_flip(pBuffer, data, (int)width, (int)height);
	}else{
		if(flipLR){
			const size_t pitch = width*3;
			byte* pSrc = pBuffer;
			byte* pDst = data;
			for(size_t y=0; y<height; y++){
				size_t x=0;
				size_t x2=pitch-3;
				while(x<pitch){
					pDst[x]   = pSrc[x2];
					pDst[x+1] = pSrc[x2+1];
					pDst[x+2] = pSrc[x2+2];
					x+=3;
					x2-=3;
				}
				pSrc+=pitch;
				pDst+=pitch;
			}
		}else{
			memcpy(data, pBuffer, size);
		}
	}
}

bool RGB24Buffer::trySetImgData( BYTE * pBuffer, long lBufferSize, bool flipLR/*=false*/, bool isYUY2/*=false*/ )
{
	if(WAIT_OBJECT_0==WaitForSingleObject(hLock, 0)){
		CMutexRelease mutexRelease(hLock);
		internalSetImgData(pBuffer, lBufferSize, flipLR, isYUY2);
		return true;
	}else
		return false;

}

void RGB24Buffer::setImgData( BYTE * pBuffer, long lBufferSize, bool flipLR/*flase*/, bool isYUY2/*=false*/ )
{
	WaitForSingleObject(hLock, INFINITE);

	CMutexRelease mutexRelease(hLock);
	internalSetImgData(pBuffer, lBufferSize, flipLR, isYUY2);
}

const byte* RGB24Buffer::bufPtr()
{
	return data;
}

byte* RGB24Buffer::lock(int nMilli)
{
	if(!data) return NULL;

	DWORD result = WaitForSingleObject(hLock, nMilli);
	if(result==WAIT_OBJECT_0){
		return data;
	}else{
		Logger::error(L"RGB24Buffer::lock: res=%d", result);
		return NULL;
	}
}

bool RGB24Buffer::unlock()
{
	if(ReleaseMutex(hLock)){
		return true;
	}else{
		DWORD eCode = GetLastError();
		Logger::warn("RGB24Buffer::unlock return false, err=%d\n", eCode);
		return false;
	}

}
