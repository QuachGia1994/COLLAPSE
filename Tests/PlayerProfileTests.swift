import XCTest
@testable import Collapse

@MainActor
final class PlayerProfileTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "collapse.tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }

    func testAudioSettingsDefaultEnabled() {
        let profile = PlayerProfile(defaults: makeDefaults())
        XCTAssertTrue(profile.musicEnabled)
        XCTAssertTrue(profile.soundEnabled)
        XCTAssertTrue(profile.hapticsEnabled)
    }

    func testAudioSettingsPersistAcrossReload() {
        let defaults = makeDefaults()
        let profile = PlayerProfile(defaults: defaults)
        profile.musicEnabled = false
        profile.hapticsEnabled = false

        let reloaded = PlayerProfile(defaults: defaults)
        XCTAssertFalse(reloaded.musicEnabled)
        XCTAssertTrue(reloaded.soundEnabled)
        XCTAssertFalse(reloaded.hapticsEnabled)
    }
}
