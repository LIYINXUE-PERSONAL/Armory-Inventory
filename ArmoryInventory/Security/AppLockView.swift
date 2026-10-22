//
//  AppLockView.swift
//  Armory Inventory
//
//  Created by Codex on 10/21/26.
//

import SwiftUI

struct AppLockView: View {
    @EnvironmentObject private var coordinator: AppLockCoordinator
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

            if coordinator.state == .authenticating {
                ProgressView("Authenticating…")
                    .accessibilityLabel("Authenticating")
            } else {
                Button {
                    coordinator.requestUnlock()
                } label: {
                    Label("Unlock", systemImage: "lock.open")
                        .frame(maxWidth: 280)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityHint("Shows system authentication")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(Color(.systemBackground))
        .onAppear {
            isHeadingFocused = true
        }
        .onChange(of: coordinator.state) { _, newState in
            if newState != .authenticating {
                isHeadingFocused = true
            }
        }
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
                isSceneActive: scenePhase == .active
            )
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
        }
    }
}
