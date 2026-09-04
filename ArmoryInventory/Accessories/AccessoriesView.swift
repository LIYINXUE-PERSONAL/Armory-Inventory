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
    private let viewModel = AccessoriesViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accessory Types")
                            .font(.headline)

                        Text("Track the major components you swap between firearms.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    ForEach(viewModel.topLevelCategories) { category in
                        NavigationLink {
                            destination(for: category)
                        } label: {
                            AccessoryCategoryRow(category: category)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    if showTotalValue {
                        LabeledContent("Total Value", value: totalValueText)
                            .padding(16)
                            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                }
                .padding()
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
        case "kits":
            KitsView()
        default:
            AccessoryCategoryDetailView(category: category)
        }
    }

    private var totalValueText: String {
        viewModel.totalValueText(optics: optics, magazines: magazines, attachments: attachments, parts: parts)
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

#Preview {
    AccessoriesView()
}
