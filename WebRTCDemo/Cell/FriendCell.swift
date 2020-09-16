/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

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

    var priority: Int {
        switch self {
        case .online:
            return 1
        case .offline:
            return 2
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
