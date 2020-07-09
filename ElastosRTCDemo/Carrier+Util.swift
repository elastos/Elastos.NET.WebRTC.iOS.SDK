//
//  Carrier+Util.swift
//  ElastosRTCDemo
//
//  Created by idanzhu on 2020/6/13.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import ElastosCarrierSDK
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
        FriendCellModel(id: self.userId ?? "no user id",
                        name: (self.name?.isEmpty == true ? "no name" : self.name)!,
                        avatar: nil,
                        status: self.status.status)
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
