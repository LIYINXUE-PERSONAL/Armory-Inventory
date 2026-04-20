//
//  CaliberListViewModel.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation
import SwiftData

final class CaliberListViewModel {
    private let ammoChangeService: AmmoChangeServicing
    private let taxRateProvider: InventoryTaxRateProviding

    init(
        ammoChangeService: AmmoChangeServicing = AppServices.shared.resolve(),
        taxRateProvider: InventoryTaxRateProviding = AppServices.shared.resolve()
    ) {
        self.ammoChangeService = ammoChangeService
        self.taxRateProvider = taxRateProvider
    }

    enum AmmoHistoryPreset: String, CaseIterable, Identifiable {
        case day
        case week
        case month
        case custom

        var id: String { rawValue }

        var title: String {
            switch self {
            case .day:
                return "Day"
            case .week:
                return "Week"
            case .month:
                return "Month"
            case .custom:
                return "Custom"
            }
        }

        var summaryTitle: String {
            switch self {
            case .day:
                return "Today"
            case .week:
                return "This Week"
            case .month:
                return "This Month"
            case .custom:
                return "Custom Range"
            }
        }
    }

    func totalRounds(for caliber: Caliber) -> Int {
        caliber.ammoTypes.reduce(0) { $0 + max(0, $1.quantity) }
    }

    func sortedCalibers(from calibers: [Caliber]) -> [Caliber] {
        calibers.sorted { CaliberSort.areInAscendingOrder($0.name, $1.name) }
    }

    func sortedAmmo(for caliber: Caliber) -> [AmmoType] {
        caliber.ammoTypes.sorted {
            if $0.quantity != $1.quantity {
                return $0.quantity > $1.quantity
            }
            if $0.brand != $1.brand {
                return $0.brand.localizedCaseInsensitiveCompare($1.brand) == .orderedAscending
            }
            if $0.bulletType != $1.bulletType {
                return $0.bulletType.localizedCaseInsensitiveCompare($1.bulletType) == .orderedAscending
            }
            if $0.loadDetail != $1.loadDetail {
                return ($0.loadDetail ?? "").localizedCaseInsensitiveCompare($1.loadDetail ?? "") == .orderedAscending
            }
            return $0.grain < $1.grain
        }
    }

    func inStockSortedAmmo(for caliber: Caliber) -> [AmmoType] {
        sortedAmmo(for: caliber).filter { $0.quantity > 0 }
    }

    func outOfStockSortedAmmo(for caliber: Caliber) -> [AmmoType] {
        sortedAmmo(for: caliber).filter { $0.quantity <= 0 }
    }

    func ammoRows(for caliber: Caliber, includeOutOfStock: Bool) -> [[AmmoType]] {
        let ammo = includeOutOfStock ? sortedAmmo(for: caliber) : inStockSortedAmmo(for: caliber)
        return ammoRows(for: ammo)
    }

    func ammoRows(for ammo: [AmmoType]) -> [[AmmoType]] {
        return stride(from: 0, to: ammo.count, by: 2).map { index in
            Array(ammo[index..<min(index + 2, ammo.count)])
        }
    }

    func totalValueText(for calibers: [Caliber], currencyCode: String) -> String {
        let totalCents = calibers
            .flatMap(\.ammoTypes)
            .reduce(0) { partialResult, ammo in
                partialResult + max(0, ammo.quantity * ammo.centsPerRound)
            }
        let amount = Decimal(totalCents) / 100
        return amount.formatted(.currency(code: currencyCode))
    }

    func updateQuantity(for ammo: AmmoType, to newValue: Int, in context: ModelContext) {
        ammo.quantity = max(0, newValue)
        saveContext(context)
    }

    func adjustQuantity(for ammo: AmmoType, by delta: Int, occurredAt: Date, in context: ModelContext) {
        ammoChangeService.applyChange(to: ammo, delta: delta, occurredAt: occurredAt, in: context)
    }

    func consumptionRange(
        for preset: AmmoHistoryPreset,
        customStartDate: Date,
        customEndDate: Date,
        calendar: Calendar = .current
    ) -> AmmoChangeRange {
        let now = Date()

        switch preset {
        case .day:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return AmmoChangeRange(start: start, end: end)
        case .week:
            let start = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) ?? now
            return AmmoChangeRange(start: start, end: end)
        case .month:
            let start = calendar.dateInterval(of: .month, for: now)?.start ?? calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? now
            return AmmoChangeRange(start: start, end: end)
        case .custom:
            let start = calendar.startOfDay(for: min(customStartDate, customEndDate))
            let normalizedEndDate = calendar.startOfDay(for: max(customStartDate, customEndDate))
            let end = calendar.date(byAdding: .day, value: 1, to: normalizedEndDate) ?? normalizedEndDate
            return AmmoChangeRange(start: start, end: end)
        }
    }

    func ammoHistory(for caliber: Caliber, within range: AmmoChangeRange) -> AmmoChangeSummary {
        ammoChangeService.summary(
            for: caliber,
            within: range,
            taxRate: taxRateProvider.ammoTaxRate
        )
    }

    func consumptionSummary(
        for preset: AmmoHistoryPreset,
        range: AmmoChangeRange,
        calendar: Calendar = .current
    ) -> String {
        switch preset {
        case .day, .week, .month:
            return preset.summaryTitle
        case .custom:
            let formatter = DateFormatter()
            formatter.calendar = calendar
            formatter.dateStyle = .medium
            formatter.timeStyle = .none

            let inclusiveEndDate = calendar.date(byAdding: .day, value: -1, to: range.end) ?? range.end
            return "\(formatter.string(from: range.start)) - \(formatter.string(from: inclusiveEndDate))"
        }
    }

    func currencyString(for cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        let amount = NSDecimalNumber(value: cents).dividing(by: 100)
        return formatter.string(from: amount) ?? "$0.00"
    }

    func deleteAmmo(_ ammo: AmmoType, in context: ModelContext) {
        context.delete(ammo)
        saveContext(context)
    }

    func shouldClearSelectedCaliber(_ selectedID: PersistentIdentifier?, deleting caliber: Caliber) -> Bool {
        selectedID == caliber.persistentModelID
    }

    func hasLinkedFirearms(_ caliber: Caliber) -> Bool {
        !caliber.firearms.isEmpty
    }

    func deleteCaliber(_ caliber: Caliber, in context: ModelContext) {
        context.delete(caliber)
        saveContext(context)
    }

    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
        } catch {
            print("Save error: \(error)")
        }
    }
}
