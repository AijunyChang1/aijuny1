/** 
 * @file fxobjectimpl.h
 * @brief defined standard object, FXList, FXObject
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */

#ifndef _MOBINEX_UTIL_OBJECT_IMPL_H
#define _MOBINEX_UTIL_OBJECT_IMPL_H

#include "fxobject.h"
#include "fxcriticalsection.h"
#include <vector>
namespace mobinex
{
	namespace util
	{
		/** Implementation class for Object.*/
		class MOBINEX_UTIL_EXPORT ObjectImpl : public virtual Object
		{
		public:
			ObjectImpl();
			virtual ~ObjectImpl();
			void addRef() const;
			void releaseRef() const;
			virtual void lock() const;
			virtual void unlock() const;
			virtual void wait() const;
			virtual void notify() const;
			virtual void notifyAll() const;

		protected:
			mutable long volatile ref;
			mutable CriticalSection cs;
			mutable void * eventList;
		}; // class ObjectImpl
		
		/** FXObject*/
		class FXObject;
		typedef ObjectPtrT<FXObject> FXObjectPtr;

		class MOBINEX_UTIL_EXPORT FXObject: public virtual ObjectImpl
		{
		public:
			DECLARE_MOBINEX_OBJECT(FXObject)
				BEGIN_MOBINEX_CAST_MAP()
				MOBINEX_CAST_ENTRY(FXObject)
			END_MOBINEX_CAST_MAP()

			FXObject();
			virtual ~FXObject();
			void SetKey(const String& key);
			String GetKey();
		protected:
			/* The key that is used for sort fxobject list or search a fxobject*/
			String m_sKey;
		}; // class FXObject

		class MOBINEX_UTIL_EXPORT ObjectNotFoundException : public RuntimeException
		{
		public:
			ObjectNotFoundException(const String& message)
			 : RuntimeException(message) {}
		}; // class ObjectNotFoundException
		
	 /** FXList*/
	  template <class T> 
	  class MOBINEX_UTIL_EXPORT FXList
	  {
	  public:
		   FXList(){}
		   virtual ~FXList(){ RemoveAll();}

		   /*Add a Object to the list and sort in increase order*/
		   int Add(T aFXObject, int position = -1){
				if(&aFXObject== NULL) return -1;

				if(position > -1){
				 m_lsFxList.insert(m_lsFxList.begin() + position, aFXObject);
				 return position;
				}

				m_lsFxList.push_back(aFXObject);
				return m_lsFxList.size() - 1;   
		   }

		   /*Get a Object with a position*/
		   T Get(int position){
				return m_lsFxList.at(position); 
		   }
		   /*Remove a Object with a position*/
		   void Remove(int position){
				m_lsFxList.erase(m_lsFxList.begin() + position);
		   }
		   /*Clear all item of the list*/
		   void RemoveAll(){
			m_lsFxList.clear();
		   }
		   /*Get size of FXList*/
		   int GetSize(){return m_lsFxList.size();}

		   /*Set type for the list*/
		   void SetType(int iType){m_iType = iType;}
			/*Get type of the list*/
		   int GetType(){return m_iType;}
		   /*Set key for the list*/
		   void SetKey(const String& sKey){m_sKey = sKey;}
		   /*Get key for the list*/
		   String GetKey(){return m_sKey;}
	  private:
		   /*List object*/
		   std::vector<T> m_lsFxList;
		   /*type of the list*/
		   int m_iType;
		   /*key of the list*/
		   String m_sKey;
	  };

