//
//  WebRtcClient.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

public protocol WebRtcDelegate: class {

    /// fired when receive invite from your friends
    /// - Parameter friendId: who is calling you
    /// - Parameter completion: reject or accept
    func onInvite(friendId: String, completion: @escaping (Bool) -> Void)

    func onAnswer();

    func onActive()

    func onEndCall(reason: CallReason)

    func onIceConnected()

    func onIceDisconnected()

    func onConnectionError(error: Error)

    func onConnectionClosed()
}

public class WebRtcClient: NSObject {

    public let carrier: CarrierExtension
    public var friendId: String?
    public weak var delegate: WebRtcDelegate?

    lazy var localVideoView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var remoteVideoView: UIView = {
        let view = UIView()
        return view
    }()

    public internal(set) var options: MediaOptions = [.audio, .video] {
        didSet {
            setupMedia()
        }
    }

    var videoCapturer: RTCVideoCapturer?
    var remoteStream: RTCMediaStream?

    var messageQueue: [RtcSignal] = []
    var hasReceivedSdp: Bool = false {
        didSet {
            if hasReceivedSdp {
                self.drainMessageQueueIfReady()
            }
        }
    }

    private var _peerConnection: RTCPeerConnection?
    var peerConnection: RTCPeerConnection {
        if _peerConnection == nil {
            let config = RTCConfiguration()
            let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
            config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"]),
                                 RTCIceServer(urlStrings: ["stun:gfax.net:3478"]),
                                 RTCIceServer(urlStrings: ["turn:gfax.net:3478"], username: "allcom", credential: "allcompass")]
            _peerConnection = peerConnectionFactory.peerConnection(with: config, constraints: constraints, delegate: self)
        }
        return _peerConnection!
    }

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

        #if targetEnvironment(simulator)
            // we're on the simulator - use the file local video
            videoCapturer = RTCFileVideoCapturer(delegate: source)
        #else
            // we're on a device – use front camera
            videoCapturer = RTCCameraVideoCapturer(delegate: source)
        #endif
        return peerConnectionFactory.videoTrack(with: source, trackId: "video0")
    }()

    public var isEnableAudio: Bool {
        get {
            peerConnection.localStreams.first?.audioTracks.first?.isEnabled == true
        }
        set {
            guard let audioTrack = peerConnection.localStreams.first?.audioTracks.first else { return }
            audioTrack.isEnabled = newValue
        }
    }

    public var isEnableVideo: Bool {
        get {
            peerConnection.localStreams.first?.videoTracks.first?.isEnabled == true
        }
        set {
            guard let videoTrack = peerConnection.localStreams.first?.videoTracks.first else { return }
            videoTrack.isEnabled = newValue
        }
    }

    public var isSpeaker: Bool {
        true//todo
    }

    public init(carrier: Carrier, delegate: WebRtcDelegate) {
        self.carrier = CarrierExtension(carrier)
        self.delegate = delegate
        super.init()
        self.registerCarrierCallback()
    }

    public func inviteCall(friendId: String, options: MediaOptions) {
        self.friendId = friendId
        self.options = options
        self.messageQueue = []
        if isEnableVideo {
            peerConnection.add(self.localVideoTrack, streamIds: ["stream0"])
        }
        createOffer { [weak self] sdp in
            guard let self = self else { return }
            self.send(desc: sdp, options: options)
        }
    }

    public func endCall(friendId: String) {
        send(signal: RtcSignal(type: .bye))
        cleanup()
    }

    func cleanup() {
        _peerConnection?.close()
        _peerConnection = nil
        hasReceivedSdp = false
        messageQueue.removeAll()
        Log.d(TAG, "webrtc client cleanup")
    }
}
