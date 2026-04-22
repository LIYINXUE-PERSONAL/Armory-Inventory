//
//  MagazinePatternModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/21/26.
//

import XCTest
@testable import ArmoryInventory

final class MagazinePatternModelsTests: XCTestCase {
    func testAr15PatternSupportsMultipleCalibers() throws {
        let pattern = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "ar15-stanag-223-556-300blk"))

        XCTAssertEqual(pattern.family, .ar15Stanag)
        XCTAssertTrue(pattern.supports(caliberName: ".223 Rem"))
        XCTAssertTrue(pattern.supports(caliberName: "5.56 NATO"))
        XCTAssertTrue(pattern.supports(caliberName: ".300 Blackout"))
        XCTAssertFalse(pattern.supports(caliberName: "9mm"))
        XCTAssertTrue(pattern.isCompatible(with: .rifle, action: .semiAuto, caliberName: "5.56 NATO"))
        XCTAssertFalse(pattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: "5.56 NATO"))
    }

    func testCatalogCanRepresentDistinctPatternsForSameCaliber() throws {
        let fullSize = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "glock-double-stack-9mm-full-size-compact"))
        let compact = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "glock-double-stack-9mm-compact"))

        XCTAssertEqual(fullSize.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(compact.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(fullSize.family, .glockDoubleStack9mm)
        XCTAssertEqual(compact.family, .glockDoubleStack9mm)
        XCTAssertNotEqual(fullSize.id, compact.id)
        XCTAssertNotEqual(fullSize.fitProfile, compact.fitProfile)
        XCTAssertTrue(fullSize.compatiblePlatformNames.contains("Glock 17"))
        XCTAssertFalse(compact.compatiblePlatformNames.contains("Glock 17"))
        XCTAssertTrue(compact.compatiblePlatformNames.contains("Glock 19"))
    }

    func testSuggestedPatternsFilterByTypeActionAndCaliber() {
        let pistolPatterns = MagazinePatternCatalog.suggestedPatterns(
            firearmType: .pistol,
            action: .semiAuto,
            caliberName: "9mm"
        )
        let riflePatterns = MagazinePatternCatalog.suggestedPatterns(
            firearmType: .rifle,
            action: .semiAuto,
            caliberName: ".300 Blackout"
        )

        XCTAssertEqual(
            Set(pistolPatterns.map(\.id)),
            [
                "glock-double-stack-9mm-full-size-compact",
                "glock-double-stack-9mm-compact",
                "sig-p320-double-stack-9mm",
                "2011-double-stack-9mm"
            ]
        )
        XCTAssertEqual(riflePatterns.map(\.id), ["ar15-stanag-223-556-300blk"])
    }

    func testLegacyFallbackPreservesUserFacingDetails() {
        let legacyPattern = MagazinePattern.legacy(
            displayName: "CZ 75 Pattern",
            supportedCaliberNames: ["9mm"],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            compatiblePlatformNames: ["CZ 75", "Shadow 2"],
            notes: "Imported before catalog support existed."
        )

        XCTAssertEqual(legacyPattern.kind, .legacy)
        XCTAssertEqual(legacyPattern.family, .legacy)
        XCTAssertEqual(legacyPattern.displayName, "CZ 75 Pattern")
        XCTAssertEqual(legacyPattern.fitProfile, .legacy)
        XCTAssertEqual(legacyPattern.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(legacyPattern.compatiblePlatformNames, ["CZ 75", "Shadow 2"])
        XCTAssertTrue(legacyPattern.id.hasPrefix("legacy:"))
        XCTAssertTrue(legacyPattern.isFallback)
    }

    func testUnknownFallbackIsAvailableForUnmappedRecords() {
        XCTAssertEqual(MagazinePattern.unknown.kind, .unknown)
        XCTAssertEqual(MagazinePattern.unknown.family, .unknown)
        XCTAssertTrue(MagazinePattern.unknown.supportedCaliberNames.isEmpty)
        XCTAssertTrue(MagazinePattern.unknown.compatiblePlatformNames.isEmpty)
        XCTAssertTrue(MagazinePattern.unknown.isFallback)
    }
}
