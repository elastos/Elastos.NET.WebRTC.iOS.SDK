//
//  WebRtcSignal.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/5.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

enum SdpType: String, Codable {
    case answer = "answer"
    case offer = "offer"
    case candidate = "candidate"
    case removeCandiate = "remove-candidates"
    case prAnswer = "prAnswer"
}

//jsonPut(json, "type", "remove-candidates");
//JSONArray jsonArray = new JSONArray();
//for (final IceCandidate candidate : candidates) {
//    jsonArray.put(toJsonCandidate(candidate));
//}
//jsonPut(json, "candidates", jsonArray);

//jsonPut(json, "type", "candidate");
//jsonPut(json, "label", candidate.sdpMLineIndex);
//jsonPut(json, "id", candidate.sdpMid);
//jsonPut(json, "candidate", candidate.sdp);

//jsonPut(json, "sdp", sdp.description);
//jsonPut(json, "type", "answer");
//send(json.toString());

struct RtcSignal: Codable {
	let type: SdpType
	let sdp: String?
	let sdpMLineIndex: Int32?
	let sdpMid: String?
    let candidates: [RtcCandidateSignal]?

	enum CoingKeys: CodingKey {
		case type
        case sdp
        case sdpMLineIndex
        case sdpMid
        case candidates
	}

    init(type: SdpType, sdp: String? = nil, sdpMLineIndex: Int32? = nil, sdpMid: String? = nil, candidates: [RtcCandidateSignal]? = nil) {
        self.type = type
        self.sdp = sdp
        self.sdpMLineIndex = sdpMLineIndex
        self.sdpMid = sdpMid
        self.candidates = candidates
    }

    var candidate: RTCIceCandidate? {
        guard type == .candidate, let sdp = sdp, let index = sdpMLineIndex, let mid = sdpMid else {
            return nil
        }
        return RTCIceCandidate(sdp: sdp, sdpMLineIndex: index, sdpMid: mid)
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

	var value: String {
		switch self {
			case .answer:
				return "answer"
			case .offer:
				return "offer"
			case .prAnswer:
				return "prAnswer"
			@unknown default:
				assertionFailure("unknown state")
				return "unknown"
		}
	}

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
