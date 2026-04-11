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
        PartTypeSort.saveOrder(["Trigger", "Barrel", "Slide"])

        XCTAssertTrue(PartTypeSort.areInAscendingOrder("Trigger", "Barrel"))
        XCTAssertTrue(PartTypeSort.areInAscendingOrder("Barrel", "Custom Tuning Kit"))
        XCTAssertFalse(PartTypeSort.areInAscendingOrder("Custom Tuning Kit", "Slide"))
    }

    func testDisplayOrderSortsBySavedRankingThenLocalizedFallback() {
        PartTypeSort.saveOrder(["Charging Handle", "Lower Receiver"])

        XCTAssertEqual(
            PartTypeSort.displayOrder(for: ["Trigger", "Custom Z", "Lower Receiver", "Charging Handle", "Custom A"]),
            ["Charging Handle", "Lower Receiver", "Trigger", "Custom A", "Custom Z"]
        )
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        PartTypeSort.saveOrder([" barrel ", "custom internals"])

        let persisted = PartTypeSort.persistedOrder(including: ["Trigger", "Custom Buffer", "Slide"])

        XCTAssertEqual(
            persisted,
            [
                "barrel",
                "custom internals",
                "trigger",
                "slide",
                "bolt carrier group",
                "charging handle",
                "upper receiver",
                "lower receiver",
                "recoil system",
                "internals",
                "other",
                "custom buffer"
            ]
        )
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        PartTypeSort.saveOrder(["Trigger"])
        let versionAfterSave = UserDefaults.standard.integer(forKey: PartTypeSort.settingsVersionKey)

        PartTypeSort.resetOrder()

        XCTAssertEqual(
            PartTypeSort.persistedOrder(),
            PartType.allCases.map(\.displayName).map { $0.lowercased() }
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: PartTypeSort.settingsVersionKey),
            versionAfterSave + 1
        )
    }
}
