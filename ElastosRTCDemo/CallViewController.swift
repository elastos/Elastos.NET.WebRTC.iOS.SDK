//
//  CallViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/11.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import ElastosCarrierSDK
import ElastosRTC

protocol CallingDelegate: NSObject {
    
    func getClient() -> WebRtcClient
}

enum CallState {
    case calling
    case receiving
    case connecting
    case connected
    case disconnected
}


class CallViewController: UIViewController {

    var friendId: String = ""

    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    
    private let nameLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .orange
        view.text = "Name ?"
        return view
    }()
    
    private lazy var rejectBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Reject", for: .normal)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        view.widthAnchor.constraint(equalToConstant: 80).isActive = true
        view.addTarget(self, action: #selector(rejectCall), for: .touchUpInside)
        view.backgroundColor = .red
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 40
        return view
    }()
    
    private lazy var acceptBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Accept", for: .normal)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        view.widthAnchor.constraint(equalToConstant: 80).isActive = true
        view.addTarget(self, action: #selector(acceptCall), for: .touchUpInside)
        view.backgroundColor = .blue
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 40
        return view
    }()
    
    private lazy var endBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("End", for: .normal)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        view.widthAnchor.constraint(equalToConstant: 80).isActive = true
        view.addTarget(self, action: #selector(endCall), for: .touchUpInside)
        view.backgroundColor = .blue
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 40
        return view
    }()
    
    private lazy var cancelBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Cancel", for: .normal)
        view.heightAnchor.constraint(equalToConstant: 80).isActive = true
        view.widthAnchor.constraint(equalToConstant: 80).isActive = true
        view.addTarget(self, action: #selector(cancelCall), for: .touchUpInside)
        view.backgroundColor = .blue
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 40
        return view
    }()
    
    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [rejectBtn, acceptBtn, endBtn, cancelBtn])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 80
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

    override func viewDidLoad() {
        super.viewDidLoad()

        client?.localVideoView = localVideoView
        client?.remoteVideoView = remoteVideoView
        
        if state == .calling {
            client?.inviteCall(friendId: self.friendId, options: [.audio, .video])
        }
        
        view.backgroundColor = .white
        
        view.addSubview(nameLabel)
        view.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: nameLabel.centerXAnchor),
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -60),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 60)
        ])
        updateUI()
    }
    
    func updateUI() {
        switch state {
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
                self.dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func onBack(_ sender: Any) {
        client?.endCall(friendId: self.friendId)
        self.dismiss(animated: true, completion: nil)
    }
        
    @objc func acceptCall() {
        self.state = .connecting
        closure?(true)
    }
    
    @objc func rejectCall() {
        closure?(false)
    }
    
    @objc func endCall() {
        
    }
    
    @objc func cancelCall() {
        weakDataSource?.getClient().endCall(friendId: self.friendId)
        self.dismiss(animated: true, completion: nil)
    }
}
