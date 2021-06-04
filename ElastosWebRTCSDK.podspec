#
#  Be sure to run `pod spec lint ElastosWebRTCSDK.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "ElastosWebRTCSDK"
  spec.version      = "1.0.3"

  spec.summary      = "Elastos WebRTC iOS SDK"
  spec.description  = "Elastos WebRTC iOS SDK Framework Distribution."
  spec.homepage     = "https://www.elastos.org"

  spec.license      = { :type => 'GPLv3', :file => './LICENSE' }

  spec.author       = { "weili" => "weili@130mail.com" }

  spec.platform     = :ios
  spec.platform     = :ios, "11.0"

  spec.source       = { :git => "git@github.com:elastos/Elastos.NET.WebRTC.iOS.SDK.git", :tag => "#{spec.version}" }
  spec.source_files = "ElastosWebRTCSDK/*.{swift}"

  spec.requires_arc = true
  spec.swift_version = '5.0'
  spec.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }

  spec.dependency "GoogleWebRTC", "1.1.31999"
  spec.dependency "ElastosCarrierSDK", "~> 6.0.3"
  spec.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  spec.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

end
