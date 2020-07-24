//
//  ViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/2.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import EFQRCode
import AVFoundation

class ViewController: UIViewController, CarrierDelegate {

    var carrier: Carrier {
        DeviceManager.sharedInstance.carrierInst
    }

    lazy var rtcClient: WebRtcClient = {
        let client = WebRtcClient(carrier: self.carrier, delegate: self)
        return client
    }()

    @IBOutlet weak var tableView: UITableView!

    private var friends: [FriendCellModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupObserver()
        tableView.register(FriendCell.self, forCellReuseIdentifier: NSStringFromClass(FriendCell.self))
        DeviceManager.sharedInstance.start()
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .done, target: self, action: #selector(openMyInfo))

        checkPermission()
    }

    func checkPermission() {
        // Request permission to record.
         AVAudioSession.sharedInstance().requestRecordPermission { granted in
            if !granted {
                 self.alert(message: "Open: Settings -> Privacy -> Microphone")
            }
         }

        // Request permission to capture
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    self.alert(message: "Open: Settings -> Privacy -> Camera")
                }
            }
        case .denied:
            self.alert(message: "Open: Settings -> Privacy -> Camera")
        case .restricted:
            self.alert(message: "Open: Settings -> Privacy -> Camera")
        @unknown default:
            self.alert(message: "Open: Settings -> Privacy -> Camera")
        }
    }

    func alert(message: String) {
        let vc = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(vc, animated: true, completion: nil)
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendStatusChanged(_:)), name: .friendStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendList(_:)), name: .friendList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newFriendAdded(_:)), name: .friendAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newFriendAdded(_:)), name: .friendInfoChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeReady), name: .didBecomeReady, object: nil)
    }
    
    @objc func openMyInfo() {
        let vc = MyProfileViewController()
        vc.update(address: carrier.getAddress(), userId: carrier.getUserId(), carrier: self.carrier)
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "My Favorite"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(FriendCell.self), for: indexPath) as? FriendCell else { fatalError() }
        let friend = friends[indexPath.row]
        cell.update(FriendCellModel(id: friend.id, name: friend.name, avatar: nil, status: friend.status))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let friend = friends[indexPath.row]

        let alert = UIAlertController(title: "Call Type", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let nav: UINavigationController = {
                let callVc = MediaCallViewController(direction: .outgoing, type: .audio, client: self.rtcClient, friendId: friend.id)
                let nav = UINavigationController(rootViewController: callVc)
                nav.modalPresentationStyle = .fullScreen
                return nav
            }()
            self.present(nav, animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "Data", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let nav: UINavigationController = {
                let mock = MockUser(senderId: self.carrier.getUserId(), displayName: "")
                let chatVc = ChatViewController(sender: mock, client: self.rtcClient, state: .connecting)
                let nav = UINavigationController(rootViewController: chatVc)
                nav.modalPresentationStyle = .fullScreen
                return nav
            }()

            self.present(nav, animated: true) { self.rtcClient.inviteCall(friendId: friend.id, options: [.data]) }
         }))

        alert.addAction(UIAlertAction(title: "Audio + Video + Data", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let nav: UINavigationController = {
                let callVc = MediaCallViewController(direction: .outgoing, type: .video, client: self.rtcClient, friendId: friend.id)
                let nav = UINavigationController(rootViewController: callVc)
                nav.modalPresentationStyle = .fullScreen
                return nav
            }()
            self.present(nav, animated: true, completion: nil)
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.modalPresentationStyle = .popover
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = tableView
            presenter.sourceRect = tableView.rectForRow(at: indexPath)
        }
        present(alert, animated: true, completion: nil)
    }
}

/// Handle Notification
extension ViewController {

    @objc func handleFriendStatusChanged(_ notification: NSNotification) {
        guard let id = notification.userInfo?["friendId"] as? String,
            let status = notification.userInfo?["status"] as? CarrierConnectionStatus else { return assertionFailure("missing data") }
        if var found = friends.first(where: { $0.id == id }) {
            found.status = status.status
            upSert(friend: found)
        } else {
            assertionFailure("❌ not found friend information in friendslist")
        }
    }

    @objc func newFriendAdded(_ notification: NSNotification) {
        guard let friend = notification.userInfo?["friend"] as? CarrierFriendInfo else { return assertionFailure("missing data") }
        upSert(friend: friend.convert())
    }

    @objc func handleFriendList(_ notification: NSNotification) {
        guard let list = notification.userInfo?["friends"] as? [CarrierFriendInfo] else {
            return assertionFailure("missing data")
        }
        friends = list.map { $0.convert() }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func upSert(friend: FriendCellModel) {
        if let index = friends.firstIndex(of: friend) {
            friends.remove(at: index)
            friends.insert(friend, at: index)
        } else {
            friends.append(friend)
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    @objc func didBecomeReady() {
        print(self.rtcClient)
        DataManager.shared.me = self.carrier.getUserId()
    }
}

extension ViewController: WebRtcDelegate {

    func onReceiveMessage(_ data: Data, isBinary: Bool, channelId: Int) {
        print("✅ [RECV]: \(String(describing: String(data: data, encoding: .utf8)))")
        let content = String(describing: String(data: data, encoding: .utf8))
        DataManager.shared.write(message: content, from: self.rtcClient.friendId!, to: self.carrier.getUserId())
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .receiveMessage, object: nil, userInfo: ["data": data, "isBinary": isBinary, "userId": channelId])
        }
    }

    func onInvite(friendId: String, mediaOption: MediaOptions, completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async {
            let av = mediaOption.isEnableAudio && mediaOption.isEnableVideo
            let callViewController = MediaCallViewController(direction: .incoming,
                                                             type: av ? .video : .audio,
                                                             client: self.rtcClient,
                                                             friendId: friendId,
                                                             closure: completion)
            let nav = UINavigationController(rootViewController: callViewController)
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }

    func onAnswer() {

    }

    func onActive() {

    }

    func onEndCall(reason: HangupType) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .reject, object: reason)
        }
    }

    func onIceConnected() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iceConnected, object: nil)
        }
    }

    func onIceDisconnected() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .iceDisconnected, object: nil)
        }
    }

    func onConnectionError(error: Error) {

    }

    func onConnectionClosed() {

    }
}
