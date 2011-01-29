<%-- This controls the multiplayer games. --%>
<%@page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page language="java"%>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="risingnumbers.data.model.Game" %>
<%@ page import="risingnumbers.data.model.Ball" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheService" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheServiceFactory" %>

<%!
// Constants
public static int CONNECTION_OLD_MILLIS=5000;
public static String PENDING_GAME="pendingGame";
public static String GAME_ID_PREFIX="gameId_";
public static String USER_ID_PREFIX="userId_";
public static String GAME_ID_GENERATOR="gameIdGenerator";
%>

<%
response.setHeader("Cache-Control","no-cache");
response.setHeader("Pragma","no-cache");
response.setDateHeader ("Expires", -1);

/** Server
* Change pending list to pending game... (there will be only 1 for now...) TEST
* Get game status from game.  If over, signal to other player.
*/

MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();

String userId=request.getParameter("userId");
Long gameId=null;

if (userId==null || userId.trim().length()==0) {
    // No user Id
    System.out.println("No user Id");
    return;
} else {
    userId=userId.trim();
    gameId=(Long)memcache.get(USER_ID_PREFIX+userId);
}

// If game is null, check pending game.
if (gameId==null) {
    System.out.println("No game Id - checking pending game");        
    
    // Get pending game
    Game pendingGame=(Game)memcache.get(PENDING_GAME);
    if (pendingGame!=null){
        long time=new Date().getTime();
        
        // Check time
        if (time - pendingGame.lastTimeCheckedAccessedByUser1.getTime() > CONNECTION_OLD_MILLIS ) {
            System.out.println("Removing pending game Id: " + pendingGame.Id);               
            memcache.delete(GAME_ID_PREFIX + pendingGame.Id);
            memcache.delete(PENDING_GAME);
            pendingGame=null;           
        } else {
            // Debug       
            System.out.println("Adding user to existing game Id: " + pendingGame.Id);               
        
            // Set as user 2 and put into play
            pendingGame.userId2=userId;
            pendingGame.lastTimeCheckedAccessedByUser2=new Date();
            pendingGame.status=Game.IN_PLAY;
            memcache.delete(PENDING_GAME);
        }
    }
    
    if (pendingGame==null) {        
        // Create new pending game
        pendingGame=new Game();
        pendingGame.Id=memcache.increment(GAME_ID_GENERATOR,1L,0L);
        pendingGame.status=Game.PENDING;
        pendingGame.userId1=userId;
        pendingGame.lastTimeCheckedAccessedByUser1=new Date();
        memcache.put(PENDING_GAME,pendingGame);
        
        // Debug
        System.out.println("Creating pending game Id: " + pendingGame.Id);
    }

    // Set in cache
    memcache.put(GAME_ID_PREFIX+pendingGame.Id, pendingGame);    
    memcache.put(USER_ID_PREFIX+userId,pendingGame.Id);

} else {
 
    System.out.println("Existing game Id: " + gameId);        
    
    // Get game
    Game game=(Game)memcache.get(GAME_ID_PREFIX + gameId);
   
    // If null, then error
    if (game==null) {
        memcache.delete(GAME_ID_PREFIX + gameId);
        memcache.delete(USER_ID_PREFIX + userId);
        return;
    }
    
    // Check which user
    boolean isUser1=userId.equals(game.userId1);
    System.out.println(userId + " " + game.userId1 + " " + isUser1);        
    
    // Update time stamps
    if (isUser1){
        game.lastTimeCheckedAccessedByUser1=new Date();
    } else {
        game.lastTimeCheckedAccessedByUser2=new Date();
    }
    
    // If pending, return
    if (game.status==Game.PENDING) {    
        out.write( game.status + ",");
        System.out.println("Existing game pending");       
        memcache.put(GAME_ID_PREFIX + gameId, game);
        memcache.put(PENDING_GAME,game);
     }
 
    // If running, switch numbers. 
    else if (game.status==Game.IN_PLAY) {
    
        if (isUser1){
            if (new Date().getTime() - game.lastTimeCheckedAccessedByUser2.getTime() > CONNECTION_OLD_MILLIS ) {
        
                game.status=Game.USER_2_LOST_CONNECTION;
                memcache.put(GAME_ID_PREFIX + gameId,game);        
            }
        } else {
            if (new Date().getTime() - game.lastTimeCheckedAccessedByUser1.getTime() > CONNECTION_OLD_MILLIS ) {        
                game.status=Game.USER_1_LOST_CONNECTION;
                memcache.put(GAME_ID_PREFIX + gameId,game);
            }        
        }
    
        System.out.println("Existing game in play");      
    
        //String 
        String number=request.getParameter("number");
        String x=request.getParameter("x");

        if (number!=null && x!=null){
            Ball ball=new Ball();
            ball.number=new Integer(number).intValue();
            ball.x=new Integer(x).intValue();
            
            System.out.println("Existing game in play - Adding ball");      
          
            if (isUser1){
                game.ballsToUser2.add(ball);
            } else {
                game.ballsToUser1.add(ball);            
            }
        }
      
        Ball ballToSend=null;
        List ballsToSend=null;
        if (isUser1){
            System.out.println("Existing game in play - Checking 1 return");      
            ballsToSend=game.ballsToUser1;
        } else {
            System.out.println("Existing game in play - Checking 2 return");      
            ballsToSend=game.ballsToUser2;
        }
       
        if (ballsToSend.size()>0) {
            ballToSend=(Ball)ballsToSend.remove(0);          
        }
      
        // Always send game status
        out.write( game.status + ",");
      
        if (ballToSend!=null){
            System.out.println("Existing game in play - Returning ball");
            out.write( ballToSend.number + "," + ballToSend.x );
        } 
        
        // Save game
        memcache.put(GAME_ID_PREFIX + gameId,game);        
    }
    else {
    
        out.write( game.status + "," );
    }
      
    // If game lost or game won?   
}
%>