//
//  CaliberSort.swift
//  Armory Inventory
//
//  Created by Yinxue Li on 4/2/26.
//

import Foundation

enum CaliberSort {
    nonisolated static func areInAscendingOrder(_ lhs: String, _ rhs: String) -> Bool {
        let lhsRank = rank(for: lhs)
        let rhsRank = rank(for: rhs)

        switch (lhsRank, rhsRank) {
        case let (lhsRank?, rhsRank?):
            if lhsRank != rhsRank {
                return lhsRank < rhsRank
            }
        case (.some, .none):
            return true
        case (.none, .some):
            return false
        case (.none, .none):
            break
        }

        return lhs.localizedStandardCompare(rhs) == .orderedAscending
    }

    nonisolated static func displayOrder(for caliberNames: [String]) -> [String] {
        caliberNames.sorted(by: areInAscendingOrder)
    }

    nonisolated static func persistedOrder(including caliberNames: [String] = []) -> [String] {
        let names = caliberNames.map(normalize(caliberName:))
        let savedOrder = UserDefaults.standard.stringArray(forKey: settingsKey)?.map(normalize(caliberName:)) ?? []
        let knownNames = defaultOrder.filter { !savedOrder.contains($0) }
        let customNames = names.filter { !savedOrder.contains($0) && !knownNames.contains($0) }
        return savedOrder + knownNames + customNames.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    nonisolated static func saveOrder(_ caliberNames: [String]) {
        let normalized = caliberNames.map(normalize(caliberName:))
        UserDefaults.standard.set(normalized, forKey: settingsKey)
        let nextVersion = UserDefaults.standard.integer(forKey: settingsVersionKey) + 1
        UserDefaults.standard.set(nextVersion, forKey: settingsVersionKey)
    }

    nonisolated static func resetOrder() {
        UserDefaults.standard.removeObject(forKey: settingsKey)
        let nextVersion = UserDefaults.standard.integer(forKey: settingsVersionKey) + 1
        UserDefaults.standard.set(nextVersion, forKey: settingsVersionKey)
    }

    nonisolated static let settingsVersionKey = InventorySettingsKeys.caliberSortOrderVersion

    nonisolated private static func rank(for caliberName: String) -> Int? {
        let normalizedName = normalize(caliberName: caliberName)
        return currentOrder.firstIndex(of: normalizedName)
    }

    nonisolated private static func normalize(caliberName: String) -> String {
        caliberName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    nonisolated private static var currentOrder: [String] {
        persistedOrder()
    }

    nonisolated private static let settingsKey = InventorySettingsKeys.caliberSortOrder

    nonisolated private static let defaultOrder: [String] = [
        ".22 lr",
        ".223 rem",
        "5.56 nato",
        ".300 blackout",
        "7.62x39",
        "6.5 creedmoor",
        ".308 win",
        ".380 acp",
        "9mm",
        ".40 s&w",
        ".45 acp",
        "12 gauge"
    ]
}
