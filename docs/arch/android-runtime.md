# Android runtime

> updated 2026-08-30 · 66993a0

Product direction and monetization boundaries: `../biz/product.md`.

## Parity contract
- iOS is the behavior and visual source of truth for the shared COLLAPSE experience: three-step tutorial, Home hierarchy, two-future gameplay, Pause/Resume, Game Over, skins, gem economy, Plus messaging, brand mark, colors, timing, hazard/gem placement, and navigation semantics.
- Android uses Jetpack Compose Canvas and Material surfaces to reproduce that contract without maintaining a second gameplay concept.
- Platform-only features stay native: ActivityKit/Dynamic Island is iOS-only and is not imitated on Android.

## Gameplay and rendering
- `GameController` owns ready/playing/paused/game-over state and uses the same score-dependent choice/travel timing as iOS.
- `RoundGenerator` ports the same SplitMix64 seed flow, quadratic future paths, hazard progress, safe-path gem progress, and branch rules as the Swift model.
- `GameScreen` draws both predicted paths, ghost positions, hazard, gem, portal, player, decision ring, and feedback ring through Compose `Canvas`.
- One tap changes the selected future only during the decision phase. Pause, Game Over, restart, and Home are explicit overlays instead of implicit canvas behavior.

## Meta and persistence
- `PlayerProfile` persists first-run tutorial completion, lifetime/daily best, daily streak, gem balance, selected skin, and gem-unlocked skins with SharedPreferences.
- Skin access mirrors iOS: Classic free, Aurora 25 gems, Solar 60 gems, Nebula/Obsidian/Frozen Quartz Plus-only.
- Plus remains cosmetic/access-only. Google Play Billing is intentionally not faked in the beta parity stage; the Plus screen exposes the same benefits and fairness contract while billing actions remain unavailable until a real Billing integration stage.

## Feedback and CI
- `SensoryEngine` maps branch precision, commit, gem, success, and collision to Android `Vibrator` and procedural `ToneGenerator` feedback without bundled audio assets.
- Android CI runs focused JVM gameplay tests before building the installable debug APK and unsigned release APK. The unsigned release remains gated below 25 MB.
