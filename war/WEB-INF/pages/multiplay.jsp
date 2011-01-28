<%-- This JSP has the HTML for the store page. --%>
<%@page pageEncoding="UTF-8" contentType="text/html; charset=UTF-8" %>
<%@ page language="java"%>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Random" %>
<%@ page import="risingnumbers.data.PMF" %>
<%@ page import="risingnumbers.data.model.Game" %>
<%@ page import="risingnumbers.data.model.Ball" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheService" %>
<%@ page import="com.google.appengine.api.memcache.MemcacheServiceFactory" %>


<%! public static int CONNECTION_OLD_MILLIS=10000; %>

<%
response.setHeader("Cache-Control","no-cache");
response.setHeader("Pragma","no-cache");
response.setDateHeader ("Expires", -1);

/** Server

Get game status from game.  If over, signal to other player.
User mem cache increment!!!

*/

MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();

String userId=request.getParameter("userId");
Long gameId=null;

if (userId==null || userId.trim().length()==0) {
    // No user
    System.out.println("No user Id");
    throw new RuntimeException("No user Id");
} else {
    userId=userId.trim();
    gameId=(Long)memcache.get("userId_"+userId);
    System.out.println("Game Id: " + gameId);
}

// If game is null, check pending games.
if (gameId==null) {
    System.out.println("New game");        
    
    // Get pending games
    List<Game> pendingGames=(List<Game>)memcache.get("pendingGames");
    
    // If no pending games list, add new list.
    if (pendingGames==null){
        pendingGames=new ArrayList<Game>();
        memcache.put("pendingGames", pendingGames);        
        System.out.println("New pending game list");        
    }
    
    // If no pending games, add pending game.
    Game game=null;
    if (!pendingGames.isEmpty()){
        while (pendingGames.size()>0) {
            // Get first 
            game=(Game)pendingGames.remove(0);
        
            if (new Date().getTime() - game.lastTimeCheckedAccessedByUser1.getTime() > CONNECTION_OLD_MILLIS ) {
                System.out.println("Removing old game Id: " + game.Id);               
                game=null;
   
                // Update
                memcache.put("pendingGames",pendingGames);            
            } else {
                // Set as user 2 and put into play
                game.userId2=userId;
                game.lastTimeCheckedAccessedByUser2=new Date();
                game.status=Game.IN_PLAY;
                
                memcache.put("pendingGames",pendingGames);
                break;
            }
            
            // Get latest
            pendingGames=(List<Game>)memcache.get("pendingGames");
        }
    }
    
    if (game==null) {
        game=new Game();
        
        // TODO - User mem cache increment!!!
        game.Id=new Random().nextLong();
        game.status=Game.PENDING;
        game.userId1=userId;
        game.lastTimeCheckedAccessedByUser1=new Date();
        
        System.out.println("Adding pending game Id: " + game.Id);        
        
        pendingGames.add(game);
        memcache.put("pendingGames",pendingGames);
    }    

    // Set in cache
    memcache.put("gameId_" + game.Id, game);    
    memcache.put("userId_"+userId,game.Id);

} else {
 
    System.out.println("Existing game Id: " + gameId);        
    
    // Get game
    Game game=(Game)memcache.get("gameId_" + gameId);
   
    // If null, then error
    if (game==null) {
        memcache.delete("gameId_" + gameId);
        memcache.delete("userId_" + userId);
        
        throw new RuntimeException("Game object not found");
    }
    
    boolean isUser1=userId.equals(game.userId1);
    
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
    }
 
    // If running, switch numbers. 
    else if (game.status==Game.IN_PLAY) {
    
        if (isUser1){
            if (new Date().getTime() - game.lastTimeCheckedAccessedByUser2.getTime() > CONNECTION_OLD_MILLIS ) {
        
                game.status=Game.USER_2_LOST_CONNECTION;
                memcache.put("gameId_" + gameId,game);        
                //memcache.delete("userId_" + game.userId2);
                //throw new RuntimeException("User 2 lost connection");
            }
        } else {
            if (new Date().getTime() - game.lastTimeCheckedAccessedByUser1.getTime() > CONNECTION_OLD_MILLIS ) {
        
                game.status=Game.USER_1_LOST_CONNECTION;
                //memcache.delete("userId_" + game.userId1);   
                //throw new RuntimeException("User 1 lost connection");
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
            
         //   memcache.put("gameId_" + gameId,game);
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
        //    memcache.put("gameId_" + gameId,game);                    
            
        }
      
        out.write( game.status + ",");
      
        if (ballToSend!=null){
            System.out.println("Existing game in play - Returning ball");      
        
            out.write( ballToSend.number + "," + ballToSend.x );
        } 
        
        memcache.put("gameId_" + gameId,game);        
    }
    else {
    
            out.write( game.status + "," );
    }
      
    // If game lost or game won?
    
}

%>