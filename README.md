# COLLAPSE

COLLAPSE is a one-tap mobile game: the player sees two near-future timelines, taps to switch the selected future, and watches that choice become real when the decision timer closes.

## Core loop
1. Read both visible future paths.
2. Tap once to switch the selected future.
3. The timer commits the choice.
4. The rejected future collapses.
5. Survive the chosen path, collect the safe-path gem, score, and immediately receive the next prediction.

The game never hides the outcome that matters to the current decision. Difficulty comes from shorter decision time and denser future modifiers, not invisible hazards.

## iOS runtime
- `GameEngine`: `@MainActor @Observable` owner for ready, playing, paused, game-over, deterministic rounds, timing, collision, score, run gems, and transient feedback.
- `GameBoardView`: pure SwiftUI `TimelineView(.animation(minimumInterval: 1.0 / 60.0))` + `Canvas` loop.
- `GameRenderSnapshot` + `CollapseCanvasRenderer`: immutable render input and procedural SwiftUI drawing for paths, hazard spikes, gem, portal, player pulse, decision ring, and feedback rings.
- SwiftUI `.thinMaterial` / `.regularMaterial`: Liquid Glass surfaces for the HUD, cards, home, skins, and Plus paywall without UIKit color/view bridges.
- `SensoryEngine`: Core Haptics continuous guidance plus procedural `AVAudioEngine` tones for commit, gem, success, and collision.
- `RunActivityController` + `CollapseWidgets`: ActivityKit Live Activity and Dynamic Island for streak, current score, best score, and local top-run rank.

The default animation schedule uses `minimumInterval: 1.0 / 60.0`. `RenderBudgetMonitor` keeps an 8.3 ms render-work budget so the renderer retains headroom for 120 Hz hardware when a measured need justifies raising cadence; ownership-specific hot-path optimization stays deferred until profiling proves it is needed.

## Meta and economy
- Daily run streak, daily best, lifetime best, local top-three scores, selected skin, gem balance, and gem-unlocked skins persist locally.
- Safe-path gems are cosmetic currency. Aurora and Solar can be unlocked with gems; premium themes stay Plus-only.
- Theme/pulse differences are visual only and never alter hazards, decision timing, scoring, collision, or ranking.

## Plus
COLLAPSE Plus is an auto-renewable weekly/monthly StoreKit 2 subscription. Product IDs are `collapse.plus.weekly` and `collapse.plus.monthly`.

Plus removes ads when the ad layer ships, unlocks Plus-only theme/pulse/sound presentation, and grants early access to future levels/modes. Entitlement truth comes from verified `Transaction.updates` and current entitlements, including expiration and revocation checks. Plus never creates a gameplay advantage.

The free product is intentionally built around the single core mechanic first. Rewarded/interstitial ad provider integration remains outside `GameEngine`; D1/D7 retention should be measured before expanding the mode catalogue or economy depth.

## Size and assets
Gameplay visuals are procedural SwiftUI Canvas shapes and gameplay audio is synthesized at runtime. The App Store icon remains the required static visual asset. The `<25 MB` goal is a release gate measured from the archived app, not inferred from source size.

## Project generation
The repository uses XcodeGen so the Xcode project does not need to be hand-maintained.

```sh
xcodegen generate
open Collapse.xcodeproj
```

Target: iOS 18+, Swift 6 language mode with complete strict concurrency. CI uses the Xcode 27 runner and explicitly verifies the installed Swift 6.4 compiler before build/test.

## CI
GitHub Actions runs two build pipelines:
- `iOS CI` generates `Collapse.xcodeproj`, builds the app + Live Activity extension, runs unit/UI tests, uploads `COLLAPSE-iOS-Simulator-Xcode27`, then builds a Release device app without code signing and packages `COLLAPSE-iOS-Unsigned-IPA`. The unsigned IPA has a strict `<25 MB` CI gate.
- `Android APK` builds both `COLLAPSE-Android-Debug-APK` (`app-debug.apk`, installable for device testing) and `COLLAPSE-Android-Unsigned-APK` (`app-release-unsigned.apk`, unsigned release artifact), with the unsigned release APK held under the same `<25 MB` gate.

Both workflows trigger on pushes and pull requests to `main` and can also be started manually.

Architecture and monetization details live in `docs/index.md`.
