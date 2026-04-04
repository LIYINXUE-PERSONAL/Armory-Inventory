//
//  AddFirearmLookupServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddFirearmLookupServiceTests: XCTestCase {
    @MainActor
    func testFetchLookupDataReturnsEmptyCollectionsWhenContextIsEmpty() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let service = AddFirearmLookupService()

        let lookupData = try service.fetchLookupData(in: context)

        XCTAssertTrue(lookupData.calibers.isEmpty)
        XCTAssertTrue(lookupData.existingFirearms.isEmpty)
        XCTAssertTrue(lookupData.optics.isEmpty)
        XCTAssertTrue(lookupData.magazines.isEmpty)
        XCTAssertTrue(lookupData.attachments.isEmpty)
    }

    @MainActor
    func testFetchLookupDataReturnsSortedCollections() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let service = AddFirearmLookupService()

        context.insert(Caliber(name: "9mm"))
        context.insert(Caliber(name: ".22 LR"))
        context.insert(Caliber(name: ".223 Rem"))

        context.insert(
            Firearm(
                brand: "Glock",
                modelName: "19",
                purchasePriceCents: 50000,
                type: .pistol,
                action: .semiAuto
            )
        )
        context.insert(
            Firearm(
                brand: "Benelli",
                modelName: "M4",
                purchasePriceCents: 180000,
                type: .shotgun,
                action: .semiAuto
            )
        )
        context.insert(
            Firearm(
                brand: "Glock",
                modelName: "17",
                purchasePriceCents: 52000,
                type: .pistol,
                action: .semiAuto
            )
        )

        context.insert(
            Optic(
                brand: "Vortex",
                modelName: "Razor",
                type: .lpvo,
                minMagnification: 1,
                maxMagnification: 6,
                footprint: .picatinny,
                purchasePriceCents: 129999
            )
        )
        context.insert(
            Optic(
                brand: "Aimpoint",
                modelName: "T-2",
                type: .redDot,
                minMagnification: 1,
                maxMagnification: 1,
                footprint: .picatinny,
                purchasePriceCents: 80000
            )
        )
        context.insert(
            Optic(
                brand: "Aimpoint",
                modelName: "Acro",
                type: .redDot,
                minMagnification: 1,
                maxMagnification: 1,
                footprint: .acro,
                purchasePriceCents: 60000
            )
        )

        context.insert(
            Magazine(
                brand: "Magpul",
                modelName: "PMAG",
                count: 2,
                capacity: 30,
                purchasePriceCents: 3000
            )
        )
        context.insert(
            Magazine(
                brand: "CZ",
                modelName: "OEM",
                count: 3,
                capacity: 15,
                purchasePriceCents: 9000
            )
        )
        context.insert(
            Magazine(
                brand: "CZ",
                modelName: "Competition",
                count: 1,
                capacity: 20,
                purchasePriceCents: 5000
            )
        )

        context.insert(
            Attachment(
                brand: "SureFire",
                modelName: "X300",
                type: .light,
                purchasePriceCents: 28000
            )
        )
        context.insert(
            Attachment(
                brand: "BCM",
                modelName: "KAG",
                type: .handStop,
                purchasePriceCents: 2000
            )
        )
        context.insert(
            Attachment(
                brand: "BCM",
                modelName: "Vertical Grip",
                type: .grip,
                purchasePriceCents: 2500
            )
        )

        let lookupData = try service.fetchLookupData(in: context)

        XCTAssertEqual(lookupData.calibers.map(\.name), [".22 LR", ".223 Rem", "9mm"])
        XCTAssertEqual(lookupData.existingFirearms.map(\.displayName), ["Benelli M4", "Glock 17", "Glock 19"])
        XCTAssertEqual(lookupData.optics.map(\.displayName), ["Aimpoint Acro", "Aimpoint T-2", "Vortex Razor"])
        XCTAssertEqual(lookupData.magazines.map(\.displayName), ["CZ Competition", "CZ OEM", "Magpul PMAG"])
        XCTAssertEqual(lookupData.attachments.map(\.displayName), ["BCM KAG", "BCM Vertical Grip", "SureFire X300"])
    }
}
