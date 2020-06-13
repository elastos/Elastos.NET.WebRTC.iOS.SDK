//
//  Carrier+Util.swift
//  ElastosRTCDemo
//
//  Created by idanzhu on 2020/6/13.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import ElastosCarrierSDK

extension CarrierConnectionStatus {

    var status: Status {
        switch self {
        case .Connected:
            return .online
        case .Disconnected:
            return .offline
        }
    }
}

extension CarrierFriendInfo {

    func convert() -> FriendCellModel {
        FriendCellModel(id: self.userId ?? "no user id",
                        name: self.label ?? self.name ?? "no name",
                        avatar: nil,
                        status: self.status.status)
    }
}
