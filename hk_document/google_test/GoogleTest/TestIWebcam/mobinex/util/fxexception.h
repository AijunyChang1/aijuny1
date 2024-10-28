/** 
 * @file exception.h
 * @brief defined standard exception class
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */
#ifndef _MOBINEX_UTIL_EXCEPTION_H
#define _MOBINEX_UTIL_EXCEPTION_H
#include <exception>
#include "mobinex/util/fxtchar.h"

namespace mobinex {

	namespace util {
		/** The class CFXException and its subclasses indicate conditions that a
		reasonable application might want to catch.
		*/
		class MOBINEX_UTIL_EXPORT CFXException : public std::exception
		{
		public:
			CFXException() {}
			CFXException(const String& message): message(message) {}
			inline const String& getMessage() { return message; }	
		protected:
			String message;
		};// class CFXException

		/** RuntimeException is the parent class of those exceptions that can be
		thrown during the normal operation of the process.
		*/
		class MOBINEX_UTIL_EXPORT RuntimeException : public CFXException
		{
		public:
			RuntimeException() {}
			RuntimeException(const String& message)
			 : CFXException(message) {}
		}; // class RuntimeException

		/** Thrown when an application attempts to use null in a case where an
		object is required.
		*/
		class MOBINEX_UTIL_EXPORT NullPointerException : public RuntimeException
		{
		public:
			NullPointerException() {}
			NullPointerException(const String& message)
			 : RuntimeException(message) {}
		}; // class NullPointerException

		/** Thrown to indicate that a method has been passed 
		an illegal or inappropriate argument.*/
		class MOBINEX_UTIL_EXPORT IllegalArgumentException : public RuntimeException
		{
		public:
			IllegalArgumentException(const String& message)
			 : RuntimeException(message) {}
		}; // class IllegalArgumentException
		
		/** Signals that an I/O exception of some sort has occurred. This class
		is the general class of exceptions produced by failed or interrupted
		I/O operations.
		*/
		class MOBINEX_UTIL_EXPORT IOException : public CFXException
		{
		public:
			IOException() {}
			IOException(const String& message)
			 : CFXException(message) {}
		};//class IOException
	} //name space util
} //name space mobinex

#endif //_MOBINEX_UTIL_EXCEPTION_H