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
    @State private var selectedCategoryID: AccessoryCategory.ID = "optics"
    @State private var preferredCompactColumn = NavigationSplitViewColumn.sidebar
    private let viewModel = AccessoriesViewModel()

    var body: some View {
        NavigationSplitView(
            columnVisibility: .constant(.all),
            preferredCompactColumn: $preferredCompactColumn
        ) {
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
                        Button {
                            selectedCategoryID = category.id
                            preferredCompactColumn = .detail
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
            .toolbarVisibility(.visible, for: .navigationBar)
            .toolbar(removing: .sidebarToggle)
            .containerBackground(Color(.systemBackground), for: .navigation)
        } detail: {
            destination(for: selectedCategoryID)
        }
    }

    @ViewBuilder
    private func destination(for categoryID: AccessoryCategory.ID) -> some View {
        switch categoryID {
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
            OpticsView()
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

#Preview {
    AccessoriesView()
}
