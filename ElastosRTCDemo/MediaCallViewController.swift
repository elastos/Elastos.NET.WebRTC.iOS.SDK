//
//  MediaCallViewController.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/7/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

enum MediaCallType {
    case audio
    case video

    var title: String {
        switch self {
        case .audio:
            return "Audio Call"
        case .video:
            return "Video Call"
        }
    }
}

enum MeidaCallState {
    case connecting
    case connected
    case hangup
    case cancel
}

enum MediaCallDirection {
    case incoming
    case outgoing
}

class MediaCallViewController: UIViewController {

    var callType: MediaCallType = .audio {
        didSet {
            updateToolsStack()
        }
    }

    var callState: MeidaCallState = .connecting {
        didSet {
            updateToolsStack()
        }
    }

    var callDirection: MediaCallDirection = .incoming {
        didSet {
            updateToolsStack()
        }
    }

    private lazy var endBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "end-call"), for: .normal)
        view.addTarget(self, action: #selector(didPressEndCall(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var acceptBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "accept"), for: .normal)
        view.addTarget(self, action: #selector(didPressAcceptCall(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var audioMuteBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "audio-call-active"), for: .normal)
        view.setImage(UIImage(named: "audio-call-inactive"), for: .selected)
        view.addTarget(self, action: #selector(didPressAudioControl(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var loudSpeakerBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "loud-speaker-active"), for: .normal)
        view.setImage(UIImage(named: "loud-speaker-inactive"), for: .selected)
        view.addTarget(self, action: #selector(didPressLoudSpeakerControl(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var videoMuteBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "video-active"), for: .normal)
        view.setImage(UIImage(named: "video-inactive"), for: .selected)
        view.addTarget(self, action: #selector(didPressVideoControl(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var flipCameraBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "video-switch-camera"), for: .normal)
        view.addTarget(self, action: #selector(didPressCameraControl(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var chatBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setImage(UIImage(named: "conversation"), for: .normal)
        view.addTarget(self, action: #selector(didPressCameraControl(_:)), for: .touchUpInside)
        return view
    }()

    private lazy var toolStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [self.audioMuteBtn, self.videoMuteBtn, self.loudSpeakerBtn, self.flipCameraBtn, self.chatBtn, self.acceptBtn, self.endBtn])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .equalSpacing

        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = callType.title

        view.addSubview(toolStack)
        NSLayoutConstraint.activate([
            toolStack.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
            toolStack.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
            toolStack.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor)
        ])
    }

    func updateToolsStack() {
        toolStack.arrangedSubviews.forEach { $0.isHidden = true }
        let views = tools(state: callState, direction: callDirection, type: callType)
        views.forEach { $0.isHidden = false }
    }

    func tools(state: MeidaCallState, direction: MediaCallDirection, type: MediaCallType) -> [UIView] {
        switch type {
        case .audio:
            switch state {
            case .connecting:
                return direction == .incoming ? [self.acceptBtn, self.endBtn] : [self.endBtn]
            case .connected:
                return [self.audioMuteBtn, self.loudSpeakerBtn, self.chatBtn, self.endBtn]
            default:
                return []
            }
        case .video:
            switch state {
            case .connecting:
                return direction == .incoming ? [self.acceptBtn, self.endBtn] : [self.endBtn]
            case .connected:
                return [self.audioMuteBtn, self.videoMuteBtn, self.loudSpeakerBtn, self.flipCameraBtn, self.chatBtn, self.endBtn]
            default:
                return []
            }
        }
    }
}

extension MediaCallViewController {

    /// Did tap end call button
    /// - Parameter sender: the button that user taped
    @objc func didPressEndCall(_ sender: UIButton) {

    }

    @objc func didPressAcceptCall(_ sender: UIButton) {

    }

    /// Did tap audio mute control button
    /// - Parameter sender: normal: unmute, selected: mute
    @objc func didPressAudioControl(_ sender: UIButton) {

    }

    /// Did tap loud speaker control button
    /// - Parameter sender: normal: loud speaker, selected: micro
    @objc func didPressLoudSpeakerControl(_ sender: UIButton) {

    }

    /// Did tap video mute control button
    /// - Parameter sender: normal: enable local video, selected: disable local video
    @objc func didPressVideoControl(_ sender: UIButton) {

    }

    @objc func didPressCameraControl(_ sender: UIButton) {

    }
}
