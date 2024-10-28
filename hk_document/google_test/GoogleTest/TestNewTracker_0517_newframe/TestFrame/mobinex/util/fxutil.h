// StringHelper.h: interface for the StringHelper class.
//
//////////////////////////////////////////////////////////////////////
#ifndef _MOBINEX_UTIL_H
#define _MOBINEX_UTIL_H
 
#include "mobinex/util/fxtchar.h"
#include "mobinex/util/fxexception.h"
#include <stdarg.h>
#include "mobinex/util/fxobjectimpl.h"
#include "mobinex/util/fxobjectptr.h"
#include <map>

namespace mobinex
{
    namespace util
    {
		/** 
		String manipulation routines
		*/
		class MOBINEX_UTIL_EXPORT StringHelper
		{
		   public:
			static String toUpperCase(const String& s);
			static String toLowerCase(const String& s);
			static String trim(const String& s);
			static bool equalsIgnoreCase(const String& s1, const String& s2);
  			static bool endsWith(const String& s, const String& suffix);
			/** 
			Creates a message with the given pattern and uses it to format the
			given arguments.
			
			This method provides a means to produce concatenated messages in
			language-neutral way.
			
			@param pattern the pattern for this message. The different arguments
			are represented in the pattern string by the symbols {0} to {9}
			
			@param argList a variable list of srrings to be formatted and
			substituted. The type of the strings must be (TCHAR *).
			*/
			static String format(const String& pattern, va_list argList);
		};

		class MOBINEX_UTIL_EXPORT NoSuchElementException : public CFXException
		{
		};

		class MOBINEX_UTIL_EXPORT StringTokenizer
		{
		public:
			StringTokenizer(const String& str, const String& delim);
			~StringTokenizer();
			bool hasMoreTokens() const;
			String nextToken();

		protected:
			TCHAR * str;
			String delim;
			TCHAR * token;
			TCHAR * state;
		}; // class StringTokenizer
	}
}
#endif //_MOBINEX_UTIL_H