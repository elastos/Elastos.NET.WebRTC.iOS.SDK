//
//  CameraSession.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/6/5.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import AVFoundation

class CameraSession: NSObject {

    private var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        return session
    }()

    private var output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        let queue: DispatchQueue = DispatchQueue(label: "videodata", attributes: .concurrent)
        output.setSampleBufferDelegate(self, queue: queue)
        output.alwaysDiscardsLateVideoFrames = false
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] as [String : Any]
        return output
    }()

    private var device: AVCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)

    override init() {
        super.init()
    }

    func setupSession() {
        guard let input = try? AVCaptureDeviceInput(device: device) else {
            return assertionFailure("could not found input device")
        }
        session.addInput(input)
        session.addOutput(self.output)
        session.sessionPreset = .inputPriority
        session.usesApplicationAudioSession = false
        session.startRunning()
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {

}
