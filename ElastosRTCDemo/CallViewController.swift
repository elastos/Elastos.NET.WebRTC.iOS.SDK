//
//  CallViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/11.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

protocol CallingDelegate: NSObject {
    
    func getClient() -> WebRtcClient
    func carrierInstance() -> Carrier
}

enum CallDirection {
    case outgoing
    case incoming
}

enum CallState: Equatable {
    case calling
    case receiving
    case connecting
    case connected
    case disconnected(reason: CallReason)

    var title: String {
        switch self {
        case .calling:
            return "正在呼出..."
        case .receiving:
            return "正在呼入..."
        case .connecting:
            return "正在连接中..."
        case .connected:
            return "已连接"
        case .disconnected(let reason):
            switch reason {
            case .cancel:
                return "已取消通话"
            case .close:
                return "已关闭通话"
            case .missing:
                return "missing"
            case .reject:
                return "对方拒绝接听"
            case .unknown:
                return "unknown 挂断"
            }
        }
    }
}

func makeButton(image: UIImage? = nil, selected: UIImage? = nil, title: String? = nil, target: Any, selector: Selector) -> UIButton {
    let view = UIButton(type: .custom)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.setTitle(title, for: .normal)
    view.setBackgroundImage(image, for: .normal)
    view.setBackgroundImage(selected, for: .selected)
    view.heightAnchor.constraint(equalToConstant: 80).isActive = true
    view.widthAnchor.constraint(equalToConstant: 80).isActive = true
    view.layer.masksToBounds = true
    view.layer.cornerRadius = 40
    view.addTarget(target, action: selector, for: .touchUpInside)
    return view
}

class CallViewController: UIViewController {

    var friendId: String = ""
    
