//
//  KitModelsTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/14/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class KitModelsTests: XCTestCase {
    @MainActor
    func testKitComponentSupportsOnlyPartsOpticsAndAttachments() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let part = Part(brand: "BCM", modelName: "Upper", type: .upperReceiver, purchasePriceCents: 10_000)
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let attachment = Attachment(brand: "BCM", modelName: "Grip", type: .grip, purchasePriceCents: 2_000)
        let magazine = Magazine(brand: "Magpul", modelName: "PMAG", capacity: 30, purchasePriceCents: 1_500)
        let kit = Kit(name: "Upper", kind: .upperReceiver)
        let partComponent = KitComponent(category: .part, slot: .receiver, part: part)
        let opticComponent = KitComponent(category: .optic, slot: .optic, optic: optic)
        let attachmentComponent = KitComponent(category: .attachment, slot: .foregrip, attachment: attachment)

        context.insert(part)
        context.insert(optic)
        context.insert(attachment)
        context.insert(magazine)
        context.insert(kit)
        for component in [partComponent, opticComponent, attachmentComponent] {
            component.kit = kit
            context.insert(component)
        }
        kit.components = [partComponent, opticComponent, attachmentComponent]
        try context.save()

        XCTAssertEqual(kit.components.count, 3)
        XCTAssertEqual(Set(kit.components.map(\.componentCategory)), Set([.part, .optic, .attachment]))
        XCTAssertNil(magazine.firearm)
        XCTAssertEqual(kit.totalValueCents, 82_000)
    }

    @MainActor
    func testStatusReservationFlagsMatchLifecycle() {
        XCTAssertTrue(KitStatus.built.reservesComponents)
        XCTAssertTrue(KitStatus.linked.reservesComponents)
    }
}
