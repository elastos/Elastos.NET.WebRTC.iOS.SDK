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

import XCTest

extension XCTestCase {

    func loadData<T: Decodable>(from filename: String, decode typeOf: T.Type) -> T? {
        guard let filePath = Bundle(for: type(of: self)).path(forResource: filename, ofType: "json") else {
            XCTFail("Could not find file with name \(filename)")
            return nil
        }

        guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else {
            XCTFail("Could not create data from file with name \(filename)")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let model = try decoder.decode(T.self, from: data)

            return model
        } catch {
            print("Decode error: \(error)")
            return nil
        }
    }

    func jsonObject(from fileName: String) -> Any {
        guard let fileURL = Bundle.url(forResource: fileName, withExtension: "json", subdirectory: nil, in: Bundle(for: WebRtcSignalTests.self).bundleURL) else {
            fatalError("\(fileName) not found")
        }
        let data = try! Data(contentsOf: fileURL, options: [])
        return try! JSONSerialization.jsonObject(with: data, options: [.allowFragments])
    }
}
