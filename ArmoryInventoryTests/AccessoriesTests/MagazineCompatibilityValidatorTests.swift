//
//  MagazineCompatibilityValidatorTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/22/26.
//

import XCTest
@testable import ArmoryInventory

final class MagazineCompatibilityValidatorTests: XCTestCase {
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

    func testValidateUsesPatternSupportedCalibersWhenAvailable() {
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
            selectedMagazineCaliber: nil,
            firearmType: .pistol,
            action: .semiAuto,
            caliber: Caliber(name: ".300 Blackout"),
            firearmDescription: "AR Pistol"
        )

        XCTAssertEqual(
            result.failure,
            .caliberMismatch(magazineCaliberName: "5.56 NATO", firearmCaliberName: ".300 Blackout")
        )
    }

    func testValidateReturnsCompatibleForMatchingPatternAndCaliber() {
        let validator = MagazineCompatibilityValidator()
        let result = validator.validate(
            pattern: MagazinePatternCatalog.canonicalPatterns.first { $0.id == "catalog:ar15-stanag-223-556-300blk" }!,
            selectedMagazineCaliber: nil,
            firearmType: .pistol,
            action: .semiAuto,
            caliber: Caliber(name: "5.56 NATO"),
            firearmDescription: "AR Pistol"
        )

        XCTAssertTrue(result.isCompatible)
        XCTAssertNil(result.message)
    }
}
