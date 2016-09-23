platform :ios, '9.0'
use_frameworks!

project 'Sulfur.xcodeproj'
workspace 'Sulfur'

abstract_target 'SulfurProject' do

  pod 'XCGLogger', '~> 4.0'
  pod 'Cartography', :git => 'https://github.com/robb/Cartography.git', :branch => 'swift3_ci'
  pod 'RxSwift', '~> 3.0.0-beta.1'

  target 'Sulfur' do
    target 'SulfurTests' do
      inherit! :search_paths
    end
  end
end
