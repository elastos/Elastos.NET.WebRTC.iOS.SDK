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

import XCTest
@testable import ElastosWebRTCSDK

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
