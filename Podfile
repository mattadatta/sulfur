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
