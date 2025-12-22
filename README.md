# xAI Balance Menu

A macOS menu bar app that displays the remaining prepaid credit balance and postpaid invoice amount from xAI.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Features

- Displays current prepaid credit balance and postpaid invoice amount in the menu bar
- Custom xAI logo as the menubar icon
- Automatically refreshes every 30 minutes
- Manual refresh option
- Secure API key and team ID storage in macOS Keychain
- Option to launch automatically at login

## Setup

1. Clone the repository
2. Open `xAI-Balance-Menu.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Launch the app
2. Right-click the menu bar icon and select "Set API Key"
3. Enter your xAI API key and Team ID
4. The balances will be displayed in the menu bar

## API

Uses xAI Management API endpoint:
- `/v1/billing/teams/{team_id}/postpaid/invoice/preview` for both prepaid credit balance and postpaid invoice amount

## Version Management

The app uses git tags for version management. The version is embedded in the app's About dialog.

### Updating Version Locally

After creating a new git tag, update the version in Info.plist:

```bash
# After creating a new tag
git tag v0.0.3
./scripts/update-version.sh
git add Info.plist
git commit -m "Update version to 0.0.3"
```

The `update-version.sh` script:
- Extracts the latest git tag (e.g., `v0.0.2` → `0.0.2`)
- Updates `CFBundleShortVersionString` in Info.plist with the version
- Updates `CFBundleVersion` with the commit count for unique build numbers
- Updates `CommitYear` with the year of the latest commit
- Updates `NSHumanReadableCopyright` with dynamic copyright information

### Automatic Version Updates

GitHub Actions automatically updates the version when you push new tags:
- Push a tag: `git push origin v0.0.3`
- GitHub Actions updates Info.plist and commits the changes
- The About dialog will then display the correct version

## Building Releases

GitHub Actions automatically:
- Builds the app on macOS for every push to `main` and pull requests
- Uses `release-please` to generate release notes and manage versioning
- On release creation, builds the final app, creates a DMG installer, and uploads it as a release asset

## Contributing

1. Create a feature branch from `main`
2. Make changes and commit with conventional commit messages (e.g., `feat: add new feature`)
3. Open a pull request to `main`
4. GitHub Actions will run builds and tests
5. Merge the PR, and `release-please` will create a release PR with notes
6. Merge the release PR to publish the new version

## Code Coverage

The project includes code coverage tracking using Codecov.

### Setting up Codecov

1. Fork/connect your repository on [Codecov](https://codecov.io)
2. Add a `CODECOV_TOKEN` secret to your GitHub repository settings (get the token from Codecov)
3. The CI workflow will automatically upload coverage reports

### Local Development

Generate coverage reports locally:

```bash
chmod +x scripts/generate-coverage.sh
./scripts/generate-coverage.sh
```

This will:
- Run all tests with coverage enabled
- Generate a coverage report in `TestResults.xcresult`
- Display the coverage summary

To view detailed HTML coverage report:
```bash
xcrun xccov view --report --html TestResults.xcresult
```

### CI Integration

- Code coverage is automatically generated and uploaded on every push to `main` and pull requests
- The CI workflow runs tests with `-enableCodeCoverage YES`
- Coverage data is converted and uploaded to Codecov

### GitHub Secrets Setup

To enable Codecov integration:

1. Go to your GitHub repository settings → Secrets and variables → Actions
2. Add a new repository secret:
   - Name: `CODECOV_TOKEN`
   - Value: Your Codecov token (get this from your Codecov repository settings)
3. The CI workflow will automatically use this token to upload coverage reports