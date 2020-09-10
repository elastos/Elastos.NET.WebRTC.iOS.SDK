//
//  MediaCallViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/7/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

typealias VoidClosure = () -> Void
typealias BoolClosure = (Bool) -> Void

extension MediaOptions {

    var title: String {
        if self.isEnableVideo == true, self.isEnableAudio == true {
            return "Audio + Video Call"
        } else if self.isEnableAudio {
            return "Audio Call"
        } else if self.isEnableVideo {
            return "Video Call"
        } else {
            fatalError("should not run here")
        }
    }
}

enum MediaCallState {
    case answering
    case connecting
    case connected
    case hangup
    case cancel
    case reject
    case newMessage

    var state: String {
        switch self {
        case .answering:
            return "waiting for answer"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .hangup:
            return "Hangup"
        case .cancel:
            return "Cancel"
        case .reject:
            return "Reject"
        case .newMessage:
            return "Has New Message"
        }
    }
}

enum MediaCallDirection {
    case incoming
    case outgoing
}

class MediaCallViewController: UIViewController {

    var callOptions: MediaOptions {
        didSet {
            updateToolsStack()
        }
    }

    var callState: MediaCallState = .connecting {
        didSet {
            updateToolsStack()
            nameLabel.text = callState.state
        }
    }

    var callDirection: MediaCallDirection {
        didSet {
            updateToolsStack()
        }
    }

    private lazy var endBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "end-call"), for: .normal)
        view.addTarget(self, action: #selector(didPressEndCall(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var acceptBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "accept"), for: .normal)
        view.addTarget(self, action: #selector(didPressAcceptCall(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var audioMuteBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "audio-call-active"), for: .normal)
        view.setImage(UIImage(named: "audio-call-inactive"), for: .selected)
        view.addTarget(self, action: #selector(didPressAudioControl(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var loudSpeakerBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "loud-speaker-inactive"), for: .normal)
        view.setImage(UIImage(named: "loud-speaker-active"), for: .selected)
        view.setImage(UIImage(named: "loud-speaker-active"), for: .disabled)
        view.isEnabled = UIDevice.current.userInterfaceIdiom == .phone
        view.isSelected = UIDevice.current.userInterfaceIdiom == .pad
        view.addTarget(self, action: #selector(didPressLoudSpeakerControl(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var videoMuteBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "video-active"), for: .normal)
        view.setImage(UIImage(named: "video-inactive"), for: .selected)
        view.addTarget(self, action: #selector(didPressVideoControl(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var flipCameraBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "video-switch-camera"), for: .normal)
        view.addTarget(self, action: #selector(didPressCameraControl(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var chatBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "conversation"), for: .normal)
        view.addTarget(self, action: #selector(didPressChatControl(_:)), for: .touchUpInside)
        view.widthAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        return view
    }()

    private lazy var toolStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [audioMuteBtn, videoMuteBtn, loudSpeakerBtn, flipCameraBtn, chatBtn, acceptBtn, endBtn])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .fillProportionally
        return view
    }()

    private let nameLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .blue
        view.textAlignment = .center
        return view
    }()
    
    private let newMessageTipLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .red
        return view
    }()

    let client: WebRtcClient
    let friendId: String
    let myId: String
    let closure: BoolClosure?
    init(direction: MediaCallDirection, options: MediaOptions, client: WebRtcClient, friendId: String, myId: String, closure: BoolClosure? = nil) {
        self.callDirection = direction
        self.callOptions = options
        self.client = client
        self.friendId = friendId
        self.closure = closure
        self.myId = myId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = callOptions.title
        view.backgroundColor = .black
        view.addSubview(nameLabel)
        view.addSubview(newMessageTipLabel)
        view.addSubview(toolStack)
        callState = .answering

        setupObserver()
        NSLayoutConstraint.activate([
            toolStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant:  -20),
            toolStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 10),
            toolStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -10),

            nameLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 30),
            nameLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            newMessageTipLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 20),
            newMessageTipLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        if callDirection == .outgoing {
            client.inviteCall(friendId: friendId, options: callOptions)
        }
        perform(#selector(setupVideoView), with: nil, afterDelay: 1.0)
    }

    @objc func setupVideoView() {
        guard let localVideo = client.localVideoView, let remoteVideo = client.remoteVideoView else { return }
        view.insertSubview(localVideo, belowSubview: toolStack)
        view.insertSubview(remoteVideo, belowSubview: localVideo)

        localVideo.translatesAutoresizingMaskIntoConstraints = false
        remoteVideo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            localVideo.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            localVideo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            localVideo.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.3),
            localVideo.heightAnchor.constraint(equalToConstant: 200),

            remoteVideo.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            remoteVideo.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            remoteVideo.topAnchor.constraint(equalTo: view.topAnchor),
            remoteVideo.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(webrtcStateChanged(_:)), name: .rtcStateChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didReceiveMessage(_:)), name: .receiveMessage, object: nil)
    }

    func updateToolsStack() {
        toolStack.arrangedSubviews.forEach { $0.isHidden = true }
        let views = tools(state: callState, direction: callDirection, options: callOptions)
        views.forEach { $0.isHidden = false }
    }

    func tools(state: MediaCallState, direction: MediaCallDirection, options: MediaOptions) -> [UIView] {
        if options.isEnableVideo, options.isEnableAudio {
            switch state {
            case .answering:
                return direction == .incoming ? [acceptBtn, endBtn] : [endBtn]
            case .connected:
                return [audioMuteBtn, videoMuteBtn, loudSpeakerBtn, flipCameraBtn, chatBtn, endBtn]
            default:
                return [endBtn]
            }
        } else if options.isEnableAudio {
            switch state {
            case .answering:
                return direction == .incoming ? [acceptBtn, endBtn] : [endBtn]
            case .connected:
                return [audioMuteBtn, loudSpeakerBtn, chatBtn, endBtn]
            default:
                return [endBtn]
            }
        } else if options.isEnableVideo {
            switch state {
            case .answering:
                return direction == .incoming ? [acceptBtn, endBtn] : [endBtn]
            case .connected:
                return [videoMuteBtn, flipCameraBtn, chatBtn, endBtn]
            default:
                return [endBtn]
            }
        } else {
            return []
        }
    }
    
    deinit {
        print("[FREE MEMORY] \(self)")
    }
}

