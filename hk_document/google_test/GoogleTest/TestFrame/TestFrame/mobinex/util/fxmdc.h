#ifndef _MOBINEX_UTIL_MDC_H
#define _MOBINEX_UTIL_MDC_H

#include "mobinex/util/fxtchar.h"
#include "mobinex/util/fxthreadspecificdata.h"
#include <map>

namespace mobinex
{
	namespace util{

	class MOBINEX_UTIL_EXPORT MDC
	{
	public:
		/** String to string stl mp
		*/
		typedef std::map<String, String> Map;

	private:
		static Map * getCurrentThreadMap();
		static void setCurrentThreadMap(Map * map);

		static ThreadSpecificData threadSpecificData;
		const String& key;

	public:
		MDC(const String& key, const String& value);
		~MDC();

		/**
		* Put a context value (the <code>o</code> parameter) as identified
		* with the <code>key</code> parameter into the current thread's
		* context map.
		*
		* <p>If the current thread does not have a context map it is
		* created as a side effect.
		* */
  		static void put(const String& key, const String& value);

		/**
		* Get the context identified by the <code>key</code> parameter.
		*
		*  <p>This method has no side effects.
		* */
		static String get(const String& key);

		/**
		* Remove the the context identified by the <code>key</code>
		* parameter. */
		static String remove(const String& key);

		/**
		* Clear all entries in the MDC.
		*/
		static void clear();

		/**
		* Get the current thread's MDC as a Map. This method is
		* intended to be used internally.
		* */
		static const Map getContext();
		
		static void setContext(Map& map);
	}; // class MDC;
}  // namespace util
} //namespace mobinex

#endif // _MOBINEX_UTIL_MDC_H
