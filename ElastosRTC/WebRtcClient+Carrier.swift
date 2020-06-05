//
//  WebRtcClient+Carrier.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import ElastosCarrierSDK
import WebRTC

extension WebRtcClient {

    func send(candidate: RTCIceCandidate) {
        // todo: send candidate to friend by carrier sdk
    }

    func send(desc: RTCSessionDescription) {
        // todo: send offer or answer to friend by carrier sdk
    }
}

extension WebRtcClient: CarrierDelegate {
    
    public func didReceiveGroupInvite(_ carrier: Carrier, _ from: String, _ cookie: Data) {
        do {
            let message = try JSONDecoder().decode(SignalingMessage.self, from: cookie)
            guard from == message.destination else { return assertionFailure("not my rtc message") }
            switch message.type {
            case .offer:
                guard let sdp = message.sessionDescription?.sdp else { return }
                receive(sdp: RTCSessionDescription(type: .offer, sdp: sdp)) { [weak self] desc in
                    guard let self = self else { return }
                    self.send(desc: desc)
                }
            case .answer:
                guard let sdp = message.sessionDescription?.sdp else { return }
                receive(sdp: RTCSessionDescription(type: .answer, sdp: sdp))
            case .candidate:
                guard let candidate = message.candidate else { return }
                receive(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            case .prAnswer:
                assertionFailure("not support prAnswer")
            }
        } catch {
            assertionFailure("signal message decode error, due to \(error)")
        }
    }
}
