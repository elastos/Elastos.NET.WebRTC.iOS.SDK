//
//  LocalVideoView.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/8/28.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import UIKit

public class LocalVideoView: UIView {
    private let localVideoCapturePreview = RTCCameraPreviewView()

    var captureSession: AVCaptureSession? {
        set { localVideoCapturePreview.captureSession = newValue }
        get { localVideoCapturePreview.captureSession }
    }

    public override var contentMode: UIView.ContentMode {
        didSet { localVideoCapturePreview.contentMode = contentMode }
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)

        addSubview(localVideoCapturePreview)

        localVideoCapturePreview.translatesAutoresizingMaskIntoConstraints = false
        localVideoCapturePreview.autoPinEdgesToSuperviewEdges()

        NotificationCenter.default.addObserver(self, selector: #selector(updateLocalVideoOrientation), name: UIDevice.orientationDidChangeNotification, object: nil
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var frame: CGRect {
        didSet {
            updateLocalVideoOrientation()
        }
    }

    @objc
    func updateLocalVideoOrientation() {
        defer { localVideoCapturePreview.frame = bounds }

        // iPad supports rotating this view controller directly, so we don't need to do anything here.
        guard UIDevice.current.userInterfaceIdiom != .pad else { return }

        // We lock this view to portrait only on phones, but the local video capture will rotate with the device's orientation (so the remote party will render your video in the correct orientation). As such, we need to rotate the local video preview layer so it *looks* like we're also always capturing in portrait.

        switch UIDevice.current.orientation {
        case .portrait:
            localVideoCapturePreview.transform = .identity
        case .portraitUpsideDown:
            localVideoCapturePreview.transform = .init(rotationAngle: .pi)
        case .landscapeLeft:
            localVideoCapturePreview.transform = .init(rotationAngle: .pi / 2)
        case .landscapeRight:
            localVideoCapturePreview.transform = .init(rotationAngle: .pi * 1.5)
        case .faceUp, .faceDown, .unknown:
            break
        @unknown default:
            break
        }
    }
}

extension RTCCameraPreviewView {
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return layer as? AVCaptureVideoPreviewLayer
    }

    open override var contentMode: UIView.ContentMode {
        set {
            guard let previewLayer = previewLayer else {
                return print("missing preview layer")
            }

            switch newValue {
            case .scaleAspectFill:
                previewLayer.videoGravity = .resizeAspectFill
            case .scaleAspectFit:
                previewLayer.videoGravity = .resizeAspect
            case .scaleToFill:
                previewLayer.videoGravity = .resize
            default:
                print("Unexpected contentMode")
            }
        }
        get {
            guard let previewLayer = previewLayer else {
                print("missing preview layer")
                return .scaleToFill
            }

            switch previewLayer.videoGravity {
            case .resizeAspectFill:
                return .scaleAspectFill
            case .resizeAspect:
                return .scaleAspectFit
            case .resize:
                return .scaleToFill
            default:
                print("Unexpected contentMode")
                return .scaleToFill
            }
        }
    }
}
