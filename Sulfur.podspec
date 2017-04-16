Pod::Spec.new do |s|
  s.name                  = "Sulfur"
  s.version               = "2.0.1"
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

  s.dependency 'XCGLogger',    '~> 5.0'
  s.dependency 'Cartography',  '~> 1.1'
  s.dependency 'RxSwift',      '~> 3.4'
  s.dependency 'RxCocoa',      '~> 3.4'
  s.dependency 'RxSwiftExt',   '~> 2.4'
  s.dependency 'RxGesture',    '~> 1.0'
end
