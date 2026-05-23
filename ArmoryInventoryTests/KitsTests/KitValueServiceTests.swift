//
//  KitValueServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/14/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class KitValueServiceTests: XCTestCase {
    @MainActor
    func testKitValueDeduplicatesRepeatedComponentIdentity() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        context.insert(optic)
        try context.save()

        let first = KitComponent(category: .optic, slot: .optic, optic: optic)
        let second = KitComponent(category: .optic, slot: .support, optic: optic)

        XCTAssertEqual(KitValueService.totalValueCents(for: [first, second]), 70_000)
    }

    @MainActor
    func testFirearmEffectiveValueDeduplicatesDirectAndKitManagedItems() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let firearm = Firearm(brand: "Daniel Defense", modelName: "DDM4", purchasePriceCents: 100_000, type: .rifle, action: .semiAuto)
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000,
            firearm: firearm
        )
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000)
        let kit = Kit(name: "Upper", kind: .upperReceiver, status: .linked, firearm: firearm)
        let opticComponent = KitComponent(category: .optic, slot: .optic, optic: optic)
        let partComponent = KitComponent(category: .part, slot: .boltCarrierGroup, part: part)
        opticComponent.kit = kit
        partComponent.kit = kit
        kit.components = [opticComponent, partComponent]
        firearm.optics = [optic]

        context.insert(firearm)
        context.insert(optic)
        context.insert(part)
        context.insert(kit)
        context.insert(opticComponent)
        context.insert(partComponent)
        try context.save()

        let total = KitValueService.effectiveTotalValueCents(
            for: firearm,
            linkedKits: [kit],
            compatibleMagazines: []
        )

        XCTAssertEqual(total, 188_000)
    }
}
