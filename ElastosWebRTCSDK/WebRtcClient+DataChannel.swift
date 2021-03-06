/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

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
        if self.buffers.isEmpty == false && dataChannel.bufferedAmount < HIGH_WATER_MARK {
            self.condition.broadcast()
        }
    }
}

extension WebRtcClient {

    var hasAvailableBuffersToSend: Bool {
        guard let channel = self.dataChannel else { return false }
        return !buffers.isEmpty && channel.bufferedAmount < HIGH_WATER_MARK
    }

    @objc func startToSendData() {
        while self.options.isEnableDataChannel {
            self.condition.lock()
            let channel = self.dataChannel!

            if !hasAvailableBuffersToSend {
                self.condition.wait()
            }

            while hasAvailableBuffersToSend {
                let buffer = self.buffers.removeFirst()
                channel.sendData(buffer)
            }

            condition.signal()
            condition.unlock()
        }
    }

    public func sendText(_ text: String) throws {
        guard let channel = dataChannel else { throw WebRtcError.dataChannelInitFailed }
        guard channel.readyState == .open else { throw WebRtcError.dataChannelStateIsNotOpen }
        guard let data = text.data(using: .utf8) else { fatalError("utf8 failure") }
        DispatchQueue.global().async {
            self.condition.lock()
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
        let bufferSize = MAX_CHUNK_SIZE
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            stream.close()
            buffer.deallocate()
        }
        var index: Int = 0
        let fileID = UUID().uuidString
        while stream.hasBytesAvailable {
            condition.lock()
            if buffers.count > MAX_CHUNK_COUNT {
                condition.wait()
            }
            let read = stream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                throw stream.streamError!
            } else if read == 0 {
                break //EOF
            }
            let dict: [String: Any] = ["data": Data(bytes: buffer, count: read).base64EncodedString(),
                                       "fileId": fileID,
                                       "index": index,
                                       "mime": mimeType(pathExtension: fileExtension),
                                       "end": !stream.hasBytesAvailable]
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            buffers.append(RTCDataBuffer(data: data, isBinary: true))
            index += 1
            condition.signal()
            condition.unlock()
        }
    }
}
