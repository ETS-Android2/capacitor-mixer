package com.skylabs.mixer;

import java.util.HashMap;
import java.util.Map;

public class MicInput {
    Mixer _parent;
    public MicInput(Mixer parent) {
        _parent = parent;
    }

    public void setupAudio(ChannelSettings channelSettings) {

    }

    public void setupEq(ChannelSettings channelSettings) {

    }

    public void configureEngine(ChannelSettings channelSettings) {

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

    }

    public double getCurrentVolume() {
        return -1;
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
