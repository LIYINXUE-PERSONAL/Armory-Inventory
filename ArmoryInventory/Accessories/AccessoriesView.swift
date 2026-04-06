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
            name: "Optics",
            systemImage: "scope",
            shortDescription: "Scopes, red dots, and magnifiers",
            detailDescription: "Optics include sighting systems used to improve target acquisition and precision across different firearm setups.",
            examples: ["LPVO", "Red Dot", "Holographic Sight", "Magnifier"]
        ),
        AccessoryCategory(
            id: "magazines",
            name: "Magazines",
            systemImage: "rectangle.stack.fill.badge.plus",
            shortDescription: "Spare mags and loadout essentials",
            detailDescription: "Magazine tracking helps you manage capacity, platform compatibility, and quantity on hand.",
            examples: ["Pistol Magazine", "AR-15 Magazine", "AK Magazine", "Drum Magazine"]
        ),
        AccessoryCategory(
            id: "attachments",
            name: "Attachments",
            systemImage: "hand.raised.fill",
            shortDescription: "Mounted accessories grouped by attachment type",
            detailDescription: "Attachments include mounted accessories such as stocks, grips, lasers, lights, hand stops, and similar hardware. They can be categorized later using an Attachment Type field instead of separate screens.",
            examples: ["Stock", "Grip", "Laser", "Light", "Hand Stop", "Bipod"]
        ),
        AccessoryCategory(
            id: "parts",
            name: "Parts",
            systemImage: "gearshape.2.fill",
            shortDescription: "Core components and replacement assemblies",
            detailDescription: "Parts cover major firearm components you install, swap, or keep on hand, such as barrels, triggers, receivers, recoil systems, and other internal assemblies.",
            examples: ["Barrel", "Trigger", "Bolt Carrier Group", "Charging Handle", "Slide", "Recoil System"]
        ),
    ]
}

#Preview {
    AccessoriesView()
}
