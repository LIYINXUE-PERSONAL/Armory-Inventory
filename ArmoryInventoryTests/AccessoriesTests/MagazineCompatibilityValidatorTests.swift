//
//  MagazineCompatibilityValidatorTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/22/26.
//

import XCTest
@testable import ArmoryInventory

final class MagazineCompatibilityValidatorTests: XCTestCase {
    func testValidateReturnsLinkedToDifferentFirearmFailure() {
        let validator = MagazineCompatibilityValidator()
        let currentFirearm = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto
        )
        let otherFirearm = Firearm(
            brand: "SIG",
            modelName: "P320",
            purchasePriceCents: 65000,
            type: .pistol,
            action: .semiAuto
        )
        let magazine = Magazine(
            brand: "SIG",
            modelName: "OEM",
            capacity: 17,
            purchasePriceCents: 4500,
            caliber: Caliber(name: "9mm"),
            firearm: otherFirearm
        )

        let result = validator.validate(
            magazine: magazine,
            firearmType: .pistol,
            action: .semiAuto,
            caliber: currentFirearm.caliber,
            owningFirearm: currentFirearm
        )

        XCTAssertEqual(
            result.failure,
            .linkedToDifferentFirearm(currentFirearmName: otherFirearm.displayName)
        )
    }

    func testValidateReturnsCaliberMismatchFailure() {
        let validator = MagazineCompatibilityValidator()
        let result = validator.validate(
            pattern: .legacy(displayName: "Atlas 2011"),
            selectedMagazineCaliber: Caliber(name: "9mm"),
            firearmType: .pistol,
            action: .semiAuto,
            caliber: Caliber(name: ".45 ACP"),
            firearmDescription: "Staccato P"
        )

        XCTAssertEqual(
            result.failure,
            .caliberMismatch(magazineCaliberName: "9mm", firearmCaliberName: ".45 ACP")
        )
    }

    func testValidateReturnsIncompatiblePatternFailure() {
        let validator = MagazineCompatibilityValidator()
        let arPattern = MagazinePattern(
            id: "catalog:test-ar-pattern",
            kind: .catalog,
            displayName: "Test AR Pattern",
            familyLabel: "AR-15 STANAG",
            compatibility: MagazinePatternCompatibility(
                supportedCaliberNames: ["5.56 NATO"],
                compatibleFirearmTypes: [.rifle],
                compatibleFirearmActions: [.semiAuto],
                platformTags: ["AR-15"],
                fitDescriptors: ["standard rifle magazine"]
            ),
            aliases: [],
            notes: nil
        )
        let result = validator.validate(
            pattern: arPattern,
            selectedMagazineCaliber: Caliber(name: "5.56 NATO"),
            firearmType: .pistol,
            action: .semiAuto,
            caliber: Caliber(name: "5.56 NATO"),
            firearmDescription: "Glock 19"
        )

        XCTAssertEqual(
            result.failure,
            .incompatiblePattern(patternName: "Test AR Pattern", firearmDescription: "Glock 19")
        )
    }

    func testValidateReturnsCompatibleForMatchingPatternAndCaliber() {
        let validator = MagazineCompatibilityValidator()
        let result = validator.validate(
            pattern: MagazinePatternCatalog.canonicalPatterns.first { $0.id == "catalog:glock-double-stack-9mm-full-size-compact" }!,
            selectedMagazineCaliber: Caliber(name: "9mm"),
            firearmType: .pistol,
            action: .semiAuto,
            caliber: Caliber(name: "9mm"),
            firearmDescription: "Glock 19"
        )

        XCTAssertTrue(result.isCompatible)
        XCTAssertNil(result.message)
    }
}
