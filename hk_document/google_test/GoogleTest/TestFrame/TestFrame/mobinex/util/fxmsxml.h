/** 
 * @file fxmsxml.h
 * @brief defined standard MSXML parser class, interface
 * @author : Tri Tran - tri.tran@fix8.com
 * @version 1.0.0.0
 * @date    12 Otc 2007
 */

#ifndef _MOBINEX_UTIL_MSXML_H
#define _MOBINEX_UTIL_MSXML_H

#include "fxconfig.h"

#ifdef HAVE_MS_XML

#include "mobinex/util/fxxml.h"
#include "mobinex/util/fxobjectimpl.h"

namespace mobinex
{
	namespace util
	{
		class MOBINEX_UTIL_EXPORT MsXMLDOMNode : 
			virtual public XMLDOMNode,
			virtual public ObjectImpl
		{
			public:
				DECLARE_ABSTRACT_MOBINEX_OBJECT(MsXMLDOMNode)
				BEGIN_MOBINEX_CAST_MAP()
					MOBINEX_CAST_ENTRY(XMLDOMNode)
				END_MOBINEX_CAST_MAP()

				MsXMLDOMNode(MSXML2::IXMLDOMNodePtr node);

				virtual XMLDOMNodeListPtr getChildNodes();
				virtual MSXML2::DOMNodeType getNodeType();
				virtual LPCTSTR getName();

				virtual LPCTSTR	getText();
				virtual bool setText(LPCTSTR sText);
				virtual bool setText(String sText);

				virtual XMLDOMDocumentPtr getOwnerDocument();

			protected:
				MSXML2::IXMLDOMNodePtr node;
		};

		class MOBINEX_UTIL_EXPORT MsXMLDOMDocument : 
			virtual public XMLDOMDocument,
			virtual public ObjectImpl
		{
			public:
				DECLARE_ABSTRACT_MOBINEX_OBJECT(MsXMLDOMDocument)
				BEGIN_MOBINEX_CAST_MAP()
					MOBINEX_CAST_ENTRY(XMLDOMDocument)
					MOBINEX_CAST_ENTRY(XMLDOMNode)
				END_MOBINEX_CAST_MAP()

				MsXMLDOMDocument();
				MsXMLDOMDocument(MSXML2::IXMLDOMDocumentPtr document);
				~MsXMLDOMDocument();

				virtual MSXML2::DOMNodeType getNodeType();
				virtual LPCTSTR	getName();
				virtual LPCTSTR	getText();
				virtual bool setText(LPCTSTR sText);
				virtual bool setText(String sText);
				virtual XMLDOMDocumentPtr getOwnerDocument();

				virtual XMLDOMNodeListPtr getChildNodes();

				virtual void load(LPCTSTR fileName);
				virtual void save(LPCTSTR fileName);
				virtual void loadXML(LPCTSTR strXML);
				virtual LPCTSTR getXML();
				
				virtual XMLDOMElementPtr getDocumentElement();
				virtual XMLDOMElementPtr getElementById(LPCTSTR tagName,LPCTSTR elementId);
				virtual	XMLDOMElementPtr getElementByLang(LPCTSTR tagName, LPCTSTR elementLang);
				virtual XMLDOMNodeListPtr getElementByTagName(LPCTSTR tagName);
				
				virtual XMLDOMElementPtr selectSingleNode(LPCTSTR nodeXPath);
				virtual XMLDOMNodeListPtr selectNodes(LPCTSTR nodeXPath);
				virtual void setSelectionLanguage(LPCTSTR xmlLang);
				
				virtual XMLDOMElementPtr createRootElement(LPCTSTR tagName);
				virtual XMLDOMElementPtr createElement(LPCTSTR tagName);
				virtual XMLDOMNodePtr createNode(LPCTSTR tagName, MSXML2::DOMNodeType nodeType = NODE_TEXT);

			protected:
				MSXML2::IXMLDOMDocumentPtr document;
				bool mustCallCoUninitialize;
		};

		class MOBINEX_UTIL_EXPORT MsXMLDOMElement : 
			virtual public XMLDOMElement,
			virtual public ObjectImpl
		{
			public:
				DECLARE_ABSTRACT_MOBINEX_OBJECT(MsXMLDOMElement)
				BEGIN_MOBINEX_CAST_MAP()
					MOBINEX_CAST_ENTRY(XMLDOMElement)
					MOBINEX_CAST_ENTRY(XMLDOMNode)
				END_MOBINEX_CAST_MAP()

				MsXMLDOMElement(MSXML2::IXMLDOMElementPtr element);

				virtual XMLDOMDocumentPtr getOwnerDocument();
				virtual MSXML2::IXMLDOMElementPtr getOwnElement(){ return element;}

				virtual MSXML2::DOMNodeType getNodeType();

				virtual XMLDOMNodeListPtr getChildNodes();
				virtual void	addChildNode(XMLDOMElementPtr aEmlementPtr);
				virtual void	removeChildNode(XMLDOMElementPtr aEmlementPtr);
				
				virtual LPCTSTR	getTagName();
				virtual LPCTSTR	getName();

				virtual LPCTSTR	getText();
				virtual bool	setText(LPCTSTR sText);
				virtual bool	setText(String sText);

				virtual LPCTSTR	getAttribute(LPCTSTR name);
				virtual void	setAttribute(LPCTSTR name, const _variant_t val);
				virtual int		getAttributeNum();
				virtual LPCTSTR	getAttributeItemName(const int nAtt);
				virtual LPCTSTR	getAttributeItemValue(const int nAtt);

			protected:
				MSXML2::IXMLDOMElementPtr element;
				MSXML2::IXMLDOMNamedNodeMapPtr pAttributes;
		};

		class  MOBINEX_UTIL_EXPORT MsXMLDOMNodeList : 
			virtual public XMLDOMNodeList,
			virtual public ObjectImpl
		{
			public:
				DECLARE_ABSTRACT_MOBINEX_OBJECT(MsXMLDOMNodeList)
				BEGIN_MOBINEX_CAST_MAP()
					MOBINEX_CAST_ENTRY(XMLDOMNodeList)
				END_MOBINEX_CAST_MAP()

				MsXMLDOMNodeList(MSXML2::IXMLDOMNodeListPtr nodeList);

				virtual int getLength();
				virtual XMLDOMNodePtr item(int index);
				virtual XMLDOMElementPtr nextElement();

			protected:
				MSXML2::IXMLDOMNodeListPtr nodeList;
			};
	}  // namespace util
}; // namespace mobinex

#endif // HAVE_MS_XML
#endif // _MOBINEX_UTIL_MSXML_H
