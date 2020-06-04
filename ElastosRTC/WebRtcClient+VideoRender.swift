//
//  WebRtcClient+VideoRender.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/6/4.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

extension WebRtcClient: RTCVideoViewDelegate {

    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        print("\(#function)")
    }
}
