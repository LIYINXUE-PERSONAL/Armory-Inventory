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
                    ForEach(groupedOpticTypes, id: \.self) { type in
                        Section(type) {
                            ForEach(groupedOptics[type] ?? []) { optic in
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

                                        if let firearm = optic.firearm {
                                            LabeledContent("Linked Firearm", value: firearm.displayName)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                deleteOptics(at: offsets, in: type)
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
    }

    private var groupedOptics: [String: [Optic]] {
        Dictionary(grouping: optics, by: \.typeDisplayName).mapValues {
            AccessoryItemSort.sorted($0, by: selectedItemSortOrder, direction: selectedItemSortDirection)
        }
    }

    private var groupedOpticTypes: [String] {
        OpticTypeSort.displayOrder(for: Array(groupedOptics.keys))
    }

    private func deleteOptics(at offsets: IndexSet, in type: String) {
        guard let sectionOptics = groupedOptics[type] else {
            return
        }

        for index in offsets {
            context.delete(sectionOptics[index])
        }
        resequenceOptics()

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            reloadOptics()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private func reloadOptics() {
        do {
            optics = try inventoryListService.fetchOptics(in: context)
        } catch {
            print("Optics fetch error: \(error)")
        }
    }

    private func resequenceOptics() {
        for (index, optic) in optics.enumerated() {
            optic.sortOrder = index
        }
    }

    private var totalValueText: String {
        let totalCents = optics.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
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
