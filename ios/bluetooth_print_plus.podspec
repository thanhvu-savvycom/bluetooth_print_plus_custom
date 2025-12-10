#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint bluetooth_print_plus.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'bluetooth_print_plus'
  s.version          = '2.4.5'
  s.summary          = 'A new Flutter project.'
  s.description      = <<-DESC
A new Flutter project.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.static_framework = true
  s.dependency 'Flutter'
  s.dependency 'GSDK', '0.0.7'
  s.platform = :ios, '11.0'
  s.static_framework = true
  s.swift_version = '5.0'

  # TSC MFI Framework
  s.vendored_frameworks = 'Frameworks/tscswift.framework'
  s.frameworks = 'ExternalAccessory'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
      'DEFINES_MODULE' => 'YES',
      'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
      'FRAMEWORK_SEARCH_PATHS' => '$(inherited) "${PODS_CONFIGURATION_BUILD_DIR}/Flutter"'
    }
end