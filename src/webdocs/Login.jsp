<%@ page import="org.apache.log4j.*" %>
<%@ page import="com.ecyrd.jspwiki.*" %>
<%@ page import="com.ecyrd.jspwiki.attachment.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.security.Principal" %>
<%@ page import="com.ecyrd.jspwiki.tags.WikiTagBase" %>
<%@ page import="com.ecyrd.jspwiki.auth.*" %>
<%@ page import="com.ecyrd.jspwiki.auth.login.CookieAssertionLoginModule" %>
<%@ page errorPage="/Error.jsp" %>
<%@ taglib uri="/WEB-INF/jspwiki.tld" prefix="wiki" %>

<%! 
    public void jspInit()
    {
        wiki = WikiEngine.getInstance( getServletConfig() );
    }
    Logger log = Logger.getLogger("JSPWiki"); 
    WikiEngine wiki;
%>

<%
    AuthenticationManager mgr = wiki.getAuthenticationManager();
    WikiContext wikiContext = wiki.createContext( request, WikiContext.LOGIN );
    WikiSession wikiSession = wikiContext.getWikiSession();
    NDC.push( wiki.getApplicationName() + ":Login.jsp"  );
    
    if( !mgr.isContainerAuthenticated() )
    {
        // If user got here and is already authenticated, it means
        // they just aren't allowed access to what they asked for.
        // Weepy tears and hankies all 'round.
        if( wikiSession.isAuthenticated() )
        {
            response.sendError( HttpServletResponse.SC_FORBIDDEN, "It seems you don't have access to that. Sorry." );
            return;
        }
    
        // If using custom auth, we need to do the login now

        String action = request.getParameter("action");
        if( "login".equals(action) )
        {
            String uid    = request.getParameter( "j_username" );
            String passwd = request.getParameter( "j_password" );
            log.debug( "Attempting to authenticate user " + uid );
            
            // Log the user in!
            if ( mgr.login( wikiSession, uid, passwd ) )
            {
                log.info( "Successfully authenticated user " + uid + " (custom auth)" );
            }
            else
            {
                log.info( "Failed to authenticate user " + uid );
                if ( passwd.length() > 0 && passwd.toUpperCase().equals(passwd) )
                {
                    wikiSession.addMessage("Invalid login (please check your Caps Lock key)");
                }
                else
                {
                    wikiSession.addMessage("Not a valid login.");
                }
            }
        }
    }
    else 
    {
        // If using container auth, the container will have automatically
        // attempted to log in the user before Login.jsp was loaded.
        // Thus, if we got here, the container must have authenticated 
        // the user already. All we do is simply record that fact.
        // Nice and easy.
        
        Principal user = wikiSession.getLoginPrincipal();
        log.info( "Successfully authenticated user " + user.getName() + " (container auth)" );
    }    
    
    // If user logged in, set the user cookie with the wiki principal's name.
    // redirect to wherever we're supposed to go. If login.jsp
    // was called without parameters, this will be the front page. Otherwise,
    // there's probably a 'page' parameter telling us where to go.
    
    if( wikiSession.isAuthenticated() )
    {
        // Set user cookie
        Principal principal = wikiSession.getUserPrincipal();
        CookieAssertionLoginModule.setUserCookie( response, principal.getName() );
        
        // If wiki page was "Login", redirect to main, otherwise use the page supplied
        String redirectPage = wikiContext.getPage().getName();
        String viewUrl = ( "Login".equals( redirectPage ) ) ? "Wiki.jsp" : wiki.getViewURL( redirectPage );
    
        // Redirect!
        log.info( "Redirecting user to " + viewUrl );
        response.sendRedirect( viewUrl );
        NDC.pop();
        NDC.remove();
        return;
    }
    
    // If we've gotten here, the user hasn't authenticated yet.
    // So, find the login form and include it. This should be in the same directory
    // as this page. We don't need to use the wiki:Include tag.
    
%><jsp:include page="LoginForm.jsp" /><%
    // Clean up the logger and clear UI messages
    NDC.pop();
    NDC.remove();
    wikiContext.getWikiSession().clearMessages();
%>
