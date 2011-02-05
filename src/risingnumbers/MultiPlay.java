package risingnumbers;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.util.Date;
import java.util.List;

import risingnumbers.data.model.Game;
import risingnumbers.data.model.Ball;
import com.google.appengine.api.memcache.MemcacheService;
import com.google.appengine.api.memcache.MemcacheServiceFactory;

/**
* TODO
* Add double handshake to beginning - Test.
*
* Minor:
* Comment out system outs
*
*/
public class MultiPlay extends HttpServlet {

    // Constants
    public static int CONNECTION_OLD_MILLIS=10000;

    // Memcache names
    public static String PENDING_GAME="pendingGame";
    public static String GAME_ID_PREFIX="gameId_";
    public static String USER_ID_PREFIX="userId_";
    public static String GAME_ID_GENERATOR="gameIdGenerator";

    // Response parameter names
    public static String USER_ID_PARAMETER="userId";
    public static String NUMBER_PARAMETER="number";
    public static String GAME_OVER_PARAMETER="gameOver";

    // Response constants.  Different than game status constants.
    public static int RESPONSE_PENDING=1;
    public static int RESPONSE_IN_PLAY=2;
    public static int RESPONSE_OPPONENT_LOST_CONNECTION=3;
    public static int RESPONSE_USER_WON=4;
    public static int RESPONSE_USER_LOST=5;

    /**
    * Process the request.
    */
    public void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
      
        // Don't cache
        response.setHeader("Cache-Control","no-cache");
        response.setHeader("Pragma","no-cache");
        response.setDateHeader ("Expires", -1);
    
        PrintWriter out = response.getWriter();
    
        MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();

        String userId=request.getParameter(USER_ID_PARAMETER);
        Long gameId=null;

        // Check if user Id
        if (userId==null || userId.trim().length()==0) {
            System.err.println("No user Id");
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
                    pendingGame.status=Game.CONFIRM_START_1_AND_2;
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
                System.err.println("Existing game Id is null");
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
                System.out.println("Existing game pending");
                out.write( RESPONSE_PENDING );
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
                
                    if (!isGameBeingConfirmed(game.status)) {
                        game.status=Game.USER_2_LOST_CONNECTION;
                        memcache.put(GAME_ID_PREFIX + gameId,game);
                    } else {
                        // Remove game because it hasn't even started
                        removeGame(memcache,game);
                        out.write( RESPONSE_PENDING );
                        return;
                    }
                }
            } else {
                if (new Date().getTime() - game.lastTimeCheckedAccessedByUser1.getTime() > CONNECTION_OLD_MILLIS ) {
                
                    if (!isGameBeingConfirmed(game.status)) {
                        game.status=Game.USER_1_LOST_CONNECTION;
                        memcache.put(GAME_ID_PREFIX + gameId,game);
                    } else {
                        // Remove game because it hasn't even started
                        removeGame(memcache,game);
                        out.write( RESPONSE_PENDING );
                        return;
                    }                    
                }
            }

            // If running, switch numbers.
            if (game.status==Game.IN_PLAY) {
                System.out.println("Existing game in play");

                // Get ball from request
                String number=request.getParameter(NUMBER_PARAMETER);

                if (number!=null) {
                    Ball ball=new Ball();
                    ball.number=new Integer(number).intValue();

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
                out.write( RESPONSE_IN_PLAY );

                if (ballToSend!=null){
                    System.out.println("Existing game in play - Returning ball");
                    out.write( "," + ballToSend.number );
                }

                // Save game
                memcache.put(GAME_ID_PREFIX + gameId,game);
            }
            // Game won
            else if (game.status==Game.USER_1_WON || game.status==Game.USER_2_WON) {
                // Check user
                if ((isUser1 && game.status==Game.USER_1_WON)
                || (!isUser1 && game.status==Game.USER_2_WON)) {
                    out.write( RESPONSE_USER_WON );
                } else {
                  out.write( RESPONSE_USER_LOST );
                }
            }
            // Lost connection
            else if (game.status==Game.USER_1_LOST_CONNECTION || game.status==Game.USER_2_LOST_CONNECTION) {
                // Check user
                if ((isUser1 && game.status==Game.USER_2_LOST_CONNECTION)
                || (!isUser1 && game.status==Game.USER_1_LOST_CONNECTION)) {
                    out.write( RESPONSE_OPPONENT_LOST_CONNECTION );
                }
                // The user that lost the connection will see game lost if they reconnect
                else {
                    out.write( RESPONSE_USER_LOST );
                }
            }
            // Confirm start
            else if (isGameBeingConfirmed(game.status)) {
                if (isUser1) {
                    // If 2 already confirmed, now 1 is confirming.  So start play.
                    if (game.status==Game.CONFIRMED_START_2) {
                        game.status=Game.IN_PLAY;
                        memcache.put(GAME_ID_PREFIX + gameId,game);
                        out.write( RESPONSE_IN_PLAY );
                        return;
                    } else if (game.status==Game.CONFIRM_START_1_AND_2) {
                        // Confirm 1.
                        game.status=Game.CONFIRMED_START_1;
                        memcache.put(GAME_ID_PREFIX + gameId,game);
                    }
                } else {
                    // If 1 already confirmed, now 2 is confirming.  So start play.
                    if (game.status==Game.CONFIRMED_START_1) {
                        game.status=Game.IN_PLAY;
                        memcache.put(GAME_ID_PREFIX + gameId,game);
                        out.write( RESPONSE_IN_PLAY );
                        return;
                    } else if (game.status==Game.CONFIRM_START_1_AND_2) {
                        // Confirm 2.
                        game.status=Game.CONFIRMED_START_2;
                        memcache.put(GAME_ID_PREFIX + gameId,game);
                    }                
                }
               
                out.write( RESPONSE_PENDING );
                return;
            }
        }
    }    
    
   /**
    * Check if confirming.
    */
    public static boolean isGameBeingConfirmed(int status) {
        return status==Game.CONFIRM_START_1_AND_2
            || status==Game.CONFIRMED_START_1
            || status==Game.CONFIRMED_START_2;
    }
    
    /**
    * Remove game.
    */
    public static void removeGame(MemcacheService memcache, Game game) {
        memcache.delete(GAME_ID_PREFIX + game.Id);
        memcache.delete(USER_ID_PREFIX + game.userId1);
        memcache.delete(USER_ID_PREFIX + game.userId2);
    }
}