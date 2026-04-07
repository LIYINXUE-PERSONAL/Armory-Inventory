//
//  OpticTypeSort.swift
//  Armory Inventory
//
//  Created by Codex on 4/6/26.
//

import Foundation

enum OpticTypeSort {
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

    nonisolated static func displayOrder(for typeNames: [String]) -> [String] {
        typeNames.sorted(by: areInAscendingOrder)
    }

    nonisolated static func persistedOrder(including typeNames: [String] = []) -> [String] {
        let names = typeNames.map(normalize(typeName:))
        let savedOrder = UserDefaults.standard.stringArray(forKey: settingsKey)?.map(normalize(typeName:)) ?? []
        let knownNames = defaultOrder.filter { !savedOrder.contains($0) }
        let customNames = names.filter { !savedOrder.contains($0) && !knownNames.contains($0) }
        return savedOrder + knownNames + customNames.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    nonisolated static func saveOrder(_ typeNames: [String]) {
        let normalized = typeNames.map(normalize(typeName:))
        UserDefaults.standard.set(normalized, forKey: settingsKey)
        let nextVersion = UserDefaults.standard.integer(forKey: settingsVersionKey) + 1
        UserDefaults.standard.set(nextVersion, forKey: settingsVersionKey)
    }

    nonisolated static func resetOrder() {
        UserDefaults.standard.removeObject(forKey: settingsKey)
        let nextVersion = UserDefaults.standard.integer(forKey: settingsVersionKey) + 1
        UserDefaults.standard.set(nextVersion, forKey: settingsVersionKey)
    }

    nonisolated static let settingsVersionKey = InventorySettingsKeys.opticTypeSortOrderVersion

    nonisolated private static func rank(for typeName: String) -> Int? {
        let normalizedName = normalize(typeName: typeName)
        return currentOrder.firstIndex(of: normalizedName)
    }

    nonisolated private static func normalize(typeName: String) -> String {
        typeName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    nonisolated private static var currentOrder: [String] {
        persistedOrder()
    }

    nonisolated private static let settingsKey = InventorySettingsKeys.opticTypeSortOrder

    nonisolated private static let defaultOrder: [String] = OpticType.allCases.map {
        normalize(typeName: $0.displayName)
    }
}
