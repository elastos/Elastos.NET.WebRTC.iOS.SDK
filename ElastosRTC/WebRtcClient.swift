//
//  WebRtcClient.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//
import AVFoundation

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

    func onReceiveMessage(_ data: Data, isBinary: Bool, channelId: Int)
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
    var isUsingFrontCamera: Bool = true

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

    var dataChannel: RTCDataChannel?

    func createDataChannel() -> RTCDataChannel? {
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        config.isNegotiated = false
        config.maxRetransmits = -1
        config.maxPacketLifeTime = -1
        config.channelId = 3
        return self.peerConnection.dataChannel(forLabel: "message", configuration: config)
    }

    public init(carrier: Carrier, delegate: WebRtcDelegate) {
        self.carrier = CarrierExtension(carrier)
        self.delegate = delegate
        super.init()
        self.registerCarrierCallback()
    }

    func cleanup() {
        _peerConnection?.close()
        _peerConnection = nil
        dataChannel?.close()
        dataChannel = nil
        hasReceivedSdp = false
        messageQueue.removeAll()
        Log.d(TAG, "webrtc client cleanup")
    }
}

/// Public API
public extension WebRtcClient {

    var isEnableAudio: Bool {
        get {
            peerConnection.localStreams.first?.audioTracks.first?.isEnabled == true
        }
        set {
            guard let audioTrack = peerConnection.localStreams.first?.audioTracks.first else { return }
            audioTrack.isEnabled = newValue
        }
    }

    var isEnableVideo: Bool {
        get {
            peerConnection.localStreams.first?.videoTracks.first?.isEnabled == true
        }
        set {
            guard let videoTrack = peerConnection.localStreams.first?.videoTracks.first else { return }
            videoTrack.isEnabled = newValue
        }
    }

    var isLoudSpeaker: Bool {
        true//todo
    }

    func inviteCall(friendId: String, options: MediaOptions) {
        self.friendId = friendId
        self.options = options
        self.messageQueue = []
        if options.isEnableVideo {
            peerConnection.add(self.localVideoTrack, streamIds: ["stream0"])
        }

        createOffer { [weak self] sdp in
            guard let self = self else { return }
            self.send(desc: sdp, options: options)
        }
    }

    func endCall(friendId: String) {
        send(signal: RtcSignal(type: .bye))
        cleanup()
    }

    func setResolution(cameraPosition: AVCaptureDevice.Position = .front, width: Int = 1280, height: Int = 1280 * 16 / 9, fps: Int = 30) {
        self.startCaptureLocalVideo(cameraPositon: cameraPosition, videoWidth: width, videoHeight: width, videoFps: fps)
    }

    func switchCarmeraToPosition(_ position: AVCaptureDevice.Position, completion: (() -> Void)? = nil) {
        setResolution(cameraPosition: position)
    }

    func stopCapture() {
        guard let videoSource = self.videoCapturer as? RTCCameraVideoCapturer else { return }
        videoSource.stopCapture()
    }

    func sendData(_ data: Data, isBinary: Bool) -> Bool {
        let buffer = RTCDataBuffer(data: data, isBinary: isBinary)
        assert(dataChannel != nil, "create data channel first")
        return self.dataChannel?.sendData(buffer) == true
    }
}
