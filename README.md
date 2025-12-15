# xAI Balance Menu

A macOS menu bar app that displays the remaining prepaid credit balance and postpaid invoice amount from xAI.

## Features

- Displays current prepaid credit balance and postpaid invoice amount in the menu bar
- Automatically refreshes every 30 minutes
- Manual refresh option
- Secure API key and team ID storage in macOS Keychain

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

GitHub Actions automatically builds and releases the app on macOS.