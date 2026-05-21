//
//  FirearmsViewModel.swift
//  Armory Inventory
//
//  Created by Codex on 5/20/26.
//

import Foundation
import SwiftData

final class FirearmsViewModel {
    func selectedSortOrder(from rawValue: String) -> FirearmSortOrder {
        FirearmSortOrder(rawValue: rawValue) ?? .manual
    }

    func selectedSortDirection(from rawValue: String, sortOrder: FirearmSortOrder) -> FirearmSortDirection {
        FirearmSortDirection(rawValue: rawValue) ?? preferredDirection(for: sortOrder)
    }

    func preferredDirection(for sortOrder: FirearmSortOrder) -> FirearmSortDirection {
        switch sortOrder {
        case .manual:
            return .ascending
        case .purchaseDate, .value, .barrelLength:
            return .descending
        case .brand, .caliber, .type:
            return .ascending
        }
    }

    func filteredFirearms(
        _ firearms: [Firearm],
        kits: [Kit],
        magazines: [Magazine],
        selectedTypeFilter: FirearmType?,
        selectedActionFilter: FirearmAction?,
        selectedCaliberFilter: Caliber?,
        sortOrder: FirearmSortOrder,
        sortDirection: FirearmSortDirection
    ) -> [Firearm] {
        let filtered = firearms.filter {
            matchesFilters(
                $0,
                selectedTypeFilter: selectedTypeFilter,
                selectedActionFilter: selectedActionFilter,
                selectedCaliberFilter: selectedCaliberFilter
            )
        }

        switch sortOrder {
        case .manual:
            return filtered
        case .purchaseDate:
            return filtered.sorted {
                if $0.purchaseDate != $1.purchaseDate {
                    return compare($0.purchaseDate, $1.purchaseDate, direction: sortDirection)
                }
                return compareNames($0.displayName, $1.displayName, direction: sortDirection)
            }
        case .value:
            return filtered.sorted {
                let lhs = effectiveValueCents(for: $0, kits: kits, magazines: magazines)
                let rhs = effectiveValueCents(for: $1, kits: kits, magazines: magazines)
                if lhs != rhs {
                    return compare(lhs, rhs, direction: sortDirection)
                }
                return compareNames($0.displayName, $1.displayName, direction: sortDirection)
            }
        case .barrelLength:
            return filtered.sorted {
                let lhs = $0.barrelLengthInches ?? -1
                let rhs = $1.barrelLengthInches ?? -1
                if lhs != rhs {
                    return compare(lhs, rhs, direction: sortDirection)
                }
                return compareNames($0.displayName, $1.displayName, direction: sortDirection)
            }
        case .brand:
            return filtered.sorted {
                let brandComparison = $0.brand.localizedStandardCompare($1.brand)
                if brandComparison != .orderedSame {
                    return compare(brandComparison, direction: sortDirection)
                }
                return compareNames($0.modelName, $1.modelName, direction: sortDirection)
            }
        case .caliber:
            return filtered.sorted {
                let lhs = $0.caliber?.name ?? ""
                let rhs = $1.caliber?.name ?? ""
                let caliberComparison = lhs.localizedStandardCompare(rhs)
                if caliberComparison != .orderedSame {
                    return compare(caliberComparison, direction: sortDirection)
                }
                return compareNames($0.displayName, $1.displayName, direction: sortDirection)
            }
        case .type:
            return filtered.sorted {
                let typeComparison = $0.firearmType.displayName.localizedStandardCompare($1.firearmType.displayName)
                if typeComparison != .orderedSame {
                    return compare(typeComparison, direction: sortDirection)
                }
                return compareNames($0.displayName, $1.displayName, direction: sortDirection)
            }
        }
    }

    func matchesFilters(
        _ firearm: Firearm,
        selectedTypeFilter: FirearmType?,
        selectedActionFilter: FirearmAction?,
        selectedCaliberFilter: Caliber?
    ) -> Bool {
        let matchesType = selectedTypeFilter == nil || firearm.firearmType == selectedTypeFilter
        let matchesAction = selectedActionFilter == nil || firearm.firearmAction == selectedActionFilter
        let matchesCaliber = selectedCaliberFilter == nil || firearm.caliber?.persistentModelID == selectedCaliberFilter?.persistentModelID
        return matchesType && matchesAction && matchesCaliber
    }

    func countForType(_ firearmType: FirearmType, in firearms: [Firearm]) -> Int {
        firearms.count { $0.firearmType == firearmType }
    }

    func countForAction(_ action: FirearmAction, in firearms: [Firearm]) -> Int {
        firearms.count { $0.firearmAction == action }
    }

    func countForCaliber(_ caliber: Caliber, in firearms: [Firearm]) -> Int {
        firearms.count { $0.caliber?.persistentModelID == caliber.persistentModelID }
    }

