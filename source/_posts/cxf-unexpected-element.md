---
title: 烦人的cxf unexpected element 异常
date: 2014-05-15 21:52:17
categories: java
tags:
  - cxf
---

### 1.背景

当cxf传输的数据对象结构变化时,比如请求对象减少了字段,响应对象增加了字段,在jaxb unmarsh时会抛出异常,导致接口访问失败.

	javax.xml.bind.UnmarshalException: unexpected element (uri:"", local:"name"). Expected elements are <{}name>
	
上面这是一个典型的`unexpected element`异常,如果cxf客户端请求中多了一个`name`属性,或者cxf服务端响应中多了一个`name`属性,都会导致此异常.

### 2.源代码分析

翻了下源代码:

`com.sun.xml.bind.v2.runtime.unmarshaller.StructureLoader#childElement`检查是否是新增属性
	
	 @Override
    public void childElement(UnmarshallingContext.State state, TagName arg) throws SAXException {
        ChildLoader child = childUnmarshallers.get(arg.uri,arg.local);
        if(child==null) {//检查是否新增属性
            child = catchAll;
            if(child==null) {
                super.childElement(state,arg);
                return;
            }
        }

        state.loader = child.loader;
        state.receiver = child.receiver;
    }

在`com.sun.xml.bind.v2.runtime.unmarshaller.Loader`中检查是否处理此问题

	 public void childElement(UnmarshallingContext.State state, TagName ea) throws SAXException {
        // notify the error, then recover by ignoring the whole element.
        reportUnexpectedChildElement(ea, true);
        state.loader = Discarder.INSTANCE;
        state.receiver = null;
    }

    @SuppressWarnings({"StringEquality"})
    protected final void reportUnexpectedChildElement(TagName ea, boolean canRecover) throws SAXException {
        if(canRecover && !UnmarshallingContext.getInstance().parent.hasEventHandler())
        //这里默认会有个EventHandler,不会直接忽略此问题
            // this error happens particurly often (when input documents contain a lot of unexpected elements to be ignored),
            // so don't bother computing all the messages and etc if we know that
            // there's no event handler to receive the error in the end. See #286 
            return;
         //下面的代码抛出异常
        if(ea.uri!=ea.uri.intern() || ea.local!=ea.local.intern())
            reportError(Messages.UNINTERNED_STRINGS.format(), canRecover );
        else
            reportError(Messages.UNEXPECTED_ELEMENT.format(ea.uri,ea.local,computeExpectedElements()), canRecover );
    }
    
在`org.apache.cxf.jaxb.io.DataReaderImpl#createUnmarshaller`中设置了`EventHandler`,注意这里的`veventHandler`,默认是没有的.

	if (setEventHandler) {
                um.setEventHandler(new WSUIDValidationHandler(veventHandler));
    }
    
 `org.apache.cxf.jaxb.io.DataReaderImpl.WSUIDValidationHandler`的代码很简单:

	private static class WSUIDValidationHandler implements ValidationEventHandler {
        ValidationEventHandler origHandler;
        WSUIDValidationHandler(ValidationEventHandler o) {
            origHandler = o;
        }

        public boolean handleEvent(ValidationEvent event) {
            String msg = event.getMessage();
            System.out.println("WSUIDValidationHandler"+msg);
            if (msg != null
                    && msg.contains(":Id")
                    && (msg.startsWith("cvc-type.3.1.1: ")
                    || msg.startsWith("cvc-type.3.2.2: ")
                    || msg.startsWith("cvc-complex-type.3.1.1: ")
                    || msg.startsWith("cvc-complex-type.3.2.2: "))) {
                return true;
            }
            if (origHandler != null) {
                return origHandler.handleEvent(event);
            }
            return false;
        }
    }
    
先自己处理,自己处理不了的交给`origHandler`,那我们只需要自己构建一个`javax.xml.bind.ValidationEventHandler`来专门处理`unexpected element`异常,问题就得到了解决.

`org.apache.cxf.jaxb.io.DataReaderImpl#setProperty`中有段代码:

	 veventHandler = (ValidationEventHandler)m.getContextualProperty("jaxb-validation-event-handler");
            if (veventHandler == null) {
                veventHandler = databinding.getValidationEventHandler();
            }
 
 如果配置了`jaxb-validation-event-handler`属性,就可以让我们自己的`javax.xml.bind.ValidationEventHandler`来处理此异常.也可以设置`setEventHandler`为`false`,不设置异常处理器,忽略所有unmarsh异常,不过这样我感觉太暴力了点,这样做也忽略了`org.apache.cxf.jaxb.io.DataReaderImpl.WSUIDValidationHandler`的逻辑,点儿都不科学.
 
### 3.实现

 上面分析清楚了,实现就很简单,实现`javax.xml.bind.ValidationEventHandler`
 
	public class IgnoreUnexpectedElementValidationEventHandler implements ValidationEventHandler {
    		private static final Logger logger = LoggerFactory.getLogger(IgnoreUnexpectedElementValidationEventHandler.class);

    		@Override
    		public boolean handleEvent(ValidationEvent event) {
       		 	String msg = event.getMessage();
       		 	if (msg != null && msg.startsWith("unexpected element")) {
           		 	logger.warn("{}", msg);
           		 	return true;
        	 	}
          		return false;
    		}
	}
 
 在`cxf:bus`中配置下就ok
 
 	 <cxf:bus>
        <cxf:properties>
            <entry key="jaxb-validation-event-handler">
                <bean class="IgnoreUnexpectedElementValidationEventHandler"/>
            </entry>
        </cxf:properties>
    </cxf:bus>
    
 建议只在线上环境启用此东东,线下还是不要开启,早点发现问题是好事.
 
