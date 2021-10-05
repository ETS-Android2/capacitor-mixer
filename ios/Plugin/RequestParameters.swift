//
//  RequestParameters.swift
//  Plugin
//
//  Created by Skylabs Technology on 8/13/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation

/**
 * local constant mappings for request parameters
 */
public class RequestParameters {
    // BaseMixerRequest
    static var audioId: String = "audioId";

    // InitChannelRequest
    static var filePath: String = "filePath";
    static var elapsedTimeEventName: String = "elapsedTimeEventName";
    static var channelNumber: String = "channelNumber";
    static var bassGain: String = "bassGain";
    static var bassFrequency: String = "bassFrequency";
    static var midGain: String = "midGain";
    static var midFrequency: String = "midFrequency";
    static var trebleGain: String = "trebleGain";
    static var trebleFrequency: String = "trebleFrequency";
    static var volume: String = "volume";
    static var channelListenerName: String = "channelListenerName";

    // AdjustVolumeRequest
    // static var volume = "volume";
    static var inputType: String = "inputType";

    // AdjustEqRequest
    static var eqType: String = "eqType";
    static var gain: String = "gain";
    static var frequency: String = "frequency";
    // static var inputType = "inputType";

    // ChannelPropertyRequest
    // static var inputType = "inputType";

    // SetEventRequest
    static var eventName: String = "eventName";

    // InitAudioSessionRequest
    static var inputPortType: String = "inputPortType";
    static var ioBufferDuration: String = "ioBufferDuration";
    static var audioSessionListenerName: String = "audioSessionListenerName";
    
    // FileValidationRequest
    // static var filePath: String = "filePath";

    // StreamRequest
    static var streamUrl: String = "streamUrl";
}
