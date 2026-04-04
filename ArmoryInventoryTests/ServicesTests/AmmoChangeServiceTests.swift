//
//  AmmoChangeServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AmmoChangeServiceTests: XCTestCase {
    @MainActor
    func testApplyChangeUpdatesInventoryAndRecordsHistory() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 100,
            centsPerRound: 30,
            caliber: caliber
        )

        context.insert(caliber)
        context.insert(ammo)

        let service = AmmoChangeService()
        service.applyChange(to: ammo, delta: -30, occurredAt: .now, in: context)

        let history = try context.fetch(FetchDescriptor<AmmoAdjustmentRecord>())

        XCTAssertEqual(ammo.quantity, 70)
        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.adjustmentKind, .consumption)
        XCTAssertEqual(history.first?.quantity, 30)
    }

    @MainActor
    func testApplyChangeIgnoresZeroDelta() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 100,
            centsPerRound: 30,
            caliber: caliber
        )

        context.insert(caliber)
        context.insert(ammo)

        let service = AmmoChangeService()
        service.applyChange(to: ammo, delta: 0, occurredAt: .now, in: context)

        let history = try context.fetch(FetchDescriptor<AmmoAdjustmentRecord>())

        XCTAssertEqual(ammo.quantity, 100)
        XCTAssertTrue(history.isEmpty)
    }

    @MainActor
    func testRecordInitialPurchaseOnlyRecordsPositiveQuantity() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 100,
            centsPerRound: 30,
            caliber: caliber
        )

        context.insert(caliber)
        context.insert(ammo)

        let service = AmmoChangeService()
        service.recordInitialPurchase(quantity: 50, for: ammo, in: context)
        service.recordInitialPurchase(quantity: 0, for: ammo, in: context)

        let history = try context.fetch(FetchDescriptor<AmmoAdjustmentRecord>())

        XCTAssertEqual(history.count, 1)
        XCTAssertEqual(history.first?.adjustmentKind, .purchase)
        XCTAssertEqual(history.first?.quantity, 50)
    }

    @MainActor
    func testSummaryIncludesTaxAndRangeFiltering() {
        let caliber = Caliber(name: "9mm")
        let ammo = AmmoType(
            brand: "Federal",
            bulletType: "FMJ",
            grain: 115,
            quantity: 100,
            centsPerRound: 20,
            caliber: caliber
        )
        let now = Date()

        caliber.adjustmentRecords = [
            AmmoAdjustmentRecord(
                quantity: 10,
                occurredAt: now,
                kind: .purchase,
                caliber: caliber,
                ammoType: ammo
            ),
            AmmoAdjustmentRecord(
                quantity: 5,
                occurredAt: now,
                kind: .consumption,
                caliber: caliber,
                ammoType: ammo
            ),
            AmmoAdjustmentRecord(
                quantity: 99,
                occurredAt: .distantPast,
                kind: .purchase,
                caliber: caliber,
                ammoType: ammo
            )
        ]

        let summary = AmmoChangeService().summary(
            for: caliber,
            within: AmmoChangeRange(start: now.addingTimeInterval(-1), end: now.addingTimeInterval(1)),
            taxRate: 10
        )

        XCTAssertEqual(summary.purchased, 10)
        XCTAssertEqual(summary.consumed, 5)
        XCTAssertEqual(summary.purchasedAmountCents, 220)
        XCTAssertEqual(summary.consumedAmountCents, 110)
    }
}
