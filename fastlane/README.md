fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios carthage_bootstrap
```
fastlane ios carthage_bootstrap
```
Run carthage bootstrap
### ios test
```
fastlane ios test
```
Run test
### ios lint_podspec
```
fastlane ios lint_podspec
```
Lint podspec
### ios bump_up_version
```
fastlane ios bump_up_version
```
Bump up next version
### ios create_pr_to_public
```
fastlane ios create_pr_to_public
```
Create GitHub PR to `payjp/payjp-ios` from internal repo. (internal only)
### ios check_swift_format
```
fastlane ios check_swift_format
```
Check Swift format with swiftLint
### ios check_objc_format
```
fastlane ios check_objc_format
```
Check Objective-C format with clang-format
### ios create_pr_to_update_docs
```
fastlane ios create_pr_to_update_docs
```
Create PR to update docs
### ios distribute_sample_app
```
fastlane ios distribute_sample_app
```
Distribute sample app with Firebase App Distribution
### ios build_swiftpm
```
fastlane ios build_swiftpm
```
Build with Package.swift
### ios build_carthage_swift_example
```
fastlane ios build_carthage_swift_example
```
Build carthage-swift example app
### ios build_cocoapods_objc_example
```
fastlane ios build_cocoapods_objc_example
```
Build cocoapods-objc example app

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
