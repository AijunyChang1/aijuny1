#pragma once

///\addtogroup CommonLib
///@{

///\brief This class is for synchronous or asynchronous access to an RGB24 image buffer.
///\see CMainDlg|CTrackGestureSource|CTrackerThread|CFlashThread|CFlashThreadDH|
class RGB24Buffer{

public:
	RGB24Buffer(size_t w, size_t h);
	~RGB24Buffer();
	///\brief Set image data in, execute converting if needed. Exclusively.
	void setImgData(BYTE * pBuffer, long lBufferSize, bool flipLR=false, bool isYUY2=false);
	///\brief Set image data in, execute converting if needed. None-exclusively.
	bool trySetImgData(BYTE * pBuffer, long lBufferSize, bool flipLR=false, bool isYUY2=false);
	//data access
	///\brief Get pointer to image data. Non-exclusively.
	const byte* bufPtr();
	///\brief Get pointer to image data. Exclusively.
	byte* lock(int nMilli=INFINITE);
	///\brief Release access lock to image data.
	///\warning Must be called once after lock().
	bool unlock();
	const size_t getWidth() const { return width; }
	const size_t getHeight() const { return height; }
	int getSize() const { return size; }

private:
	HANDLE hLock;

	const size_t width;
	const size_t height;
	byte* data;
	int size;
	void freeBuffer();
	void internalSetImgData(BYTE * pBuffer, long lBufferSize, bool flipLR=false, bool isYUY2=false);
};

///@}