package com.skylabs.mixer;

import android.Manifest;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbInterface;
import android.hardware.usb.UsbManager;
import android.media.AudioDeviceInfo;
import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioRouting;
import android.util.Log;

import com.getcapacitor.JSObject;
import com.getcapacitor.PermissionState;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;
import com.getcapacitor.annotation.PermissionCallback;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@CapacitorPlugin(
    permissions={
        @Permission(
            alias="storage",
            strings={
                Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE
            }
        ),
        @Permission(
            alias="audio",
            strings={
                Manifest.permission.RECORD_AUDIO,
                Manifest.permission.READ_PHONE_STATE
            }
        )
    }
)

public class Mixer extends Plugin {
    public Context _context;
    public AudioManager audioManager;
    public UsbManager usbManager;

    private final Map<String, AudioFile> audioFileList = new HashMap<>();
    private final Map<String, MicInput> micInputList = new HashMap<>();
    public String audioSessionListenerName = "";

    private boolean isAudioSessionActive = false;

    public AudioDeviceInfo preferredInputDevice;
    public Integer foundChannelMask = AudioFormat.CHANNEL_OUT_DEFAULT;
    public Integer foundChannelIndexMask;
    public Integer foundChannelCount = 1;
    public String inputPortType;
    public double ioBufferDuration;
    public AudioDeviceInfo preferredOutputDevice;


    public AudioRouting.OnRoutingChangedListener routingListener = router -> {
        AudioDeviceInfo currentRoutedDevice = router.getRoutedDevice();
        Log.i("Routed_Device: ", "current = " + String.valueOf(currentRoutedDevice));
        if(currentRoutedDevice == null) {
            micInputList.forEach((audioId, audioObject) -> {
                audioObject.interrupt();
            });
        }
        if(currentRoutedDevice != null) {
            micInputList.forEach((audioId, audioObject) -> {
                audioObject.resumeFromInterrupt();
            });
        }
    };

    @Override
    public void load() {
        _context = this.getContext();
        audioManager = (AudioManager) _context.getSystemService(Context.AUDIO_SERVICE);
        usbManager = (UsbManager) _context.getSystemService(Context.USB_SERVICE);
    }

    /**
     * Initializes audio session with selected port type
     *
     * Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)
     * @param call { String inputPortType; double ioBufferDuration; String audioSessionListenerName }
     */
    @PluginMethod
    public void initAudioSession(PluginCall call) {
        audioSessionListenerName = call.getString(RequestParameters.audioSessionListenerName, "");

        inputPortType = call.getString(RequestParameters.inputPortType, "");
        ioBufferDuration = call.getDouble(RequestParameters.ioBufferDuration, -1.0);

        int convertedInputPortType = getSelectedAudioInterface(inputPortType);

        handleUsbPermission();
        handlePreferredDevice(convertedInputPortType);

        String preferredInputPortName = "Default Mic";
        String preferredInputPortType = "builtInMic";
        if(preferredInputDevice != null) {
            setInputDeviceValues();
            preferredInputPortName = preferredInputDevice.getProductName().toString().trim();
            preferredInputPortType = inputPortType;
        }
        isAudioSessionActive = true;

        JSObject response = new JSObject();
        response.put(ResponseParameters.preferredInputPortName, preferredInputPortName);
        response.put(ResponseParameters.preferredInputPortType, preferredInputPortType);
        response.put(ResponseParameters.preferredIOBufferDuration, ioBufferDuration);

        call.resolve(buildBaseResponse(true, "successfully initialized audio session", response));
    }

    /**
     * Cancels audio session and resets selected port. Use prior to changing port type
     * @param call
     */
    @PluginMethod
    public void deinitAudioSession(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        preferredInputDevice = null;
        preferredOutputDevice = null;
        isAudioSessionActive = false;
        call.resolve(buildBaseResponse(true, "Successfully deinitialized audio session"));
    }

    /**
     * Resets plugin state back to its initial state
     *
     * CAUTION: This will completely wipe everything you have initialized from the plugin!
     * @param call
     */
    @PluginMethod
    public void resetPlugin(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        preferredInputDevice = null;
        preferredOutputDevice = null;
        isAudioSessionActive = false;
        audioFileList.forEach((audioId, audioObject) -> {
            audioObject.destroy();
        });
        micInputList.forEach((audioId, audioObject) -> {
            audioObject.destroy();
        });
        audioFileList.clear();
        micInputList.clear();
        call.resolve(buildBaseResponse(true, "Successfully restarted plugin to original state."));
    }

