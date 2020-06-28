## Protocol

### Install Pre-Requirements
Using cocoapods to manage dependencies of the WebRTC project, it must be installed before compilation.

Run the following commands to install **cocoapods**:

```shell
gem install cocoapods
```

### Build
```
git clone git@github.com:allcomsh/Elastos.NET.WebRTC.Swift.SDK.git

cd YOUR_LOCAL_PATH/Elastos.NET.WebRTC.Swift.SDK

pod install --repo-update --verbose

open ElastosRTC.xcworkspace

```

### WebRTC Protocol

| type               | sdp      | candidates | reason   | options  |
|--------------------|----------|------------|----------|----------|
| offer              | required | -          | -        | required |
| answer             | required | -          | -        | -        |
| candidate          | -        | required   | -        | -        |
| removal-candidates | -        | required   | -        | -        |
| bye                | -        | -          | required | -        |

### Example
#### 1. Offer

```json
{
	"type":"offer",
	"sdp":"rtc_session_description_generated_by_webrtc",
	"options":["audio","video"]
}
```
### 2. Answer
```
{
	"type":"answer",
	"sdp":"rtc_session_description_generated_by_webrtc"
}
```
### 3. Candidate

```
{
	"type":"candidate",
	"candidates": [{
		"sdp": "candidate:684496083 1 udp 1685855999 112.65.48.165 17465 ...",
		"sdpMLineIndex": 0,
		"sdpMid": audio
	}]
}
```
### 4. Removal-Candidate

```
{
	"type":"remove-candidates",
	"candidates": 
	[
		{
			"sdp": "candidate:684496083 1 udp 1685855999 112.65.48.165 17465 ...",
			"sdpMLineIndex": 0,
			"sdpMid": audio
		}, 
		{
			"sdp": "rtc_candiate_desciption",
			"sdpMLineIndex": 0,
			"sdpMid": audio
		}, 
		...
	]
}
```
### 5. Bye

```
{
	"type":"bye"
	"reason": "reject"
}
```
