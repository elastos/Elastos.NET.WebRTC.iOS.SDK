//
//  UIViewController+Empty.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/7/27.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import UIKit

class EmptyView: UIView {

    var titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        view.textColor = .black
        view.font = UIFont.boldSystemFont(ofSize: 18)
        return view
    }()

    var detailLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        view.textColor = .black
        view.numberOfLines = 2
        view.lineBreakMode = .byWordWrapping
        return view
    }()

    lazy var stack: UIStackView = {
        let view = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 10
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: 20)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, detail: String) {
        titleLabel.text = title
        detailLabel.text = detail
    }
}

extension UIViewController {

    private static var emptyViewAssociatedKey: UInt8 = 0

    private var emptyView: EmptyView {
        get {
            if let emptyView = objc_getAssociatedObject(self, &Self.emptyViewAssociatedKey) as? EmptyView {
                return emptyView
            } else {
                let emptyView = EmptyView()
                self.emptyView = emptyView
                return emptyView
            }
        }
        set {
            objc_setAssociatedObject(self, &Self.emptyViewAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func showEmpty(title: String, subTitle: String) {
        if emptyView.superview != nil {
            emptyView.removeFromSuperview()
        }
        emptyView.update(title: title, detail: subTitle)
        view.addSubview(emptyView)
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            emptyView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            emptyView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            emptyView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    func hideEmpty() {
        emptyView.removeFromSuperview()
    }
}
