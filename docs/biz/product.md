# Product and monetization

> updated 2026-08-30 · 6cfbf38

COLLAPSE is for mobile players who want a fast one-thumb reflex game with a visible decision instead of hidden random failure. The falsifiable product promise is: every critical choice shows both immediate futures before the timer commits one, so failure comes from the player's decision rather than an unseen obstacle.

## Free product
- Launch around one core mechanic first: read two futures, tap to switch, commit, survive, repeat.
- Keep score, daily streak, gems, free unlockable skins, and the full competitive gameplay loop available without Plus.
- The free monetization path is rewarded + interstitial ads. No ad SDK is selected in the current pre-release build; provider integration stays at the edge and must not enter `GameEngine`.
- Measure D1/D7 retention before expanding the mode set or economy depth.

## Economy
- Gems are earned during normal safe-path play and are presentation currency only.
- Gem unlocks may change skin/theme/pulse presentation but never hazard placement, choice time, scoring, collision rules, or rank.
- Economy rules live in typed domain/profile state rather than paywall views so monetization cannot silently fork gameplay rules.

## COLLAPSE Plus
- Plus is an auto-renewable weekly/monthly subscription, not a lifetime purchase.
- Product IDs: `collapse.plus.weekly` and `collapse.plus.monthly`.
- Benefits: remove ads, unlock Plus-only themes/pulses/sound presentation, and receive early access to future levels/modes.
- Plus never changes survival odds, score calculation, decision timing, hazard layout, or ranking.
- Purchase, restore, renewal, expiration, and revocation truth comes from verified StoreKit 2 transactions.

## Validation gate
Before adding deeper economy, more subscriptions, or a large mode catalogue, use D1/D7 retention and free-to-Plus conversion from the shipped core loop. If retention is weak, improve the one-tap loop and presentation before adding monetization complexity.
