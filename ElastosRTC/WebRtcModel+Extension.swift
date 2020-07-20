//
//  WebRtcModel+Extension.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/7/13.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

extension RTCIceCandidate {

    func to() -> RtcCandidateSignal {
        RtcCandidateSignal(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
}

extension RTCSessionDescription {

    func to(options: MediaOptions? = nil) -> RtcSignal {
        RtcSignal(type: type.to!, sdp: sdp, options: options)
    }
}

extension RTCSdpType {

    var to: SdpType? {
        switch self {
        case .answer:
            return .answer
        case .offer:
            return .offer
        case .prAnswer:
            return .prAnswer
        default:
            return nil
        }
    }
}

extension RTCDataChannelState {

    var state: String {
        switch self {
        case .closed:
            return "closed"
        case .closing:
            return "closing"
        case .connecting:
            return "connecting"
        case .open:
            return "open"
        @unknown default:
            return "unknown"
        }
    }
}

extension RTCIceConnectionState {

    var state: String {
        switch self {
        case .checking:
            return "checking"
        case .closed:
            return "closed"
        case .completed:
            return "completed"
        case .connected:
            return "connected"
        case .count:
            return "count"
        case .disconnected:
            return "disconnected"
        case .failed:
            return "failed"
        case .new:
            return "new"
        @unknown default:
            return "unknown"
        }
    }
}

extension TurnServerInfo {

    var iceServer: RTCIceServer {
        RTCIceServer(urlStrings: ["turn:\(server):\(port)"], username: username, credential: password)
    }
}
