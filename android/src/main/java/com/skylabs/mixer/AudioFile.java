package com.skylabs.mixer;
import android.content.res.AssetFileDescriptor;
import android.media.AudioAttributes;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.audiofx.DynamicsProcessing;
import android.media.audiofx.Visualizer;
import android.net.Uri;
import android.os.ParcelFileDescriptor;
import android.util.Log;
import android.media.audiofx.DynamicsProcessing.Eq;
import android.media.audiofx.DynamicsProcessing.EqBand;


import com.getcapacitor.JSObject;

import java.io.File;
import java.util.HashMap;
import java.util.Map;

import static com.skylabs.mixer.Utils.getPath;

public class AudioFile implements MediaPlayer.OnPreparedListener, MediaPlayer.OnCompletionListener {
    private Mixer _parent;
    private MediaPlayer player;
    private Eq eq;
    private DynamicsProcessing dp;
    private float currentVolume;
    public String elapsedTimeEventName = "";
    public String listenerName = "";

    private Visualizer visualizer;
    private boolean visualizerState = false;
    private Visualizer.MeasurementPeakRms measurementPeakRms;


    public AudioFile(Mixer parent) {
        _parent = parent;
        player = new MediaPlayer();
        player.setOnCompletionListener(this);
        player.setOnPreparedListener(this);
    }

