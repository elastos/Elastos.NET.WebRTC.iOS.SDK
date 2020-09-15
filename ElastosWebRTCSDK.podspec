#
#  Be sure to run `pod spec lint ElastosWebRtc.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "ElastosWebRTCSDK"
  spec.version      = "0.0.1"
  spec.summary      = "Elastos WebRtc"
  spec.description  = "Using the Google WebRTC for iOS."
  spec.homepage     = "https://gitlab.com/elastos/Elastos.NET.WebRTC.iOS.SDK"
  spec.license      = "MIT"
  spec.source       = { :git => "git@gitlab.com:elastos/Elastos.NET.WebRTC.iOS.SDK.git", :branch => "master" }
  spec.platform     = :ios, "11.0"

  spec.source_files = "ElastosRTC/*.{swift}"
  spec.requires_arc = true
  spec.swift_version = '5.0'
  spec.dependency "GoogleWebRTC", "1.1.31999"
  spec.dependency "ElastosCarrierSDK", "5.6.4"

end
