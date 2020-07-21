//
//  DataManager.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/7/20.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

class DataManager {

    static let shared = DataManager()

    private var history: [String: [MockMessage]] = [:]
}
