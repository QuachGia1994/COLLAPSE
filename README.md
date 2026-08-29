# COLLAPSE

COLLAPSE is a one-tap iOS game: the player sees two near-future timelines, taps to choose between them, and watches the selected future become real when the decision timer closes.

## Core loop
1. Read both visible future paths.
2. Tap to switch the selected future.
3. The timer commits the choice.
4. The rejected future collapses.
5. Survive the chosen path to score and immediately receive the next prediction.

The game never hides the outcome that matters to the current decision. Difficulty comes from shorter decision time and denser future modifiers, not from invisible hazards.

## Plus
COLLAPSE Plus is designed as a lifetime purchase. It unlocks premium skins and presentation features only. It must never modify hazard placement, timing, score, survival, or leaderboard fairness.

StoreKit product ID: `collapse.plus.lifetime`.

## Project generation
The repository uses XcodeGen so the Xcode project does not need to be hand-maintained.

```sh
xcodegen generate
open Collapse.xcodeproj
```

Target: iOS 18+, Swift 6 language mode, SwiftUI.

## CI
GitHub Actions runs on macOS, selects the latest stable Xcode, installs XcodeGen, generates `Collapse.xcodeproj`, builds the app for iOS Simulator, then runs `CollapseTests`. A successful run uploads `COLLAPSE-iOS-Simulator` as an Actions artifact. The workflow triggers on pushes and pull requests to `main`, and can also be started manually.
