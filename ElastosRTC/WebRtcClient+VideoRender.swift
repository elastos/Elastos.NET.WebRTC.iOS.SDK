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
		localVideoTrack.add(localRenderView)
	}

	func setupAudio() {
		peerConnection.add(localAudioTrack, streamIds: ["stream0"])
	}

	func startCaptureLocalVideo(cameraPositon: AVCaptureDevice.Position, videoWidth: Int, videoHeight: Int?, videoFps: Int) {
		if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
			guard let targetDevice = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == cameraPositon }) else {
				fatalError("could not find target device")
			}
			var targetFormat: AVCaptureDevice.Format?
			let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice)
			formats.forEach { format in
				let description = format.formatDescription as CMFormatDescription
				let dimensions = CMVideoFormatDescriptionGetDimensions(description)

				if dimensions.width == videoWidth && dimensions.height == videoHeight ?? 0 {
					targetFormat = format
				} else if dimensions.width == videoWidth {
					targetFormat = format
				}
			}
			guard let format = targetFormat else { fatalError("could not find target format" ) }
			capturer.startCapture(with: targetDevice, format: format, fps: videoFps)
		} else if let capturer = videoCapturer as? RTCFileVideoCapturer {
            #if DEBUG
			if Bundle.main.path( forResource: "sample.mp4", ofType: nil ) != nil {
				capturer.startCapturing(fromFileNamed: "sample.mp4") { err in print(err) }
			} else {
				print("file did not found")
			}
            #endif
		}
	}
}

extension WebRtcClient: RTCVideoViewDelegate {

    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        print("\(#function)")
        let isLandScape = size.width < size.height
        let isLocalRenderView = videoView.isEqual(localRenderView)

        //todo: other cases ?
        let renderView = isLocalRenderView ? localRenderView : remoteRenderView
        let parentView = isLocalRenderView ? localView : remoteView

        if isLandScape {
            let ratio = size.width / size.height
            renderView.frame = CGRect(x: 0, y: 0, width: parentView.frame.height * ratio, height: parentView.frame.height)
            renderView.center.x = parentView.frame.width / 2
        } else {
            let ratio = size.height / size.width
            renderView.frame = CGRect(x: 0, y: 0, width: parentView.frame.width, height: parentView.frame.width * ratio)
            renderView.center.y = parentView.frame.height / 2
        }
    }
}