    func availableCalibers(from firearms: [Firearm]) -> [Caliber] {
        var calibersByID: [PersistentIdentifier: Caliber] = [:]
        for firearm in firearms {
            if let caliber = firearm.caliber {
                calibersByID[caliber.persistentModelID] = caliber
            }
        }
        return calibersByID.values.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    func totalValueText(for firearms: [Firearm], kits: [Kit], magazines: [Magazine]) -> String {
        let totalCents = firearms.reduce(0) { $0 + effectiveValueCents(for: $1, kits: kits, magazines: magazines) }
        return currencyText(for: totalCents)
    }

    func allTypesCountText(for firearms: [Firearm]) -> String {
        String.localizedStringWithFormat(
            String(localized: "All Types (%@)"),
            firearms.count.localizedCountString
        )
    }

    func allActionsCountText(for firearms: [Firearm]) -> String {
        String.localizedStringWithFormat(
            String(localized: "All Actions (%@)"),
            firearms.count.localizedCountString
        )
    }

    func allCalibersCountText(for firearms: [Firearm]) -> String {
        String.localizedStringWithFormat(
            String(localized: "All Calibers (%@)"),
            firearms.count.localizedCountString
        )
    }

    func filterCountText(title: String, count: Int) -> String {
        String.localizedStringWithFormat(
            String(localized: "%@ (%@)"),
            title,
            count.localizedCountString
        )
    }

    func linkedKits(for firearm: Firearm, kits: [Kit]) -> [Kit] {
        kits.filter { $0.firearm?.persistentModelID == firearm.persistentModelID }
    }

    func compatibleMagazines(for firearm: Firearm, magazines: [Magazine]) -> [Magazine] {
        magazines.filter { magazine in
            magazine.linkedFirearms(from: [firearm]).contains {
                $0.persistentModelID == firearm.persistentModelID
            }
        }
    }

    func effectiveValueCents(for firearm: Firearm, kits: [Kit], magazines: [Magazine]) -> Int {
        KitValueService.effectiveTotalValueCents(
            for: firearm,
            linkedKits: linkedKits(for: firearm, kits: kits),
            compatibleMagazines: compatibleMagazines(for: firearm, magazines: magazines)
        )
    }

    func moveFirearms(
        allFirearms firearms: [Firearm],
        filteredFirearms: [Firearm],
        selectedTypeFilter: FirearmType?,
        selectedActionFilter: FirearmAction?,
        selectedCaliberFilter: Caliber?,
        sortOrder: FirearmSortOrder,
        source: IndexSet,
        destination: Int,
        in context: ModelContext
    ) -> KitValidationResult {
        guard sortOrder == .manual else {
            return .valid
        }

        let reorderedFirearms = reorderedFirearms(
            allFirearms: firearms,
            filteredFirearms: filteredFirearms,
            selectedTypeFilter: selectedTypeFilter,
            selectedActionFilter: selectedActionFilter,
            selectedCaliberFilter: selectedCaliberFilter,
            source: source,
            destination: destination
        )
        applySortOrder(to: reorderedFirearms)

        do {
            try context.save()
            UserDefaults.standard.set(Date(), forKey: "LastModelSaveDate")
            return .valid
        } catch {
            return .invalid(error.localizedDescription)
        }
    }

    func reorderedFirearms(
        allFirearms firearms: [Firearm],
        filteredFirearms: [Firearm],
        selectedTypeFilter: FirearmType?,
        selectedActionFilter: FirearmAction?,
        selectedCaliberFilter: Caliber?,
        source: IndexSet,
        destination: Int
    ) -> [Firearm] {
        let reorderedFilteredFirearms = movingItems(in: filteredFirearms, from: source, to: destination)

        var reorderedFilteredIterator = reorderedFilteredFirearms.makeIterator()
        return firearms.map { firearm in
            guard matchesFilters(
                firearm,
                selectedTypeFilter: selectedTypeFilter,
                selectedActionFilter: selectedActionFilter,
                selectedCaliberFilter: selectedCaliberFilter
            ) else {
                return firearm
            }

            return reorderedFilteredIterator.next() ?? firearm
        }
    }

    func applySortOrder(to firearms: [Firearm]) {
        for (index, firearm) in firearms.enumerated() {
            firearm.sortOrder = index
        }
    }

    private func currencyText(for cents: Int) -> String {
        let amount = Decimal(cents) / 100
        return amount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))
    }

    private func compare<T: Comparable>(_ lhs: T, _ rhs: T, direction: FirearmSortDirection) -> Bool {
        switch direction {
        case .ascending:
            return lhs < rhs
        case .descending:
            return lhs > rhs
        }
    }

    private func compare(_ comparison: ComparisonResult, direction: FirearmSortDirection) -> Bool {
        switch direction {
        case .ascending:
            return comparison == .orderedAscending
        case .descending:
            return comparison == .orderedDescending
        }
    }

    private func compareNames(_ lhs: String, _ rhs: String, direction: FirearmSortDirection) -> Bool {
        compare(lhs.localizedStandardCompare(rhs), direction: direction)
    }

    private func movingItems(in firearms: [Firearm], from source: IndexSet, to destination: Int) -> [Firearm] {
        guard !source.isEmpty else {
            return firearms
        }

        var reorderedFirearms = firearms
        let sourceIndexes = source.sorted()
        let movingFirearms = sourceIndexes.map { reorderedFirearms[$0] }

        for index in sourceIndexes.reversed() {
            reorderedFirearms.remove(at: index)
        }

        let insertionIndex = destination - sourceIndexes.count { $0 < destination }
        reorderedFirearms.insert(contentsOf: movingFirearms, at: max(0, min(insertionIndex, reorderedFirearms.count)))
        return reorderedFirearms
    }
}
