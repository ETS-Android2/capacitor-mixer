package com.skylabs.mixer;

import android.Manifest;
import android.content.Context;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.media.audiofx.Visualizer;
import android.os.Build;
import android.util.Log;

import com.getcapacitor.JSObject;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;
import com.getcapacitor.annotation.CapacitorPlugin;
import com.getcapacitor.annotation.Permission;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Supplier;
import java.util.stream.Stream;

@CapacitorPlugin(
        permissions={
            @Permission(strings={Manifest.permission.WRITE_EXTERNAL_STORAGE}),
            @Permission(strings={Manifest.permission.READ_PHONE_STATE}),
            @Permission(strings={Manifest.permission.MODIFY_AUDIO_SETTINGS}),
            @Permission(strings={Manifest.permission.RECORD_AUDIO})
})

public class Mixer extends Plugin {
    public Context _context;
    private Map<String, AudioFile> audioFileList = new HashMap<String, AudioFile>();
    private Map<String, MicInput> micInputList = new HashMap<String, MicInput>();
    private String audioSessionListenerName = "";
    public AudioManager audioManager;
    public AudioDeviceInfo preferredDevice;


    @Override
    public void load() {
        _context = this.getContext();
        audioManager = (AudioManager) _context.getSystemService(Context.AUDIO_SERVICE);
    }

    //TODO: write utility to check if file or mic input is null

    @PluginMethod
    public void initAudioSession(PluginCall call) {
        if (android.os.Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            List<AudioDeviceInfo> deviceInfoList = Arrays.asList(audioManager.getDevices(AudioManager.GET_DEVICES_ALL));
            for (AudioDeviceInfo device : deviceInfoList) {
                Log.i("DeviceList", String.valueOf(device));
            }
            Supplier<Stream<AudioDeviceInfo>> options = () -> deviceInfoList.stream().filter(deviceInfo -> deviceInfo.getType() == AudioDeviceInfo.TYPE_USB_DEVICE);
            if (options.get().count() > 0) {
                preferredDevice = options.get().findFirst().get();
            } else {
                Log.e("From initAudioSession:", "Preferred Device was not found");
            }
//            preferredDevice = deviceInfoList.stream().filter(deviceInfo -> deviceInfo.getType() == AudioDeviceInfo.TYPE_USB_DEVICE).findFirst().get();
        }

        call.resolve(buildBaseResponse(true, "not implemented Android", (JSObject)null));
        return;
    }

    @PluginMethod
    public void deinitAudioSession(PluginCall call) {

    }

    @PluginMethod
    public void restartPlugin(PluginCall call) {

    }

    @PluginMethod
    public void getAudioSessionPreferredInputPortType(PluginCall call) {

    }

    @PluginMethod
    public void initMicInput(PluginCall call) {
        String audioId;
        int channelNumber;
        if ((audioId = getAudioId(call, "initMicInput")) == null) { return; }
        if (micInputList.containsKey(audioId)) {
            call.resolve(buildBaseResponse(false, "from initMicInput - audioId already in use"));
            return;
        }
        channelNumber = call.getInt("channelNumber", -1);
        if (channelNumber == -1) {
            call.resolve(buildBaseResponse(false, "from initMicInput - no channel number"));
            return;
        }

        EqSettings eqSettings = new EqSettings();
        ChannelSettings channelSettings = new ChannelSettings();

        eqSettings.bassGain = call.getDouble("bassGain", 0.0);
        eqSettings.bassFrequency = call.getDouble("bassFrequency", 200.0);
        eqSettings.midGain = call.getDouble("midGain", 0.0);
        eqSettings.midFrequency = call.getDouble("midFrequency", 1499.0);
        eqSettings.trebleGain = call.getDouble("trebleGain", 0.0);
        eqSettings.trebleFrequency = call.getDouble("trebleFrequency", 20000.0);

        channelSettings.volume = call.getDouble("volume", 1.0);
        channelSettings.channelListenerName = call.getString("channelListenerName", "");
        channelSettings.eqSettings = eqSettings;
        channelSettings.channelNumber = channelNumber;

        micInputList.put(audioId, new MicInput(this));
        MicInput micObject = micInputList.get(audioId);
        micObject.setupAudio(audioId, channelSettings);
        call.resolve(buildBaseResponse(true, "mic was successfully initialized"));
    }

