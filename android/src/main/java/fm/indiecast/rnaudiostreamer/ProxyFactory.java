package fm.indiecast.rnaudiostreamer;

import android.content.Context;
import com.danikula.videocache.HttpProxyCacheServer;
import android.util.Log;

/**
 * <strong>Not thread-safe</strong> {@link HttpProxyCacheServer} factory that returns single instance of proxy.
 *
 * @author Alexey Danilov (danikula@gmail.com).
 */

public class ProxyFactory {

    private static HttpProxyCacheServer sharedProxy;

    private ProxyFactory() {
    }

    public static HttpProxyCacheServer getProxy(Context context, Integer maxCacheFilesCount, Integer maxCacheSize) {
        return sharedProxy == null ? (sharedProxy = newProxy(context, maxCacheFilesCount, maxCacheSize)) : sharedProxy;
    }

    private static HttpProxyCacheServer newProxy(Context context, Integer maxCacheFilesCount, Integer maxCacheSize) {
        Log.d("HttpProxyCacheServer","New Instance: {maxCacheFilesCount: "+ maxCacheFilesCount +"}, {maxCacheSize: "+ maxCacheSize +"}");
        return new HttpProxyCacheServer.Builder(context)
            .maxCacheSize(maxCacheSize)
            .maxCacheFilesCount(maxCacheFilesCount)
            .build();
    }
}
