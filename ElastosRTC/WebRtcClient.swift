//
//  WebRtcClient.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import UIKit
import ElastosCarrierSDK

public enum CallReason {
    case reject
    case missing
}

public protocol WebRtcDelegate {
    
    /// fired when receive invite from yur friends
    /// - Parameter friendId: who is calling you
    func onInvite(friendId: String)
    
    func onAnswer();
    
    func onActive()
    
    func onEndCall(reason: CallReason)
    
    func onIceConnected()
    
    func onIceDisconnected()
    
    func onConnectionError(error: Error)
    
    func onConnectionClosed()
}

public class WebRtcClient: NSObject {
    
    public let carrier: Carrier
    
    public let delegate: WebRtcDelegate
        
    public init(carrier: Carrier, delegate: WebRtcDelegate) {
        self.carrier = carrier
        self.delegate = delegate
    }
    
    public func inviteCall(friendId: String) {
        
    }
    
    public func endCall(friendId: String) {
        
    }
}
