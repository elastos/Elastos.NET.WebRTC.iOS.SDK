source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'
use_frameworks!

def common_pods
  pod "ElastosCarrierSDK", '5.6.4'
  pod "GoogleWebRTC", '1.1.31999'
end

# Debug Mode
target 'ElastosWebRTCSDK' do
  common_pods

  target 'WebRTCDemo' do
    pod 'EFQRCode', '5.1.6'
    pod 'QRCodeReader.swift', '10.1.0'
    pod 'MessageKit', '3.1.0'
    common_pods
    inherit! :search_paths
  end

  target 'ElastosWebRTCSDKTests' do
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
