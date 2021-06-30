//
//  InputBufferData.swift
//  Plugin
//
//  Created by Skylabs Technology on 6/29/21.
//  Copyright © 2021 Max Lynch. All rights reserved.
//

import Foundation
import AVFoundation

public class InputBufferData {
    var channel: UnsafeBufferPointer<UnsafeMutablePointer<Float>>?;
    var buffer: AVAudioPCMBuffer?;
    var data: [NSData] = [];
}
