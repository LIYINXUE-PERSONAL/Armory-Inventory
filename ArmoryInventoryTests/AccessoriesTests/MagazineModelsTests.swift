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
        XCTAssertEqual(magazine.countCapacityText, "3 20-round magazines")
        XCTAssertEqual(magazine.totalRoundCapacity, 60)
        XCTAssertEqual(magazine.totalRoundCapacityText, "60 Rounds")
        XCTAssertEqual(magazine.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(magazine.caliberDisplayText, "9mm")
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
        XCTAssertEqual(magazine.countCapacityText, "1 17-round magazine")
        XCTAssertEqual(magazine.totalRoundCapacity, 17)
        XCTAssertEqual(magazine.totalRoundCapacityText, "17 Rounds")
        XCTAssertEqual(magazine.caliberDisplayText, "No Caliber")
        XCTAssertEqual(magazine.magazineColor, .other)
        XCTAssertEqual(magazine.colorDisplayName, "Other")

        magazine.color = nil

        XCTAssertNil(magazine.magazineColor)
        XCTAssertNil(magazine.colorDisplayName)
        XCTAssertEqual(magazine.resolvedPattern.kind, .legacy)
        XCTAssertEqual(magazine.resolvedPattern.displayName, "Glock OEM")
    }

    func testLinkedFirearmsDeriveFromSupportedPatterns() {
        let caliber = Caliber(name: "5.56 NATO")
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            count: 2,
            capacity: 30,
            purchasePriceCents: 2500,
            caliber: caliber
        )
        let directLegacyFirearm = Firearm(
            brand: "Legacy",
            modelName: "Host",
            purchasePriceCents: 100000,
            type: .rifle,
            action: .semiAuto,
            magazines: [magazine]
        )
        let supportedPatternFirearm = Firearm(
            brand: "AR",
            modelName: "Pistol",
            purchasePriceCents: 120000,
            type: .pistol,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)],
            caliber: caliber
        )

        XCTAssertEqual(
            magazine.linkedFirearms(from: [supportedPatternFirearm, directLegacyFirearm]).map(\.displayName),
            ["AR Pistol", "Legacy Host"]
        )
        XCTAssertEqual(magazine.caliberDisplayText, ".223 Rem, 5.56 NATO, .300 Blackout")
    }
}
