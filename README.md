# COLLAPSE

COLLAPSE is a one-tap iOS game: the player sees two near-future timelines, taps to switch the selected future, and watches that choice become real when the decision timer closes.

## Core loop
1. Read both visible future paths.
2. Tap once to switch the selected future.
3. The timer commits the choice.
4. The rejected future collapses.
5. Survive the chosen path to score and immediately receive the next prediction.

The game never hides the outcome that matters to the current decision. Difficulty comes from shorter decision time and denser future modifiers, not invisible hazards.

## Runtime architecture
- `GameEngine`: `@MainActor @Observable` state owner for ready, playing, paused, game-over, deterministic rounds, timing, collision, and score.
- `CollapseScene`: SpriteKit renderer hosted by SwiftUI `SpriteView`; it reads `GameEngine`, draws only `SKShapeNode`/Core Graphics primitives, and sends the one-tap input back to the engine.
- SwiftUI HUD: score, Daily Run streak, pause/restart, tutorial, skins, and Plus UI stay outside the SpriteKit scene.
- `SensoryEngine`: Core Haptics continuous guidance plus procedural `AVAudioEngine`; no bundled gameplay sound files.
- `RunActivityController` + `CollapseWidgets`: ActivityKit Live Activity and Dynamic Island for streak, current score, best score, and a local top-run rank.

The renderer requests 120 FPS on supported displays. `RenderBudgetMonitor` records the 8.3 ms frame-budget target, but the target is not considered proven until measured on 120 Hz hardware.

## Plus
COLLAPSE Plus is a lifetime purchase. It unlocks premium skins and presentation features only; it never changes hazard placement, decision timing, score, survival, or ranking fairness.

StoreKit product ID: `collapse.plus.lifetime`. The Plus screen uses StoreKit 2 `ProductView`; entitlement truth comes from verified `Transaction.updates` and current entitlements.

## Size and assets
Gameplay visuals are procedural SpriteKit/Core Graphics primitives and gameplay audio is synthesized at runtime. The App Store icon remains the required static visual asset. The `<25 MB` goal is a release gate measured from the archived app, not inferred from source size.

## Project generation
The repository uses XcodeGen so the Xcode project does not need to be hand-maintained.

```sh
xcodegen generate
open Collapse.xcodeproj
```

Target: iOS 18+, Swift 6 language mode with complete strict concurrency. Xcode 27 builds use SwiftUI `ContentBuilder`; standard SwiftUI controls/materials are left native so current platform design, including Liquid Glass where the OS applies it, is not reimplemented manually.

## CI
GitHub Actions uses the `xcode-27` public-preview runner, installs XcodeGen, generates `Collapse.xcodeproj`, builds the app plus Live Activity extension for iOS Simulator, and runs `CollapseTests`. A successful run uploads `COLLAPSE-iOS-Simulator-Xcode27`. The workflow triggers on pushes and pull requests to `main` and can also be started manually.
