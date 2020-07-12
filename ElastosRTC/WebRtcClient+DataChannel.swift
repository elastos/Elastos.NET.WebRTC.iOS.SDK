//
//  WebRtcClient+DataChannel.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/7/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

extension WebRtcClient: RTCDataChannelDelegate {

    public func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        Log.d(TAG, "data-channel did change state %@", dataChannel.readyState.state as CVarArg)
    }

    public func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        Log.d(TAG, "data-channel did receive message %@, from %d", buffer.data as CVarArg, dataChannel.channelId)
        self.delegate?.onReceiveMessage(buffer.data, isBinary: buffer.isBinary, channelId: Int(dataChannel.channelId))
    }
    
    public func dataChannel(_ dataChannel: RTCDataChannel, didChangeBufferedAmount amount: UInt64) {
        Log.d(TAG, "data-channel didChangeBufferedAmount, %ld", amount)
    }
}
