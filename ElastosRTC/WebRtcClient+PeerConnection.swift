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
                self.delegate?.onConnectionError(error: error)
                return Log.e(TAG, "failed to create offer, due to %@", error as CVarArg)
            } else if let desc = desc {
                self.peerConnection.setLocalDescription(desc) { error in
                    if let error = error {
                        self.delegate?.onConnectionError(error: error)
                        return Log.e(TAG, "failed to set local sdp into peerconnection, due to %@", error as CVarArg)
                    } else {
                        closure(desc)
                    }
                }
            } else {
                fatalError("could not happen here")
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
                self.delegate?.onConnectionError(error: error)
                return Log.e(TAG, "failed to create local answer sdp, due to %@", error as CVarArg)
            } else if let desc = desc {
                self.peerConnection.setLocalDescription(desc) { error in
                    if let error = error {
                        self.delegate?.onConnectionError(error: error)
                        return Log.e(TAG, "failed to set local answer sdp, due to %@", error as CVarArg)
                    }
                    closure(desc)
                }
            } else {
                fatalError("could not happen here")
            }
        }
    }

    /// Receive offer sdp from message channel
    /// - Parameters:
    ///   - sdp: SDP Desc
    ///   - closure: called when set offer sdp success and create a answer sdp and set local success
    func receive(sdp: RTCSessionDescription, closure: @escaping (RTCSessionDescription) -> Void) {
        hasReceivedSdp = true
        if options.isEnableVideo {
            peerConnection.add(self.localVideoTrack, streamIds: ["stream-0"])
        }
        peerConnection.setRemoteDescription(sdp) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                return Log.e(TAG, "failed to set remote offer sdp into peerconnection, due to %@", error as CVarArg)
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
                return Log.e(TAG, "failed to set remote offer sdp into peerconnection, due to %@", error as CVarArg)
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
        RTCDispatcher.dispatchAsync(on: .typeMain) {
            if let track = stream.videoTracks.first {
                track.add(self.remoteRenderView)
            }
        }
    }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        Log.d(TAG, "peerconnection did remove stream with id: , %@", stream.streamId)
    }

    public func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) { }

    public func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        Log.d(TAG, "peerconnection did change state: ", newState.state)
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

    public func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        Log.d(TAG, "peerconnection did open data-channel")
        print("✅ peerconnection did open data-channel")
        guard self.callDirection == .incoming else { return }
        self.dataChannel = dataChannel
        self.dataChannel?.delegate = self
    }
}
