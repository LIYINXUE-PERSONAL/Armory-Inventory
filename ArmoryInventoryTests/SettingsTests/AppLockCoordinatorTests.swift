//
//  AppLockCoordinatorTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 10/21/26.
//

import XCTest
@testable import ArmoryInventory

@MainActor
final class AppLockCoordinatorTests: XCTestCase {
    func testInitialStateReflectsPersistedSetting() {
        let disabledStore = TestAppLockSettingsStore(isEnabled: false)
        let enabledStore = TestAppLockSettingsStore(isEnabled: true)

        let disabled = AppLockCoordinator(
            settingsStore: disabledStore,
            authenticator: TestAppLockAuthenticator()
        )
        let enabled = AppLockCoordinator(
            settingsStore: enabledStore,
            authenticator: TestAppLockAuthenticator()
        )

        XCTAssertEqual(disabled.state, .disabled)
        XCTAssertTrue(disabled.canRevealProtectedContent)
        XCTAssertEqual(enabled.state, .locked)
        XCTAssertFalse(enabled.canRevealProtectedContent)
    }

    func testFirstActiveTransitionAuthenticatesOnlyOncePerForeground() async {
        let authenticator = TestAppLockAuthenticator(results: [.success(())])
        let coordinator = AppLockCoordinator(
            settingsStore: TestAppLockSettingsStore(isEnabled: true),
            authenticator: authenticator
        )

        coordinator.appDidBecomeActive()
        await allowAuthenticationTaskToComplete(for: coordinator)

        XCTAssertEqual(coordinator.state, .unlocked)
        XCTAssertEqual(authenticator.authenticateCallCount, 1)

        coordinator.appDidBecomeActive()
        await allowAuthenticationTaskToComplete(for: coordinator)

        XCTAssertEqual(authenticator.authenticateCallCount, 1)
    }

    func testCancellationRemainsLockedAndDoesNotAutomaticallyReprompt() async {
        let authenticator = TestAppLockAuthenticator(results: [.failure(.userCancelled)])
        let coordinator = AppLockCoordinator(
            settingsStore: TestAppLockSettingsStore(isEnabled: true),
            authenticator: authenticator
        )

        coordinator.appDidBecomeActive()
        await allowAuthenticationTaskToComplete(for: coordinator)

        XCTAssertEqual(coordinator.state, .unavailable(.userCancelled))
        XCTAssertFalse(coordinator.canRevealProtectedContent)

        coordinator.appDidBecomeActive()
        await allowAuthenticationTaskToComplete(for: coordinator)

        XCTAssertEqual(authenticator.authenticateCallCount, 1)
    }

    func testBackgroundCancelsAuthenticationAndIgnoresItsStaleCompletion() async {
        let authenticator = TestAppLockAuthenticator()
        let coordinator = AppLockCoordinator(
            settingsStore: TestAppLockSettingsStore(isEnabled: true),
            authenticator: authenticator
        )

        coordinator.appDidBecomeActive()
        await Task.yield()
        XCTAssertEqual(coordinator.state, .authenticating)

        coordinator.appDidEnterBackground()
        await allowAuthenticationTaskToComplete(for: coordinator)

        XCTAssertEqual(authenticator.cancelCallCount, 1)
        XCTAssertEqual(coordinator.state, .locked)
        XCTAssertFalse(coordinator.canRevealProtectedContent)
    }

    func testReturningAfterBackgroundRequiresAnotherAuthentication() async {
        let authenticator = TestAppLockAuthenticator(results: [.success(()), .success(())])
        let coordinator = AppLockCoordinator(
            settingsStore: TestAppLockSettingsStore(isEnabled: true),
            authenticator: authenticator
        )

        coordinator.appDidBecomeActive()
        await allowAuthenticationTaskToComplete(for: coordinator)
        coordinator.appDidEnterBackground()
        coordinator.appDidBecomeActive()
        await allowAuthenticationTaskToComplete(for: coordinator)

        XCTAssertEqual(coordinator.state, .unlocked)
        XCTAssertEqual(authenticator.authenticateCallCount, 2)
    }

    func testUnavailableAuthenticationFailsClosedWithoutPresentingPrompt() {
        let authenticator = TestAppLockAuthenticator(
            capability: AppLockAuthenticationCapability(
                isAvailable: false,
                method: .devicePasscode,
                failure: .passcodeNotSet
            )
        )
        let coordinator = AppLockCoordinator(
            settingsStore: TestAppLockSettingsStore(isEnabled: true),
            authenticator: authenticator
        )

        coordinator.appDidBecomeActive()

        XCTAssertEqual(coordinator.state, .unavailable(.passcodeNotSet))
        XCTAssertEqual(authenticator.authenticateCallCount, 0)
        XCTAssertFalse(coordinator.canRevealProtectedContent)
    }

