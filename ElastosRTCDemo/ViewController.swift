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

    private let titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "Please enter carrier userId, if the user is not your friend. please add as friend"
        view.numberOfLines = 0
        view.lineBreakMode = .byWordWrapping
        view.textColor = .lightGray
        return view
    }()

    private var friends: Set<FriendCellModel> = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "WebRtc Demo"
        tableView.register(FriendCell.self, forCellReuseIdentifier: NSStringFromClass(FriendCell.self))
        DeviceManager.sharedInstance.start()
        loadMyInfo()
    }

    func setupObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendStatusChanged(notif:)), name: .friendStatusChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleFriendList(notif:)), name: .friendList, object: nil)
    }

    func loadMyInfo() {
        let address = carrier.getAddress()
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
        cell.update(FriendCellModel(id: "xxx", name: "Tomas Shao", avatar: nil, status: .online))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