    /**
     * Returns a value describing the initialized port type for the audio session (usb, built-in, etc.)
     * @param call
     */
    @PluginMethod
    public void getAudioSessionPreferredInputPortType(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        JSObject response = new JSObject();
        String portType = Utils.convertAudioPortType(preferredInputDevice.getType());
        response.put(ResponseParameters.value, portType);
        call.resolve(buildBaseResponse(true, "Successfully got preferred input", response));
    }

    /**
     * Initializes microphone channel on mixer
     *
     * Returns AudioId string of initialized microphone input
     * @param call { String audioId;
     *             int channelNumber;
     *             double bassGain;
     *             double bassFrequency;
     *             double midGain;
     *             double midFrequency;
     *             double trebleGain;
     *             double trebleFrequency;
     *             double volume;
     *             String channelListenerName;
     *            }
     */
    @PluginMethod
    public void initMicInput(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        int channelNumber;
        if ((audioId = getAudioId(call, "initMicInput")) == null) { return; }
        if (micInputList.containsKey(audioId)) {
            call.resolve(buildBaseResponse(false, "audioId already in use"));
            return;
        }
        channelNumber = call.getInt(RequestParameters.channelNumber, -1);
        if (channelNumber == -1) {
            call.resolve(buildBaseResponse(false, "no channel number"));
            return;
        }

        EqSettings eqSettings = new EqSettings();
        ChannelSettings channelSettings = new ChannelSettings();

        eqSettings.bassGain = call.getDouble(RequestParameters.bassGain, 0.0);
        eqSettings.bassFrequency = call.getDouble(RequestParameters.bassFrequency, 200.0);
        eqSettings.midGain = call.getDouble(RequestParameters.midGain, 0.0);
        eqSettings.midFrequency = call.getDouble(RequestParameters.midFrequency, 1499.0);
        eqSettings.trebleGain = call.getDouble(RequestParameters.trebleGain, 0.0);
        eqSettings.trebleFrequency = call.getDouble(RequestParameters.trebleFrequency, 20000.0);

        channelSettings.volume = call.getDouble(RequestParameters.volume, 1.0);
        channelSettings.channelListenerName = call.getString(RequestParameters.channelListenerName, "");
        channelSettings.eqSettings = eqSettings;
        channelSettings.channelNumber = channelNumber;

        micInputList.put(audioId, new MicInput(this));
        MicInput micObject = micInputList.get(audioId);

        micObject.setupAudio(channelSettings);

        call.resolve(buildBaseResponse(true, "mic was successfully initialized"));
    }

