//
//  AppLockSettingsView.swift
//  Armory Inventory
//
//  Created by Codex on 10/21/26.
//

import SwiftUI

struct AppLockSettingsView: View {
    @EnvironmentObject private var coordinator: AppLockCoordinator
    @State private var pendingValue: Bool?
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section {
                Toggle(
                    "Require Authentication",
                    isOn: Binding(
                        get: { coordinator.isEnabled },
                        set: { pendingValue = $0 }
                    )
                )
                .disabled(coordinator.isChangingSetting)

                if coordinator.isChangingSetting {
                    ProgressView("Authenticating…")
                }
            } footer: {
                Text("When enabled, Armory Inventory requires system authentication after the app returns from the background.")
            }

            Section("Authentication") {
                LabeledContent("Method", value: coordinator.capability.method.displayName)

                if !coordinator.capability.isAvailable,
                   let failure = coordinator.capability.failure {
                    Text(failure.recoveryMessage)
                        .foregroundStyle(.secondary)
                }
            }

            Section("About App Lock") {
                Text("App Lock protects access to the app using Face ID, Touch ID, or your device passcode. It does not encrypt exported backup files.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("App Lock")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            coordinator.refreshCapability()
        }
        .alert(confirmationTitle, isPresented: confirmationBinding) {
            Button("Cancel", role: .cancel) {
                pendingValue = nil
            }

            Button(confirmationButtonTitle, role: pendingValue == false ? .destructive : nil) {
                guard let requestedValue = pendingValue else { return }
                pendingValue = nil
                Task {
                    let result = await coordinator.setAppLockEnabled(requestedValue)
                    if case let .failure(failure) = result {
                        errorMessage = failure.recoveryMessage
                    }
                }
            }
        } message: {
            Text(confirmationMessage)
        }
        .alert("App Lock", isPresented: errorBinding) {
            Button("OK", role: .cancel) {
                errorMessage = nil
            }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var confirmationBinding: Binding<Bool> {
        Binding(
            get: { pendingValue != nil },
            set: { isPresented in
                if !isPresented {
                    pendingValue = nil
                }
            }
        )
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    private var confirmationTitle: String {
        pendingValue == true
            ? String(localized: "Turn On App Lock?")
            : String(localized: "Turn Off App Lock?")
    }

    private var confirmationButtonTitle: String {
        pendingValue == true
            ? String(localized: "Turn On")
            : String(localized: "Turn Off")
    }

    private var confirmationMessage: String {
        pendingValue == true
            ? String(localized: "You will authenticate now. Afterward, authentication will be required whenever the app returns from the background.")
            : String(localized: "Authenticate to stop requiring App Lock when the app returns from the background.")
    }
}
