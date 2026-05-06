//
//  PartTypeOrderingView.swift
//  Armory Inventory
//
//  Created by Codex on 4/6/26.
//

import SwiftUI

struct PartTypeOrderingView: View {
    @AppStorage(PartTypeSort.settingsVersionKey) private var sortVersion = 0
    @AppStorage(InventorySettingsKeys.partItemSortOrder) private var itemSortOrder = AccessoryItemSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.partItemSortDirection) private var itemSortDirectionRaw = ""
    @State private var rankingNames: [String] = []
    let viewModel: PartTypeOrderingViewModel

    var body: some View {
        List {
            Section {
                Text("Hold and drag part types to control the section order used in parts.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Type Order") {
                ForEach(rankingNames, id: \.self) { typeName in
                    Text(viewModel.displayName(for: typeName))
                }
                .onMove(perform: moveRanking)
            }

            Section {
                Button("Reset to Default Order", role: .destructive) {
                    viewModel.resetOrder(rankingNames: &rankingNames)
                }
            }

            AccessoryItemSortingSection(
                sortOrderRaw: $itemSortOrder,
                sortDirectionRaw: $itemSortDirectionRaw,
                itemLabelPlural: String(localized: "Parts")
            )
        }
        .navigationTitle("Parts Sorting")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
        }
        .onAppear {
            rankingNames = viewModel.refreshedRankingNames()
        }
        .onChange(of: sortVersion) { _, _ in
            rankingNames = viewModel.refreshedRankingNames()
        }
    }

    private func moveRanking(from source: IndexSet, to destination: Int) {
        rankingNames = viewModel.moveRanking(rankingNames, from: source, to: destination)
    }
}
