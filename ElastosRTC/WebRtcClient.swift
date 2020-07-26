//
//  WebRtcClient.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//
import AVFoundation

public enum WebRtcCallState {
    case connecting
    case connected
    case disconnected
    case localFailure(error: Error) //set offer or answer local failure
    case localHangup // hangup by me
    case remoteHangup // hangup by other
}

public protocol WebRtcDelegate: class {

    /// fired when receive invite from your friends
    /// - Parameter friendId: who is calling you
    /// - Parameter completion: reject or accept
    func onInvite(friendId: String, mediaOption: MediaOptions, completion: @escaping (Bool) -> Void)
    
    /// Fired when webrtc state did change
    /// - Parameters:
    ///   - client: the client
    ///   - state: state of webrtc
    func onWebRtc(_ client: WebRtcClient, didChangeState state: WebRtcCallState)
    
    /// Fired when receive data from webrtc data-channel
    /// - Parameters:
    ///   - data: the data that was received from data-channel
    ///   - isBinary: Indicates whether |data| contains UTF-8 or binary data.
    ///   - channelId: The identifier for this data channel
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
    var callDirection: WebRtcCallDirection = .incoming

    var messageQueue: [RtcSignal] = []
    var hasReceivedSdp: Bool = false {
        didSet {
            if hasReceivedSdp {
                self.drainMessageQueueIfReady()
            }
        }
    }
    private var videoWidth = 1280
    private var videoHeight = 1280 * 16 / 9
    private var videoFps = 30
    
    private var _peerConnection: RTCPeerConnection?
    var peerConnection: RTCPeerConnection {
        if _peerConnection == nil {
            let config = RTCConfiguration()
            let constraints = RTCMediaConstraints.init(mandatoryConstraints: nil, optionalConstraints: nil)
            config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
            if let turn = try? self.carrier.turnServerInfo() {
                config.iceServers.append(turn.iceServer)
            } else {
                assertionFailure("turn server is null")
            }
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
    func createDataChannel() {
        let config = RTCDataChannelConfiguration()
        config.isOrdered = true
        config.isNegotiated = false
        config.maxRetransmits = -1
        config.maxPacketLifeTime = -1
        config.channelId = 3
        self.dataChannel = peerConnection.dataChannel(forLabel: "message", configuration: config)
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
            localAudioTrack.isEnabled
        }
        set {
            RTCDispatcher.dispatchAsync(on: .typeAudioSession) {
                self.localAudioTrack.isEnabled = newValue
            }
        }
    }

    var isEnableVideo: Bool {
        get {
            localVideoTrack.isEnabled == true
        }
        set {
            RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
                self.localVideoTrack.isEnabled = newValue
            }
        }
    }

    var isLoudSpeaker: Bool {
        get {
            true //TODO
        }
        set {
            RTCDispatcher.dispatchAsync(on: .typeAudioSession) {
                let session = AVAudioSession.sharedInstance()
                var _: Error?
                try? session.setCategory(.playAndRecord)
                try? session.setMode(.voiceChat)
                if newValue {
                    try? session.overrideOutputAudioPort(.speaker)
                } else {
                    try? session.overrideOutputAudioPort(.none)
                }
                try? session.setActive(true)
            }
        }
    }

    func inviteCall(friendId: String, options: MediaOptions) {
        self.callDirection = .outgoing
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

    func endCall(type: HangupType) {
        send(signal: RtcSignal(type: .bye, reason: type))
        cleanup()
    }

    func setResolution(cameraPosition: AVCaptureDevice.Position = .front, width: Int = 1280, height: Int = 1280 * 16 / 9, fps: Int = 30) {
        self.videoWidth = width
        self.videoHeight = height
        self.videoFps = fps
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
            self.startCaptureLocalVideo(cameraPositon: cameraPosition, videoWidth: width, videoHeight: width, videoFps: fps)
        }
    }

    func switchCamera(position: AVCaptureDevice.Position, completion: (() -> Void)? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
            self.startCaptureLocalVideo(cameraPositon: position,
                                        videoWidth: self.videoWidth,
                                        videoHeight: self.videoHeight,
                                        videoFps: self.videoFps)
        }
    }

    func stopCapture() {
        guard let videoSource = self.videoCapturer as? RTCCameraVideoCapturer else { return }
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
            videoSource.stopCapture()
        }
    }

    @discardableResult
    func sendData(_ data: Data, isBinary: Bool) throws -> Bool {
        let buffer = RTCDataBuffer(data: data, isBinary: isBinary)
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        return channel.sendData(buffer) == true
    }
}
