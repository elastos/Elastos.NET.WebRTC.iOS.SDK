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

    var friendId: String = ""

    @IBOutlet weak var localVideoView: UIView!
    @IBOutlet weak var remoteVideoView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()

        DataManager.shared.rtcClient.localVideoView = localVideoView
        DataManager.shared.rtcClient.remoteVideoView = remoteVideoView
        DataManager.shared.rtcClient.inviteCall(friendId: self.friendId, options: [.audio, .video])
    }

    @IBAction func onBack(_ sender: Any) {
        DataManager.shared.rtcClient.endCall(friendId: self.friendId)
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
