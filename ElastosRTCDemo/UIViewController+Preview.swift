//
//  UIViewController+Preview.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/8/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

import UIKit

class PreviewView: UIView {

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.4)

        addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            imageView.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            imageView.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            imageView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
        ])
    }

    var image: UIImage? = nil {
        didSet {
            imageView.image = image
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

extension UIViewController {

    private static var previewViewAssociatedKey: UInt8 = 0
    var preview: PreviewView {
                get {
            if let view = objc_getAssociatedObject(self, &Self.previewViewAssociatedKey) as? PreviewView {
                return view
            } else {
                let view: PreviewView = {
                    let view = PreviewView()
                    view.translatesAutoresizingMaskIntoConstraints = false
                    return view
                }()
                self.preview = view
                view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissView)))
                return view
            }
        }
        set {
            objc_setAssociatedObject(self, &Self.previewViewAssociatedKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc func dismissView() {
        hidePreview()
    }

    func showPreview(image: UIImage) {
        if self.preview.superview == nil {
            self.view.addSubview(preview)
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                preview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                preview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        }
        self.preview.image = image
        self.view.bringSubviewToFront(self.preview)
    }

    func hidePreview() {
        self.preview.removeFromSuperview()
    }
}
