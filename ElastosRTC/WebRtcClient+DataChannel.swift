//
//  WebRtcClient+DataChannel.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/7/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import MobileCoreServices

let bufferAmountSize: UInt64 = 10 * 1024 * 10
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
        if self.buffers.isEmpty == false && dataChannel.bufferedAmount < bufferAmountSize {
            self.condition.signal()
        }
    }
}

extension WebRtcClient {

    @objc func startToSendData() {
        while self.options.isEnableDataChannel {
            print("READY TO SEND DATA")
            self.condition.lock()
            let channel = self.dataChannel!
            if self.buffers.isEmpty == true || channel.bufferedAmount > bufferAmountSize {
                print("[CONSUMER-WAIT]🕒: buffer amount = \(channel.bufferedAmount), buffers count = \(self.buffers.count)")
                self.condition.wait()
            }
            let buffer = self.buffers.removeFirst()
            channel.sendData(buffer) ? print("[CONSUMER]✅: \(buffer)") : print("[CONSUMER]❌: \(buffer)")
            self.condition.unlock()
        }
    }

    public func sendText(_ text: String) throws {
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        guard let data = text.data(using: .utf8) else { fatalError("utf8 failure") }
        DispatchQueue.global().async {
            self.condition.lock()
            print("[PRODUCER]: Append a new item: | \(text)")
            self.buffers.append(RTCDataBuffer(data: data, isBinary: false))
            self.condition.signal()
            self.condition.unlock()
        }
    }

    public func sendFile(_ path: String) throws {
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        guard FileManager.default.fileExists(atPath: path) else { fatalError("file path must be valid") }

        DispatchQueue.global().async {
            let stream = InputStream(fileAtPath: path)!
            try? self.readData(stream, fileExtension: (path as NSString).pathExtension)
        }
    }

    public func sendImage(_ image: UIImage) throws {
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        guard let data = image.pngData() else { fatalError("image must not be null") }
        DispatchQueue.global().async {
            let stream = InputStream(data: data)
            try? self.readData(stream, fileExtension: "png")
        }
    }

    func readData(_ stream: InputStream, fileExtension: String) throws {
        stream.open()
        let bufferSize = 1024 * 16 //16k
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            stream.close()
            buffer.deallocate()
        }
        var index: Int = 0
        let fileID = UUID().uuidString
        while stream.hasBytesAvailable {
            condition.lock()
            if buffers.count > 10 {
                print("[PRODUCER-WAIT]🕒: buffers count > 10")
                condition.wait()
            }
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                throw stream.streamError!
            } else if read == 0 {
                //EOF
                assertionFailure()
                break
            }
            let dict: [String: Any] = ["data": Data(bytes: buffer, count: read).base64EncodedString(),
                                       "fileId": fileID,
                                       "index": index,
                                       "mime": mimeType(pathExtension: fileExtension),
                                       "end": !stream.hasBytesAvailable]
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            print("[PRODUCER]: Append a new item | \(mimeType(pathExtension: fileExtension))")
            self.buffers.append(RTCDataBuffer(data: data, isBinary: true))
            index += 1
            condition.signal()
            condition.unlock()
        }
    }

    func mimeType(pathExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
            let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
                return mimetype as String
        }
        return "application/octet-stream"
    }
}
