//
//  DataManager.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/7/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

class DataManager {

    static let shared = DataManager()

    private var history: [String: [MockMessage]] = [:]
    var me: String = ""

    func write(message: String, from: String, to: String, id: String = UUID().uuidString, date: Date = Date()) {
        assert(me.isEmpty == true, "set me user id first")
        let key: String = (from == me) ? (from + to) : (to + from)
        if history[key] == nil {
            history[key] = []
        }
        history[key]?.append(MockMessage(text: message, user: MockUser(senderId: from, displayName: from), messageId: id, date: date))
    }

    func read(message: String, from: String, to: String) -> [MockMessage] {
        assert(me.isEmpty == true, "set me user id first")
        let key: String = (from == me) ? (from + to) : (to + from)
        return history[key] ?? []
    }
}
