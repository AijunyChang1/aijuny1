#ifndef _MOBINEX_UITL_DATE_FORMAT_H
#define _MOBINEX_UITL_DATE_FORMAT_H

#include "mobinex/util/fxtchar.h"
#include "mobinex/util/fxtimezone.h"

namespace mobinex
{
	namespace util
	{
		/** 
		Concrete class for formatting and parsing dates in a 
		locale-sensitive manner.
		*/
		class MOBINEX_UTIL_EXPORT DateFormat
		{
		public:
			DateFormat(const String& dateFormat);
			DateFormat(const String& dateFormat, const TimeZonePtr& timeZone);
			virtual void format(ostream& os, int64_t time) const;
			String format(int64_t timeMillis) const;

		protected:
			TimeZonePtr timeZone;
			String dateFormat;
		};
	}  // namespace util
}; // namespace mobinex

#endif //_MOBINEX_UITL_DATE_FORMAT_H
