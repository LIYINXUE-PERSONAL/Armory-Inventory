//
//  InventoryListServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class InventoryListServiceTests: XCTestCase {
    @MainActor
    func testFetchMethodsReturnEmptyCollectionsWhenContextHasNoInventory() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let service = InventoryListService()

        XCTAssertTrue(try service.fetchAttachments(in: context).isEmpty)
        XCTAssertTrue(try service.fetchMagazines(in: context).isEmpty)
        XCTAssertTrue(try service.fetchOptics(in: context).isEmpty)
        XCTAssertTrue(try service.fetchParts(in: context).isEmpty)
        XCTAssertTrue(try service.fetchFirearms(in: context).isEmpty)
    }

    @MainActor
    func testFetchMethodsSortBySortOrderThenCreatedAt() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let service = InventoryListService()

        let earlyDate = Date(timeIntervalSince1970: 100)
        let middleDate = Date(timeIntervalSince1970: 200)
        let laterDate = Date(timeIntervalSince1970: 300)

        let firstAttachment = Attachment(
            brand: "Magpul",
            modelName: "CTR",
            type: .stock,
            purchasePriceCents: 6500,
            sortOrder: 1,
            createdAt: middleDate
        )
        let secondAttachment = Attachment(
            brand: "BCM",
            modelName: "KAG",
            type: .handStop,
            purchasePriceCents: 2000,
            sortOrder: 0,
            createdAt: laterDate
        )
        let thirdAttachment = Attachment(
            brand: "SureFire",
            modelName: "M640DF",
            type: .light,
            purchasePriceCents: 32999,
            sortOrder: 1,
            createdAt: earlyDate
        )

        let firstMagazine = Magazine(
            brand: "CZ",
            modelName: "OEM",
            count: 3,
            capacity: 15,
            purchasePriceCents: 12000,
            sortOrder: 1,
            createdAt: middleDate
        )
        let secondMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            count: 5,
            capacity: 30,
            purchasePriceCents: 7500,
            sortOrder: 0,
            createdAt: laterDate
        )
        let thirdMagazine = Magazine(
            brand: "Mec-Gar",
            modelName: "Competition",
            count: 2,
            capacity: 17,
            purchasePriceCents: 9000,
            sortOrder: 1,
            createdAt: earlyDate
        )

        let firstOptic = Optic(
            brand: "Vortex",
            modelName: "Razor HD",
            type: .lpvo,
            minMagnification: 1,
            maxMagnification: 6,
            footprint: .picatinny,
            purchasePriceCents: 129999,
            sortOrder: 1,
            createdAt: middleDate
        )
        let secondOptic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 80000,
            sortOrder: 0,
            createdAt: laterDate
        )
        let thirdOptic = Optic(
            brand: "EOTech",
            modelName: "EXPS3",
            type: .holographic,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 69999,
            sortOrder: 1,
            createdAt: earlyDate
        )

        let firstFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto,
            sortOrder: 1,
            createdAt: middleDate
        )
        let secondFirearm = Firearm(
            brand: "CZ",
            modelName: "P-10 C",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto,
            sortOrder: 0,
            createdAt: laterDate
        )
        let thirdFirearm = Firearm(
            brand: "Benelli",
            modelName: "M4",
            purchasePriceCents: 190000,
            type: .shotgun,
            action: .semiAuto,
            sortOrder: 1,
            createdAt: earlyDate
        )
        let firstPart = Part(
            brand: "Geissele",
            modelName: "SSA-E",
            type: .trigger,
            purchasePriceCents: 24000,
            sortOrder: 1,
            createdAt: middleDate
        )
        let secondPart = Part(
            brand: "BCM",
            modelName: "MK2",
            type: .chargingHandle,
            purchasePriceCents: 8000,
            sortOrder: 0,
            createdAt: laterDate
        )
        let thirdPart = Part(
            brand: "Aero",
            modelName: "M4E1",
            type: .upperReceiver,
            purchasePriceCents: 12500,
            sortOrder: 1,
            createdAt: earlyDate
        )

        context.insert(firstAttachment)
        context.insert(secondAttachment)
        context.insert(thirdAttachment)
        context.insert(firstMagazine)
        context.insert(secondMagazine)
        context.insert(thirdMagazine)
        context.insert(firstOptic)
        context.insert(secondOptic)
        context.insert(thirdOptic)
        context.insert(firstPart)
        context.insert(secondPart)
        context.insert(thirdPart)
        context.insert(firstFirearm)
        context.insert(secondFirearm)
        context.insert(thirdFirearm)

        let attachments = try service.fetchAttachments(in: context)
        let magazines = try service.fetchMagazines(in: context)
        let optics = try service.fetchOptics(in: context)
        let parts = try service.fetchParts(in: context)
        let firearms = try service.fetchFirearms(in: context)

        XCTAssertEqual(attachments.map(\.displayName), ["BCM KAG", "SureFire M640DF", "Magpul CTR"])
        XCTAssertEqual(magazines.map(\.displayName), ["Magpul PMAG", "Mec-Gar Competition", "CZ OEM"])
        XCTAssertEqual(optics.map(\.displayName), ["Aimpoint T-2", "EOTech EXPS3", "Vortex Razor HD"])
        XCTAssertEqual(parts.map(\.displayName), ["BCM MK2", "Aero M4E1", "Geissele SSA-E"])
        XCTAssertEqual(firearms.map(\.displayName), ["CZ P-10 C", "Benelli M4", "Daniel Defense DDM4"])
    }
}
