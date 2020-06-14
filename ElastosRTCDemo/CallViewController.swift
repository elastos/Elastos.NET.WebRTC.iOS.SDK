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

class CallViewController: UIViewController {

    //todo: for a test
    var friendId: String = ""

    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!
    
    var carrier: Carrier {
        DeviceManager.sharedInstance.carrierInst
    }

    lazy var client: WebRtcClient = {
        let instance = WebRtcClient(carrier: carrier,
                                    delegate: self,
                                    localView: localVideoView,
                                    remoteView: remoteVideoView)
        return instance
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        client.inviteCall(friendId: friendId)
    }

    @IBAction func onBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension CallViewController: WebRtcDelegate {

    func onInvite(friendId: String) {
        
    }

    func onAnswer() {
        
    }

    func onActive() {
        
    }

    func onEndCall(reason: CallReason) {
        
    }

    func onIceConnected() {
        
    }
    
    func onIceDisconnected() {
        
    }
    
    func onConnectionError(error: Error) {
        
    }
    
    func onConnectionClosed() {
        
    }
}
