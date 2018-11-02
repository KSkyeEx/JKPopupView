Pod::Spec.new do |s|
s.name = 'JKPopup'
s.version = '0.0.4'
s.summary = 'An easy way to use frame'
s.homepage = 'https://github.com/JokerKin/JKPopup'
s.license = 'MIT'
s.authors = {"JokerKin" => "weijoker_king@163.com"}
s.platform = :ios, '8.0'
s.source = {:git => 'https://github.com/JokerKin/JKPopup.git', :tag => s.version}
s.source_files = "JKPopup", "JKPopup/**/*.{h,m}"
s.requires_arc = true
end