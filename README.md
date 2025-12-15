# xAI Balance Menu

A macOS menu bar app that displays the remaining prepaid credit balance and postpaid invoice amount from xAI.

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