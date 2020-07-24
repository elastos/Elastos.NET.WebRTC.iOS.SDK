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
    private var me: String = ""

    func write(message: String, from: String, to: String, id: String = UUID().uuidString, date: Date = Date()) {
        if from == me {

        }
        history[from + to]?.append(MockMessage(text: message, user: MockUser(senderId: from, displayName: from), messageId: id, date: date))
    }

    func read(message: String, other: String) {

    }
}
