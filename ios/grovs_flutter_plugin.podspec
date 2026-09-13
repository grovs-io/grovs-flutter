Pod::Spec.new do |s|
  s.name             = 'grovs_flutter_plugin'
  s.version          = '3.0.0'
  s.summary          = 'Flutter plugin for the Grovs SDK.'
  s.description      = <<-DESC
Deep linking, smart links, analytics, user messaging, and campaign tracking for Flutter apps.
                       DESC
  s.homepage         = 'https://grovs.io'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Grovs' => 'support@grovs.io' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'Grovs', '~> 3.0'
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
