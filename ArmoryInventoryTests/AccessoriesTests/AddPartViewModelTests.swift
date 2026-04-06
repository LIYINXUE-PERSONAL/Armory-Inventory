//
//  AddPartViewModelTests.swift
//  Armory InventoryTests
//
//  Created by Codex on 4/5/26.
//

import XCTest
import SwiftData
@testable import ArmoryInventory

final class AddPartViewModelTests: XCTestCase {
    func testResolutionAndValidationHandleTrimmedAndInvalidValues() {
        let viewModel = AddPartViewModel()

        XCTAssertEqual(viewModel.initialPurchasePriceText(for: nil), "0.00")
        XCTAssertEqual(viewModel.trimmedValue("  Geissele "), "Geissele")
        XCTAssertEqual(viewModel.optionalValue("  SSA-E  "), "SSA-E")
        XCTAssertNil(viewModel.optionalValue(" "))
        XCTAssertEqual(viewModel.purchasePriceCents(from: " 240.00 "), 24000)
        XCTAssertNil(viewModel.purchasePriceCents(from: "bad"))
        XCTAssertNil(viewModel.resolvedTypeDetail(selectedType: .trigger, customType: "Ignored"))
        XCTAssertEqual(viewModel.resolvedTypeDetail(selectedType: .other, customType: "  Fire Control Group  "), "Fire Control Group")
        XCTAssertNil(viewModel.resolvedColorDetail(selectedColor: .black, customColor: "Ignored"))
        XCTAssertEqual(viewModel.resolvedColorDetail(selectedColor: .other, customColor: "  Nitride  "), "Nitride")
        XCTAssertNil(viewModel.linkedFirearm(for: nil, unlinkFirearm: false))
        XCTAssertEqual(viewModel.purchasePriceWithTaxText(purchasePriceCents: nil, taxRate: 6), "--")
        XCTAssertTrue(viewModel.isReadOnly(hasPart: true, isEditing: false))
        XCTAssertFalse(viewModel.showsPurchaseSection(showValueInDetails: false, isReadOnly: true))
        XCTAssertEqual(viewModel.primaryButtonTitle(hasPart: true, isEditing: false), "Edit")
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Geissele",
                modelName: "SSA-E",
                selectedType: .other,
                typeDetail: nil,
                selectedColor: nil,
                colorDetail: nil,
                purchasePriceText: "100"
            )
        )
        XCTAssertFalse(
            viewModel.canAdd(
                brand: "Geissele",
                modelName: "SSA-E",
                selectedType: .trigger,
                typeDetail: nil,
                selectedColor: .other,
                colorDetail: nil,
                purchasePriceText: "100"
            )
        )
        XCTAssertTrue(
            viewModel.canAdd(
                brand: "Geissele",
                modelName: "SSA-E",
                selectedType: .trigger,
                typeDetail: nil,
                selectedColor: .black,
                colorDetail: nil,
                purchasePriceText: "100"
            )
        )
    }

    @MainActor
    func testAddPartPersistsModel() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddPartViewModel()
        let purchaseDate = Date(timeIntervalSince1970: 1_234_567)
        let firearm = Firearm(
            brand: "BCM",
            modelName: "Recce",
            purchasePriceCents: 160000,
            type: .rifle,
            action: .semiAuto
        )
        context.insert(firearm)

        let didAdd = viewModel.addPart(
            brand: "  Geissele ",
            modelName: " SSA-E ",
            type: .trigger,
            typeDetail: nil,
            color: .black,
            colorDetail: nil,
            purchaseDate: purchaseDate,
            purchasePriceCents: 24000,
            notes: "Match trigger",
            firearm: firearm,
            canAdd: true,
            to: context
        )

        let parts = try context.fetch(FetchDescriptor<Part>())

        XCTAssertTrue(didAdd)
        XCTAssertEqual(parts.count, 1)
        XCTAssertEqual(parts.first?.brand, "Geissele")
        XCTAssertEqual(parts.first?.modelName, "SSA-E")
        XCTAssertEqual(parts.first?.partType, .trigger)
        XCTAssertEqual(parts.first?.firearm?.displayName, "BCM Recce")
        XCTAssertEqual(parts.first?.purchaseDate, purchaseDate)
        XCTAssertEqual(parts.first?.sortOrder, 0)
    }

    @MainActor
    func testAddPartReturnsFalseWhenBlocked() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let viewModel = AddPartViewModel()

        let didAdd = viewModel.addPart(
            brand: "BCM",
            modelName: "MK2",
            type: .chargingHandle,
            typeDetail: nil,
            color: nil,
            colorDetail: nil,
            purchaseDate: .now,
            purchasePriceCents: 8000,
            notes: nil,
            firearm: nil,
            canAdd: false,
            to: context
        )

        XCTAssertFalse(didAdd)
        XCTAssertTrue(try context.fetch(FetchDescriptor<Part>()).isEmpty)
    }

    @MainActor
    func testUpdatePartPersistsEditedValues() throws {
        let container = try makeInMemoryContainer()
        let context = container.mainContext
        let originalFirearm = Firearm(
            brand: "Daniel Defense",
            modelName: "MK18",
            purchasePriceCents: 180000,
            type: .rifle,
            action: .semiAuto
        )
        let updatedFirearm = Firearm(
            brand: "LMT",
            modelName: "MARS-L",
            purchasePriceCents: 250000,
            type: .rifle,
            action: .semiAuto
        )
        let part = Part(
            brand: "BCM",
            modelName: "MK2",
            type: .chargingHandle,
            purchasePriceCents: 8000,
            firearm: originalFirearm
        )
        context.insert(originalFirearm)
        context.insert(updatedFirearm)
        context.insert(part)

        let viewModel = AddPartViewModel()
        let didSave = viewModel.updatePart(
            part,
            brand: "  Apex ",
            modelName: " Trigger Kit ",
            type: .other,
            typeDetail: "Fire Control Group",
            color: .other,
            colorDetail: "Nitride",
            purchaseDate: Date(timeIntervalSince1970: 9_999),
            purchasePriceCents: 12999,
            notes: "Updated",
            firearm: updatedFirearm,
            canSave: true,
            in: context
        )

        XCTAssertTrue(didSave)
        XCTAssertEqual(part.brand, "Apex")
        XCTAssertEqual(part.modelName, "Trigger Kit")
        XCTAssertEqual(part.partType, .other)
        XCTAssertEqual(part.typeDetail, "Fire Control Group")
        XCTAssertEqual(part.partColor, .other)
        XCTAssertEqual(part.colorDetail, "Nitride")
        XCTAssertEqual(part.firearm?.displayName, "LMT MARS-L")
        XCTAssertEqual(part.notes, "Updated")
    }
}