	  template <> 
	  class MOBINEX_UTIL_EXPORT FXList <FXObjectPtr>
	  {
	  public:
		  FXList(): m_pFXObject(0),m_iCurrentPos(0), m_bSorted (true){
		  };
		  virtual ~FXList(){
			  RemoveAll();
		  };
		   /*Add a Object to the list and sort in increase order*/
		   int Add(FXObjectPtr aFXObject, int position = -1)
		   {

			   if(aFXObject==0) return -1;

			   if(m_lsFxList.size() ==0){
				   m_bSorted = true;
				   m_lsFxList.push_back(aFXObject);
				   return m_lsFxList.size() - 1;
			   }

			   if(position > -1){
				   if(aFXObject->GetKey() != L"" && GetWithKey(aFXObject->GetKey())) return position;
				   m_bSorted = false;
				   FXObjectPtr aTmpObj = 0;
				   if(position >= m_lsFxList.size()){
					   position = 	m_lsFxList.size();
					   aTmpObj = m_lsFxList.at(position - 1);
					   if(aTmpObj && aTmpObj->GetKey() > aFXObject->GetKey())
						   m_bSorted = true;
					   m_lsFxList.insert(m_lsFxList.begin() + position, aFXObject);

				   }else{
					   if(position == 0){
						   aTmpObj = m_lsFxList.at(position);
						   if(aTmpObj && aTmpObj->GetKey() < aFXObject->GetKey())
							   m_bSorted = true;
					   }else{
						   aTmpObj = m_lsFxList.at(position - 1);
						   if(aTmpObj && aTmpObj->GetKey() > aFXObject->GetKey())
							   m_bSorted = true;
						   if(m_bSorted){
							   aTmpObj = m_lsFxList.at(position);
							   if(aTmpObj && aTmpObj->GetKey() > aFXObject->GetKey())
								   m_bSorted = false;
						   }
					   }
					   m_lsFxList.insert(m_lsFxList.begin() + position, aFXObject);
				   }
				   return position;
			   }

			   FXObjectPtr theFXObject = m_lsFxList.at(0);
			   if(aFXObject->GetKey()!= L"" && aFXObject->GetKey() == theFXObject->GetKey()){
				   theFXObject = 0;
				   m_iCurrentPos = 0;
				   return m_iCurrentPos;
			   }

			   // Phuc - May 29 2008
			   //if(aFXObject->GetKey() < theFXObject->GetKey() || aFXObject->GetKey() == L""){
			   if(aFXObject->GetKey() > theFXObject->GetKey() || aFXObject->GetKey() == L""){
				   m_lsFxList.insert(m_lsFxList.begin(), aFXObject);
				   theFXObject = 0;
				   m_iCurrentPos = 0;
				   return m_iCurrentPos;
			   }

			   theFXObject = m_lsFxList.at(m_lsFxList.size() - 1);
			   if(aFXObject->GetKey() == theFXObject->GetKey()){
				   theFXObject = 0;
				   return m_lsFxList.size() - 1;
			   }

			   // Phuc - May 29 2008
			   //if(aFXObject->GetKey() > theFXObject->GetKey()){
			   if(aFXObject->GetKey() < theFXObject->GetKey()){
				   m_lsFxList.push_back(aFXObject);
				   theFXObject = 0;
				   return m_lsFxList.size() - 1;
			   }

			   PartitionSort(0, m_lsFxList.size() - 1, aFXObject);
			   return m_iCurrentPos;
		   }
		   /*Get a Object with a position*/
		   FXObjectPtr Get(int position){
			   if(position < 0 || position >= m_lsFxList.size() ) return 0;
			   return m_lsFxList.at(position);
		   };
		   /** 
		    * James:
		    * Set a Object to the list but not sort in increase order
		    */
		   int Set(FXObjectPtr aFXObject, int position){
			   FXObjectPtr aTmpObj = 0;
			   if (position >= 0 && position < m_lsFxList.size())
			   {
				   m_lsFxList.erase(m_lsFxList.begin() + position);
				   m_lsFxList.insert(m_lsFxList.begin() + position, aFXObject);
				   m_bSorted = false;
				   return position;
			   }
			   return -1;
		   };
		   /*Get a Object with a key*/
		   FXObjectPtr GetWithKey(const String& objKey){	
			   String sObjKey = objKey;
			   std::transform(sObjKey.begin(), sObjKey.end(), sObjKey.begin(),tolower);
			   m_pFXObject = 0;

			   // Phuc - May 29 2008
			   if(m_bSorted)
				   PartitionSearch(0, m_lsFxList.size() - 1, sObjKey);

			   if(!m_pFXObject){
				   for(int i=0; i < m_lsFxList.size(); i++){
					   m_pFXObject = m_lsFxList.at(i);
					   if(m_pFXObject->GetKey() == sObjKey) return m_pFXObject;
					   m_pFXObject = 0;
				   }
			   }

			   return m_pFXObject;
		   };
		    /*Erase a Object with a key and no the object*/	
		   FXObjectPtr EraseWithKey(const String& objKey){
			   String sObjKey = objKey;
			   std::transform(sObjKey.begin(), sObjKey.end(), sObjKey.begin(),tolower);
			   m_iCurrentPos = -1;
			   if(m_bSorted)
				   PartitionSearch(0, m_lsFxList.size()-1, sObjKey);

			   if(m_iCurrentPos < 0)
			   {
				   for(int i=0; i < m_lsFxList.size(); i++){
					   m_pFXObject = m_lsFxList.at(i);
					   if(m_pFXObject->GetKey() == sObjKey){
						   m_iCurrentPos = i;
						   break;
					   }
				   }	

				   if(m_iCurrentPos < 0){
					   m_pFXObject = 0;
				   }
			   }

			   FXObjectPtr aObjectPtr = 0;
			   if(m_iCurrentPos > -1) {
				   aObjectPtr = m_lsFxList.at(m_iCurrentPos);
				   m_lsFxList.erase(m_lsFxList.begin() + m_iCurrentPos);
			   }
			   return aObjectPtr;
		   };
		   /*Remove a Object with a key and delete the object*/
		   int RemoveWithKey(const String& objKey){
			   String sObjKey = objKey;
			   std::transform(sObjKey.begin(), sObjKey.end(), sObjKey.begin(),tolower);
			   m_iCurrentPos = -1;
			   if(m_bSorted)
				   PartitionSearch(0, m_lsFxList.size()-1, sObjKey);

			   if(m_iCurrentPos < 0){
				   for(int i=0; i < m_lsFxList.size(); i++){
					   m_pFXObject = m_lsFxList.at(i);
					   if(m_pFXObject->GetKey() == sObjKey){
						   m_iCurrentPos = i;
						   break;
					   }
				   }	

				   if(m_iCurrentPos < 0)
					   return -1;
			   }

			   FXObjectPtr aObjectPtr = m_lsFxList.at(m_iCurrentPos);
			   if(aObjectPtr) aObjectPtr = 0;
			   m_lsFxList.erase(m_lsFxList.begin() + m_iCurrentPos);		
			   return m_iCurrentPos;
		   };
		   /*Remove a Object with a position and delete the object*/
			void Remove(int position){
				if(position < 0) return;
				FXObjectPtr aObjectPtr = m_lsFxList.at(position);
				if(aObjectPtr) aObjectPtr = 0;
				m_lsFxList.erase(m_lsFxList.begin() + position);	
			};
		   /*Remove a object with a postion but no delete the object*/
			FXObjectPtr Erase(int position){
				if(position < 0) return NULL;
				FXObjectPtr aObjectPtr = m_lsFxList.at(position);
				m_lsFxList.erase(m_lsFxList.begin() + position);
				return aObjectPtr;
			};
		   /*Clear all item of the list*/
			void RemoveAll(){
				for(int i=0; i < m_lsFxList.size(); i ++){
					FXObjectPtr aObjectPtr = m_lsFxList.at(i);
					if(aObjectPtr) 
					{
							aObjectPtr = 0;
					}
				}
				m_lsFxList.clear();
			};
		   /*Get size of FXList*/
			int GetSize(){
				return m_lsFxList.size();
			}
;
		   /*Set type for the list*/
		   void SetType(int iType){m_iType = iType;}
			/*Get type of the list*/
		   int GetType(){return m_iType;}
		   /*Set key for the list*/
		   void SetKey(const String sKey){m_sKey = sKey;}
		   /*Get key for the list*/
		   String GetKey(){return m_sKey;}
	  private:
		   /*Add with quick sort algorithm to make sortable list in increase order by key*/
		  void PartitionSort(int low_pos, int high_pos, FXObjectPtr aValue){
			  	int pivot_pos = (low_pos + high_pos) / 2;
			  
			  	FXObjectPtr pivot_obj = m_lsFxList.at(pivot_pos);
			  	if(pivot_obj->GetKey() == aValue->GetKey())
			  	{
			  		pivot_obj = 0;
			  		m_iCurrentPos = pivot_pos ;
			  		return;
			  	}
			  
			  	if(pivot_pos == low_pos){
			  			m_iCurrentPos = low_pos + 1;
			  			m_lsFxList.insert(m_lsFxList.begin() + m_iCurrentPos, aValue);
			  		return;
			  	} 
			  
			  	// Phuc - May 29 2008
			  	//if(pivot_obj->GetKey() > aValue->GetKey()){
			  	if(pivot_obj->GetKey() < aValue->GetKey()){
			  		PartitionSort(low_pos, pivot_pos, aValue);
			  	}else{
			  		PartitionSort(pivot_pos, high_pos, aValue);
			  	}
			  	pivot_obj =0;
			  };
		   /*Search a object with key by using quick sort algorithm with sortable list*/
		   void PartitionSearch(int low_pos, int high_pos, const String& akeyValue)
		   {
			   	m_pFXObject = 0;
			   	if(low_pos > high_pos){
			   		m_iCurrentPos = -1;
			   		m_pFXObject = 0;
			   		return;
			   	}
			   
			   	int pivot_pos = (low_pos + high_pos) / 2;
			   	// James: must check size
			   	if (m_lsFxList.size() <= 0) return;
			   	m_pFXObject = m_lsFxList.at(pivot_pos);
			   	m_iCurrentPos = pivot_pos;
			   	if(m_pFXObject->GetKey() == akeyValue) return;
			   	
			   	if(pivot_pos + 1 == high_pos){
			   		m_pFXObject = m_lsFxList.at(low_pos);
			   		m_iCurrentPos = low_pos;
			   		if(m_pFXObject->GetKey() == akeyValue) return;
			   		
			   		m_pFXObject = m_lsFxList.at(high_pos);
			   		m_iCurrentPos = high_pos;
			   		if(m_pFXObject->GetKey() == akeyValue) return;
			   
			   		//Else Object not found
			   		m_iCurrentPos = -1;
			   		m_pFXObject = 0;
			   		return;
			   	}
			   
			   	// Phuc - May 29 2008
			   	//if(m_pFXObject->GetKey() > akeyValue)
			   	if(m_pFXObject->GetKey() < akeyValue)
			   		PartitionSearch(0, pivot_pos - 1, akeyValue);
			   	else
			   		PartitionSearch(pivot_pos + 1, high_pos, akeyValue);
			   };
		   /*List object that is sorted in increase order*/
		   std::vector<FXObjectPtr> m_lsFxList;
		   /*Last Object that is got by using a key*/
		   FXObjectPtr m_pFXObject;
		   /*Last Object position that is got by using a key*/
		   int m_iCurrentPos;
		   /*type of the list*/
		   int m_iType;
		   /*key of the list*/
		   String m_sKey;
  		   /*Check list is sorted*/
		   bool m_bSorted; // Phuc - May 29 2008 

	  }; // class FXList

	  typedef FXList<FXObjectPtr> FXListEx;
	} 
} 

#endif //_MOBINEX_UTIL_OBJECT_IMPL_H
