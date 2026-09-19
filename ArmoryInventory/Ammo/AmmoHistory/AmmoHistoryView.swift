//
//  AmmoHistoryView.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import SwiftUI
import SwiftData

struct AmmoHistoryView: View {
    @Query private var calibers: [Caliber]
    @AppStorage(CaliberSort.settingsVersionKey) private var sortVersion = 0
    @State private var historyPreset: CaliberListViewModel.AmmoHistoryPreset = .week
    @State private var customStartDate = Date()
    @State private var customEndDate = Date()
    let viewModel: CaliberListViewModel

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                historyFilterCard

                ForEach(sortedCalibers) { caliber in
                    let ammoHistory = history(for: caliber)

                    VStack(alignment: .leading, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(caliber.name)
                                .font(.title3.weight(.semibold))
                            Text(consumptionSummary)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            historyMetric(
                                title: "Purchased",
                                value: ammoHistory.purchased,
                                amountCents: ammoHistory.purchasedAmountCents,
                                tint: Color(red: 0.14, green: 0.45, blue: 0.28)
                            )
                            historyMetric(
                                title: "Consumed",
                                value: ammoHistory.consumed,
                                amountCents: ammoHistory.consumedAmountCents,
                                tint: Color(red: 0.66, green: 0.20, blue: 0.32)
                            )
                        }

                        Text("\(AmmoType.roundsText(for: viewModel.totalRounds(for: caliber))) currently on hand")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
            .padding()
        }
        .navigationTitle("Ammo History")
    }

    private var sortedCalibers: [Caliber] {
        _ = sortVersion
        return viewModel.sortedCalibers(from: calibers)
    }

    private var selectedHistoryRange: AmmoChangeRange {
        viewModel.consumptionRange(
            for: historyPreset,
            customStartDate: customStartDate,
            customEndDate: customEndDate
        )
    }

    private var consumptionSummary: String {
        viewModel.consumptionSummary(for: historyPreset, range: selectedHistoryRange)
    }

    private func history(for caliber: Caliber) -> AmmoChangeSummary {
        viewModel.ammoHistory(for: caliber, within: selectedHistoryRange)
    }

    private var historyFilterCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("View rounds purchased and consumed by caliber for a selected period.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Picker("Range", selection: $historyPreset) {
                ForEach(CaliberListViewModel.AmmoHistoryPreset.allCases) { preset in
                    Text(preset.title).tag(preset)
                }
            }
            .pickerStyle(.segmented)

            if historyPreset == .custom {
                HStack(alignment: .top, spacing: 12) {
                    DatePicker("From", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("To", selection: $customEndDate, displayedComponents: .date)
                }
                .datePickerStyle(.compact)
            }

            Text(consumptionSummary)
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func historyMetric(title: String, value: Int, amountCents: Int, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value, format: .number)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
            Text(currencyString(for: amountCents))
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func currencyString(for cents: Int) -> String {
        viewModel.currencyString(for: cents)
    }
}

#Preview {
    let preview = AmmoHistoryPreviewer()
    return NavigationStack {
        AmmoHistoryView(viewModel: CaliberListViewModel())
    }
    .modelContainer(preview.container)
}

@MainActor
private struct AmmoHistoryPreviewer {
    let container: ModelContainer

    init() {
        let schema = Schema([Caliber.self, AmmoType.self, AmmoAdjustmentRecord.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: [config])
        let nine = Caliber(name: "9mm")
        let twoTwoThree = Caliber(name: ".223 Rem")
        container.mainContext.insert(nine)
        container.mainContext.insert(twoTwoThree)
        let federal = AmmoType(brand: "Federal", bulletType: "FMJ", grain: 115, quantity: 250, caliber: nine)
        let hornady = AmmoType(brand: "Hornady", bulletType: "JHP", grain: 124, quantity: 50, caliber: nine)
        let pmc = AmmoType(brand: "PMC", bulletType: "FMJ", grain: 55, quantity: 180, caliber: twoTwoThree)
        container.mainContext.insert(federal)
        container.mainContext.insert(hornady)
        container.mainContext.insert(pmc)
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 300, kind: .purchase, caliber: nine, ammoType: federal))
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 75, kind: .consumption, caliber: nine, ammoType: federal))
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 50, kind: .purchase, caliber: nine, ammoType: hornady))
        container.mainContext.insert(AmmoAdjustmentRecord(quantity: 20, kind: .consumption, caliber: nine, ammoType: hornady))
        container.mainContext.insert(
            AmmoAdjustmentRecord(
                quantity: 180,
                occurredAt: Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now,
                kind: .purchase,
                caliber: twoTwoThree,
                ammoType: pmc
            )
        )
        container.mainContext.insert(
            AmmoAdjustmentRecord(
                quantity: 40,
                occurredAt: Calendar.current.date(byAdding: .day, value: -3, to: .now) ?? .now,
                kind: .consumption,
                caliber: twoTwoThree,
                ammoType: pmc
            )
        )
    }
}
