//
//  WebRtcClient+Carrier.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/3.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import ElastosCarrierSDK

extension WebRtcClient: CarrierDelegate {
    
    public func didReceiveGroupInvite(_ carrier: Carrier, _ from: String, _ cookie: Data) {
        
    }
}
