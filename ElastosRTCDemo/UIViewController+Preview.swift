//
//  UIViewController+Preview.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/8/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {

    private static var previewViewAssociatedKey: UInt8 = 0
    var imageView: UIImageView {
                get {
            if let view = objc_getAssociatedObject(self, &Self.previewViewAssociatedKey) as? UIImageView {
                return view
            } else {
                let view: UIImageView = {
                    let view = UIImageView()
                    view.translatesAutoresizingMaskIntoConstraints = false
                    view.contentMode = .scaleAspectFit
                    return view
                }()
                self.imageView = view
                return view
            }
        }
        set {
            objc_setAssociatedObject(self, &Self.previewViewAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    func showPreview(image: UIImage) {
        if self.imageView.superview == nil {
            self.view.addSubview(imageView)
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        self.view.bringSubviewToFront(self.imageView)
    }

    func hidePreview() {
        self.imageView.removeFromSuperview()
    }
}
