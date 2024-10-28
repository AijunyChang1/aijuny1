#pragma once
#include <fstream>
using namespace std;

///\addtogroup CommonLib
///@{

///\brief This class calculate frame rate in latest _N frames of webcam and notify client class when it's lower than threshold.
template<size_t _N>
class CFPSDetector{

public:
	CFPSDetector(void)
		:m_current(0)
		,m_num(0)
		,threshold(7.0f)
		,above_threshold(threshold+0.1f)
		,m_lastLowFpsTick(0)
		,m_startTick(0)
		//,f("fps.log")
	{
		memset(m_ticks, 0, sizeof(DWORD)*_N);
	}

	///Call this function when got a video frame.
	void OnGotFrame(){
		DWORD now = GetTickCount();

		//store time of first frame
		if(!m_startTick) m_startTick = GetTickCount();

		//f << now << endl;
		//Logger::info(L"m_current=%d", m_current);
		m_ticks[m_current] = now;
		m_current = (m_current+1) % (_N+1);
		m_num++;
	}

	///Calculate fps of latest _N frames.
	float getFPS(){
		//don't report low fps if less than 10 seconds
		if( (GetTickCount()-m_startTick) < 10000 ) return above_threshold;

		if(m_num==0){
			return above_threshold;
		}else if(m_num<_N+1){
			DWORD diff = m_ticks[m_current-1]-m_ticks[0];
			if(diff<=0) diff = 1;
			float fps = float((m_num-1)*1000.0 /diff);
			return (fps<=threshold) ? above_threshold : fps;
		}else{
			size_t last = (m_current+_N) % (_N+1);
			//Logger::info(L"last=%d, m_current=%d", last, m_current);
			//f << m_num << ": " << m_ticks[last] << ", " << m_ticks[m_current] << endl;
			DWORD diff = m_ticks[last]-m_ticks[m_current];
			if(diff<=0) diff = 1;
			float fps =  float(_N*1000.0 /diff);

			//return low fps no more than 1 time every 1 second.
			if(fps<=threshold){
				DWORD now = GetTickCount();
				if(now-m_lastLowFpsTick > 1000){
					m_lastLowFpsTick = now;
				}else{
					fps = above_threshold;
				}
			}
			//if(fps>100) DebugBreak();
			return fps;
		}
	}

	const bool isLowFPS(float fps){
		return fps<=threshold;
	}

private:
	const float threshold;
	const float above_threshold;
	DWORD m_ticks[_N+1];
	size_t m_current;
	size_t m_num;
	DWORD m_lastLowFpsTick;
	DWORD m_startTick;
};

///@}
