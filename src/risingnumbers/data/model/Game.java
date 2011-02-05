package risingnumbers.data.model;

import java.io.Serializable;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * Game which has id, user 1, user 2, balls to user 1, balls to user 2, and status.
 *
 * @author Brian Spiegel
 */
public class Game implements Serializable {

    private static final long serialVersionUID = 1L;

    public static final int PENDING = 1;
    public static final int CONFIRM_START_1_AND_2 = 2;    
    public static final int CONFIRMED_START_1 = 3;
    public static final int CONFIRMED_START_2 = 4;
    public static final int IN_PLAY = 5;
    public static final int USER_1_LOST_CONNECTION = 6;
    public static final int USER_2_LOST_CONNECTION = 7;
    public static final int USER_1_WON = 8;
    public static final int USER_2_WON = 9;



    
    public long Id;

    public String userId1;

    public String userId2;

    public int status;

    public Date lastTimeCheckedAccessedByUser1;

    public Date lastTimeCheckedAccessedByUser2;

    public List<Ball> ballsToUser1=new ArrayList<Ball>();

    public List<Ball> ballsToUser2=new ArrayList<Ball>();
}