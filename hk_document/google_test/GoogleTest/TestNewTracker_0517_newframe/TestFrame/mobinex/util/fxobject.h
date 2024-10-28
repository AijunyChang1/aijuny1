/*
 * Tri.Tran
 * tri.tran@fix8.com
 * 2007-10-12
 */
#ifndef _MOBINEX_UTIL_OBJECT_H
#define _MOBINEX_UTIL_OBJECT_H

#include "fxtchar.h"
#include "fxclass.h"
#include "fxobjectptr.h"

#define DECLARE_ABSTRACT_MOBINEX_OBJECT(object)\
public:\
class Class##object : public mobinex::util::Class\
{\
public:\
	Class##object() : mobinex::util::Class(_T(#object)) {}\
};\
virtual const mobinex::util::Class& getClass() const;\
static const mobinex::util::Class& getStaticClass();\
static Class##object theClass##object;

#define DECLARE_MOBINEX_OBJECT(object)\
public:\
class Class##object : public mobinex::util::Class\
{\
public:\
	Class##object() : mobinex::util::Class(_T(#object)) {}\
	virtual mobinex::util::ObjectPtr newInstance() const\
	{\
		return new object();\
	}\
};\
	virtual const mobinex::util::Class& getClass() const;\
static const mobinex::util::Class& getStaticClass();\
static Class##object theClass##object;

#define DECLARE_MOBINEX_OBJECT_WITH_CUSTOM_CLASS(object, class)\
public:\
virtual const mobinex::util::Class& getClass() const;\
static const mobinex::util::Class& getStaticClass();\
static class theClass##object;

#define IMPLEMENT_MOBINEX_OBJECT(object)\
object::Class##object object::theClass##object;\
const mobinex::util::Class& object::getClass() const { return theClass##object; }\
const mobinex::util::Class& object::getStaticClass() { return theClass##object; }

#define IMPLEMENT_MOBINEX_OBJECT_WITH_CUSTOM_CLASS(object, class)\
object::class object::theClass##object;\
const mobinex::util::Class& object::getClass() const { return theClass##object; }\
const mobinex::util::Class& object::getStaticClass() { return theClass##object; }

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT IllegalMonitorStateException : public CFXException
		{
		public:
			IllegalMonitorStateException(const String& message) : CFXException(message)
			{
			}
		};
		
		class Object;
		typedef ObjectPtrT<Object> ObjectPtr;

		/** base class for java-like objects.*/
		class MOBINEX_UTIL_EXPORT Object
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(Object)
			virtual ~Object() {}
			virtual void addRef() const = 0;
			virtual void releaseRef() const = 0;
			virtual void lock() const = 0;
			virtual void unlock() const = 0;
			virtual void wait() const = 0;
			virtual void notify() const = 0;
			virtual void notifyAll() const = 0;
			virtual bool instanceof(const Class& clazz) const = 0;
			virtual const void * cast(const Class& clazz) const = 0;
		};

		/** utility class for objects multi-thread synchronization.*/
		class synchronized
		{
		public:
			synchronized(const Object * object) : object(object)
				{ object->lock(); }

			~synchronized()
				{ object->unlock(); }

		protected:
			const Object * object;
		};
	} 
} 

#define BEGIN_MOBINEX_CAST_MAP()\
const void * cast(const mobinex::util::Class& clazz) const\
{\
	const void * object = 0;\
if (&clazz == &mobinex::util::Object::getStaticClass()) return (mobinex::util::Object *)this;

#define END_MOBINEX_CAST_MAP()\
	return object;\
}\
bool instanceof(const mobinex::util::Class& clazz) const\
{ return cast(clazz) != 0; }

#define MOBINEX_CAST_ENTRY(Interface)\
if (&clazz == &Interface::getStaticClass()) return (Interface *)this;

#define MOBINEX_CAST_ENTRY2(Interface, interface2)\
if (&clazz == &Interface::getStaticClass()) return (Interface *)(interface2 *)this;

#define MOBINEX_CAST_ENTRY_CHAIN(Interface)\
object = Interface::cast(clazz);\
if (object != 0) return object;

#endif //_MOBINEX_UTIL_OBJECT_H
