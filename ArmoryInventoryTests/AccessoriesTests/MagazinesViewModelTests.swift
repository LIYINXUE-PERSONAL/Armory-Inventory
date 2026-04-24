//
//  MagazinesViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/24/26.
//

import XCTest
@testable import ArmoryInventory

final class MagazinesViewModelTests: XCTestCase {
    func testGroupedMagazinesUsesCaliberSortAndBuildsGroupSummaries() {
        let viewModel = MagazinesViewModel()

        let rifleMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            count: 2,
            capacity: 30,
            purchasePriceCents: 1500
        )
        let pistolMagazine = Magazine(
            brand: "Glock",
            modelName: "OEM 15",
            patternID: "catalog:glock-double-stack-9mm-compact",
            patternKind: .catalog,
            count: 3,
            capacity: 15,
            purchasePriceCents: 1200
        )
        let customMagazine = Magazine(
            brand: "Mystery",
            modelName: "Tube",
            patternID: "custom:12345678-1234-1234-1234-1234567890ab",
            patternKind: .custom,
            patternDisplayName: "Mystery Tube",
            patternSupportedCaliberNames: [],
            count: 1,
            capacity: 20,
            purchasePriceCents: 500
        )

        let arFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: rifleMagazine.resolvedPattern)]
        )
        let glockFirearm = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: pistolMagazine.resolvedPattern)]
        )
        let secondGlockFirearm = Firearm(
            brand: "Glock",
            modelName: "26",
            purchasePriceCents: 45000,
            type: .pistol,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: pistolMagazine.resolvedPattern)]
        )

        let groups = viewModel.groupedMagazines(
            [customMagazine, pistolMagazine, rifleMagazine],
            firearms: [secondGlockFirearm, arFirearm, glockFirearm]
        )

        XCTAssertEqual(groups.map(\.id), [
            "catalog:ar15-stanag-223-556-300blk",
            "catalog:glock-double-stack-9mm-compact",
            "custom:12345678-1234-1234-1234-1234567890ab",
        ])
        XCTAssertEqual(groups[0].summaryText, ".223 Rem, 5.56 NATO, .300 Blackout • 2 magazines")
        XCTAssertEqual(groups[1].summaryText, "9mm • 3 magazines")
        XCTAssertEqual(groups[1].linkedFirearmsText, "Used by 2 firearms: Glock 19, Glock 26")
        XCTAssertEqual(groups[2].linkedFirearmsText, "Used by 0 firearm.")
    }

    func testLinkedFirearmNamesDeduplicatesAndSortsDisplayNames() {
        let viewModel = MagazinesViewModel()
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            count: 1,
            capacity: 30,
            purchasePriceCents: 1500
        )

        let zulu = Firearm(
            brand: "Zulu",
            modelName: "Host",
            purchasePriceCents: 100000,
            type: .rifle,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)]
        )
        let alpha = Firearm(
            brand: "Alpha",
            modelName: "Host",
            purchasePriceCents: 100000,
            type: .rifle,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)]
        )
        let duplicateAlpha = Firearm(
            brand: "Alpha",
            modelName: "Host",
            purchasePriceCents: 100000,
            type: .rifle,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)]
        )

        XCTAssertEqual(
            viewModel.linkedFirearmNames(for: [magazine], firearms: [zulu, alpha, duplicateAlpha]),
            ["Alpha Host", "Zulu Host"]
        )
    }
}
