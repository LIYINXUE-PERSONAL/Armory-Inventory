//
//  PartsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/5/26.
//

import SwiftUI
import SwiftData

struct PartsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(PartTypeSort.settingsVersionKey) private var typeSortVersion = 0
    @AppStorage(InventorySettingsKeys.partItemSortOrder) private var itemSortOrder = AccessoryItemSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.partItemSortDirection) private var itemSortDirectionRaw = ""
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddPart = false
    @State private var selectedPart: Part?
    @State private var parts: [Part] = []

    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)

    var body: some View {
        Group {
            if parts.isEmpty {
                ContentUnavailableView(
                    "No Parts Yet",
                    systemImage: "gearshape.2.fill",
                    description: Text("Add your first part to track barrels, triggers, receivers, recoil systems, and other swap-ready components.")
                )
            } else {
                List {
                    ForEach(groupedPartTypes, id: \.self) { type in
                        Section(type) {
                            ForEach(groupedParts[type] ?? []) { part in
                                Button {
                                    selectedPart = part
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(part.displayName)
                                            .font(.headline)

                                        if showValueInCard, part.purchasePriceCents > 0 {
                                            LabeledContent("Value", value: part.purchasePriceText)
                                        }

                                        if let firearm = part.firearm {
                                            LabeledContent("Linked Firearm", value: firearm.displayName)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                deleteParts(at: offsets, in: type)
                            }
                        }
                    }

                    if showTotalValue {
                        Section {
                            LabeledContent("Total Value", value: totalValueText)
                        }
                    }
                }
            }
        }
        .navigationTitle("Parts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadParts()
        }
        .onAppear {
            reloadParts()
        }
        .onChange(of: showingAddPart) {
            if !showingAddPart {
                reloadParts()
            }
        }
        .onChange(of: selectedPart) {
            if selectedPart == nil {
                reloadParts()
            }
        }
        .onChange(of: typeSortVersion) { _, _ in
            reloadParts()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()

                Button {
                    showingAddPart = true
                } label: {
                    Label("Add Part", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddPart) {
            AddPartView(viewModel: AddPartViewModel())
                .presentationDetents([.large])
        }
        .sheet(item: $selectedPart) { part in
            AddPartView(part: part, viewModel: AddPartViewModel())
                .presentationDetents([.large])
        }
    }

    private var groupedParts: [String: [Part]] {
        Dictionary(grouping: parts, by: \.typeDisplayName).mapValues {
            AccessoryItemSort.sorted($0, by: selectedItemSortOrder, direction: selectedItemSortDirection)
        }
    }

    private var groupedPartTypes: [String] {
        PartTypeSort.displayOrder(for: Array(groupedParts.keys))
    }

    private func deleteParts(at offsets: IndexSet, in type: String) {
        guard let sectionParts = groupedParts[type] else {
            return
        }

        for index in offsets {
            context.delete(sectionParts[index])
        }
        resequenceParts()

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            reloadParts()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private func reloadParts() {
        do {
            parts = try inventoryListService.fetchParts(in: context)
        } catch {
            print("Parts fetch error: \(error)")
        }
    }

    private func resequenceParts() {
        for (index, part) in parts.enumerated() {
            part.sortOrder = index
        }
    }

    private var totalValueText: String {
        let totalCents = parts.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private var selectedItemSortOrder: AccessoryItemSortOrder {
        AccessoryItemSortOrder(rawValue: itemSortOrder) ?? .manual
    }

    private var selectedItemSortDirection: AccessoryItemSortDirection {
        AccessoryItemSortDirection(rawValue: itemSortDirectionRaw) ?? AccessoryItemSort.preferredDirection(for: selectedItemSortOrder)
    }
}
