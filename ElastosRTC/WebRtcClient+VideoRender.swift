//
//  WebRtcClient+VideoRender.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/4.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

import AVFoundation

extension WebRtcClient {

    func setupMedia() {
        if self.options.isEnableAudio {
            peerConnection?.add(localAudioTrack, streamIds: ["stream0"])
        }

        if self.options.isEnableVideo {
            RTCDispatcher.dispatchAsync(on: .typeMain) {
                self.localVideoView.addSubview(self.localRenderView!)
                self.remoteVideoView.addSubview(self.remoteRenderView!)
                self.localRenderView!.frame = self.localVideoView.bounds
                self.remoteRenderView!.frame = self.remoteVideoView.bounds
                self.localVideoTrack.add(self.localRenderView!)
                self.startCaptureLocalVideo(cameraPositon: .front)
            }
        }
        if self.options.isEnableDataChannel {
            assert(self.dataChannel != nil, "create data channel failed")
            dataChannel?.delegate = self
            Thread(target: self, selector: #selector(startToSendData), object: nil).start()
        }
    }

    func startCaptureLocalVideo(cameraPositon: AVCaptureDevice.Position, videoWidth: CGFloat? = nil, videoHeight: CGFloat? = nil, videoFps: Double? = nil) {
        if let capturer = self.videoCapturer as? RTCCameraVideoCapturer {
            guard let targetDevice = RTCCameraVideoCapturer.captureDevices().first(where: { $0.position == cameraPositon }) else {
                fatalError("could not find target device")
            }
            var targetFormat: AVCaptureDevice.Format?
            var targetFps = videoFps

            let formats = RTCCameraVideoCapturer.supportedFormats(for: targetDevice)
            if let videoWidth = videoWidth, let videoHeight = videoHeight {
                formats.forEach { format in
                    let description = format.formatDescription as CMFormatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)

                    if dimensions.width == Int(videoWidth) && dimensions.height == Int(videoHeight) {
                        targetFormat = format
                    } else if dimensions.width == Int(videoWidth) {
                        targetFormat = format
                    }
                }
            }

            if targetFormat == nil {
                // choose highest resolution
                targetFormat = formats.sorted { CMVideoFormatDescriptionGetDimensions($0.formatDescription).width < CMVideoFormatDescriptionGetDimensions($1.formatDescription).width }.last
            }

            if targetFps == nil {
                targetFps = targetFormat?.videoSupportedFrameRateRanges.sorted { return $0.maxFrameRate < $1.maxFrameRate }.last?.maxFrameRate
            }

            guard let format = targetFormat, let fps = targetFps else { fatalError("could not find target format" ) }
            capturer.startCapture(with: targetDevice, format: format, fps: Int(fps))
        } else if let capturer = videoCapturer as? RTCFileVideoCapturer {
            #if DEBUG
            if Bundle.main.path( forResource: "sample.mp4", ofType: nil ) != nil {
                capturer.startCapturing(fromFileNamed: "sample.mp4") { err in print(err) }
            } else {
                Log.d(TAG, "cannot find sample video for simulator")
            }
            #endif
        } else {
            assertionFailure()
        }
    }

    public func getLocalVideoView() -> UIView? {
        if options.isEnableVideo {
            return self.localVideoView
        }
        return nil
    }

    public func getRemoteVideoView() -> UIView? {
        if options.isEnableVideo {
            return self.remoteVideoView
        }
        return nil
    }

    public func setLocalVideoFrame(_ frame: CGRect) {
        localVideoView.frame = frame
        localRenderView?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }

    public func setRemoteVideoFrame(_ frame: CGRect) {
        remoteVideoView.frame = frame
        remoteRenderView?.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }
}

extension WebRtcClient: RTCVideoViewDelegate {

    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        let isLocalView = videoView.isEqual(localRenderView)
        let parentView = isLocalView ? localVideoView : remoteVideoView
        let renderView = isLocalView ? localRenderView : remoteRenderView


        var frame = AVMakeRect(aspectRatio: size, insideRect: parentView.bounds)
        var scale: CGFloat = 1
        if frame.width > frame.height {
            // scale by height
            scale = parentView.bounds.height / frame.height
        } else {
            // scale by width
            scale = parentView.bounds.width / frame.width
        }

        frame.size.height *= scale
        frame.size.width *= scale
        renderView?.frame = frame
        renderView?.center = CGPoint(x: parentView.bounds.midX, y: parentView.bounds.midY)
    }
}
