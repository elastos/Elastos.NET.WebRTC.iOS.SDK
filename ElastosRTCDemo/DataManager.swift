//
//  DataManager.swift
//  ElastosRTCDemo
//
//  Created by idanzhu on 2020/6/14.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import ElastosCarrierSDK
import ElastosRTC

class DataManager {
    
    var carrier: Carrier {
        DeviceManager.sharedInstance.carrierInst
    }
    
    lazy var rtcClient: WebRtcClient = {
        let client = WebRtcClient(carrier: self.carrier, delegate: self)
        return client
    }()
    
    static let shared = DataManager()
    
    func start() {
        print(self.rtcClient)
    }
}

extension DataManager: WebRtcDelegate {
    
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