    func testEnablingPersistsOnlyAfterSuccessfulAuthentication() async {
        let store = TestAppLockSettingsStore(isEnabled: false)
        let authenticator = TestAppLockAuthenticator(results: [.success(())])
        let coordinator = AppLockCoordinator(settingsStore: store, authenticator: authenticator)

        let result = await coordinator.setAppLockEnabled(true)

        XCTAssertEqual(result, .success)
        XCTAssertTrue(store.isEnabled)
        XCTAssertEqual(coordinator.state, .unlocked)
    }

    func testFailedEnableLeavesSettingDisabled() async {
        let store = TestAppLockSettingsStore(isEnabled: false)
        let authenticator = TestAppLockAuthenticator(results: [.failure(.authenticationFailed)])
        let coordinator = AppLockCoordinator(settingsStore: store, authenticator: authenticator)

        let result = await coordinator.setAppLockEnabled(true)

        XCTAssertEqual(result, .failure(.authenticationFailed))
        XCTAssertFalse(store.isEnabled)
        XCTAssertEqual(coordinator.state, .disabled)
    }

    func testDisablingRequiresSuccessfulAuthentication() async {
        let store = TestAppLockSettingsStore(isEnabled: true)
        let authenticator = TestAppLockAuthenticator(
            results: [.failure(.userCancelled), .success(())]
        )
        let coordinator = AppLockCoordinator(settingsStore: store, authenticator: authenticator)

        let failedResult = await coordinator.setAppLockEnabled(false)
        XCTAssertEqual(failedResult, .failure(.userCancelled))
        XCTAssertTrue(store.isEnabled)

        let successfulResult = await coordinator.setAppLockEnabled(false)
        XCTAssertEqual(successfulResult, .success)
        XCTAssertFalse(store.isEnabled)
        XCTAssertEqual(coordinator.state, .disabled)
    }

    func testPrivacyShieldRevealsImmediatelyAfterSuccessfulAuthentication() {
        var state = PrivacyShieldVisibilityState()
        state.update(
            isProtectionEnabled: true,
            isAuthenticating: true,
            canRevealProtectedContent: false,
            isSceneActive: false
        )
        XCTAssertTrue(state.shouldShowShield)

        state.update(
            isProtectionEnabled: true,
            isAuthenticating: false,
            canRevealProtectedContent: true,
            isSceneActive: false
        )

        XCTAssertFalse(state.shouldShowShield)
    }

    func testPrivacyShieldRemainsAfterFailedAuthentication() {
        var state = PrivacyShieldVisibilityState()
        state.update(
            isProtectionEnabled: true,
            isAuthenticating: true,
            canRevealProtectedContent: false,
            isSceneActive: false
        )
        state.update(
            isProtectionEnabled: true,
            isAuthenticating: false,
            canRevealProtectedContent: false,
            isSceneActive: false
        )

        XCTAssertTrue(state.shouldShowShield)
    }

    func testPrivacyShieldReturnsOnLaterDeactivation() {
        var state = PrivacyShieldVisibilityState()
        state.update(
            isProtectionEnabled: true,
            isAuthenticating: true,
            canRevealProtectedContent: false,
            isSceneActive: false
        )
        state.update(
            isProtectionEnabled: true,
            isAuthenticating: false,
            canRevealProtectedContent: true,
            isSceneActive: false
        )
        state.sceneDidActivate()
        state.sceneWillDeactivate()

        XCTAssertTrue(state.shouldShowShield)
    }

    private func allowAuthenticationTaskToComplete(for coordinator: AppLockCoordinator) async {
        for _ in 0..<20 where coordinator.state == .authenticating {
            await Task.yield()
        }
    }
}

private final class TestAppLockSettingsStore: AppLockSettingsStoring {
    var isEnabled: Bool

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }
}

@MainActor
private final class TestAppLockAuthenticator: AppLockAuthenticating {
    var capabilityValue: AppLockAuthenticationCapability
    var results: [Result<Void, AppLockAuthenticationFailure>]
    private(set) var authenticateCallCount = 0
    private(set) var cancelCallCount = 0
    private var continuation: CheckedContinuation<Result<Void, AppLockAuthenticationFailure>, Never>?

    init(
        capability: AppLockAuthenticationCapability = AppLockAuthenticationCapability(
            isAvailable: true,
            method: .faceID,
            failure: nil
        ),
        results: [Result<Void, AppLockAuthenticationFailure>] = []
    ) {
        capabilityValue = capability
        self.results = results
    }

    func capability() -> AppLockAuthenticationCapability {
        capabilityValue
    }

    func authenticate(reason: String) async -> Result<Void, AppLockAuthenticationFailure> {
        authenticateCallCount += 1
        if !results.isEmpty {
            return results.removeFirst()
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func cancel() {
        cancelCallCount += 1
        continuation?.resume(returning: .failure(.interrupted))
        continuation = nil
    }
}
