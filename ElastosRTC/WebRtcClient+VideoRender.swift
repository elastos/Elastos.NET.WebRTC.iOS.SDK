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
            peerConnection.add(localAudioTrack, streamIds: ["stream0"])
        }

        if self.options.isEnableVideo {
            RTCDispatcher.dispatchAsync(on: .typeMain) {
                print(self.localVideoTrack)
                self.remoteVideoView = RemoteVideoView(frame: .zero)
                self.localVideoView = self.createLocalVideoView()
                if Platform.isSimulator {
                    self.videoCaptureController.stopCapture()
                } else {
                    self.videoCaptureController.startCapture()
                }
            }
        }
        if self.options.isEnableDataChannel {
            self.dataChannel = self.createDataChannel()
            assert(self.dataChannel != nil, "create data channel failed")
            dataChannel?.delegate = self
            Thread(target: self, selector: #selector(startToSendData), object: nil).start()
        }
    }
}
