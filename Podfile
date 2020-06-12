source 'https://github.com/CocoaPods/Specs.git'
source 'git@github.com:Tomas-Shao/specs.git'

platform :ios, '11.0'
use_frameworks!

target 'ElastosRTCDemo' do
  pod 'ElastosWebRtc', :path => './'
  pod 'EFQRCode'
  pod 'SDWebImage'
  inherit! :search_paths
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
