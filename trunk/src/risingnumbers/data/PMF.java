package risingnumbers.data;

import javax.jdo.JDOHelper;
import javax.jdo.PersistenceManagerFactory;

/**
 * Singleton to get PersistenceManagerFactory.
 *
 * @author Brian Spiegel
 */
public final class PMF {
    private static final PersistenceManagerFactory pmfInstance =
        JDOHelper.getPersistenceManagerFactory("transactions-optional");

    /**
     * Default constructor.
     *
     */
    private PMF()
    {
        // Do nothing
    }

    /**
     * Get PersistenceManagerFactory.
     *
     * @return PersistenceManagerFactory
     */
    public static PersistenceManagerFactory get() {
        return pmfInstance;
    }
}
