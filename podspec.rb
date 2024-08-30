module PAYJPSDK
  VERSION = '2.0.0'
  HOMEPAGE_URL = 'https://github.com/payjp/payjp-ios'
  LICENSE = { :type => 'MIT' }
  AUTHOR = { 'PAY.JP (https://pay.jp)' => 'support@pay.jp' }
  SOURCE = { :git => 'https://github.com/payjp/payjp-ios.git', :tag => VERSION }
  MODULE_NAME = 'PAYJP'
  SWIFT_VERSIONS = ['5.0', '5.1', '5.2', '5.3', '5.4', '5.5']
  IOS_DEPLOYMENT_TARGET = '12.0'
  SOURCE_FILES = ['Sources/**/*.{h,m,swift}']
  RESOURCE_BUNDLES = { 'PAYJP' => ['Sources/Resources/**/*'] }
  RESOURCES = [ 'Sources/Resources/Assets.xcassets' ]
  PUBLIC_HEADER_FILES = 'Sources/**/*.h'
  FRAMEWORKS = 'PassKit'
  POD_TARGET_XCCONFIG = { 'OTHER_SWIFT_FLAGS' => '-DPAYJPSDKCocoaPods' }
end
