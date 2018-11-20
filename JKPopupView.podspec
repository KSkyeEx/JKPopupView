#
#  Be sure to run `pod spec lint JKMicroWebView.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

s.name         = "JKPopupView"
s.version      = "0.0.5"
s.summary      = "弹出自定义视图"
s.description  = "弹出自定义视图。"
s.homepage     = "https://github.com/JokerKin/JKPopupView"
s.license      = "MIT"
s.author             = { "joker" => "https://github.com/JokerKin" }
s.platform     = :ios, "8.0"
s.ios.deployment_target = "8.0"

s.public_header_files = 'JKPopupView/**/**/**/*.h'
s.source       = { :git => "https://github.com/JokerKin/JKPopupView.git", :tag => "#{s.version}"}

s.source_files  = "JKPopupView", "JKPopupView/JKPopupView/JKPopupView/JKPopupView/*.{h,m}"
end
