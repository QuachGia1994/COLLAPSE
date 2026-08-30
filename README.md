# COLLAPSE

COLLAPSE is a one-tap mobile game: the player sees two near-future timelines, taps to switch the selected future, and watches that choice become real when the decision timer closes.

## Core loop
1. Read both visible future paths.
2. Tap once to switch the selected future.
3. The timer commits the choice.
4. The rejected future collapses.
5. Survive the chosen path, collect the safe-path gem, score, and immediately receive the next prediction.

The game never hides the outcome that matters to the current decision. Every run now starts with a gated `3 → 2 → 1 → GO` countdown so the first prediction is readable before timing begins.

## Modes
- `CLASSIC` — balanced original timing.
- `RUSH` — shorter decision window and faster travel from round one.
- `PRECISION` — one branch switch per round plus larger hazard pressure.
- `DAILY` — deterministic local-calendar-day seed with a fixed daily timeline.
- `ZEN` — slower practice mode; collisions advance to another round instead of ending the run and the mode is excluded from competitive score persistence/Live Activity.

Mode rules are centralized in `GameMode` on both platforms; they do not fork the core two-future mechanic.

## Progression, stats, language, and leaderboards
- Best score, daily best, and local top-three scores are stored separately for CLASSIC/RUSH/PRECISION/DAILY. Streak and gem balance are intentionally account-wide; Zen is practice-only and excluded from competitive persistence.
- iOS uses Game Center leaderboards `collapse.classic.best`, `collapse.rush.best`, `collapse.precision.best`, and `collapse.daily.best`. Android uses Play Games leaderboard IDs supplied through Gradle properties. Both queue the highest unsent score per mode and retry after authentication/reconnect.
- Home exposes an always-visible language control for EN/VI/JA/zh-Hans and a header `?` shortcut plus in-card How to Play action. CI rejects missing locale keys or Unicode replacement characters.

## iOS runtime
- `GameEngine`: `@MainActor @Observable` owner for startup countdown, ready/playing/paused/game-over state, selected `GameMode`, deterministic rounds, timing, collision, score, run gems, and transient feedback.
- `GameBoardView`: pure SwiftUI `TimelineView(.animation(minimumInterval: 1.0 / 60.0))` + `Canvas` loop.
- `GameRenderSnapshot` + `CollapseCanvasRenderer`: immutable render input and procedural SwiftUI drawing for paths, hazard spikes, gem, portal, player pulse, decision ring, and feedback rings.
- SwiftUI `.thinMaterial` / `.regularMaterial`: Liquid Glass surfaces for the HUD, cards, home, skins, and Plus paywall without UIKit color/view bridges.
- `SensoryEngine`: Core Haptics continuous guidance plus procedural `AVAudioEngine` tones for commit, gem, success, and collision.
- `RunActivityController` + `CollapseWidgets`: ActivityKit Live Activity and Dynamic Island for streak, current score, best score, and local top-run rank; gameplay owns exactly one activity and dismisses it immediately when the game leaves the foreground.

The default animation schedule uses `minimumInterval: 1.0 / 60.0`. `RenderBudgetMonitor` keeps an 8.3 ms render-work budget so the renderer retains headroom for 120 Hz hardware when a measured need justifies raising cadence; ownership-specific hot-path optimization stays deferred until profiling proves it is needed.

## Android runtime
- Android is no longer a reduced test client. The current iOS flow is the shared visual/behavior source of truth for Home, tutorial, gameplay, Pause/Resume, Game Over, branding, skins, gem economy, Plus presentation, timing, and navigation.
- `GameController` ports the same startup countdown, `GameMode` configuration, deterministic SplitMix64 round generation, choice/travel timing, hazard branch, safe-path gem, score, pause/restart, and game-over state.
- Jetpack Compose `Canvas` renders both future paths, ghost positions, hazard, gem, portal, player, decision ring, and feedback ring; there is no second legacy Android renderer.
- SharedPreferences persist tutorial completion, daily/lifetime score, streak, gems, selected skin, and gem unlocks. Android `Vibrator` + procedural `ToneGenerator` provide branch, commit, gem, success, and collision feedback.
- Dynamic Island/ActivityKit stays iOS-only. Android does not imitate platform-specific UI.

## Meta and economy
- Daily run streak, daily best, lifetime best, local top-three scores, selected skin, gem balance, and gem-unlocked skins persist locally.
- Safe-path gems are cosmetic currency. Aurora and Solar can be unlocked with gems; premium themes stay Plus-only.
- Theme/pulse differences are visual only and never alter hazards, decision timing, scoring, collision, or ranking.

## Plus
COLLAPSE Plus is an auto-renewable weekly/monthly subscription. Product IDs are `collapse.plus.weekly` and `collapse.plus.monthly` on both platforms. iOS entitlement truth comes from verified StoreKit 2 `Transaction.updates` and current entitlements. Android uses Google Play Billing Library 9.1.0 to load real localized subscription pricing/offers, launch Play checkout, reconcile/acknowledge purchases, restore via purchase query, and drive Plus-only presentation. Sideload APKs never fabricate prices or entitlements; purchase testing requires configured Play Console products and a Play test track.

Plus removes ads when the ad layer ships, unlocks Plus-only theme/pulse/sound presentation, and grants early access to future levels/modes. Plus never creates a gameplay advantage.

The free product is intentionally built around the single core mechanic first. Rewarded/interstitial ad provider integration remains outside `GameEngine`; D1/D7 retention should be measured before expanding the mode catalogue or economy depth.

## Size and assets
Gameplay visuals are procedural on both platforms: SwiftUI Canvas on iOS and Compose Canvas on Android. Gameplay audio/feedback is synthesized at runtime. iOS keeps its App Store icon asset; Android uses a vector COLLAPSE launcher mark. The `<25 MB` goal is enforced on unsigned iOS IPA and Android release APK artifacts.

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
- `Android APK` runs focused gameplay parity unit tests, then builds both `COLLAPSE-Android-Debug-APK` (`app-debug.apk`, installable for device testing) and `COLLAPSE-Android-Unsigned-APK` (`app-release-unsigned.apk`, unsigned release artifact), with the unsigned release APK held under the same `<25 MB` gate.

Both workflows trigger on pushes and pull requests to `main` and can also be started manually.

Architecture and monetization details live in `docs/index.md`.
