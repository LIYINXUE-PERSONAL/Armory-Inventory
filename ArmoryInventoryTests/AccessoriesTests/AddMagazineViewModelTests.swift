//
//  AddMagazineViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/3/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddMagazineViewModelTests: XCTestCase {
    func testResolutionAndValidationHandleTrimmedAndInvalidValues() {
        let viewModel = AddMagazineViewModel()

        XCTAssertEqual(viewModel.initialPurchasePriceText(for: nil), "0.00")
        XCTAssertEqual(viewModel.trimmedValue("  PMAG "), "PMAG")
        XCTAssertEqual(viewModel.optionalValue("  Gen M3 "), "Gen M3")
        XCTAssertNil(viewModel.optionalValue(" "))
        XCTAssertEqual(viewModel.purchasePriceCents(from: " 15.99 "), 1599)
        XCTAssertNil(viewModel.purchasePriceCents(from: "bad"))
        XCTAssertEqual(viewModel.capacity(from: " 30 "), 30)
        XCTAssertNil(viewModel.capacity(from: "0"))
        XCTAssertEqual(viewModel.count(from: " 4 "), 4)
        XCTAssertNil(viewModel.count(from: "-1"))
        XCTAssertNil(viewModel.resolvedColorDetail(selectedColor: .black, customColor: "Ignored"))
        XCTAssertEqual(viewModel.resolvedColorDetail(selectedColor: .other, customColor: "  Smoke  "), "Smoke")
        XCTAssertNil(viewModel.linkedFirearm(for: nil, unlinkFirearm: false))
        XCTAssertEqual(viewModel.purchasePriceWithTaxText(purchasePriceCents: nil, taxRate: 5), "--")
        XCTAssertTrue(viewModel.isReadOnly(hasMagazine: true, isEditing: false))
        XCTAssertFalse(viewModel.showsPurchaseSection(showValueInDetails: false, isReadOnly: true))
        XCTAssertEqual(viewModel.primaryButtonTitle(hasMagazine: false, isEditing: false), "Add")
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "",
                modelName: "PMAG",
                countText: "1",
                capacityText: "30",
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "10",
                patternSelection: .catalog("catalog:ar15-stanag-223-556-300blk"),
                manualPatternName: "",
                compatibleCaliberNames: [],
                firearm: nil
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Magpul",
                modelName: "PMAG",
                countText: "1",
                capacityText: "30",
                selectedColor: .other,
                colorDetail: nil,
                purchasePriceText: "10",
                patternSelection: .catalog("catalog:ar15-stanag-223-556-300blk"),
                manualPatternName: "",
                compatibleCaliberNames: [],
                firearm: nil
            )
        )
        XCTAssertTrue(
            viewModel.canAdd(
                brand: "Magpul",
                modelName: "PMAG",
                countText: "3",
                capacityText: "30",
                selectedColor: .black,
                colorDetail: nil,
                purchasePriceText: "10",
                patternSelection: .catalog("catalog:ar15-stanag-223-556-300blk"),
                manualPatternName: "",
                compatibleCaliberNames: [],
                firearm: nil
            )
        )
        XCTAssertEqual(viewModel.initialPatternSelection(for: nil), .custom)
        XCTAssertEqual(viewModel.initialManualPatternName(for: nil), "")
    }

    func testPatternSelectionMetadataAndPresentationHelpers() {
        let viewModel = AddMagazineViewModel()
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180_000,
            type: .rifle,
            action: .semiAuto,
            caliber: Caliber(name: "5.56 NATO")
        )
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            capacity: 30,
            purchasePriceCents: 1_599,
            firearm: firearm
        )
        let customPattern = MagazinePattern.custom(
            id: UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!,
            displayName: "P320 Legion",
            familyLabel: "P320 Legion",
            supportedCaliberNames: ["9mm"]
        )

        XCTAssertEqual(MagazinePatternSelection.catalog("catalog:ar15-stanag-223-556-300blk").id, "catalog:catalog:ar15-stanag-223-556-300blk")
        XCTAssertEqual(MagazinePatternSelection.existingCustom(customPattern).id, "existing-custom:\(customPattern.id)")
        XCTAssertEqual(MagazinePatternSelection.legacy.id, "legacy")
        XCTAssertEqual(MagazinePatternSelection.custom.id, "custom")
        XCTAssertFalse(MagazinePatternSelection.catalog(customPattern.id).requiresManualName)
        XCTAssertTrue(MagazinePatternSelection.legacy.requiresManualName)
        XCTAssertTrue(MagazinePatternSelection.custom.allowsManualCaliberSelection)
        XCTAssertFalse(MagazinePatternSelection.existingCustom(customPattern).allowsManualCaliberSelection)
        XCTAssertEqual(viewModel.initialPurchasePriceText(for: magazine), "15.99")
        XCTAssertEqual(viewModel.linkedFirearm(for: magazine, unlinkFirearm: false)?.displayName, "Daniel Defense DDM4")
        XCTAssertNil(viewModel.linkedFirearm(for: magazine, unlinkFirearm: true))
        XCTAssertEqual(viewModel.purchasePriceWithTaxText(purchasePriceCents: 10_000, taxRate: 8.25), "$108.25")
        XCTAssertFalse(viewModel.isReadOnly(hasMagazine: false, isEditing: false))
        XCTAssertTrue(viewModel.showsPurchaseSection(showValueInDetails: true, isReadOnly: true))
        XCTAssertEqual(viewModel.primaryButtonTitle(hasMagazine: true, isEditing: false), "Edit")
        XCTAssertEqual(viewModel.primaryButtonTitle(hasMagazine: true, isEditing: true), "Save")
    }

    func testPatternSelectionResolvesTitlesDescriptionsAndCalibers() {
        let viewModel = AddMagazineViewModel()
        let firearm = Firearm(
            brand: "Glock",
            modelName: "19",
            purchasePriceCents: 50_000,
            type: .pistol,
            action: .semiAuto,
            caliber: Caliber(name: "9mm")
        )
        let customPattern = MagazinePattern.custom(
            id: UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!,
            displayName: "P320 Legion",
            familyLabel: "P320 Legion",
            supportedCaliberNames: ["9mm"]
        )
        let existingCustomMagazine = Magazine(
            brand: "SIG",
            modelName: "OEM",
            patternID: customPattern.id,
            patternKind: .custom,
            patternDisplayName: customPattern.displayName,
            patternSupportedCaliberNames: customPattern.compatibility.supportedCaliberNames,
            capacity: 17,
            purchasePriceCents: 4_000
        )
        let invalidCatalogMagazine = Magazine(
            brand: "Legacy",
            modelName: "Tube",
            patternID: "catalog:missing",
            patternKind: .catalog,
            capacity: 10,
            purchasePriceCents: 2_000
        )

        XCTAssertEqual(viewModel.initialPatternSelection(for: existingCustomMagazine), .existingCustom(customPattern))
        XCTAssertEqual(viewModel.initialPatternSelection(for: invalidCatalogMagazine), .custom)
        XCTAssertEqual(viewModel.initialCompatibleCaliberNames(for: existingCustomMagazine), ["9mm"])
        XCTAssertEqual(
            viewModel.toggledCompatibleCaliberSelection(currentSelection: [], caliberName: " 9mm ", isEditing: false),
            []
        )
        XCTAssertEqual(
            viewModel.toggledCompatibleCaliberSelection(currentSelection: [], caliberName: " ", isEditing: true),
            []
        )
        XCTAssertEqual(
            viewModel.toggledCompatibleCaliberSelection(currentSelection: [], caliberName: " 9mm ", isEditing: true),
            ["9mm"]
        )
        XCTAssertEqual(
            viewModel.toggledCompatibleCaliberSelection(currentSelection: ["9mm"], caliberName: "9mm", isEditing: true),
            []
        )
        XCTAssertFalse(viewModel.suggestedCatalogPatterns(firearm: firearm).isEmpty)
        XCTAssertFalse(viewModel.additionalCatalogPatterns(firearm: firearm).contains { $0.id == "catalog:glock-double-stack-9mm-full-size-compact" })
        XCTAssertEqual(
            viewModel.selectedPatternTitle(
                selection: .catalog("catalog:glock-double-stack-9mm-full-size-compact"),
                manualPatternName: "",
                brand: "Glock",
                modelName: "OEM",
                compatibleCaliberNames: [],
                firearm: firearm
            ),
            "Glock 17 Pattern"
        )
        XCTAssertEqual(
            viewModel.selectedPatternDescription(
                selection: .existingCustom(customPattern),
                manualPatternName: "",
                brand: "SIG",
                modelName: "OEM",
                compatibleCaliberNames: [],
                firearm: nil
            ),
            "9mm"
        )
        XCTAssertEqual(
            viewModel.selectedPatternDescription(
                selection: .legacy,
                manualPatternName: "Legacy Tube",
                brand: "",
                modelName: "",
                compatibleCaliberNames: [],
                firearm: nil
            ),
            "Legacy pattern names stay visible and editable for existing data."
        )
        XCTAssertEqual(
            viewModel.selectedPatternDescription(
                selection: .custom,
                manualPatternName: "Match Tube",
                brand: "",
                modelName: "",
                compatibleCaliberNames: [],
                firearm: nil
            ),
            "Custom pattern names are stored exactly as entered."
        )
        XCTAssertEqual(
            viewModel.resolvedSupportedCaliberNames(
                selection: .custom,
                manualPatternName: "Match Tube",
                brand: "",
                modelName: "",
                compatibleCaliberNames: [" 9mm ", ".38 Super", ""],
                firearm: nil
            ),
            [".38 Super", "9mm"]
        )
    }

    func testCanAddReturnsFalseForMagazineCaliberMismatchAgainstLinkedFirearm() {
        let viewModel = AddMagazineViewModel()
        let firearmCaliber = Caliber(name: ".45 ACP")
        let firearm = Firearm(
            brand: "Staccato",
            modelName: "P",
            purchasePriceCents: 250000,
            type: .pistol,
            action: .semiAuto,
            caliber: firearmCaliber
        )

        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Atlas",
                modelName: "2011",
                countText: "2",
                capacityText: "20",
                selectedColor: .black,
                colorDetail: nil,
                purchasePriceText: "75",
                patternSelection: .catalog("catalog:2011-double-stack-9mm"),
                manualPatternName: "",
                compatibleCaliberNames: [],
                firearm: firearm
            )
        )
    }

    func testCanAddRequiresManualPatternNameForCustomSelection() {
        let viewModel = AddMagazineViewModel()

        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Magpul",
                modelName: "PMAG",
                countText: "1",
                capacityText: "30",
                selectedColor: .black,
                colorDetail: nil,
                purchasePriceText: "20",
                patternSelection: .custom,
                manualPatternName: "",
                compatibleCaliberNames: [],
                firearm: nil
            )
        )
    }

    @MainActor
    func testAddMagazinePersistsModel() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()
        let purchaseDate = Date(timeIntervalSince1970: 1_234_567)
        let caliber = Caliber(name: "9mm")
        let firearm = Firearm(
            brand: "CZ",
            modelName: "P-10 C",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto,
            caliber: caliber
        )
        context.insert(caliber)
        context.insert(firearm)

        let didAdd = viewModel.addMagazine(
            brand: "  CZ ",
            modelName: " OEM ",
            count: 5,
            capacity: 15,
            purchaseDate: purchaseDate,
            purchasePriceCents: 17500,
            color: .black,
            colorDetail: nil,
            notes: "Range set",
            patternSelection: .custom,
            manualPatternName: "CZ OEM",
            compatibleCaliberNames: ["9mm"],
            firearm: firearm,
            canAdd: true,
            to: context
        )

        let magazines = try context.fetch(FetchDescriptor<Magazine>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(magazines.count, 1)
        XCTAssertEqual(magazines.first?.brand, "CZ")
        XCTAssertEqual(magazines.first?.modelName, "OEM")
        XCTAssertEqual(magazines.first?.count, 5)
        XCTAssertEqual(magazines.first?.capacity, 15)
        XCTAssertEqual(magazines.first?.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(magazines.first?.firearm?.displayName, "CZ P-10 C")
        XCTAssertEqual(magazines.first?.purchaseDate, purchaseDate)
        XCTAssertEqual(magazines.first?.sortOrder, 0)
        XCTAssertEqual(magazines.first?.storedPatternKind, .custom)
        XCTAssertEqual(magazines.first?.patternDisplayName, "CZ OEM")
    }

    @MainActor
    func testAddMagazineReturnsFalseWhenBlocked() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()

        let didAdd = viewModel.addMagazine(
            brand: "Glock",
            modelName: "OEM",
            count: 2,
            capacity: 17,
            purchaseDate: .now,
            purchasePriceCents: 5000,
            color: nil,
            colorDetail: nil,
            notes: nil,
            patternSelection: .catalog("catalog:glock-double-stack-9mm-full-size-compact"),
            manualPatternName: "",
            compatibleCaliberNames: [],
            firearm: nil,
            canAdd: false,
            to: context
        )

        XCTAssertFalse(didAdd)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Magazine>()).isEmpty)
    }

    @MainActor
    func testAddMagazineAllowsUnlinkedCatalogPatternMagazine() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()
        let didAdd = viewModel.addMagazine(
            brand: "Magpul",
            modelName: "PMAG",
            count: 3,
            capacity: 30,
            purchaseDate: .now,
            purchasePriceCents: 4500,
            color: .black,
            colorDetail: nil,
            notes: nil,
            patternSelection: .catalog("catalog:ar15-stanag-223-556-300blk"),
            manualPatternName: "",
            compatibleCaliberNames: [],
            firearm: nil,
            canAdd: true,
            to: context
        )

        let magazines = try context.fetch(FetchDescriptor<Magazine>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(magazines.count, 1)
        XCTAssertNil(magazines.first?.firearm)
        XCTAssertEqual(magazines.first?.storedPatternKind, .catalog)
        XCTAssertEqual(magazines.first?.patternID, "catalog:ar15-stanag-223-556-300blk")
    }

    @MainActor
    func testAddMagazinePersistsExplicitCustomPattern() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()
        let didAdd = viewModel.addMagazine(
            brand: "Atlas",
            modelName: "Premium",
            count: 2,
            capacity: 20,
            purchaseDate: .now,
            purchasePriceCents: 12000,
            color: .black,
            colorDetail: nil,
            notes: nil,
            patternSelection: .custom,
            manualPatternName: "Match Tube",
            compatibleCaliberNames: ["9mm", ".38 Super"],
            firearm: nil,
            canAdd: true,
            to: context
        )

        let magazines = try context.fetch(FetchDescriptor<Magazine>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(magazines.first?.storedPatternKind, .custom)
        XCTAssertEqual(magazines.first?.patternDisplayName, "Match Tube")
        XCTAssertEqual(magazines.first?.supportedCaliberNames, [".38 Super", "9mm"])
    }

    @MainActor
    func testUpdateMagazinePersistsEditedValues() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let originalCaliber = Caliber(name: "9mm")
        let updatedCaliber = Caliber(name: ".45 ACP")
        let originalFirearm = Firearm(
            brand: "Glock",
            modelName: "17",
            purchasePriceCents: 50000,
            type: .pistol,
            action: .semiAuto
        )
        let updatedFirearm = Firearm(
            brand: "Staccato",
            modelName: "XC",
            purchasePriceCents: 430000,
            type: .pistol,
            action: .semiAuto
        )
        let magazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            count: 2,
            capacity: 17,
            purchasePriceCents: 5000,
            caliber: originalCaliber,
            firearm: originalFirearm
        )
        context.insert(originalCaliber)
        context.insert(updatedCaliber)
        context.insert(originalFirearm)
        context.insert(updatedFirearm)
        context.insert(magazine)

        let viewModel = AddMagazineViewModel()
        let didSave = viewModel.updateMagazine(
            magazine,
            brand: "  Atlas ",
            modelName: " Premium ",
            count: 3,
            capacity: 20,
            purchaseDate: Date(timeIntervalSince1970: 9_999),
            purchasePriceCents: 21000,
            color: .other,
            colorDetail: "Nickel",
            notes: "Updated",
            patternSelection: .catalog("catalog:2011-double-stack-9mm"),
            manualPatternName: "",
            compatibleCaliberNames: [],
            firearm: updatedFirearm,
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(magazine.brand, "Atlas")
        XCTAssertEqual(magazine.modelName, "Premium")
        XCTAssertEqual(magazine.count, 3)
        XCTAssertEqual(magazine.capacity, 20)
        XCTAssertEqual(magazine.magazineColor, .other)
        XCTAssertEqual(magazine.colorDetail, "Nickel")
        XCTAssertEqual(magazine.supportedCaliberNames, ["9mm"])
        XCTAssertEqual(magazine.firearm?.displayName, "Staccato XC")
        XCTAssertEqual(magazine.notes, "Updated")
        XCTAssertEqual(magazine.storedPatternKind, .catalog)
        XCTAssertEqual(magazine.patternID, "catalog:2011-double-stack-9mm")
        XCTAssertNil(magazine.patternDisplayName)
    }

    @MainActor
    func testUpdateMagazineReturnsFalseWithoutMutatingWhenCompatibilityFails() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let originalCaliber = Caliber(name: "9mm")
        let firearmCaliber = Caliber(name: ".45 ACP")
        let firearm = Firearm(
            brand: "Staccato",
            modelName: "P",
            purchasePriceCents: 250000,
            type: .pistol,
            action: .semiAuto,
            caliber: firearmCaliber
        )
        let magazine = Magazine(
            brand: "Glock",
            modelName: "OEM",
            count: 2,
            capacity: 17,
            purchasePriceCents: 5000,
            caliber: originalCaliber
        )
        context.insert(originalCaliber)
        context.insert(firearmCaliber)
        context.insert(firearm)
        context.insert(magazine)

        let viewModel = AddMagazineViewModel()
        let didSave = viewModel.updateMagazine(
            magazine,
            brand: "Atlas",
            modelName: "2011",
            count: 3,
            capacity: 20,
            purchaseDate: Date(timeIntervalSince1970: 9_999),
            purchasePriceCents: 21000,
            color: .black,
            colorDetail: nil,
            notes: "Updated",
            patternSelection: .catalog("catalog:2011-double-stack-9mm"),
            manualPatternName: "",
            compatibleCaliberNames: [],
            firearm: firearm,
            canSave: true,
            in: context
        )

        XCTAssertFalse(didSave)
        XCTAssertEqual(magazine.brand, "Glock")
        XCTAssertEqual(magazine.modelName, "OEM")
        XCTAssertEqual(magazine.count, 2)
        XCTAssertEqual(magazine.capacity, 17)
        XCTAssertNil(magazine.firearm)
    }

    @MainActor
    func testUpdateMagazineAllowsUnlinkingCatalogPatternMagazine() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let caliber = Caliber(name: "5.56 NATO")
        let firearm = Firearm(
            brand: "Daniel Defense",
            modelName: "DDM4",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto,
            caliber: caliber
        )
        let magazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            capacity: 30,
            purchasePriceCents: 1500,
            caliber: caliber,
            firearm: firearm
        )
        context.insert(caliber)
        context.insert(firearm)
        context.insert(magazine)

        let viewModel = AddMagazineViewModel()
        let didSave = viewModel.updateMagazine(
            magazine,
            brand: "Magpul",
            modelName: "PMAG",
            count: 1,
            capacity: 30,
            purchaseDate: .now,
            purchasePriceCents: 1500,
            color: nil,
            colorDetail: nil,
            notes: nil,
            patternSelection: .catalog("catalog:ar15-stanag-223-556-300blk"),
            manualPatternName: "",
            compatibleCaliberNames: [],
            firearm: nil,
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertNil(magazine.firearm)
        XCTAssertEqual(magazine.storedPatternKind, .catalog)
        XCTAssertEqual(magazine.patternID, "catalog:ar15-stanag-223-556-300blk")
    }

    func testInitialPatternHelpersExposeLegacyValues() {
        let magazine = Magazine(
            brand: "CZ",
            modelName: "OEM",
            patternID: "legacy:cz-oem",
            patternKind: .legacy,
            patternDisplayName: "Legacy CZ Tube",
            capacity: 17,
            purchasePriceCents: 3200
        )
        let viewModel = AddMagazineViewModel()

        XCTAssertEqual(viewModel.initialPatternSelection(for: magazine), .legacy)
        XCTAssertEqual(viewModel.initialManualPatternName(for: magazine), "Legacy CZ Tube")
    }

    @MainActor
    func testAvailableCustomPatternsReturnsPersistedCustomPatterns() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let customPattern = MagazinePattern.custom(
            id: UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!,
            displayName: "P320 Legion 9mm",
            familyLabel: "P320 Legion 9mm",
            supportedCaliberNames: ["9mm"]
        )
        let duplicateMagazine = Magazine(
            brand: "SIG",
            modelName: "Legion Spare",
            patternID: customPattern.id,
            patternKind: .custom,
            patternDisplayName: customPattern.displayName,
            patternSupportedCaliberNames: customPattern.compatibility.supportedCaliberNames,
            capacity: 21,
            purchasePriceCents: 5000
        )
        let originalMagazine = Magazine(
            brand: "SIG",
            modelName: "Legion",
            patternID: customPattern.id,
            patternKind: .custom,
            patternDisplayName: customPattern.displayName,
            patternSupportedCaliberNames: customPattern.compatibility.supportedCaliberNames,
            capacity: 21,
            purchasePriceCents: 4500
        )
        let catalogMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG",
            patternID: "catalog:ar15-stanag-223-556-300blk",
            patternKind: .catalog,
            capacity: 30,
            purchasePriceCents: 1500
        )
        context.insert(originalMagazine)
        context.insert(duplicateMagazine)
        context.insert(catalogMagazine)

        let viewModel = AddMagazineViewModel()
        let availablePatterns = viewModel.availableCustomPatterns(in: context)

        XCTAssertEqual(availablePatterns.count, 1)
        XCTAssertEqual(availablePatterns.first?.id, customPattern.id)
        XCTAssertEqual(availablePatterns.first?.displayName, "P320 Legion 9mm")
        XCTAssertEqual(availablePatterns.first?.compatibility.supportedCaliberNames, ["9mm"])
    }

    @MainActor
    func testAddMagazineWithExistingCustomPatternReusesPatternIdentity() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()
        let customPattern = MagazinePattern.custom(
            id: UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!,
            displayName: "P320 Legion 9mm",
            familyLabel: "P320 Legion 9mm",
            supportedCaliberNames: ["9mm"]
        )

        let didAdd = viewModel.addMagazine(
            brand: "SIG",
            modelName: "OEM 17",
            count: 2,
            capacity: 17,
            purchaseDate: .now,
            purchasePriceCents: 4000,
            color: .black,
            colorDetail: nil,
            notes: nil,
            patternSelection: .existingCustom(customPattern),
            manualPatternName: "",
            compatibleCaliberNames: [],
            firearm: nil,
            canAdd: true,
            to: context
        )

        let magazines = try context.fetch(FetchDescriptor<Magazine>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(magazines.count, 1)
        XCTAssertEqual(magazines.first?.storedPatternKind, .custom)
        XCTAssertEqual(magazines.first?.patternID, customPattern.id)
        XCTAssertEqual(magazines.first?.patternDisplayName, customPattern.displayName)
        XCTAssertEqual(magazines.first?.supportedCaliberNames, ["9mm"])
    }

    @MainActor
    func testUpdateMagazineEditingSavedCustomPatternPropagatesToSharedRecords() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()
        let customPatternID = UUID(uuidString: "12345678-1234-1234-1234-1234567890AB")!
        let originalPattern = MagazinePattern.custom(
            id: customPatternID,
            displayName: "P320 Legion 9mm",
            familyLabel: "P320 Legion 9mm",
            supportedCaliberNames: ["9mm"]
        )
        let editedMagazine = Magazine(
            brand: "SIG",
            modelName: "OEM 17",
            patternID: originalPattern.id,
            patternKind: .custom,
            patternDisplayName: originalPattern.displayName,
            patternSupportedCaliberNames: originalPattern.compatibility.supportedCaliberNames,
            capacity: 17,
            purchasePriceCents: 4000
        )
        let siblingMagazine = Magazine(
            brand: "SIG",
            modelName: "OEM 21",
            patternID: originalPattern.id,
            patternKind: .custom,
            patternDisplayName: originalPattern.displayName,
            patternSupportedCaliberNames: originalPattern.compatibility.supportedCaliberNames,
            capacity: 21,
            purchasePriceCents: 4500
        )
        let firearm = Firearm(
            brand: "SIG",
            modelName: "P320",
            purchasePriceCents: 70000,
            type: .pistol,
            action: .semiAuto,
            supportedMagazinePatterns: [FirearmMagazinePatternReference(pattern: originalPattern)]
        )
        context.insert(editedMagazine)
        context.insert(siblingMagazine)
        context.insert(firearm)

        let didSave = viewModel.updateMagazine(
            editedMagazine,
            brand: "SIG",
            modelName: "OEM 17",
            count: 1,
            capacity: 17,
            purchaseDate: .now,
            purchasePriceCents: 4000,
            color: nil,
            colorDetail: nil,
            notes: nil,
            patternSelection: .custom,
            manualPatternName: "P320 Legion Multi-Cal",
            compatibleCaliberNames: ["9mm", ".357 SIG"],
            existingCustomPatternIDOverride: customPatternID,
            firearm: nil,
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(editedMagazine.patternID, originalPattern.id)
        XCTAssertEqual(editedMagazine.patternDisplayName, "P320 Legion Multi-Cal")
        XCTAssertEqual(editedMagazine.supportedCaliberNames, [".357 SIG", "9mm"])
        XCTAssertEqual(siblingMagazine.patternDisplayName, "P320 Legion Multi-Cal")
        XCTAssertEqual(siblingMagazine.supportedCaliberNames, [".357 SIG", "9mm"])
        XCTAssertEqual(firearm.supportedMagazinePatterns.first?.displayName, "P320 Legion Multi-Cal")
    }

    @MainActor
    func testDeleteMagazineRemovesMagazineAndResequencesRemainingInventory() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddMagazineViewModel()
        let deletedMagazine = Magazine(
            brand: "Magpul",
            modelName: "PMAG 30",
            capacity: 30,
            purchasePriceCents: 1_200,
            sortOrder: 0
        )
        let remainingMagazine = Magazine(
            brand: "Lancer",
            modelName: "L5AWM",
            capacity: 30,
            purchasePriceCents: 1_800,
            sortOrder: 4
        )
        context.insert(deletedMagazine)
        context.insert(remainingMagazine)
        try context.save()

        let result = viewModel.deleteMagazine(deletedMagazine, in: context)
        let magazines = try context.fetch(FetchDescriptor<Magazine>())

        XCTAssertTrue(result.isValid)
        XCTAssertEqual(magazines.map(\.displayName), ["Lancer L5AWM"])
        XCTAssertEqual(remainingMagazine.sortOrder, 0)
    }
}
