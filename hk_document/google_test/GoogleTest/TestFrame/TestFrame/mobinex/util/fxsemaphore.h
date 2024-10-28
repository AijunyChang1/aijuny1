/** 
 * @file fxsemaphore.h
 * @brief defined standard Semaphore class
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */
#ifndef _MOBINEX_UTIL_SEMAPHORE_H
#define _MOBINEX_UTIL_SEMAPHORE_H

#include "fxconfig.h"
#include "mobinex/util/fxexception.h"

#ifdef HAVE_PTHREAD
#include <semaphore.h>
#endif

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT SemaphoreException : public CFXException
		{
		};

#ifdef HAVE_MS_THREAD
		class Condition;
#endif

		class MOBINEX_UTIL_EXPORT Semaphore
		{
#ifdef HAVE_MS_THREAD
		friend class Condition;
#endif
		public:
			Semaphore(int value = 0);
			~Semaphore();
			void wait();
			bool tryWait();
			void post();

		protected:
#ifdef HAVE_PTHREAD
			sem_t semaphore;
#elif defined (HAVE_MS_THREAD)
			void * semaphore;
#endif
		};
	}  // namespace util
}; // namespace mobinex

#endif //_MOBINEX_UTIL_SEMAPHORE_H
