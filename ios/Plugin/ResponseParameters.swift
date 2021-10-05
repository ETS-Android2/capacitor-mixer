//
//  ResponseParameters.swift
//  Plugin
//
//  Created by Skylabs Technology on 8/13/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation

/**
 * local constant mappings for response parameters
 */
public class ResponseParameters {
    // BaseResponse
    static var status: String = "status";
    static var message: String = "message";
    static var data: String = "data";

    // MixerTimeResponse
    static var milliSeconds: String = "milliSeconds";
    static var seconds: String = "seconds";
    static var minutes: String = "minutes";
    static var hours: String = "hours";

    // PlaybackStateResponse
    static var state: String = "state";

    // PlaybackStateBoolean
    static var value: String = "value";

    // VolumeResponse
    static var volume: String = "volume";

    // EqResponse
    static var bassGain: String = "bassGain";
    static var bassFrequency: String = "bassFrequency";
    static var midGain: String = "midGain";
    static var midFrequency: String = "midFrequency";
    static var trebleGain: String = "trebleGain";
    static var trebleFrequency: String = "trebleFrequency";

    // VolumeMeterResponse
    static var meterLevel: String = "meterLevel";

    // InitResponse
//    static var value: String = "value";

    // ChannelCountResponse
    static var channelCount: String = "channelCount";
    static var deviceName: String = "deviceName";

    // DestroyResponse
    static var listenerName: String = "listenerName";
    static var elapsedTimeEventName: String = "elapsedTimeEventName";

    // InitAudioSessionResponse
    static var preferredInputPortType: String = "preferredInputPortType";
    static var preferredInputPortName: String = "preferredInputPortName";
    static var preferredIOBufferDuration: String = "preferredIOBufferDuration";
    
    // FileValidationResponse
    static var isFileValid: String = "isFileValid";
    static var filePath: String = "filePath";

    // StateResponse
    // static var state: String = "state";
}
