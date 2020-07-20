source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:Tomas-Shao/specs.git'

platform :ios, '11.0'
use_frameworks!

# Debug Mode
target 'ElastosRTC' do
  pod "GoogleWebRTC"
  pod "ElastosCarrierSDKWebRTC"

  target 'ElastosRTCDemo' do
    pod 'EFQRCode'
    pod 'QRCodeReader.swift'
    pod 'MessageKit'
    pod 'ElastosWebRtc', :path => './'
    inherit! :search_paths
  end

  target 'ElastosRTCTests' do
    pod 'ElastosWebRtc', :path => './'
    inherit! :search_paths
  end
end

# Release Mode
#target 'ElastosRTCDemo' do
#  pod 'ElastosWebRtc', :path => './'
#  pod 'EFQRCode'
#  inherit! :search_paths
#end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
