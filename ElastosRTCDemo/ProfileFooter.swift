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
        
        contentView.addSubview(userIdLabel)
        contentView.addSubview(addressIdLabel)
        setupConstraints()
        contentView.backgroundColor = .brown
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        let views = ["userId": userIdLabel, "addressId": addressIdLabel]
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[userId]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-[addressId]-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:|-[userId]-[addressId]", options: [], metrics: nil, views: views)
        NSLayoutConstraint.activate(constraints)
    }
    
    func update(userId: String, addressId: String) {
        userIdLabel.text = "[UserID]: " + userId
        addressIdLabel.text = "[Address]: " + addressId
    }
    
}