    /**
     * Starts initialization of an MediaPlayer. Configures player then starts its listeners
     *
     * @param audioFilePath
     * @param channelSettings
     */
    public void setupAudio(String audioFilePath, ChannelSettings channelSettings) {
        try {
            Uri uri = Uri.parse(audioFilePath);
            String filePath = getPath(_parent._context, uri);
            File file = new File(filePath);
            ParcelFileDescriptor pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY);
            AssetFileDescriptor afd = new AssetFileDescriptor(pfd, 0, -1);
            player.setAudioAttributes(new AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_MEDIA)
                            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                            .setLegacyStreamType(AudioManager.STREAM_MUSIC)
                            .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                            .build()
            );
            player.setDataSource(afd.getFileDescriptor(), afd.getStartOffset(), afd.getLength());
            player.prepare();
            setupEq(channelSettings);
        }
        catch(Exception ex) {
            Log.e("setupAudio", "Exception thrown in setupAudio: " + ex);
        }
    }

    /**
     * Sets up EQ and attaches it to MediaPlayer
     *
     * @param channelSettings
     */
    private void setupEq(ChannelSettings channelSettings) {
        EqBand bassEq = new EqBand(true, (float)channelSettings.eqSettings.bassFrequency, (float)channelSettings.eqSettings.bassGain);
        EqBand midEq = new EqBand(true, (float)channelSettings.eqSettings.midFrequency, (float)channelSettings.eqSettings.midGain);
        EqBand trebleEq = new EqBand(true, (float)channelSettings.eqSettings.trebleFrequency, (float)channelSettings.eqSettings.trebleGain);
        eq = new Eq(true, true, 3);
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
        dp = new DynamicsProcessing(0, player.getAudioSessionId(), config);
        dp.setPostEqAllChannelsTo(eq);
        configureEngine(channelSettings);
    }

    /**
     * Completes remaing setup for MediaPlayer and enables EQ
     *
     * @param channelSettings
     */
    private void configureEngine(ChannelSettings channelSettings) {
        if (!channelSettings.channelListenerName.isEmpty()) {
            listenerName = channelSettings.channelListenerName;
        }
        if (!channelSettings.elapsedTimeEventName.isEmpty()) {
            setElapsedTimeEvent(channelSettings.elapsedTimeEventName);
        }
        dp.setEnabled(true);
        currentVolume = (float)channelSettings.volume;
        player.setVolume(currentVolume, currentVolume);
    }

    /**
     * Adds the elapsedTimeEventName and enables playback notifications for MediaPlayer elapsed time
     *
     * @param eventName
     */
    public void setElapsedTimeEvent(String eventName) {
        elapsedTimeEventName = eventName;
    }

    /**
     * Handles play or pause for MediaPlayer
     *
     * @return
     */
    public String playOrPause() {
        if (player.isPlaying()) {
            player.pause();
            if(visualizerState) {
                destroyVisualizerListener();
            }
            return "pause";
        } else {
            player.start();
            if(!visualizerState) {
                initVisualizerListener();
            }
            return "play";
        }
    }

    /**
     * Handles "stop" for MediaPlayer
     *
     * @return
     */
    public String stop() {
        if (player.isPlaying()) {
            player.pause();
        }
        player.seekTo(0);
        if(visualizerState) {
            destroyVisualizerListener();
        }
        return "stop";
    }

    /**
     * Returns MediaPlayer if it is playing
     *
     * @return
     */
    public boolean isPlaying() {
        return player.isPlaying();
    }

    /**
     * Changes volume for the MediaPlayer
     *
     * @param volume
     */
    public void adjustVolume(double volume) {
        currentVolume = (float)volume;
        player.setVolume(currentVolume, currentVolume);
    }

    /**
     * Returns current volume for MediaPlayer
     *
     * @return
     */
    public double getCurrentVolume() {
        return currentVolume;
    }

    /**
     * Changes EQ output associated with the MediaPlayer
     *
     * @param type
     * @param gain
     * @param freq
     */
    public void adjustEq(String type, double gain, double freq) {
        if (eq.getBandCount() < 1) {
            return;
        }
        if (type.equals("bass")) {
            EqBand bassEq = eq.getBand(0);
            bassEq.setGain((float) gain);
            bassEq.setCutoffFrequency((float) freq);
            eq.setBand(0, bassEq);
            dp.setPostEqAllChannelsTo(eq);
        }
        else if (type.equals("mid")) {
            EqBand midEq = eq.getBand(1);
            midEq.setGain((float) gain);
            midEq.setCutoffFrequency((float) freq);
            eq.setBand(1, midEq);
            dp.setPostEqAllChannelsTo(eq);
        }
        else if (type.equals("treble")) {
            EqBand trebleEq = eq.getBand(2);
            trebleEq.setGain((float) gain);
            trebleEq.setCutoffFrequency((float) freq);
            eq.setBand(2, trebleEq);
            dp.setPostEqAllChannelsTo(eq);
        }
        else {
            System.out.println("adjustEq: invalid eq type");
        }
    }

    /**
     * Returns current tracked EQ
     * @return
     */
    public Map<String, Object> getCurrentEq() {
        Map<String, Object> currentEq = new HashMap<String, Object>();
        currentEq.put(ResponseParameters.bassGain, eq.getBand(0).getGain());
        currentEq.put(ResponseParameters.bassFrequency, eq.getBand(0).getCutoffFrequency());
        currentEq.put(ResponseParameters.midGain, eq.getBand(1).getGain());
        currentEq.put(ResponseParameters.midFrequency, eq.getBand(1).getCutoffFrequency());
        currentEq.put(ResponseParameters.trebleGain, eq.getBand(2).getGain());
        currentEq.put(ResponseParameters.trebleFrequency, eq.getBand(2).getCutoffFrequency());
        return currentEq;
    }

    /**
     * Returns current elapsed time on MediaPlayer
     *
     * Note: This can be done automatically using setElapsedTimeEvent
     *
     * @return
     */
    public Map<String, Object> getElapsedTime() {
        // Is there an event I can subscribe to?
        Map<String, Object> elapsedTime = Utils.timeToDictionary(player.getCurrentPosition());
        return elapsedTime;
    }

    /**
     * Returns total time for the loaded track
     * @return
     */
    public Map<String, Object> getTotalTime() {
        Map<String, Object> totalTime = Utils.timeToDictionary(player.getDuration());
        return totalTime;
    }

    /**
     * Destroys object and resets state.
     *
     * @return
     */
    public Map<String, Object> destroy() {
        stop();
        player.stop();
        player.release();
        dp.release();
        Map<String, Object> response = new HashMap<String, Object>();
        response.put(ResponseParameters.listenerName, listenerName);
        response.put(ResponseParameters.elapsedTimeEventName, elapsedTimeEventName);
        return response;
    }

    /**
     * Handles when a track has completed.
     *
     * @param mediaPlayer
     */
    @Override
    public void onCompletion(MediaPlayer mediaPlayer) {
        try {
            stop();
        }
        catch (Exception ex) {
            Log.e("onCompletion AudioFile", "An error occurred in onCompletion. Exception: " + ex.getLocalizedMessage());
        }
    }

    /**
     * Handles when a track has been initialized
     * @param mediaPlayer
     */
    @Override
    public void onPrepared(MediaPlayer mediaPlayer) {
        try {
            player.seekTo(0);
        }
        catch (Exception ex) {
            Log.e("onPrepared AudioFile", "An error occurred in onPrepared. Exception: " + ex.getLocalizedMessage());
        }
    }

    /**
     * Starts listener for Audio metering.
     *
     * Note: this should only run when being used as it will run continuously in the background
     *       call destroyVisualizerListener to stop process.
     */
    private void initVisualizerListener() {
        if (listenerName.isEmpty()){
            return;
        }
        visualizer = new Visualizer(player.getAudioSessionId());
        visualizer.setScalingMode(Visualizer.SCALING_MODE_AS_PLAYED);
        visualizer.setMeasurementMode(Visualizer.MEASUREMENT_MODE_PEAK_RMS);
        visualizer.setCaptureSize(Visualizer.getCaptureSizeRange()[0]);
        measurementPeakRms = new Visualizer.MeasurementPeakRms();
        visualizer.setDataCaptureListener(new Visualizer.OnDataCaptureListener() {
            @Override
            public void onWaveFormDataCapture(Visualizer vis, byte[] bytes, int i) {
                if(visualizerState) {
                    visualizer.getMeasurementPeakRms(measurementPeakRms);
                    double measurement = (double)measurementPeakRms.mRms;
                    measurement = (measurement / 100) * (1 / currentVolume);
                    double response = measurement < -80 ? -80 : measurement;
                    JSObject data = new JSObject();
                    data.put(ResponseParameters.meterLevel, response);
                    _parent.notifyPluginListeners(listenerName, data);

                    if (!elapsedTimeEventName.isEmpty()) {
                        _parent.notifyPluginListeners(elapsedTimeEventName, Utils.buildResponseData(getElapsedTime()));
                    }
                }

            }

            @Override
            public void onFftDataCapture(Visualizer visualizer, byte[] bytes, int i) {
                Log.i("FFT Byte Array: ", String.valueOf(bytes[0]));
            }
        }, Visualizer.getMaxCaptureRate(), true, false);
        visualizer.setEnabled(true);
        visualizerState = true;
    }

    /**
     * Stop listener for audio metering.
     */
    private void destroyVisualizerListener() {
        if (listenerName.isEmpty()){
            return;
        }
        if (visualizerState) {
            visualizer.setDataCaptureListener(null, 0, false, false);
            visualizer.setEnabled(false);
            visualizerState = false;
            visualizer.release();
        }
        return;
    }
}
