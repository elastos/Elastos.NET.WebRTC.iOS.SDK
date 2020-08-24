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

    public internal(set) var options: MediaOptions = [.audio, .video] {
        didSet {
            setupMedia()
        }
    }

    var videoCapturer: RTCVideoCapturer?
    var isUsingFrontCamera: Bool = true
    var callDirection: WebRtcCallDirection = .incoming

    var buffers: [RTCDataBuffer] = []
    let condition = NSCondition()

    var messageQueue: [RtcSignal] = []
    var hasReceivedSdp: Bool = false {
        didSet {
            if hasReceivedSdp {
                self.drainMessageQueueIfReady()
            }
        }
    }
    var videoWidth = UIScreen.main.nativeBounds.width
    var videoHeight = UIScreen.main.nativeBounds.height
    var videoFps: Double = 30

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

    lazy var localVideoView: UIView = {
        let view = UIView()
        return view
    }()

    lazy var remoteVideoView: UIView = {
        let view = UIView()
        return view
    }()

    var localRenderView: RTCEAGLVideoView?
    var remoteRenderView: RTCEAGLVideoView?

    func createRenderVideoView() -> RTCEAGLVideoView {
        let view = RTCEAGLVideoView()
        view.delegate = self
        view.contentMode = .scaleAspectFill
        return view
    }

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
        return peerConnection.dataChannel(forLabel: "message", configuration: config)
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
        options = []
        buffers = []
        DispatchQueue.main.async {
            self.localRenderView?.removeFromSuperview()
            self.remoteRenderView?.removeFromSuperview()
            self.localRenderView = nil
            self.remoteRenderView = nil
        }

        Log.d(TAG, "webrtc client cleanup")
        print("[FREE MEMORY]: WebRtcClient clean up")
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

    func setLoudSpeaker(enabled: Bool) {
        RTCDispatcher.dispatchAsync(on: .typeAudioSession) {
            let session = RTCAudioSession.sharedInstance()
            session.lockForConfiguration()
            do {
                try session.setCategory(AVAudioSession.Category.playAndRecord.rawValue)
                try session.setMode(AVAudioSession.Mode.voiceChat.rawValue)
                if enabled {
                    try session.overrideOutputAudioPort(.speaker)
                    try session.setActive(true)
                } else {
                    try session.overrideOutputAudioPort(.none)
                }
            } catch {
                assertionFailure("set speaker failure")
            }
            session.unlockForConfiguration()
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

    func setResolution(cameraPosition: AVCaptureDevice.Position = .front, width: CGFloat, height: CGFloat, fps: Double) {
        self.videoWidth = width
        self.videoHeight = height
        self.videoFps = fps
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
            self.startCaptureLocalVideo(cameraPositon: cameraPosition, videoWidth: width, videoHeight: width, videoFps: fps)
        }
    }

    func switchCamera(position: AVCaptureDevice.Position, completion: (() -> Void)? = nil) {
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
            self.startCaptureLocalVideo(cameraPositon: position)
        }
    }

    func stopCapture() {
        guard let videoSource = self.videoCapturer as? RTCCameraVideoCapturer else { return }
        RTCDispatcher.dispatchAsync(on: .typeCaptureSession) {
            videoSource.stopCapture()
        }
    }
}
