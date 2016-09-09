platform :ios, '9.0'
use_frameworks!

project 'Sulfur.xcodeproj'
workspace 'Sulfur'

abstract_target 'SulfurProject' do

  pod 'Cartography', :git => 'https://github.com/mattadatta/Cartography.git', :branch => 'feature/swift-3'
  pod 'XCGLogger', :git => 'https://github.com/mattadatta/XCGLogger.git', :branch => 'feature/swift-3'
  pod 'RxSwift', :git => 'https://github.com/ReactiveX/RxSwift.git', :branch => 'develop'

  target 'Sulfur' do
    target 'SulfurTests' do
      inherit! :search_paths
    end
  end
end
