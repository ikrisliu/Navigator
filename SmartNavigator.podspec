Pod::Spec.new do |s|
  s.name = 'SmartNavigator'
  s.version = '1.8.0'
  s.license = 'MIT'
  s.summary = 'Generic navigation framework for view controllers'
  s.homepage = 'https://github.com/ikrisliu/Navigator'
  s.authors = { 'Kris Liu' => 'ikris.liu@gmail.com' }
  s.source = { :git => 'https://github.com/ikrisliu/Navigator.git', :tag => s.version }

  s.ios.deployment_target = '10.0'
  s.swift_versions = ['5.1', '5.2', '5.3', '5.4', '5.5', '5.6']
  
  s.module_name = 'Navigator'
  s.source_files = 'Sources/Navigator/**/*.swift'
end
