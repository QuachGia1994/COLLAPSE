# Changelog

## [Unreleased]

### Added
- SwiftUI application shell for COLLAPSE.
- Deterministic two-future one-tap game engine with visible hazard prediction, timed commit, timeline collapse, scoring, and death/restart.
- Three-step first-run tutorial matching the core concept: see futures, tap to switch, commit the choice.
- Lifetime COLLAPSE Plus StoreKit 2 entitlement flow with restore support and no fake purchase fallback.
- Classic plus Nebula, Aurora, Solar, Obsidian, and Frozen Quartz visual skins; Plus skins do not alter gameplay.
- Local best score, selected skin, and tutorial persistence.
- Unit tests for deterministic rounds, hazard placement, safe scoring, and dangerous-future death.
- GitHub Actions macOS CI that generates the Xcode project, builds the iOS Simulator app, runs unit tests on every push or pull request to `main`, and uploads the successful simulator app as a downloadable artifact.
- SpriteKit rendering hosted by SwiftUI `SpriteView`, with a 120 FPS target on supported ProMotion displays and a frame-budget monitor for the 8.3 ms target.
- `@Observable` `GameEngine` state machine with explicit playing, paused, and game-over states, separated from the SwiftUI HUD and SpriteKit scene.
- Core Haptics continuous guidance whose intensity softens and sharpness increases when the selected future is the optimal safe branch.
- Procedural `AVAudioEngine` tones synchronized with guidance, commit, success, and failure haptics without bundled gameplay audio files.
- ActivityKit Live Activity and Dynamic Island presentation for Daily Run streak, current score, best score, and local top-run rank.
- StoreKit 2 `ProductView` merchandising while verified entitlement state remains driven by `Transaction.updates` and current entitlements.
- Xcode 27 CI preview lane and SwiftUI `ContentBuilder` adoption for the app root and Plus purchase section.
- Daily Run streak and local top-three score persistence with focused unit coverage.
- Repeated cold-launch UI smoke test to catch startup crashes in CI before release builds.
- Native Android Jetpack Compose test client preserving the visible-two-futures, one-tap core loop, plus GitHub Actions debug APK output for device testing.

### Changed
- Gameplay rendering now uses only SpriteKit/Core Graphics primitives and procedural audio; the app icon is the only required static visual asset.
- CI now builds the app and Live Activity extension on the GitHub Actions Xcode 27 public-preview runner and uploads `COLLAPSE-iOS-Simulator-Xcode27`.

### Fixed
- CI test-host resolution now uses the same `Collapse.app/Collapse` product name expected by the generated unit-test target.
- Xcode 27 ActivityKit updates no longer send a main-actor-isolated `Activity` reference into `@concurrent` APIs; the controller keeps only the activity ID and resolves each activity inside a nonisolated helper.
