//
//  WebRtcSignal.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/5.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

public enum MediaOptionItem: String, Equatable, Codable {
    case audio
    case video
    case dataChannel = "data"
}

enum CallDirection {
    case outgoing
    case incoming
}

public enum CallState {
    case idle
    case dialing
    case answering
    case connected
    case localFailure //set offer or answer local failure
    case localHangup
    case remoteHangup
    case remoteBusy
}

public enum WebRtcError: Error {
    case dataChannelInitFailed
}

public class MediaOptions: ExpressibleByArrayLiteral, Codable, Equatable, CustomDebugStringConvertible {

    public typealias ArrayLiteralElement = MediaOptionItem

    private let options: Set<MediaOptionItem>

    public required init(arrayLiteral elements: MediaOptionItem...) {
        self.options = Set(elements)
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        try self.options = container.decode(Set<MediaOptionItem>.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.options)
    }

    public var debugDescription: String {
        self.options.reduce(into: "") { (result, item) in result = result + item.rawValue + " " }
    }

    public var isEnableAudio: Bool {
        self.options.contains(.audio)
    }

    public var isEnableVideo: Bool {
        self.options.contains(.video)
    }

    public var isEnableDataChannel: Bool {
        self.options.contains(.dataChannel)
    }

    public static func == (lhs: MediaOptions, rhs: MediaOptions) -> Bool {
        lhs.options == rhs.options
    }
}

public enum CallReason: String, Codable {
    case reject
    case missing
    case cancel
    case unknown
    case close
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
    let options: MediaOptions?

    enum CodingKeys: String, CodingKey {
        case type
        case sdp
        case candidates
        case reason
        case options
    }

    init(type: SdpType, sdp: String? = nil, candidates: [RtcCandidateSignal]? = nil, reason: CallReason? = nil, options: MediaOptions? = nil) {
        self.type = type
        self.sdp = sdp
        self.candidates = candidates
        self.reason = reason
        self.options = options
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
