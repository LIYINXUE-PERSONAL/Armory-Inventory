//
//  AppLockAuthentication.swift
//  Armory Inventory
//
//  Created by Codex on 10/21/26.
//

import Foundation
import LocalAuthentication

enum AppLockAuthenticationMethod: Equatable {
    case faceID
    case touchID
    case devicePasscode

    var displayName: String {
        switch self {
        case .faceID:
            return String(localized: "Face ID or Device Passcode")
        case .touchID:
            return String(localized: "Touch ID or Device Passcode")
        case .devicePasscode:
            return String(localized: "Device Passcode")
        }
    }
}

enum AppLockAuthenticationFailure: Error, Equatable {
    case authenticationFailed
    case userCancelled
    case interrupted
    case passcodeNotSet
    case biometryUnavailable
    case biometryNotEnrolled
    case biometryLockedOut
    case interactionUnavailable
    case unexpected

    var recoveryMessage: String {
        switch self {
        case .authenticationFailed:
            return String(localized: "Authentication was unsuccessful. Try again.")
        case .userCancelled:
            return String(localized: "Authentication was cancelled. Your inventory remains locked.")
        case .interrupted:
            return String(localized: "Authentication was interrupted. Try again when the app is active.")
        case .passcodeNotSet:
            return String(localized: "Set a device passcode in Settings before using App Lock.")
        case .biometryUnavailable:
            return String(localized: "System authentication is unavailable. Check your device settings and try again.")
        case .biometryNotEnrolled:
            return String(localized: "Set up Face ID or Touch ID, or use a device passcode, then try again.")
        case .biometryLockedOut:
            return String(localized: "Biometric authentication is locked. Unlock your device with its passcode, then try again.")
        case .interactionUnavailable:
            return String(localized: "Authentication cannot be shown right now. Return to the app and try again.")
        case .unexpected:
            return String(localized: "Authentication is unavailable right now. Try again.")
        }
    }
}

struct AppLockAuthenticationCapability: Equatable {
    let isAvailable: Bool
    let method: AppLockAuthenticationMethod
    let failure: AppLockAuthenticationFailure?
}

@MainActor
protocol AppLockAuthenticating: AnyObject {
    func capability() -> AppLockAuthenticationCapability
    func authenticate(reason: String) async -> Result<Void, AppLockAuthenticationFailure>
    func cancel()
}

@MainActor
final class LocalAuthenticationService: AppLockAuthenticating {
    private var activeContext: LAContext?

    func capability() -> AppLockAuthenticationCapability {
        let context = LAContext()
        var error: NSError?
        let isAvailable = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

        return AppLockAuthenticationCapability(
            isAvailable: isAvailable,
            method: authenticationMethod(for: context.biometryType),
            failure: isAvailable ? nil : map(error: error)
        )
    }

    func authenticate(reason: String) async -> Result<Void, AppLockAuthenticationFailure> {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Cancel")
        context.touchIDAuthenticationAllowableReuseDuration = 0

        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(map(error: error))
        }

        activeContext?.invalidate()
        activeContext = context

        do {
            try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            if activeContext === context {
                activeContext = nil
            }
            return .success(())
        } catch {
            if activeContext === context {
                activeContext = nil
            }
            return .failure(map(error: error as NSError))
        }
    }

    func cancel() {
        activeContext?.invalidate()
        activeContext = nil
    }

    private func authenticationMethod(for biometryType: LABiometryType) -> AppLockAuthenticationMethod {
        switch biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .none, .opticID:
            return .devicePasscode
        @unknown default:
            return .devicePasscode
        }
    }

    private func map(error: NSError?) -> AppLockAuthenticationFailure {
        guard let error,
              error.domain == LAError.errorDomain,
              let code = LAError.Code(rawValue: error.code) else {
            return .unexpected
        }

        switch code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel, .userFallback:
            return .userCancelled
        case .systemCancel, .appCancel, .invalidContext:
            return .interrupted
        case .passcodeNotSet:
            return .passcodeNotSet
        case .biometryNotAvailable:
            return .biometryUnavailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockedOut
        case .notInteractive:
            return .interactionUnavailable
        default:
            return .unexpected
        }
    }
}
