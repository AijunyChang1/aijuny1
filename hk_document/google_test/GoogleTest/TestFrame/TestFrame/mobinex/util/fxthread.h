/** 
 * @file fxthread.h
 * @brief defined standard Thread, Runable class, Interface
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */

#ifndef _MOBINEX_UTIL_THREAD_H
#define _MOBINEX_UTIL_THREAD_H

#include "fxconfig.h"
#include "mobinex/util/fxobject.h"
#include "mobinex/util/fxobjectptr.h"
#include "mobinex/util/fxobjectimpl.h"
#include "mobinex/util/fxexception.h"
#include "mobinex/util/fxmdc.h"

// Windows specific :
// winspool.h defines MIN_PRIORITY and MAX_PRIORITY
#ifdef MIN_PRIORITY
#define OLD_MIN_PRIORITY MIN_PRIORITY
#undef MIN_PRIORITY
#endif

#ifdef MAX_PRIORITY
#define OLD_MAX_PRIORITY MAX_PRIORITY
#undef MAX_PRIORITY
#endif

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT ThreadException : public CFXException
		{
		public:
			ThreadException() {}
			ThreadException(const String& message)
			 : CFXException(message) {}

		};

		class MOBINEX_UTIL_EXPORT InterruptedException : public CFXException
		{
			public:
				InterruptedException() {}
				InterruptedException(const String& message)
				 : CFXException(message) {}
		};
		
		/** The Runnable interface should be implemented by any class whose 
		instances are intended to be executed by a thread. 
		The class must define a method of no arguments called run.
		*/
		class MOBINEX_UTIL_EXPORT Runnable : public virtual Object
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(Runnable)

			/** When an object implementing interface Runnable is used to
			create a thread, starting the thread causes the object's run 
			method to be called in that separately executing thread.
			*/
			virtual void run() = 0;
		};

		typedef ObjectPtrT<Runnable> RunnablePtr;
		
		/** A thread is a thread of execution in a program.
		*/
		class MOBINEX_UTIL_EXPORT Thread : public virtual ObjectImpl
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(Thread)

			BEGIN_MOBINEX_CAST_MAP()
				MOBINEX_CAST_ENTRY(Thread)
			END_MOBINEX_CAST_MAP()

			/**  Allocates a new Thread object.*/
			Thread();
			
			/**  Allocates a new Thread object.*/
			Thread(RunnablePtr runnable);
			
			virtual ~Thread();

			/** Returns the current thread identifier
			*/
			static unsigned long getCurrentThreadId();

			/** Causes the currently executing thread to sleep (temporarily
			cease execution) for the specified number of milliseconds.
			*/
			static void sleep(long millis);

			/** Causes this thread to begin execution;
			calls the run method of this thread.
			*/
			void start();

			/**  If this thread was constructed using a separate Runnable
			run object, then that Runnable object's run method is called;
			otherwise, this method does nothing and returns.
			*/
			virtual void run();

			/** Waits for this thread to die.
			*/
			void join();

			/** release thread when not need */
			void release();

			/** Check a running thread */
			virtual bool isRunning();

			enum
			{
				MIN_PRIORITY = 1,
				NORM_PRIORITY = 2,
				MAX_PRIORITY = 3 
			};

			/** Changes the priority of this thread.
			*/
			void setPriority(int newPriority);

			/**
			Atomic increment
			*/
			static long InterlockedIncrement(volatile long * val);

			/**
			Atomic decrement
			*/
			static long InterlockedDecrement(volatile long * val);
		
		protected:
			/** Thread descriptor */
#ifdef HAVE_PTHREAD
			pthread_t thread;
#elif defined(HAVE_MS_THREAD)
			void * thread;
#endif
			RunnablePtr runnable;
			MDC::Map parentMDCMap;
		};
		
		typedef ObjectPtrT<Thread> ThreadPtr;
	
	}  // namespace util
}; //namespace mobinex

#endif // _MOBINEX_UTIL_THREAD_H
