//
//  MyProfileViewController.swift
//  ElastosRTCDemo
//
//  Created by idanzhu on 2020/7/19.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import EFQRCode
import QRCodeReader
import ElastosCarrierSDK

class MyProfileViewController: UIViewController {
    
    private let titleLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.text = "Please enter a carrier address id, if the user is not your friend, please ad as friend"
        view.lineBreakMode = .byWordWrapping
        view.numberOfLines = 0
        return view
    }()

    private let textField: UITextField = {
        let view = UITextField()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.placeholder = "carrier address id"
        return view
    }()

    private let line: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .lightGray
        return view
    }()

    private let addBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Add", for: .normal)
        view.backgroundColor = .red
        return view
    }()

    private let qrCodeView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    private let userLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textAlignment = .center
        view.numberOfLines = 0
        view.lineBreakMode = .byCharWrapping
        return view
    }()

    private lazy var copyBtn: UIButton = {
        let view = UIButton(type: .custom)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.setTitle("Copy Address", for: .normal)
        view.setTitleColor(.black, for: .normal)
        view.layer.borderColor = UIColor.black.cgColor
        view.layer.borderWidth = 1.0
        view.addTarget(self, action: #selector(copyCarrierUserAddress), for: .touchUpInside)
        return view
    }()

    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
            $0.showTorchButton        = false
            $0.showSwitchCameraButton = false
            $0.showCancelButton       = false
            $0.showOverlayView        = true
            $0.rectOfInterest         = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
        }
        
        return QRCodeReaderViewController(builder: builder)
    }()
    
    var carrier: Carrier!
    private var userAddressId: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "My Info"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Scan", style: .done, target: self, action: #selector(scanQRCode))
        view.backgroundColor = .white
        
        setupViews()
        setupConstriants()
    }
    
    func setupViews() {
        view.addSubview(textField)
        view.addSubview(addBtn)
        view.addSubview(qrCodeView)
        view.addSubview(userLabel)
        view.addSubview(line)
        view.addSubview(titleLabel)
        view.addSubview(copyBtn)
        
        addBtn.addTarget(self, action: #selector(addAsFriend), for: .touchUpInside)
    }
    
    func setupConstriants() {
        let views = ["input": textField, "add": addBtn, "qr": qrCodeView, "user": userLabel, "line": line, "title": titleLabel, "copy": copyBtn]
        var constraints: [NSLayoutConstraint] = []
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[input]-[add(44)]-20-|", options: .alignAllCenterY, metrics: nil, views: views)
        constraints.append(textField.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor))
        constraints.append(textField.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor))
        constraints.append(textField.leadingAnchor.constraint(equalTo: line.leadingAnchor))
        constraints.append(textField.trailingAnchor.constraint(equalTo: line.trailingAnchor))
        
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "H:|-20-[user]-20-|", options: [], metrics: nil, views: views)
        constraints += NSLayoutConstraint.constraints(withVisualFormat: "V:[title]-[input(40)][line(1)]-40-[qr(200)]-10-[user]-[copy(44)]-(>=0)-|", options: [], metrics: nil, views: views)
        constraints.append(qrCodeView.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(copyBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor))
        constraints.append(copyBtn.widthAnchor.constraint(equalToConstant: 150))
        constraints.append(qrCodeView.widthAnchor.constraint(equalToConstant: 200))
        constraints.append(addBtn.heightAnchor.constraint(equalToConstant: 44))
        constraints.append(titleLabel.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor, constant: 40))
        NSLayoutConstraint.activate(constraints)
    }
    
    @objc func scanQRCode() {
        readerVC.completionBlock = { [weak self] (result: QRCodeReaderResult?) in
            guard let self = self else { return }
            self.textField.text = result?.value
            self.dismiss(animated: true, completion: nil)
        }

        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        
        present(readerVC, animated: true, completion: nil)
    }
    
    @objc func addAsFriend() {
        guard let text = self.textField.text else { return }
        do {
            try self.carrier.addFriend(with: text, withGreeting: "hello, make friend with you")
            self.alert(title: "Add Friend Success")
        } catch {
            self.alert(title: "Add Friend Failure", message: error.localizedDescription)
        }
    }

    func update(address: String, userId: String, carrier: Carrier) {
        guard !address.isEmpty else { return }
        self.carrier = carrier
        userAddressId = address
        qrCodeView.image = UIImage(cgImage: EFQRCode.generate(content: address)!)
        userLabel.text = userId
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        self.view.endEditing(true)
    }

    @objc func copyCarrierUserAddress() {
        UIPasteboard.general.string = userAddressId
        copyBtn.setTitle("Copy Success", for: .normal)
    }
}

extension MyProfileViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        addAsFriend()
        return true
    }
}
