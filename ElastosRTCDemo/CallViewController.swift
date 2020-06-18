//
//  CallViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/11.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import ElastosCarrierSDK
import ElastosRTC

protocol CallingDelegate: NSObject {
    
    func getClient() -> WebRtcClient
}

class CallViewController: UIViewController {

    var friendId: String = ""

    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!

    var client: WebRtcClient? {
        self.weakDataSource?.getClient()
    }

    weak var weakDataSource: CallingDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        client?.localVideoView = localVideoView
        client?.remoteVideoView = remoteVideoView
        client?.inviteCall(friendId: self.friendId, options: [.audio, .video])
    }

    @IBAction func onBack(_ sender: Any) {
        client?.endCall(friendId: self.friendId)
        self.dismiss(animated: true, completion: nil)
    }
}
