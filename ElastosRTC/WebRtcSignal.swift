//
//  WebRtcSignal.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/5.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

public enum CallReason: String, Codable {
    case reject
    case missing
    case unknown
}

enum SdpType: String, Codable {
    case answer = "answer"
    case offer = "offer"
    case candidate = "candidate"
    case removeCandiate = "remove-candidates"
    case prAnswer = "prAnswer"
    case bye = "bye"
}

struct RtcSignal: Codable {
    let type: SdpType
    let sdp: String?
    let candidates: [RtcCandidateSignal]?
    let reason: CallReason?

    enum CoingKeys: CodingKey {
        case type
        case sdp
        case candidates
    }

    init(type: SdpType, sdp: String? = nil, candidates: [RtcCandidateSignal]? = nil, reason: CallReason? = nil) {
        self.type = type
        self.sdp = sdp
        self.candidates = candidates
        self.reason = reason
    }

    var candidate: RTCIceCandidate? {
        guard type == .candidate, let sdp = candidates?.first?.sdp, let sdpMLineIndex = candidates?.first?.sdpMLineIndex else { return nil }
        return RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: candidates?.first?.sdpMid)
    }

    var offer: RTCSessionDescription? {
        guard type == .offer, let sdp = sdp else { return nil }
        return RTCSessionDescription(type: .offer, sdp: sdp)
    }

    var answer: RTCSessionDescription? {
        guard type == .answer, let sdp = sdp else { return nil }
        return RTCSessionDescription(type: .answer, sdp: sdp)
    }

    var removeCandidates: [RTCIceCandidate]? {
        guard type == .removeCandiate, let candidates = candidates else { return nil }
        return candidates.map {
            RTCIceCandidate(sdp: $0.sdp, sdpMLineIndex: $0.sdpMLineIndex, sdpMid: $0.sdpMid)
        }
    }
}

struct RtcCandidateSignal: Codable {

    let sdp: String
    let sdpMLineIndex: Int32
    let sdpMid: String?
}

extension RTCIceCandidate {

    func to() -> RtcCandidateSignal {
        RtcCandidateSignal(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
}

extension RTCSessionDescription {

    func to() -> RtcSignal {
        RtcSignal(type: type.to!, sdp: sdp)
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
