//
//  ProfileFooter.swift
//  ElastosRTCDemo
//
//  Created by idanzhu on 2020/6/14.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import UIKit

class ProfileFooter: UITableViewHeaderFooterView {

    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)

        container.addSubview(userIdLabel)
        container.addSubview(addressIdLabel)
        container.addSubview(titleLabel)
        addSubview(container)
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private let container: UIView = {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1.0
        view.layer.cornerRadius = 4.0
        view.layer.masksToBounds = true
        return view
    }()

    let titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "MY INFO"
        return view
    }()

    let userIdLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.numberOfLines = 0
        view.lineBreakMode = .byCharWrapping
        return view
    }()

    let addressIdLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.numberOfLines = 0
        view.lineBreakMode = .byCharWrapping
        return view
    }()

    private func setupConstraints() {
        let views = ["userId": userIdLabel, "addressId": addressIdLabel, "container": container, "title": titleLabel]
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[title]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[userId]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[addressId]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[title]-[userId]-[addressId]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-2-[container]-2-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-2-[container]-2-|", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(constraints)
    }

    func update(userId: String, addressId: String) {
        userIdLabel.text = "[UserID]: " + userId
        addressIdLabel.text = "[Address]: " + addressId
    }
}
