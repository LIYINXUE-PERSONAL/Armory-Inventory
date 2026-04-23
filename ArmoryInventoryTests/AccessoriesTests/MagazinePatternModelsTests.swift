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

        XCTAssertEqual(pattern.familyLabel, "AR-15 STANAG")
        XCTAssertTrue(pattern.supports(caliberName: ".223 Rem"))
        XCTAssertTrue(pattern.supports(caliberName: "5.56 NATO"))
        XCTAssertTrue(pattern.supports(caliberName: ".300 Blackout"))
        XCTAssertFalse(pattern.supports(caliberName: "9mm"))
        XCTAssertTrue(pattern.compatibility.platformTags.contains("AR-15"))
        XCTAssertTrue(pattern.isCompatible(with: .rifle, action: .semiAuto, caliberName: "5.56 NATO"))
        XCTAssertFalse(pattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: "5.56 NATO"))
    }

    func testCatalogCanRepresentDistinctPatternsForSameCaliber() throws {
        let fullSize = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "glock-double-stack-9mm-full-size-compact"))
        let compact = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "glock-double-stack-9mm-compact"))

        XCTAssertEqual(fullSize.compatibility.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(compact.compatibility.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(fullSize.familyLabel, "Glock Double-Stack 9mm")
        XCTAssertEqual(compact.familyLabel, "Glock Double-Stack 9mm")
        XCTAssertNotEqual(fullSize.id, compact.id)
        XCTAssertNotEqual(fullSize.compatibility.fitDescriptors, compact.compatibility.fitDescriptors)
        XCTAssertTrue(fullSize.compatibility.platformTags.contains("Glock 17"))
        XCTAssertFalse(compact.compatibility.platformTags.contains("Glock 17"))
        XCTAssertTrue(compact.compatibility.platformTags.contains("Glock 19"))
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
            familyLabel: "CZ 75",
            supportedCaliberNames: ["9mm"],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            platformTags: ["CZ 75", "Shadow 2"],
            fitDescriptors: ["double-stack steel-frame pistol"],
            notes: "Imported before catalog support existed."
        )

        XCTAssertEqual(legacyPattern.kind, .legacy)
        XCTAssertEqual(legacyPattern.familyLabel, "CZ 75")
        XCTAssertEqual(legacyPattern.displayName, "CZ 75 Pattern")
        XCTAssertEqual(legacyPattern.compatibility.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(legacyPattern.compatibility.platformTags, ["CZ 75", "Shadow 2"])
        XCTAssertEqual(legacyPattern.compatibility.fitDescriptors, ["double-stack steel-frame pistol"])
        XCTAssertTrue(legacyPattern.id.hasPrefix("legacy:"))
        XCTAssertTrue(legacyPattern.isFallback)
    }

    func testLegacyFallbackGeneratesDistinctIDsWhenSlugWouldBeEmpty() {
        let punctuationPattern = MagazinePattern.legacy(displayName: "!!!")
        let cjkPattern = MagazinePattern.legacy(displayName: "弹匣")

        XCTAssertNotEqual(punctuationPattern.id, cjkPattern.id)
        XCTAssertEqual(punctuationPattern.id, "legacy:legacy-002100210021")
        XCTAssertEqual(cjkPattern.id, "legacy:legacy-5f395323")
    }

    func testUnknownFallbackIsAvailableForUnmappedRecords() {
        XCTAssertEqual(MagazinePattern.unknown.kind, .unknown)
        XCTAssertEqual(MagazinePattern.unknown.familyLabel, "Unknown")
        XCTAssertTrue(MagazinePattern.unknown.compatibility.supportedCaliberNames.isEmpty)
        XCTAssertTrue(MagazinePattern.unknown.compatibility.platformTags.isEmpty)
        XCTAssertTrue(MagazinePattern.unknown.isFallback)
    }

    func testEmptyCaliberConstraintsActAsWildcard() {
        let unknownPattern = MagazinePattern.unknown
        let legacyPattern = MagazinePattern.legacy(
            displayName: "Imported Pattern",
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto]
        )

        XCTAssertTrue(unknownPattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: "9mm"))
        XCTAssertTrue(legacyPattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: ".45 ACP"))
        XCTAssertFalse(legacyPattern.isCompatible(with: .rifle, action: .semiAuto, caliberName: ".45 ACP"))
    }
}
