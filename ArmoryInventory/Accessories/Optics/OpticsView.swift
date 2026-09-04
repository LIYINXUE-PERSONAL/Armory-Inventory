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
                List {
                    Section {
                        AccessoryLinkStatusFiltersCard(
                            isExpanded: $showingFilters,
                            selectedStatusFilter: $selectedStatusFilter
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }

                    if filteredOptics.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "No Matching Optics",
                                systemImage: "line.3.horizontal.decrease.circle",
                                description: Text("No optics match the selected filters.")
                            )
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        ForEach(groupedOpticTypes, id: \.self) { typeID in
                            Section(opticTypeDisplayName(for: typeID)) {
                                ForEach(groupedOptics[typeID] ?? []) { optic in
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
                                        .padding(.vertical, 6)
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete { offsets in
                                    deleteOptics(at: offsets, in: typeID)
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
                EditButton()

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

    private var filteredOptics: [Optic] {
        viewModel.filteredOptics(optics, selectedStatusFilter: selectedStatusFilter, kits: kits)
    }

    private var groupedOptics: [String: [Optic]] {
        viewModel.groupedOptics(filteredOptics, sortOrderRaw: itemSortOrder, sortDirectionRaw: itemSortDirectionRaw)
    }

    private var groupedOpticTypes: [String] {
        viewModel.groupedOpticTypes(from: groupedOptics)
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
