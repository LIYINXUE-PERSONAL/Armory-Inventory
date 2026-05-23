//
//  AddKitViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 5/20/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddKitViewModelTests: XCTestCase {
    @MainActor
    func testPresentationHelpersReturnLocalizedTitlesAndVisibility() {
        let viewModel = AddKitViewModel()
        let kit = Kit(name: "Upper", kind: .upperReceiver, status: .built)
        let linkedKit = Kit(name: "Linked", kind: .custom, status: .linked)

        XCTAssertEqual(viewModel.initialName(for: kit), "Upper")
        XCTAssertEqual(viewModel.initialName(for: nil), "")
        XCTAssertEqual(viewModel.initialNotes(for: Kit(name: "Notes", kind: .custom, notes: "Range setup")), "Range setup")
        XCTAssertEqual(viewModel.initialKind(for: nil), .upperReceiver)
        XCTAssertEqual(viewModel.initialKind(for: linkedKit), .custom)
        XCTAssertEqual(viewModel.navigationTitle(for: nil), "New Kit")
        XCTAssertEqual(viewModel.navigationTitle(for: kit), "Kit Details")
        XCTAssertEqual(viewModel.primarySaveTitle(for: nil), "Build Kit")
        XCTAssertEqual(viewModel.primarySaveTitle(for: kit), "Save")
        XCTAssertTrue(viewModel.shouldShowDisassembleButton(for: kit))
        XCTAssertTrue(viewModel.shouldShowDisassembleButton(for: linkedKit))
        XCTAssertFalse(viewModel.shouldShowDisassembleButton(for: nil))
        XCTAssertEqual(viewModel.optionalValue("  Notes  "), "Notes")
        XCTAssertNil(viewModel.optionalValue("   "))
        XCTAssertEqual(viewModel.displayName(name: "  ", kind: .optics), "Optics Kit")
        XCTAssertEqual(viewModel.displayName(name: "  Match Kit  ", kind: .custom), "Match Kit")
        XCTAssertEqual(viewModel.emptySelectionText(for: .part), "No parts selected.")
        XCTAssertEqual(viewModel.emptySelectionText(for: .attachment), "No attachments selected.")
        XCTAssertEqual(viewModel.pickerTitle(for: .part), "Select Parts")
        XCTAssertEqual(viewModel.pickerTitle(for: .optic), "Select Optics")
        XCTAssertEqual(viewModel.pickerTitle(for: .attachment), "Select Attachments")
        XCTAssertEqual(viewModel.pickerEmptyTitle(for: .part), "No Parts Available")
        XCTAssertEqual(viewModel.pickerEmptyTitle(for: .optic), "No Optics Available")
        XCTAssertEqual(viewModel.pickerEmptyTitle(for: .attachment), "No Attachments Available")
    }

    @MainActor
    func testSelectionsRowsComponentsAndPickerItemsAreViewModelOwned() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddKitViewModel()
        let part = Part(brand: "BCM", modelName: "MK2", type: .upperReceiver, purchasePriceCents: 20_000)
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

        let selections = [
            KitComponentSelection(category: .part, itemID: part.persistentModelID),
            KitComponentSelection(category: .optic, itemID: optic.persistentModelID),
            KitComponentSelection(category: .attachment, itemID: attachment.persistentModelID)
        ]

        XCTAssertEqual(viewModel.selectedIDs(from: selections, category: .part), [part.persistentModelID])
        let initialSelections = viewModel.initialSelections(
            for: Kit(
                name: "Upper",
                kind: .upperReceiver,
                components: [
                    KitComponent(category: .part, part: part),
                    KitComponent(category: .optic, optic: optic),
                    KitComponent(category: .attachment, attachment: attachment),
                    KitComponent(category: .part)
                ]
            )
        )
        XCTAssertEqual(Set(initialSelections), Set(selections))
        XCTAssertEqual(
            viewModel.toggledSelection([], category: .part, itemID: part.persistentModelID),
            [selections[0]]
        )
        XCTAssertEqual(
            viewModel.toggledSelection([selections[0]], category: .part, itemID: part.persistentModelID),
            []
        )
        XCTAssertEqual(
            viewModel.components(from: selections, parts: [part], optics: [optic], attachments: [attachment]).map(\.componentCategory),
            [.part, .optic, .attachment]
        )
        XCTAssertEqual(
            viewModel.selectedComponentRows(
                for: .optic,
                selections: selections,
                parts: [part],
                optics: [optic],
                attachments: [attachment]
            ),
            [
                AddKitComponentRow(
                    selection: selections[1],
                    title: "Aimpoint T-2",
                    subtitle: "Red Dot • 1x"
                )
            ]
        )
        XCTAssertEqual(
            viewModel.componentTitle(
                for: KitComponentSelection(category: .optic, itemID: part.persistentModelID),
                parts: [part],
                optics: [],
                attachments: [attachment]
            ),
            "Missing Optic"
        )
        XCTAssertEqual(
            viewModel.componentTitle(
                for: KitComponentSelection(category: .part, itemID: optic.persistentModelID),
                parts: [],
                optics: [optic],
                attachments: [attachment]
            ),
            "Missing Part"
        )
        XCTAssertEqual(
            viewModel.componentTitle(
                for: KitComponentSelection(category: .attachment, itemID: optic.persistentModelID),
                parts: [part],
                optics: [optic],
                attachments: []
            ),
            "Missing Attachment"
        )
        XCTAssertEqual(
            viewModel.componentSubtitle(
                for: KitComponentSelection(category: .optic, itemID: part.persistentModelID),
                parts: [part],
                optics: [],
                attachments: [attachment]
            ),
            "Optic"
        )
        XCTAssertEqual(viewModel.componentValueCents(from: selections, parts: [part], optics: [optic], attachments: [attachment]), 92_000)

        let partItems = viewModel.partPickerItems(parts: [part], selections: selections, kits: [], editing: nil)
        XCTAssertEqual(partItems.first?.title, "BCM MK2")
        XCTAssertEqual(partItems.first?.subtitle, "Upper Receiver")
        XCTAssertEqual(partItems.first?.isSelected, true)

        let opticItems = viewModel.opticPickerItems(optics: [optic], selections: selections, kits: [], editing: nil)
        XCTAssertEqual(opticItems.count, 1)
        XCTAssertEqual(opticItems.first?.title, "Aimpoint T-2")
        XCTAssertEqual(opticItems.first?.subtitle, "Red Dot • 1x")
        XCTAssertEqual(opticItems.first?.isSelected, true)

        let attachmentItems = viewModel.attachmentPickerItems(attachments: [attachment], selections: selections, kits: [], editing: nil)
        XCTAssertEqual(attachmentItems.first?.title, "BCM KAG")
        XCTAssertEqual(attachmentItems.first?.subtitle, "Hand Stop")
        XCTAssertEqual(attachmentItems.first?.isSelected, true)
    }

    @MainActor
    func testAvailabilityValidationSaveAndDisassemble() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddKitViewModel()
        let firearm = Firearm(brand: "Daniel Defense", modelName: "DDM4", purchasePriceCents: 100_000, type: .rifle, action: .semiAuto)
        let unavailablePart = Part(brand: "BCM", modelName: "Linked", type: .upperReceiver, purchasePriceCents: 20_000, firearm: firearm)
        let selectedUnavailablePart = Part(brand: "BCM", modelName: "Selected", type: .chargingHandle, purchasePriceCents: 8_000, firearm: firearm)
        let freePart = Part(brand: "Aero", modelName: "M4E1", type: .lowerReceiver, purchasePriceCents: 12_000)
        let freeOptic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let freeAttachment = Attachment(brand: "BCM", modelName: "KAG", type: .handStop, purchasePriceCents: 2_000)
        context.insert(firearm)
        context.insert(unavailablePart)
        context.insert(selectedUnavailablePart)
        context.insert(freePart)
        context.insert(freeOptic)
        context.insert(freeAttachment)
        try context.save()

        XCTAssertEqual(
            viewModel.availableParts(
                from: [unavailablePart, selectedUnavailablePart, freePart],
                selectedIDs: [selectedUnavailablePart.persistentModelID],
                kits: [],
                editing: nil
            ).map(\.displayName),
            ["BCM Selected", "Aero M4E1"]
        )
        XCTAssertFalse(viewModel.validationResultForBuild(components: [], kits: [], editing: nil).isValid)

        let components = [
            KitComponent(category: .part, part: freePart),
            KitComponent(category: .optic, optic: freeOptic),
            KitComponent(category: .attachment, attachment: freeAttachment)
        ]
        let saveResult = viewModel.saveKit(
            nil,
            name: "  ",
            kind: .upperReceiver,
            notes: "Range",
            components: components,
            targetStatus: .built,
            kits: [],
            in: context
        )
        let kits = try context.fetch(FetchDescriptor<Kit>())

        XCTAssertTrue(saveResult.isValid)
        XCTAssertEqual(kits.count, 1)
        XCTAssertEqual(kits.first?.displayName, "Upper Receiver Kit")
        XCTAssertEqual(kits.first?.components.count, 3)
        XCTAssertEqual(viewModel.nextSortOrder(in: context), 1)

        let updatedResult = viewModel.saveKit(
            kits[0],
            name: "Updated Kit",
            kind: .custom,
            notes: nil,
            components: [KitComponent(category: .part, part: freePart)],
            targetStatus: .built,
            kits: [kits[0]],
            in: context
        )

        XCTAssertTrue(updatedResult.isValid)
        XCTAssertEqual(kits[0].displayName, "Updated Kit")
        XCTAssertEqual(kits[0].kitKind, .custom)
        XCTAssertEqual(kits[0].components.count, 1)

        let disassembleResult = viewModel.disassembleKit(kits[0], in: context)
        let remainingKits = try context.fetch(FetchDescriptor<Kit>())

        XCTAssertTrue(disassembleResult.isValid)
        XCTAssertTrue(remainingKits.isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Part>()).map(\.displayName).sorted(), ["Aero M4E1", "BCM Linked", "BCM Selected"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Optic>()).map(\.displayName), ["Aimpoint T-2"])
        XCTAssertEqual(try context.fetch(FetchDescriptor<Attachment>()).map(\.displayName), ["BCM KAG"])
    }

    @MainActor
    func testDiscardDeletesKitAndLinkedComponents() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddKitViewModel()
        let retainedPart = Part(brand: "Aero", modelName: "Lower", type: .lowerReceiver, purchasePriceCents: 12_000)
        let discardedPart = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 18_000)
        let discardedOptic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .aimpointMicro,
            purchasePriceCents: 70_000
        )
        let discardedAttachment = Attachment(brand: "BCM", modelName: "KAG", type: .handStop, purchasePriceCents: 2_000)
        context.insert(retainedPart)
        context.insert(discardedPart)
        context.insert(discardedOptic)
        context.insert(discardedAttachment)
        try context.save()

        let saveResult = viewModel.saveKit(
            nil,
            name: "Discard Target",
            kind: .upperReceiver,
            notes: nil,
            components: [
                KitComponent(category: .part, part: discardedPart),
                KitComponent(category: .optic, optic: discardedOptic),
                KitComponent(category: .attachment, attachment: discardedAttachment)
            ],
            targetStatus: .built,
            kits: [],
            in: context
        )
        let kit = try XCTUnwrap(context.fetch(FetchDescriptor<Kit>()).first)

        XCTAssertTrue(saveResult.isValid)
        XCTAssertTrue(viewModel.discardKit(kit, in: context).isValid)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Kit>()).isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Part>()).map(\.displayName), ["Aero Lower"])
        XCTAssertTrue(try context.fetch(FetchDescriptor<Optic>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Attachment>()).isEmpty)
    }
}
