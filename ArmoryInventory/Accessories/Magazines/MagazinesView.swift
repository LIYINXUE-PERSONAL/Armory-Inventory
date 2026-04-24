//
//  MagazinesView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct MagazinesView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\Firearm.brand), SortDescriptor(\Firearm.modelName)]) private var firearms: [Firearm]
    @AppStorage(InventorySettingsKeys.showValueInCard) private var showValueInCard = true
    @AppStorage(InventorySettingsKeys.showTotalValue) private var showTotalValue = true
    @State private var showingAddMagazine = false
    @State private var selectedMagazine: Magazine?
    @State private var magazines: [Magazine] = []

    private let inventoryListService: InventoryListServicing = AppServices.shared.resolve(InventoryListServicing.self)
    private let viewModel = MagazinesViewModel()

    var body: some View {
        Group {
            if magazines.isEmpty {
                ContentUnavailableView(
                    "No Magazines Yet",
                    systemImage: "rectangle.stack.fill.badge.plus",
                    description: Text("Add your first magazine to track capacity, supported calibers, and linked firearms.")
                )
            } else {
                List {
                    ForEach(groupedMagazines) { group in
                        Section {
                            ForEach(group.magazines) { magazine in
                                Button {
                                    selectedMagazine = magazine
                                } label: {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(magazine.displayName)
                                            .font(.headline)

                                        HStack {
                                            Text(magazine.caliberDisplayText)
                                            Text("•")
                                            Text(magazine.countCapacityText)
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                        if showValueInCard, magazine.purchasePriceCents > 0 {
                                            LabeledContent("Value", value: magazine.purchasePriceText)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                            .onDelete { offsets in
                                deleteMagazines(in: group.magazines, at: offsets)
                            }
                        } header: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(group.displayName)
                                Text(group.summaryText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(group.linkedFirearmsText)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
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
        .navigationTitle("Magazines")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            reloadMagazines()
        }
        .onAppear {
            reloadMagazines()
        }
        .onChange(of: showingAddMagazine) {
            if !showingAddMagazine {
                reloadMagazines()
            }
        }
        .onChange(of: selectedMagazine) {
            if selectedMagazine == nil {
                reloadMagazines()
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                EditButton()

                Button {
                    showingAddMagazine = true
                } label: {
                    Label("Add Magazine", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddMagazine) {
            AddMagazineView(viewModel: AddMagazineViewModel())
                .presentationDetents([.large])
        }
        .sheet(item: $selectedMagazine) { magazine in
            AddMagazineView(magazine: magazine, viewModel: AddMagazineViewModel())
                .presentationDetents([.large])
        }
    }

    private func deleteMagazines(in group: [Magazine], at offsets: IndexSet) {
        for index in offsets {
            context.delete(group[index])
        }
        resequenceMagazines()

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            reloadMagazines()
        } catch {
            print("Delete error: \(error)")
        }
    }

    private func reloadMagazines() {
        do {
            magazines = try inventoryListService.fetchMagazines(in: context)
        } catch {
            print("Magazines fetch error: \(error)")
        }
    }

    private func resequenceMagazines() {
        for (index, magazine) in magazines.enumerated() {
            magazine.sortOrder = index
        }
    }

    private var totalValueText: String {
        let totalCents = magazines.reduce(0) { $0 + max(0, $1.purchasePriceCents) }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private var groupedMagazines: [MagazinePatternGroupSummary] {
        viewModel.groupedMagazines(magazines, firearms: firearms)
    }
}
