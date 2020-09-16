/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

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
