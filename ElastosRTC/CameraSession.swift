//
//  CameraSession.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/6/5.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import AVFoundation

@objc protocol CameraSessionDelegate {
    
    func didOutput(_ sampleBuffer: CMSampleBuffer)
}

class CameraSession: NSObject {
    
    weak var delegate: CameraSessionDelegate?

    private var session: AVCaptureSession = {
        let session = AVCaptureSession()
        session.sessionPreset = .medium
        return session
    }()

    private lazy var output: AVCaptureVideoDataOutput = {
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "elastos.video.data.output", attributes: .concurrent))
        output.alwaysDiscardsLateVideoFrames = false
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange] as [String : Any]
        return output
    }()

    func start() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
            let input = try? AVCaptureDeviceInput(device: device) else {
            return assertionFailure("could not found input device")
        }
        session.addInput(input)
        session.addOutput(output)
        session.sessionPreset = .inputPriority
        session.usesApplicationAudioSession = false
        session.startRunning()
    }
}

extension CameraSession: AVCaptureVideoDataOutputSampleBufferDelegate {

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.delegate?.didOutput(sampleBuffer)
    }
}
