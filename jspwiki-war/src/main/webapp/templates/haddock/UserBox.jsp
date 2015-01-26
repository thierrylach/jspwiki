<%--
    Licensed to the Apache Software Foundation (ASF) under one
    or more contributor license agreements.  See the NOTICE file
    distributed with this work for additional information
    regarding copyright ownership.  The ASF licenses this file
    to you under the Apache License, Version 2.0 (the
    "License"); you may not use this file except in compliance
    with the License.  You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing,
    software distributed under the License is distributed on an
    "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
    KIND, either express or implied.  See the License for the
    specific language governing permissions and limitations
    under the License.  
--%>

<%@ taglib uri="http://jspwiki.apache.org/tags" prefix="wiki" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ page import="javax.servlet.jsp.jstl.fmt.*" %>
<%@ page import="org.apache.wiki.*" %>
<fmt:setLocale value="${prefs.Language}" />
<fmt:setBundle basename="templates.default"/>
<%
  WikiContext c = WikiContext.findContext(pageContext);
%>
<wiki:UserCheck status="anonymous">
  <label class="username anonymous"><fmt:message key="fav.greet.anonymous" /></label>
</wiki:UserCheck>
<wiki:UserCheck status="asserted">
  <label class="username asserted">
    <fmt:message key="fav.greet.asserted">
      <fmt:param><wiki:Translate>[<wiki:UserName />]</wiki:Translate></fmt:param>
    </fmt:message>
  </label>
</wiki:UserCheck>
<wiki:UserCheck status="authenticated">
  <label class="username authenticated">
    <fmt:message key="fav.greet.authenticated">
      <fmt:param><wiki:Translate>[<wiki:UserName />]</wiki:Translate></fmt:param>
    </fmt:message>
  </label>
</wiki:UserCheck>

<%-- login button --%>
<div class="btn-group">
<wiki:UserCheck status="notAuthenticated">
  <wiki:CheckRequestContext context='!login'>
    <wiki:Permission permission="login">
      <a href="<wiki:Link jsp='Login.jsp' format='url'><wiki:Param 
         name='redirect' value='<%=c.getEngine().encodeName(c.getName())%>'/></wiki:Link>" 
         class="btn btn-default login"
         title="<fmt:message key='actions.login.title'/>"><fmt:message key="actions.login"/></a>
    </wiki:Permission>
  </wiki:CheckRequestContext>
</wiki:UserCheck>

<%-- logout button --%>
<wiki:UserCheck status="authenticated">
   <a href="<wiki:Link jsp='Logout.jsp' format='url' />" 
      class="btn btn-default logout"
      title="<fmt:message key='actions.logout.title'/>"><fmt:message key="actions.logout"/></a>
   <%--onclick="return( confirm('<fmt:message key="actions.confirmlogout"/>') && (location=this.href) );"--%>
</wiki:UserCheck>

<%-- user preferences button --%>
<wiki:CheckRequestContext context='!prefs'>
  <wiki:CheckRequestContext context='!preview'>
    <a href="<wiki:Link jsp='UserPreferences.jsp' format='url' ><wiki:Param name='redirect'
      value='<%=c.getEngine().encodeName(c.getName())%>'/></wiki:Link>"
      class="btn btn-default login prefs" 
      accesskey="p"
      title="<fmt:message key='actions.prefs.title'/>"><fmt:message key="actions.prefs" />
    </a>
  </wiki:CheckRequestContext>
</wiki:CheckRequestContext>
</div>