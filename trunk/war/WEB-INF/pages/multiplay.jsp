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

// Memcache names
public static String PENDING_GAME="pendingGame";
public static String GAME_ID_PREFIX="gameId_";
public static String USER_ID_PREFIX="userId_";
public static String GAME_ID_GENERATOR="gameIdGenerator";

// Response parameter names
public static String USER_ID_PARAMETER="userId";
public static String NUMBER_PARAMETER="number";
public static String X_PARAMETER="x";
public static String GAME_OVER_PARAMETER="gameOver";

// Response constants.  Different than game status constants.
public static int RESPONSE_PENDING=1;
public static int RESPONSE_IN_PLAY=2;
public static int RESPONSE_OPPONENT_LOST_CONNECTION=3;
public static int RESPONSE_USER_WON=4;
public static int RESPONSE_USER_LOST=5;

%>

<%
response.setHeader("Cache-Control","no-cache");
response.setHeader("Pragma","no-cache");
response.setDateHeader ("Expires", -1);

/** TODO
* Clean up system outs.
*/

MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();

String userId=request.getParameter(USER_ID_PARAMETER);
Long gameId=null;

// Check if user Id
if (userId==null || userId.trim().length()==0) {
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

        // Remove pending game if old
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

    // If no pending game, create a new one
    if (pendingGame==null) {
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
    System.out.println(userId + " " + isUser1);

    // Update time stamps
    if (isUser1){
        game.lastTimeCheckedAccessedByUser1=new Date();
    } else {
        game.lastTimeCheckedAccessedByUser2=new Date();
    }

    // If pending, return
    if (game.status==Game.PENDING) {
        out.write( RESPONSE_PENDING + ",");
        System.out.println("Existing game pending");
        memcache.put(GAME_ID_PREFIX + gameId, game);
        memcache.put(PENDING_GAME,game);
        return;
    }

    //  Check game over
    String gameOverString=request.getParameter(GAME_OVER_PARAMETER);
    if (gameOverString!=null && gameOverString.equals("true")) {
        if (isUser1) {
            game.status=Game.USER_2_WON;
        } else {
            game.status=Game.USER_1_WON;
        }
        memcache.put(GAME_ID_PREFIX + gameId, game);
    }

    // Check for lost connections
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

    // If running, switch numbers.
    if (game.status==Game.IN_PLAY) {
        System.out.println("Existing game in play");

        // Get ball from request
        String number=request.getParameter(NUMBER_PARAMETER);
        String x=request.getParameter(X_PARAMETER);

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

        // Check ball to send
        Ball ballToSend=null;
        List ballsToSend=null;
        if (isUser1){
            System.out.println("Existing game in play - Checking 1 return");
            ballsToSend=game.ballsToUser1;
        } else {
            System.out.println("Existing game in play - Checking 2 return");
            ballsToSend=game.ballsToUser2;
        }

        // If there is ball to send, get the oldest
        if (ballsToSend.size()>0) {
            ballToSend=(Ball)ballsToSend.remove(0);
        }

        // Always send game status
        out.write( RESPONSE_IN_PLAY + ",");

        if (ballToSend!=null){
            System.out.println("Existing game in play - Returning ball");
            out.write( ballToSend.number + "," + ballToSend.x );
        }

        // Save game
        memcache.put(GAME_ID_PREFIX + gameId,game);
    }
    // Game won
    else if (game.status==Game.USER_1_WON || game.status==Game.USER_2_WON) {
        // Check user
        if ((isUser1 && game.status==Game.USER_1_WON)
        || (!isUser1 && game.status==Game.USER_2_WON)) {
            out.write( RESPONSE_USER_WON + "," );
        } else {
          out.write( RESPONSE_USER_LOST + "," );
        }
    }
    // Lost connection
    else if (game.status==Game.USER_1_LOST_CONNECTION || game.status==Game.USER_2_LOST_CONNECTION) {
        // Check user
        if ((isUser1 && game.status==Game.USER_2_LOST_CONNECTION)
        || (!isUser1 && game.status==Game.USER_1_LOST_CONNECTION)) {
            out.write( RESPONSE_OPPONENT_LOST_CONNECTION + "," );
        }
        // The user that lost the connection will see game lost if they reconnect
        else {
            out.write( RESPONSE_USER_LOST + "," );
        }
    }
}
%>