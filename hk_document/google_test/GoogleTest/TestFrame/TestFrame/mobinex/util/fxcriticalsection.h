/** 
 * @file fxcriticalsection.h
 * @brief defined standard Criticalsection class
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */
#ifndef _MOBINEX_UTIL_CRITICAL_SECTION_H
#define _MOBINEX_UTIL_CRITICAL_SECTION_H

#include "fxconfig.h"

#ifdef HAVE_PTHREAD
#include <pthread.h>
#elif defined(HAVE_MS_THREAD)
#include <windows.h>
#endif

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT CriticalSection
		{
		public:
			CriticalSection();
			~CriticalSection();
			void lock();
			void unlock();
			unsigned long getOwningThread();

#ifdef HAVE_PTHREAD
			pthread_mutex_t mutex;
#elif defined(HAVE_MS_THREAD)
			CRITICAL_SECTION mutex;
#endif						
			unsigned long owningThread;
		};

		/** CriticalSection helper class to be used on call stack
		*/
		class WaitAccess
		{
		public:
			/// lock a critical section
			WaitAccess(CriticalSection& cs) : cs(cs)
			{
				cs.lock();
				locked = true;
			}

			/** automatically unlock the critical section
			if unlock has not be called.
			*/
			~WaitAccess()
			{
				if (locked)
				{
					unlock();
				}
			}

			/// unlock the critical section
			void unlock()
			{
				cs.unlock();
				locked = false;
			}

		private:
			/// the CriticalSection to be automatically unlocked
			CriticalSection& cs;
			/// verify the CriticalSection state
			bool locked;
		};
	}  // namespace util
}; // namespace mobinex

#endif //_MOBINEX_UTIL_CRITICAL_SECTION_H
