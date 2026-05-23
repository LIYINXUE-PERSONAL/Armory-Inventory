//
//  AccessoryInventoryListViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/20/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AccessoryInventoryListViewModelTests: XCTestCase {
    func testGroupingDisplayNamesAndTotalsAreViewModelOwned() {
        let viewModel = AccessoryInventoryListViewModel()
        let chargingHandle = Part(
            brand: "Radian",
            modelName: "Raptor",
            type: .chargingHandle,
            purchasePriceCents: 9_000,
            sortOrder: 1
        )
        let boltCarrierGroup = Part(
            brand: "BCM",
            modelName: "BCG",
            type: .boltCarrierGroup,
            purchasePriceCents: 18_000,
            sortOrder: 0
        )
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let attachment = Attachment(brand: "BCM", modelName: "KAG", type: .handStop, purchasePriceCents: 2_000)
        let groupedParts = viewModel.groupedParts(
            [chargingHandle, boltCarrierGroup],
            sortOrderRaw: AccessoryItemSortOrder.manual.rawValue,
            sortDirectionRaw: AccessoryItemSortDirection.ascending.rawValue
        )
        let groupedOptics = viewModel.groupedOptics(
            [optic],
            sortOrderRaw: AccessoryItemSortOrder.model.rawValue,
            sortDirectionRaw: AccessoryItemSortDirection.descending.rawValue
        )
        let groupedAttachments = viewModel.groupedAttachments(
            [attachment],
            sortOrderRaw: "invalid",
            sortDirectionRaw: "invalid"
        )

        XCTAssertEqual(groupedParts[PartType.chargingHandle.rawValue]?.map(\.displayName), ["Radian Raptor"])
        XCTAssertEqual(groupedParts[PartType.boltCarrierGroup.rawValue]?.map(\.displayName), ["BCM BCG"])
        XCTAssertEqual(viewModel.groupedPartTypes(from: groupedParts), [PartType.boltCarrierGroup.rawValue, PartType.chargingHandle.rawValue])
        XCTAssertEqual(viewModel.partTypeDisplayName(for: PartType.chargingHandle.rawValue), "Charging Handle")
        XCTAssertEqual(viewModel.partTypeDisplayName(for: "custom part"), "custom part")
        XCTAssertEqual(groupedOptics[OpticType.redDot.rawValue]?.map { $0.displayName }, ["Aimpoint T-2"])
        XCTAssertEqual(viewModel.groupedOpticTypes(from: groupedOptics), [OpticType.redDot.rawValue])
        XCTAssertEqual(viewModel.opticTypeDisplayName(for: OpticType.redDot.rawValue), "Red Dot")
        XCTAssertEqual(viewModel.opticTypeDisplayName(for: "custom optic"), "custom optic")
        XCTAssertEqual(groupedAttachments[AttachmentType.handStop.rawValue]?.map(\.displayName), ["BCM KAG"])
        XCTAssertEqual(viewModel.groupedAttachmentTypes(from: groupedAttachments), [AttachmentType.handStop.rawValue])
        XCTAssertEqual(viewModel.attachmentTypeDisplayName(for: AttachmentType.handStop.rawValue), "Hand Stop")
        XCTAssertEqual(viewModel.attachmentTypeDisplayName(for: "custom attachment"), "custom attachment")
        XCTAssertEqual(viewModel.totalValueText(for: [chargingHandle, boltCarrierGroup]), "$270.00")
    }

    @MainActor
    func testDeletionIsBlockedForBuiltKitComponents() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AccessoryInventoryListViewModel()
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000)
        let kit = Kit(name: "Upper Kit", kind: .upperReceiver, status: .built)
        let component = KitComponent(category: .part, part: part)
        component.kit = kit
        kit.components = [component]

        context.insert(part)
        context.insert(kit)
        context.insert(component)
        try context.save()

        let groupedParts = viewModel.groupedParts(
            [part],
            sortOrderRaw: AccessoryItemSortOrder.manual.rawValue,
            sortDirectionRaw: AccessoryItemSortDirection.ascending.rawValue
        )
        let result = viewModel.deleteParts(
            at: IndexSet(integer: 0),
            in: PartType.boltCarrierGroup.rawValue,
            groupedParts: groupedParts,
            allParts: [part],
            kits: [kit],
            context: context
        )
        let remainingParts = try context.fetch(FetchDescriptor<Part>())

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.message, "Disassemble or edit the built/linked kit using BCM BCG before deleting it.")
        XCTAssertEqual(remainingParts.map(\.displayName), ["BCM BCG"])
    }

    @MainActor
    func testDeletionHandlesMissingGroupsAndDeletesUnreservedItems() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AccessoryInventoryListViewModel()
        let part = Part(brand: "Aero", modelName: "M4E1", type: .lowerReceiver, purchasePriceCents: 12_000, sortOrder: 5)
        let optic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let attachment = Attachment(brand: "BCM", modelName: "KAG", type: .handStop, purchasePriceCents: 2_000)
        context.insert(part)
        context.insert(optic)
        context.insert(attachment)
        try context.save()

        XCTAssertTrue(
            viewModel.deleteParts(
                at: IndexSet(integer: 0),
                in: "missing",
                groupedParts: [:],
                allParts: [part],
                kits: [],
                context: context
            ).isValid
        )

        let opticResult = viewModel.deleteOptics(
            at: IndexSet(integer: 0),
            in: OpticType.redDot.rawValue,
            groupedOptics: viewModel.groupedOptics(
                [optic],
                sortOrderRaw: AccessoryItemSortOrder.manual.rawValue,
                sortDirectionRaw: ""
            ),
            allOptics: [optic],
            kits: [],
            context: context
        )
        let attachmentResult = viewModel.deleteAttachments(
            at: IndexSet(integer: 0),
            in: AttachmentType.handStop.rawValue,
            groupedAttachments: viewModel.groupedAttachments(
                [attachment],
                sortOrderRaw: AccessoryItemSortOrder.manual.rawValue,
                sortDirectionRaw: ""
            ),
            allAttachments: [attachment],
            kits: [],
            context: context
        )

        XCTAssertTrue(opticResult.isValid)
        XCTAssertTrue(attachmentResult.isValid)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Optic>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Attachment>()).isEmpty)
    }
}
