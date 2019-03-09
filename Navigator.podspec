Pod::Spec.new do |s|
  s.name = 'Navigator'
  s.version = '1.0.0'
  s.license = 'MIT'
  s.summary = 'Generic navigation framework for view controllers'
  s.homepage = 'https://github.com/iKrisLiu/Navigator'
  s.authors = { 'Kris Liu' => 'ikris.liu@gmail.com' }
  s.source = { :git => 'https://github.com/iKrisLiu/Navigator.git', :tag => s.version }

  s.ios.deployment_target = '10.0'
  s.swift_version = '4.2'
  
  s.source_files = 'Navigator/**/*.{h,m,swift}'
end