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

extension WebRtcClient {

    func send(signal: RtcSignal) {
        do {
            let data = try JSONEncoder().encode(signal)
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            assertionFailure("convert signal to json failure, due to \(error)")
        }
    }

    func send(candidate: RTCIceCandidate) {
        let signal = RtcSignal(type: .candidate, candidates: [candidate.to()])
        messageQueue.append(signal)
        drainMessageQueueIfReady()
    }

    func send(removal candidates: [RTCIceCandidate]) {
        let signal = RtcSignal(type: .removeCandiate, candidates: candidates.map({ $0.to() }))
        messageQueue.append(signal)
        drainMessageQueueIfReady()
    }

    func send(desc: RTCSessionDescription, options: MediaOptions? = nil) {
        let signal = desc.to(options: options)
        send(signal: signal)
    }

    func send(json: String) {
        guard let friendId = self.friendId else { return assertionFailure("friendId is null") }
        do {
            Log.d(TAG, "[SEND]: %@, \n data: %@", friendId, json)
            try carrier.sendInviteFriendRequest(to: friendId, withData: json, { (carrier, arg1, arg2, arg3, arg4) in
                Log.d(TAG, "[RECV]: %@, arg1: %d, arg2: %@, arg3: %@, arg4: %@", friendId, arg1, arg2, arg3 ?? "", arg4 ?? "")
            })
        } catch {
            assertionFailure(error.localizedDescription)
            Log.e(TAG, "send data failure, due to \(error)")
        }
    }

    func receive(from: String, data: String) {
        do {
            let message = try JSONDecoder().decode(RtcSignal.self, from: data.data(using: .utf8)!)
            switch message.type {
            case .offer:
                guard let sdp = message.offer else { return }
                friendId = from
                callDirection = .incoming
                options = message.options ?? [.audio, .video, .data]
                let closureAfterAccepted = { [weak self] in
                    self?.receive(sdp: sdp) { [weak self] sdp in
                        self?.send(desc: sdp)
                    }
                }

                if let delegate = self.delegate {
                    delegate.onInvite(friendId: from, mediaOption: options) { [weak self] isAllow in
                        if isAllow {
                            closureAfterAccepted()
                        } else {
                            self?.endCall(type: .declined)
                        }
                    }
                } else {
                    Log.d(TAG, "Auto answer for user")
                    closureAfterAccepted()
                }
            case .answer:
                guard let sdp = message.answer, from == self.friendId else { return Log.d(TAG, "ignore answer") }
                receive(sdp: sdp)
            case .candidate:
                guard let candidate = message.candidate, from == self.friendId else { return Log.d(TAG, "candidate") }
                receive(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            case .prAnswer:
                fatalError("not support prAnswer now")
            case .removeCandiate:
                guard let candiates = message.removeCandidates, from == self.friendId else { return Log.d(TAG, "ignore removal-candidates") }
                receive(removal: candiates)
            case .bye:
                self.delegate?.onWebRtc(self, didChangeState: .remoteHangup)
                self.cleanup()
            }
        } catch {
            Log.e(TAG, "signal message decode error, due to ", error as CVarArg)
        }
        drainMessageQueueIfReady()
    }

    func registerCarrierCallback() {
        do {
            try self.carrier.registerExtension { [weak self] (carrier, friendId, message) in
                Log.d(TAG, "[RECV]: %@, data: %@", friendId, message ?? "empty content")
                guard let data = message, let self = self else { return }
                self.receive(from: friendId, data: data)
                try? self.carrier.replyFriendInviteRequest(to: friendId, withStatus: 0, nil, "data")
            }
        } catch {
            fatalError("register extension error, due to \(error)")
        }
    }

    func drainMessageQueueIfReady() {
        if hasReceivedSdp {
            messageQueue.forEach { self.send(signal: $0) }
            messageQueue.removeAll()
        }
    }
}