    /**
     *De-initializes a mic input channel based on audioId
     *
     * Note: Once destroyed, the channel cannot be recovered
     * @param call { String audioId; }
     */
    @PluginMethod
    public void destroyMicInput(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "destroyMicInput")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
        MicInput audioObject = micInputList.get(audioId);
        Map<String, Object> response = audioObject.destroy();
        call.resolve(buildBaseResponse(true, "mic input destroyed", Utils.buildResponseData(response)));
    }

    /**
     * Returns AudioId string of initialized audio file
     * @param call { String audioId;
     *             int channelNumber;
     *             double bassGain;
     *             double bassFrequency;
     *             double midGain;
     *             double midFrequency;
     *             double trebleGain;
     *             double trebleFrequency;
     *             double volume;
     *             String channelListenerName;
     *            }
     */
    @PluginMethod
    public void initAudioFile(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        String filePath;
        if ((audioId = getAudioId(call, "initAudioFile")) == null) { return; }
        if (audioFileList.containsKey(audioId)) {
            call.resolve(buildBaseResponse(false, "audioId already in use"));
            return;
        }

        filePath = call.getString(RequestParameters.filePath, "");
        if (filePath.isEmpty()) {
            call.resolve(buildBaseResponse(false, "filepath not found"));
            return;
        }

        EqSettings eqSettings = new EqSettings();
        ChannelSettings channelSettings = new ChannelSettings();

        eqSettings.bassGain = call.getDouble(RequestParameters.bassGain, 0.0);
        eqSettings.bassFrequency = call.getDouble(RequestParameters.bassFrequency, 200.0);
        eqSettings.midGain = call.getDouble(RequestParameters.midGain, 0.0);
        eqSettings.midFrequency = call.getDouble(RequestParameters.midFrequency, 1499.0);
        eqSettings.trebleGain = call.getDouble(RequestParameters.trebleGain, 0.0);
        eqSettings.trebleFrequency = call.getDouble(RequestParameters.trebleFrequency, 20000.0);

        channelSettings.volume = call.getDouble(RequestParameters.volume, 1.0);
        channelSettings.channelListenerName = call.getString(RequestParameters.channelListenerName, "");
        channelSettings.eqSettings = eqSettings;

        audioFileList.put(audioId, new AudioFile(this));
        AudioFile audioObject = audioFileList.get(audioId);
        audioObject.setupAudio(filePath, channelSettings);
        call.resolve(buildBaseResponse(true, "audio file was successfully initialized"));
    }

    /**
     * De-initializes an audio file channel based on audioId
     *
     * Note: Once destroyed, the channel cannot be recovered
     * @param call { String audioId; }
     */
    @PluginMethod
    public void destroyAudioFile(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "destroyAudioFile")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        Map<String, Object> response = audioObject.destroy();
        call.resolve(buildBaseResponse(true, "audioFile destroyed", Utils.buildResponseData(response)));
    }

    /**
     * A boolean that returns the playback state of initialized audio file
     * @param call { String audioId; }
     */
    @PluginMethod
    public void isPlaying(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "isPlaying")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        boolean playingResponse = audioObject.isPlaying();
        JSObject response = new JSObject();
        response.put(ResponseParameters.value, playingResponse);
        call.resolve(buildBaseResponse(true, "audioFile is playing", response));
    }

    /**
     * Toggles playback and pause on an initialized audio file
     * @param call { String audioId; }
     */
    @PluginMethod
    public void play(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "play")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        final String result = audioObject.playOrPause();
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>() {{
            put(ResponseParameters.state, result);
        }});
        call.resolve(buildBaseResponse(true, "playing or pausing playback", data));
    }

    /**
     * Stops playback on a playing audio file
     * @param call { String audioId; }
     */
    @PluginMethod
    public void stop(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "stop")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        final String result = audioObject.stop();
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>() {{
            put(ResponseParameters.state, result);
        }});
        call.resolve(buildBaseResponse(true, "stopping playback", data));
    }

    /**
     * Adjusts volume for a channel
     * @param call { String audioId; double volume; String inputType; }
     */
    @PluginMethod
    public void adjustVolume(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "adjustVolume")) == null) { return; }
        double volume = call.getDouble(RequestParameters.volume, -1.0);
        String inputType = call.getString(RequestParameters.inputType, "");

        if (volume < 0) {
            call.resolve(buildBaseResponse(false, "in adjustVolume - volume cannot be less than zero percent"));
            return;
        }
        if (inputType.equals("file")) {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            audioObject.adjustVolume(volume);
        }
        else if (inputType.equals("mic")) {
            if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
            MicInput micObject = micInputList.get(audioId);
            micObject.adjustVolume(volume);
        }
        else {
            call.resolve(buildBaseResponse(false, "Could not find object at [audioId]"));
            return;
        }
        call.resolve(buildBaseResponse(true, "You are adjusting the volume"));
    }

    /**
     * Returns current volume of a channel as a number between 0 and 1
     * @param call { String audioId; String inputType; }
     */
    @PluginMethod
    public void getCurrentVolume(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "getCurrentVolume")) == null) { return; }

        String inputType = call.getString(RequestParameters.inputType, "");
        final double result;
        if (inputType.equals("file")) {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            result = audioObject.getCurrentVolume();
        }
        else if (inputType.equals("mic")) {
            if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
            MicInput micObject = micInputList.get(audioId);
            result = micObject.getCurrentVolume();
        }
        else {
            call.resolve(buildBaseResponse(false, "Could not find object at [audioId]"));
            return;
        }
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>(){{
            put(ResponseParameters.volume, result);
        }});
        call.resolve(buildBaseResponse(true, "Here is the current volume", data));
    }

    /**
     * Adjusts gain and frequency in bass, mid, and treble ranges for a channel
     * @param call { String audioId;
     *             String eqType;
     *             double gain;
     *             double frequency
     *             String inputType
     *             }
     */
    @PluginMethod
    public void adjustEq(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "getCurrentVolume")) == null) { return; }
        String filterType = call.getString(RequestParameters.eqType);
        double gain = call.getDouble(RequestParameters.gain, -100.0);
        double freq = call.getDouble(RequestParameters.frequency, -1.0);
        String inputType = call.getString(RequestParameters.inputType);

        if (filterType.isEmpty()) {
            call.resolve(buildBaseResponse(false, "from adjustEq - filter type not specified"));
            return;
        }
        if (gain < -100.0) {
            call.resolve(buildBaseResponse(false, "from adjustEq - gain too low"));
        }
        if (freq < -1.0) {
            call.resolve(buildBaseResponse(false, "from adjustEq - frequency not specified"));
        }
        if (inputType.equals("file")) {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            audioObject.adjustEq(filterType, gain, freq);
        }
        else if (inputType.equals("mic")) {
            if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
            MicInput micObject = micInputList.get(audioId);
            micObject.adjustEq(filterType, gain, freq);
        }
        else {
            call.resolve(buildBaseResponse(false, "Could not find object at [audioId]"));
            return;
        }
        call.resolve(buildBaseResponse(true, "You are adjusting EQ"));
    }

    /**
     * Returns an object with numeric values for gain and frequency in bass, mid, and treble ranges
     * @param call { String audioId; String inputType; }
     */
    @PluginMethod
    public void getCurrentEq(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "getCurrentEq")) == null) { return; }
        String inputType = call.getString(RequestParameters.inputType);
        final Map<String, Object> result;
