package fm.indiecast.rnaudiostreamer;

import android.os.Handler;
import android.util.Log;
import android.os.Build;
import android.net.Uri;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import com.google.android.exoplayer2.DefaultLoadControl;
import com.google.android.exoplayer2.ExoPlaybackException;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.ExoPlayerFactory;
import com.google.android.exoplayer2.LoadControl;
import com.google.android.exoplayer2.SimpleExoPlayer;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.extractor.DefaultExtractorsFactory;
import com.google.android.exoplayer2.extractor.ExtractorsFactory;
import com.google.android.exoplayer2.source.ExtractorMediaSource;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.trackselection.DefaultTrackSelector;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;
import com.google.android.exoplayer2.trackselection.TrackSelector;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultBandwidthMeter;
import com.google.android.exoplayer2.upstream.DefaultDataSourceFactory;

import java.io.IOException;
import java.util.Map;
import java.util.List;

public class RNAudioStreamerModule extends ReactContextBaseJavaModule implements ExoPlayer.EventListener, ExtractorMediaSource.EventListener{

    // Player
    private SimpleExoPlayer player = null;
    private String status = "STOPPED";
    private ReactApplicationContext reactContext = null;

    public RNAudioStreamerModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;
    }

    // Status
    private static final String PLAYING = "PLAYING";
    private static final String PAUSED = "PAUSED";
    private static final String STOPPED = "STOPPED";
    private static final String FINISHED = "FINISHED";
    private static final String BUFFERING = "BUFFERING";
    private static final String ERROR = "ERROR";

    @Override public String getName() {
        return "RNAudioStreamer";
    }

    @ReactMethod public void setUrl(String urlString) {

        if (player != null){
            player.stop();
            player = null;
            status = "STOPPED";
            this.sendStatusEvent();
        }

        // Create player
        TrackSelector trackSelector = new DefaultTrackSelector();
        LoadControl loadControl = new DefaultLoadControl();
        this.player = ExoPlayerFactory.newSimpleInstance(reactContext, trackSelector, loadControl);

        // Create source
        ExtractorsFactory extractorsFactory = new DefaultExtractorsFactory();
        DefaultBandwidthMeter bandwidthMeter = new DefaultBandwidthMeter();
        DataSource.Factory dataSourceFactory = new DefaultDataSourceFactory(reactContext, getDefaultUserAgent(), bandwidthMeter);
        Handler mainHandler = new Handler();
        MediaSource audioSource = new ExtractorMediaSource(Uri.parse(urlString), dataSourceFactory, extractorsFactory, mainHandler, this);

        // Start preparing audio
        player.prepare(audioSource);
        player.addListener(this);
    }

    @ReactMethod public void play() {
        if(player != null) player.setPlayWhenReady(true);
    }

    @ReactMethod public void pause() {
        if(player != null) player.setPlayWhenReady(false);
    }

    @ReactMethod public void seekToTime(double time) {
        if(player != null) player.seekTo((long)time * 1000);
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
                this.sendStatusEvent();
                break;
            case ExoPlayer.STATE_BUFFERING:
                status = BUFFERING;
                this.sendStatusEvent();
                break;
            case ExoPlayer.STATE_READY:
                if (this.player != null && this.player.getPlayWhenReady()) {
                    status = PLAYING;
                    this.sendStatusEvent();
                } else {
                    status = PAUSED;
                    this.sendStatusEvent();
                }
                break;
            case ExoPlayer.STATE_ENDED:
                status = FINISHED;
                this.sendStatusEvent();
                break;
        }
    }

    @Override
    public void onPlayerError(ExoPlaybackException error) {
        status = ERROR;
        this.sendStatusEvent();
    }

    @Override
    public void onPositionDiscontinuity() {

    }

    @Override
    public void onLoadingChanged(boolean isLoading) {
        if (isLoading == true){
            status = BUFFERING;
            this.sendStatusEvent();
        }else if (this.player != null){
            if (this.player.getPlayWhenReady()) {
                status = PLAYING;
                this.sendStatusEvent();
            } else {
                status = PAUSED;
                this.sendStatusEvent();
            }
        }else{
            status = STOPPED;
            this.sendStatusEvent();
        }
    }

    @Override
    public void onLoadError(IOException error) {
        status = ERROR;
        this.sendStatusEvent();
    }

    @Override
    public void onTimelineChanged(Timeline timeline, Object manifest) {}

    @Override
    public void onTracksChanged(TrackGroupArray trackGroups, TrackSelectionArray trackSelections) {}

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

    private void sendStatusEvent() {
        this.reactContext
                .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                .emit("RNAudioStreamerStatusChanged", status);
    }
}