extension MediaCallViewController {

    /// Did tap end call button
    /// - Parameter sender: the button that user taped
    @objc func didPressEndCall(_ sender: UIButton) {
        if callDirection == .incoming, callState == .answering {
            closure?(false)
        } else {
            client.endCall(type: .normal)
        }
        dismiss(animated: true, completion: nil)
    }

    @objc func didPressAcceptCall(_ sender: UIButton) {
        self.callState = .connecting
        closure?(true)
    }

    /// Did tap audio mute control button
    /// - Parameter sender: normal: unmute, selected: mute
    @objc func didPressAudioControl(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        client.isEnableAudio = !sender.isSelected
    }

    /// Did tap loud speaker control button
    /// - Parameter sender: normal: loud speaker, selected: micro
    @objc func didPressLoudSpeakerControl(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        client.setLoudSpeaker(enabled: sender.isSelected)
    }

    /// Did tap video mute control button
    /// - Parameter sender: normal: enable local video, selected: disable local video
    @objc func didPressVideoControl(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        client.isEnableVideo = !sender.isSelected
    }

    /// Did tap camera control button
    /// - Parameter sender: normal: front, selected: back camera
    @objc func didPressCameraControl(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        client.switchCamera(position: sender.isSelected ? .back : .front)
    }

    /// Goto Conversation page
    /// - Parameter sender: button
    @objc func didPressChatControl(_ sender: UIButton) {
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        let chatViewController = ChatViewController(sender: myId, to: friendId, client: client, state: .connected)
        chatViewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(chatViewController, animated: true)
        newMessageTipLabel.text = ""
    }
}

extension MediaCallViewController {

    @objc func webrtcStateChanged(_ notification: NSNotification) {
        guard let state = notification.userInfo?["state"] as? WebRtcCallState else { return }
        switch state {
        case .connecting:
            self.callState = .connecting
        case .connected:
            self.callState = .connected
            if UIDevice.current.userInterfaceIdiom == .phone {
                DispatchQueue.main.async {
                    self.loudSpeakerBtn.isSelected = false
                    self.didPressLoudSpeakerControl(self.loudSpeakerBtn)
                }
            }
        case .disconnected, .localFailure, .localHangup:
            self.callState = .hangup
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismiss(animated: true, completion: nil)
            }
        case .remoteHangup:
            self.callState = .reject
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    @objc func didReceiveMessage(_ notification: NSNotification) {
        DispatchQueue.main.async {
            self.newMessageTipLabel.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.newMessageTipLabel.alpha = 1
                self.newMessageTipLabel.text = "Have a New Message"
            }
        }
    }
}
