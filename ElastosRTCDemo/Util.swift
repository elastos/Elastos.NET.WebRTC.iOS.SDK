//
//  Util.swift
//  ElastosRTCDemo
//
//  Created by tomas.shao on 2020/8/6.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import MobileCoreServices
import UIKit

let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

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

extension UIImage {
    public enum DataUnits: String {
        case byte, kilobyte, megabyte, gigabyte

        var unit: String {
            switch self {
            case .byte:
                return "B"
            case .kilobyte:
                return "KB"
            case .megabyte:
                return "M"
            case .gigabyte:
                return "G"
            }
        }
    }

    func getSizeIn(_ type: DataUnits)-> String {
        guard let data = self.pngData() else {
            return ""
        }

        var size: Double = 0.0

        switch type {
        case .byte:
            size = Double(data.count)
        case .kilobyte:
            size = Double(data.count) / 1024
        case .megabyte:
            size = Double(data.count) / 1024 / 1024
        case .gigabyte:
            size = Double(data.count) / 1024 / 1024 / 1024
        }

        return String(format: "%.2f", size) + type.unit
    }
}
