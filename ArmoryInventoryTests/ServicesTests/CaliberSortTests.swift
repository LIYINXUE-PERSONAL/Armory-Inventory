//
//  CaliberSortTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
@testable import ArmoryInventory

final class CaliberSortTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "CaliberSortOrder")
        UserDefaults.standard.removeObject(forKey: CaliberSort.settingsVersionKey)
        super.tearDown()
    }

    func testAscendingOrderPrefersRankedCalibers() {
        XCTAssertTrue(CaliberSort.areInAscendingOrder("9mm", ".45 ACP"))
        XCTAssertFalse(CaliberSort.areInAscendingOrder("Custom", "9mm"))
    }

    func testDisplayOrderSortsByConfiguredRanking() {
        let ordered = CaliberSort.displayOrder(for: ["Custom", ".45 ACP", "9mm"])

        XCTAssertEqual(ordered, ["9mm", ".45 ACP", "Custom"])
    }

    func testPersistedOrderIncludesSavedKnownAndCustomNames() {
        CaliberSort.saveOrder(["  Custom  ", "9MM"])

        let order = CaliberSort.persistedOrder(including: ["Another Custom"])

        XCTAssertEqual(order.prefix(2), ["custom", "9mm"])
        XCTAssertTrue(order.contains(".22 lr"))
        XCTAssertTrue(order.contains("another custom"))
        XCTAssertEqual(UserDefaults.standard.integer(forKey: CaliberSort.settingsVersionKey), 1)
    }

    func testResetOrderClearsSavedOrderAndBumpsVersion() {
        CaliberSort.saveOrder(["9mm"])
        CaliberSort.resetOrder()

        XCTAssertNil(UserDefaults.standard.stringArray(forKey: "CaliberSortOrder"))
        XCTAssertEqual(UserDefaults.standard.integer(forKey: CaliberSort.settingsVersionKey), 2)
    }
}
