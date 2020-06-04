//
//  WebRtcClient+VideoRender.swift
//  ElastosRTC
//
//  Created by tomas.shao on 2020/6/4.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import Foundation
import WebRTC

extension WebRtcClient {

	func setupVideo() {
		peerConnection.add(localVideoTrack, streamIds: ["stream0"])
		startCaptureLocalVideo(cameraPositon: .front, videoWidth: 640, videoHeight: 640*16/9, videoFps: 30)
		self.localVideoTrack.add(localRenderView)
	}

	func setupAudio() {
		peerConnection.add(localAudioTrack, streamIds: ["stream0"])
	}

	func startCaptureLocalVideo(cameraPositon: AVCaptureDevice.Position, videoWidth: Int, videoHeight: Int?, videoFps: Int) {
		if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
			guard let targetDevice = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == cameraPositon }) else {
				fatalError("could not found target device")
			}
			var targetFormat: AVCaptureDevice.Format?
			// find target format
			let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice)
			formats.forEach { (format) in
				let description = format.formatDescription as CMFormatDescription
				let dimensions = CMVideoFormatDescriptionGetDimensions(description)

				if dimensions.width == videoWidth && dimensions.height == videoHeight ?? 0 {
					targetFormat = format
				} else if dimensions.width == videoWidth {
					targetFormat = format
				}
			}
			guard let format = targetFormat else { fatalError("could not found target format" ) }
			capturer.startCapture(with: targetDevice, format: format, fps: videoFps)
		} else if let capturer = videoCapturer as? RTCFileVideoCapturer{
			if Bundle.main.path( forResource: "sample.mp4", ofType: nil ) != nil {
				capturer.startCapturing(fromFileNamed: "sample.mp4") { err in print(err) }
			} else {
				print("file did not found")
			}
		}
	}
}

extension WebRtcClient: RTCVideoViewDelegate {

    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        print("\(#function)")
    }
}
