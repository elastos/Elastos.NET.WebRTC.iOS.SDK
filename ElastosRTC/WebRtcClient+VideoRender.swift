/*
* Copyright (c) 2020 Elastos Foundation
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*/

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
