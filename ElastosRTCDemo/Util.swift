//
//  Util.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/8/6.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import MobileCoreServices

extension UIColor {
    static let primaryColor = UIColor(red: 69/255, green: 193/255, blue: 89/255, alpha: 1)
}

func readData(_ stream: InputStream, closure: (Data, Int, Bool) -> Void) throws {
    stream.open()

    let bufferSize = 1024 * 16 //16k
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer {
        stream.close()
        buffer.deallocate()
    }
    var index: Int = 0
    while stream.hasBytesAvailable {
        let read = stream.read(buffer, maxLength: bufferSize)
        if read < 0 {
            throw stream.streamError!
        } else if read == 0 {
            //EOF
            break
        }
        closure(Data(bytes: buffer, count: read), index, !stream.hasBytesAvailable)
        index += 1
    }
}

func mimeType(pathExtension: String) -> String {
    if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension as NSString, nil)?.takeRetainedValue(),
        let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() {
            return mimetype as String
    }
    return "application/octet-stream"
}

func jsonToData(jsonDic: [String: Any]) -> Data? {
    if !JSONSerialization.isValidJSONObject(jsonDic) {
        print("is not a valid json object")
        return nil
    }
    return try? JSONSerialization.data(withJSONObject: jsonDic, options: [])

}

func dataToDict(data: Data) -> [String: Any]? {
    do {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        return json as? [String: Any]
    } catch {
        return nil
    }
}
