//
//  RemoteVideoView.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/8/27.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit
import MetalKit

public class RemoteVideoView: UIView {

    #if arch(arm64)
    public var metalRenderer: RTCMTLVideoView?
    #endif

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupMetalRender()
        #if targetEnvironment(simulator)
        // Metal is not supported on the simulator, so we just set a background color for debugging purposes.
        self.backgroundColor = .blue
        #endif
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupMetalRender() {
        #if arch(arm64)
        let view = RTCMTLVideoView(frame: .zero)
        self.metalRenderer = view
        addSubview(view)
        view.autoPinEdgesToSuperviewEdges()

        for subview in view.subviews {
            if let view = subview as? MTKView {
                view.autoPinEdgesToSuperviewEdges()
            }
        }

        if UIDevice.current.userInterfaceIdiom != .pad {
            view.videoContentMode = .scaleAspectFill
            view.rotationOverride = NSNumber(value: RTCVideoRotation._90.rawValue)
        }
        #endif
    }
}

extension RemoteVideoView: RTCVideoRenderer {

    public func setSize(_ size: CGSize) {
        #if arch(arm64)
        self.metalRenderer?.setSize(size)
        #endif
    }

    public func renderFrame(_ frame: RTCVideoFrame?) {
        #if arch(arm64)
        self.metalRenderer?.renderFrame(frame)

        RTCDispatcher.dispatchAsync(on: .typeMain) {
            if UIDevice.current.userInterfaceIdiom == .pad {
                let currentWindowSize = UIScreen.main.bounds.size
                let isLandScape = currentWindowSize.width > currentWindowSize.height
                let remoteIsLandScape = frame?.rotation == ._180 || frame?.rotation == ._0

                // if we're both in the same orientation, let video fill the screen, otherwise, fit the video to the screen size respecting the aspect ration
                if isLandScape == remoteIsLandScape {
                    self.metalRenderer?.videoContentMode = .scaleAspectFill
                } else {
                    self.metalRenderer?.videoContentMode = .scaleAspectFit
                }
            } else {
                switch frame?.rotation {
                case ._270:
                    // portrait upside down render in portrait
                    self.metalRenderer?.rotationOverride = NSNumber(value: RTCVideoRotation._270.rawValue)
                case ._90:
                    //portrait renders in portrait
                    self.metalRenderer?.rotationOverride = NSNumber(value: RTCVideoRotation._90.rawValue)
                case ._180:
                    // if the device is in landscape left, flip upside down
                    switch UIDevice.current.orientation {
                    case .landscapeLeft:
                        self.metalRenderer?.rotationOverride = NSNumber(value: RTCVideoRotation._270.rawValue)
                    case .landscapeRight:
                        self.metalRenderer?.rotationOverride = NSNumber(value: RTCVideoRotation._90.rawValue)
                    default:
                        break
                    }
                case ._0:
                    // if the device is in landscape right, flip upside down
                    switch UIDevice.current.orientation {
                    case .landscapeRight:
                        self.metalRenderer?.rotationOverride = NSNumber(value: RTCVideoRotation._270.rawValue)
                    case .landscapeLeft:
                        self.metalRenderer?.rotationOverride = NSNumber(value: RTCVideoRotation._90.rawValue)
                    default:
                        break
                    }
                case .none:
                    break
                @unknown default:
                    break
                }
            }
        }
        #endif
    }
}
