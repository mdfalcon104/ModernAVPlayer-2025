use_frameworks!
inhibit_all_warnings!

target 'ModernAVPlayer_Example' do
  platform :ios, '12.0'
  pod 'ModernAVPlayer/RxSwift', :path => '.'
  pod 'SwiftLint', '0.38.2'

  target 'ModernAVPlayer_Tests' do
    inherit! :search_paths

	pod 'Quick', '2.2.0'
	pod 'Nimble', '8.0.4'
	pod 'SwiftyMocky', '3.5.0'

  end
end

target 'ModernAVPlayer_Example_tvOS' do
  platform :tvos, '12.0'
  pod 'ModernAVPlayer/RxSwift', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
      config.build_settings['TVOS_DEPLOYMENT_TARGET'] = '12.0'
      
      # Fix XCTest linking for test pods (Nimble, Quick, SwiftyMocky)
      test_pod_names = ['Nimble', 'Quick', 'SwiftyMocky']
      if test_pod_names.include?(target.name)
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] ||= []
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] << '$(inherited)'
        config.build_settings['OTHER_LDFLAGS'] ||= []
        xctest_path = '$(SDKROOT)/System/Library/Frameworks'
        unless config.build_settings['OTHER_LDFLAGS'].include?("-F#{xctest_path}")
          config.build_settings['OTHER_LDFLAGS'] << "-F#{xctest_path}"
        end
      end
    end
  end
end
