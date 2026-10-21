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
    let isSceneActive: Bool

    func makeUIView(context: Context) -> PrivacyShieldProbeView {
        PrivacyShieldProbeView()
    }

    func updateUIView(_ view: PrivacyShieldProbeView, context: Context) {
        view.update(
            isProtectionEnabled: isProtectionEnabled,
            isSceneActive: isSceneActive
        )
    }
}

final class PrivacyShieldProbeView: UIView {
    private weak var observedScene: UIScene?
    private var observers: [NSObjectProtocol] = []
    private var isProtectionEnabled = false
    private var isSceneActive = false
    private weak var shieldView: UIView?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        isSceneActive = window?.windowScene?.activationState == .foregroundActive
        observeCurrentScene()
        synchronizeShield()
    }

    func update(
        isProtectionEnabled: Bool,
        isSceneActive: Bool
    ) {
        self.isProtectionEnabled = isProtectionEnabled
        self.isSceneActive = isSceneActive
            && window?.windowScene?.activationState == .foregroundActive
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
                self?.isSceneActive = false
                self?.installShieldIfNeeded()
            },
            NotificationCenter.default.addObserver(
                forName: UIScene.didActivateNotification,
                object: scene,
                queue: .main
            ) { [weak self] _ in
                self?.isSceneActive = true
                self?.synchronizeShield()
            },
            NotificationCenter.default.addObserver(
                forName: UIScene.didEnterBackgroundNotification,
                object: scene,
                queue: .main
            ) { [weak self] _ in
                self?.isSceneActive = false
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
        if isProtectionEnabled && !isSceneActive {
            installShieldIfNeeded()
        } else {
            shieldView?.removeFromSuperview()
        }
    }

    private func installShieldIfNeeded() {
        guard isProtectionEnabled,
              shieldView == nil,
              let window else {
            return
        }

        let shield = UIView()
        shield.translatesAutoresizingMaskIntoConstraints = false
        shield.backgroundColor = .systemBackground
        shield.isAccessibilityElement = false
        shield.accessibilityElementsHidden = true
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
