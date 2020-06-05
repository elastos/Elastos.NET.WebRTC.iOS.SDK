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

extension WebRtcClient: CarrierDelegate {
    
    public func didReceiveGroupInvite(_ carrier: Carrier, _ from: String, _ cookie: Data) {
        do {
            let message = try JSONDecoder().decode(SignalingMessage.self, from: cookie)
            guard from == message.destination else { return assertionFailure("not my rtc message") }
            switch message.type {
            case "offer":
                guard let sdp = message.sessionDescription?.sdp else { return }
                receive(sdp: RTCSessionDescription(type: .offer, sdp: sdp))
            case "answer":
                guard let sdp = message.sessionDescription?.sdp else { return }
                receive(sdp: RTCSessionDescription(type: .answer, sdp: sdp))
            case "candidate":
                guard let candidate = message.candidate else { return assertionFailure("candidate must not be null") }
                receive(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            default:
                break
            }
        } catch {

        }
    }
}
