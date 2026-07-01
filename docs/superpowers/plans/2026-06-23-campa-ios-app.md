# Campa iOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a standard UIKit iOS app project named Campa with MVVM home screen, unit tests, and UI tests.

**Architecture:** The app target contains lifecycle files under `Campa/App`, a home feature under `Campa/Presentation/Home`, and resources under `Campa/Resources`. Tests validate `HomeViewModel` behavior and app launch.

**Tech Stack:** Swift 5.9+, UIKit, XCTest, Xcode project format, iOS 15.0+.

---

### Task 1: Project and Red Test

**Files:**
- Create: `Campa.xcodeproj/project.pbxproj`
- Create: `CampaTests/HomeViewModelTests.swift`
- Create: `CampaUITests/CampaUITests.swift`

- [x] **Step 1: Write the failing unit test**

```swift
import XCTest
@testable import Campa

final class HomeViewModelTests: XCTestCase {
    func testTitleReturnsAppName() {
        let viewModel = HomeViewModel()

        XCTAssertEqual(viewModel.title, "Campa")
    }
}
```

- [x] **Step 2: Run test to verify it fails**

Run: `xcodebuild test -project Campa.xcodeproj -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: failure because `HomeViewModel` is not implemented yet.

### Task 2: Minimal App Implementation

**Files:**
- Create: `Campa/App/AppDelegate.swift`
- Create: `Campa/App/SceneDelegate.swift`
- Create: `Campa/Presentation/Home/HomeViewModel.swift`
- Create: `Campa/Presentation/Home/HomeViewController.swift`
- Create: `Campa/Resources/Info.plist`
- Create: `Campa/Resources/Base.lproj/LaunchScreen.storyboard`
- Create: `Campa/Resources/Assets.xcassets/Contents.json`

- [x] **Step 1: Implement minimal ViewModel**

```swift
final class HomeViewModel {
    let title = NSLocalizedString("Campa", comment: "Application title")
}
```

- [x] **Step 2: Implement UIKit home screen**

```swift
final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel

    init(viewModel: HomeViewModel = HomeViewModel()) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        nil
    }
}
```

- [x] **Step 3: Run unit and UI tests**

Run: `xcodebuild test -project Campa.xcodeproj -scheme Campa -destination 'platform=iOS Simulator,name=iPhone 15'`
Expected: tests pass.
