#ifndef _MOBINEX_UTIL_DATE_TIME_DATE_FORMAT_H
#define _MOBINEX_UTIL_DATE_TIME_DATE_FORMAT_H

#include "dateformat.h"

namespace mobinex
{
	namespace util
	{
		/**
		Formats a date in the format <b>\%d-\%m-\%Y \%H:\%M:\%S,\%Q</b> for example,
	   "06 Nov 1994 15:49:37,459".
		*/
		class MOBINEX_UTIL_EXPORT DateTimeDateFormat : public DateFormat
		{
		public:
			DateTimeDateFormat(const TimeZonePtr& timeZone)
			 : DateFormat(_T("%d %b %Y %H:%M:%S,%Q"), timeZone) {}
		};
	}  // namespace util
}; // namespace mobinex

#endif // _MOBINEX_UTIL_DATE_TIME_DATE_FORMAT_H
