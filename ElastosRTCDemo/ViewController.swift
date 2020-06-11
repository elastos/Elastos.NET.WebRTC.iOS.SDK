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
import ElastosWebRtc

class ViewController: UIViewController, CarrierDelegate {

    var carrier: Carrier {
        DeviceManager.sharedInstance.carrierInst
    }

    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var myUserIdLabel: UILabel!
    @IBOutlet weak var myQRCodeView: UIImageView!

    private var friends: Set<FriendCellModel> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupObserver()
        tableView.register(FriendCell.self, forCellReuseIdentifier: NSStringFromClass(FriendCell.self))
        DeviceManager.sharedInstance.start()
        loadMyInfo()
    }
    @IBAction func addAsFriend(_ sender: Any) {
        if textField.text?.isEmpty == false {
            try? carrier.addFriend(with: textField.text!, withGreeting: "hi my friend.")
        }
    }
    
    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendStatusChanged(notif:)), name: .friendStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendList(notif:)), name: .friendList, object: nil)
    }

    func loadMyInfo() {
        let address = carrier.getAddress()
        myUserIdLabel.text = address
        print(address)
        myQRCodeView.image = UIImage(cgImage: EFQRCode.generate(content: address)!)
    }

    @objc func handleFriendStatusChanged(notif: NSNotification) {
//        guard let friendState = notif.userInfo?["friendState"] as? CarrierConnectionStatus,
//            let id = notif.userInfo?["id"] as? String else {
//            return assertionFailure("missing data")
//        }
    }

    @objc func handleFriendList(notif: NSNotification) {
        guard let list = notif.userInfo?["friends"] as? [CarrierFriendInfo] else {
            return assertionFailure("missing data")
        }
        friends = Set(list.map({ $0.convert() }))
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "callingPage", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let calling = segue.destination as? CallViewController, let index = tableView.indexPathForSelectedRow?.row {
            calling.friendId = Array(friends)[index].id
        }
    }
}

extension CarrierConnectionStatus {

    var status: Status {
        switch self {
        case .Connected:
            return .online
        case .Disconnected:
            return .offline
        }
    }
}

extension CarrierPresenceStatus {

    var status: Status {
        switch self {
        case .None:
            return .online
        case .Busy:
            return .busy
        case .Away:
            return .away
        }
    }
}

extension CarrierFriendInfo {

    func convert() -> FriendCellModel {
        FriendCellModel(id: self.userId ?? "no user id",
                        name: self.label ?? self.name ?? "no name",
                        avatar: nil,
                        status: self.presence.status)
    }
}
