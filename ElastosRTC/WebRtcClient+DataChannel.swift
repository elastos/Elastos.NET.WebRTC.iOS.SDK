//
//  WebRtcClient+DataChannel.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/7/3.
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
        print("[WARN]❗️: buffer amount did change: \(amount), sum: \(self.dataChannel!.bufferedAmount)")
        if self.buffers.isEmpty == false && dataChannel.bufferedAmount / 20 * 1024 < 5 {
            self.condition.broadcast()
        }
    }
}

extension WebRtcClient {

    @objc func startToSendData() {
        guard let channel = self.dataChannel else { return }
        while self.options.isEnableDataChannel {
            self.condition.lock()
            if self.buffers.isEmpty == true || channel.bufferedAmount / 20 * 1024 > 5 {
                if self.buffers.isEmpty == false {
                    print("[WAIT]❌: buffer amount = \(channel.bufferedAmount), buffers count = \(self.buffers.count)")
                }
                self.condition.wait()
            }
            let buffer = self.buffers.removeFirst()
            channel.sendData(buffer) ? print("[SEND]✅: \(buffer)") : print("[SEND]❌: \(buffer)")
            self.condition.unlock()
        }

    }

    public func sendData(_ data: Data, isBinary: Bool) throws {
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        queue.sync {
            self.condition.lock()
            self.buffers.append(RTCDataBuffer(data: data, isBinary: isBinary))
            self.condition.signal()
            self.condition.unlock()
        }
    }
}
