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
        let superView = (self.navigationController?.view ?? self.view)!
        if self.preview.superview == nil {
            superView.addSubview(preview)
            NSLayoutConstraint.activate([
                preview.leadingAnchor.constraint(equalTo: superView.leadingAnchor),
                preview.trailingAnchor.constraint(equalTo: superView.trailingAnchor),
                preview.topAnchor.constraint(equalTo: superView.topAnchor),
                preview.bottomAnchor.constraint(equalTo: superView.bottomAnchor),
            ])
        }
        self.preview.image = image
        superView.bringSubviewToFront(preview)
    }

    func hidePreview() {
        self.preview.removeFromSuperview()
    }
}
