//
//  WebRtcClient+Carrier.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import ElastosCarrierSDK
import WebRTC

extension WebRtcClient {

    func send(signal: RtcSignal) {
        do {
            let data = try JSONEncoder().encode(signal)
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            Logger.log(level: .error, message: "convert signal to json failure, due to \(error)")
        }
    }

    func send(candidate: RTCIceCandidate) {
        let signal = RtcSignal(type: .candidate, sdp: nil, candidates: [candidate.to()])
        send(signal: signal)
    }

    func send(removal candidates: [RTCIceCandidate]) {
        let signal = RtcSignal(type: .removeCandiate, candidates: candidates.map({ $0.to() }))
        send(signal: signal)
    }

    func send(desc: RTCSessionDescription) {
        let signal = desc.to()
        send(signal: signal)
    }

    func send(json: String) {
        guard let friendId = self.friendId else { return assertionFailure("friendId is null") }
        do {
            Logger.log(level: .debug, message: "send data to friend \nname = \(friendId), content = \(json)")
            try carrier.sendInviteFriendRequest(to: friendId, withData: json, { (carrier, arg1, arg2, arg3, arg4) in
                Logger.log(level: .debug, message: "invite friend callback, \(arg1), \(arg2), \(String(describing: arg3)), \(String(describing: arg4))")
            })
        } catch {
            Logger.log(level: .error, message: "send data failure, due to \(error)")
        }
    }

    func receive(from: String, data: String) {
        do {
            let message = try JSONDecoder().decode(RtcSignal.self, from: data.data(using: .utf8)!)
            switch message.type {
            case .offer:
                guard let sdp = message.offer else { return }
                self.friendId = from
                if let delegate = self.delegate {
                    delegate.onInvite(friendId: from) { [weak self] result in
                        if result {
                            self?.receive(sdp: sdp) { [weak self] sdp in
                                self?.send(desc: sdp)
                            }
                        } else {
                            self?.send(signal: RtcSignal(type: .bye, reason: .reject))
                        }
                    }
                } else {
                    self.receive(sdp: sdp) { [weak self] sdp in
                        self?.send(desc: sdp)
                    }
                }
            case .answer:
                guard let sdp = message.answer, from == self.friendId else { return }
                receive(sdp: sdp)
            case .candidate:
                guard let candidate = message.candidate, from == self.friendId else { return }
                receive(candidate: RTCIceCandidate(sdp: candidate.sdp, sdpMLineIndex: candidate.sdpMLineIndex, sdpMid: candidate.sdpMid))
            case .prAnswer:
                Logger.log(level: .error, message: "not support prAnswer")
            case .removeCandiate:
                guard let candiates = message.removeCandidates, from == self.friendId else { return }
                receive(removal: candiates)
            case .bye:
                self.delegate?.onEndCall(reason: message.reason ?? .unknown)
                self.peerConnection.close()
            }
        } catch {
            Logger.log(level: .error, message: "signal message decode error, due to \(error)")
        }
    }

    func registerCarrierCallback() {
        do {
            try self.carrier.registerExtension { [weak self] (carrier, friendId, message) in
                print("register extension callback, \(friendId), \(message ?? "no value")")
                guard let data = message, let self = self else { return }
                self.receive(from: friendId, data: data)
            }
        } catch {
            print("register extension error, due to \(error)")
        }
    }
}
