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
                selectedCaliber: nil,
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
                selectedCaliber: nil,
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
                selectedCaliber: nil,
                firearm: nil
            )
        )
    }

    func testCanAddReturnsFalseForMagazineCaliberMismatchAgainstLinkedFirearm() {
        let viewModel = AddMagazineViewModel()
        let magazineCaliber = Caliber(name: "9mm")
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
                selectedCaliber: magazineCaliber,
                firearm: firearm
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
            action: .semiAuto
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
            caliber: caliber,
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
        XCTAssertEqual(magazines.first?.caliber?.name, "9mm")
        XCTAssertEqual(magazines.first?.firearm?.displayName, "CZ P-10 C")
        XCTAssertEqual(magazines.first?.purchaseDate, purchaseDate)
        XCTAssertEqual(magazines.first?.sortOrder, 0)
        XCTAssertEqual(magazines.first?.storedPatternKind, .legacy)
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
            caliber: nil,
            firearm: nil,
            canAdd: false,
            to: context
        )

        XCTAssertFalse(didAdd)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Magazine>()).isEmpty)
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
            caliber: updatedCaliber,
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
        XCTAssertEqual(magazine.caliber?.name, ".45 ACP")
        XCTAssertEqual(magazine.firearm?.displayName, "Staccato XC")
        XCTAssertEqual(magazine.notes, "Updated")
        XCTAssertEqual(magazine.storedPatternKind, .legacy)
        XCTAssertEqual(magazine.patternID, "legacy:atlas-premium")
        XCTAssertEqual(magazine.patternDisplayName, "Atlas Premium")
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
            caliber: originalCaliber,
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
}
