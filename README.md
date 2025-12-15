# xAI Balance Menu

A macOS menu bar app that displays the remaining balance from xAI's prepaid credit or postpaid invoice.

## Features

- Displays current prepaid credit balance or postpaid invoice amount in the menu bar
- Automatically refreshes every 30 minutes
- Manual refresh option
- Secure API key storage in macOS Keychain

## Setup

1. Clone the repository
2. Open `xAI-Balance-Menu.xcodeproj` in Xcode
3. Build and run the project

## Usage

1. Launch the app
2. Right-click the menu bar icon and select "Set API Key"
3. Enter your xAI API key
4. The balance will be displayed in the menu bar

## API

Uses xAI Management API endpoints:
- `/v1/management/prepaid-balance` for prepaid credit balance
- `/v1/management/postpaid-invoice` for postpaid invoice preview

## Building Releases

GitHub Actions automatically builds and releases the app on macOS.