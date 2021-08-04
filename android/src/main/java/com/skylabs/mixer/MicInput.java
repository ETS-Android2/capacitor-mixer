package com.skylabs.mixer;

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
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;

public class MicInput {
    Mixer _parent;
    private AudioRecord recorder;
    private DynamicsProcessing.Eq eq;
    private DynamicsProcessing dp;
    private byte[] audioData;
    private boolean recording = false;
    private String listenerName = "";
    private AudioTrack audioTrack;
    private double currentVolume;
    private String audioFileName = "";
    private File file;
    private File path;

    public MicInput(Mixer parent) {
        _parent = parent;
    }

    public void setupAudio(String audioId, ChannelSettings channelSettings) {
        audioFileName = "temp_" + audioId + ".mp3";
        recorder = new AudioRecord(MediaRecorder.AudioSource.MIC,
                AudioFormat.SAMPLE_RATE_UNSPECIFIED,
                AudioFormat.CHANNEL_IN_MONO,
                AudioFormat.ENCODING_PCM_FLOAT, 1024);
        audioData = new byte[1024];
        recording = true;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            recorder.setPreferredDevice(_parent.preferredDevice);
        }
        setupEq(channelSettings);
    }

    private void startRecording() {
        // TODO: create a getFileName GUID
        path = _parent._context.getFilesDir();
        file = new File(path, audioFileName);
        OutputStream os = null;
        try {
            os = new FileOutputStream(file);
        } catch(FileNotFoundException e) {
            e.printStackTrace();
        }
        int read = 0;
        while (recording) {
            read = recorder.read(audioData,0,1024);
            if(AudioRecord.ERROR_INVALID_OPERATION != read){
                try {
                    os.write(audioData);
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }

        try {
            os.close();
        } catch (IOException io) {
            io.printStackTrace();
        }
    }

    private void playRecording(ChannelSettings channelSettings) {
        // TODO: create a getFileName GUID
        byte[] audioData = null;
        try {
            InputStream inputStream = new FileInputStream(file);
//            int minBufferSize = AudioTrack.getMinBufferSize(AudioFormat.SAMPLE_RATE_UNSPECIFIED, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT);
//            audioData = new byte[minBufferSize];
//            audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC,
//                                       AudioFormat.SAMPLE_RATE_UNSPECIFIED,
//                                       AudioFormat.CHANNEL_OUT_MONO,
//                                       AudioFormat.ENCODING_PCM_FLOAT,
//                                       minBufferSize,
//                                       AudioTrack.MODE_STREAM);
            audioTrack.setVolume((float) channelSettings.volume);
            currentVolume = channelSettings.volume;
            audioTrack.play();
            
            int i=0;
            while((i = inputStream.read(audioData)) != -1) {
                audioTrack.write(audioData,0,i);
            }

        } catch(FileNotFoundException fe) {
            Log.e("playRecording exception","File not found");
        } catch(IOException io) {
            Log.e("playRecording exception","IO Exception");
        }
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
            Log.i("SetupEq, audioSessionId", String.valueOf(recorder.getAudioSessionId()));
            DynamicsProcessing.Config config = new DynamicsProcessing.Config.Builder(
                    DynamicsProcessing.VARIANT_FAVOR_FREQUENCY_RESOLUTION,
                    1,
                    false, 0,
                    false, 0,
                    true, 3,
                    false
            ).setPreferredFrameDuration(10).build();
            configureEngine(channelSettings, config);
        }
    }

    private void configureEngine(ChannelSettings channelSettings, DynamicsProcessing.Config config) {
        if (!channelSettings.channelListenerName.isEmpty()) {
            listenerName = channelSettings.channelListenerName;
        }
        int minBufferSize = AudioTrack.getMinBufferSize(44100, AudioFormat.CHANNEL_OUT_MONO, AudioFormat.ENCODING_PCM_FLOAT);
        audioData = new byte[minBufferSize];
        audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC,
                44100,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_FLOAT,
                minBufferSize,
                AudioTrack.MODE_STREAM);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            CompletableFuture.runAsync(() -> {
                    startRecording();
                    playRecording(channelSettings);
            });
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            dp = new DynamicsProcessing(0, audioTrack.getAudioSessionId(), config);
            dp.setPostEqAllChannelsTo(eq);
        }
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
        audioTrack.setVolume((float)volume);
        currentVolume = volume;
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


}
