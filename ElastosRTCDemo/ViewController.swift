//
//  ViewController.swift
//  ElastosRTCDemo
//
//  Created by ZeLiang on 2020/6/2.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import ElastosCarrierSDK

class ViewController: UIViewController, CarrierDelegate {
    
    public var carrierInstance: Carrier?
    
    var carrierDirectory: String {
        let path = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] + "/carrier"
        if !FileManager.default.fileExists(atPath: path) {
            var url = URL(fileURLWithPath: path)
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
                
                var resourceValues = URLResourceValues()
                resourceValues.isExcludedFromBackup = true
                try url.setResourceValues(resourceValues)
            } catch {
                assertionFailure("create carrier directory failure, due to \(error)")
            }
        }
        return path
    }
    
    private func createCarrierInstanceIfNeeded() -> Carrier? {
        if let instance = self.carrierInstance { return instance }
        
        let options: CarrierOptions = {
            let options = CarrierOptions()
            options.bootstrapNodes = [BootstrapNode]()
            options.hivebootstrapNodes = [HiveBootstrapNode]()
            let bootstrapNodes = [["ipv4": "13.58.208.50", "port": "33445", "publicKey": "89vny8MrKdDKs7Uta9RdVmspPjnRMdwMmaiEW27pZ7gh"],
                                  ["ipv4": "18.216.102.47", "port": "33445", "publicKey": "G5z8MqiNDFTadFUPfMdYsYtkUDbX5mNCMVHMZtsCnFeb"],
                                  ["ipv4": "18.216.6.197", "port": "33445", "publicKey": "H8sqhRrQuJZ6iLtP2wanxt4LzdNrN2NNFnpPdq1uJ9n2"],
                                  ["ipv4": "54.223.36.193", "port": "33445", "publicKey": "5tuHgK1Q4CYf4K5PutsEPK5E3Z7cbtEBdx7LwmdzqXHL"],
                                  ["ipv4": "52.83.191.228", "port": "33445", "publicKey": "3khtxZo89SBScAMaHhTvD68pPHiKxgZT6hTCSZZVgNEm"]]
            
            let hivestrapNodes = [["ipv4": "52.83.159.189", "port": "9095"],
                                  ["ipv4": "52.83.119.110", "port": "9095"],
                                  ["ipv4": "3.16.202.140", "port": "9095"],
                                  ["ipv4": "18.219.53.133", "port": "9095"],
                                  ["ipv4": "18.217.147.205", "port": "9095"]]
            
            bootstrapNodes.forEach {
                let node = BootstrapNode()
                node.ipv4 = $0["ipv4"]
                node.ipv6 = $0["ipv6"]
                node.publicKey = $0["publicKey"]
                options.bootstrapNodes?.append(node)
            }
            
            hivestrapNodes.forEach {
                let node = HiveBootstrapNode()
                node.ipv4 = $0["ipv4"]
                node.port = $0["port"]
                options.hivebootstrapNodes?.append(node)
            }
            
            options.udpEnabled = true
            options.persistentLocation = carrierDirectory
            return options
        }()
        
        return try? Carrier.createInstance(options: options, delegate: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
}
