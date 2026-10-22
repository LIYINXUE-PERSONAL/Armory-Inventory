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
    let isSceneActive: Bool

    func makeUIView(context: Context) -> PrivacyShieldProbeView {
        PrivacyShieldProbeView()
    }

    func updateUIView(_ view: PrivacyShieldProbeView, context: Context) {
        view.update(
            isProtectionEnabled: isProtectionEnabled,
            isAuthenticating: isAuthenticating,
            isSceneActive: isSceneActive
        )
    }
}

final class PrivacyShieldProbeView: UIView {
    private weak var observedScene: UIScene?
    private var observers: [NSObjectProtocol] = []
    private var isProtectionEnabled = false
    private var isAuthenticating = false
    private var isSceneActive = false
    private weak var shieldView: PrivacyShieldView?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        isSceneActive = window?.windowScene?.activationState == .foregroundActive
        observeCurrentScene()
        synchronizeShield()
    }

    func update(
        isProtectionEnabled: Bool,
        isAuthenticating: Bool,
        isSceneActive: Bool
    ) {
        self.isProtectionEnabled = isProtectionEnabled
        self.isAuthenticating = isAuthenticating
        self.isSceneActive = isSceneActive
            && window?.windowScene?.activationState == .foregroundActive
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

        let shield = PrivacyShieldView(isAuthenticating: isAuthenticating)
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
    private let progressView = UIActivityIndicatorView(style: .medium)
    private let statusLabel = UILabel()

    init(isAuthenticating: Bool) {
        super.init(frame: .zero)
        configureView()
        configure(isAuthenticating: isAuthenticating)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(isAuthenticating: Bool) {
        statusLabel.text = isAuthenticating
            ? String(localized: "Confirm your identity using the system prompt.")
            : String(localized: "Authenticate to access your inventory.")

        if isAuthenticating {
            progressView.startAnimating()
        } else {
            progressView.stopAnimating()
        }
        progressView.isHidden = !isAuthenticating
    }

    private func configureView() {
        backgroundColor = .systemBackground
        isAccessibilityElement = false
        accessibilityElementsHidden = true

        let iconView = UIImageView(image: UIImage(systemName: "lock.shield.fill"))
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 52)
        iconView.tintColor = tintColor
        iconView.contentMode = .scaleAspectFit

        let titleLabel = UILabel()
        titleLabel.text = String(localized: "Armory Inventory Locked")
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        statusLabel.font = .preferredFont(forTextStyle: .body)
        statusLabel.adjustsFontForContentSizeCategory = true
        statusLabel.textColor = .secondaryLabel
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0

        let statusStack = UIStackView(arrangedSubviews: [statusLabel, progressView])
        statusStack.axis = .vertical
        statusStack.alignment = .center
        statusStack.spacing = 12

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, statusStack])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 16
        addSubview(stack)

        NSLayoutConstraint.activate([
            iconView.widthAnchor.constraint(equalToConstant: 64),
            iconView.heightAnchor.constraint(equalToConstant: 64),
            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -32)
        ])
    }
}
