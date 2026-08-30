# iOS runtime

> updated 2026-08-30 · 6cfbf38

Product direction and monetization boundaries: `../biz/product.md`.

## Rendering
- iOS gameplay is pure SwiftUI: `TimelineView(.animation(minimumInterval: 1.0 / 60.0))` supplies frame dates and `Canvas` draws the procedural scene.
- `GameBoardView` snapshots `GameEngine` state on `@MainActor` into immutable `GameRenderSnapshot`; `CollapseCanvasRenderer` consumes the snapshot without reaching across actor isolation.
- The renderer draws future paths, hazard spikes, gem, portal, player pulse, decision ring, and short scale/opacity-style feedback rings. No SpriteKit, UIKit renderer, or Metal layer is required.
- Glass surfaces use SwiftUI `.thinMaterial` and `.regularMaterial`; background and gameplay colors come from `GameSkin` palettes.
- The default animation schedule uses a 1/60 minimum interval, while the render-work budget stays at 8.3 ms to preserve 120 Hz headroom when measured hardware/gameplay needs justify raising cadence. Optimization beyond this baseline is deferred until profiling proves a hot path.

## State and domain
- `GameEngine` is the `@MainActor @Observable` reference-semantic owner for run state, deterministic rounds, timers, score, run gems, collision, and transient feedback events.
- `RoundLayout`, `FuturePath`, `Hazard`, `Gem`, `RunEconomy`, and render snapshots are value types and `Sendable` where they cross isolation boundaries.
- A safe-path gem is presentation-economy reward only. It cannot alter score, hazard placement, decision time, or collision rules.

## Persistence and feedback
- `PlayerProfile` owns UserDefaults-backed tutorial, best score, daily best/streak, top scores, gem balance, unlocked skins, and selected skin state.
- Run completion records score and gems through an async API; persistence remains behind the profile boundary rather than inside rendering or StoreKit code.
- `SensoryEngine` owns Core Haptics and procedural AVAudio feedback for guidance, commit, gem, success, and collision. `GameEngine` depends only on `SensoryClient` closures.

## Plus and external services
- `EntitlementStore` owns StoreKit 2 product loading, purchase, restore, `Transaction.updates`, current entitlements, expiration, revocation, and verified transaction handling for weekly/monthly Plus.
- Plus affects presentation/access only. When Plus expires, a selected Plus-only skin falls back to Classic without deleting the saved preference.
- `RunActivityController` remains the ActivityKit boundary for Live Activity/Dynamic Island state and stores only the activity ID across MainActor state.
