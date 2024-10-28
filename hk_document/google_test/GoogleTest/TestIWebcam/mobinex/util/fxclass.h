
#ifndef _MOBINEX_UTIL_CLASS_H
#define _MOBINEX_UTIL_CLASS_H

#include "mobinex/util/fxtchar.h"
#include "mobinex/util/fxobjectptr.h"

namespace mobinex
{
	namespace util
	{
		class Object;
		typedef ObjectPtrT<Object> ObjectPtr;

		/**
		Thrown when an application tries to create an instance of a class using
		the newInstance method in class Class, but the specified class object
		cannot be instantiated because it is an interface or is an abstract class.
		*/
		class MOBINEX_UTIL_EXPORT InstantiationException : public CFXException
		{
		public:
			InstantiationException() : CFXException(_T("Abstract class")) {}
		};

		/**
		Thrown when an application tries to load in a class through its
		string name but no definition for the class with the specified name
		could be found.
		*/
		class MOBINEX_UTIL_EXPORT ClassNotFoundException : public CFXException
		{
		public:
			ClassNotFoundException(const String& className);
		};

		class MOBINEX_UTIL_EXPORT Class
		{
		public:
			Class(const String& name);
			virtual ObjectPtr newInstance() const;
			const String& toString() const;
			const String& getName() const;
			static const Class& forName(const String& className);

		protected:
			static void registerClass(const Class * newClass);
			String name;
		};
	}  // namespace util
}; // namespace mobinex

#endif //_MOBINEX_UTIL_CLASS_H
