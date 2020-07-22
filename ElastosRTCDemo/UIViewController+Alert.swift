//
//  UIViewController+Alert.swift
//  ElastosRTCDemo
//
//  Created by idanzhu on 2020/7/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alert(title: String? = nil, message: String? = nil, closure: ((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .cancel, handler: closure))
        present(alert, animated: true, completion: nil)
    }
}