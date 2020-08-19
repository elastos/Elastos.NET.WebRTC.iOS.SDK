//
//  UIView+Progress.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/8/19.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

class IndicatorProgressView: UIView {

    let titleLabel: UILabel = {
        let view = UILabel(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .vertical)
        return view
    }()

    let activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .medium)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.startAnimating()
        view.hidesWhenStopped = true
        return view
    }()

    let backgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView(arrangedSubviews: [activityIndicatorView, titleLabel])
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.spacing = 4
        view.distribution = .fillProportionally
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(backgroundView)
        addSubview(stackView)

        let constraints = [
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor),
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor)
        ]
        constraints.forEach { $0.priority = .required - 1 }
        NSLayoutConstraint.activate(constraints)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String) {
        titleLabel.text = title
    }
}

extension UIView {

    //Set the progress of the circular view in an animated manner. Only valid for values between `0` and `1`.
    func showProgress(_ progress: Float) {
        if indicatorView.superview == nil {
            addSubview(indicatorView)
            indicatorView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor),
                indicatorView.trailingAnchor.constraint(equalTo: trailingAnchor),
                indicatorView.topAnchor.constraint(equalTo: topAnchor),
                indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            ])
        }
        indicatorView.update(title: String(format: "%.0f%%", progress * 100))
    }

    func hideProgress() {
        UIView.animate(withDuration: 0.3, animations: { self.indicatorView.alpha = 0 }) { _ in self.indicatorView.removeFromSuperview() }
    }

    //associate the indicator view inn the view

    private static var indicator_associate_key: UInt8 = 0
    var indicatorView: IndicatorProgressView {
        get {
            if let view = objc_getAssociatedObject(self, &Self.indicator_associate_key) as? IndicatorProgressView {
                return view
            }
            let view = IndicatorProgressView()
            self.indicatorView = view
            return view
        }
        set {
            objc_setAssociatedObject(self, &Self.indicator_associate_key, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
