platform :ios, '9.0'
use_frameworks!

project 'Sulfur.xcodeproj'
workspace 'Sulfur'

target 'Sulfur' do
  pod 'Cartography', :git => 'https://github.com/mattadatta/Cartography.git', :branch => 'feature/swift-3'
  pod 'XCGLogger', :git => 'https://github.com/mattadatta/XCGLogger.git', :branch => 'feature/swift-3'

  target 'SulfurTests' do
    inherit! :search_paths
  end
end

# Mach-O header bug with Xcode 8 beta 2
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ALWAYS_EMBED_SWIFT_STANDARD_LIBRARIES'] = 'NO'
    end
  end
end
