//
//  WebRtcClient.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import UIKit
import ElastosCarrierSDK
import WebRTC

public enum CallReason {
    case reject
    case missing
}

public protocol WebRtcDelegate {
    
    /// fired when receive invite from yur friends
    /// - Parameter friendId: who is calling you
    func onInvite(friendId: String)
    
    func onAnswer();
    
    func onActive()
    
    func onEndCall(reason: CallReason)
    
    func onIceConnected()
    
    func onIceDisconnected()
    
    func onConnectionError(error: Error)
    
    func onConnectionClosed()
}

public class WebRtcClient: NSObject {
    
    public let carrier: Carrier
    public var customFrameCapturer = false
    public let delegate: WebRtcDelegate

    private var videoCapture: RTCVideoCapturer?
    private var enableAudio: Bool = true
    private var enableVideo: Bool = true

    private lazy var peerConnection: RTCPeerConnection = {
        let config = RTCConfiguration()
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        return peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }()

    private let peerConnectionFactory: RTCPeerConnectionFactory = {
        let videoDecoder = RTCDefaultVideoDecoderFactory()
        let videoEncoder = RTCDefaultVideoEncoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoder, decoderFactory: videoDecoder)
    }()

    private lazy var localView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var remoteView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var localRenderView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView()
        view.delegate = self
        return view
    }()

    private lazy var remoteRenderView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView()
        view.delegate = self
        return view
    }()

    private lazy var localAudioTrack: RTCAudioTrack = {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let source = self.peerConnectionFactory.audioSource(with: constraints)
        return self.peerConnectionFactory.audioTrack(with: source, trackId: "audio0")
    }()

    private lazy var localVideoTrack: RTCVideoTrack = {
        let source = self.peerConnectionFactory.videoSource()

        if customFrameCapturer {
            self.videoCapture = RTCFrameCapturer(delegate: source)
        } else if TARGET_OS_SIMULATOR != 0 {
            self.videoCapture = RTCFileVideoCapturer(delegate: source)
        } else {
          self.videoCapturer = RTCCameraVideoCapturer(delegate: source)
        }
        return self.peerConnectionFactory.videoTrack(with: source, trackId: "video0")
    }()
        
    public init(carrier: Carrier, delegate: WebRtcDelegate) {
        self.carrier = carrier
        self.delegate = delegate
    }

    private func setupViews() {
        localView.addSubview(localRenderView)
        remoteView.addSubview(remoteRenderView)
    }

    public func inviteCall(friendId: String) {

        if enableAudio {
            self.peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        }
        if enableVideo {
            self.peerConnection.add(localVideoTrack, streamIds: ["stream0"])
        }

    }
    
    public func endCall(friendId: String) {
        
    }
}
