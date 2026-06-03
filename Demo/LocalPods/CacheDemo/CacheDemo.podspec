Pod::Spec.new do |s|
  s.name             = 'CacheDemo'
  s.version          = '0.1.0'
  s.summary          = 'CacheDemo demo module for BASwiftKit.'
  s.homepage         = 'https://github.com/boai/BASwiftKit'
  s.license          = { :type => 'MIT', :file => '../../../LICENSE' }
  s.author           = { 'boai' => 'sunboyan@outlook.com' }
  s.source           = { :git => 'https://github.com/boai/BASwiftKit.git', :tag => "\#{s.version}" }
  s.ios.deployment_target = '15.0'
  s.swift_version    = '5.0'
  s.source_files     = 'Sources/**/*.swift'
  s.dependency 'BASwiftKit'
  s.dependency 'DemoCommon'
  s.dependency 'SnapKit'
end
