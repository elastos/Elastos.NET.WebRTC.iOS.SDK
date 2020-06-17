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

    func send(candidate: RTCIceCandidate) {
        do {
            let data = try JSONEncoder().encode(candidate.to())
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            Logger.log(level: .error, message: "convert candidate to json failure, due to \(error)")
        }
    }

    func send(removal candidates: [RTCIceCandidate]) {
        do {
            let signal = RtcSignal(type: .removeCandiate, candidates: candidates.map({ $0.to() }))
            let data = try JSONEncoder().encode(signal)
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            Logger.log(level: .error, message: "convert removeal candidate to json failure, due to \(error)")
        }
    }

    func send(desc: RTCSessionDescription) {
        do {
            let data = try JSONEncoder().encode(desc.to())
            guard let message = String(data: data, encoding: .utf8) else { return }
            send(json: message)
        } catch {
            Logger.log(level: .error, message: "convert sdp to json failure, due to \(error)")
        }
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
                    receive(sdp: sdp) { [weak self] desc in
                        guard let self = self else { return }
                        self.send(desc: desc)
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
