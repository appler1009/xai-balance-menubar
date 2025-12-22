#!/bin/bash

# Generate code coverage report for local development
set -e

echo "Building and running tests with coverage..."

# Clean any existing test results
rm -rf TestResults.xcresult
rm -f coverage.json

# Build and run tests with coverage
echo "Running tests with coverage enabled..."
xcodebuild test -project xAI-Balance-Menu.xcodeproj -scheme "xAI-Balance-Menu" \
  -destination 'platform=macOS,arch=x86_64' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Generate coverage report
echo ""
echo "Generating coverage report..."
xcrun xccov view --report TestResults.xcresult

# Generate HTML coverage report if available
echo ""
echo "Coverage report saved to TestResults.xcresult"
echo "You can view the detailed report by running:"
echo "xcrun xccov view --report --html TestResults.xcresult"