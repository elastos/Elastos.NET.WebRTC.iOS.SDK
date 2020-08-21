//
//  UIViewController+Alert.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/7/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func alert(title: String? = nil, message: String? = nil, closure: ((UIAlertAction) -> Void)? = nil, cancelled:((UIAlertAction) -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "OK", style: .default, handler: closure ))
        if let cancelClosure = cancelled {
            alert.addAction(.init(title: "Cancel", style: .cancel, handler: cancelClosure))
        }
        topViewController().present(alert, animated: true, completion: nil)
    }

    func topViewController() -> UIViewController {
        if var topController = UIApplication.shared.keyWindow?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }
            return topController
        }
        return self
    }
}
