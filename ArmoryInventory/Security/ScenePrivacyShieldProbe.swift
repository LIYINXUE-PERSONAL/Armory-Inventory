//
//  ScenePrivacyShieldProbe.swift
//  Armory Inventory
//
//  Created by Codex on 10/21/26.
//

import SwiftUI
import UIKit

struct ScenePrivacyShieldProbe: UIViewRepresentable {
    let isProtectionEnabled: Bool
    let isAuthenticating: Bool
    let canRevealProtectedContent: Bool
    let isSceneActive: Bool

    func makeUIView(context: Context) -> PrivacyShieldProbeView {
        PrivacyShieldProbeView()
    }

    func updateUIView(_ view: PrivacyShieldProbeView, context: Context) {
        view.update(
            isProtectionEnabled: isProtectionEnabled,
            isAuthenticating: isAuthenticating,
            canRevealProtectedContent: canRevealProtectedContent,
            isSceneActive: isSceneActive
        )
    }
}

struct PrivacyShieldVisibilityState {
    private(set) var isProtectionEnabled = false
    private(set) var isAuthenticating = false
    private(set) var isSceneActive = false
    private var canRevealFollowingAuthentication = false

    var shouldShowShield: Bool {
        isProtectionEnabled && !isSceneActive && !canRevealFollowingAuthentication
    }

    mutating func update(
        isProtectionEnabled: Bool,
        isAuthenticating: Bool,
        canRevealProtectedContent: Bool,
        isSceneActive: Bool
    ) {
        let didAuthenticateSuccessfully = self.isAuthenticating
            && !isAuthenticating
            && canRevealProtectedContent

        self.isProtectionEnabled = isProtectionEnabled
        self.isAuthenticating = isAuthenticating
        self.isSceneActive = isSceneActive

        if isSceneActive {
            canRevealFollowingAuthentication = false
        } else if didAuthenticateSuccessfully {
            canRevealFollowingAuthentication = true
        }
    }

    mutating func sceneWillDeactivate() {
        isSceneActive = false
        canRevealFollowingAuthentication = false
    }

    mutating func sceneDidActivate() {
        isSceneActive = true
        canRevealFollowingAuthentication = false
    }

    mutating func sceneDidEnterBackground() {
        isSceneActive = false
        canRevealFollowingAuthentication = false
    }
}

final class PrivacyShieldProbeView: UIView {
    private weak var observedScene: UIScene?
    private var observers: [NSObjectProtocol] = []
    private var visibilityState = PrivacyShieldVisibilityState()
    private weak var shieldView: PrivacyShieldView?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window?.windowScene?.activationState == .foregroundActive {
            visibilityState.sceneDidActivate()
        } else {
            visibilityState.sceneWillDeactivate()
        }
        observeCurrentScene()
        synchronizeShield()
    }

    func update(
        isProtectionEnabled: Bool,
        isAuthenticating: Bool,
        canRevealProtectedContent: Bool,
        isSceneActive: Bool
    ) {
        visibilityState.update(
            isProtectionEnabled: isProtectionEnabled,
            isAuthenticating: isAuthenticating,
            canRevealProtectedContent: canRevealProtectedContent,
            isSceneActive: isSceneActive
                && window?.windowScene?.activationState == .foregroundActive
        )
        shieldView?.configure(isAuthenticating: isAuthenticating)
        observeCurrentScene()
        synchronizeShield()
    }

    deinit {
        removeObservers()
        shieldView?.removeFromSuperview()
    }

    private func observeCurrentScene() {
        guard let scene = window?.windowScene,
              scene !== observedScene else {
            return
        }

        removeObservers()
        observedScene = scene

        observers = [
            NotificationCenter.default.addObserver(
                forName: UIScene.willDeactivateNotification,
                object: scene,
                queue: .main
            ) { [weak self] _ in
                self?.visibilityState.sceneWillDeactivate()
                self?.installShieldIfNeeded()
            },
            NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification,
                object: scene,
                queue: .main
            ) { [weak self] _ in
                self?.visibilityState.sceneDidActivate()
                self?.synchronizeShield()
            },
            NotificationCenter.default.addObserver(
                forName: UIScene.didEnterBackgroundNotification,
                object: scene,
                queue: .main
            ) { [weak self] _ in
                self?.visibilityState.sceneDidEnterBackground()
                self?.installShieldIfNeeded()
            }
        ]
    }

    private func removeObservers() {
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
        observedScene = nil
    }

    private func synchronizeShield() {
        if visibilityState.shouldShowShield {
            installShieldIfNeeded()
        } else {
            shieldView?.removeFromSuperview()
        }
    }

    private func installShieldIfNeeded() {
        guard visibilityState.shouldShowShield,
              shieldView == nil,
              let window else {
            return
        }

        let shield = PrivacyShieldView(isAuthenticating: visibilityState.isAuthenticating)
        shield.translatesAutoresizingMaskIntoConstraints = false
        window.addSubview(shield)
        NSLayoutConstraint.activate([
            shield.leadingAnchor.constraint(equalTo: window.leadingAnchor),
            shield.trailingAnchor.constraint(equalTo: window.trailingAnchor),
            shield.topAnchor.constraint(equalTo: window.topAnchor),
            shield.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        shieldView = shield
    }
}

final class PrivacyShieldView: UIView {
    private let hostingController: UIHostingController<AppLockStatusView>

    init(isAuthenticating: Bool) {
        hostingController = UIHostingController(
            rootView: Self.content(isAuthenticating: isAuthenticating)
        )
        super.init(frame: .zero)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isAuthenticating: Bool) {
        hostingController.rootView = Self.content(isAuthenticating: isAuthenticating)
    }

    private func configureView() {
        backgroundColor = .systemBackground
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        let hostedView = hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hostedView)

        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private static func content(isAuthenticating: Bool) -> AppLockStatusView {
        AppLockStatusView(
            isAuthenticating: isAuthenticating,
            statusMessage: isAuthenticating
                ? String(localized: "Confirm your identity using the system prompt.")
                : String(localized: "Authenticate to access your inventory."),
            focusesHeadingOnAppear: false,
            unlockAction: nil
        )
    }
}
