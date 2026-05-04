//
//  PartTypeSortTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/6/26.
//

import XCTest
@testable import ArmoryInventory

final class PartTypeSortTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PartTypeSort.resetOrder()
    }

    override func tearDown() {
        PartTypeSort.resetOrder()
        super.tearDown()
    }

    func testAscendingOrderPrefersConfiguredRankingOverUnknownNames() {
        PartTypeSort.saveOrder(["trigger", "barrel", "slide"])

        XCTAssertTrue(PartTypeSort.areInAscendingOrder("trigger", "barrel"))
        XCTAssertTrue(PartTypeSort.areInAscendingOrder("barrel", "custom tuning kit"))
        XCTAssertFalse(PartTypeSort.areInAscendingOrder("custom tuning kit", "slide"))
    }

    func testDisplayOrderSortsBySavedRankingThenLocalizedFallback() {
        PartTypeSort.saveOrder(["charginghandle", "lowerreceiver"])

        XCTAssertEqual(
            PartTypeSort.displayOrder(for: ["trigger", "Custom Z", "lowerreceiver", "charginghandle", "Custom A"]),
            ["charginghandle", "lowerreceiver", "trigger", "Custom A", "Custom Z"]
        )
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        PartTypeSort.saveOrder([" barrel ", "custom internals"])

        let persisted = PartTypeSort.persistedOrder(including: ["trigger", "Custom Buffer", "slide"])

        XCTAssertEqual(
            persisted,
            [
                "barrel",
                "custom internals",
                "trigger",
                "slide",
                "boltcarriergroup",
                "charginghandle",
                "upperreceiver",
                "lowerreceiver",
                "recoilsystem",
                "internals",
                "other",
                "custom buffer"
            ]
        )
    }

    func testPersistedOrderIgnoresLegacyDisplayNamesAndUsesStableIDs() {
        UserDefaults.standard.set(["trigger", "barrel", "charging handle"], forKey: InventorySettingsKeys.partTypeSortOrder)

        let persisted = PartTypeSort.persistedOrder(including: ["trigger", "barrel", "slide"])

        XCTAssertEqual(
            persisted.prefix(3).map(\.self),
            ["trigger", "barrel", "slide"]
        )
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        PartTypeSort.saveOrder(["trigger"])
        let versionAfterSave = UserDefaults.standard.integer(forKey: PartTypeSort.settingsVersionKey)

        PartTypeSort.resetOrder()

        XCTAssertEqual(
            PartTypeSort.persistedOrder(),
            PartType.allCases.map(\.id).map { $0.lowercased() }
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: PartTypeSort.settingsVersionKey),
            versionAfterSave + 1
        )
    }
}