    @PluginMethod
    public void destroyMicInput(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "destroyMicInput")) == null) { return; }
    }

    @PluginMethod
    public void initAudioFile(PluginCall call) {
        String audioId;
        String filePath;
        if ((audioId = getAudioId(call, "initAudioFile")) == null) { return; }
        if (audioFileList.containsKey(audioId)) {
            call.resolve(buildBaseResponse(false, "from initAudioFile - audioId already in use"));
            return;
        }

        filePath = call.getString("filePath", "");
        if (filePath.isEmpty()) {
            call.resolve(buildBaseResponse(false, "from initAudioFile - filepath not found"));
            return;
        }

        EqSettings eqSettings = new EqSettings();
        ChannelSettings channelSettings = new ChannelSettings();

        eqSettings.bassGain = call.getDouble("bassGain", 0.0);
        eqSettings.bassFrequency = call.getDouble("bassFrequency", 200.0);
        eqSettings.midGain = call.getDouble("midGain", 0.0);
        eqSettings.midFrequency = call.getDouble("midFrequency", 1499.0);
        eqSettings.trebleGain = call.getDouble("trebleGain", 0.0);
        eqSettings.trebleFrequency = call.getDouble("trebleFrequency", 20000.0);

        channelSettings.volume = call.getDouble("volume", 1.0);
        channelSettings.channelListenerName = call.getString("channelListenerName", "");
        channelSettings.eqSettings = eqSettings;

        audioFileList.put(audioId, new AudioFile(this));
        AudioFile audioObject = audioFileList.get(audioId);
        audioObject.setupAudio(filePath, channelSettings);
        call.resolve(buildBaseResponse(true, "audio file was successfully initialized"));
    }

    @PluginMethod
    public void destroyAudioFile(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "destroyAudioFile")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        Map<String, Object> response = audioObject.destroy();
        call.resolve(buildBaseResponse(true, "audioFile destroyed", Utils.buildResponseData(response)));
    }

    @PluginMethod
    public void isPlaying(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "isPlaying")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        boolean playingResponse = audioObject.isPlaying();
        JSObject response = new JSObject();
        response.put("value", playingResponse);
        call.resolve(buildBaseResponse(true, "audioFile is playing", response));
    }


    @PluginMethod
    public void play(PluginCall call) {
        //TODO: checkAudioSessionInit
        String audioId;
        if ((audioId = getAudioId(call, "play")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        final String result = audioObject.playOrPause();
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>() {{
            put("state", result);
        }});
        call.resolve(buildBaseResponse(true, "playing or pausing playback", data));
    }

    @PluginMethod
    public void stop(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "stop")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        final String result = audioObject.stop();
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>() {{
            put("state", result);
        }});
        call.resolve(buildBaseResponse(true, "stopping playback", data));
        //TODO: checkAudioSessionInit
    }

    @PluginMethod
    public void adjustVolume(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "adjustVolume")) == null) { return; }
        double volume = call.getDouble("volume", -1.0);
        String inputType = call.getString("inputType", "");

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

    @PluginMethod
    public void getCurrentVolume(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "getCurrentVolume")) == null) { return; }

        String inputType = call.getString("inputType", "");
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
            put("volume", result);
        }});
        call.resolve(buildBaseResponse(true, "Here is the current volume", data));
    }

    @PluginMethod
    public void adjustEq(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "getCurrentVolume")) == null) { return; }
        String filterType = call.getString("eqType");
        double gain = call.getDouble("gain", -100.0);
        double freq = call.getDouble("frequency", -1.0);
        String inputType = call.getString("inputType");

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

    @PluginMethod
    public void getCurrentEq(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "getCurrentEq")) == null) { return; }
        String inputType = call.getString("inputType");
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

    @PluginMethod
    public void setElapsedTimeEvent(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "setElapsedTimeEvent")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        String eventName = call.getString("eventName", "");
        if (eventName.isEmpty()) {
            call.resolve(buildBaseResponse(false, "from setElapsedTimeEvent - eventName not found"));
            return;
        }
        AudioFile audioObject = audioFileList.get(audioId);
        audioObject.setElapsedTimeEvent(eventName);
        call.resolve(buildBaseResponse(true, "set elapsed time event"));
    }

    @PluginMethod
    public void getElapsedTime(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "getElapsedTime")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        final Map<String, Object> result;
        AudioFile audioObject = audioFileList.get(audioId);
        result = audioObject.getElapsedTime();
        JSObject data = Utils.buildResponseData(result);
        call.resolve(buildBaseResponse(true, "got elapsed time", data));
    }

    @PluginMethod
    public void getTotalTime(PluginCall call) {
        String audioId;
        if ((audioId = getAudioId(call, "getTotalTime")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        final Map<String, Object> result;
        AudioFile audioObject = audioFileList.get(audioId);
        result = audioObject.getTotalTime();
        JSObject data = Utils.buildResponseData(result);
        call.resolve(buildBaseResponse(true, "got total time", data));
    }

    @PluginMethod
    public void getInputChannelCount(PluginCall call) {
        //TODO: implement channel count response
        //TODO: implement deviceName response
        final double channelCount;
        channelCount = 2.0;
        final String deviceName;
        deviceName = "stardust";
        JSObject data = Utils.buildResponseData(new HashMap<String, Object>(){{
            put("channelCount", channelCount);
            put("deviceName", deviceName);
        }});
        call.resolve(buildBaseResponse(true, "got input channel count and device name", data));
    }

    public void notifyPluginListeners(String eventName, JSObject data) {
        notifyListeners(eventName, data);
    }

    private JSObject buildBaseResponse(Boolean wasSuccessful, String message, JSObject data) {
        JSObject response = buildBaseResponse(wasSuccessful, message);
        response.put("data", data);
        return response;
    }

    private JSObject buildBaseResponse(Boolean wasSuccessful, String message, EqSettings eqData) {
        JSObject response = buildBaseResponse(wasSuccessful, message);
        response.put("data", eqData);
        return response;
    }

    private JSObject buildBaseResponse(Boolean wasSuccessful, String message) {
        JSObject response = new JSObject();
        response.put("status", wasSuccessful ? "success" : "error");
        response.put("message", message);
        return response;
    }

    private String getAudioId(PluginCall call, String functionName) {
        String audioId = call.getString("audioId", "");
        if (audioId.isEmpty()) {
            call.resolve(buildBaseResponse(false, String.format("from %s, audioId not found", functionName)));
            return null;
        }
        return audioId;
    }

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
}
