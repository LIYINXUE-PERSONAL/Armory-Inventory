//
//  AddFirearmViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/2/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddFirearmViewModelTests: XCTestCase {
    func testResolutionAndValidationHandleTrimmedAndInvalidValues() {
        let viewModel = AddFirearmViewModel()
        let existing = [
            Firearm(
                brand: "Glock",
                modelName: "19",
                serialNumber: "ABC123",
                purchasePriceCents: 50000,
                type: .pistol,
                action: .semiAuto
            )
        ]

        XCTAssertNil(viewModel.resolvedActionDetail(selectedAction: .bolt, customAction: "Ignored"))
        XCTAssertEqual(viewModel.resolvedActionDetail(selectedAction: .other, customAction: "  Roller-Delayed  "), "Roller-Delayed")
        XCTAssertNil(viewModel.resolvedColorDetail(selectedColor: .black, customColor: "Ignored"))
        XCTAssertEqual(viewModel.resolvedColorDetail(selectedColor: .other, customColor: "  Burnt Bronze  "), "Burnt Bronze")
        XCTAssertEqual(viewModel.trimmedValue("  DANIEL DEFENSE "), "DANIEL DEFENSE")
        XCTAssertEqual(viewModel.optionalValue("  Range Rifle "), "Range Rifle")
        XCTAssertEqual(viewModel.normalizedSerialNumber(" ab-12 cd_34 "), "AB12CD34")
        XCTAssertNil(viewModel.optionalSerialNumber(" - _ "))
        XCTAssertEqual(viewModel.barrelLength(from: " 16.3 "), 16.3)
        XCTAssertEqual(viewModel.purchasePriceCents(from: " 1299.95 "), 129995)
        XCTAssertNil(viewModel.barrelLength(from: "-1"))
        XCTAssertNil(viewModel.purchasePriceCents(from: ""))
        XCTAssertTrue(viewModel.duplicateExists(serialNumber: " abc123 ", in: existing))
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Glock",
                modelName: "19",
                serialNumber: "ABC123",
                selectedType: .pistol,
                selectedAction: .semiAuto,
                actionDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "bad",
                barrelLengthText: "bad",
                duplicateExists: false,
                magazines: [],
                selectedMagazinePatterns: [],
                caliber: nil,
                owningFirearm: nil
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Glock",
                modelName: "19",
                serialNumber: "ABC123",
                selectedType: .pistol,
                selectedAction: .other,
                actionDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "100",
                barrelLengthText: "",
                duplicateExists: false,
                magazines: [],
                selectedMagazinePatterns: [],
                caliber: nil,
                owningFirearm: nil
            )
        )
        XCTAssertTrue(
            viewModel.canAdd(
                brand: "Glock",
                modelName: "19",
                serialNumber: "",
                selectedType: .pistol,
                selectedAction: .semiAuto,
                actionDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "100",
                barrelLengthText: "",
                duplicateExists: false,
                magazines: [],
                selectedMagazinePatterns: [],
                caliber: nil,
                owningFirearm: nil
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Glock",
                modelName: "19",
                serialNumber: "ABC123",
                selectedType: .pistol,
                selectedAction: .semiAuto,
                actionDetail: nil,
                selectedColor: .other,
                colorDetail: nil,
                purchasePriceText: "100",
                barrelLengthText: "",
                duplicateExists: false,
                magazines: [],
                selectedMagazinePatterns: [],
                caliber: nil,
                owningFirearm: nil
            )
        )
    }

    func testMagazinePatternDetailTextReturnsSummaryForMatchingMagazines() {
        let viewModel = AddFirearmViewModel()
        let pattern = FirearmMagazinePatternReference(
            id: "catalog:ar15-stanag-223-556-300blk",
            kind: .catalog,
            displayName: nil
        )
        let matchingMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: pattern.id,
            patternKind: .catalog,
            count: 2,
            capacity: 30,
            purchasePriceCents: 1500
        )
        let nonMatchingMagazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            patternID: "catalog:glock-double-stack-9mm-compact",
            patternKind: .catalog,
            count: 1,
            capacity: 15,
            purchasePriceCents: 1200
        )
        let summaryFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto
        )

        XCTAssertEqual(
            viewModel.magazinePatternDetailText(
                for: pattern,
                magazines: [matchingMagazine, nonMatchingMagazine],
                summaryFirearm: summaryFirearm
            ),
            "2 magazines • 60 Rounds"
        )
        XCTAssertEqual(
            viewModel.magazinePatternDetailText(
                for: pattern,
                magazines: [nonMatchingMagazine],
                summaryFirearm: summaryFirearm
            ),
            ""
        )
    }

    @MainActor
    func testRelationshipSelectionAndAvailabilityHelpersRespectAssignments() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()

        let currentFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto
        )
        let otherFirearm = Firearm(
            brand: "CZ",
            modelName: "Shadow 2",
            purchasePriceCents: 120000,
            type: .pistol,
            action: .semiAuto
        )
        let freeOptic = Optic(
            brand: "Aimpoint",
            modelName: "T-2",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 80000
        )
        let currentOptic = Optic(
            brand: "EOTech",
            modelName: "EXPS3",
            type: .holographic,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .picatinny,
            purchasePriceCents: 65000,
            firearm: currentFirearm
        )
        let otherOptic = Optic(
            brand: "Trijicon",
            modelName: "SRO",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .rmr,
            purchasePriceCents: 55000,
            firearm: otherFirearm
        )
        let rifleCaliber = Caliber(name: "5.56 NATO")
        let pistolCaliber = Caliber(name: "9mm")
        let freeMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            capacity: 30,
            purchasePriceCents: 1500,
            caliber: rifleCaliber
        )
        let currentMagazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            patternID: "catalog:glock-double-stack-9mm-full-size-compact",
            patternKind: .catalog,
            capacity: 17,
            purchasePriceCents: 2500,
            caliber: pistolCaliber,
            firearm: currentFirearm
        )
        let otherMagazine = Magazine(
            brand: "Mec-Gar",
            modelName: "CZ 75",
            capacity: 16,
            purchasePriceCents: 3200,
            caliber: pistolCaliber,
            firearm: otherFirearm
        )
        let freeAttachment = Attachment(
            brand: "SureFire",
            modelName: "X300",
            type: .light,
            purchasePriceCents: 28000
        )
        let currentAttachment = Attachment(
            brand: "BCM",
            modelName: "KAG",
            type: .handStop,
            purchasePriceCents: 2000,
            firearm: currentFirearm
        )
        let otherAttachment = Attachment(
            brand: "B5",
            modelName: "Bravo",
            type: .stock,
            purchasePriceCents: 5800,
            firearm: otherFirearm
        )
        let freePart = Part(
            brand: "Geissele",
            modelName: "SSA-E",
            type: .trigger,
            purchasePriceCents: 24000
        )
        let currentPart = Part(
            brand: "BCM",
            modelName: "MK2",
            type: .chargingHandle,
            purchasePriceCents: 8000,
            firearm: currentFirearm
        )
        let otherPart = Part(
            brand: "Apex",
            modelName: "Action Enhancement",
            type: .trigger,
            purchasePriceCents: 12500,
            firearm: otherFirearm
        )

        context.insert(currentFirearm)
        context.insert(otherFirearm)
        context.insert(rifleCaliber)
        context.insert(pistolCaliber)
        context.insert(freeOptic)
        context.insert(currentOptic)
        context.insert(otherOptic)
        context.insert(freeMagazine)
        context.insert(currentMagazine)
        context.insert(otherMagazine)
        context.insert(freeAttachment)
        context.insert(currentAttachment)
        context.insert(otherAttachment)
        context.insert(freePart)
        context.insert(currentPart)
        context.insert(otherPart)
        try context.save()

        currentFirearm.optics = [currentOptic]
        currentFirearm.magazines = [currentMagazine]
        currentFirearm.attachments = [currentAttachment]
        currentFirearm.parts = [currentPart]

        let selectedOpticIDs = viewModel.selectedOpticIDs(for: currentFirearm)
        let selectedMagazinePatterns = viewModel.selectedMagazinePatterns(for: currentFirearm)
        let selectedAttachmentIDs = viewModel.selectedAttachmentIDs(for: currentFirearm)
        let selectedPartIDs = viewModel.selectedPartIDs(for: currentFirearm)

        XCTAssertEqual(selectedOpticIDs, [currentOptic.persistentModelID])
        XCTAssertEqual(selectedMagazinePatterns, [FirearmMagazinePatternReference(pattern: currentMagazine.resolvedPattern)])
        XCTAssertEqual(selectedAttachmentIDs, [currentAttachment.persistentModelID])
        XCTAssertEqual(selectedPartIDs, [currentPart.persistentModelID])

        XCTAssertEqual(
            Set(
                viewModel.availableOptics(
                    from: [freeOptic, currentOptic, otherOptic],
                    selectedIDs: [otherOptic.persistentModelID],
                    firearm: currentFirearm,
                    kits: []
                )
                .map(\.persistentModelID)
            ),
            [freeOptic.persistentModelID, currentOptic.persistentModelID, otherOptic.persistentModelID]
        )
        XCTAssertEqual(
            Set(
                viewModel.linkedMagazines(
                    from: [freeMagazine, currentMagazine, otherMagazine],
                    selectedPatterns: selectedMagazinePatterns,
                    firearmType: .pistol,
                    action: .semiAuto,
                    caliber: currentMagazine.caliber
                )
                .map(\.persistentModelID)
            ),
            [currentMagazine.persistentModelID]
        )
        XCTAssertEqual(
            Set(
                viewModel.availableAttachments(
                    from: [freeAttachment, currentAttachment, otherAttachment],
                    selectedIDs: [],
                    firearm: currentFirearm,
                    kits: []
                )
                .map(\.persistentModelID)
            ),
            [freeAttachment.persistentModelID, currentAttachment.persistentModelID]
        )
        XCTAssertEqual(
            Set(
                viewModel.availableParts(
                    from: [freePart, currentPart, otherPart],
                    selectedIDs: [],
                    firearm: currentFirearm,
                    kits: []
                )
                .map(\.persistentModelID)
            ),
            [freePart.persistentModelID, currentPart.persistentModelID]
        )

        XCTAssertEqual(
            viewModel.resolvedOptics(
                from: [freeOptic, currentOptic, otherOptic],
                selectedIDs: [freeOptic.persistentModelID, otherOptic.persistentModelID]
            )
            .map(\.persistentModelID),
            [freeOptic.persistentModelID, otherOptic.persistentModelID]
        )
        XCTAssertEqual(
            viewModel.resolvedAttachments(
                from: [freeAttachment, currentAttachment, otherAttachment],
                selectedIDs: [freeAttachment.persistentModelID, currentAttachment.persistentModelID]
            )
            .map(\.persistentModelID),
            [freeAttachment.persistentModelID, currentAttachment.persistentModelID]
        )
        XCTAssertEqual(
            viewModel.resolvedParts(
                from: [freePart, currentPart, otherPart],
                selectedIDs: [freePart.persistentModelID, otherPart.persistentModelID]
            )
            .map(\.persistentModelID),
            [freePart.persistentModelID, otherPart.persistentModelID]
        )
    }

    func testPresentationHelpersReflectEditingState() {
        let viewModel = AddFirearmViewModel()
        let itemID = Firearm(
            brand: "Test",
            modelName: "ID Source",
            purchasePriceCents: 1,
            type: .other,
            action: .other
        ).persistentModelID

        XCTAssertEqual(
            viewModel.toggledSelection(
                currentSelection: [],
                itemID: itemID,
                isEditing: false
            ),
            []
        )
        XCTAssertEqual(
            viewModel.toggledSelection(
                currentSelection: [],
                itemID: itemID,
                isEditing: true
            ),
            [itemID]
        )
        XCTAssertEqual(
            viewModel.toggledSelection(
                currentSelection: [itemID],
                itemID: itemID,
                isEditing: true
            ),
            []
        )

        XCTAssertTrue(viewModel.isReadOnly(hasFirearm: true, isEditing: false))
        XCTAssertFalse(viewModel.isReadOnly(hasFirearm: false, isEditing: false))
        XCTAssertFalse(viewModel.isReadOnly(hasFirearm: true, isEditing: true))

        XCTAssertTrue(viewModel.showsPurchaseSection(showValueInDetails: true, isReadOnly: true))
        XCTAssertTrue(viewModel.showsPurchaseSection(showValueInDetails: false, isReadOnly: false))
        XCTAssertFalse(viewModel.showsPurchaseSection(showValueInDetails: false, isReadOnly: true))

        XCTAssertEqual(viewModel.primaryButtonTitle(hasFirearm: false, isEditing: false), "Add")
        XCTAssertEqual(viewModel.primaryButtonTitle(hasFirearm: true, isEditing: false), "Edit")
        XCTAssertEqual(viewModel.primaryButtonTitle(hasFirearm: true, isEditing: true), "Save")
        XCTAssertTrue(viewModel.showsPostTaxTotalSection(hasFirearm: true, showValueInDetails: true))
        XCTAssertFalse(viewModel.showsPostTaxTotalSection(hasFirearm: true, showValueInDetails: false))
        XCTAssertEqual(viewModel.taxedAmountCents(baseAmountCents: 10_000, taxRate: 8.25), 10_825)
        XCTAssertEqual(
            viewModel.totalValueWithTaxText(
                firearmPriceCents: 100_000,
                accessoriesSubtotalCents: 50_000,
                firearmsTaxRate: 10,
                accessoriesTaxRate: 5
            ),
            "$1,625.00"
        )
    }

    @MainActor
    func testInitialValuesMagazinePatternsAndKitHelpers() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()
        let caliber = Caliber(name: "5.56 NATO")
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180_050,
            type: .rifle,
            action: .semiAuto,
            barrelLengthInches: 14.5,
            caliber: caliber
        )
        let selectedPattern = FirearmMagazinePatternReference(
            id: "catalog:glock-double-stack-9mm-full-size-compact",
            kind: .catalog,
            displayName: nil
        )
        let selectedKit = Kit(name: "Linked Kit", kind: .upperReceiver, status: .linked, firearm: firearm)
        let builtKit = Kit(name: "Built Kit", kind: .lowerReceiver, status: .built)
        let linkedElsewhere = Kit(
            name: "Other Kit",
            kind: .optics,
            status: .linked,
            firearm: Firearm(brand: "CZ", modelName: "Shadow 2", purchasePriceCents: 120_000, type: .pistol, action: .semiAuto)
        )
        context.insert(caliber)
        context.insert(firearm)
        context.insert(selectedKit)
        context.insert(builtKit)
        context.insert(linkedElsewhere)
        try context.save()

        let arMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            capacity: 30,
            purchasePriceCents: 1_500,
            caliber: caliber
        )

        XCTAssertEqual(viewModel.initialPurchasePriceText(for: firearm), "1,800.50")
        XCTAssertEqual(viewModel.initialBarrelLengthText(for: firearm), "14.5")
        XCTAssertEqual(viewModel.selectedKitIDs(for: firearm, kits: [selectedKit, builtKit]), [selectedKit.persistentModelID])
        XCTAssertEqual(
            viewModel.linkedKits(from: [selectedKit, builtKit], selectedIDs: [selectedKit.persistentModelID]).map(\.persistentModelID),
            [selectedKit.persistentModelID]
        )
        XCTAssertEqual(
            Set(viewModel.availableKits(from: [selectedKit, builtKit, linkedElsewhere], selectedIDs: [selectedKit.persistentModelID], firearm: firearm).map(\.persistentModelID)),
            [selectedKit.persistentModelID, builtKit.persistentModelID]
        )
        XCTAssertEqual(
            viewModel.availableMagazinePatterns(
                from: [arMagazine],
                firearmType: .rifle,
                action: .semiAuto,
                caliber: caliber,
                selectedPatterns: [selectedPattern]
            ).first,
            selectedPattern
        )
        XCTAssertEqual(
            viewModel.toggledMagazinePatternSelection(
                currentSelection: [],
                pattern: selectedPattern,
                isEditing: false
            ),
            []
        )
        XCTAssertEqual(
            viewModel.toggledMagazinePatternSelection(
                currentSelection: [],
                pattern: selectedPattern,
                isEditing: true
            ),
            [selectedPattern]
        )
        XCTAssertEqual(
            viewModel.toggledMagazinePatternSelection(
                currentSelection: [selectedPattern],
                pattern: selectedPattern,
                isEditing: true
            ),
            []
        )
    }

    @MainActor
    func testKitManagedItemsSummaryFallbackAndDeleteFirearm() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()
        let firearm = Firearm(brand: "Aero", modelName: "M4E1", purchasePriceCents: 80_000, type: .rifle, action: .semiAuto)
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
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 20_000)
        let staleUpdatedAt = Date(timeIntervalSince1970: 1)
        let kit = Kit(name: "Upper Kit", kind: .upperReceiver, status: .linked, firearm: firearm, updatedAt: staleUpdatedAt)
        let opticComponent = KitComponent(category: .optic, optic: optic)
        let attachmentComponent = KitComponent(category: .attachment, attachment: attachment)
        let partComponent = KitComponent(category: .part, part: part)
        kit.components = [opticComponent, attachmentComponent, partComponent]
        context.insert(firearm)
        context.insert(optic)
        context.insert(attachment)
        context.insert(part)
        context.insert(kit)
        context.insert(opticComponent)
        context.insert(attachmentComponent)
        context.insert(partComponent)
        try context.save()

        let summary = viewModel.currentFirearmForSummary(
            firearm: nil,
            brand: "SIG",
            modelName: "P320",
            purchasePriceCents: 70_000,
            type: .pistol,
            action: .semiAuto
        )

        XCTAssertEqual(summary.displayName, "SIG P320")
        XCTAssertEqual(
            viewModel.currentFirearmForSummary(firearm: firearm, brand: "", modelName: "", purchasePriceCents: 0, type: .other, action: .other).persistentModelID,
            firearm.persistentModelID
        )
        XCTAssertEqual(viewModel.managedOptics(from: [kit]).map(\.persistentModelID), [optic.persistentModelID])
        XCTAssertEqual(viewModel.managedAttachments(from: [kit]).map(\.persistentModelID), [attachment.persistentModelID])
        XCTAssertEqual(viewModel.managedParts(from: [kit]).map(\.persistentModelID), [part.persistentModelID])
        XCTAssertEqual(
            viewModel.managingKitName(
                for: Optic(
                    brand: "Loose",
                    modelName: "Dot",
                    type: .redDot,
                    minMagnification: 1,
                    maxMagnification: 1,
                    footprint: .aimpointMicro,
                    purchasePriceCents: 1
                ),
                kits: []
            ),
            "Kit"
        )
        XCTAssertEqual(viewModel.managingKitName(for: Attachment(brand: "Loose", modelName: "Grip", type: .grip, purchasePriceCents: 1), kits: []), "Kit")
        XCTAssertEqual(viewModel.managingKitName(for: Part(brand: "Loose", modelName: "Part", type: .other, purchasePriceCents: 1), kits: []), "Kit")

        let deleteResult = viewModel.deleteFirearm(firearm, in: context)

        XCTAssertTrue(deleteResult.isValid)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Firearm>()).isEmpty)
        let remainingKit = try XCTUnwrap(context.fetch(FetchDescriptor<Kit>()).first)
        XCTAssertNil(remainingKit.firearm)
        XCTAssertEqual(remainingKit.kitStatus, .built)
        XCTAssertGreaterThan(remainingKit.updatedAt, staleUpdatedAt)
    }

    @MainActor
    func testKitEffectiveItemsNamesAndLinkPersistenceHelpers() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180_000,
            type: .rifle,
            action: .semiAuto
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
        let part = Part(brand: "BCM", modelName: "BCG", type: .boltCarrierGroup, purchasePriceCents: 20_000)
        let kit = Kit(name: "Upper Kit", kind: .upperReceiver)
        let opticComponent = KitComponent(category: .optic, optic: optic)
        let attachmentComponent = KitComponent(category: .attachment, attachment: attachment)
        let partComponent = KitComponent(category: .part, part: part)
        opticComponent.kit = kit
        attachmentComponent.kit = kit
        partComponent.kit = kit
        kit.components = [opticComponent, attachmentComponent, partComponent]

        context.insert(firearm)
        context.insert(optic)
        context.insert(attachment)
        context.insert(part)
        context.insert(kit)
        context.insert(opticComponent)
        context.insert(attachmentComponent)
        context.insert(partComponent)
        try context.save()

        XCTAssertEqual(viewModel.effectiveOptics(resolvedOptics: [optic], managedOptics: [optic]).map(\.displayName), ["Aimpoint T-2"])
        XCTAssertEqual(viewModel.effectiveAttachments(resolvedAttachments: [], managedAttachments: [attachment]).map(\.displayName), ["BCM KAG"])
        XCTAssertEqual(viewModel.effectiveParts(resolvedParts: [], managedParts: [part]).map(\.displayName), ["BCM BCG"])
        XCTAssertEqual(
            viewModel.accessoriesSubtotalCents(
                optics: [optic],
                magazines: [],
                attachments: [attachment],
                parts: [part]
            ),
            92_000
        )
        XCTAssertEqual(viewModel.managingKitName(for: optic, kits: [kit]), "Upper Kit")
        XCTAssertEqual(viewModel.managingKitName(for: attachment, kits: [kit]), "Upper Kit")
        XCTAssertEqual(viewModel.managingKitName(for: part, kits: [kit]), "Upper Kit")

        let linkResult = viewModel.saveKitLinks(
            firearm: firearm,
            selectedKitIDs: [kit.persistentModelID],
            kits: [kit],
            in: context
        )

        XCTAssertTrue(linkResult.isValid)
        XCTAssertEqual(kit.firearm?.persistentModelID, firearm.persistentModelID)
        XCTAssertEqual(kit.kitStatus, .linked)

        let unlinkResult = viewModel.saveKitLinks(
            firearm: firearm,
            selectedKitIDs: [],
            kits: [kit],
            in: context
        )

        XCTAssertTrue(unlinkResult.isValid)
        XCTAssertNil(kit.firearm)
        XCTAssertEqual(kit.kitStatus, .built)
    }

    @MainActor
    func testNextSortOrderUsesHighestExistingValue() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()

        context.insert(
            Firearm(
                brand: "Colt",
                modelName: "6920",
                purchasePriceCents: 110000,
                type: .rifle,
                action: .semiAuto,
                sortOrder: 2
            )
        )
        context.insert(
            Firearm(
                brand: "Remington",
                modelName: "870",
                purchasePriceCents: 45000,
                type: .shotgun,
                action: .pump,
                sortOrder: 7
            )
        )

        XCTAssertEqual(viewModel.nextSortOrder(in: context), 8)
    }

    @MainActor
    func testAddFirearmPersistsModel() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()
        let purchaseDate = Date(timeIntervalSince1970: 1_234_567)
        let caliber = Caliber(name: "9mm")
        let optic = Optic(
            brand: "Holosun",
            modelName: "507C",
            type: .redDot,
            minMagnification: 1,
            maxMagnification: 1,
            footprint: .rmr,
            purchasePriceCents: 31000
        )
        let magazine = Magazine(
            brand: "CZ",
            modelName: "P-10",
            capacity: 15,
            purchasePriceCents: 3500
        )
        let attachment = Attachment(
            brand: "Streamlight",
            modelName: "TLR-7A",
            type: .light,
            purchasePriceCents: 14000
        )
        let part = Part(
            brand: "Apex",
            modelName: "Action Enhancement",
            type: .trigger,
            purchasePriceCents: 12500
        )
        context.insert(caliber)
        context.insert(optic)
        context.insert(magazine)
        context.insert(attachment)
        context.insert(part)

        let didAdd = viewModel.addFirearm(
            brand: "  cZ  ",
            modelName: " p-10 c ",
            nickname: "carry gun",
            serialNumber: " cz-999 ",
            purchaseDate: purchaseDate,
            lastCleanedDate: Date(timeIntervalSince1970: 22_222),
            purchasePriceCents: 49999,
            type: .pistol,
            action: .semiAuto,
            actionDetail: nil,
            color: .black,
            colorDetail: nil,
            barrelLengthInches: 4.02,
            notes: "Optics ready",
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)],
            caliber: caliber,
            optics: [optic],
            magazines: [magazine],
            attachments: [attachment],
            parts: [part],
            canAdd: true,
            to: context
        )

        let firearms = try context.fetch(FetchDescriptor<Firearm>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(firearms.count, 1)
        XCTAssertEqual(firearms.first?.brand, "cZ")
        XCTAssertEqual(firearms.first?.modelName, "p-10 c")
        XCTAssertEqual(firearms.first?.nickname, "carry gun")
        XCTAssertEqual(firearms.first?.serialNumber, "CZ999")
        XCTAssertEqual(firearms.first?.purchasePriceCents, 49999)
        XCTAssertEqual(firearms.first?.firearmType, .pistol)
        XCTAssertEqual(firearms.first?.firearmAction, .semiAuto)
        XCTAssertEqual(firearms.first?.firearmColor, .black)
        XCTAssertEqual(firearms.first?.caliber?.name, "9mm")
        XCTAssertEqual(firearms.first?.purchaseDate, purchaseDate)
        XCTAssertEqual(firearms.first?.lastCleanedDate, Date(timeIntervalSince1970: 22_222))
        XCTAssertEqual(firearms.first?.optics.map(\.displayName), ["Holosun 507C"])
        XCTAssertEqual(
            firearms.first?.supportedMagazinePatterns,
            [FirearmMagazinePatternReference(pattern: magazine.resolvedPattern)]
        )
        XCTAssertEqual(firearms.first?.attachments.map(\.displayName), ["Streamlight TLR-7A"])
        XCTAssertEqual(firearms.first?.parts.map(\.displayName), ["Apex Action Enhancement"])
    }

    @MainActor
    func testAddFirearmReturnsFalseWhenBlocked() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()

        let didAdd = viewModel.addFirearm(
            brand: "Benelli",
            modelName: "M4",
            nickname: nil,
            serialNumber: "",
            purchaseDate: .now,
            lastCleanedDate: nil,
            purchasePriceCents: 189900,
            type: .shotgun,
            action: .semiAuto,
            actionDetail: nil,
            color: nil,
            colorDetail: nil,
            barrelLengthInches: 18.5,
            notes: nil,
            supportedMagazinePatterns: [],
            caliber: nil,
            optics: [],
            magazines: [],
            attachments: [],
            parts: [],
            canAdd: false,
            to: context
        )

        let firearms = try context.fetch(FetchDescriptor<Firearm>())

        XCTAssertFalse(didAdd)
        XCTAssertTrue(firearms.isEmpty)
    }

    @MainActor
    func testUpdateFirearmPersistsEditedValues() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: ".45 ACP")
        context.insert(caliber)
        let firearm = Firearm(
            brand: "Glock",
            modelName: "19",
            nickname: "Carry",
            serialNumber: "ABC123",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto,
            color: .black,
            barrelLengthInches: 4.0,
            notes: "Old"
        )
        context.insert(firearm)

        let viewModel = AddFirearmViewModel()
        let didSave = viewModel.updateFirearm(
            firearm,
            brand: "smith & wesson",
            modelName: "m&p 2.0",
            nickname: "range gun",
            serialNumber: "",
            purchaseDate: Date(timeIntervalSince1970: 9_999),
            lastCleanedDate: Date(timeIntervalSince1970: 15_555),
            purchasePriceCents: 65000,
            type: .pistol,
            action: .other,
            actionDetail: "DA/SA",
            color: .other,
            colorDetail: "Two Tone",
            barrelLengthInches: 4.25,
            notes: "Updated",
            supportedMagazinePatterns: [],
            caliber: caliber,
            optics: [],
            magazines: [],
            attachments: [],
            parts: [],
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(firearm.brand, "smith & wesson")
        XCTAssertEqual(firearm.modelName, "m&p 2.0")
        XCTAssertEqual(firearm.nickname, "range gun")
        XCTAssertNil(firearm.serialNumber)
        XCTAssertEqual(firearm.lastCleanedDate, Date(timeIntervalSince1970: 15_555))
        XCTAssertEqual(firearm.purchasePriceCents, 65000)
        XCTAssertEqual(firearm.firearmAction, .other)
        XCTAssertEqual(firearm.actionDetail, "DA/SA")
        XCTAssertEqual(firearm.firearmColor, .other)
        XCTAssertEqual(firearm.colorDetail, "Two Tone")
        XCTAssertEqual(firearm.caliber?.name, ".45 ACP")
        XCTAssertEqual(firearm.notes, "Updated")
    }

    func testCanAddReturnsFalseForSelectedMagazineCompatibilityFailure() {
        let viewModel = AddFirearmViewModel()
        let caliber = Caliber(name: "9mm")
        let incompatibleMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            capacity: 30,
            purchasePriceCents: 1500,
            caliber: Caliber(name: "5.56 NATO")
        )

        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Glock",
                modelName: "19",
                serialNumber: "",
                selectedType: .pistol,
                selectedAction: .semiAuto,
                actionDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "500",
                barrelLengthText: "",
                duplicateExists: false,
                magazines: [incompatibleMagazine],
                selectedMagazinePatterns: [],
                caliber: caliber,
                owningFirearm: nil
            )
        )
    }

    func testCanAddReturnsFalseWhenSelectedMagazinePatternExcludesLinkedMagazine() {
        let viewModel = AddFirearmViewModel()
        let caliber = Caliber(name: "9mm")
        let magazine = Magazine(
            brand: "Staccato",
            modelName: "2011",
            patternID: "catalog:2011-double-stack-9mm",
            patternKind: .catalog,
            capacity: 20,
            purchasePriceCents: 8000,
            caliber: caliber
        )
        let selectedPatterns = [
            FirearmMagazinePatternReference(
                id: "catalog:glock-double-stack-9mm-full-size-compact",
                kind: .catalog,
                displayName: nil
            )
        ]

        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Staccato",
                modelName: "P",
                serialNumber: "",
                selectedType: .pistol,
                selectedAction: .semiAuto,
                actionDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "500",
                barrelLengthText: "",
                duplicateExists: false,
                magazines: [magazine],
                selectedMagazinePatterns: selectedPatterns,
                caliber: caliber,
                owningFirearm: nil
            )
        )
    }

    func testAvailableMagazinesFiltersToSelectedPatterns() {
        let viewModel = AddFirearmViewModel()
        let caliber = Caliber(name: "9mm")
        let glockMagazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            patternID: "catalog:glock-double-stack-9mm-full-size-compact",
            patternKind: .catalog,
            capacity: 17,
            purchasePriceCents: 2500,
            caliber: caliber
        )
        let staccatoMagazine = Magazine(
            brand: "Staccato",
            modelName: "2011",
            patternID: "catalog:2011-double-stack-9mm",
            patternKind: .catalog,
            capacity: 20,
            purchasePriceCents: 8000,
            caliber: caliber
        )
        let selectedPatterns = [
            FirearmMagazinePatternReference(
                id: "catalog:glock-double-stack-9mm-full-size-compact",
                kind: .catalog,
                displayName: nil
            )
        ]

        XCTAssertEqual(
            viewModel.linkedMagazines(
                from: [glockMagazine, staccatoMagazine],
                selectedPatterns: selectedPatterns,
                firearmType: .pistol,
                action: .semiAuto,
                caliber: caliber
            ).map(\.displayName),
            ["Glock OEM"]
        )
    }

    @MainActor
    func testAddFirearmPersistsSelectedMagazinePatterns() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddFirearmViewModel()
        let selectedPatterns = [
            FirearmMagazinePatternReference(
                id: "catalog:glock-double-stack-9mm-full-size-compact",
                kind: .catalog,
                displayName: nil
            ),
            FirearmMagazinePatternReference(
                id: "legacy:cz-shadow-pattern",
                kind: .legacy,
                displayName: "CZ Shadow Legacy"
            )
        ]

        let didAdd = viewModel.addFirearm(
            brand: "CZ",
            modelName: "Shadow 2",
            nickname: nil,
            serialNumber: "",
            purchaseDate: .now,
            lastCleanedDate: nil,
            purchasePriceCents: 150000,
            type: .pistol,
            action: .semiAuto,
            actionDetail: nil,
            color: nil,
            colorDetail: nil,
            barrelLengthInches: nil,
            notes: nil,
            supportedMagazinePatterns: selectedPatterns,
            caliber: nil,
            optics: [],
            magazines: [],
            attachments: [],
            parts: [],
            canAdd: true,
            to: context
        )

        let firearms = try context.fetch(FetchDescriptor<Firearm>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(firearms.first?.supportedMagazinePatterns, selectedPatterns)
    }

    @MainActor
    func testUpdateFirearmReturnsFalseWithoutMutatingWhenSelectedMagazineBecomesInvalid() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let originalCaliber = Caliber(name: "9mm")
        let updatedCaliber = Caliber(name: ".45 ACP")
        let firearm = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto,
            caliber: originalCaliber
        )
        let magazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            capacity: 17,
            purchasePriceCents: 2500,
            caliber: originalCaliber,
            firearm: firearm
        )
        context.insert(originalCaliber)
        context.insert(updatedCaliber)
        context.insert(firearm)
        context.insert(magazine)

        let viewModel = AddFirearmViewModel()
        let didSave = viewModel.updateFirearm(
            firearm,
            brand: "Staccato",
            modelName: "P",
            nickname: nil,
            serialNumber: "",
            purchaseDate: .now,
            lastCleanedDate: nil,
            purchasePriceCents: 250000,
            type: .pistol,
            action: .semiAuto,
            actionDetail: nil,
            color: nil,
            colorDetail: nil,
            barrelLengthInches: 4.4,
            notes: nil,
            supportedMagazinePatterns: [],
            caliber: updatedCaliber,
            optics: [],
            magazines: [magazine],
            attachments: [],
            parts: [],
            canSave: true,
            in: context
        )

        XCTAssertFalse(didSave)
        XCTAssertEqual(firearm.brand, "Glock")
        XCTAssertEqual(firearm.modelName, "19")
        XCTAssertEqual(firearm.caliber?.name, "9mm")
    }
}
