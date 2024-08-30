fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios carthage_bootstrap

```sh
[bundle exec] fastlane ios carthage_bootstrap
```

Run carthage bootstrap

### ios test

```sh
[bundle exec] fastlane ios test
```

Run test

### ios lint_podspec

```sh
[bundle exec] fastlane ios lint_podspec
```

Lint podspec

### ios bump_up_version

```sh
[bundle exec] fastlane ios bump_up_version
```

Bump up next version

### ios create_pr_to_public

```sh
[bundle exec] fastlane ios create_pr_to_public
```

Create GitHub PR to `payjp/payjp-ios` from internal repo. (internal only)

### ios check_swift_format

```sh
[bundle exec] fastlane ios check_swift_format
```

Check Swift format with swiftLint

### ios check_objc_format

```sh
[bundle exec] fastlane ios check_objc_format
```

Check Objective-C format with clang-format

### ios update_docs

```sh
[bundle exec] fastlane ios update_docs
```

Update docs

### ios create_pr_to_update_docs

```sh
[bundle exec] fastlane ios create_pr_to_update_docs
```

Create PR to update docs

### ios distribute_sample_app

```sh
[bundle exec] fastlane ios distribute_sample_app
```

Distribute sample app with Firebase App Distribution

### ios build_swiftpm

```sh
[bundle exec] fastlane ios build_swiftpm
```

Build with Package.swift

### ios build_carthage_swift_example

```sh
[bundle exec] fastlane ios build_carthage_swift_example
```

Build carthage-swift example app

### ios build_cocoapods_objc_example

```sh
[bundle exec] fastlane ios build_cocoapods_objc_example
```

Build cocoapods-objc example app

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
