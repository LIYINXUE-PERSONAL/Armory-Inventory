//
//  OpticsView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct OpticsView: View {
    @Environment(\.modelContext) private var context
    @AppStorage(OpticTypeSort.settingsVersionKey) private var typeSortVersion = 0
    @AppStorage(InventorySettingsKeys.opticItemSortOrder) private var itemSortOrder = AccessoryItemSortOrder.manual.rawValue
    @AppStorage(InventorySettingsKeys.opticItemSortDirection) private var itemSortDirectionRaw = ""
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddOptic = false
    @State private var selectedOptic: Optic?
    @State private var optics: [Optic] = []
    @State private var kits: [Kit] = []
    @State private var alertMessage: String?
    @State private var showingFilters = false
    @State private var selectedType: String?
    @State private var selectedStatusFilter: AccessoryLinkStatusFilter = .all

    private let viewModel = AccessoryInventoryListViewModel()
    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)

    var body: some View {
        Group {
            if optics.isEmpty {
                ContentUnavailableView(
                    "No Optics Yet",
                    systemImage: "scope",
                    description: Text("Add your first optic to start tracking mounts, magnification, and purchase cost.")
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

                        if filteredOptics.isEmpty {
                            ContentUnavailableView(
                                "No Matching Optics",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No optics match the selected filters.")
                            )
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                        } else {
                            ForEach(filteredOptics) { optic in
                                opticRow(optic)
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
        .navigationTitle("Optics")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadOptics()
        }
        .onAppear {
            reloadOptics()
        }
        .onChange(of: showingAddOptic) {
            if !showingAddOptic {
                reloadOptics()
            }
        }
        .onChange(of: selectedOptic) {
            if selectedOptic == nil {
                reloadOptics()
            }
        }
        .onChange(of: typeSortVersion) { _, _ in
            reloadOptics()
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingAddOptic = true
                } label: {
                    Label("Add Optic", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddOptic) {
            AddOpticView(viewModel: AddOpticViewModel())
                .presentationDetents([.large])
        }
        .sheet(item: $selectedOptic) { optic in
            AddOpticView(optic: optic, viewModel: AddOpticViewModel())
                .presentationDetents([.large])
        }
        .alert("Optic Cannot Be Deleted", isPresented: alertBinding) {
            Button("OK", role: .cancel) {
                alertMessage = nil
            }
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func opticRow(_ optic: Optic) -> some View {
        Button {
            selectedOptic = optic
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(optic.displayName)
                            .font(.headline)
                        Text(optic.magnificationText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Footprint", value: optic.footprintDisplayName)

                if let tubeSizeText = optic.tubeSizeText {
                    LabeledContent("Tube", value: tubeSizeText)
                }

                if let focalPlane = optic.opticFocalPlane {
                    LabeledContent("Focal Plane", value: focalPlane.displayName)
                }

                if showValueInCard, optic.purchasePriceCents > 0 {
                    LabeledContent("Value", value: optic.purchasePriceText)
                }

                if let firearm = viewModel.linkedFirearm(for: optic, kits: kits) {
                    LabeledContent("Linked Firearm", value: firearm.displayName)
                }

                if let kit = viewModel.linkedKit(for: optic, kits: kits) {
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
                deleteOptic(optic)
            }
        }
    }

    private var filteredOptics: [Optic] {
        viewModel.sortedOptics(
            viewModel.filteredOptics(optics, selectedType: selectedType, selectedStatusFilter: selectedStatusFilter, kits: kits),
            sortOrderRaw: itemSortOrder,
            sortDirectionRaw: itemSortDirectionRaw
        )
    }

    private var typeFilterOptions: [InventoryTypeFilterOption] {
        viewModel.groupedOpticTypes(from: viewModel.groupedOptics(optics, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw))
            .map { InventoryTypeFilterOption(id: $0, displayName: opticTypeDisplayName(for: $0)) }
    }

    private var groupedOptics: [String: [Optic]] {
        viewModel.groupedOptics(filteredOptics, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw)
    }

    private func deleteOptics(at offsets: IndexSet, in type: String) {
        let result = viewModel.deleteOptics(
            at: offsets,
            in: type,
            groupedOptics: groupedOptics,
            allOptics: optics,
            kits: kits,
            context: context
        )
        if result.isValid {
            reloadOptics()
        } else {
            alertMessage = result.message
            reloadOptics()
        }
    }

    private func deleteOptic(_ optic: Optic) {
        guard let index = groupedOptics[optic.type]?.firstIndex(where: { $0.persistentModelID == optic.persistentModelID }) else {
            return
        }
        deleteOptics(at: IndexSet(integer: index), in: optic.type)
    }

    private func reloadOptics() {
        do {
            optics = try inventoryListService.fetchOptics(in: context)
            kits = try inventoryListService.fetchKits(in: context)
        } catch {
            print("Optics fetch error: \(error)")
        }
    }

    private var totalValueText: String {
        viewModel.totalValueText(for: filteredOptics)
    }

    private func opticTypeDisplayName(for typeID: String) -> String {
        viewModel.opticTypeDisplayName(for: typeID)
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )
    }
}
