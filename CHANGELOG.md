# Changelog

## [Unreleased]

### Added
- Android foreground background music using the CC0 `duru-arcade-vibe` track from `uncle-sheepsky/duru-cc0-bgm`, with lifecycle pause/resume and lower volume in Power Save Mode.
- Mode-scoped best/today/top-score persistence so CLASSIC/RUSH/PRECISION/DAILY records are no longer mixed together; streak and gem balance remain account-wide.
- Game Center leaderboards on iOS and Play Games Services v2 leaderboards on Android, with per-mode IDs, remote rank display, offline score queue, and retry on reconnect; Zen stays local-only.
- EN/VI/JA/zh-Hans in-app language switching, localized Home/game/tutorial/Plus/skin surfaces, and CI localization key parity checks on both platforms.
- Always-visible tutorial access in the Home action card plus a header `?` shortcut, so How to Play never depends on scrolling to the bottom.
- SwiftUI application shell for COLLAPSE.
- Deterministic two-future one-tap game engine with visible hazard prediction, timed commit, timeline collapse, scoring, and death/restart.
- Three-step first-run tutorial matching the core concept: see futures, tap to switch, commit the choice.
- Weekly/monthly COLLAPSE Plus StoreKit 2 subscription flow with verified purchase, restore, renewal/expiration, and revocation handling.
- Classic plus Nebula, Aurora, Solar, Obsidian, and Frozen Quartz visual skins; Plus skins do not alter gameplay.
- Local best score, daily best/streak, selected skin, gem balance, gem-unlocked skins, and tutorial persistence.
- Unit tests for deterministic rounds, hazard placement, safe scoring, and dangerous-future death.
- GitHub Actions macOS CI that generates the Xcode project, builds the iOS Simulator app, runs unit tests on every push or pull request to `main`, and uploads the successful simulator app as a downloadable artifact.
- Pure SwiftUI `Canvas` rendering driven by `TimelineView(.animation(minimumInterval: 1.0 / 60.0))`, with immutable render snapshots and an 8.3 ms render-work budget target.
- `@MainActor @Observable` `GameEngine` state machine with explicit playing, paused, and game-over states, run gem economy, and transient gem/collision feedback events.
- Core Haptics continuous guidance whose intensity softens and sharpness increases when the selected future is the optimal safe branch.
- Procedural `AVAudioEngine` tones synchronized with guidance, commit, gem, success, and collision haptics without bundled gameplay audio files.
- ActivityKit Live Activity and Dynamic Island presentation for Daily Run streak, current score, best score, and local top-run rank.
- StoreKit 2 product loading and purchase UI for `collapse.plus.weekly` and `collapse.plus.monthly`, with entitlement truth driven by verified `Transaction.updates` and current entitlements.
- Xcode 27 CI preview lane with standard SwiftUI `ViewBuilder` composition for app-root and Plus purchase conditionals.
- Daily Run streak, daily best, local top-three scores, cosmetic gem economy, free gem-unlocked skins, and Plus-only theme/pulse access with focused unit coverage.
- Repeated cold-launch UI smoke test to catch startup crashes in CI before release builds.
- Native Android Jetpack Compose production-parity client matching iOS Home, three-step tutorial, two-future gameplay, Pause/Resume, Game Over, branding, skins, gem economy, Plus presentation, haptic/audio feedback, and navigation semantics.
- Unsigned beta artifacts in CI: `COLLAPSE-iOS-Unsigned-IPA` from an unsigned Release device build and `COLLAPSE-Android-Unsigned-APK` from the Android release variant, both gated below 25 MB; Android also keeps an installable debug APK.
- Android parity unit tests for deterministic rounds, hazard/gem branch placement, safe scoring/gem collection, dangerous-future death, and pause/restart state.
- Cross-platform `CLASSIC`, `RUSH`, `PRECISION`, `DAILY`, and `ZEN` modes using centralized data-driven timing/rule configuration rather than cosmetic-only variants.
- Gated `3 → 2 → 1 → GO` pre-run countdown on start/restart so the first future prediction is readable before gameplay timing begins.
- Procedural centered startup branding on iOS and Android without adding new external image assets.

### Changed
- Android is no longer a reduced test client: iOS is now the shared visual/behavior source of truth for cross-platform screens and gameplay, while platform-only UI such as Dynamic Island remains iOS-only.
- Android now uses the same skin access rules as iOS, persists profile/economy state with SharedPreferences, and provides a vector COLLAPSE launcher icon instead of a generic app icon.
- Android Plus mirrors iOS benefits, locks, and fairness messaging without fabricating Google Play purchases before Billing integration.
- iOS gameplay rendering now uses SwiftUI Canvas/Path primitives and native `.thinMaterial` / `.regularMaterial` glass surfaces; procedural audio remains synthesized at runtime and the app icon is the only required static visual asset.
- CI now builds the app and Live Activity extension on the GitHub Actions Xcode 27 public-preview runner and uploads `COLLAPSE-iOS-Simulator-Xcode27`.

### Fixed
- Android Home no longer vertically centers an oversized scroll column into the status bar; Home, Skin, Plus, and Gameplay HUD now respect status/navigation insets while keeping decorative backgrounds edge-to-edge.
- Android Pause control now uses a centered custom two-bar glyph inside a fixed 48dp circular hit target; iOS Pause uses a centered custom glass circle instead of system bordered-button padding.
- Startup branding now stays centered independently of Home/Tutorial layout, avoiding offset/cropped logo composition on compact portrait devices.
- Android tutorial header now keeps Skip/Close in the same responsive safe-area row as a compact brand mark, and board/card/CTA sizing adapts on compact-height portrait devices instead of overlapping or clipping.
- Android edge-to-edge system bars now explicitly use light status/navigation icons on the dark COLLAPSE visual language.
- Android Pause/Game Over now freeze the render clock, hide the gameplay HUD, block canvas input, suppress transient feedback bleed-through, and dim the frozen board so overlay actions are the only visual/interactive foreground.
- Android Plus now uses Google Play Billing Library 9.1.0 with real weekly/monthly ProductDetails pricing, purchase flow, purchase reconciliation/acknowledgement and restore checks; sideload builds show unavailable state instead of fake BETA prices or entitlements.
- Tutorial replay now reuses the full three-step procedural gameplay tutorial instead of opening a black text-only pager, with balanced portrait layout and explicit close/next/finish actions.
- Home, tutorial, Plus, pause, and game-over surfaces now share a procedural COLLAPSE brand mark so the app has a visible identity without adding external image assets.
- Gameplay now exposes a persistent 44-point Pause control; paused runs provide Resume, Restart, and Home, while game-over provides Restart and Home instead of a dead-end overlay.
- Live Activity ownership now follows gameplay visibility: inactive/background/disappearing gameplay ends Dynamic Island immediately, stale activities are cleared on next launch, and start/restart/resume paths avoid duplicate activities.
- CI test-host resolution now uses the same `Collapse.app/Collapse` product name expected by the generated unit-test target.
- Xcode 27 ActivityKit updates no longer send a main-actor-isolated `Activity` reference into `@concurrent` APIs; the controller keeps only the activity ID and resolves each activity inside a nonisolated helper.
- Android debug builds now enable AndroidX explicitly so Compose dependencies pass AAR metadata validation.
