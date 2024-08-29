# carthage.sh
# Usage example: ./carthage.sh build --platform iOS

set -euo pipefail

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

echo "IPHONEOS_DEPLOYMENT_TARGET = 12.0" >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"
carthage "$@"