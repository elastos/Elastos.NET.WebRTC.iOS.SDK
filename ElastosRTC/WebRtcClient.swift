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

public enum SupportMediaType {
	case audio
	case video
	case audioAndVideo
	case none
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
	
	public var mediaType: SupportMediaType = .audioAndVideo {
		didSet {
			//todo
		}
	}

	var videoCapturer: RTCVideoCapturer?

	lazy var peerConnection: RTCPeerConnection = {
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

	lazy var dataChannel: RTCDataChannel = {
		let config = RTCDataChannelConfiguration()
		config.channelId = 0
		return peerConnection.dataChannel(forLabel: "dataChannel", configuration: config)!
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
        
    public init(carrier: Carrier, delegate: WebRtcDelegate) {
        self.carrier = carrier
        self.delegate = delegate
    }

    private func setupViews() {
        localView.addSubview(localRenderView)
        remoteView.addSubview(remoteRenderView)
    }

    public func inviteCall(friendId: String) {
		switch mediaType {
		case .audio:
			setupAudio()
		case .video:
			setupVideo()
		case .audioAndVideo:
			setupAudio()
			setupVideo()
		case .none:
			break
		}
		createOffer { sdp in
			//todo, send sdp to friend
		}
    }
    
    public func endCall(friendId: String) {
        
    }
}
