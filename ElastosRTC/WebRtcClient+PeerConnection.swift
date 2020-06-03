//
//  WebRtcClient+PeerConnection.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

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

