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
        let pattern = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "catalog:ar15-stanag-223-556-300blk"))

        XCTAssertEqual(pattern.familyLabel, "AR-15 STANAG")
        XCTAssertEqual(
            pattern.compatibility.supportedCaliberNames,
            [KnownCaliber.rem223.displayName, KnownCaliber.nato556.displayName, KnownCaliber.blackout300.displayName]
        )
        XCTAssertTrue(pattern.supports(caliberName: KnownCaliber.rem223.displayName))
        XCTAssertTrue(pattern.supports(caliberName: KnownCaliber.nato556.displayName))
        XCTAssertTrue(pattern.supports(caliberName: KnownCaliber.blackout300.displayName))
        XCTAssertFalse(pattern.supports(caliberName: KnownCaliber.mm9.displayName))
        XCTAssertTrue(pattern.compatibility.platformTags.contains("AR-15"))
        XCTAssertTrue(pattern.isCompatible(with: .rifle, action: .semiAuto, caliberName: KnownCaliber.nato556.displayName))
        XCTAssertFalse(pattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: KnownCaliber.nato556.displayName))
    }

    func testCatalogCanRepresentDistinctPatternsForSameCaliber() throws {
        let fullSize = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "catalog:glock-double-stack-9mm-full-size-compact"))
        let compact = try XCTUnwrap(MagazinePatternCatalog.pattern(id: "catalog:glock-double-stack-9mm-compact"))

        XCTAssertEqual(fullSize.compatibility.supportedCaliberNames, [KnownCaliber.mm9.displayName])
        XCTAssertEqual(compact.compatibility.supportedCaliberNames, [KnownCaliber.mm9.displayName])
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
            caliberName: KnownCaliber.mm9.displayName
        )
        let riflePatterns = MagazinePatternCatalog.suggestedPatterns(
            firearmType: .rifle,
            action: .semiAuto,
            caliberName: KnownCaliber.blackout300.displayName
        )

        XCTAssertEqual(
            Set(pistolPatterns.map(\.id)),
            [
                "catalog:glock-double-stack-9mm-full-size-compact",
                "catalog:glock-double-stack-9mm-compact",
                "catalog:sig-p320-double-stack-9mm",
                "catalog:2011-double-stack-9mm"
            ]
        )
        XCTAssertEqual(riflePatterns.map(\.id), ["catalog:ar15-stanag-223-556-300blk"])
    }

    func testLegacyFallbackPreservesUserFacingDetails() {
        let legacyPattern = MagazinePattern.legacy(
            displayName: "CZ 75 Pattern",
            familyLabel: "CZ 75",
            supportedCaliberNames: [KnownCaliber.mm9.displayName],
            compatibleFirearmTypes: [.pistol],
            compatibleFirearmActions: [.semiAuto],
            platformTags: ["CZ 75", "Shadow 2"],
            fitDescriptors: ["double-stack steel-frame pistol"],
            notes: "Imported before catalog support existed."
        )

        XCTAssertEqual(legacyPattern.kind, .legacy)
        XCTAssertEqual(legacyPattern.familyLabel, "CZ 75")
        XCTAssertEqual(legacyPattern.displayName, "CZ 75 Pattern")
        XCTAssertEqual(legacyPattern.compatibility.supportedCaliberNames, [KnownCaliber.mm9.displayName])
        XCTAssertEqual(legacyPattern.compatibility.platformTags, ["CZ 75", "Shadow 2"])
        XCTAssertEqual(legacyPattern.compatibility.fitDescriptors, ["double-stack steel-frame pistol"])
        XCTAssertTrue(legacyPattern.id.hasPrefix("legacy:"))
        XCTAssertTrue(legacyPattern.isFallback)
    }

    func testCustomPatternsUseStableOpaqueIDNamespace() {
        let pattern = MagazinePattern.custom(
            id: UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!,
            displayName: "My PCC Pattern",
            familyLabel: "AR9 Lower",
            supportedCaliberNames: [KnownCaliber.mm9.displayName],
            compatibleFirearmTypes: [.rifle],
            compatibleFirearmActions: [.semiAuto],
            platformTags: ["AR9", "Colt-style"],
            fitDescriptors: ["straight magazine"],
            aliases: ["Competition PCC"]
        )

        XCTAssertEqual(pattern.id, "custom:12345678-1234-1234-1234-1234567890ab")
        XCTAssertEqual(pattern.displayName, "My PCC Pattern")
        XCTAssertEqual(pattern.familyLabel, "AR9 Lower")
        XCTAssertEqual(pattern.compatibility.platformTags, ["AR9", "Colt-style"])
        XCTAssertEqual(pattern.aliases, ["Competition PCC"])
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
        XCTAssertEqual(MagazinePattern.unknown.id, "legacy:unknown")
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

        XCTAssertTrue(unknownPattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: KnownCaliber.mm9.displayName))
        XCTAssertTrue(legacyPattern.isCompatible(with: .pistol, action: .semiAuto, caliberName: KnownCaliber.acp45.displayName))
        XCTAssertFalse(legacyPattern.isCompatible(with: .rifle, action: .semiAuto, caliberName: KnownCaliber.acp45.displayName))
    }
}
