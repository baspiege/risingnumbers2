package risingnumbers.data.model;

import com.google.appengine.api.datastore.Key; 

import java.io.Serializable;

import java.util.ArrayList;
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
    public static final int USER_1_WON = 2;
    public static final int USER_2_WON = 3;
    
    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    private Key key;

    @Persistent 
    public String userId1;
    
    @Persistent 
    public String userId2;

    @Persistent 
    public int status;    


// TODO - Have ball be class.  number and x?

    @Persistent 
    public List<Integer> ballsToUser1=new ArrayList<Integer>();   
    
    @Persistent 
    public List<Integer> ballsToUser2=new ArrayList<Integer>();
   
}