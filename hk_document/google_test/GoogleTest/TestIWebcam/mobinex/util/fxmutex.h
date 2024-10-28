/** 
 * @file fxmutex.h
 * @brief defined standard Mutex class
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */

#ifndef _MOBINEX_UTIL_MUTEX_H
#define _MOBINEX_UTIL_MUTEX_H

#include "fxconfig.h"
#include "mobinex/util/fxexception.h"

#ifdef HAVE_PTHREAD
#include <pthread.h>
#endif

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT MutexException : public CFXException
		{
		};

		class Condition;//this is used for Pthread

		class MOBINEX_UTIL_EXPORT Mutex
		{
		friend class Condition;
		public:
			Mutex();
			~Mutex();
			void lock();
			void unlock();

		protected:
#ifdef HAVE_PTHREAD
			pthread_mutex_t mutex;
#elif defined(HAVE_MS_THREAD)
			void * mutex;
#endif
		};
	} // namespace util
};// namespace mobinex

#endif //_MOBINEX_UTIL_MUTEX_H
