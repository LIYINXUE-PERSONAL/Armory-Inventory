//
//  AppLockCoordinator.swift
//  Armory Inventory
//
//  Created by Codex on 10/21/26.
//

import Combine
import Foundation

enum AppLockState: Equatable {
    case disabled
    case locked
    case authenticating
    case unlocked
    case unavailable(AppLockAuthenticationFailure)
}

enum AppLockSettingChangeResult: Equatable {
    case success
    case failure(AppLockAuthenticationFailure)
}

protocol AppLockSettingsStoring: AnyObject {
    var isEnabled: Bool { get set }
}

final class UserDefaultsAppLockSettingsStore: AppLockSettingsStoring {
    static let enabledKey = "AppLockEnabled"

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    var isEnabled: Bool {
        get { userDefaults.bool(forKey: Self.enabledKey) }
        set { userDefaults.set(newValue, forKey: Self.enabledKey) }
    }
}

@MainActor
final class AppLockCoordinator: ObservableObject {
    @Published private(set) var state: AppLockState
    @Published private(set) var capability: AppLockAuthenticationCapability
    @Published private(set) var isChangingSetting = false

    private let settingsStore: AppLockSettingsStoring
    private let authenticator: AppLockAuthenticating
    private var authenticationTask: Task<Void, Never>?
    private var authenticationGeneration = 0
    private var hasAttemptedUnlockThisForeground = false

    convenience init() {
        self.init(
            settingsStore: UserDefaultsAppLockSettingsStore(),
            authenticator: LocalAuthenticationService()
        )
    }

    init(
        settingsStore: AppLockSettingsStoring,
        authenticator: AppLockAuthenticating
    ) {
        self.settingsStore = settingsStore
        self.authenticator = authenticator
        capability = authenticator.capability()
        state = settingsStore.isEnabled ? .locked : .disabled
    }

    var isEnabled: Bool {
        settingsStore.isEnabled
    }

    var canRevealProtectedContent: Bool {
        state == .disabled || state == .unlocked
    }

    func refreshCapability() {
        capability = authenticator.capability()
    }

    func appDidBecomeActive() {
        refreshCapability()
        guard isEnabled,
              !hasAttemptedUnlockThisForeground else {
            return
        }

        hasAttemptedUnlockThisForeground = true
        requestUnlock()
    }

    func appDidEnterBackground() {
        authenticationGeneration += 1
        authenticationTask?.cancel()
        authenticationTask = nil
        authenticator.cancel()
        isChangingSetting = false
        hasAttemptedUnlockThisForeground = false

        state = isEnabled ? .locked : .disabled
    }

    func requestUnlock() {
        guard isEnabled,
              state != .authenticating,
              !isChangingSetting else {
            return
        }

        refreshCapability()
        guard capability.isAvailable else {
            state = .unavailable(capability.failure ?? .unexpected)
            return
        }

        authenticationGeneration += 1
        let generation = authenticationGeneration
        state = .authenticating

        authenticationTask = Task { [weak self] in
            guard let self else { return }
            let result = await authenticator.authenticate(
                reason: String(localized: "Unlock Armory Inventory to access your inventory.")
            )
            guard generation == authenticationGeneration,
                  isEnabled else {
                return
            }

            authenticationTask = nil
            switch result {
            case .success:
                state = .unlocked
            case let .failure(failure):
                state = .unavailable(failure)
            }
        }
    }

    func setAppLockEnabled(_ enabled: Bool) async -> AppLockSettingChangeResult {
        guard enabled != isEnabled,
              !isChangingSetting,
              state != .authenticating else {
            return .success
        }

        refreshCapability()
        guard capability.isAvailable else {
            return .failure(capability.failure ?? .unexpected)
        }

        isChangingSetting = true
        authenticationGeneration += 1
        let generation = authenticationGeneration
        let result = await authenticator.authenticate(
            reason: enabled
                ? String(localized: "Authenticate to turn on App Lock.")
                : String(localized: "Authenticate to turn off App Lock.")
        )

        guard generation == authenticationGeneration else {
            return .failure(.interrupted)
        }

        isChangingSetting = false
        switch result {
        case .success:
            settingsStore.isEnabled = enabled
            hasAttemptedUnlockThisForeground = enabled
            state = enabled ? .unlocked : .disabled
            return .success
        case let .failure(failure):
            state = isEnabled ? .unlocked : .disabled
            return .failure(failure)
        }
    }
}
