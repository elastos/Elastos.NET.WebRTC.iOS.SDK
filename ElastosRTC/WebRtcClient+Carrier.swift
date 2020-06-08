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
        do {
            let data = try JSONEncoder().encode(candidate.to())
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            assertionFailure("failed to convert data, due to \(error)")
        }
    }

    func send(desc: RTCSessionDescription) {
        // todo: send offer or answer to friend by carrier sdk
        do {
            let data = try JSONEncoder().encode(desc.to())
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            assertionFailure("failed to convert data, due to \(error)")
        }
    }

	func send(json: String) {
		guard let friendId = self.friendId else { return assertionFailure("friendId is null") }
		do {
			try carrier.sendInviteFriendRequest(to: friendId, withData: json) { (carrier, _, _, _, _) in }
		} catch {
			assertionFailure("failed to send candidate to \(friendId), due to \(error)")
		}
	}
}

extension WebRtcClient: CarrierDelegate {

	public func didReceiveFriendInviteRequest(_ carrier: Carrier, _ from: String, _ data: String) {
        do {
            let message = try JSONDecoder().decode(RtcSignal.self, from: data.data(using: .utf8)!)
            switch message.type {
                case .offer:
                    guard let sdp = message.offer else { return }
                    self.friendId = from
                    receive(sdp: sdp) { [weak self] desc in
                        guard let self = self else { return }
                        self.send(desc: desc)
                }
                case .answer:
                    guard let sdp = message.answer, from == self.friendId else { return }
                    receive(sdp: sdp)
                case .candidate:
                    guard let candidate = message.candidate, from == self.friendId else { return }
                    receive(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
                case .prAnswer:
                    assertionFailure("not support prAnswer")
                case .removeCandiate:
                    guard let candiates = message.removeCandidates, from == self.friendId else { return }
                    receive(removal: candiates)
            }
        } catch {
            assertionFailure("signal message decode error, due to \(error)")
        }
	}
}
