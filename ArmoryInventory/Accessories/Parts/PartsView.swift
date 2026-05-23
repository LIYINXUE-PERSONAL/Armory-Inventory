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
    @State private var kits: [Kit] = []
    @State private var alertMessage: String?

    private let viewModel = AccessoryInventoryListViewModel()
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
                    ForEach(groupedPartTypes, id: \.self) { typeID in
                        Section(partTypeDisplayName(for: typeID)) {
                            ForEach(groupedParts[typeID] ?? []) { part in
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
                                deleteParts(at: offsets, in: typeID)
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
        .alert("Part Cannot Be Deleted", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private var groupedParts: [String: [Part]] {
        viewModel.groupedParts(parts, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw)
    }

    private var groupedPartTypes: [String] {
        viewModel.groupedPartTypes(from: groupedParts)
    }

    private func deleteParts(at offsets: IndexSet, in type: String) {
        let result = viewModel.deleteParts(
            at: offsets,
            in: type,
            groupedParts: groupedParts,
            allParts: parts,
            kits: kits,
            context: context
        )
        if result.isValid {
            reloadParts()
        } else {
            alertMessage = result.message
            reloadParts()
        }
    }

    private func reloadParts() {
        do {
            parts = try inventoryListService.fetchParts(in: context)
            kits = try inventoryListService.fetchKits(in: context)
        } catch {
            print("Parts fetch error: \(error)")
        }
    }

    private var totalValueText: String {
        viewModel.totalValueText(for: parts)
    }

    private func partTypeDisplayName(for typeID: String) -> String {
        viewModel.partTypeDisplayName(for: typeID)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }
}
