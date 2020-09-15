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

extension RTCIceCandidate {

    func to() -> RtcCandidateSignal {
        RtcCandidateSignal(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid)
    }
}

extension RTCSessionDescription {

    func to(options: MediaOptions? = nil) -> RtcSignal {
        RtcSignal(type: type.to!, sdp: sdp, options: options)
    }
}

extension RTCSdpType {

    var to: SdpType? {
        switch self {
        case .answer:
            return .answer
        case .offer:
            return .offer
        case .prAnswer:
            return .prAnswer
        default:
            return nil
        }
    }
}

extension RTCDataChannelState {

    var state: String {
        switch self {
        case .closed:
            return "closed"
        case .closing:
            return "closing"
        case .connecting:
            return "connecting"
        case .open:
            return "open"
        @unknown default:
            return "unknown"
        }
    }
}

extension RTCIceConnectionState {

    var state: String {
        switch self {
        case .checking:
            return "checking"
        case .closed:
            return "closed"
        case .completed:
            return "completed"
        case .connected:
            return "connected"
        case .count:
            return "count"
        case .disconnected:
            return "disconnected"
        case .failed:
            return "failed"
        case .new:
            return "new"
        @unknown default:
            return "unknown"
        }
    }
}

extension TurnServerInfo {

    var iceServer: RTCIceServer {
        RTCIceServer(urlStrings: ["turn:\(server):\(port)"], username: username, credential: password)
    }
}
