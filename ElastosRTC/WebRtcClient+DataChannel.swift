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
        print("✅, data channel did change state")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            print("send data channel for test")
            self.dataChannel?.sendData(RTCDataBuffer(data: "hello".data(using: .utf8)!.base64EncodedData(), isBinary: true))
        }
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        print("✅, data channel did didReceiveMessageWith")

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            print("send data channel for test")
            self.dataChannel?.sendData(RTCDataBuffer(data: "hello_2".data(using: .utf8)!.base64EncodedData(), isBinary: true))
        }
    }
}
