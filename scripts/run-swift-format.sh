#!/bin/bash -ex
ROOT="$(git rev-parse --show-toplevel)"
swiftlint --fix --format $ROOT --config $ROOT/.swiftlint.yml
swiftlint --fix --format $ROOT/example-swift/**/*.swift --config $ROOT/.swiftlint.yml
