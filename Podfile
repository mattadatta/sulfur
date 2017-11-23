platform :ios, '11.0'
use_frameworks!

project 'Sulfur.xcodeproj'
workspace 'Sulfur'

abstract_target 'SulfurProject' do

  pod 'XCGLogger',    '~> 6.0'
  pod 'Cartography',  '~> 3.0'
  pod 'RxSwift',      '~> 4.0'
  pod 'RxCocoa',      '~> 4.0'
  pod 'RxSwiftExt',   '~> 3.0'
  pod 'RxGesture',    '~> 1.2'

  target 'Sulfur' do
    target 'SulfurTests' do
      inherit! :search_paths
    end
  end
end
