package risingnumbers.data.model;

import com.google.appengine.api.datastore.Key; 

import java.io.Serializable;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.jdo.annotations.IdGeneratorStrategy; 
import javax.jdo.annotations.IdentityType; 
import javax.jdo.annotations.PersistenceCapable; 
import javax.jdo.annotations.Persistent; 
import javax.jdo.annotations.PrimaryKey; 
 
@PersistenceCapable(identityType = IdentityType.APPLICATION, detachable="true")

/**
 * Game which has id, user 1, user 2, balls to user 1, balls to user 2, and status.
 * 
 * @author Brian Spiegel
 */
public class Game implements Serializable {

    private static final long serialVersionUID = 1L;
    
    public static final int PENDING = 1;
    public static final int IN_PLAY = 2;
    public static final int USER_1_LOST_CONNECTION = 3;
    public static final int USER_2_LOST_CONNECTION = 4;    
    public static final int USER_1_WON = 5;
    public static final int USER_2_WON = 6;
    
    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    public Key key;
    
    @Persistent 
    public long Id;

    @Persistent 
    public String userId1;
    
    @Persistent 
    public String userId2;

    @Persistent 
    public int status;    
    
    @Persistent 
    public Date lastTimeCheckedAccessedByUser1;    
    
    @Persistent 
    public Date lastTimeCheckedAccessedByUser2;

    @Persistent 
    public List<Ball> ballsToUser1=new ArrayList<Ball>();   
    
    @Persistent 
    public List<Ball> ballsToUser2=new ArrayList<Ball>();
   
}