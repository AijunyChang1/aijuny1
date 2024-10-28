#ifndef _MOBINEX_UTIL_ABSOLUTE_TIME_DATE_FORMAT_H
#define _MOBINEX_UTIL_ABSOLUTE_TIME_DATE_FORMAT_H

#include "mobinex/util/fxdateformat.h"

namespace mobinex
{
	namespace util
	{
		/**
		Formats a date in the format <b>%H:%M:%S,%Q</b> for example,
		"15:49:37,459".
		*/
		class MOBINEX_UTIL_EXPORT AbsoluteTimeDateFormat : public DateFormat
		{
		public:
			/**
			string constant used to specify
			ISO8601DateFormat in layouts. Current
			value is <b>ISO8601</b>.
			*/
			static String ISO8601_DATE_FORMAT;

			/**
			String constant used to specify
			AbsoluteTimeDateFormat in layouts. Current
			value is <b>ABSOLUTE</b>.  */
			static String ABS_TIME_DATE_FORMAT;

			/**
			String constant used to specify
			DateTimeDateFormat in layouts.  Current
			value is <b>DATE</b>.
			*/
			static String DATE_AND_TIME_DATE_FORMAT;

			AbsoluteTimeDateFormat(const TimeZonePtr& timeZone)
			: DateFormat(_T("%H:%M:%S,%Q"), timeZone) {}
		};
	}  // namespace util
}; // namespace mobinex

#endif // _MOBINEX_UTIL_ABSOLUTE_TIME_DATE_FORMAT_H
