#ifndef _MOBINEX_UTIL_THREAD_SPECIFIC_DATA_H
#define _MOBINEX_UTIL_THREAD_SPECIFIC_DATA_H

#include "fxconfig.h"

#ifdef HAVE_PTHREAD
#include <pthread.h>
#endif

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT ThreadSpecificData
		{
		public:
			ThreadSpecificData();
			~ThreadSpecificData();
			void * GetData() const;
			void SetData(void * data);

		protected:
#ifdef HAVE_PTHREAD
			pthread_key_t key;
#elif defined(HAVE_MS_THREAD)
			void * key;
#endif
		};
	}  // namespace util
}; // namespace mobinex

#endif
