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
 * Ball which has number and x value.
 * 
 * TODO - Remove annotations for datastore if not stored in datastore.
 *
 * @author Brian Spiegel
 */
public class Ball implements Serializable {

    private static final long serialVersionUID = 1L;
        
    @PrimaryKey 
    @Persistent(valueStrategy = IdGeneratorStrategy.IDENTITY) 
    public Key key;

    @Persistent 
    public int number;
    
    @Persistent 
    public int x;   
}