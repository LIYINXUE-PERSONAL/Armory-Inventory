//
//  OpticLookupServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class OpticLookupServiceTests: XCTestCase {
    @MainActor
    func testFetchExistingOpticsReturnsEmptyCollectionWhenNoOpticsExist() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let service = OpticLookupService()

        XCTAssertTrue(try service.fetchExistingOptics(in: context).isEmpty)
    }

    @MainActor
    func testFetchExistingOpticsSortsByBrandThenModelName() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let service = OpticLookupService()

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

        XCTAssertEqual(
            try service.fetchExistingOptics(in: context).map(\.displayName),
            ["Aimpoint Acro", "Aimpoint T-2", "Vortex Razor"]
        )
    }
}
