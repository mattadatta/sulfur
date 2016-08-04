platform :ios, '9.0'
use_frameworks!

project 'Sulfur.xcodeproj'
workspace 'Sulfur'

abstract_target 'SulfurProject' do
  pod 'Cartography', :git => 'https://github.com/mattadatta/Cartography.git', :branch => 'feature/swift-3'
  pod 'XCGLogger', :git => 'https://github.com/mattadatta/XCGLogger.git', :branch => 'feature/swift-3'

  target 'Sulfur' do
  end
  target 'SulfurTests' do
  end
end

# Xcode 8 beta 4
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3.0'
    end
  end
end
