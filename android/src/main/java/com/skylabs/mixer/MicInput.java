package com.skylabs.mixer;

import android.media.AudioAttributes;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRecord;
import android.media.AudioTrack;
import android.media.MediaRecorder;
import android.media.MicrophoneInfo;
import android.media.audiofx.DynamicsProcessing;
import android.media.audiofx.Visualizer;
import android.util.Log;

import com.getcapacitor.JSObject;

import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class MicInput {
    private Mixer _parent;
    private DynamicsProcessing.Eq eq;
    private DynamicsProcessing dp;
    private double currentVolume;
    private String listenerName = "";
    private int selectedChannel;

    private static final String APP_TAG = "Microphone";
    private static final int mSampleRate = 44100;
    private static final int mFormat = AudioFormat.ENCODING_PCM_16BIT;

    private AudioTrack mAudioOutput;

    private AudioRecord mAudioInput;
    private int mInBufferSize;
    public int mOutBufferSize;
    private static boolean mActive = true;

    private Visualizer visualizer;
    private boolean visualizerState = false;
    private Visualizer.MeasurementPeakRms measurementPeakRms;

    private boolean isInterrupt = false;

    public MicInput(Mixer parent) {
        _parent = parent;
    }

    /**
     * Starts initialization of an Mic input. Configures AudioTrack and AudioRecord, then starts mic and its listeners
     *
     * @param channelSettings
     */
    public void setupAudio(ChannelSettings channelSettings) {
        selectedChannel = channelSettings.channelNumber;
        int mOutChannelFormat = getAudioOutFormatEnum(_parent.foundChannelCount);

        mInBufferSize  = AudioRecord.getMinBufferSize(mSampleRate, AudioFormat.CHANNEL_IN_DEFAULT, mFormat);
        mOutBufferSize = AudioTrack.getMinBufferSize(mSampleRate, mOutChannelFormat, mFormat);

        AudioFormat inAudioFormat;
        if(_parent.foundChannelIndexMask != null){
            inAudioFormat = new AudioFormat.Builder()
                    .setSampleRate(mSampleRate)
                    .setEncoding(mFormat)
                    .setChannelIndexMask(_parent.foundChannelIndexMask)
                    .build();
        }
        else {
            inAudioFormat = new AudioFormat.Builder()
                    .setSampleRate(mSampleRate)
                    .setEncoding(mFormat)
                    .setChannelMask(_parent.foundChannelMask)
                    .build();
        }

        mAudioInput = new AudioRecord.Builder()
                .setAudioFormat(inAudioFormat)
                .setAudioSource(MediaRecorder.AudioSource.MIC)
                .setBufferSizeInBytes(mInBufferSize)
                .build();
        AudioAttributes audioAttributes = new AudioAttributes.Builder()
                                                             .setUsage(AudioAttributes.USAGE_MEDIA)
                                                             .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                                                             .setLegacyStreamType(AudioManager.STREAM_MUSIC)
                                                             .setFlags(AudioAttributes.FLAG_AUDIBILITY_ENFORCED)
                                                             .build();
        AudioFormat outAudioFormat = new AudioFormat.Builder()
                                                 .setSampleRate(mSampleRate)
                                                 .setEncoding(mFormat)
                                                 .setChannelMask(mOutChannelFormat)
                                                 .build();
        mAudioOutput = new AudioTrack.Builder()
                                     .setAudioAttributes(audioAttributes)
                                     .setAudioFormat(outAudioFormat)
                                     .setBufferSizeInBytes(mOutBufferSize)
                                     .setTransferMode(AudioTrack.MODE_STREAM)
                                     //.setEncapsulationMode(AudioTrack.ENCAPSULATION_MODE_ELEMENTARY_STREAM)
                                     .setPerformanceMode(AudioTrack.PERFORMANCE_MODE_LOW_LATENCY)
                                     .setSessionId(_parent.audioManager.generateAudioSessionId())
                                     .build();
        if(_parent.preferredInputDevice != null) {
            mAudioInput.setPreferredDevice(_parent.preferredInputDevice);
        }

//        if(_parent.preferredOutputDevice != null) {
//            mAudioOutput.setPreferredDevice(_parent.preferredOutputDevice);
//        }
        setupEq(channelSettings);
    }

    /**
     * Sets up EQ and attaches it to AudioTrack object
     *
     * @param channelSettings
     */
    private void setupEq(ChannelSettings channelSettings) {
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

    /**
     * Completes remaining setup for AudioTrack and AudioRecord objects and enables EQ
     *
     * @param channelSettings
     */
    private void configureEngine(ChannelSettings channelSettings) {
        if (!channelSettings.channelListenerName.isEmpty()) {
            listenerName = channelSettings.channelListenerName;
        }
        currentVolume = channelSettings.volume;
        mAudioOutput.setVolume((float)channelSettings.volume);
        mAudioOutput.setPlaybackRate(mSampleRate);
        dp.setEnabled(true);
        initVisualizerListener();
        List<MicrophoneInfo> mics = null;
        try {
            mics = mAudioInput.getActiveMicrophones();
            Log.i("","");
        } catch (IOException e) {
            e.printStackTrace();
        }
        mAudioInput.addOnRoutingChangedListener(_parent.routingListener, null);
        record();
    }

    /**
     * Not Implemented for MicInput
     *
     * @return
     */
    public String playOrPause() {
        return "not implemented";
    }

    /**
     * Not Implemented for MicInput
     *
     * @return
     */
    public String stop() {
        return "not implemented";
    }

    /**
     * Always returns true for MicInput
     *
     * @return
     */
    public boolean isPlaying() {
        return true;
    }

    /**
     * Changes volume for the AudioTrack
     *
     * @param volume
     */
    public void adjustVolume(double volume) {
        currentVolume = volume;
        mAudioOutput.setVolume((float)volume);
    }

    /**
     * Returns current volume for AudioTrack
     *
     * @return
     */
    public double getCurrentVolume() {
        return currentVolume;
    }

    /**
     * Changes EQ output associated with the AudioTrack
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
            DynamicsProcessing.EqBand bassEq = eq.getBand(0);
            bassEq.setGain((float) gain);
            bassEq.setCutoffFrequency((float) freq);
            eq.setBand(0, bassEq);
            dp.setPostEqAllChannelsTo(eq);
        }
        else if (type.equals("mid")) {
            DynamicsProcessing.EqBand midEq = eq.getBand(1);
            midEq.setGain((float) gain);
            midEq.setCutoffFrequency((float) freq);
            eq.setBand(1, midEq);
            dp.setPostEqAllChannelsTo(eq);
        }
        else if (type.equals("treble")) {
            DynamicsProcessing.EqBand trebleEq = eq.getBand(2);
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
     *
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
     * Stops mic input temporarily and removes meter notifications and alerts listener.
     *
     * Note: processes will continue running for AudioRecord and AudioTrack in thread.
     * This should only be used temporarily
     */
    public void interrupt() {
        mAudioOutput.setVolume(0);
        if(visualizerState){
            destroyVisualizerListener();
        }
        JSObject response = new JSObject();
        response.put("handlerType", "ROUTE_DEVICE_DISCONNECTED");

        _parent.notifyPluginListeners(_parent.audioSessionListenerName, response);
    }

    /**
     * Resumes mic input and starts meter notifications and alerts listener.
     */
    public void resumeFromInterrupt() {
        mAudioOutput.setVolume((float)currentVolume);
        if(!visualizerState){
            initVisualizerListener();
        }
        JSObject response = new JSObject();
        response.put("handlerType", "ROUTE_DEVICE_RECONNECTED");

        _parent.notifyPluginListeners(_parent.audioSessionListenerName, response);
    }

    /**
     * Destroys object and resets state
     *
     * @return
     */
    public Map<String, Object> destroy() {
        if(visualizerState) {
            destroyVisualizerListener();
        }
        mActive = false;
        Map<String, Object> response = new HashMap<String, Object>();
        response.put(ResponseParameters.listenerName, listenerName);
        response.put(ResponseParameters.elapsedTimeEventName, "");
        return response;
    }

    /**
     * Starts AudioRecord and AudioTrack and starts metering in its own Thread
     */
    private void record() {
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
                        try { mAudioOutput.play(); } catch (Exception e) { Log.e(APP_TAG, "Failed to start playback"); return; }
                        try { mAudioInput.startRecording(); } catch (Exception e) { Log.e(APP_TAG,"Failed to start recording"); mAudioOutput.stop(); return; }

                        try {
                            ByteBuffer bytes = ByteBuffer.allocateDirect(mInBufferSize);
                            int o = 0;
                            byte[] b = new byte[mInBufferSize];
                            while(mActive) {
                                o = mAudioInput.read(bytes, (mInBufferSize));
                                bytes.get(b);
                                bytes.rewind();
                                b = removeUnusedChannels(selectedChannel, _parent.foundChannelCount, b);
                                mAudioOutput.write(b, 0, o);
                            }
                            Log.d(APP_TAG, "Finished recording");
                        }
                        catch (Exception e) {
                            Log.d(APP_TAG, "Error while recording, aborting.");
                        }
                        try {
                            if(isInterrupt){
                                mAudioOutput.pause();
                            }
                            else {
                                mAudioOutput.stop();
                            }

                        } catch (Exception e) {
                            Log.e(APP_TAG, "Can't stop playback");
                            mAudioInput.stop();
                            return;
                        }
                        try {
                            if(!isInterrupt){
//                                mAudioInput.stop();
                            }
                        } catch (Exception e) {
                            Log.e(APP_TAG, "Can't stop recording");
                            return;
                        }
                    }
                    catch (Exception e) {
                        Log.d(APP_TAG, "Error somewhere in record loop.");
                    }
                }
            }
            private byte[] removeUnusedChannels(int channelNumber, int totalChannels, byte[] buffer) {
                if(totalChannels == 1 ) return buffer;

                byte[] newBuffer = new byte[buffer.length];

                int offset = 2 * channelNumber;
                int totalChannelBytes = totalChannels * 2;

                for(int i = offset; i < buffer.length; i += totalChannelBytes){
                    newBuffer[i] = buffer[i];
                    newBuffer[i+1] = buffer[i+1];
                }
                return newBuffer;
            }
        };
        t.start();
    }

    /**
     * Tries to determine AudioFormat based on found number of channels
     *
     * @param numberOfChannels
     * @return
     */
    private int getAudioOutFormatEnum(int numberOfChannels){
        switch (numberOfChannels){
            case 1:
                return AudioFormat.CHANNEL_OUT_MONO;
            case 2:
                return AudioFormat.CHANNEL_OUT_STEREO;
            case 4:
                return AudioFormat.CHANNEL_OUT_QUAD;
            case 6:
                return AudioFormat.CHANNEL_OUT_5POINT1;
            case 8:
                return AudioFormat.CHANNEL_OUT_7POINT1_SURROUND;
            default:
                return  AudioFormat.CHANNEL_OUT_DEFAULT;
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
        if(!visualizerState){
            visualizer = new Visualizer(mAudioOutput.getAudioSessionId());
            visualizer.setScalingMode(Visualizer.SCALING_MODE_AS_PLAYED);
            visualizer.setMeasurementMode(Visualizer.MEASUREMENT_MODE_PEAK_RMS);
            visualizer.setCaptureSize(Visualizer.getCaptureSizeRange()[0]);
            measurementPeakRms = new Visualizer.MeasurementPeakRms();
            visualizer.setDataCaptureListener(new Visualizer.OnDataCaptureListener() {
                @Override
                public void onWaveFormDataCapture(Visualizer vis, byte[] bytes, int i) {
                    if(visualizerState){
                        visualizer.getMeasurementPeakRms(measurementPeakRms);
                        double measurement = (double)measurementPeakRms.mRms;
                        measurement = (measurement / 100) * (1 / currentVolume);
                        double response = measurement < -80 ? -80 : measurement;
                        JSObject data = new JSObject();
                        data.put(ResponseParameters.meterLevel, response);
                        _parent.notifyPluginListeners(listenerName, data);
                    }
                }

                @Override
                public void onFftDataCapture(Visualizer visualizer, byte[] bytes, int i) {
                    // Log.i("FFT Byte Array: ", String.valueOf(bytes[0]));
                }
            }, Visualizer.getMaxCaptureRate(), true, false);
            visualizer.setEnabled(true);
            visualizerState = true;
        }
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
    }
}
