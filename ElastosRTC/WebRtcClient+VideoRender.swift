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

    func setupMedia() {
        if options.isEnabledAudio {
            Logger.log(level: .debug, message: "enable audio")
            peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        } else {
            // disable audio
            Logger.log(level: .error, message: "cannot disable audio")
        }

        if options.isEnabledVideo {
            localVideoView.addSubview(localRenderView)
            remoteVideoView.addSubview(remoteRenderView)
            Logger.log(level: .debug, message: "enable video")
            startCaptureLocalVideo(cameraPositon: .front, videoWidth: 640, videoHeight: 640*16/9, videoFps: 30)
            localVideoTrack.add(localRenderView)
            peerConnection.add(localVideoTrack, streamIds: ["stream0"])
        } else {
            // todo: disable video
            localRenderView.removeFromSuperview()
            remoteRenderView.removeFromSuperview()
        }
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

    public func getLocalVideoView() -> UIView? {
        if options.isEnabledVideo == true {
            return self.localVideoView
        }
        return nil
    }

    public func getRemoteVideoView() -> UIView? {
        if options.isEnabledVideo == true {
            return self.remoteVideoView
        }
        return nil
    }

    public func setLocalVideoFrame(_ frame: CGRect) {
        localVideoView.frame = frame
        localRenderView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }

    public func setRemoteVideoFrame(_ frame: CGRect) {
        remoteVideoView.frame = frame
        remoteRenderView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }
}

extension WebRtcClient: RTCVideoViewDelegate {

    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        let isLandScape = size.width < size.height
        let isLocalRenderView = videoView.isEqual(localRenderView)

        let parentView = isLocalRenderView ? localVideoView : remoteVideoView
        let renderView = isLocalRenderView ? localRenderView : remoteRenderView

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
