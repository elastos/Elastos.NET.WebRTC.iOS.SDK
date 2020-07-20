//
//  WebRtcClient+Carrier.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

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
            delegate?.onConnectionError(error: error)
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
                self.callDirection = .incoming
                options = message.options ?? [.audio, .video]
                let closureAfterAccepted = { [weak self] in
                    self?.receive(sdp: sdp) { [weak self] sdp in
                        self?.send(desc: sdp)
                    }
                }

                if let delegate = self.delegate {
                    delegate.onInvite(friendId: from, mediaOption: options) { [weak self] result in
                        if result {
                            closureAfterAccepted()
                        } else {
                            self?.rejectCall()
                        }
                    }
                } else {
                    Log.d(TAG, "Auto answer for user")
                    closureAfterAccepted()
                }
            case .answer:
                guard let sdp = message.answer, from == self.friendId else { return }
                receive(sdp: sdp)
            case .candidate:
                guard let candidate = message.candidate, from == self.friendId else { return }
                receive(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            case .prAnswer:
                fatalError("not support prAnswer now")
            case .removeCandiate:
                guard let candiates = message.removeCandidates, from == self.friendId else { return }
                receive(removal: candiates)
            case .bye:
                self.delegate?.onEndCall(reason: message.reason ?? .unknown)
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
            }
        } catch {
            fatalError("register extension error, due to \(error)")
        }

        do {
            self.turnInfo = try self.carrier.turnServerInfo()
            print(self.turnInfo?.server, self.turnInfo?.password, self.turnInfo?.port)
        } catch {
            fatalError("get turn server info failued, due to \(error)")
        }
    }

    func drainMessageQueueIfReady() {
        if hasReceivedSdp {
            messageQueue.forEach { self.send(signal: $0) }
            messageQueue.removeAll()
        }
    }

    func rejectCall() {
        send(signal: RtcSignal(type: .bye, reason: .reject))
        delegate?.onEndCall(reason: .reject)
    }
}
