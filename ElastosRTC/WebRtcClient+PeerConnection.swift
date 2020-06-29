//
//  WebRtcClient+PeerConnection.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//


extension WebRtcClient {

    /// Create Offer SDP
    /// - Parameter closure: callback was called when both create offer and set local sdp successfully
    func createOffer(closure: @escaping (RTCSessionDescription) -> Void) {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection.offer(for: constraints) { [weak self] (desc, error) in
            guard let self = self else { return }
            if let error = error {
                return assertionFailure("failed to create offer, due to \(error)")
            } else if let desc = desc {
                self.peerConnection.setLocalDescription(desc) { error in
                    if let error = error {
                        return assertionFailure("failed to set local sdp, due to \(error)")
                    } else {
                        closure(desc)
                    }
                }
            } else {
                assertionFailure("could not happen here")
            }
        }
    }

    /// Create Answer SDP
    /// - Parameter closure: callback was called when both creat answer and set local sdp successfully
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

    /// Receive offer sdp from message channel
    /// - Parameters:
    ///   - sdp: SDP Desc
    ///   - closure: called when set offer sdp success and create a answer sdp and set local success
    func receive(sdp: RTCSessionDescription, closure: @escaping (RTCSessionDescription) -> Void) {
        setupMedia()
        hasReceivedSdp = true
        if options.isEnableVideo {
            peerConnection.add(self.localVideoTrack, streamIds: ["stream-0"])
        }
        peerConnection.setRemoteDescription(sdp) { error in
            if let error = error {
                return assertionFailure("failed to set remote offer sdp, due to \(error)")
            }
            self.createAnswer(closure: closure)
        }
    }

    /// Receive answer sdp from message channel
    /// - Parameter sdp: SDP Desc
    func receive(sdp: RTCSessionDescription) {
        hasReceivedSdp = true
        peerConnection.setRemoteDescription(sdp) { error in
            if let error = error {
                return assertionFailure("failed to set remote answer sdp, due to \(error)")
            }
        }
    }

    /// Receive candidate from message channel
    /// - Parameter candidate: iceCandidate instance generated by WebRtc
    func receive(candidate: RTCIceCandidate) {
        peerConnection.add(candidate)
    }

    /// Receive removal candidates from message channel
    /// - Parameter removal: the RtcCandiates array was generated by WebRtc
    func receive(removal: [RTCIceCandidate]) {
        peerConnection.remove(removal)
    }
}

extension WebRtcClient: RTCPeerConnectionDelegate {

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) { }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        self.remoteStream = stream
        DispatchQueue.main.async {
            if let track = stream.videoTracks.first {
                track.add(self.remoteRenderView)
            }
            if let track = stream.audioTracks.first {
                track.source.volume = 8
            }
        }
        print("peer connection receive stream: \(stream.videoTracks), \(stream.audioTracks)")
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        print("\(#function) stream = \(stream)")
        if stream.videoTracks.isEmpty {
            Log.d(TAG, "peerconnection remove video track")
        }
        if stream.audioTracks.isEmpty {
            Log.d(TAG, "peerconnection remove audio track")
        }
    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) { }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        switch newState {
        case .connected:
            self.delegate?.onIceConnected()
        case .disconnected, .failed:
            self.delegate?.onIceDisconnected()
        case .closed:
            self.delegate?.onConnectionClosed()
        default:
            break
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) { }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        send(candidate: candidate)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        send(removal: candidates)
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) { }
}