    private let nameLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .orange
        view.text = "Name ?"
        return view
    }()
    
    private lazy var rejectBtn = makeButton(image: UIImage(named: "hangup"), target: self, selector: #selector(didPressReject(_:)))
    private lazy var acceptBtn = makeButton(image: UIImage(named: "accept"), target: self, selector: #selector(didPressAccept(_:)))
    private lazy var endBtn = makeButton(image: UIImage(named: "end-call"), target: self, selector: #selector(didPressEndup(_:)))
    private lazy var cancelBtn = makeButton(image: UIImage(named: "end-call"), target: self, selector: #selector(didPressCancel(_:)))

    private lazy var flipCameraBtn = makeButton(image: UIImage(named: "video-switch-camera-unselected"),
                                                target: self,
                                                selector: #selector(didPressFlipCamera(_:)))

    private lazy var speakerBtn = makeButton(image: UIImage(named: "audio-call-speaker-inactive"),
                                             selected: UIImage(named: "audio-call-speaker-active"),
                                             target: self, selector: #selector(didPressLoudSpeaker(_:)))

    private lazy var muteAudioBtn = makeButton(image: UIImage(named: "video-mute-unselected"),
                                               selected: UIImage(named: "video-mute-selected"),
                                               target: self,
                                               selector: #selector(toggleAudio(_:)))

    private lazy var muteVideoBtn = makeButton(image: UIImage(named: "video-video-unselected"),
                                               selected: UIImage(named: "video-video-selected"),
                                               target: self,
                                               selector: #selector(toggleVideo(_:)))

    private lazy var chatBtn = makeButton(image: UIImage(named: "conversation"), target: self, selector: #selector(didPressConversation(_:)))

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [acceptBtn, rejectBtn, endBtn, cancelBtn])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 80
        return view
    }()

    private lazy var toolStack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [flipCameraBtn, speakerBtn, muteAudioBtn, muteVideoBtn])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.distribution = .fillProportionally
        view.spacing = 6.0
        return view
    }()

    var client: WebRtcClient? {
        self.weakDataSource?.getClient()
    }

    weak var weakDataSource: CallingDelegate?
    
    var closure: ((Bool) -> Void)?

    var state: CallState = .calling {
        didSet {
            updateUI()
        }
    }

    var callOptions: MediaOptions = [.audio, .video]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if state == .calling {
            client?.inviteCall(friendId: self.friendId, options: callOptions)
        }

        view.backgroundColor = .black

        view.addSubview(nameLabel)
        view.addSubview(stackView)
        view.addSubview(toolStack)
        view.addSubview(chatBtn)

        chatBtn.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: nameLabel.centerXAnchor),
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -60),
            toolStack.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: toolStack.bottomAnchor, constant: 20),
            view.centerXAnchor.constraint(equalTo: toolStack.centerXAnchor),

            chatBtn.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            chatBtn.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 20),
        ])
        updateUI()
        NotificationCenter.default.addObserver(self, selector: #selector(iceDidConnected), name: .iceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(reject(_:)), name: .reject, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(iceDidDisconnected), name: .iceDisconnected, object: nil)

        let localVideoView = client?.getLocalVideoView()
        let remoteVideoView = client?.getRemoteVideoView()

        guard let localView = localVideoView, let remoteView = remoteVideoView else { return }
        view.addSubview(localView)
        view.addSubview(remoteView)

        self.view.sendSubviewToBack(remoteView)
        self.view.sendSubviewToBack(localView)

        client?.setLocalVideoFrame(CGRect(x: 0, y: 0, width: self.view.frame.width, height: self.view.frame.height))
        client?.setRemoteVideoFrame(CGRect(x: 0, y: 100, width: 50, height: 150))

        localView.isHidden = client?.options.isEnableVideo == false
        remoteView.isHidden = client?.options.isEnableVideo == false
    }

    @objc func iceDidConnected() {
        self.state = .connected
    }

    @objc func iceDidDisconnected() {
        self.state = .disconnected(reason: .cancel)
    }

    func updateUI() {
        DispatchQueue.main.async {
            switch self.state {
            case .calling:
                self.acceptBtn.isHidden = true
                self.endBtn.isHidden = true
                self.rejectBtn.isHidden = true
                self.cancelBtn.isHidden = false
            case .receiving:
                self.acceptBtn.isHidden = false
                self.rejectBtn.isHidden = false
                self.cancelBtn.isHidden = true
                self.endBtn.isHidden = true
            case .connected:
                self.acceptBtn.isHidden = true
                self.rejectBtn.isHidden = true
                self.cancelBtn.isHidden = true
                self.endBtn.isHidden = false
            case .connecting:
                self.acceptBtn.isHidden = true
                self.rejectBtn.isHidden = true
                self.cancelBtn.isHidden = false
                self.endBtn.isHidden = true
            case .disconnected:
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            self.nameLabel.text = self.state.title
            self.flipCameraBtn.isEnabled = self.callOptions.isEnableVideo
            self.muteVideoBtn.isEnabled = self.callOptions.isEnableVideo
            self.muteAudioBtn.isEnabled = self.callOptions.isEnableAudio
            self.chatBtn.isEnabled = self.callOptions.isEnableDataChannel

            self.muteVideoBtn.isSelected = self.client?.isEnableVideo == false
            self.muteAudioBtn.isSelected = self.client?.isEnableAudio == false
        }
    }

    @IBAction func onBack(_ sender: Any) {
        client?.endCall(friendId: self.friendId)
        self.dismiss(animated: true, completion: nil)
    }

    @objc func reject(_ notification: Notification) {
        guard let reason = notification.object as? CallReason else { return assertionFailure() }
        self.state = .disconnected(reason: reason)
    }
}

extension CallViewController {

    @objc func didPressFlipCamera(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.client?.switchCarmeraToPosition(sender.isSelected ? .back : .front)
    }

    @objc func didPressLoudSpeaker(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
    }

    @objc func didPressReject(_ sender: UIButton) {
        closure?(false)
        dismiss(animated: true, completion: nil)
    }

    @objc func didPressEndup(_ sender: UIButton) {
        client?.endCall(friendId: self.friendId)
        dismiss(animated: true, completion: nil)
    }

    @objc func didPressCancel(_ sender: UIButton) {
        client?.endCall(friendId: self.friendId)
        dismiss(animated: true, completion: nil)
    }

    @objc func didPressAccept(_ sender: UIButton) {
        state = .connecting
        closure?(true)
    }

    @objc func didPressConversation(_ sender: UIButton) {
        guard let userId = self.weakDataSource?.carrierInstance().getAddress(),
            let name = try? self.weakDataSource?.carrierInstance().getSelfUserInfo(), let client = client else { return }
        let chat = ChatViewController(sender: MockUser(senderId: userId, displayName: name.name ?? "No Name"), client: client)
        showDetailViewController(chat, sender: nil)
    }

    @objc func toggleAudio(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        client?.isEnableAudio = !sender.isSelected
    }

    @objc func toggleVideo(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        client?.isEnableVideo = !sender.isSelected
    }
}
