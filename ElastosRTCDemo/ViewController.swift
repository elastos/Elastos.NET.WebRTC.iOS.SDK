//
//  ViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/2.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import EFQRCode
import ElastosCarrierSDK
import ElastosRTC
import AVFoundation

class ViewController: UIViewController, CarrierDelegate {

    var carrier: Carrier {
        DeviceManager.sharedInstance.carrierInst
    }

    lazy var rtcClient: WebRtcClient = {
        let client = WebRtcClient(carrier: self.carrier, delegate: self)
        return client
    }()

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    private var friends: [FriendCellModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupObserver()
        tableView.register(FriendCell.self, forCellReuseIdentifier: NSStringFromClass(FriendCell.self))
        tableView.register(ProfileFooter.self, forHeaderFooterViewReuseIdentifier: NSStringFromClass(ProfileFooter.self))
        tableView.sectionFooterHeight = UITableView.automaticDimension
        DeviceManager.sharedInstance.start()

        checkPermission()
    }

    func checkPermission() {
        // Request permission to record.
         AVAudioSession.sharedInstance().requestRecordPermission { granted in
             if granted {
                 // The user granted access. Present recording interface.
             } else {
                self.alert(message: "Open: Settings -> Privacy -> Microphone")
             }
         }

        // Request permission to capture
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: // The user has previously granted access to the camera.
                break

            case .notDetermined: // The user has not yet been asked for camera access.
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if granted == false {
                        self.alert(message: "Open: Settings -> Privacy -> Camera")
                    }
                }

            case .denied: // The user has previously denied access.
                self.alert(message: "Open: Settings -> Privacy -> Camera")

            case .restricted: // The user can't grant access due to restrictions.
                self.alert(message: "Open: Settings -> Privacy -> Camera")
        @unknown default:
            self.alert(message: "Open: Settings -> Privacy -> Camera")
        }
    }

    func alert(message: String) {
        let vc = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        present(vc, animated: true, completion: nil)
    }

    @IBAction func addAsFriend(_ sender: Any) {
        if textField.text?.isEmpty == false {
            do {
                try carrier.addFriend(with: textField.text!, withGreeting: "hi my friend.")
            } catch {
                print("add as friend error, due to \(error)")
            }
        }

        self.view.endEditing(true)
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendStatusChanged(_:)), name: .friendStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendList(_:)), name: .friendList, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newFriendAdded(_:)), name: .friendAdded, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(newFriendAdded(_:)), name: .friendInfoChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didBecomeReady), name: .didBecomeReady, object: nil)
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

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        guard let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: NSStringFromClass(ProfileFooter.self)) as? ProfileFooter else { return nil }
        print("userID: \(carrier.getUserId()), addressID: \(carrier.getAddress())")
        view.update(userId: carrier.getUserId(), addressId: carrier.getAddress())
        return view
    }

    func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let friend = friends[indexPath.row]
        call(friendId: friend.id)
    }

    func call(friendId: String) {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        let callVc = sb.instantiateViewController(withIdentifier: "call_page") as! CallViewController
        callVc.state = .calling
        callVc.friendId = friendId
        callVc.weakDataSource = self

        let alert = UIAlertController(title: "选择通话类型", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "语音", style: .default, handler: { [weak self] _ in
            callVc.callOptions = [.audio]
            self?.present(callVc, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "视频语音", style: .destructive, handler: { [weak self] _ in
            callVc.callOptions = [.audio, .video]
            self?.present(callVc, animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        alert.modalPresentationStyle = .popover
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = tableView;
            presenter.sourceRect = tableView.bounds;
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
            print("❌ not found friend information in friendslist")
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
    }
}

extension ViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.textField, let content = textField.text {
            addAsFriend(content)
        }
        return true
    }
}

extension ViewController: CallingDelegate {

    func getClient() -> WebRtcClient {
        return self.rtcClient
    }
}

extension ViewController: WebRtcDelegate {

    func onInvite(friendId: String, completion: @escaping (Bool) -> Void) {
        print("reject or accept")
        DispatchQueue.main.async {
            let sb = UIStoryboard(name: "Main", bundle: nil)
            let callVc = sb.instantiateViewController(withIdentifier: "call_page") as! CallViewController

            callVc.closure = completion
            callVc.state = .receiving
            callVc.weakDataSource = self
            self.present(callVc, animated: true, completion: nil)
        }
    }

    func onAnswer() {

    }

    func onActive() {

    }

    func onEndCall(reason: CallReason) {
        NotificationCenter.default.post(name: .reject, object: reason)
    }

    func onIceConnected() {
        NotificationCenter.default.post(name: .iceConnected, object: nil)
    }

    func onIceDisconnected() {
        NotificationCenter.default.post(name: .iceDisconnected, object: nil)
    }

    func onConnectionError(error: Error) {

    }

    func onConnectionClosed() {

    }
}
