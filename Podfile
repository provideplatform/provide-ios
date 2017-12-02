source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.3'
inhibit_all_warnings!
use_frameworks!

project 'provide/provide.xcodeproj'

def shared_pods
  pod 'Analytics'
  pod 'BadgeSwift'
  pod 'ELFixSecureTextFieldFont', git: 'https://github.com/elegion/ELFixSecureTextFieldFont'
  pod 'FacebookCore'
  pod 'FacebookLogin'
  pod 'Firebase/Core'
  pod 'Firebase/Crash'
  pod 'FontAwesomeKit/FontAwesome'
  pod 'jetfire'
  pod 'JSQMessagesViewController', '~> 7.3.4'
  pod 'KTSwiftExtensions', path: 'KTSwiftExtensions'
  pod 'NotificationBannerSwift'
  pod 'OHHTTPStubs'
  pod 'PDTSimpleCalendar'
  pod 'Reachability'
  pod 'RestKit'
  pod 'RFGravatarImageView'
  pod 'SDWebImage'
  pod 'SWTableViewCell', git: 'https://github.com/kthomas/SWTableViewCell'
  pod 'SwiftLint'
  pod 'UICKeyChainStore'
end


target 'provide' do
  shared_pods
end

target 'provideTests' do
  shared_pods
end

target 'provideUITests' do
  shared_pods
end

target 'unicorn' do
  shared_pods
end

target 'unicorn driver' do
  shared_pods
end
