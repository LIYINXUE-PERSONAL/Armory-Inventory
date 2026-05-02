//
//  AccessoriesView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AccessoriesView: View {
    @Query private var optics: [Optic]
    @Query private var magazines: [Magazine]
    @Query private var attachments: [Attachment]
    @Query private var parts: [Part]
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    private let topLevelCategories = AccessoryCategory.topLevelCategories

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(topLevelCategories) { category in
                        NavigationLink {
                            destination(for: category)
                        } label: {
                            AccessoryCategoryRow(category: category)
                        }
                    }
                } header: {
                    Text("Accessory Types")
                } footer: {
                    Text("Track the major components you swap between firearms.")
                }

                if showTotalValue {
                    Section {
                        LabeledContent("Total Value", value: totalValueText)
                    }
                }
            }
            .navigationTitle("Accessories")
        }
    }

    @ViewBuilder
    private func destination(for category: AccessoryCategory) -> some View {
        switch category.id {
        case "optics":
            OpticsView()
        case "magazines":
            MagazinesView()
        case "attachments":
            AttachmentsView()
        case "parts":
            PartsView()
        default:
            AccessoryCategoryDetailView(category: category)
        }
    }

    private var totalValueText: String {
        let totalCents =
            optics.reduce(0) { $0 + max(0, $1.purchasePriceCents) } +
            magazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) } +
            attachments.reduce(0) { $0 + max(0, $1.purchasePriceCents) } +
            parts.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }
}

private struct AccessoryCategoryRow: View {
    let category: AccessoryCategory

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: category.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.headline)
                Text(category.shortDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AccessoryCategoryDetailView: View {
    let category: AccessoryCategory

    var body: some View {
        List {
            Section {
                Label(category.name, systemImage: category.systemImage)
                    .font(.headline)

                Text(category.detailDescription)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Overview")
            }

            Section("Examples") {
                ForEach(category.examples, id: \.self) { example in
                    Text(example)
                }
            }
        }
        .navigationTitle(category.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct AccessoryCategory: Identifiable {
    let id: String
    let name: String
    let systemImage: String
    let shortDescription: String
    let detailDescription: String
    let examples: [String]

    static let topLevelCategories: [AccessoryCategory] = [
        AccessoryCategory(
            id: "optics",
            name: String(localized: "Optics"),
            systemImage: "scope",
            shortDescription: String(localized: "Scopes, red dots, and magnifiers"),
            detailDescription: String(localized: "Optics include sighting systems used to improve target acquisition and precision across different firearm setups."),
            examples: [
                String(localized: "LPVO"),
                String(localized: "Red Dot"),
                String(localized: "Holographic Sight"),
                String(localized: "Magnifier"),
            ]
        ),
        AccessoryCategory(
            id: "magazines",
            name: String(localized: "Magazines"),
            systemImage: "rectangle.stack.fill.badge.plus",
            shortDescription: String(localized: "Spare mags and loadout essentials"),
            detailDescription: String(localized: "Magazine tracking helps you manage capacity, platform compatibility, and quantity on hand."),
            examples: [
                String(localized: "Pistol Magazine"),
                String(localized: "AR-15 Magazine"),
                String(localized: "AK Magazine"),
                String(localized: "Drum Magazine"),
            ]
        ),
        AccessoryCategory(
            id: "attachments",
            name: String(localized: "Attachments"),
            systemImage: "hand.raised.fill",
            shortDescription: String(localized: "Mounted accessories grouped by attachment type"),
            detailDescription: String(localized: "Attachments include mounted accessories such as stocks, grips, lasers, lights, hand stops, and similar hardware. They can be categorized later using an Attachment Type field instead of separate screens."),
            examples: [
                String(localized: "Stock"),
                String(localized: "Grip"),
                String(localized: "Laser"),
                String(localized: "Light"),
                String(localized: "Hand Stop"),
                String(localized: "Bipod"),
            ]
        ),
        AccessoryCategory(
            id: "parts",
            name: String(localized: "Parts"),
            systemImage: "gearshape.2.fill",
            shortDescription: String(localized: "Core components and replacement assemblies"),
            detailDescription: String(localized: "Parts cover major firearm components you install, swap, or keep on hand, such as barrels, triggers, receivers, recoil systems, and other internal assemblies."),
            examples: [
                String(localized: "Barrel"),
                String(localized: "Trigger"),
                String(localized: "Bolt Carrier Group"),
                String(localized: "Charging Handle"),
                String(localized: "Slide"),
                String(localized: "Recoil System"),
            ]
        ),
    ]
}

#Preview {
    AccessoriesView()
}
