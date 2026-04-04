//
//  AttachmentTypeSortTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class AttachmentTypeSortTests: XCTestCase {
    override func setUp() {
        super.setUp()
        AttachmentTypeSort.resetOrder()
    }

    override func tearDown() {
        AttachmentTypeSort.resetOrder()
        super.tearDown()
    }

    func testAscendingOrderPrefersConfiguredRankingOverUnknownNames() {
        AttachmentTypeSort.saveOrder(["Light", "Grip", "Stock"])

        XCTAssertTrue(AttachmentTypeSort.areInAscendingOrder("Light", "Grip"))
        XCTAssertTrue(AttachmentTypeSort.areInAscendingOrder("Grip", "Custom Sling"))
        XCTAssertFalse(AttachmentTypeSort.areInAscendingOrder("Custom Sling", "Stock"))
    }

    func testDisplayOrderSortsBySavedRankingThenLocalizedFallback() {
        AttachmentTypeSort.saveOrder(["Laser", "Stock"])

        XCTAssertEqual(
            AttachmentTypeSort.displayOrder(for: ["Grip", "Custom Z", "Stock", "Laser", "Custom A"]),
            ["Laser", "Stock", "Grip", "Custom A", "Custom Z"]
        )
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        AttachmentTypeSort.saveOrder([" laser ", "custom wrap"])

        let persisted = AttachmentTypeSort.persistedOrder(including: ["Stock", "Custom Mount", "Grip"])

        XCTAssertEqual(
            persisted,
            [
                "laser",
                "custom wrap",
                "stock",
                "grip",
                "light",
                "hand stop",
                "bipod",
                "sling mount",
                "muzzle device",
                "other",
                "custom mount"
            ]
        )
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        AttachmentTypeSort.saveOrder(["Grip"])
        let versionAfterSave = UserDefaults.standard.integer(forKey: AttachmentTypeSort.settingsVersionKey)

        AttachmentTypeSort.resetOrder()

        XCTAssertEqual(
            AttachmentTypeSort.persistedOrder(),
            AttachmentType.allCases.map(\.displayName).map { $0.lowercased() }
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: AttachmentTypeSort.settingsVersionKey),
            versionAfterSave + 1
        )
    }
}
