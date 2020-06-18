//
//  InviteViewController.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/6/18.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

class InviteViewController: UIViewController {

    private let nameLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .blue
        return view
    }()

    private lazy var rejectBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Reject", for: .normal)
        view.heightAnchor.constraint(equalToConstant: 44).isActive = true
        view.widthAnchor.constraint(equalToConstant: 44).isActive = true
        view.addTarget(self, action: #selector(rejectCall), for: .touchUpInside)
        return view
    }()

    private lazy var acceptBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Accept", for: .normal)
        view.heightAnchor.constraint(equalToConstant: 44).isActive = true
        view.widthAnchor.constraint(equalToConstant: 44).isActive = true
        view.addTarget(self, action: #selector(acceptCall), for: .touchUpInside)
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [rejectBtn, acceptBtn])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .horizontal
        view.spacing = 20
        return view
    }()

    var closure: ((Bool) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(nameLabel)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: nameLabel.centerXAnchor),
            view.centerXAnchor.constraint(equalTo: stackView.centerXAnchor),
            view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -60),
            view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 60)
        ])
    }

    @objc func acceptCall() {
        closure?(true)
    }

    @objc func rejectCall() {
        closure?(false)
    }
}
