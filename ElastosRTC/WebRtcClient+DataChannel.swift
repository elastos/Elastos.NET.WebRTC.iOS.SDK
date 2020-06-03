//
//  WebRtcClient+DataChannel.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

extension WebRtcClient: RTCDataChannelDelegate {
    
    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("\(#function)")
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        print("\(#function)")
    }
}
