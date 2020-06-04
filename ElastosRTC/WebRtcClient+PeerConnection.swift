//
//  WebRtcClient+PeerConnection.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

extension WebRtcClient {

	func createOffer(closure: @escaping (RTCSessionDescription) -> Void) {
		let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
		peerConnection.offer(for: constraints) { [weak self] (desc, error) in
			guard let self = self else { return }
			if let error = error {
				return assertionFailure("cound not create offer, due to \(error)")
			} else if let desc = desc {
				self.peerConnection.setLocalDescription(desc) { error in
					if let error = error {
						return assertionFailure("cound not set local sdp, due to \(error)")
					} else {
						closure(desc)
					}
				}
			} else {
				assertionFailure("could not happen here")
			}
		}
	}

	func createAnswer(closure: @escaping (RTCSessionDescription) -> Void) {
		let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
		peerConnection.answer(for: constraints) { [weak self] (desc, error) in
			guard let self = self else { return }
			if let error = error {
				return assertionFailure("failed to create local answer sdp, due to \(error)")
			} else if let desc = desc {
				self.peerConnection.setLocalDescription(desc) { error in
					if let error = error {
						return assertionFailure("failed to set local answer sdp, due to \(error)")
					}
					closure(desc)
				}
			} else {
				assertionFailure("could not happen here")
			}
		}
	}
}

extension WebRtcClient: RTCPeerConnectionDelegate {
	
	public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
		print("\(#function)")
	}

	public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
		print("\(#function)")
	}
	
	public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
		print("\(#function)")
	}

	public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
		print("\(#function)")
	}

	public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
		print("\(#function)")
	}

	public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
		print("\(#function)")
	}
	
	public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
		print("\(#function)")
	}
	
	public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
		print("\(#function)")
	}
	
	public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
		print("\(#function)")
	}
}

