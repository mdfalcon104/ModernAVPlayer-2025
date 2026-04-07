Pod::Spec.new do |s|
  s.name             = 'ModernAVPlayer2'
  s.version          = '1.8.2'
  s.summary          = 'ModernAVPlayer2 is an audio persistence AVPlayer wrapper'
  s.description      = <<-DESC
ModernAVPlayer is an ongoing project that aims to create a more usable audio video player with readable status and network persistence option.
                       DESC
  s.homepage         = 'https://github.com/mdfalcon104/ModernAVPlayer-2025'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'mdfalcon104' => 'mdfalcon104@example.com' }
  s.source           = { :git => 'https://github.com/mdfalcon104/ModernAVPlayer-2025.git', :tag => s.version.to_s }
  s.default_subspec  = 'Core'

  s.ios.deployment_target = '10.0'
  # s.tvos.deployment_target = '12.0'
  s.swift_version = '5.0'

  s.subspec 'Core' do |core|
    core.source_files = 'Sources/Core/**/*'
  end

  s.subspec 'RxSwift' do |ss|
    ss.ios.deployment_target = '10.0'
    # ss.tvos.deployment_target = '12.0'
    ss.dependency 'ModernAVPlayer2/Core'
    ss.dependency "RxSwift", "~> 6.0"
    ss.dependency "RxCocoa", "~> 6.0"
    ss.source_files = 'Sources/RxModernAVPlayer/**/*'
  end

end
