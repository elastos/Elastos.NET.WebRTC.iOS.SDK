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

    private let qrcodeView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "Please enter carrier userId, if the user is not your friend. please add as friend"
        view.numberOfLines = 0
        view.lineBreakMode = .byWordWrapping
        view.textColor = .lightGray
        return view
    }()

    private let textField: UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.adjustsFontSizeToFitWidth = true
        view.textColor = .white
        return view
    }()

    private let bottomLine: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        return view
    }()

    private let tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .grouped)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.register(UITableViewCell.self, forCellReuseIdentifier: NSStringFromClass(UITableViewCell.self))
        return view
    }()

    private var friends: [String] = ["xx"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "WebRtc Demo"
        view.backgroundColor = .darkGray
        DeviceManager.sharedInstance.start()
        setupSubviews()
        setupConstraints()
        loadMyInfo()
    }

    private func setupSubviews() {
        view.addSubview(titleLabel)
        view.addSubview(textField)
        view.addSubview(bottomLine)
        view.addSubview(tableView)
        view.addSubview(qrcodeView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundView = nil
        tableView.backgroundColor = .clear
    }
    
    private func setupConstraints() {
        let views = ["title": titleLabel, "textField": textField, "line": bottomLine, "tableView": tableView, "qrcode": qrcodeView]
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[title]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[textField]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[line]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|[tableView]|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:[title]-20-[textField][line(1)]-20-[tableView]-[qrcode(80)]|", options: [], metrics: nil, views: views)
        constraints.append(titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20))
        constraints.append(qrcodeView.widthAnchor.constraint(equalToConstant: 80))
        constraints.append(qrcodeView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        NSLayoutConstraint.activate(constraints)
    }
    
    func loadMyInfo() {
        let address = carrier.getAddress()
        qrcodeView.image = UIImage(cgImage: EFQRCode.generate(content: address)!)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(UITableViewCell.self), for: indexPath)
        cell.textLabel?.text = friends[indexPath.row]
        cell.backgroundColor = .clear
        cell.textLabel?.textColor = .white
        return cell
    }
}
