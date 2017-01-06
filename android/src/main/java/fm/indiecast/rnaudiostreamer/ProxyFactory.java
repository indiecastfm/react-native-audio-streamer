package fm.indiecast.rnaudiostreamer;

import android.content.Context;
import com.danikula.videocache.HttpProxyCacheServer;

/**
 * <strong>Not thread-safe</strong> {@link HttpProxyCacheServer} factory that returns single instance of proxy.
 *
 * @author Alexey Danilov (danikula@gmail.com).
 */

public class ProxyFactory {

    private static HttpProxyCacheServer sharedProxy;

    private ProxyFactory() {
    }

    public static HttpProxyCacheServer getProxy(Context context) {
        return sharedProxy == null ? (sharedProxy = newProxy(context)) : sharedProxy;
    }

    private static HttpProxyCacheServer newProxy(Context context) {
        return new HttpProxyCacheServer.Builder(context)
            //.maxCacheSize(1024 * 1024 * 1024) // 1 Gb for cache
            .maxCacheFilesCount(100) // 100 files
            .build();
    }
}
