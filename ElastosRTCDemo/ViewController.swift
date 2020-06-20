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
        let friend = Array(friends)[indexPath.row]
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
        performSegue(withIdentifier: "calling", sender: self)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "calling":
            guard let calling = (segue.destination as? UINavigationController)?.viewControllers.first as? CallViewController else { return }
            calling.friendId = friends[tableView.indexPathForSelectedRow?.row ?? 0].id
            calling.weakDataSource = self
            calling.state = .calling
        case "setting":
            break
        default:
            assertionFailure("not support now")
        }
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
        if textField == self.textField {
            addAsFriend(textField)
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
            let vc = CallViewController(nibName: nil, bundle: nil)
            vc.closure = completion
            vc.state = .receiving
            self.present(vc, animated: true, completion: nil)
        }
    }

    func onAnswer() {

    }

    func onActive() {

    }

    func onEndCall(reason: CallReason) {

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
