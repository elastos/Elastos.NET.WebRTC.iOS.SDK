//
//  WebRtcClient+VideoRender.swift
//  ElastosRTC
//
//  Created by ZeLiang on 2020/6/4.
//  Copyright © 2020 Elastos Foundation. All rights reserved.
//

extension WebRtcClient {

    func setupMedia() {
        if self.options.isEnableAudio {
            peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        }

        if self.options.isEnableVideo {
            RTCDispatcher.dispatchAsync(on: .typeMain) {
                self.localVideoView.addSubview(self.localRenderView)
                self.remoteVideoView.addSubview(self.remoteRenderView)
                self.localVideoTrack.add(self.localRenderView)
                NSLayoutConstraint.activate([
                    self.localRenderView.leadingAnchor.constraint(greaterThanOrEqualTo: self.localVideoView.leadingAnchor),
                    self.localRenderView.trailingAnchor.constraint(lessThanOrEqualTo: self.localVideoView.trailingAnchor),
                    self.localRenderView.topAnchor.constraint(greaterThanOrEqualTo: self.localVideoView.topAnchor),
                    self.localRenderView.bottomAnchor.constraint(lessThanOrEqualTo: self.localVideoView.bottomAnchor),
                    self.localRenderView.centerXAnchor.constraint(equalTo: self.localVideoView.centerXAnchor),
                    self.localRenderView.centerYAnchor.constraint(equalTo: self.localVideoView.centerYAnchor),

                    self.remoteVideoView.leadingAnchor.constraint(greaterThanOrEqualTo: self.remoteRenderView.leadingAnchor),
                    self.remoteVideoView.trailingAnchor.constraint(lessThanOrEqualTo: self.remoteRenderView.trailingAnchor),
                    self.remoteVideoView.topAnchor.constraint(greaterThanOrEqualTo: self.remoteRenderView.topAnchor),
                    self.remoteVideoView.bottomAnchor.constraint(lessThanOrEqualTo: self.remoteRenderView.bottomAnchor),
                    self.remoteVideoView.centerXAnchor.constraint(equalTo: self.remoteRenderView.centerXAnchor),
                    self.remoteVideoView.centerYAnchor.constraint(equalTo: self.remoteRenderView.centerYAnchor),
                ])
                self.startCaptureLocalVideo(cameraPositon: .front, videoWidth: 1280, videoHeight: 1280 * 16 / 9, videoFps: 30)
            }
        }
        if self.options.isEnableDataChannel {
            createDataChannel()
            dataChannel?.delegate = self
            assert(self.dataChannel != nil, "create data channel failed")
            print("✅ enable data-channel")
        }
        
        Log.d(TAG, isEnableVideo ? "enable video" : "disable video")
        Log.d(TAG, isEnableAudio ? "enable audio" : "disable audio")
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
        localRenderView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }

    public func setRemoteVideoFrame(_ frame: CGRect) {
        remoteVideoView.frame = frame
        remoteRenderView.frame = CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height)
    }
}

extension WebRtcClient: RTCVideoViewDelegate {

    public func videoView(_ videoView: RTCVideoRenderer, didChangeVideoSize size: CGSize) {
        self.delegate?.onWebRtc(self, videoView: videoView, didChangeVideoSize: size)
    }
}
