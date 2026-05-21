//
//  KitEligibilityServiceTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/14/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class KitEligibilityServiceTests: XCTestCase {
    private let service = KitEligibilityService()

    @MainActor
    func testDirectFirearmLinkedItemCannotBeSelectedForKit() throws {
        let firearm = Firearm(brand: "Daniel Defense", modelName: "DDM4", purchasePriceCents: 100_000, type: .rifle, action: .semiAuto)
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000, firearm: firearm)

        XCTAssertFalse(service.canSelectForKit(part, kits: [], excluding: nil))
    }

    @MainActor
    func testBuiltAndLinkedKitsReserveItems() throws {
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000)
        let builtKit = Kit(name: "Built", kind: .upperReceiver, status: .built)
        let linkedKit = Kit(name: "Linked", kind: .upperReceiver, status: .linked)
        let builtComponent = KitComponent(category: .part, slot: .boltCarrierGroup, part: part)
        let linkedComponent = KitComponent(category: .part, slot: .boltCarrierGroup, part: part)
        builtComponent.kit = builtKit
        builtKit.components = [builtComponent]
        linkedComponent.kit = linkedKit
        linkedKit.components = [linkedComponent]

        XCTAssertFalse(service.canSelectForKit(part, kits: [builtKit], excluding: nil))
        XCTAssertFalse(service.canSelectForKit(part, kits: [linkedKit], excluding: nil))
        XCTAssertFalse(service.canSelectForDirectFirearm(part, kits: [builtKit]))
    }

    @MainActor
    func testBuildValidationFailsWhenItemWasClaimedByAnotherKit() throws {
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000)
        let editedKit = Kit(name: "Edited", kind: .upperReceiver, status: .built)
        let claimingKit = Kit(name: "Claim", kind: .upperReceiver, status: .built)
        let editedComponent = KitComponent(category: .part, slot: .boltCarrierGroup, part: part)
        let claimingComponent = KitComponent(category: .part, slot: .boltCarrierGroup, part: part)
        editedComponent.kit = editedKit
        editedKit.components = [editedComponent]
        claimingComponent.kit = claimingKit
        claimingKit.components = [claimingComponent]

        let result = service.validationResultForBuild(
            components: editedKit.components,
            kits: [editedKit, claimingKit],
            excluding: editedKit
        )

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "BCM BCG is already reserved by another built or linked kit.")
    }
}
