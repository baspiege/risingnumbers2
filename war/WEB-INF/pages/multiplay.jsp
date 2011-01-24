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
<%@ page import="com.google.appengine.api.memcache.MemcacheService" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheServiceFactory" %>

<%
response.setHeader("Cache-Control","no-cache");
response.setHeader("Pragma","no-cache");
response.setDateHeader ("Expires", -1);
%>

<%

// See if in game.  Else, see if pending.  Else, create new game.

String gameId=request.getParameter("gameId");

if (gameId!=null) {
    gameId=gameId.trim();
}
//System.out.println("Game Id: " + gameId);        

if (gameId==null || gameId.equals("NA")) {

    System.out.println("Pending game");        
    
    // Get pending games
    MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
    List<Game> pendingGames=(List<Game>)memcache.get("pendingGames");
    
    // If no pending games list, add new list.
    if (pendingGames==null){
        pendingGames=new ArrayList<Game>();
        memcache.put("pendingGames", pendingGames);
        
        System.out.println("New pending game list");        
    }
    
    // If no pending games, add pending game.
    Game game=null;
    if (pendingGames.isEmpty()){
        game=new Game();
        game.Id=session.getId();
        game.status=Game.PENDING;
        System.out.println("Adding pending game Id: " + game.Id);        
        
        pendingGames.add(game);
    } else {
        
        // Start new game (check if pending game is old?)
     
        // Get first 
        game=(Game)pendingGames.remove(0);
    }
    
    out.write(game.Id);    

} else {
 
    System.out.println("Existing game Id: " + gameId);        

    out.write( gameId );
    
    // Get game
    
    // If no game?
    
    // If game, if pending, return
    
    // If game, if running, switch numbers.

      //String 
      String number=request.getParameter("number");
      String x=request.getParameter("x");
      
      if (number!=null && x!=null){
        out.write( "," + number + "," + x );
      }
      
    // If game lost or game won?
    
    // If lost connection?
}

%>