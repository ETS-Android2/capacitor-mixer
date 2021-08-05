package com.skylabs.mixer;

import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.MediaPlayer;
import android.media.MediaRecorder;
import android.media.audiofx.DynamicsProcessing;
import android.os.Build;
import android.util.Log;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

public class MicInput {
    Mixer _parent;
    private DynamicsProcessing.Eq eq;
    private DynamicsProcessing dp;
    private double currentVolume;
    private String listenerName = "";

    private static final String APP_TAG = "Microphone";
    private static final int mSampleRate = 44100;
    private static final int mFormat = AudioFormat.ENCODING_PCM_16BIT;

    private AudioTrack mAudioOutput;
    private AudioRecord mAudioInput;
    private int mInBufferSize;
    public int mOutBufferSize;
    private static boolean mActive = false;

    public MicInput(Mixer parent) {
        _parent = parent;
    }

    public void setupAudio(String audioId, ChannelSettings channelSettings) {
        mInBufferSize  = AudioRecord.getMinBufferSize(mSampleRate, AudioFormat.CHANNEL_OUT_MONO , mFormat);
        mOutBufferSize = AudioTrack.getMinBufferSize(mSampleRate, AudioFormat.CHANNEL_OUT_MONO, mFormat);
        mAudioInput = new AudioRecord(MediaRecorder.AudioSource.MIC, mSampleRate, AudioFormat.CHANNEL_OUT_MONO, mFormat, mInBufferSize);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            mAudioInput.setPreferredDevice(_parent.preferredDevice);
        }
        mAudioOutput = new AudioTrack(AudioManager.STREAM_MUSIC, mSampleRate, AudioFormat.CHANNEL_OUT_MONO, mFormat, mOutBufferSize, AudioTrack.MODE_STREAM);
        setupEq(channelSettings);
    }

    private void setupEq(ChannelSettings channelSettings) {
        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.P) {
            DynamicsProcessing.EqBand bassEq = new DynamicsProcessing.EqBand(true, (float)channelSettings.eqSettings.bassFrequency, (float)channelSettings.eqSettings.bassGain);
            DynamicsProcessing.EqBand midEq = new DynamicsProcessing.EqBand(true, (float)channelSettings.eqSettings.midFrequency, (float)channelSettings.eqSettings.midGain);
            DynamicsProcessing.EqBand trebleEq = new DynamicsProcessing.EqBand(true, (float)channelSettings.eqSettings.trebleFrequency, (float)channelSettings.eqSettings.trebleGain);
            eq = new DynamicsProcessing.Eq(true, true, 3);
            eq.setBand(0, bassEq);
            eq.setBand(1, midEq);
            eq.setBand(2, trebleEq);
            DynamicsProcessing.Config config = new DynamicsProcessing.Config.Builder(
                    DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                    1,
                    false, 0,
                    false, 0,
                    true, 3,
                    false
            ).setPreferredFrameDuration(10).build();
            dp = new DynamicsProcessing(0, mAudioOutput.getAudioSessionId(), config);
            dp.setPostEqAllChannelsTo(eq);
            configureEngine(channelSettings);
        }
    }

    private void configureEngine(ChannelSettings channelSettings) {
        if (!channelSettings.channelListenerName.isEmpty()) {
            listenerName = channelSettings.channelListenerName;
        }
        record();
    }

    public void handleMetering() {

    }

    public void handleInputBuffer() {

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
        currentVolume = volume;
        mAudioOutput.setVolume((float)volume);
    }

    public double getCurrentVolume() {
        return currentVolume;
    }

    public void adjustEq(String type, double gain, double freq) {

    }

    public Map<String, Object> getCurrentEq() {
        return new HashMap<String, Object>();
    }


    public void interrupt() {

    }

    public void resumeFromInterrupt() {

    }

    public void destroy() {

    }

    public void record() {
        Thread t = new Thread() {
            public void run() {

                Log.d(APP_TAG, "Entered record loop");

                recordLoop();

                Log.d(APP_TAG, "Record loop finished");
            }

            private void recordLoop() {
                if ( mAudioOutput.getState() != AudioTrack.STATE_INITIALIZED || mAudioInput.getState() != AudioTrack.STATE_INITIALIZED) {
                    Log.d(APP_TAG, "Can't start. Race condition?");
                }
                else {

                    try {

                        try { mAudioOutput.play(); }          catch (Exception e) { Log.e(APP_TAG, "Failed to start playback"); return; }
                        try { mAudioInput.startRecording(); } catch (Exception e) { Log.e(APP_TAG, "Failed to start recording"); mAudioOutput.stop(); return; }

                        try {

                            ByteBuffer bytes = ByteBuffer.allocateDirect(mInBufferSize);
                            int o = 0;
                            byte b[] = new byte[mInBufferSize];
                            while(mActive) {
                                o = mAudioInput.read(bytes, mInBufferSize);
                                bytes.get(b);
                                bytes.rewind();
                                mAudioOutput.write(b, 0, o);
                            }

                            Log.d(APP_TAG, "Finished recording");
                        }
                        catch (Exception e) {
                            Log.d(APP_TAG, "Error while recording, aborting.");
                        }

                        try { mAudioOutput.stop(); } catch (Exception e) { Log.e(APP_TAG, "Can't stop playback"); mAudioInput.stop(); return; }
                        try { mAudioInput.stop();  } catch (Exception e) { Log.e(APP_TAG, "Can't stop recording"); return; }
                    }
                    catch (Exception e) {
                        Log.d(APP_TAG, "Error somewhere in record loop.");
                    }
                }
                try {
                } catch (IllegalArgumentException e) { Log.e(APP_TAG, "Receiver wasn't registered: " + e.toString()); }
            }
        };
        t.start();

    }


}
