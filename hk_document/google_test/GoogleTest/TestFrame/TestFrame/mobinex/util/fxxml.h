/** 
 * @file fxxml.h
 * @brief defined standard XML parser interface
 * @author : Tri Tran - tri.tran@fix8.com, James Duy Trinh (duy.trinh@fix8.com)
 * @version 1.0.0.0
 * @date    12 Otc 2007
 * @modified
 * - use MSXML2
 */
#ifndef _MOBINEX_UTIL_XML_H
#define _MOBINEX_UTIL_XML_H

#include "mobinex/util/fxtchar.h"
#include "mobinex/util/fxobjectptr.h"
#include "mobinex/util/fxobject.h"
#include "mobinex/util/fxexception.h"
//#import "msxml.dll"
#include "mobinex/util/msxml.tlh"
namespace mobinex
{
	namespace util
	{
		class XMLDOMNode;
		typedef ObjectPtrT<XMLDOMNode> XMLDOMNodePtr;

		class XMLDOMDocument;
		typedef ObjectPtrT<XMLDOMDocument> XMLDOMDocumentPtr;

		class XMLDOMElement;
		typedef ObjectPtrT<XMLDOMElement> XMLDOMElementPtr;

		class XMLDOMNodeList;
		typedef ObjectPtrT<XMLDOMNodeList> XMLDOMNodeListPtr;

		class  MOBINEX_UTIL_EXPORT DOMException : public RuntimeException
		{
		public:
			DOMException() {}
			DOMException(LPCTSTR message)
			 : RuntimeException(message) {}
		};

		/**
		The XMLDOMNode interface is the primary data type for the entire Document
		Object Model.
		*/
		class  MOBINEX_UTIL_EXPORT XMLDOMNode : virtual public Object
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(XMLDOMNode)
			
			enum XMLDOMNodeType
 			{
 				NOT_IMPLEMENTED_NODE = 0,
 				ELEMENT_NODE = 1,
 				DOCUMENT_NODE = 9
 			};

			virtual MSXML2::DOMNodeType	getNodeType() = 0;

			virtual LPCTSTR				getName() = 0;
			virtual LPCTSTR				getText() = 0;
			virtual bool				setText(LPCTSTR val) = 0;
			virtual bool				setText(String val) = 0;

			virtual XMLDOMNodeListPtr	getChildNodes() = 0;
			virtual XMLDOMDocumentPtr	getOwnerDocument() = 0;
		};

		/**
		The XMLDOMDocument interface represents an entire XML document.
		
		Conceptually, it is the root of the document tree, and provides the
		primary access to the document's data.
		*/
		class  MOBINEX_UTIL_EXPORT XMLDOMDocument : virtual public XMLDOMNode
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(XMLDOMDocument)
			
			virtual void load(LPCTSTR fileName) = 0;
			virtual void save(LPCTSTR fileName) = 0;
			virtual void loadXML(LPCTSTR strXML) = 0;
			virtual LPCTSTR getXML() = 0;

			virtual XMLDOMElementPtr getDocumentElement() = 0;
			virtual XMLDOMElementPtr getElementById(LPCTSTR tagName,LPCTSTR elementId) = 0;
			virtual	XMLDOMElementPtr getElementByLang(LPCTSTR tagName, LPCTSTR elementLang) = 0;
			virtual XMLDOMNodeListPtr getElementByTagName(LPCTSTR tagName) = 0;

			virtual XMLDOMElementPtr selectSingleNode(LPCTSTR nodeXPath) = 0;
			virtual XMLDOMNodeListPtr selectNodes(LPCTSTR nodeXPath) = 0;
			virtual void setSelectionLanguage(LPCTSTR xmlLang) = 0;
			
			virtual XMLDOMElementPtr createRootElement(LPCTSTR tagName) = 0;
			virtual XMLDOMElementPtr createElement(LPCTSTR tagName) = 0;
			virtual XMLDOMNodePtr createNode(LPCTSTR tagName, MSXML2::DOMNodeType nodeType = NODE_TEXT) = 0;
		};

		/** 
		The XMLDOMElement interface represents an element in an XML document
		*/
		class  MOBINEX_UTIL_EXPORT XMLDOMElement : virtual public XMLDOMNode
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(XMLDOMElement)
			
			virtual MSXML2::IXMLDOMElementPtr getOwnElement() = 0;
			
			virtual XMLDOMNodeListPtr getChildNodes() = 0;
			virtual void	addChildNode(XMLDOMElementPtr aEmlementPtr) = 0;
			virtual void	removeChildNode(XMLDOMElementPtr aEmlementPtr) = 0;
			
			virtual LPCTSTR	getTagName() = 0;
			
			virtual LPCTSTR	getAttribute(LPCTSTR name) = 0;
			virtual void	setAttribute(LPCTSTR name, const _variant_t val) = 0;
			virtual int		getAttributeNum() = 0;
			virtual LPCTSTR	getAttributeItemName(const int nAtt) = 0;
			virtual LPCTSTR	getAttributeItemValue(const int nAtt) = 0;
		};

		/**
		The XMLDOMNodeList interface provides the abstraction of an ordered
		collection of nodes, without defining or constraining how this
		collection is implemented. 
		
		XMLDOMNodeList objects in the DOM are live.

		The items in the XMLDOMNodeList are accessible via an integral index,
		starting from 0. 
		*/
		class  MOBINEX_UTIL_EXPORT XMLDOMNodeList : virtual public Object
		{
		public:
			DECLARE_ABSTRACT_MOBINEX_OBJECT(XMLDOMNodeList)
			virtual int getLength() = 0;
			virtual XMLDOMNodePtr item(int index) = 0;
			virtual XMLDOMElementPtr nextElement() = 0;
		};
	}  // namespace util
}; // namespace mobinex

#endif // _MOBINEX_UTIL_XML_H

