//
//  AccessoryItemSortTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/6/26.
//

import XCTest
@testable import ArmoryInventory

final class AccessoryItemSortTests: XCTestCase {
    func testPreferredDirectionMatchesSortOrder() {
        XCTAssertEqual(AccessoryItemSort.preferredDirection(for: .manual), .ascending)
        XCTAssertEqual(AccessoryItemSort.preferredDirection(for: .purchaseDate), .descending)
        XCTAssertEqual(AccessoryItemSort.preferredDirection(for: .value), .descending)
        XCTAssertEqual(AccessoryItemSort.preferredDirection(for: .brand), .ascending)
        XCTAssertEqual(AccessoryItemSort.preferredDirection(for: .model), .ascending)
    }

    func testManualSortPreservesInputOrder() {
        let items = [
            makeOptic(brand: "Vortex", model: "Razor", purchaseDate: 300, price: 100_000),
            makeOptic(brand: "Aimpoint", model: "T-2", purchaseDate: 100, price: 80_000),
            makeOptic(brand: "EOTech", model: "EXPS3", purchaseDate: 200, price: 70_000)
        ]

        let sorted = AccessoryItemSort.sorted(items, by: .manual, direction: .ascending)

        XCTAssertEqual(sorted.map(\.displayName), ["Vortex Razor", "Aimpoint T-2", "EOTech EXPS3"])
    }

    func testPurchaseDateSortUsesDirectionAndNameFallback() {
        let items = [
            makeOptic(brand: "Vortex", model: "Razor", purchaseDate: 200, price: 100_000),
            makeOptic(brand: "Aimpoint", model: "T-2", purchaseDate: 300, price: 80_000),
            makeOptic(brand: "EOTech", model: "EXPS3", purchaseDate: 300, price: 70_000)
        ]

        let descending = AccessoryItemSort.sorted(items, by: .purchaseDate, direction: .descending)
        let ascending = AccessoryItemSort.sorted(items, by: .purchaseDate, direction: .ascending)

        XCTAssertEqual(descending.map(\.displayName), ["EOTech EXPS3", "Aimpoint T-2", "Vortex Razor"])
        XCTAssertEqual(ascending.map(\.displayName), ["Vortex Razor", "Aimpoint T-2", "EOTech EXPS3"])
    }

    func testValueSortUsesDirectionAndNameFallback() {
        let items = [
            makeOptic(brand: "Vortex", model: "Razor", purchaseDate: 300, price: 100_000),
            makeOptic(brand: "Aimpoint", model: "T-2", purchaseDate: 100, price: 80_000),
            makeOptic(brand: "EOTech", model: "EXPS3", purchaseDate: 200, price: 80_000)
        ]

        let descending = AccessoryItemSort.sorted(items, by: .value, direction: .descending)
        let ascending = AccessoryItemSort.sorted(items, by: .value, direction: .ascending)

        XCTAssertEqual(descending.map(\.displayName), ["Vortex Razor", "EOTech EXPS3", "Aimpoint T-2"])
        XCTAssertEqual(ascending.map(\.displayName), ["Aimpoint T-2", "EOTech EXPS3", "Vortex Razor"])
    }

    func testBrandAndModelSortUseConfiguredDirection() {
        let items = [
            makeOptic(brand: "Vortex", model: "Razor", purchaseDate: 300, price: 100_000),
            makeOptic(brand: "Aimpoint", model: "CompM5", purchaseDate: 100, price: 90_000),
            makeOptic(brand: "Aimpoint", model: "T-2", purchaseDate: 200, price: 80_000)
        ]

        let brandSorted = AccessoryItemSort.sorted(items, by: .brand, direction: .ascending)
        let modelSorted = AccessoryItemSort.sorted(items, by: .model, direction: .descending)

        XCTAssertEqual(brandSorted.map(\.displayName), ["Aimpoint CompM5", "Aimpoint T-2", "Vortex Razor"])
        XCTAssertEqual(modelSorted.map(\.displayName), ["Aimpoint T-2", "Vortex Razor", "Aimpoint CompM5"])
    }

    private func makeOptic(brand: String, model: String, purchaseDate: TimeInterval, price: Int) -> Optic {
        Optic(
            brand: brand,
            modelName: model,
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchaseDate: Date(timeIntervalSince1970: purchaseDate),
            purchasePriceCents: price
        )
    }
}
