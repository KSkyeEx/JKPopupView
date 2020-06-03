#
# Be sure to run `pod lib lint JKPopupView.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'JKPopupView'
  s.version          = '1.1.1'
  s.summary          = 'JKPopupView.以不同的方式弹出各种自定义的视图'
  s.description      = 'JKPopupView.以不同的方式弹出各种自定义的视图,当传递了view，就显示在view上，否则就在window上'

  s.homepage         = 'https://github.com/jokerwking/JKPopupView'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'weijoker_king' => 'weijoker_king@163.com' }
  s.source           = { :git => 'https://github.com/jokerwking/JKPopupView.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'JKPopupView/Classes/**/*'
end
