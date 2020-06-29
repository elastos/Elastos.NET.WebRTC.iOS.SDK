//
//  WebRtcSignalTests.swift
//  ElastosRTCTests
//
//  Created by tomas.shao on 2020/6/28.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import XCTest
@testable import ElastosRTC

class WebRtcSignalTests: XCTestCase {

    func testDecodeAddedCandidate() {
        let candidate = loadData(from: "mock_added_candidate", decode: RtcSignal.self)?.candidate
        XCTAssertNotNil(candidate)
        XCTAssertEqual(candidate?.sdp, "candidate:520584137 1 udp 2122260223 10.21.7.37 64501 typ host generation 0 ufrag 6hC6 network-id 1 network-cost 10")
        XCTAssertEqual(candidate?.sdpMLineIndex, 0)
        XCTAssertEqual(candidate?.sdpMid, "audio")
    }
    //todo: disable decode removal candidates
    func testDecodeRemovalCandidates() {
        let candidates = loadData(from: "removal_candidates", decode: RtcSignal.self)?.removeCandidates
        XCTAssertNotNil(candidates)
    }

    func testDecodeOffer() {
        let signal = loadData(from: "mock_offer", decode: RtcSignal.self)
        let offer = signal?.offer
        XCTAssertNotNil(offer)
        XCTAssertEqual(offer?.sdp, "v=0\r\no=- 2583953393187837782 2 IN IP4 127.0.0.1....")
        XCTAssertEqual(offer?.type, .offer)
        XCTAssertEqual(signal?.options, [.audio, .video])
    }

    func testDecodeAnswer() {
        let signal = loadData(from: "mock_answer", decode: RtcSignal.self)
        let offer = signal?.answer
        XCTAssertNotNil(offer)
        XCTAssertEqual(offer?.sdp, "v=0\r\no=- 1824575949192503590 2 IN IP4 127.0.0.1...")
        XCTAssertEqual(offer?.type, .answer)
        XCTAssertNil(signal?.options)
    }
}
