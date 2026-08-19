//
//  PartModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/5/26.
//

import XCTest
@testable import ArmoryInventory

final class PartModelsTests: XCTestCase {
    func testPartTypeDisplayNamesCoverKnownAndOtherCases() {
        XCTAssertEqual(PartType.barrel.displayName, "Barrel")
        XCTAssertEqual(PartType.trigger.displayName, "Trigger")
        XCTAssertEqual(PartType.boltCarrierGroup.displayName, "Bolt Carrier Group")
        XCTAssertEqual(PartType.other.displayName, "Other")
    }

    func testPartTypesThatCanProvideFirearmConfiguration() {
        XCTAssertTrue(PartType.barrel.supportsFirearmConfiguration)
        XCTAssertTrue(PartType.slide.supportsFirearmConfiguration)
        XCTAssertTrue(PartType.upperReceiver.supportsFirearmConfiguration)
        XCTAssertFalse(PartType.trigger.supportsFirearmConfiguration)
        XCTAssertFalse(PartType.other.supportsFirearmConfiguration)
    }

    func testPartComputedPropertiesPreferCustomDetailsAndFallbacks() {
        let firearm = Firearm(
            brand: "BCM",
            modelName: "Recce",
            purchasePriceCents: 160000,
            type: .rifle,
            action: .semiAuto
        )
        let part = Part(
            brand: "Apex",
            modelName: "Enhancement Kit",
            type: .other,
            typeDetail: "Trigger Kit",
            color: .other,
            colorDetail: "Nitride",
            purchasePriceCents: 12999,
            firearm: firearm
        )

        XCTAssertEqual(part.partType, .other)
        XCTAssertEqual(part.typeDisplayName, "Trigger Kit")
        XCTAssertEqual(part.displayName, "Apex Enhancement Kit")
        XCTAssertEqual(part.partColor, .other)
        XCTAssertEqual(part.colorDisplayName, "Nitride")
        XCTAssertTrue(part.purchasePriceText.contains("129"))
        XCTAssertTrue(part.firearm === firearm)
    }

    func testPartComputedPropertiesFallbackWhenStoredValuesAreInvalidOrMissing() {
        let part = Part(
            brand: "BCM",
            modelName: "MK2",
            type: .chargingHandle,
            purchasePriceCents: 8000
        )
        part.type = "not-a-real-type"
        part.color = "not-a-real-color"
        part.colorDetail = nil

        XCTAssertEqual(part.partType, .other)
        XCTAssertEqual(part.typeDisplayName, "Other")
        XCTAssertEqual(part.partColor, .other)
        XCTAssertEqual(part.colorDisplayName, "Other")

        part.color = nil

        XCTAssertNil(part.partColor)
        XCTAssertNil(part.colorDisplayName)
    }
}
