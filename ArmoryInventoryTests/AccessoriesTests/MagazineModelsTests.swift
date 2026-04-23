//
//  MagazineModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
@testable import ArmoryInventory

final class MagazineModelsTests: XCTestCase {
    func testMagazineComputedPropertiesPreferStoredDetails() {
        let caliber = Caliber(name: "9mm")
        let firearm = Firearm(
            brand: "Staccato",
            modelName: "P",
            purchasePriceCents: 250000,
            type: .pistol,
            action: .semiAuto
        )
        let magazine = Magazine(
            brand: "Atlas",
            modelName: "Premium",
            count: 3,
            capacity: 20,
            purchasePriceCents: 21000,
            color: .other,
            colorDetail: "Nickel",
            caliber: caliber,
            firearm: firearm
        )

        XCTAssertEqual(magazine.displayName, "Atlas Premium")
        XCTAssertEqual(magazine.capacityText, "20 rounds")
        XCTAssertEqual(magazine.countText, "3 magazines")
        XCTAssertEqual(magazine.totalRoundCapacity, 60)
        XCTAssertEqual(magazine.totalRoundCapacityText, "60 Rounds")
        XCTAssertEqual(magazine.magazineColor, .other)
        XCTAssertEqual(magazine.colorDisplayName, "Nickel")
        XCTAssertTrue(magazine.purchasePriceText.contains("210"))
        XCTAssertTrue(magazine.caliber === caliber)
        XCTAssertTrue(magazine.firearm === firearm)
        XCTAssertEqual(magazine.resolvedPattern.kind, .catalog)
        XCTAssertEqual(magazine.resolvedPattern.id, "catalog:2011-double-stack-9mm")
    }

    func testMagazineComputedPropertiesFallbackForSingularAndInvalidColor() {
        let magazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            count: 1,
            capacity: 17,
            purchasePriceCents: 3500
        )
        magazine.color = "invalid-color"
        magazine.colorDetail = nil

        XCTAssertEqual(magazine.countText, "1 magazine")
        XCTAssertEqual(magazine.capacityText, "17 rounds")
        XCTAssertEqual(magazine.totalRoundCapacity, 17)
        XCTAssertEqual(magazine.totalRoundCapacityText, "17 Rounds")
        XCTAssertEqual(magazine.magazineColor, .other)
        XCTAssertEqual(magazine.colorDisplayName, "Other")

        magazine.color = nil

        XCTAssertNil(magazine.magazineColor)
        XCTAssertNil(magazine.colorDisplayName)
        XCTAssertEqual(magazine.resolvedPattern.kind, .legacy)
        XCTAssertEqual(magazine.resolvedPattern.displayName, "Glock OEM")
    }
}
