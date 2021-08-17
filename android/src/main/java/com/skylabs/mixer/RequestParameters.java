package com.skylabs.mixer;

/**
 * local constant mappings for request parameters
 */
public class RequestParameters {
    // BaseMixerRequest
    public static String audioId = "audioId";

    // InitChannelRequest
    public static String filePath = "filePath";
    public static String channelNumber = "channelNumber";
    public static String bassGain = "bassGain";
    public static String bassFrequency = "bassFrequency";
    public static String midGain = "midGain";
    public static String midFrequency = "midFrequency";
    public static String trebleGain = "trebleGain";
    public static String trebleFrequency = "trebleFrequency";
    public static String volume = "volume";
    public static String channelListenerName = "channelListenerName";
    public static String elapsedTimeEventName = "elapsedTimeEventName";

    // AdjustVolumeRequest
//    public static String volume = "volume";
    public static String inputType = "inputType";

    // AdjustEqRequest
    public static String eqType = "eqType";
    public static String gain = "gain";
    public static String frequency = "frequency";
//    public static String inputType = "inputType";

    // ChannelPropertyRequest
//    public static String inputType = "inputType";

    // SetEventRequest
    public static String eventName = "eventName";

    // InitAudioSessionRequest
    public static String inputPortType = "inputPortType";
    public static String ioBufferDuration = "ioBufferDuration";
    public static String audioSessionListenerName = "audioSessionListenerName";

}
