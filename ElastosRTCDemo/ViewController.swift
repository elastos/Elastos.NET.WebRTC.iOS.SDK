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
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(testMessage))
    }
    
    @objc func testMessage() {
        do {
            try self.carrier.sendFriendMessage(to: "Djyqhb7skN1uNa5phVp275MoMUFCZ1g4QvxYmPbdfWEo", "hi message".data(using: .utf8)!)
            try self.carrier.sendInviteFriendRequest(to: "Djyqhb7skN1uNa5phVp275MoMUFCZ1g4QvxYmPbdfWEo", withData: "hi invite message", responseHandler: { (_, _, _, _, _) in
            })
        } catch {
            print(error)
        }
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
    }

    func loadMyInfo() {
        let address = carrier.getAddress()
        print(carrier.getUserId())
        myUserIdLabel.text = address
        print(address)
        myQRCodeView.image = UIImage(cgImage: EFQRCode.generate(content: address)!)
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
        performSegue(withIdentifier: "callingPage", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let navigation = segue.destination as? UINavigationController,
			let calling = navigation.viewControllers.first as? CallViewController,
			let index = tableView.indexPathForSelectedRow?.row else { return assertionFailure() }
        calling.friendId = Array(friends)[index].id
    }
}

/// Handle Notification
extension ViewController {

	@objc func handleFriendStatusChanged(_ notification: NSNotification) {

	}
	
	@objc func newFriendAdded(_ notification: NSNotification) {
		guard let friend = notification.userInfo?["friend"] as? CarrierFriendInfo else { return assertionFailure("missing data") }
        friends.remove(friend.convert())
		friends.insert(friend.convert())
	}

	@objc func handleFriendList(_ notification: NSNotification) {
		guard let list = notification.userInfo?["friends"] as? [CarrierFriendInfo] else {
			return assertionFailure("missing data")
		}
		friends = Set(list.map({ $0.convert() }))
		DispatchQueue.main.async {
			self.tableView.reloadData()
		}
	}
}
