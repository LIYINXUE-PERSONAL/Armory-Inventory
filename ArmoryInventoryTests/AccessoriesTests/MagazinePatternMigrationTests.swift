//
//  MagazinePatternMigrationTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/22/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class MagazinePatternMigrationTests: XCTestCase {
    @MainActor
    func testBackfillAssignsCanonicalPatternWhenCompatibilityIsUnambiguous() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let caliber = Caliber(name: KnownCaliber.blackout300.displayName)
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180_000,
            type: .rifle,
            action: .semiAuto,
            caliber: caliber
        )
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG 30",
            count: 4,
            capacity: 30,
            purchasePriceCents: 7_500,
            caliber: caliber,
            firearm: firearm
        )

        context.insert(caliber)
        context.insert(firearm)
        context.insert(magazine)

        XCTAssertTrue(MagazinePatternMigration.backfillMissingPatterns(in: context))
        XCTAssertEqual(magazine.patternID, "catalog:ar15-stanag-223-556-300blk")
        XCTAssertEqual(magazine.storedPatternKind, .catalog)
        XCTAssertNil(magazine.patternDisplayName)
        XCTAssertEqual(magazine.resolvedPattern.id, "catalog:ar15-stanag-223-556-300blk")
    }

    @MainActor
    func testBackfillFallsBackToLegacyPatternWhenCatalogMatchIsUnknownToCatalog() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let caliber = Caliber(name: KnownCaliber.mm9.displayName)
        let firearm = Firearm(
            brand: "CZ",
            modelName: "P-10 C",
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto,
            caliber: caliber
        )
        let magazine = Magazine(
            brand: "CZ",
            modelName: "OEM",
            count: 3,
            capacity: 15,
            purchasePriceCents: 5_000,
            caliber: caliber,
            firearm: firearm
        )

        context.insert(caliber)
        context.insert(firearm)
        context.insert(magazine)

        XCTAssertTrue(MagazinePatternMigration.backfillMissingPatterns(in: context))
        XCTAssertEqual(magazine.storedPatternKind, .legacy)
        XCTAssertEqual(magazine.patternDisplayName, "CZ OEM")
        XCTAssertEqual(magazine.resolvedPattern.displayName, "CZ OEM")
        XCTAssertEqual(magazine.resolvedPattern.compatibility.supportedCaliberNames, [KnownCaliber.mm9.displayName])
        XCTAssertTrue(magazine.resolvedPattern.id.hasPrefix("legacy:"))
    }

    @MainActor
    func testBackfillIsIdempotentForMagazinesThatAlreadyHavePatternMetadata() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext

        let caliber = Caliber(name: KnownCaliber.blackout300.displayName)
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180_000,
            type: .rifle,
            action: .semiAuto,
            caliber: caliber
        )
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG 30",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            count: 2,
            capacity: 30,
            purchasePriceCents: 4_000,
            caliber: caliber,
            firearm: firearm
        )

        context.insert(caliber)
        context.insert(firearm)
        context.insert(magazine)

        XCTAssertFalse(MagazinePatternMigration.backfillMissingPatterns(in: context))
        XCTAssertEqual(magazine.patternID, "catalog:ar15-stanag-223-556-300blk")
        XCTAssertEqual(magazine.storedPatternKind, .catalog)
    }
}
