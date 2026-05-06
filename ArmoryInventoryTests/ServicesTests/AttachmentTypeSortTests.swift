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
        AttachmentTypeSort.saveOrder(["light", "grip", "stock"])

        XCTAssertTrue(AttachmentTypeSort.areInAscendingOrder("light", "grip"))
        XCTAssertTrue(AttachmentTypeSort.areInAscendingOrder("grip", "custom sling"))
        XCTAssertFalse(AttachmentTypeSort.areInAscendingOrder("custom sling", "stock"))
    }

    func testDisplayOrderSortsBySavedRankingThenLocalizedFallback() {
        AttachmentTypeSort.saveOrder(["laser", "stock"])

        XCTAssertEqual(
            AttachmentTypeSort.displayOrder(for: ["grip", "Custom Z", "stock", "laser", "Custom A"]),
            ["laser", "stock", "grip", "Custom A", "Custom Z"]
        )
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        AttachmentTypeSort.saveOrder([" laser ", "custom wrap"])

        let persisted = AttachmentTypeSort.persistedOrder(including: ["stock", "Custom Mount", "grip"])

        XCTAssertEqual(
            persisted,
            [
                "laser",
                "custom wrap",
                "stock",
                "grip",
                "light",
                "handstop",
                "bipod",
                "slingmount",
                "muzzledevice",
                "other",
                "custom mount"
            ]
        )
    }

    func testPersistedOrderIgnoresLegacyDisplayNamesAndUsesStableIDs() {
        UserDefaults.standard.set(["light", "grip", "stock", "hand stop"], forKey: InventorySettingsKeys.attachmentTypeSortOrder)

        let persisted = AttachmentTypeSort.persistedOrder(including: ["stock", "grip", "laser"])

        XCTAssertEqual(
            persisted.prefix(4).map(\.self),
            ["light", "grip", "stock", "laser"]
        )
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        AttachmentTypeSort.saveOrder(["grip"])
        let versionAfterSave = UserDefaults.standard.integer(forKey: AttachmentTypeSort.settingsVersionKey)

        AttachmentTypeSort.resetOrder()

        XCTAssertEqual(
            AttachmentTypeSort.persistedOrder(),
            AttachmentType.allCases.map(\.id).map { $0.lowercased() }
        )
        XCTAssertEqual(
            UserDefaults.standard.integer(forKey: AttachmentTypeSort.settingsVersionKey),
            versionAfterSave + 1
        )
    }
}
