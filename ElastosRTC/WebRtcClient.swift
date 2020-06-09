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

public enum MediaOptionItem: String, Equatable {
    case audio
    case video
    case dataChannel
}

public class MediaOptions: ExpressibleByArrayLiteral, CustomStringConvertible {

    public var description: String {
        options.reduce(into: "") { (result, item) in
            result += item.rawValue + ", "
        }
    }

    public typealias ArrayLiteralElement = MediaOptionItem

    private let options: [MediaOptionItem]

    public required init(arrayLiteral elements: MediaOptionItem...) {
        self.options = elements
    }

    public var isEnabledAudio: Bool {
        options.contains(.audio)
    }

    public var isEnabledVideo: Bool {
        options.contains(.video)
    }

    public var isEnabledDataChannel: Bool {
        options.contains(.dataChannel)
    }
}

public protocol WebRtcDelegate: class {

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
	public var friendId: String?
    public weak var delegate: WebRtcDelegate?

    public let localView: UIView?
    public let remoteView: UIView?

    public var options: MediaOptions? {
        didSet {
            setupMedia()
        }
    }

	var videoCapturer: RTCVideoCapturer?
    var remoteStream: RTCMediaStream?

	lazy var peerConnection: RTCPeerConnection = {
        let config = RTCConfiguration()
        let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                             RTCIceServer(urlStrings: ["stun:gfax.net:3478"]),
                             RTCIceServer(urlStrings: ["turn:gfax.net:3478"], username: "allcom", credential: "allcompass")]
        return peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
    }()

    private let peerConnectionFactory: RTCPeerConnectionFactory = {
        let videoDecoder = RTCDefaultVideoDecoderFactory()
        let videoEncoder = RTCDefaultVideoEncoderFactory()
        return RTCPeerConnectionFactory(encoderFactory: videoEncoder, decoderFactory: videoDecoder)
    }()

    lazy var localRenderView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView()
        view.delegate = self
        return view
    }()

    lazy var remoteRenderView: RTCEAGLVideoView = {
        let view = RTCEAGLVideoView()
        view.delegate = self
        return view
    }()

	lazy var localAudioTrack: RTCAudioTrack = {
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let source = peerConnectionFactory.audioSource(with: constraints)
        return peerConnectionFactory.audioTrack(with: source, trackId: "audio0")
    }()

	lazy var localVideoTrack: RTCVideoTrack = {
        let source = peerConnectionFactory.videoSource()

        if customFrameCapturer {
            videoCapturer = RTCFrameCapturer(delegate: source)
        } else if TARGET_OS_SIMULATOR != 0 {
            videoCapturer = RTCFileVideoCapturer(delegate: source)
        } else {
          videoCapturer = RTCCameraVideoCapturer(delegate: source)
        }
        return peerConnectionFactory.videoTrack(with: source, trackId: "video0")
    }()
        
    public init(carrier: Carrier, delegate: WebRtcDelegate, localView: UIView? = nil, remoteView: UIView? = nil) {
        self.carrier = carrier
        self.delegate = delegate
        self.localView = localView
        self.remoteView = remoteView
    }

    private func setupViews() {
        localView?.addSubview(localRenderView)
        remoteView?.addSubview(remoteRenderView)
    }

    public func inviteCall(friendId: String) {
		self.friendId = friendId
        setupMedia()
		createOffer { [weak self] sdp in
            guard let self = self else { return }
            self.send(desc: sdp)
		}
    }

    public func endCall(friendId: String) {
        peerConnection.close()
    }
}

extension WebRtcClient: CameraSessionDelegate {
    
    func didOutput(_ sampleBuffer: CMSampleBuffer) {
        guard let cvpixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let capturer = self.videoCapturer as? RTCFrameCapturer else { return }
        capturer.capture(cvpixelBuffer)
    }
}
