//
//  AppLockView.swift
//  Armory Inventory
//
//  Created by Codex on 10/21/26.
//

import SwiftUI

struct AppLockView: View {
    @EnvironmentObject private var coordinator: AppLockCoordinator

    var body: some View {
        AppLockStatusView(
            isAuthenticating: coordinator.state == .authenticating,
            statusMessage: statusMessage,
            focusesHeadingOnAppear: true,
            unlockAction: coordinator.requestUnlock
        )
    }

    private var statusMessage: String {
        switch coordinator.state {
        case .authenticating:
            return String(localized: "Confirm your identity using the system prompt.")
        case let .unavailable(failure):
            return failure.recoveryMessage
        case .disabled, .locked, .unlocked:
            return String(localized: "Authenticate to access your inventory.")
        }
    }
}

struct AppLockStatusView: View {
    let isAuthenticating: Bool
    let statusMessage: String
    let focusesHeadingOnAppear: Bool
    let unlockAction: (() -> Void)?

    @AccessibilityFocusState private var isHeadingFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 52))
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: 8) {
                Text("Armory Inventory Locked")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .accessibilityFocused($isHeadingFocused)

                Text(statusMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            ZStack {
                if isAuthenticating {
                    ProgressView("Authenticating…")
                        .accessibilityLabel("Authenticating")
                } else if let unlockAction {
                    Button {
                        unlockAction()
                    } label: {
                        Label("Unlock", systemImage: "lock.open")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityHint("Shows system authentication")
                }
            }
            .frame(maxWidth: 280)
            .frame(height: 52)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .onAppear {
            if focusesHeadingOnAppear {
                isHeadingFocused = true
            }
        }
        .onChange(of: isAuthenticating) { _, isAuthenticating in
            if focusesHeadingOnAppear && !isAuthenticating {
                isHeadingFocused = true
            }
        }
    }
}

struct ProtectedRootView: View {
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var coordinator: AppLockCoordinator

    var body: some View {
        ZStack {
            RootTabView()
                .opacity(coordinator.canRevealProtectedContent ? 1 : 0)
                .allowsHitTesting(coordinator.canRevealProtectedContent)
                .accessibilityHidden(!coordinator.canRevealProtectedContent)

            if !coordinator.canRevealProtectedContent {
                AppLockView()
            }
        }
        .overlay {
            ScenePrivacyShieldProbe(
                isProtectionEnabled: coordinator.isEnabled,
                isAuthenticating: coordinator.state == .authenticating || coordinator.isChangingSetting,
                canRevealProtectedContent: coordinator.canRevealProtectedContent,
                isSceneActive: scenePhase == .active
            )
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
    }
}
