//
//  Logger.swift
//  ElastosRTC
//
//  Created by idanzhu on 2020/6/14.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation

public class Logger {

    public enum Level {
        case debug
        case error

        var flag: String {
            switch self {
            case .debug:
                return "[ℹ️] "
            case .error:
                return "[❌] "
            }
        }
    }

    public static func log(level: Level, message: String) {
        print("\(level.flag) + \(message)")
    }
}
