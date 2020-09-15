/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

import Foundation
import AVFoundation

extension CarrierConnectionStatus {

    var status: Status {
        switch self {
        case .Connected:
            return .online
        case .Disconnected:
            return .offline
        }
    }
}

extension CarrierFriendInfo {

    func convert() -> FriendCellModel {
        FriendCellModel(id: userId ?? "no user id",
                        name: (name?.isEmpty == true ? "unknown" : name)!,
                        avatar: nil,
                        status: status.status)
    }
}

enum AudioOutputAvailablePort: CaseIterable {
    case headphones
    case bluetooth
    case builtInSpeaker
    case builtInMic
    case carAudio
}

func availableAudioRoutes() -> [AudioOutputAvailablePort] {
    var routes: [AudioOutputAvailablePort] = []

    if AVAudioSession.isHeadphonesConnected {
        routes.append(.headphones)
    }
    if AVAudioSession.isBluetoothConnected {
        routes.append(.bluetooth)
    }
    if AVAudioSession.isCarAudioConnected {
        routes.append(.carAudio)
    }
    if AVAudioSession.isBuiltInMic {
        routes.append(.builtInMic)
    }
    if AVAudioSession.isBuiltInSpeaker {
        routes.append(.builtInSpeaker)
    }
    return routes
}

extension AVAudioSession {

    static var isHeadphonesConnected: Bool {
        sharedInstance().isHeadphonesConnected
    }

    static var isBluetoothConnected: Bool {
        sharedInstance().isBluetoothConnected
    }

    static var isCarAudioConnected: Bool {
        sharedInstance().isCarAudioConnected
    }

    static var isBuiltInSpeaker: Bool {
        sharedInstance().isBuiltInSpeaker
    }

    static var isBuiltInMic: Bool {
        sharedInstance().isBuiltInMic
    }

    var isCarAudioConnected: Bool {
        !currentRoute.outputs.filter { $0.isCarAudio }.isEmpty
    }

    var isHeadphonesConnected: Bool {
        !currentRoute.outputs.filter { $0.isHeadphones }.isEmpty
    }

    var isBluetoothConnected: Bool {
        !currentRoute.outputs.filter { $0.isBluetooth }.isEmpty
    }

    var isBuiltInSpeaker: Bool {
        !currentRoute.outputs.filter { $0.isSpeaker }.isEmpty
    }

    var isBuiltInMic: Bool {
        !currentRoute.outputs.filter { $0.isBuiltInMic }.isEmpty
    }
}

extension AVAudioSessionPortDescription {

    var isHeadphones: Bool {
        [.headphones, .headsetMic].contains(portType)
    }

    var isBluetooth: Bool {
        [.bluetoothHFP, .bluetoothA2DP, .bluetoothLE].contains(portType)
    }

    var isCarAudio: Bool {
        portType == .carAudio
    }

    var isSpeaker: Bool {
        portType == .builtInSpeaker
    }

    var isBuiltInMic: Bool {
        portType == .builtInMic
    }
}
