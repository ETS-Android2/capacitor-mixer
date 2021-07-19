package com.skylabs.mixer;
import android.content.Context;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.MediaPlayer;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

public class AudioFile implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
    Mixer _parent;
    private MediaPlayer player;

    public AudioFile(Mixer parent) {
        _parent = parent;
        player = new MediaPlayer();
        player.setOnCompletionListener(this);
        player.setOnPreparedListener(this);

    }

    public void setupAudio(String audioFilePath, ChannelSettings channelSettings) {
        Context context = _parent._context;
        int identifier = context.getResources().getIdentifier(audioFilePath, "raw", context.getPackageName());
        AssetFileDescriptor afd = context.getResources().openRawResourceFd(identifier);
        try {
            player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            player.setAudioAttributes(new AudioAttributes.Builder()
                                                         .setUsage(AudioAttributes.USAGE_MEDIA)
                                                         .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                                         .build()
            );
            setupEq(channelSettings);
        }
        catch(Exception ex) {
            Log.e("setupAudio", "Exception thrown in setupAudio: " + ex);
        }
    }

    public void setupEq(ChannelSettings channelSettings) {

    }

    public void configureEngine(ChannelSettings channelSettings) {

    }

    public void scheduleAudioFile() {

    }

    public void handleMetering() {

    }

    public void setElapsedTimeEvent(String eventName) {

    }

    public String playOrPause() {
        return "placeholder";
    }

    public String stop() {
        return "placeholder";
    }

    public boolean isPlaying() {
        return true;
    }

    public void adjustVolume(double volume) {

    }

    public double getCurrentVolume() {
        return -1;
    }

    public void adjustEq(String type, double gain, double freq) {

    }

    public Map<String, Object> getCurrentEq() {
        return new HashMap<String, Object>();
    }

    public Map<String, Object> getElapsedTime() {
        return new HashMap<String, Object>();
    }

    public Map<String, Object> getTotalTime() {
        return new HashMap<String, Object>();
    }

    public Map<String, String> destroy() {
        return new HashMap<String, String>();
    }

    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {
        try {
            stop();
        }
        catch (Exception ex) {
            Log.e("onCompletion AudioFile", "An error occurred in onCompletion. Exception: " + ex.getLocalizedMessage());
        }
    }

    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        try {
            player.seekTo(0);
        }
        catch (Exception ex) {
            Log.e("onPrepared AudioFile", "An error occurred in onPrepared. Exception: " + ex.getLocalizedMessage());
        }
    }



}
