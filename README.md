Elastos WebRTC iOS SDK
=====================

## Introduction
Elastos WebRTC is the WebRTC framework over the Elastos Carrier network, which supports basic features of Audio/Video communication and data communication over DataChannel.

This is the repository of WebRTC iOS SDK over the Carrier network. With that, it's available for developers to implement VoIP applications on Android/iOS mobile platforms over the Carrier network.

## Build from source
### Install Prerequisites
Please be sure you have **CocoaPods** installed on your macOS device. Otherwise, run the following command to install it:
```shell
$ gem install cocopods
```

### Build WebRTC SDK
```shell
$ git clone git@github.com:elastos/Elastos.NET.WebRTC.iOS.SDK.git
$ cd Elastos.NET.WebRTC.iOS.SDK
$ pod install --repo-update
```
Then use **"Xcode"** to open the workspace and start the build process.

## Build Docs
Run the following script to generate swift APIs documents with the appledoc tool:
```shell
$ ./docs.sh
```

## Contribution
We welcome contributions to the Elastos WebRTC iOS SDK Project.

## Acknowledgments
A sincere thank you to all teams and projects that we rely on directly or indirectly.

## License
This project is licensed under the terms of the [GPLv3 license]

