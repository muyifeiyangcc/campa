# Campa iOS App Design

## Goal
Create a standard UIKit-based iOS app project named Campa that can be opened in Xcode and built for iOS 15.0+.

## Architecture
The app uses a small MVVM structure. `HomeViewController` owns the initial UIKit screen, while `HomeViewModel` provides display text and keeps presentation state testable outside UIKit.

## Project Structure
- `Campa.xcodeproj`: Xcode project with app, unit test, and UI test targets.
- `Campa/App`: application lifecycle files.
- `Campa/Presentation/Home`: home screen view controller and view model.
- `Campa/Resources`: app resources, launch screen, assets, and Info.plist.
- `CampaTests`: unit tests for Core/presentation logic.
- `CampaUITests`: smoke UI test target.

## Behavior
The first screen displays the localized app title `Campa`. The ViewModel exposes that title so it can be unit-tested without launching UIKit.

## Testing
Unit tests verify the home title. UI tests verify the app launches.

## Constraints
The project follows the local `AGENTS.md`: Swift 5.9+, iOS 15.0+, UIKit, MVVM, XCTest, and localization-ready UI strings.
