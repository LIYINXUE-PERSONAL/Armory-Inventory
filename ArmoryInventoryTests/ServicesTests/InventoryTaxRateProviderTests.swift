//
//  InventoryTaxRateProviderTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
@testable import ArmoryInventory

final class InventoryTaxRateProviderTests: XCTestCase {
    @MainActor
    func testInventoryTaxCategoryCasesIDsAndTitles() {
        XCTAssertEqual(InventoryTaxCategory.allCases, [.firearms, .ammo, .accessories])
        XCTAssertEqual(InventoryTaxCategory.firearms.id, .firearms)
        XCTAssertEqual(InventoryTaxCategory.ammo.id, .ammo)
        XCTAssertEqual(InventoryTaxCategory.accessories.id, .accessories)
        XCTAssertEqual(InventoryTaxCategory.firearms.title, "Firearms")
        XCTAssertEqual(InventoryTaxCategory.ammo.title, "Ammo")
        XCTAssertEqual(InventoryTaxCategory.accessories.title, "Accessories")
    }

    func testProviderReadsConfiguredAmmoTaxRate() {
        let suiteName = "InventoryTaxRateProviderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(8.25, forKey: InventorySettingsKeys.ammoSalesTaxRate)

        let provider = UserDefaultsInventoryTaxRateProvider(userDefaults: defaults)

        XCTAssertEqual(provider.taxRate(for: .ammo), 8.25)
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testProviderReadsConfiguredCategorySpecificRates() {
        let suiteName = "InventoryTaxRateProviderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(6.5, forKey: InventorySettingsKeys.firearmsSalesTaxRate)
        defaults.set(9.0, forKey: InventorySettingsKeys.accessoriesSalesTaxRate)

        let provider = UserDefaultsInventoryTaxRateProvider(userDefaults: defaults)

        XCTAssertEqual(provider.taxRate(for: .firearms), 6.5)
        XCTAssertEqual(provider.taxRate(for: .accessories), 9.0)
        defaults.removePersistentDomain(forName: suiteName)
    }

    @MainActor
    func testProviderConveniencePropertiesReadExpectedCategories() {
        let suiteName = "InventoryTaxRateProviderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.set(6.5, forKey: InventorySettingsKeys.firearmsSalesTaxRate)
        defaults.set(8.25, forKey: InventorySettingsKeys.ammoSalesTaxRate)
        defaults.set(9.75, forKey: InventorySettingsKeys.accessoriesSalesTaxRate)

        let provider: InventoryTaxRateProviding = UserDefaultsInventoryTaxRateProvider(userDefaults: defaults)

        XCTAssertEqual(provider.firearmsTaxRate, 6.5)
        XCTAssertEqual(provider.ammoTaxRate, 8.25)
        XCTAssertEqual(provider.accessoriesTaxRate, 9.75)
        defaults.removePersistentDomain(forName: suiteName)
    }

    func testProviderDefaultsToZeroWhenUnset() {
        let suiteName = "InventoryTaxRateProviderTests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!

        let provider = UserDefaultsInventoryTaxRateProvider(userDefaults: defaults)

        XCTAssertEqual(provider.taxRate(for: .firearms), 0)
        XCTAssertEqual(provider.taxRate(for: .ammo), 0)
        XCTAssertEqual(provider.taxRate(for: .accessories), 0)
        defaults.removePersistentDomain(forName: suiteName)
    }
}
