package com.skylabs.mixer;

public class ResponseParameters {
    // BaseResponse
    public static String status = "status";
    public static String message = "message";
    public static String data = "data";

    // MixerTimeResponse
    public static String milliSeconds = "milliSeconds";
    public static String seconds = "seconds";
    public static String minutes = "minutes";
    public static String hours = "hours";

    // PlaybackStateResponse
    public static String state = "state";

    // PlaybackStateBoolean
    public static String value = "value";

    // VolumeResponse
    public static String volume = "volume";

    // EqResponse
    public static String bassGain = "bassGain";
    public static String bassFrequency = "bassFrequency";
    public static String midGain = "midGain";
    public static String midFrequency = "midFrequency";
    public static String trebleGain = "trebleGain";
    public static String trebleFrequency = "trebleFrequency";

    // VolumeMeterResponse
    public static String meterLevel = "meterLevel";

    // InitResponse
//    public static String value = "value";

    // ChannelCountResponse
    public static String channelCount = "channelCount";
    public static String deviceName = "deviceName";

    // DestroyResponse
    public static String listenerName = "listenerName";
    public static String elapsedTimeEventName = "elapsedTimeEventName";

    // InitAudioSessionResponse
    public static String preferredInputPortType = "preferredInputPortType";
    public static String preferredInputPortName = "preferredInputPortName";
    public static String preferredIOBufferDuration = "preferredIOBufferDuration";
}
