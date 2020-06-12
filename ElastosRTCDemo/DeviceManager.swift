import Foundation
import AVFoundation
import MediaPlayer
import ElastosCarrierSDK

extension Notification.Name {
    static let didBecomeReady = Notification.Name("didBecomeReady")
    static let deviceStatusChanged = Notification.Name("completedLengthyDownload")
    static let friendStatusChanged = Notification.Name("friendStatusChanged")
    static let friendInfoChanged = Notification.Name("friendInfoChanged")
    static let friendAdded = Notification.Name("friendAdded")
    static let acceptFriend = Notification.Name("acceptFriend")
    static let friendList = Notification.Name("friendList")

}
var transferFrientId = ""
class DeviceManager : NSObject {
    fileprivate static let checkURL = "https://apache.org"

    // MARK: - Singleton
    @objc(sharedInstance)
    static let sharedInstance = DeviceManager()
    var status = CarrierConnectionStatus.Disconnected
    @objc(carrierInst)
    var carrierInst: ElastosCarrierSDK.Carrier!

    var carrierGroup: CarrierGroup?

    override init() {
    }

    func start() {
        if carrierInst == nil {
            do {

                let carrierDirectory: String = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)[0] + "/carrier"
                if !FileManager.default.fileExists(atPath: carrierDirectory) {
                    var url = URL(fileURLWithPath: carrierDirectory)
                    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)

                    var resourceValues = URLResourceValues()
                    resourceValues.isExcludedFromBackup = true
                    try url.setResourceValues(resourceValues)
                }

                let options = CarrierOptions()
                options.bootstrapNodes = [BootstrapNode]()
                options.expressNodes = [ExpressNode]()
                let bootstrapNodes = [["ipv4": "13.58.208.50", "port": "33445", "publicKey": "89vny8MrKdDKs7Uta9RdVmspPjnRMdwMmaiEW27pZ7gh"],
                                      ["ipv4": "18.216.102.47", "port": "33445", "publicKey": "G5z8MqiNDFTadFUPfMdYsYtkUDbX5mNCMVHMZtsCnFeb"],
                                      ["ipv4": "18.216.6.197", "port": "33445", "publicKey": "H8sqhRrQuJZ6iLtP2wanxt4LzdNrN2NNFnpPdq1uJ9n2"],
                                      ["ipv4": "54.223.36.193", "port": "33445", "publicKey": "5tuHgK1Q4CYf4K5PutsEPK5E3Z7cbtEBdx7LwmdzqXHL"],
                                      ["ipv4": "52.83.191.228", "port": "33445", "publicKey": "3khtxZo89SBScAMaHhTvD68pPHiKxgZT6hTCSZZVgNEm"]]

                let expressNodes = [["ipv4": "ece00.trinity-tech.io", "port": "443", "publicKey": "FyTt6cgnoN1eAMfmTRJCaX2UoN6ojAgCimQEbv1bruy9"],
                                      ["ipv4": "ece01.trinity-tech.io", "port": "443", "publicKey": "FyTt6cgnoN1eAMfmTRJCaX2UoN6ojAgCimQEbv1bruy9"],
                                      ["ipv4": "ece01.trinity-tech.cn", "port": "443", "publicKey": "FyTt6cgnoN1eAMfmTRJCaX2UoN6ojAgCimQEbv1bruy9"]]

                bootstrapNodes.enumerated().forEach { (index, obj) in
                    let bootstrapNode = BootstrapNode()
                    bootstrapNode.ipv4 = obj["ipv4"]
                    bootstrapNode.port = obj["port"]
                    bootstrapNode.publicKey = obj["publicKey"]
                    options.bootstrapNodes?.append(bootstrapNode)
                }

                expressNodes.enumerated().forEach { (index, obj) in
                    let expressNode = ExpressNode()
                    expressNode.ipv4 = obj["ipv4"]
                    expressNode.port = obj["port"]
                    expressNode.publicKey = obj["publicKey"]
                    options.expressNodes?.append(expressNode)
                }

                options.udpEnabled = true
                options.persistentLocation = carrierDirectory
                carrierInst = try Carrier.createInstance(options: options, delegate: self)
                print("carrier instance created")

                try! carrierInst.start(iterateInterval: 1000)
                print("carrier started, waiting for ready")
            }
            catch {
                NSLog("Start carrier instance error : \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - CarrierDelegate
extension DeviceManager : CarrierDelegate
{
    func connectionStatusDidChange(_ carrier: Carrier,
                                   _ newStatus: CarrierConnectionStatus) {
        self.status = newStatus
        if status == .Disconnected {
        }
        NotificationCenter.default.post(name: .deviceStatusChanged, object: nil)
    }
    
    public func didBecomeReady(_ carrier: Carrier) {
        let myInfo = try! carrier.getSelfUserInfo()
        if myInfo.name?.isEmpty ?? true {
            myInfo.name = UIDevice.current.name
            try? carrier.setSelfUserInfo(myInfo)
        }
        _ = try? CarrierSessionManager.createInstance(carrier: carrier, sessionRequestHandler: { (carrier, frome, adp) in
        })
        NotificationCenter.default.post(name: .didBecomeReady, object: nil)
    }

    public func selfUserInfoDidChange(_ carrier: Carrier,
                                      _ newInfo: CarrierUserInfo) {
		print("\(#function), newInfo: \(newInfo)")
    }
    
    public func didReceiveFriendsList(_ carrier: Carrier,
                                      _ friends: [CarrierFriendInfo]) {
        print("\(#function), friends: \(friends)")
        NotificationCenter.default.post(name: .friendList, object: self, userInfo: ["friends": friends])
    }
    
    public func friendInfoDidChange(_ carrier: Carrier,
                                    _ friendId: String,
                                    _ newInfo: CarrierFriendInfo) {
        print("friendInfoDidChange : \(newInfo)")
        NotificationCenter.default.post(name: .friendInfoChanged, object: self, userInfo: ["friendInfo":newInfo])
    }
    
    public func friendConnectionDidChange(_ carrier: Carrier,
                                          _ friendId: String,
                                          _ newStatus: CarrierConnectionStatus) {
        NotificationCenter.default.post(name: .friendStatusChanged,
                                        object: self,
                                        userInfo: ["friendState": newStatus, "userId": friendId])
    }
    
    public func didReceiveFriendRequest(_ carrier: Carrier,
                                        _ userId: String,
                                        _ userInfo: CarrierUserInfo,
                                        _ hello: String) {
        print("didReceiveFriendRequest, userId : \(userId), name : \(String(describing: userInfo.name)), hello : \(hello)")
        do {
            try carrier.acceptFriend(with: userId)
        } catch {
            NSLog("Accept friend \(userId) error : \(error.localizedDescription)")
        }
        NotificationCenter.default.post(name: .acceptFriend, object: self, userInfo: ["friendInfo":userInfo])
    }
    
    public func didReceiveFriendResponse(_ carrier: Carrier,
                                         _ userId: String,
                                         _ status: Int,
                                         _ reason: String?,
                                         _ entrusted: Bool,
                                         _ expire: String?) {
        print("didReceiveFriendResponse, userId : \(userId)")
    }
    
    public func newFriendAdded(_ carrier: Carrier,
                               _ newFriend: CarrierFriendInfo) {
        print("newFriendAdded : \(newFriend)")
        NotificationCenter.default.post(name: .friendAdded, object: self, userInfo: ["friendInfo":newFriend])
    }
    
    public func friendRemoved(_ carrier: Carrier,
                              _ friendId: String) {
        print("friendRemoved, userId : \(friendId)")

    }

    func didReceiveFriendMessage(_ carrier: Carrier, _ from: String, _ data: Data, _ isOffline: Bool) {
        print("didReceiveFriendMessage : \(data)")
    }
    
    public func didReceiveFriendInviteRequest(_ carrier: Carrier,
                                              _ from: String,
                                              _ data: String) {
        print("didReceiveFriendInviteRequest")
    }

}


