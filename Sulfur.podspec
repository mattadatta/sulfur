Pod::Spec.new do |s|
  s.name                  = "Sulfur"
  s.version               = "3.0.0"
  s.summary               = "A collection of various utilities I've been building out over time for iOS."
  s.homepage              = "https://github.com/mattadatta/sulfur"
  s.authors               = { "Matthew Brown" => "me.matt.brown@gmail.com" }
  s.license               = { :type => "MIT", :file => 'LICENSE' }

  s.platform              = :ios
  s.ios.deployment_target = "9.0"
  s.requires_arc          = true
  s.source                = { :git => "https://github.com/mattadatta/sulfur.git", :tag => "v/#{s.version}" }
  s.source_files          = "Sulfur/**/*.{swift,h,m}"
  s.module_name           = s.name

  s.dependency 'XCGLogger',    '~> 6.0'
  s.dependency 'Cartography',  '~> 3.0'
  s.dependency 'RxSwift',      '~> 4.0'
  s.dependency 'RxCocoa',      '~> 4.0'
  s.dependency 'RxSwiftExt',   '~> 3.0'
  s.dependency 'RxGesture',    '~> 1.2'
end
