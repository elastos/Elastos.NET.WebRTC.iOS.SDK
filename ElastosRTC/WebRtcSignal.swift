//
//  WebRtcSignal.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/5.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

struct SignalingMessage: Codable {
	let type: String
	let sessionDescription: SDP?
	let candidate: Candidate?
	let destination: String?
	let source: String?
}

struct SDP: Codable {
	let sdp: String
}

struct Candidate: Codable {
	let sdp: String
	let sdpMLineIndex: Int32
	let sdpMid: String
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
}
