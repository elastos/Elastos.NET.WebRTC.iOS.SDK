//
//  AppDelegate.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/2.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import AVFoundation
import Bugly

@_exported import ElastosRTC
@_exported import ElastosCarrierSDK

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

	var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        Bugly.start(withAppId: "d3a42a3243")
        if #available(iOS 13.0, *) {
            window!.overrideUserInterfaceStyle = .light
        }
        return true
    }
}
