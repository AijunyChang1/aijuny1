/** 
 * @file fxobjectptr.h
 * @brief defined standard pointer object class
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */

#ifndef _MOBINEX_UTIL_OBJECT_PTR_H
#define _MOBINEX_UTIL_OBJECT_PTR_H

#include "mobinex/util/fxexception.h"

namespace mobinex
{
    namespace util
    {
		/** smart pointer to a Object descendant */
        template<typename T> class ObjectPtrT
        {
        public:
 			template<typename InterfacePtr> ObjectPtrT(const InterfacePtr& p)
				: p(0)
			{
				cast(p);
			}

			// Disable conversion using ObjectPtrT* specialization of
			// template<typename InterfacePtr> ObjectPtrT(const InterfacePtr& p)
			/* template<> explicit ObjectPtrT(ObjectPtrT* const & p) throw(IllegalArgumentException)
			{
				if (p == 0)
				{
					throw IllegalArgumentException(String());
				}
				else
				{
					this->p = p->p;
                    this->p->addRef();
				}
			}*/

			ObjectPtrT(const int& null) //throw(IllegalArgumentException)
				: p(0)
			{
				if (null != 0)
				{

					throw IllegalArgumentException(String());
				}
			}

			ObjectPtrT() : p(0)
			{
			}

			ObjectPtrT(T * p) : p(p)
            {
                if (this->p != 0)
                {
                    this->p->addRef();
                }
            }

            ObjectPtrT(const ObjectPtrT& p) : p(p.p)
            {
                if (this->p != 0)
                {
                    this->p->addRef();
                }
            }

            ~ObjectPtrT()
            {
                if (this->p != 0)
                {
                    this->p->releaseRef();
                }
            }

            // Operators
			template<typename InterfacePtr> ObjectPtrT& operator=(const InterfacePtr& p)
			{
				cast(p);
				return *this;
			}

			ObjectPtrT& operator=(const ObjectPtrT& p)
            {
                if (this->p != p.p)
                {
                    if (this->p != 0)
                    {
                        this->p->releaseRef();
                    }

                    this->p = p.p;

                    if (this->p != 0)
                    {
                        this->p->addRef();
                    }
                }

				return *this;
            }

			ObjectPtrT& operator=(const int& null) //throw(IllegalArgumentException)
			{
				if (null != 0)
				{
					throw IllegalArgumentException(String());
				}

				if (this->p != 0)
                {
                    this->p->releaseRef();
					this->p = 0;
                }

				return *this;
			}

            ObjectPtrT& operator=(T* p)
            {
                if (this->p != p)
                {
                    if (this->p != 0)
                    {
                        this->p->releaseRef();
                    }

                    this->p = p;

                    if (this->p != 0)
                    {
                        this->p->addRef();
                    }
                }

				return *this;
            }

            bool operator==(const ObjectPtrT& p) const { return (this->p == p.p); }
            bool operator!=(const ObjectPtrT& p) const { return (this->p != p.p); }
            bool operator==(const T* p) const { return (this->p == p); }
            bool operator!=(const T* p) const { return (this->p != p); }
            T* operator->() {return p; }
            const T* operator->() const {return p; }
            T& operator*() const {return *p; }
            operator T*() const {return p; }

			template<typename InterfacePtr> void cast(const InterfacePtr& p)
			{
				if (this->p != 0)
                {
                    this->p->releaseRef();
					this->p = 0;
                }

				if (p != 0)
				{
					this->p = (T*)p->cast(T::getStaticClass());
					if (this->p != 0)
					{
						this->p->addRef();
					}
				}
			}


        public:
            T * p;
        };
    } 
} 

#endif //_MOBINEX_UTIL_OBJECT_PTR_H
