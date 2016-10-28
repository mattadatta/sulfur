Pod::Spec.new do |s|
  s.name                  = "Sulfur"
  s.version               = "2.0.0"
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

  s.dependency 'XCGLogger', '4.0.0'
  s.dependency 'Cartography', '1.0.1'
  s.dependency 'RxSwift', '3.0.0'
end
