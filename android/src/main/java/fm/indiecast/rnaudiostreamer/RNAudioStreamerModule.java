package fm.indiecast.rnaudiostreamer;

import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;
import android.support.v4.app.NotificationCompat;
import android.support.v4.app.TaskStackBuilder;
import android.telephony.PhoneStateListener;
import android.telephony.TelephonyManager;
import android.util.Log;
import android.widget.RemoteViews;
import android.os.Build;
import android.net.Uri;

import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

import com.facebook.infer.annotation.Assertions;
import com.google.android.exoplayer2.DefaultLoadControl;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.LoadControl;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.extractor.ExtractorsFactory;
import com.google.android.exoplayer2.extractor.ts.AdtsExtractor;
import com.google.android.exoplayer2.metadata.MetadataRenderer;
import com.google.android.exoplayer2.metadata.id3.ApicFrame;
import com.google.android.exoplayer2.metadata.id3.GeobFrame;
import com.google.android.exoplayer2.metadata.id3.Id3Frame;
import com.google.android.exoplayer2.metadata.id3.PrivFrame;
import com.google.android.exoplayer2.metadata.id3.TextInformationFrame;
import com.google.android.exoplayer2.metadata.id3.TxxxFrame;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelector;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;

import java.io.IOException;
import java.util.Map;
import java.util.List;

public class RNAudioStreamerModule extends ReactContextBaseJavaModule implements ExoPlayer.EventListener, MetadataRenderer.Output<List<Id3Frame>>, ExtractorMediaSource.EventListener{

    public RNAudioStreamerModule(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    // Player
    private SimpleExoPlayer player = null;
    private String status = "STOPPED";

    // Status
    public static final String PLAYING = "PLAYING";
    public static final String PAUSED = "PAUSED";
    public static final String STOPPED = "STOPPED";
    public static final String FINISHED = "FINISHED";
    public static final String BUFFERING = "BUFFERING";
    public static final String ERROR = "ERROR";

    @Override public String getName() {
        return "RNAudioStreamer";
    }

    @ReactMethod public void setUrl(String urlString) {

        if (player != null){
            player.stop();
            player = null;
            status = "STOPPED";
        }

        // Create player
        Handler mainHandler = new Handler();
        TrackSelector trackSelector = new DefaultTrackSelector(mainHandler);
        LoadControl loadControl = new DefaultLoadControl();
        this.player = ExoPlayerFactory.newSimpleInstance(this.getReactApplicationContext(), trackSelector, loadControl);

        // Create source
        ExtractorsFactory extractorsFactory = new DefaultExtractorsFactory();
        DefaultBandwidthMeter bandwidthMeter = new DefaultBandwidthMeter();
        DataSource.Factory dataSourceFactory = new DefaultDataSourceFactory(this.getReactApplicationContext(), getDefaultUserAgent(), bandwidthMeter);
        MediaSource audioSource = new ExtractorMediaSource(Uri.parse(urlString), dataSourceFactory, extractorsFactory, mainHandler, this);

        // Start preparing audio
        player.prepare(audioSource);
        player.addListener(this);
        player.setId3Output(this);
    }

    @ReactMethod public void play() {
        Assertions.assertNotNull(player);
        player.setPlayWhenReady(true);
    }

    @ReactMethod public void pause() {
        Assertions.assertNotNull(player);
        player.setPlayWhenReady(false);
    }

    @ReactMethod public void seekToTime(double time) {
        Assertions.assertNotNull(player);
        player.seekTo((long)time * 1000);
    }

    @ReactMethod public void currentTime(Callback callback) {
        if (player == null){
            callback.invoke(null,(double)0);
        }else{
            callback.invoke(null,(double)(player.getCurrentPosition()/1000));
        }
    }

    @ReactMethod public void status(Callback callback) {
        callback.invoke(null,status);
    }

    @ReactMethod public void duration(Callback callback) {
        if (player == null){
            callback.invoke(null,(double)0);
        }else{
            callback.invoke(null,(double)(player.getDuration()/1000));
        }
    }

    @Override
    public void onPlayerStateChanged(boolean playWhenReady, int playbackState) {
        Log.d("onPlayerStateChanged", ""+playbackState);

        switch (playbackState) {
            case ExoPlayer.STATE_IDLE:
                status = STOPPED;
                break;
            case ExoPlayer.STATE_BUFFERING:
                status = BUFFERING;
                break;
            case ExoPlayer.STATE_READY:
                if (this.player != null && this.player.getPlayWhenReady()) {
                    status = PLAYING;
                } else {
                    status = PAUSED;
                }
                break;
            case ExoPlayer.STATE_ENDED:
                status = FINISHED;
                break;
        }
    }

    @Override
    public void onPlayerError(ExoPlaybackException error) {
        status = ERROR;
    }

    @Override
    public void onPositionDiscontinuity() {

    }

    @Override
    public void onLoadingChanged(boolean isLoading) {
        if (isLoading == true){
            status = BUFFERING;
            return;
        }else if (this.player != null){
            if (this.player.getPlayWhenReady()) {
                status = PLAYING;
            } else {
                status = PAUSED;
            }
        }else{
            status = STOPPED;
        }
    }

    @Override
    public void onLoadError(IOException error) {
        status = ERROR;
    }

    @Override
    public void onTimelineChanged(Timeline timeline, Object manifest) {}

    @Override
    public void onMetadata(List<Id3Frame> id3Frames) {}

    private static String getDefaultUserAgent() {
        StringBuilder result = new StringBuilder(64);
        result.append("Dalvik/");
        result.append(System.getProperty("java.vm.version")); // such as 1.1.0
        result.append(" (Linux; U; Android ");

        String version = Build.VERSION.RELEASE; // "1.0" or "3.4b5"
        result.append(version.length() > 0 ? version : "1.0");

        // add the model for the release build
        if ("REL".equals(Build.VERSION.CODENAME)) {
            String model = Build.MODEL;
            if (model.length() > 0) {
                result.append("; ");
                result.append(model);
            }
        }
        String id = Build.ID; // "MASTER" or "M4-rc20"
        if (id.length() > 0) {
            result.append(" Build/");
            result.append(id);
        }
        result.append(")");
        return result.toString();
    }
}