//
//  WebRtcClient+DataChannel.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/7/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

//Support:
// image, text
extension WebRtcClient: RTCDataChannelDelegate {

    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("✅, data channel did change state, \(self.dataChannel)")

        switch dataChannel.readyState {
        case .open:
            print("✅: open")
            dataChannel.sendData(RTCDataBuffer(data: "data".data(using: .utf8)!, isBinary: false))
        case .closing:
            print("✅: closing")
        case .connecting:
            print("✅: connecting")
        case .closed:
            print("✅: closed")
        @unknown default:
            print("✅: default")
        }
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        self.delegate?.onReceiveMessage(buffer.data, isBinary: buffer.isBinary, channelId: Int(dataChannel.channelId))
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        print("✅, data channel did didChangeBufferedAmount: \(amount)")
    }
}
