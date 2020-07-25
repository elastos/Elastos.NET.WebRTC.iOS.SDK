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
    case connecting
    case connected
    case hangup
    case cancel
    case reject
    case newMessage

    var state: String {
        switch self {
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
        view.setImage(UIImage(named: "loud-speaker-active"), for: .normal)
        view.setImage(UIImage(named: "loud-speaker-inactive"), for: .selected)
        view.setImage(UIImage(named: "loud-speaker-active"), for: .disabled)
        view.isEnabled = UIDevice.current.userInterfaceIdiom == .phone
        view.isSelected = UIDevice.current.userInterfaceIdiom == .phone
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

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = callOptions.title
        view.backgroundColor = .black
        view.addSubview(nameLabel)
        view.addSubview(newMessageTipLabel)
        view.addSubview(toolStack)
        callState = .connecting

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

        guard let localVideo = client.getLocalVideoView(), let remoteVideo = client.getRemoteVideoView() else { return }
        self.view.addSubview(localVideo)
        self.view.addSubview(remoteVideo)
        
        self.view.sendSubviewToBack(remoteVideo)
        self.view.sendSubviewToBack(localVideo)
        
        localVideo.translatesAutoresizingMaskIntoConstraints = false
        remoteVideo.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            remoteVideo.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            remoteVideo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            remoteVideo.widthAnchor.constraint(equalToConstant: 150),
            remoteVideo.heightAnchor.constraint(equalToConstant: 150),
            localVideo.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            localVideo.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            localVideo.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            localVideo.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }
    
    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(connected(_:)), name: .iceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reject(_:)), name: .reject, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(disconnected(_:)), name: .iceDisconnected, object: nil)
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
            case .connecting:
                return direction == .incoming ? [acceptBtn, endBtn] : [endBtn]
            case .connected:
                return [audioMuteBtn, videoMuteBtn, loudSpeakerBtn, flipCameraBtn, chatBtn, endBtn]
            default:
                return [endBtn]
            }
        } else if options.isEnableAudio {
            switch state {
            case .connecting:
                return direction == .incoming ? [acceptBtn, endBtn] : [endBtn]
            case .connected:
                return [audioMuteBtn, loudSpeakerBtn, chatBtn, endBtn]
            default:
                return [endBtn]
            }
        } else if options.isEnableVideo {
            switch state {
            case .connecting:
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
}

extension MediaCallViewController {

    /// Did tap end call button
    /// - Parameter sender: the button that user taped
    @objc func didPressEndCall(_ sender: UIButton) {
        if callDirection == .incoming, callState == .connecting {
            closure?(false)
        }
        client.endCall()
        dismiss(animated: true, completion: nil)
    }

    @objc func didPressAcceptCall(_ sender: UIButton) {
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
        client.isLoudSpeaker = sender.isSelected
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

    @objc func didPressChatControl(_ sender: UIButton) {
        let chatViewController = ChatViewController(sender: myId, to: friendId, client: client, state: .connected)
        chatViewController.modalPresentationStyle = .fullScreen
        self.navigationController?.pushViewController(chatViewController, animated: true)
        newMessageTipLabel.text = ""
    }
}

extension MediaCallViewController {

    @objc func connected(_ notification: NSNotification) {
        self.callState = .connected
    }

    @objc func disconnected(_ notification: NSNotification) {
        self.callState = .hangup
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc func reject(_ notification: NSNotification) {
        self.callState = .reject
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.dismiss(animated: true, completion: nil)
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
