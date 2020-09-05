//
//  Utils.swift
//  ElastosRTC
//
//  Created by idanzhu on 2020/8/15.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import MobileCoreServices

@_exported import WebRTC
@_exported import ElastosCarrierSDK

let TAG = "CarrierWebRtcSDK"
let HIGH_WATER_MARK: UInt64 = 1048576//32 * 1024 * 8
let MAX_CHUNK_SIZE = 32 * 1024
let MAX_CHUNK_COUNT = 10

func mimeType(pathExtension: String) -> String {
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
        let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
    }
    return "application/octet-stream"
}

extension UIView {

    func autoPinEdgesToSuperviewEdges() {
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: superview!.leadingAnchor),
            trailingAnchor.constraint(equalTo: superview!.trailingAnchor),
            topAnchor.constraint(equalTo: superview!.topAnchor),
            bottomAnchor.constraint(equalTo: superview!.bottomAnchor),
        ])
    }
}

public class Platform: NSObject {

    public static let isSimulator: Bool = {
        let isSim: Bool
        #if arch(i386) || arch(x86_64)
            isSim = true
        #else
            isSim = false
        #endif
        return isSim
    }()
}
