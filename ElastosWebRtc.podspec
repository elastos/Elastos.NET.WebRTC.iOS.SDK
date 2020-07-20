#
#  Be sure to run `pod spec lint ElastosWebRtc.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "ElastosWebRtc"
  spec.version      = "0.0.1"
  spec.summary      = "A short description of ElastosWebRtc."
  spec.description  = "Using the Google WebRTC for iOS."
  spec.homepage     = "https://github.com/Tomas-Shao/Elastos.NET.WebRTC.Swift.SDK"
  spec.license      = "MIT"
  spec.author       = { "Tomas Shao" => "zeliang.shao@gmail.com" }
  spec.source       = { :git => "git@github.com:Tomas-Shao/Elastos.NET.WebRTC.Swift.SDK.git", :branch => "develop" }
  spec.platform     = :ios, "11.0"

  spec.source_files = "ElastosRTC/*.{swift}"
  spec.requires_arc = true
  spec.swift_version = '5.0'
  spec.dependency "GoogleWebRTC", "1.1.29400"
  spec.dependency "ElastosCarrierSDKWebRTC", "1.5.0"

end
