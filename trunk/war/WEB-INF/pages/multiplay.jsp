<%-- This JSP has the HTML for the store page. --%>
<%@page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page language="java"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Random" %>
<%@ page import="risingnumbers.data.PMF" %>
<%@ page import="risingnumbers.data.model.Game" %>

<%
response.setHeader("Cache-Control","no-cache");
response.setHeader("Pragma","no-cache");
response.setDateHeader ("Expires", -1);
%>

<%

// Take request.

// See if in game.  Else, see if pending.  Else, create new game.

// If in game, switch numbers.

// TODO
// return numbers, value and x

out.write( new Integer(new Random().nextInt(26)).toString() );




%>