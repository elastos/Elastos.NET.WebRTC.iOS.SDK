//
//  FriendCell.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/9.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

enum Status: String {
    case online
    case offline

    var textColor: UIColor {
        switch self {
        case .online:
            return .systemGreen
        case .offline:
            return .darkGray
        }
    }
}

struct FriendCellModel: Equatable, Hashable {

    let id: String
    let name: String
    let avatar: URL?
    var status: Status

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

class FriendCell: UITableViewCell {

    private let avatar: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .brown
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 20
        return view
    }()

    private let nameLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.lineBreakMode = .byCharWrapping
        view.numberOfLines = 0
        return view
    }()

    private let idLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.lineBreakMode = .byCharWrapping
        view.numberOfLines = 0
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupSubviews()
        setupConstrants()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(avatar)
        contentView.addSubview(idLabel)
    }

    private func setupConstrants() {
        let views = ["avatar": avatar, "name": nameLabel, "id": idLabel]
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[avatar(40)]-[name]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[name]-[id]-|", options: [], metrics: nil, views: views)
        constraints.append(nameLabel.leadingAnchor.constraint(equalTo: idLabel.leadingAnchor))
        constraints.append(avatar.heightAnchor.constraint(equalTo: avatar.widthAnchor))
        constraints.append(avatar.centerYAnchor.constraint(equalTo: contentView.centerYAnchor))
        constraints.append(idLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor))
        constraints.forEach { $0.priority = .required - 1 }
        NSLayoutConstraint.activate(constraints)
    }

    func update(_ friend: FriendCellModel) {
        nameLabel.text = "[" + friend.name + "]"
        idLabel.text = friend.id
        nameLabel.textColor = friend.status.textColor
        idLabel.textColor = friend.status.textColor
    }
}
