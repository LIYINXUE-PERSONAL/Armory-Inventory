//
//  AboutView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import UIKit

struct AboutView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 12) {
                        appIconView

                        Text("Armory Inventory")
                            .font(.title2.weight(.semibold))
                            .multilineTextAlignment(.center)

                        Text("Track firearms, ammo, optics, magazines, attachments, parts, and related inventory.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section("Special Thanks") {
                    Text("Special thanks to the Pro-2A community for the enthusiasm, knowledge sharing, and support behind responsible ownership and training.\n\nAppreciation as well to the organizations and advocates who continue defending Second Amendment rights and educating the community.")
                }

                Section("Version") {
                    LabeledContent("Build", value: appVersionText)
                }

                Section("Legal") {
                    Button {
                        openURL(privacyPolicyURL)
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                }

                Section("Feedback") {
                    Button {
                        sendFeedback()
                    } label: {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder
    private var appIconView: some View {
        if let appIconImage {
            Image(uiImage: appIconImage)
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color(.separator), lineWidth: 0.5)
                }
        }
    }

    private var appIconImage: UIImage? {
        guard let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconName = iconFiles.last else {
            return nil
        }

        return UIImage(named: iconName)
    }

    private var appVersionText: String {
        let shortVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String

        switch (shortVersion, buildNumber) {
        case let (.some(version), .some(build)):
            return "\(version) (\(build))"
        case let (.some(version), .none):
            return version
        case let (.none, .some(build)):
            return build
        case (.none, .none):
            return "Unavailable"
        }
    }

    private var privacyPolicyURL: URL {
        URL(string: "https://github.com/LIYINXUE-PERSONAL/Armory-Inventory/blob/main/PRIVACY_POLICY.md")!
    }

    private func sendFeedback() {
        let feedbackService = AppServices.shared.resolve(FeedbackServicing.self)
        guard let url = feedbackService.feedbackEmailURL(appVersion: appVersionText) else {
            return
        }
        openURL(url)
    }
}
