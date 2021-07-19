package com.skylabs.mixer;

import android.content.Context;
import android.media.AudioManager;

import com.getcapacitor.JSObject;
import com.getcapacitor.NativePlugin;
import com.getcapacitor.Plugin;
import com.getcapacitor.PluginCall;
import com.getcapacitor.PluginMethod;

import java.util.HashMap;
import java.util.Map;

@NativePlugin
public class Mixer extends Plugin {
    public Context _context;
    private Map<String, AudioFile> audioFileList = new HashMap<String, AudioFile>();
    private Map<String, MicInput> micInputList = new HashMap<String, MicInput>();
    private String audioSessionListenerName = "";
    public AudioManager audioManager;


    Mixer(Context context) {
        _context = context;
        audioManager = (AudioManager) _context.getSystemService(Context.AUDIO_SERVICE);
    }

    //TODO: write utility to check if file or mic input is null

    @PluginMethod
    public void echo(PluginCall call) {
        String value = call.getString("value");

        JSObject ret = new JSObject();
        ret.put("value", value);
        call.success(ret);
    }

    @PluginMethod
    public void play(PluginCall call) {
        //TODO: checkAudioSessionInit
        String audioId;
        if ((audioId = getAudioId(call, "play")) == null) { return; }
        if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
        AudioFile audioObject = audioFileList.get(audioId);
        final String result = audioObject.playOrPause();
        JSObject data = buildResponseData(new HashMap<String, Object>() {{
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
        JSObject data = buildResponseData(new HashMap<String, Object>() {{
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
        if (inputType == "file") {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            audioObject.adjustVolume(volume);
        }
        else if (inputType == " mic") {
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
        if (inputType == "file") {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            result = audioObject.getCurrentVolume();
        }
        else if (inputType == "mic") {
            if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
            MicInput micObject = micInputList.get(audioId);
            result = micObject.getCurrentVolume();
        }
        else {
            call.resolve(buildBaseResponse(false, "Could not find object at [audioId]"));
            return;
        }
        JSObject data = buildResponseData(new HashMap<String, Object>(){{
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
        if (inputType == "file") {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            audioObject.adjustEq(filterType, gain, freq);
        }
        else if (inputType == "mic") {
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
        if (inputType == "file") {
            if(!checkAudioIdExists(call, audioId, ListType.AUDIO_FILE)){ return; };
            AudioFile audioObject = audioFileList.get(audioId);
            result = audioObject.getCurrentEq();
        }
        else if (inputType == "mic") {
            if(!checkAudioIdExists(call, audioId, ListType.MIC_INPUT)){ return; };
            MicInput micObject = micInputList.get(audioId);
            result = micObject.getCurrentEq();
        }
        else {
            call.resolve(buildBaseResponse(false, "Could not find object at [audioId]"));
            return;
        }
        JSObject data = buildResponseData(result);
        call.resolve(buildBaseResponse(true, "Here is the current EQ"));
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
        JSObject data = buildResponseData(result);
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
        JSObject data = buildResponseData(result);
        call.resolve(buildBaseResponse(true, "got total time", data));
    }

    @PluginMethod
    public void getInputChannelCount(PluginCall call) {
        //TODO: implement channel count response
        //TODO: implement deviceName response
        final double channelCount;
        channelCount = -1.0;
        final String deviceName;
        deviceName = "stardust";
        JSObject data = buildResponseData(new HashMap<String, Object>(){{
            put("channelCount", channelCount);
            put("deviceName", deviceName);
        }});
        call.resolve(buildBaseResponse(true, "got input channel count and device name", data));
    }

    private JSObject buildBaseResponse(Boolean wasSuccessful, String message, JSObject data) {
        JSObject response = buildBaseResponse(wasSuccessful, message);
        response.put("data", data);
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

    private JSObject buildResponseData(Map<String, Object> items) {
        JSObject response = new JSObject();
        for (Map.Entry<String, Object> entry : items.entrySet()) {
            response.put(entry.getKey(), entry.getValue());
        }
        return  response;
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

enum ListType {
    AUDIO_FILE,
    MIC_INPUT
}