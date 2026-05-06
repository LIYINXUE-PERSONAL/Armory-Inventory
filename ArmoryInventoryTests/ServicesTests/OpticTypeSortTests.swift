//
//  OpticTypeSortTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/6/26.
//

import XCTest
@testable import ArmoryInventory

final class OpticTypeSortTests: XCTestCase {
    override func setUp() {
        super.setUp()
        OpticTypeSort.resetOrder()
    }

    override func tearDown() {
        OpticTypeSort.resetOrder()
        super.tearDown()
    }

    func testAscendingOrderPrefersConfiguredRankingOverUnknownNames() {
        OpticTypeSort.saveOrder(["lpvo", "reddot", "scope"])

        XCTAssertTrue(OpticTypeSort.areInAscendingOrder("lpvo", "reddot"))
        XCTAssertTrue(OpticTypeSort.areInAscendingOrder("reddot", "customthermal"))
        XCTAssertFalse(OpticTypeSort.areInAscendingOrder("customthermal", "scope"))
    }

    func testDisplayOrderSortsBySavedRankingThenLocalizedFallback() {
        OpticTypeSort.saveOrder(["holographic", "scope"])

        XCTAssertEqual(
            OpticTypeSort.displayOrder(for: ["reddot", "customz", "scope", "holographic", "customa"]),
            ["holographic", "scope", "reddot", "customa", "customz"]
        )
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        OpticTypeSort.saveOrder([" scope ", "customthermal"])

        let persisted = OpticTypeSort.persistedOrder(including: ["lpvo", "custommagnified", "reddot"])

        XCTAssertEqual(
            persisted,
            [
                "scope",
                "customthermal",
                "reddot",
                "holographic",
                "prism",
                "lpvo",
                "magnifier",
                "other",
                "custommagnified"
            ]
        )
    }

    func testPersistedOrderIgnoresLegacyDisplayNamesAndUsesStableIDs() {
        UserDefaults.standard.set(["red dot", "全息", "lpvo"], forKey: InventorySettingsKeys.opticTypeSortOrder)

        let persisted = OpticTypeSort.persistedOrder(including: ["reddot", "holographic", "lpvo"])

        XCTAssertEqual(
            persisted.prefix(3).map(\.self),
            ["lpvo", "reddot", "holographic"]
        )
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        OpticTypeSort.saveOrder(["scope"])
        let versionAfterSave = UserDefaults.standard.integer(forKey: OpticTypeSort.settingsVersionKey)

        OpticTypeSort.resetOrder()

        XCTAssertEqual(
            OpticTypeSort.persistedOrder(),
            OpticType.allCases.map(\.id).map { $0.lowercased() }
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: OpticTypeSort.settingsVersionKey),
            versionAfterSave + 1
        )
    }
}
