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
        OpticTypeSort.saveOrder(["LPVO", "Red Dot", "Scope"])

        XCTAssertTrue(OpticTypeSort.areInAscendingOrder("LPVO", "Red Dot"))
        XCTAssertTrue(OpticTypeSort.areInAscendingOrder("Red Dot", "Custom Thermal"))
        XCTAssertFalse(OpticTypeSort.areInAscendingOrder("Custom Thermal", "Scope"))
    }

    func testDisplayOrderSortsBySavedRankingThenLocalizedFallback() {
        OpticTypeSort.saveOrder(["Holographic", "Scope"])

        XCTAssertEqual(
            OpticTypeSort.displayOrder(for: ["Red Dot", "Custom Z", "Scope", "Holographic", "Custom A"]),
            ["Holographic", "Scope", "Red Dot", "Custom A", "Custom Z"]
        )
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        OpticTypeSort.saveOrder([" scope ", "custom thermal"])

        let persisted = OpticTypeSort.persistedOrder(including: ["LPVO", "Custom Magnified", "Red Dot"])

        XCTAssertEqual(
            persisted,
            [
                "scope",
                "custom thermal",
                "red dot",
                "holographic",
                "prism",
                "lpvo",
                "magnifier",
                "other",
                "custom magnified"
            ]
        )
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        OpticTypeSort.saveOrder(["Scope"])
        let versionAfterSave = UserDefaults.standard.integer(forKey: OpticTypeSort.settingsVersionKey)

        OpticTypeSort.resetOrder()

        XCTAssertEqual(
            OpticTypeSort.persistedOrder(),
            OpticType.allCases.map(\.displayName).map { $0.lowercased() }
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: OpticTypeSort.settingsVersionKey),
            versionAfterSave + 1
        )
    }
}
