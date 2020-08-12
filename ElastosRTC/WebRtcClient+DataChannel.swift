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
        sendDataIfPossible()
    }
}

extension WebRtcClient {

    func sendDataIfPossible() {
        guard let channel = self.dataChannel else { return }
        queue.sync {
            while channel.bufferedAmount / 20 * 1024 < 5 {
                guard self.bufferItems.isEmpty == false else { break }
                let item = self.bufferItems.removeFirst()
                 print("[SEND]▶️: \(item)")
                channel.sendData(item)
            }
            print("[STOP]❌: buffer amount = \(channel.bufferedAmount)")
        }
    }

    @discardableResult
    public func sendData(_ data: Data, isBinary: Bool) throws -> Bool {
        let buffer = RTCDataBuffer(data: data, isBinary: isBinary)
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        if isBinary {
            queue.sync {
                self.bufferItems.append(buffer)
                self.sendDataIfPossible()
            }
        } else {
            return channel.sendData(buffer)
        }
        return true
    }
}
