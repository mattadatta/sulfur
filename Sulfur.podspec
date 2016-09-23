Pod::Spec.new do |s|
  s.name                  = "Sulfur"
  s.version               = "1.7.0"
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

  s.dependency 'XCGLogger', '~> 4.0'
  s.dependency 'Cartography' #, :git => 'https://github.com/robb/Cartography.git', :branch => 'swift3_ci'
  s.dependency 'RxSwift', '~> 3.0.0-beta.1'
end
