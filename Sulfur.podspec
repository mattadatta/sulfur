Pod::Spec.new do |s|
  s.name                  = 'Sulfur'
  s.version               = '1.0.0'
  s.summary               = 'A collection of various utilities I\'ve been building out over time for iOS.'
  s.homepage              = 'https://github.com/mattadatta/sulfur'
  s.authors               = { 'Matthew Brown' => 'me.matt.brown@gmail.com' }
  s.license               = { :type => "MIT" }

  s.platform              = :ios
  s.ios.deployment_target = '9.0'
  s.requires_arc          = true
  s.source                = { :git => "https://github.com/mattadatta/sulfur.git", :tag => s.version }
  s.source_files          = "Sulfur/**/*.{swift,h,m"
  s.resources             = 'Sulfur/**/*.{lproj,storyboard}'
  s.module_name           = s.name
end
