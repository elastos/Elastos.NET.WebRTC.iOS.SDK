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

    var dictData: [String: Data] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupObserver()
        tableView.backgroundColor = .white
        tableView.register(FriendCell.self, forCellReuseIdentifier: NSStringFromClass(FriendCell.self))
        DeviceManager.sharedInstance.start()
        
        self.title = "WebRTC Demo(Not Ready)"
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

    deinit {
        print("[FREE MEMORY] \(self)")
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
            self.mediaCall(friendId: friend.id, options: [.audio, .data], direction: .outgoing)
        }))

        alert.addAction(UIAlertAction(title: "Data", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.chat(friendId: friend.id, direction: .outgoing)
         }))

        alert.addAction(UIAlertAction(title: "Audio + Video + Data", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            self.mediaCall(friendId: friend.id, options: [.audio, .video, .data], direction: .outgoing)
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
        friends = list.map { $0.convert() }.sorted(by: { (m1, m2) -> Bool in m1.status.priority < m2.status.priority })
        updateTableView()
    }

    func upSert(friend: FriendCellModel) {
        if let index = friends.firstIndex(of: friend) {
            friends.remove(at: index)
            friends.insert(friend, at: index)
        } else {
            friends.append(friend)
        }
        friends = friends.sorted(by: { (m1, m2) -> Bool in m1.status.priority < m2.status.priority })
        updateTableView()
    }

    @objc func didBecomeReady() {
        print(self.rtcClient)
        DataManager.shared.me = self.carrier.getUserId()
        DispatchQueue.main.async {
            self.title = "WebRTC Demo"
        }
    }

    func updateTableView() {
        DispatchQueue.main.async {
            if self.friends.isEmpty {
                self.showEmpty(title: "没有好友信息", subTitle: "请点击右上角Info按钮，邀请好友进行语音视频通话")
            } else {
                self.hideEmpty()
            }
            self.tableView.reloadData()
        }
    }
}

extension ViewController: WebRtcDelegate {

    func onWebRtc(_ client: WebRtcClient, didChangeState state: WebRtcCallState) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .rtcStateChanged, object: nil, userInfo: ["state": state])
        }
    }

    func onReceiveMessage(_ data: Data, isBinary: Bool, channelId: Int) {
        DispatchQueue.main.async {
            if isBinary {
                guard let dict = dataToDict(data: data),
                    let fileId = dict["fileId"] as? String,
                    let str = dict["data"] as? String,
                    let data = Data(base64Encoded: str),
                    let index = dict["index"] as? Int,
                    let isEnd = dict["end"] as? Bool else {
                        fatalError("error format message")
                }
                var tmpData = self.dictData[fileId] ?? Data()
                tmpData.append(data)
                if index == 0 {
                    NotificationCenter.default.post(name: .receiveMessage, object: "传输开始" + formatter.string(from: Date()), userInfo:["isBinary": false, "userId": channelId, "type": "system"])
                }
                if isEnd {
                    guard let image = UIImage(data: tmpData) else { return self.alert(message: "收到图片, 图片格式出错") }
                    DataManager.shared.write(image: image, from: self.rtcClient.friendId!, to: self.carrier.getUserId())
                    NotificationCenter.default.post(name: .receiveMessage, object: image, userInfo: ["isBinary": isBinary, "userId": channelId, "size": image.getSizeIn(.megabyte)])
                    self.dictData.removeValue(forKey: fileId)
                } else {
                    self.dictData[fileId] = tmpData
                }
                return
            }
            let content = String(describing: String(data: data, encoding: .utf8))
            DataManager.shared.write(message: content, from: self.rtcClient.friendId!, to: self.carrier.getUserId())
            NotificationCenter.default.post(name: .receiveMessage, object: content, userInfo: ["isBinary": isBinary, "userId": channelId])
        }
    }

    func onInvite(friendId: String, mediaOption: MediaOptions, completion: @escaping (Bool) -> Void) {
        print("declined or accept: \(mediaOption)")
        DispatchQueue.main.async {
            if mediaOption.isEnableAudio == false, mediaOption.isEnableVideo == false, mediaOption.isEnableDataChannel {
                let alert = UIAlertController(title: "Invite Chat", message: friendId, preferredStyle: .alert)
                alert.addAction(.init(title: "Accept", style: .default, handler: { [weak self] _ in
                    self?.chat(friendId: friendId, direction: .incoming)
                    completion(true)
                }))
                alert.addAction(.init(title: "Declined", style: .destructive, handler: { _ in
                    completion(false)
                }))
                self.present(alert, animated: true, completion: nil)
                return
            } else {
                self.mediaCall(friendId: friendId, options: mediaOption, direction: .incoming, closure: completion)
            }
        }
    }
}

extension ViewController {
    
    func chat(friendId: String, direction: MediaCallDirection) {
        let nav: UINavigationController = {
            let chatVc = ChatViewController(sender: carrier.getUserId(), to: friendId, client: rtcClient, state: .connecting)
            let nav = UINavigationController(rootViewController: chatVc)
            nav.modalPresentationStyle = .fullScreen
            return nav
        }()

        self.present(nav, animated: true) {
            if direction == .outgoing {
                self.rtcClient.inviteCall(friendId: friendId, options: [.data])
            }
        }
    }
    
    func mediaCall(friendId: String, options: MediaOptions, direction: MediaCallDirection, closure: BoolClosure? = nil) {
        let nav: UINavigationController = {
            let callVc = MediaCallViewController(direction: direction,
                                                 options: options,
                                                 client: rtcClient,
                                                 friendId: friendId,
                                                 myId: carrier.getUserId(),
                                                 closure: closure)
            let nav = UINavigationController(rootViewController: callVc)
            nav.modalPresentationStyle = .fullScreen
            return nav
        }()
        self.present(nav, animated: true, completion: nil)
    }
}
