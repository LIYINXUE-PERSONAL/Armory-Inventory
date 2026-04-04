//
//  AmmoModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
@testable import ArmoryInventory

final class AmmoModelsTests: XCTestCase {
    func testLoadDescriptionCoversLoadDetailGrainAndFallback() {
        let withLoadDetail = AmmoType(brand: "Federal", bulletType: "Buckshot", grain: 0, loadDetail: "00")
        let withGrain = AmmoType(brand: "Federal", bulletType: "FMJ", grain: 115)
        let withoutGrain = AmmoType(brand: "Federal", bulletType: "Slug", grain: 0)

        XCTAssertEqual(withLoadDetail.loadDescription, "Buckshot 00")
        XCTAssertEqual(withGrain.loadDescription, "FMJ 115gr")
        XCTAssertEqual(withoutGrain.loadDescription, "Slug")
    }

    func testRoundsTextAndAdjustmentKindFallback() {
        let record = AmmoAdjustmentRecord(quantity: 1, kind: .purchase)
        record.kind = "unknown"

        XCTAssertEqual(AmmoType.roundsText(for: 25), "25 Rounds")
        XCTAssertEqual(record.adjustmentKind, .consumption)
    }

    func testCommonAmmoCatalogReturnsExpectedData() {
        XCTAssertEqual(CommonAmmoCatalog.bulletTypes(for: "12 Gauge"), CommonAmmoCatalog.commonShotgunTypes)
        XCTAssertEqual(CommonAmmoCatalog.bulletTypes(for: "9mm"), CommonAmmoCatalog.commonBulletTypes)
        XCTAssertTrue(CommonAmmoCatalog.isShotgunCaliber("12 gauge"))
        XCTAssertEqual(CommonAmmoCatalog.grainRange(for: "9mm"), 92...180)
        XCTAssertEqual(CommonAmmoCatalog.referenceGrainRange(for: "9mm"), 115...150)
        XCTAssertNil(CommonAmmoCatalog.grainRange(for: "Unknown"))
        XCTAssertNil(CommonAmmoCatalog.referenceGrainRange(for: "Unknown"))
    }
}
