package risingnumbers.utils;

import com.google.appengine.api.memcache.MemcacheService;
import com.google.appengine.api.memcache.MemcacheServiceFactory;

import java.util.Map;
import javax.servlet.http.HttpServletRequest;

import risingnumbers.data.model.Game;


/**
 * Mem cache utilities.
 *
 * @author Brian Spiegel
 */
public class MemCacheUtils
{
    public static String GAMES="games";

    /**
    * Get the games from cache.
    *
    * @param aRequest Servlet Request
    */
    public static Map<Long,Game> getServices(HttpServletRequest aRequest)
    {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            return (Map<Long,Game>)memcache.get(GAMES);
    }
    
    /**
    * Set the games into cache.
    *
    * @param aRequest Servlet Request
    * @param aServices Services
    */
    public static void setServices(HttpServletRequest aRequest, Map<Long,Game> aGames)
    {
            MemcacheService memcache=MemcacheServiceFactory.getMemcacheService();
            memcache.put(GAMES, aGames);
    }
    

}
