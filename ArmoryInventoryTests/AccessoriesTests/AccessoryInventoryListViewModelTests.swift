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

    func testLinkedFirearmAndKitResolveThroughActiveKitComponents() {
        let viewModel = AccessoryInventoryListViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 120_000,
            type: .rifle,
            action: .semiAuto
        )
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000)
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
        let kit = Kit(name: "Upper Kit", kind: .upperReceiver, status: .linked, firearm: firearm)
        let partComponent = KitComponent(category: .part, part: part)
        let opticComponent = KitComponent(category: .optic, optic: optic)
        let attachmentComponent = KitComponent(category: .attachment, attachment: attachment)
        partComponent.kit = kit
        opticComponent.kit = kit
        attachmentComponent.kit = kit
        kit.components = [partComponent, opticComponent, attachmentComponent]

        XCTAssertEqual(viewModel.linkedFirearm(for: part, kits: [kit])?.displayName, "Daniel Defense DDM4")
        XCTAssertEqual(viewModel.linkedFirearm(for: optic, kits: [kit])?.displayName, "Daniel Defense DDM4")
        XCTAssertEqual(viewModel.linkedFirearm(for: attachment, kits: [kit])?.displayName, "Daniel Defense DDM4")
        XCTAssertEqual(viewModel.linkedKit(for: part, kits: [kit])?.displayName, "Upper Kit")
        XCTAssertEqual(viewModel.linkedKit(for: optic, kits: [kit])?.displayName, "Upper Kit")
        XCTAssertEqual(viewModel.linkedKit(for: attachment, kits: [kit])?.displayName, "Upper Kit")
    }

    func testDirectLinkedFirearmTakesPrecedenceOverKitFirearm() {
        let viewModel = AccessoryInventoryListViewModel()
        let directFirearm = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto
        )
        let kitFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 120_000,
            type: .rifle,
            action: .semiAuto
        )
        let part = Part(
            brand: "Apex",
            modelName: "Trigger",
            type: .trigger,
            purchasePriceCents: 12_000,
            firearm: directFirearm
        )
        let kit = Kit(name: "Lower Kit", kind: .lowerReceiver, status: .linked, firearm: kitFirearm)
        let component = KitComponent(category: .part, part: part)
        component.kit = kit
        kit.components = [component]

        XCTAssertEqual(viewModel.linkedFirearm(for: part, kits: [kit])?.displayName, "Glock 19")
        XCTAssertEqual(viewModel.linkedKit(for: part, kits: [kit])?.displayName, "Lower Kit")
    }

    func testStatusFilteringUsesDirectAndKitDerivedFirearmLinks() {
        let viewModel = AccessoryInventoryListViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 120_000,
            type: .rifle,
            action: .semiAuto
        )
        let linkedPart = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000, firearm: firearm)
        let kitLinkedPart = Part(brand: "Radian", modelName: "Raptor", type: .chargingHandle, purchasePriceCents: 9_000)
        let unlinkedPart = Part(brand: "Aero", modelName: "M4E1", type: .upperReceiver, purchasePriceCents: 12_000)
        let linkedOptic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000,
            firearm: firearm
        )
        let unlinkedOptic = Optic(
            brand: "EOTech",
            modelName: "EXPS3",
            type: .holographic,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 65_000
        )
        let linkedAttachment = Attachment(brand: "SureFire", modelName: "M640", type: .light, purchasePriceCents: 32_000, firearm: firearm)
        let unlinkedAttachment = Attachment(brand: "BCM", modelName: "KAG", type: .handStop, purchasePriceCents: 2_000)
        let kit = Kit(name: "Upper Kit", kind: .upperReceiver, status: .linked, firearm: firearm)
        let component = KitComponent(category: .part, part: kitLinkedPart)
        component.kit = kit
        kit.components = [component]

        XCTAssertEqual(
            viewModel.filteredParts(
                [linkedPart, kitLinkedPart, unlinkedPart],
                selectedStatusFilter: .linked,
                kits: [kit]
            ).map(\.displayName),
            ["BCM BCG", "Radian Raptor"]
        )
        XCTAssertEqual(
            viewModel.filteredParts(
                [linkedPart, kitLinkedPart, unlinkedPart],
                selectedStatusFilter: .unlinked,
                kits: [kit]
            ).map(\.displayName),
            ["Aero M4E1"]
        )
        XCTAssertEqual(
            viewModel.filteredOptics(
                [linkedOptic, unlinkedOptic],
                selectedStatusFilter: .unlinked,
                kits: []
            ).map(\.displayName),
            ["EOTech EXPS3"]
        )
        XCTAssertEqual(
            viewModel.filteredAttachments(
                [linkedAttachment, unlinkedAttachment],
                selectedStatusFilter: .linked,
                kits: []
            ).map(\.displayName),
            ["SureFire M640"]
        )
    }

    func testTypeFilteringCanCombineWithStatusFiltering() {
        let viewModel = AccessoryInventoryListViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 120_000,
            type: .rifle,
            action: .semiAuto
        )
        let linkedTrigger = Part(brand: "Apex", modelName: "Trigger", type: .trigger, purchasePriceCents: 12_000, firearm: firearm)
        let unlinkedTrigger = Part(brand: "Geissele", modelName: "SSA", type: .trigger, purchasePriceCents: 24_000)
        let unlinkedBarrel = Part(brand: "Criterion", modelName: "Core", type: .barrel, purchasePriceCents: 29_000)
        let redDot = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let scope = Optic(
            brand: "Nightforce",
            modelName: "ATACR",
            type: .scope,
            minMagnification: 1,
            maxMagnification: 8,
            footprint: .picatinny,
            purchasePriceCents: 280_000
        )
        let light = Attachment(brand: "SureFire", modelName: "M640", type: .light, purchasePriceCents: 32_000)
        let grip = Attachment(brand: "BCM", modelName: "Mod 3", type: .grip, purchasePriceCents: 2_000)

        XCTAssertEqual(
            viewModel.filteredParts(
                [linkedTrigger, unlinkedTrigger, unlinkedBarrel],
                selectedType: PartType.trigger.rawValue,
                selectedStatusFilter: .unlinked,
                kits: []
            ).map(\.displayName),
            ["Geissele SSA"]
        )
        XCTAssertEqual(
            viewModel.filteredOptics(
                [redDot, scope],
                selectedType: OpticType.scope.rawValue,
                selectedStatusFilter: .all,
                kits: []
            ).map(\.displayName),
            ["Nightforce ATACR"]
        )
        XCTAssertEqual(
            viewModel.filteredAttachments(
                [light, grip],
                selectedType: AttachmentType.light.rawValue,
                selectedStatusFilter: .all,
                kits: []
            ).map(\.displayName),
            ["SureFire M640"]
        )
    }

    func testFlatAccessorySortingUsesSelectedSortOrder() {
        let viewModel = AccessoryInventoryListViewModel()
        let lowerValue = Part(brand: "Aero", modelName: "M4E1", type: .lowerReceiver, purchasePriceCents: 12_000)
        let higherValue = Part(brand: "Geissele", modelName: "SSA", type: .trigger, purchasePriceCents: 24_000)

        XCTAssertEqual(
            viewModel.sortedParts(
                [lowerValue, higherValue],
                sortOrderRaw: AccessoryItemSortOrder.value.rawValue,
                sortDirectionRaw: AccessoryItemSortDirection.descending.rawValue
            ).map(\.displayName),
            ["Geissele SSA", "Aero M4E1"]
        )
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
