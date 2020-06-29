//
//  XCTestCase+Util.swift
//  ElastosRTCTests
//
//  Created by tomas.shao on 2020/6/28.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

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
