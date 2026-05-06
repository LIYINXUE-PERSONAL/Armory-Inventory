//
//  InventoryTaxRateProvider.swift
//  Armory Inventory
//
//  Created by Codex on 4/2/26.
//

import Foundation

enum InventoryTaxCategory: CaseIterable, Identifiable {
    case firearms
    case ammo
    case accessories

    var id: Self { self }

    var title: String {
        switch self {
        case .firearms:
            return String(localized: "Firearms")
        case .ammo:
            return String(localized: "Ammo")
        case .accessories:
            return String(localized: "Accessories")
        }
    }
}

enum InventorySettingsKeys {
    static let firearmsSalesTaxRate = "FirearmsSalesTaxRate"
    static let ammoSalesTaxRate = "AmmoSalesTaxRate"
    static let accessoriesSalesTaxRate = "AccessoriesSalesTaxRate"
    static let showValueInDetails = "ShowPurchaseInformation"
    static let showValueInCard = "ShowValueInCard"
    static let showTotalValue = "ShowTotalValue"
    static let firearmSortOrder = "FirearmSortOrder"
    static let firearmSortDirection = "FirearmSortDirection"
    static let caliberSortOrder = "CaliberSortOrder"
    static let caliberSortOrderVersion = "CaliberSortOrderVersion"
    static let attachmentTypeSortOrder = "AttachmentTypeSortOrder"
    static let attachmentTypeSortOrderVersion = "AttachmentTypeSortOrderVersion"
    static let attachmentItemSortOrder = "AttachmentItemSortOrder"
    static let attachmentItemSortDirection = "AttachmentItemSortDirection"
    static let opticTypeSortOrder = "OpticTypeSortOrder"
    static let opticTypeSortOrderVersion = "OpticTypeSortOrderVersion"
    static let opticItemSortOrder = "OpticItemSortOrder"
    static let opticItemSortDirection = "OpticItemSortDirection"
    static let partTypeSortOrder = "PartTypeSortOrder"
    static let partTypeSortOrderVersion = "PartTypeSortOrderVersion"
    static let partItemSortOrder = "PartItemSortOrder"
    static let partItemSortDirection = "PartItemSortDirection"
    static let lastModelSaveDate = "LastModelSaveDate"

    static let managedUserDataKeys: [String] = [
        firearmsSalesTaxRate,
        ammoSalesTaxRate,
        accessoriesSalesTaxRate,
        showValueInDetails,
        showValueInCard,
        showTotalValue,
        firearmSortOrder,
        firearmSortDirection,
        caliberSortOrder,
        caliberSortOrderVersion,
        attachmentTypeSortOrder,
        attachmentTypeSortOrderVersion,
        attachmentItemSortOrder,
        attachmentItemSortDirection,
        opticTypeSortOrder,
        opticTypeSortOrderVersion,
        opticItemSortOrder,
        opticItemSortDirection,
        partTypeSortOrder,
        partTypeSortOrderVersion,
        partItemSortOrder,
        partItemSortDirection,
        lastModelSaveDate
    ]
}

protocol InventoryTaxRateProviding {
    func taxRate(for category: InventoryTaxCategory) -> Double
}

extension InventoryTaxRateProviding {
    var firearmsTaxRate: Double { taxRate(for: .firearms) }
    var ammoTaxRate: Double { taxRate(for: .ammo) }
    var accessoriesTaxRate: Double { taxRate(for: .accessories) }
}

final class UserDefaultsInventoryTaxRateProvider: InventoryTaxRateProviding {
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func taxRate(for category: InventoryTaxCategory) -> Double {
        userDefaults.double(forKey: settingsKey(for: category))
    }

    private func settingsKey(for category: InventoryTaxCategory) -> String {
        switch category {
        case .firearms:
            return InventorySettingsKeys.firearmsSalesTaxRate
        case .ammo:
            return InventorySettingsKeys.ammoSalesTaxRate
        case .accessories:
            return InventorySettingsKeys.accessoriesSalesTaxRate
        }
    }
}
