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
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(groupedMagazines) { group in
                            VStack(alignment: .leading, spacing: 10) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(group.displayName)
                                        .font(.headline)
                                    Text(group.summaryText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(group.linkedFirearmsText)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 4)

                                ForEach(group.magazines) { magazine in
                                    magazineRow(magazine)
                                }
                            }
                        }

                        if showTotalValue {
                            LabeledContent("Total Value", value: totalValueText)
                                .padding(16)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Magazines")
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

    private func magazineRow(_ magazine: Magazine) -> some View {
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
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Delete", systemImage: "trash", role: .destructive) {
                deleteMagazine(magazine)
            }
        }
    }

    private func deleteMagazine(_ magazine: Magazine) {
        context.delete(magazine)
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
