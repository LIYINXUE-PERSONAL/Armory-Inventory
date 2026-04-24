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
                                    let linkedFirearms = magazine.linkedFirearms(from: firearms)

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(magazine.displayName)
                                            .font(.headline)

                                        HStack {
                                            Text(magazine.caliberDisplayText)
                                            Text("•")
                                            Text(magazine.countText)
                                            Text("•")
                                            Text(magazine.capacityText)
                                        }
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)

                                        if showValueInCard, magazine.purchasePriceCents > 0 {
                                            LabeledContent("Value", value: magazine.purchasePriceText)
                                        }

                                        if !linkedFirearms.isEmpty {
                                            LabeledContent(
                                                linkedFirearms.count == 1 ? "Linked Firearm" : "Linked Firearms",
                                                value: linkedFirearms.map(\.displayName).joined(separator: ", ")
                                            )
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

    private var groupedMagazines: [MagazinePatternGroup] {
        let grouped = Dictionary(grouping: magazines) { magazine in
            magazine.resolvedPattern.id
        }

        return grouped
            .compactMap { _, magazines in
                guard let firstMagazine = magazines.first else {
                    return nil
                }

                let pattern = firstMagazine.resolvedPattern
                return MagazinePatternGroup(
                    id: pattern.id,
                    displayName: pattern.displayName,
                    caliberText: pattern.compatibility.supportedCaliberNames.joined(separator: ", "),
                    magazines: magazines
                )
            }
            .sorted {
                switch ($0.primaryCaliberName, $1.primaryCaliberName) {
                case let (lhs?, rhs?):
                    if lhs.caseInsensitiveCompare(rhs) != .orderedSame {
                        return CaliberSort.areInAscendingOrder(lhs, rhs)
                    }
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    break
                }

                let nameComparison = $0.displayName.localizedCaseInsensitiveCompare($1.displayName)
                if nameComparison != .orderedSame {
                    return nameComparison == .orderedAscending
                }

                return $0.id.localizedCaseInsensitiveCompare($1.id) == .orderedAscending
            }
    }
}

private struct MagazinePatternGroup: Identifiable {
    let id: String
    let displayName: String
    let caliberText: String
    let magazines: [Magazine]

    init(id: String, displayName: String, caliberText: String, magazines: [Magazine] = []) {
        self.id = id
        self.displayName = displayName
        self.caliberText = caliberText
        self.magazines = magazines
    }

    var summaryText: String {
        let totalCount = magazines.reduce(0) { $0 + max(0, $1.count) }
        let countText = totalCount == 1 ? "1 magazine" : "\(totalCount) magazines"
        guard !caliberText.isEmpty else {
            return countText
        }

        return "\(caliberText) • \(countText)"
    }

    var primaryCaliberName: String? {
        let caliberNames = caliberText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return caliberNames.first
    }
}
