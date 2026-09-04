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
    @State private var showingFilters = false
    @State private var selectedType: String?
    @State private var selectedStatusFilter: AccessoryLinkStatusFilter = .all

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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        AccessoryLinkStatusFiltersCard(
                            isExpanded: $showingFilters,
                            typeOptions: typeFilterOptions,
                            selectedType: $selectedType,
                            selectedStatusFilter: $selectedStatusFilter
                        )

                        if filteredParts.isEmpty {
                            ContentUnavailableView(
                                "No Matching Parts",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No parts match the selected filters.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            ForEach(filteredParts) { part in
                                partRow(part)
                            }

                            if showTotalValue {
                                LabeledContent("Total Value", value: totalValueText)
                                    .padding(16)
                                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                            }
                        }
                    }
                    .padding()
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

    private func partRow(_ part: Part) -> some View {
        Button {
            selectedPart = part
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(part.displayName)
                    .font(.headline)

                if showValueInCard, part.purchasePriceCents > 0 {
                    LabeledContent("Value", value: part.purchasePriceText)
                }

                if let firearm = viewModel.linkedFirearm(for: part, kits: kits) {
                    LabeledContent("Linked Firearm", value: firearm.displayName)
                }

                if let kit = viewModel.linkedKit(for: part, kits: kits) {
                    LabeledContent("Linked Kit", value: kit.displayName)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                deletePart(part)
            }
        }
    }

    private var filteredParts: [Part] {
        viewModel.sortedParts(
            viewModel.filteredParts(parts, selectedType: selectedType, selectedStatusFilter: selectedStatusFilter, kits: kits),
            sortOrderRaw: itemSortOrder,
            sortDirectionRaw: itemSortDirectionRaw
        )
    }

    private var typeFilterOptions: [InventoryTypeFilterOption] {
        viewModel.groupedPartTypes(from: viewModel.groupedParts(parts, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw))
            .map { InventoryTypeFilterOption(id: $0, displayName: partTypeDisplayName(for: $0)) }
    }

    private var groupedParts: [String: [Part]] {
        viewModel.groupedParts(filteredParts, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw)
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

    private func deletePart(_ part: Part) {
        guard let index = groupedParts[part.type]?.firstIndex(where: { $0.persistentModelID == part.persistentModelID }) else {
            return
        }
        deleteParts(at: IndexSet(integer: index), in: part.type)
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
        viewModel.totalValueText(for: filteredParts)
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