//        final EqSettings result;
        if (inputType.equals("file")) {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            result = audioObject.getCurrentEq();
        }
        else if (inputType.equals("mic")) {
            if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
            MicInput micObject = micInputList.get(audioId);
            result = micObject.getCurrentEq();
        }
        else {
            call.resolve(buildBaseResponse(false, "Could not find object at [audioId]"));
            return;
        }
        JSObject data = Utils.buildResponseData(result);
        call.resolve(buildBaseResponse(true, "Here is the current EQ", data));
    }

    /**
     * Sets an elapsed time event name for a given audioId. Only applicable for audio files
     * @param call { String audioId; String eventName; }
     */
    @PluginMethod
    public void setElapsedTimeEvent(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "setElapsedTimeEvent")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        String eventName = call.getString(RequestParameters.eventName, "");
        if (eventName.isEmpty()) {
            call.resolve(buildBaseResponse(false, "from setElapsedTimeEvent - eventName not found"));
            return;
        }
        AudioFile audioObject = audioFileList.get(audioId);
        audioObject.setElapsedTimeEvent(eventName);
        call.resolve(buildBaseResponse(true, "set elapsed time event"));
    }

    /**
     * Returns an object representing hours, minutes, seconds, and milliseconds elapsed
     * @param call { String audioId; }
     */
    @PluginMethod
    public void getElapsedTime(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "getElapsedTime")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        final Map<String, Object> result;
        AudioFile audioObject = audioFileList.get(audioId);
        result = audioObject.getElapsedTime();
        JSObject data = Utils.buildResponseData(result);
        call.resolve(buildBaseResponse(true, "got elapsed time", data));
    }

    /**
     * Returns total time in an object of hours, minutes, seconds, and millisecond totals
     * @param call { String audioId; }
     */
    @PluginMethod
    public void getTotalTime(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String audioId;
        if ((audioId = getAudioId(call, "getTotalTime")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        final Map<String, Object> result;
        AudioFile audioObject = audioFileList.get(audioId);
        result = audioObject.getTotalTime();
        JSObject data = Utils.buildResponseData(result);
        call.resolve(buildBaseResponse(true, "got total time", data));
    }

    /**
     * Returns the channel count and name of the initialized audio device
     * @param call
     */
    @PluginMethod
    public void getInputChannelCount(PluginCall call) {
        if(!checkAudioSessionInit(call)) { return; }
        String deviceName = preferredInputDevice != null ? preferredInputDevice.getProductName().toString().trim() : "Default Mic";
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>() {{
            put(ResponseParameters.channelCount, foundChannelCount);
            put(ResponseParameters.deviceName, deviceName);
        }});
        call.resolve(buildBaseResponse(true, "got input channel count and device name", data));
    }

    /**
     * Requests permissions required by the mixer plugin
     *
     * - iOS: Permissions must be added to application in the Info Target Properties
     *
     * - Android: Permissions must be added to AndroidManifest.XML
     *
     * See README for additional information on permissions
     * @param call
     */
    @PluginMethod
    public void requestMixerPermissions(PluginCall call) {
        if (getPermissionState("storage") != PermissionState.GRANTED) {
            requestPermissionForAlias("storage", call, "storagePermissionCallback");
        }
        if (getPermissionState("audio") != PermissionState.GRANTED) {
            requestPermissionForAlias("audio", call, "audioPermissionCallback");
        }
        call.resolve(buildBaseResponse(true, "All required permissions granted."));
    }

    /**
     * Handles updating permissions for storage
     * @param call
     */
    @PermissionCallback
    private void storagePermissionCallback(PluginCall call) {
        try {
            if (getPermissionState("storage") == PermissionState.GRANTED) {

            } else {
                call.resolve(buildBaseResponse(false, "storage permissions needed from user"));
            }
        }
        catch (Exception e){
            call.resolve(buildBaseResponse(false, "storage permissions failed with exception: " +e.getMessage()));
        }

    }

    /**
     * Handles updating permissions for audio
     * @param call
     */
    @PermissionCallback
    private void audioPermissionCallback(PluginCall call) {
        try {
            if (getPermissionState("audio") == PermissionState.GRANTED) {

            } else {
                call.resolve(buildBaseResponse(false, "audio permissions needed from user"));
            }
        }
        catch (Exception e){
            call.resolve(buildBaseResponse(false, "audio permissions failed with exception: " +e.getMessage()));
        }
    }

    /**
     * Proxy method for child classes to notify JavaScript events
     * @param eventName
     * @param data
     */
    public void notifyPluginListeners(String eventName, JSObject data) {
        notifyListeners(eventName, data);
    }

    /**
     * Generic response builder
     * @param wasSuccessful
     * @param message
     * @param data
     * @return
     */
    private JSObject buildBaseResponse(Boolean wasSuccessful, String message, JSObject data) {
        JSObject response = buildBaseResponse(wasSuccessful, message);
        response.put(ResponseParameters.data, data);
        return response;
    }

    /**
     * Generic response builder without data parameter
     * @param wasSuccessful
     * @param message
     * @return
     */
    private JSObject buildBaseResponse(Boolean wasSuccessful, String message) {
        JSObject response = new JSObject();
        response.put(ResponseParameters.status, wasSuccessful ? "success" : "error");
        response.put(ResponseParameters.message, message);
        return response;
    }

    /**
     * Utility method to get audioId from CAPPlugin object
     *
     * Handles resolving method if no audioId found
     * @param call
     * @param functionName
     * @return
     */
    private String getAudioId(PluginCall call, String functionName) {
        String audioId = call.getString(RequestParameters.audioId, "");
        if (audioId.isEmpty()) {
            call.resolve(buildBaseResponse(false, String.format("from %s, audioId not found", functionName)));
            return null;
        }
        return audioId;
    }

    /**
     * Utility method to determine if audioId is being used in microphone or audio file lists
     *
     * Handles resolve if audioId not found in either list
     * @param call
     * @param audioId
     * @param type
     * @return
     */
    private boolean checkAudioIdExists(PluginCall call, String audioId, ListType type) {
        if(type == ListType.AUDIO_FILE) {
            if(!audioFileList.containsKey(audioId)){
                call.resolve(buildBaseResponse(false, "audioId not found in audioFileList"));
                return false;
            }
        }
        else if (type == ListType.MIC_INPUT){
            if(!micInputList.containsKey(audioId)){
                call.resolve(buildBaseResponse(false, "audioId not found in micInputList"));
                return false;
            }
        }
        return true;
    }

    /**
     * Utility method to determine if an audio session is active
     *
     * Handles resolve if audio session is not active
     * @param call
     * @return
     */
    private boolean checkAudioSessionInit(PluginCall call) {
        if (!isAudioSessionActive) {
            call.resolve(buildBaseResponse(false,"Must call initAudioSession prior to any other usage"));
            return false;
        }
        return true;
    }

    /**
     * Finds information about requested audio port type and sets global values to be used throughout application
     */
    private void setInputDeviceValues() {
        int[] channelMasks = preferredInputDevice.getChannelMasks();
        if(channelMasks.length > 0){
            if(channelMasks.length == 1){
                foundChannelMask = channelMasks[0];
            }
            else {
                foundChannelMask = Arrays.stream(channelMasks).findFirst().getAsInt();
            }
        }
        int[] channelIndexMasks = preferredInputDevice.getChannelIndexMasks();
        if(channelIndexMasks.length > 0){
            if(channelIndexMasks.length == 1){
                foundChannelIndexMask = channelIndexMasks[0];
            }
            else {
                foundChannelIndexMask = Arrays.stream(channelIndexMasks).findFirst().getAsInt();
            }
        }
        foundChannelCount = Collections.max(
                Arrays.stream(preferredInputDevice.getChannelCounts())
                        .boxed()
                        .collect(Collectors.toList())
        );
    }

    /**
     * Handles USB permissions if needed, based on passed-in requested port type
     */
    private void handleUsbPermission(){
        HashMap<String, UsbDevice> usbDeviceList = usbManager.getDeviceList();
        for (Map.Entry<String, UsbDevice> entry : usbDeviceList.entrySet()) {
            UsbDevice usbDevice = entry.getValue();
            boolean usbPermission = usbManager.hasPermission(usbDevice);
            int interfaceCount = usbDevice.getInterfaceCount();
            for (int x = 0; x < interfaceCount; x++){
                UsbInterface usbInterface = usbDevice.getInterface(x);
                Log.i("UsbInterface", usbInterface.toString());
            }
            Log.i("USB Device Permission", String.valueOf(usbPermission));
            if (!usbPermission) {
                PendingIntent permissionIntent = PendingIntent.getBroadcast(_context, 0, new Intent("com.android.mixer.USB_PERMISSION"), 0);
                usbManager.requestPermission(usbDevice, permissionIntent);
            }
        }
        return;
    }

    /**
     * Finds preferred device based on pased-in port type
     * @param convertedInputPortType
     */
    private void handlePreferredDevice(int convertedInputPortType){
        List<AudioDeviceInfo> deviceInfoList = Arrays.asList(audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS | AudioManager.GET_DEVICES_OUTPUTS));
        List<AudioDeviceInfo> options = deviceInfoList.stream().filter(deviceInfo -> deviceInfo.getType() == convertedInputPortType).collect(Collectors.toList());
        if (options.stream().count() > 0) {
            preferredInputDevice = options.stream().filter(item -> item.isSource()).findFirst().get();
            preferredOutputDevice = options.stream().filter(item -> item.isSink()).findFirst().get();
        } else {
            Log.e("From initAudioSession:", "Preferred Device was not found");
        }
    }

    /**
     * Finds audio device enum value based on passed-in port type
     * @param inputPortType
     * @return
     */
    private int getSelectedAudioInterface(String inputPortType) {
//        AVB = "avb",
//        PCI = "pci",
//        AIRPLAY = "airplay",
//        BLUETOOTH_LE = "bluetoothLE",
//        BUILT_IN_RECEIVER = "builtInReceiver",
//        BUILT_IN_SPEAKER = "builtInSpeaker",
//        CAR_AUDIO = "carAudio",
//        DISPLAY_PORT = "displayPort",
//        FIREWIRE = "firewire",
//        HEADPHONES = "headphones",
//        HEADSET_MIC = "headsetMic",
//        LINE_OUT = "lineOut",
//        THUNDERBOLT = "thunderbolt",
        if(inputPortType.equals("hdmi")) {
            return AudioDeviceInfo.TYPE_HDMI;
        }
        else if (inputPortType.equals("bluetoothA2DP")) {
            return AudioDeviceInfo.TYPE_BLUETOOTH_A2DP;
        }
        else if (inputPortType.equals("bluetoothHFP")) {
            return AudioDeviceInfo.TYPE_BLUETOOTH_SCO;
        }
        else if (inputPortType.equals("builtInMic")) {
            return AudioDeviceInfo.TYPE_BUILTIN_MIC;
        }
        else if (inputPortType.equals("headsetMicUsb")) {
            return AudioDeviceInfo.TYPE_USB_HEADSET;
        }
        else if (inputPortType.equals("headsetMicWired")) {
            return AudioDeviceInfo.TYPE_WIRED_HEADSET;
        }
        else if (inputPortType.equals("lineIn")) {
            return  AudioDeviceInfo.TYPE_LINE_ANALOG;
        }
        else if (inputPortType.equals("usbAudio")) {
            return AudioDeviceInfo.TYPE_USB_DEVICE;
        }
        else if (inputPortType.equals("virtual")) {
            return AudioDeviceInfo.TYPE_LINE_DIGITAL;
        }
        else {
            return AudioDeviceInfo.TYPE_UNKNOWN;
        }
    }
}
