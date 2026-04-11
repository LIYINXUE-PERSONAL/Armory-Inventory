//
//  AccessoryItemSort.swift
//  Armory Inventory
//
//  Created by Codex on 4/6/26.
//

import Foundation

enum AccessoryItemSortOrder: String, CaseIterable, Identifiable {
    case manual
    case purchaseDate
    case value
    case brand
    case model

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .manual:
            return "Manual"
        case .purchaseDate:
            return "Purchase Date"
        case .value:
            return "Value"
        case .brand:
            return "Brand"
        case .model:
            return "Model"
        }
    }
}

enum AccessoryItemSortDirection: String, CaseIterable, Identifiable {
    case ascending
    case descending

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ascending:
            return "Ascending"
        case .descending:
            return "Descending"
        }
    }
}

protocol AccessorySortableItem {
    var brand: String { get }
    var modelName: String { get }
    var purchaseDate: Date { get }
    var purchasePriceCents: Int { get }
    var displayName: String { get }
}

enum AccessoryItemSort {
    static func sorted<T: AccessorySortableItem>(
        _ items: [T],
        by sortOrder: AccessoryItemSortOrder,
        direction: AccessoryItemSortDirection
    ) -> [T] {
        switch sortOrder {
        case .manual:
            return items
        case .purchaseDate:
            return items.sorted {
                if $0.purchaseDate != $1.purchaseDate {
                    return compare($0.purchaseDate, $1.purchaseDate, direction: direction)
                }
                return compareNames($0.displayName, $1.displayName, direction: direction)
            }
        case .value:
            return items.sorted {
                if $0.purchasePriceCents != $1.purchasePriceCents {
                    return compare($0.purchasePriceCents, $1.purchasePriceCents, direction: direction)
                }
                return compareNames($0.displayName, $1.displayName, direction: direction)
            }
        case .brand:
            return items.sorted {
                let brandComparison = $0.brand.localizedStandardCompare($1.brand)
                if brandComparison != .orderedSame {
                    return compare(brandComparison, direction: direction)
                }
                return compareNames($0.modelName, $1.modelName, direction: direction)
            }
        case .model:
            return items.sorted {
                let modelComparison = $0.modelName.localizedStandardCompare($1.modelName)
                if modelComparison != .orderedSame {
                    return compare(modelComparison, direction: direction)
                }
                return compareNames($0.brand, $1.brand, direction: direction)
            }
        }
    }

    static func preferredDirection(for sortOrder: AccessoryItemSortOrder) -> AccessoryItemSortDirection {
        switch sortOrder {
        case .manual:
            return .ascending
        case .purchaseDate, .value:
            return .descending
        case .brand, .model:
            return .ascending
        }
    }

    private static func compare<T: Comparable>(_ lhs: T, _ rhs: T, direction: AccessoryItemSortDirection) -> Bool {
        switch direction {
        case .ascending:
            return lhs < rhs
        case .descending:
            return lhs > rhs
        }
    }

    private static func compare(_ comparison: ComparisonResult, direction: AccessoryItemSortDirection) -> Bool {
        switch direction {
        case .ascending:
            return comparison == .orderedAscending
        case .descending:
            return comparison == .orderedDescending
        }
    }

    private static func compareNames(_ lhs: String, _ rhs: String, direction: AccessoryItemSortDirection) -> Bool {
        compare(lhs.localizedStandardCompare(rhs), direction: direction)
    }
}

extension Attachment: AccessorySortableItem {}
extension Optic: AccessorySortableItem {}
extension Part: AccessorySortableItem {}
